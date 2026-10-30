local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local fetchRemoteEvent = require(script.Parent.util.fetchRemoteEvent)

local GlobalReplicator = {}
GlobalReplicator.__index = GlobalReplicator

export type GlobalReplicator<T> = typeof(setmetatable(
	{} :: {
		remote: RemoteEvent,
		value: T,
		conns: { RBXScriptConnection },
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

		local serverSyncConn = remote.OnServerEvent:Connect(function(player)
			remote:FireClient(player, self.value)
		end)
		table.insert(self.conns, serverSyncConn)
	else
		self.value = initialData

		local clientSyncConn = remote.OnClientEvent:Connect(function(syncValue)
			self.value = syncValue
		end)
		table.insert(self.conns, clientSyncConn)

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

function GlobalReplicator.sync<T>(self: GlobalReplicator<T>)
	assert(RunService:IsClient(), "Replicator 'sync' method can only be run client-side")
	self.remote:FireServer()
end

function GlobalReplicator.observe<T>(self: GlobalReplicator<T>, callback: (T) -> ...any): RBXScriptConnection
	assert(RunService:IsClient(), "Replicator 'observe' method can only be run client-side")
	return self.remote.OnClientEvent:Connect(callback)
end

function GlobalReplicator.Destroy<T>(self: GlobalReplicator<T>)
	for _, conn in self.conns do
		conn:Disconnect()
	end

	self.remote:Destroy()
end

return GlobalReplicator
