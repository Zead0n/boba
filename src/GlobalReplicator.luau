local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local castType = require(ReplicatedStorage.Packages.Boba.util.castType)
local Promise = require(script.Parent.Parent.Promise)
local Types = require(script.Parent.Types)
local Signal = require(script.Parent.Parent.Signal)
local fetchRemoteEvent = require(script.Parent.util.fetchRemoteEvent)

local GlobalReplicator = {}
GlobalReplicator.__index = GlobalReplicator

export type GlobalReplicator<C, T, P> = typeof(setmetatable(
	{} :: {
		remote: RemoteEvent,
		value: T,
		conns: { Signal.Connection },
		_clientSignal: Signal.Signal<T>,
		_syncPromise: any,
		_patch: C?,
		_patchApplyer: ((T, P) -> T)?,
		_patchDiffer: ((T, T) -> P)?,
	},
	GlobalReplicator
))

local function clientSet<C, T, P>(self: GlobalReplicator<C, T, P>, value: T | P, isPatch: boolean?)
	local newValue = if not isPatch
		then value :: T
		else assert(self._patchApplyer, "Replicator does not support patches")(self:get(), value :: P)

	self.value = newValue
	self._clientSignal:Fire(newValue)
end

function GlobalReplicator.new<C, T, P>(
	parent: Instance,
	name: string,
	initialData: T,
	patchConfig: Types.PatchConfig<C, T, P>
): GlobalReplicator<C, T, P>
	local remote = fetchRemoteEvent(parent, name)

	local self = setmetatable({}, GlobalReplicator) :: GlobalReplicator<C, T, P>
	self.remote = remote

	self._patch = castType(patchConfig.patchType)
	self._patchApplyer = patchConfig.apply
	self._patchDiffer = patchConfig.diff

	self.conns = {}

	self.value = initialData

	if RunService:IsServer() then
		local serverSyncConn = remote.OnServerEvent:Connect(function(player, sentValue)
			remote:FireClient(player, self.value, false)
		end)
		table.insert(self.conns, serverSyncConn :: any)
	else
		self.value = initialData

		local clientSyncConn = remote.OnClientEvent:Connect(function(syncValue, isPatch)
			clientSet(self, syncValue, isPatch)
		end)
		table.insert(self.conns, clientSyncConn :: any)

		self:sync()
	end

	return self
end

function GlobalReplicator.get<C, T, P>(self: GlobalReplicator<C, T, P>): T
	return self.value
end

function GlobalReplicator.set<C, T, P>(self: GlobalReplicator<C, T, P>, newValue: T)
	assert(RunService:IsServer(), "Replicator 'set' method can only be run server-side")
	self.value = newValue
	self.remote:FireAllClients(newValue, false)
end

function GlobalReplicator.patch<C, T, P>(self: GlobalReplicator<C, T, P>, patch: P)
	self.value = assert(self._patchApplyer, "Replicator does not support patches")(self:get(), patch)
	self.remote:FireAllClients(patch, true)
end

function GlobalReplicator.sync<C, T, P>(self: GlobalReplicator<C, T, P>, timeout: number?)
	assert(RunService:IsClient(), "Replicator 'sync' method can only be run client-side")
	self._syncPromise = Promise.fromEvent(self.remote.OnClientEvent):timeout(timeout or 5, self:get())
	self.remote:FireServer()
	return self._syncPromise:expect()
end

function GlobalReplicator.observe<C, T, P>(self: GlobalReplicator<C, T, P>, callback: (T) -> ...any): Signal.Connection
	assert(RunService:IsClient(), "Replicator 'observe' method can only be run client-side")
	local conn = self._clientSignal:Connect(callback)
	table.insert(self.conns, conn)

	return conn
end

function GlobalReplicator.predictUpdate<C, T, P>(self: GlobalReplicator<C, T, P>, predictedCallback: (T) -> T): Types.Prediction
	assert(RunService:IsClient(), "Replicator 'prediction' method can only be run client-side")

	return {
		replicator = self :: any,
		predict = function()
			clientSet(self, predictedCallback(self:get()), false)
		end,
	}
end

function GlobalReplicator.predictPatch<C, T, P>(self: GlobalReplicator<C, T, P>, predictedPatch: P): Types.Prediction
	assert(RunService:IsClient(), "Replicator 'predictPatch' method can only be run client-side")

	return {
		replicator = self :: any,
		predict = function()
			clientSet(self, predictedPatch, true)
		end,
	}
end

function GlobalReplicator.Destroy<C, T, P>(self: GlobalReplicator<C, T, P>)
	if self._syncPromise then
		self._syncPromise:cancel()
		self._syncPromise = nil
	end

	for _, conn in self.conns do
		conn:Disconnect()
	end

	self.remote:Destroy()
end

return GlobalReplicator
