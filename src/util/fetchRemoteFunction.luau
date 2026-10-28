local RunService = game:GetService("RunService")

return function(parent: Instance, name: string): RemoteFunction
	local remoteFunction: RemoteFunction
	if RunService:IsServer() then
		local duplicateRemote = parent:FindFirstChild(name)
		if duplicateRemote and duplicateRemote:IsA("RemoteFunction") then
			error(`'{name}' RemoteFunction already exists.`)
		end

		remoteFunction = Instance.new("RemoteFunction")
		remoteFunction.Name = name
		remoteFunction.Parent = parent
	else
		remoteFunction = assert(parent:WaitForChild(name, 5) :: RemoteFunction?, `'{name}' RemoteFunction not found.`)
		assert(remoteFunction:IsA("RemoteFunction"), `'{name}' is not a RemoteFunction.`)
	end

	return remoteFunction
end
