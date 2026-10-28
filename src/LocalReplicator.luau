local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local fetchRemoteEvent = require(script.Parent.util.fetchRemoteEvent)

local LocalReplicator = {}
LocalReplicator.__index = LocalReplicator

export type LocalReplicator<T> = typeof(setmetatable(
	{} :: {
		remote: RemoteEvent,
		value: { [Player]: T },
		conns: { RBXScriptConnection },
	},
	LocalReplicator
))

function LocalReplicator.new<T>(parent: Instance, name: string, initialData: T): LocalReplicator<T>
	local remote = fetchRemoteEvent(parent, name)

	local self = setmetatable({}, LocalReplicator) :: LocalReplicator<T>
	self.remote = remote
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

		local serverSyncConn = remote.OnServerEvent:Connect(function(player, sentValue)
			local playerValue = self.value[player]
			if playerValue == nil or playerValue == sentValue then
				return
			end

			remote:FireClient(player, playerValue)
		end)
		table.insert(self.conns, serverSyncConn)

		for _, player in Players:GetPlayers() do
			self.value[player] = initialData
		end
	else
		local localPlayer = Players.LocalPlayer
		self.value[localPlayer] = initialData

		local clientSyncConn = remote.OnClientEvent:Connect(function(syncValue)
			self.value[localPlayer] = syncValue
		end)
		table.insert(self.conns, clientSyncConn)

		self:sync()
	end

	return self
end

function LocalReplicator.get<T>(self: LocalReplicator<T>, player: Player?): any
	if RunService:IsServer() then
		assert(player, "Replicator 'get' method requires a 'player' parameter on server-side")
		return self.value[player]
	else
		if player ~= nil then
			warn("Replicator 'get' method gets local player internally client-side")
		end

		local localPlayer = Players.LocalPlayer
		return self.value[localPlayer]
	end
end

function LocalReplicator.getAll<T>(self: LocalReplicator<T>): { [Player]: T }
	assert(RunService:IsServer(), "Replicator 'getAll' method can only be run server-side")
	return self.value
end

function LocalReplicator.set<T>(self: LocalReplicator<T>, player: Player, newValue: T)
	assert(RunService:IsServer(), "Replicator 'set' method can only be run server-side")
	self.value[player] = newValue
	self.remote:FireClient(player, newValue)
end

function LocalReplicator.setAll<T>(self: LocalReplicator<T>, newValue: T)
	assert(RunService:IsServer(), "Replicator 'setAll' method can only be run server-side")
	for _, player in Players:GetPlayers() do
		self.value[player] = newValue
		self.remote:FireClient(player, newValue)
	end
end

function LocalReplicator.sync<T>(self: LocalReplicator<T>)
	assert(RunService:IsClient(), "Replicator 'sync' method can only be run client-side")
	self.remote:FireServer(self.value)
end

function LocalReplicator.observe<T>(self: LocalReplicator<T>, callback: (T) -> ...any): RBXScriptConnection
	assert(RunService:IsClient(), "Replicator 'observe' method can only be run client-side")
	return self.remote.OnClientEvent:Connect(callback)
end

function LocalReplicator.Destroy<T>(self: LocalReplicator<T>)
	for _, conn in self.conns do
		conn:Disconnect()
	end

	self.remote:Destroy()
end

return LocalReplicator
