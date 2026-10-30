local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Promise = require(script.Parent.Parent.Promise)
local Types = require(script.Parent.Types)
local Signal = require(script.Parent.Parent.Signal)
local fetchRemoteEvent = require(script.Parent.util.fetchRemoteEvent)

local GlobalReplicator = {}
GlobalReplicator.__index = GlobalReplicator

export type GlobalReplicator<T> = typeof(setmetatable(
	{} :: {
		remote: RemoteEvent,
		value: T,
		conns: { Signal.Connection },
		_clientSignal: Signal.Signal<T>,
		_syncPromise: any,
	},
	GlobalReplicator
))

function GlobalReplicator.new<T>(parent: Instance, name: string, initialData: T): GlobalReplicator<T>
	local remote = fetchRemoteEvent(parent, name)

	local self = setmetatable({}, GlobalReplicator) :: GlobalReplicator<T>
	self.remote = remote
	self.conns = {}

	self.value = initialData

	if RunService:IsServer() then
		local playerAddedConn = Players.PlayerAdded:Connect(function(player)
			self.value = initialData
		end)
		table.insert(self.conns, playerAddedConn)

		local serverSyncConn = remote.OnServerEvent:Connect(function(player, sentValue)
			remote:FireClient(player, self.value)
		end)
		table.insert(self.conns, serverSyncConn :: any)
	else
		self.value = initialData

		local clientSyncConn = remote.OnClientEvent:Connect(function(syncValue)
			self.value = syncValue
			self._clientSignal:Fire(syncValue)
		end)
		table.insert(self.conns, clientSyncConn :: any)

		self:sync()
	end

	return self
end

function GlobalReplicator.get<T>(self: GlobalReplicator<T>): T
	return self.value
end

function GlobalReplicator.set<T>(self: GlobalReplicator<T>, newValue: T)
	assert(RunService:IsServer(), "Replicator 'set' method can only be run server-side")
	self.value = newValue
	self.remote:FireAllClients(newValue)
end

function GlobalReplicator.sync<T>(self: GlobalReplicator<T>, timeout: number?)
	assert(RunService:IsClient(), "Replicator 'sync' method can only be run client-side")
	self._syncPromise = Promise.fromEvent(self.remote.OnClientEvent):timeout(timeout or 5, self:get())
	self.remote:FireServer()
	return self._syncPromise:expect()
end

function GlobalReplicator.observe<T>(self: GlobalReplicator<T>, callback: (T) -> ...any): Signal.Connection
	assert(RunService:IsClient(), "Replicator 'observe' method can only be run client-side")
	local conn = self._clientSignal:Connect(callback)
	table.insert(self.conns, conn)

	return conn
end

function GlobalReplicator.prediction<T>(self: GlobalReplicator<T>, callback: (T) -> T): Types.Prediction
	assert(RunService:IsClient(), "Replicator 'prediction' method can only be run client-side")

	return {
		replicator = self :: any,
		predict = function()
			self:_clientSet(callback(self:get()))
		end,
	}
end

function GlobalReplicator.Destroy<T>(self: GlobalReplicator<T>)
	if self._syncPromise then
		self._syncPromise:cancel()
		self._syncPromise = nil
	end

	for _, conn in self.conns do
		conn:Disconnect()
	end

	self.remote:Destroy()
end

function GlobalReplicator._clientSet<T>(self: GlobalReplicator<T>, value: T)
	assert(RunService:IsClient(), "Replicator '_clientSet' method can only be run client-side")
	self.value = value
	self._clientSignal:Fire(value)
end

return GlobalReplicator
