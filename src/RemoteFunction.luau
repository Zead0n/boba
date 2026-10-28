local assertWrapper = require(script.Parent.util.assertWrapper)
local fetchRemoteFunction = require(script.Parent.util.fetchRemoteFunction)
local resolverType = require(script.Parent.util.resolverType)

local Func = {}
Func.__index = Func

export type Func<A..., R...> = typeof(setmetatable(
	{} :: {
		remote: RemoteFunction,
		_args: (A...) -> ...any,
		_asserter: (any, ...any) -> ...any,
		_returns: (...any) -> R...,
		_returnsAsserter: (...any) -> ...any,
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
	self._args = args
	self._asserter = assertWrapper(resolver)
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
	return self._asserter(self._returns, self.remote:InvokeClient(self._asserter(self._args, ...)))
end

function Func.InvokeClient<A..., R...>(self: Func<A..., R...>, player: Player, ...: A...): R...
	return self._asserter(self._returns, self.remote:InvokeClient(player, self._asserter(self._args, ...)))
end

function Func.Destroy(self: Func<(...any), (...any)>)
	self.remote:Destroy()
end

return Func
