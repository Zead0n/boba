local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local castType = require(script.Parent.util.castType)
local Promise = require(script.Parent.Parent.Promise)
local Types = require(script.Parent.Types)
local Signal = require(script.Parent.Parent.Signal)
local fetchRemoteEvent = require(script.Parent.util.fetchRemoteEvent)

local LocalReplicator = {}
LocalReplicator.__index = LocalReplicator

export type LocalReplicator<C, T, P> = typeof(setmetatable(
	{} :: {
		remote: RemoteEvent,
		value: { [Player]: T },
		conns: { Signal.Connection },
		_clientSignal: Signal.Signal<T>,
		_asserter: (any, ...any) -> ...any,
		_syncPromise: any,
		_patch: C?,
		_patchApplyer: ((T, P) -> T)?,
		_patchDiffer: ((T, T) -> P)?,
	},
	LocalReplicator
))

local function clientSet<C, T, P>(self: LocalReplicator<C, T, P>, value: T | P, isPatch: boolean?)
	local localPlayer = Players.LocalPlayer

	local newValue = if not isPatch
		then value :: T
		else assert(self._patchApplyer, "Replicator does not support patches")(self:get(), value :: P)

	self.value[localPlayer] = newValue
	self._clientSignal:Fire(newValue)
end

function LocalReplicator.new<C, T, P>(
	parent: Instance,
	name: string,
	initialData: T,
	patchConfig: Types.PatchConfig<C, T, P>?
): LocalReplicator<C, T, P>
	local remote = fetchRemoteEvent(parent, name)

	local self = setmetatable({}, LocalReplicator) :: LocalReplicator<C, T, P>
	self.remote = remote
	self._clientSignal = Signal.new()

	if patchConfig then
		self._patch = castType(patchConfig.patchType)
		self._patchApplyer = patchConfig.apply
		self._patchDiffer = patchConfig.diff
	end

	self.conns = {}

	if RunService:IsServer() then
		self.value = {}
		local playerAddedConn = Players.PlayerAdded:Connect(function(player)
			self.value[player] = initialData
		end)
		table.insert(self.conns, playerAddedConn)

		local playerRemovedConn = Players.PlayerRemoving:Connect(function(player)
			self.value[player] = nil
		end)
		table.insert(self.conns, playerRemovedConn)

		local serverSyncConn = remote.OnServerEvent:Connect(function(player)
			local playerValue = self.value[player]
			remote:FireClient(player, playerValue, false)
		end)
		table.insert(self.conns, serverSyncConn :: any)

		for _, player in Players:GetPlayers() do
			self.value[player] = initialData
		end
	else
		local localPlayer = Players.LocalPlayer
		self.value[localPlayer] = initialData

		local clientSyncConn = remote.OnClientEvent:Connect(function(syncValue, isPatch)
			clientSet(self, syncValue, isPatch)
		end)
		table.insert(self.conns, clientSyncConn :: any)

		self:sync()
	end

	return self
end

function LocalReplicator.get<C, T, P>(self: LocalReplicator<C, T, P>, player: Player?): any
	if RunService:IsServer() then
		assert(player, "Replicator 'get' method requires a 'player' argument server-side")
		return self.value[player]
	else
		if player ~= nil then
			warn("Replicator 'get' method gets local player internally client-side")
		end

		local localPlayer = Players.LocalPlayer
		return self.value[localPlayer]
	end
end

function LocalReplicator.getAll<C, T, P>(self: LocalReplicator<C, T, P>): { [Player]: T }
	assert(RunService:IsServer(), "Replicator 'getAll' method can only be run server-side")

	return self.value
end

function LocalReplicator.set<C, T, P>(self: LocalReplicator<C, T, P>, player: Player, newValue: T)
	assert(RunService:IsServer(), "Replicator 'set' method can only be run server-side")

	self.value[player] = newValue
	self.remote:FireClient(player, newValue, false)
end

function LocalReplicator.setPatch<C, T, P>(self: LocalReplicator<C, T, P>, player: Player, newValue: T)
	assert(RunService:IsServer(), "Replicator 'setPatch' method can only be run server-side")

	local oldValue = assert(self:get(player), "Replicator holds no value, cannot run a patch")
	self:patch(player, assert(self._patchDiffer, "Replicator does not support patches")(oldValue, newValue))
end

function LocalReplicator.patch<C, T, P>(self: LocalReplicator<C, T, P>, player: Player, patch: P)
	assert(RunService:IsServer(), "Replicator 'patch' method can only be run server-side")

	self.value[player] = assert(self._patchApplyer, "Replicator does not support patches")(self:get(player), patch)
	self.remote:FireClient(player, patch, true)
end

function LocalReplicator.setAll<C, T, P>(self: LocalReplicator<C, T, P>, newValue: T)
	assert(RunService:IsServer(), "Replicator 'setAll' method can only be run server-side")

	for _, player in Players:GetPlayers() do
		self:set(player, newValue)
	end
end

function LocalReplicator.setPatchAll<C, T, P>(self: LocalReplicator<C, T, P>, newValue: T)
	assert(RunService:IsServer(), "Replicator 'setPatchAll' method can only be run server-side")

	for _, player in Players:GetPlayers() do
		self:setPatch(player, newValue)
	end
end

function LocalReplicator.patchAll<C, T, P>(self: LocalReplicator<C, T, P>, patch: P)
	assert(RunService:IsServer(), "Replicator 'setAll' method can only be run server-side")

	for _, player in Players:GetPlayers() do
		self:patch(player, patch)
	end
end

function LocalReplicator.sync<C, T, P>(self: LocalReplicator<C, T, P>, timeout: number?): T
	assert(RunService:IsClient(), "Replicator 'sync' method can only be run client-side")

	self._syncPromise = Promise.fromEvent(self.remote.OnClientEvent, function(_, isPatch)
		return not isPatch
	end)
		:andThen(function(value, _)
			return value
		end)
		:timeout(timeout or 5, self:get())

	self.remote:FireServer()
	return self._syncPromise:expect()
end

function LocalReplicator.observe<C, T, P>(self: LocalReplicator<C, T, P>, callback: (T) -> ...any): Signal.Connection
	assert(RunService:IsClient(), "Replicator 'observe' method can only be run client-side")
	local conn = self._clientSignal:Connect(callback)
	table.insert(self.conns, conn)

	return conn
end

function LocalReplicator.predictUpdate<C, T, P>(self: LocalReplicator<C, T, P>, predictedCallback: (T) -> T): Types.Prediction
	assert(RunService:IsClient(), "Replicator 'predictUpdate' method can only be run client-side")

	return {
		replicator = self :: any,
		predict = function()
			clientSet(self, predictedCallback(self:get()), false)
		end,
	}
end

function LocalReplicator.predictPatch<C, T, P>(self: LocalReplicator<C, T, P>, predictedPatch: P): Types.Prediction
	assert(RunService:IsClient(), "Replicator 'predictPatch' method can only be run client-side")

	return {
		replicator = self :: any,
		predict = function()
			clientSet(self, predictedPatch, true)
		end,
	}
end

function LocalReplicator.Destroy<C, T, P>(self: LocalReplicator<C, T, P>)
	if self._syncPromise then
		self._syncPromise:cancel()
		self._syncPromise = nil
	end

	for _, conn in self.conns do
		conn:Disconnect()
	end

	self._clientSignal:Destroy()
	self.remote:Destroy()
end

return LocalReplicator
