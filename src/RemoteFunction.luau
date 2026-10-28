local fetchRemoteFunction = require(script.Parent.util.fetchRemoteFunction)
local resolverType = require(script.Parent.util.resolverType)
local typeAssert = require(script.Parent.util.typeAssert)

local Func = {}
Func.__index = Func

export type Func<A..., R...> = typeof(setmetatable(
	{} :: {
		remote: RemoteFunction,
		_resolver: resolverType.Resolver,
		_args: (A...) -> ...any,
		_returns: (...any) -> R...,
	},
	Func
))

function Func.new<A..., R...>(
	name: string,
	parent: Instance,
	resolver: resolverType.Resolver,
	args: (A...) -> A...,
	returns: (R...) -> R...
): Func<A..., R...>
	local remoteFunction = fetchRemoteFunction(parent, name)

	local self = setmetatable({}, Func) :: Func<A..., R...>

	self.remote = remoteFunction
	self._resolver = resolver
	self._args = args
	self._returns = returns

	return self
end

function Func.SetServerInvoke<T, A..., R...>(self: Func<A..., R...>, onInvoke: (Player, A...) -> R...)
	self.remote.OnServerInvoke = onInvoke
end

function Func.SetClientInvoke<T, A..., R...>(self: Func<A..., R...>, onInvoke: (A...) -> R...)
	self.remote.OnClientInvoke = onInvoke
end

function Func.InvokeServer<T, A..., R...>(self: Func<A..., R...>, ...: A...): R...
	local ok, err = self._resolver(self._args, ...)
	if not ok then
		error(err, 2)
	end

	return typeAssert(self._resolver(self._returns, self.remote:InvokeServer(...)))
end

function Func.InvokeClient<A..., R...>(self: Func<A..., R...>, player: Player, ...: A...): R...
	local ok, err = self._resolver(self._args, ...)
	if not ok then
		error(err, 2)
	end

	return typeAssert(self._resolver(self._returns, self.remote:InvokeClient(player, ...)))
end

function Func.Destroy(self: Func<(...any), (...any)>)
	self.remote:Destroy()
end

return Func
