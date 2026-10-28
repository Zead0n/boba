local RunService = game:GetService("RunService")

return function(parent: Instance, name: string): RemoteEvent
	local remoteEvent: RemoteEvent
	if RunService:IsServer() then
		local duplicateRemote = parent:FindFirstChild(name)
		if duplicateRemote and duplicateRemote:IsA("RemoteEvent") then
			error(`'{name}' RemoteEvent already exists.`)
		end

		remoteEvent = Instance.new("RemoteEvent")
		remoteEvent.Name = name
		remoteEvent.Parent = parent
	else
		remoteEvent = assert(parent:WaitForChild(name, 5) :: RemoteEvent?, `'{name}' RemoteEvent not found.`)
		assert(remoteEvent:IsA("RemoteEvent"), `'{name}' is not a RemoteEvent.`)
	end

	return remoteEvent
end
