local RunService = game:GetService("RunService")

return function(parent: Instance, name: string): UnreliableRemoteEvent
	local remoteEvent: UnreliableRemoteEvent
	if RunService:IsServer() then
		local duplicateRemote = parent:FindFirstChild(name)
		if duplicateRemote and duplicateRemote:IsA("UnreliableRemoteEvent") then
			error(`'{name}' UnreliableRemoteEvent already exists.`)
		end

		remoteEvent = Instance.new("UnreliableRemoteEvent")
		remoteEvent.Name = name
		remoteEvent.Parent = parent
	else
		remoteEvent =
			assert(parent:WaitForChild(name, 5) :: UnreliableRemoteEvent?, `'{name}' UnreliableRemoteEvent not found.`)
		assert(remoteEvent:IsA("UnreliableRemoteEvent"), `'{name}' is not a UnreliableRemoteEvent.`)
	end

	return remoteEvent
end
