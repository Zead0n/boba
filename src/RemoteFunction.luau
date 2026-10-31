local RunService = game:GetService("RunService")

local Types = require(script.Parent.Types)
local Promise = require(script.Parent.Parent.Promise)
local assertWrapper = require(script.Parent.util.assertWrapper)
local fetchRemoteFunction = require(script.Parent.util.fetchRemoteFunction)

local Func = {}
Func.__index = Func

export type Func<C, A..., R...> = typeof(setmetatable(
	{} :: {
		remote: RemoteFunction,
		_args: (...any) -> ...any,
		_returns: (...any) -> ...any,
		_predictPromise: any,
	},
	Func
))

function Func.new<C, A..., R...>(
	name: string,
	parent: Instance,
	resolver: Types.Resolver<C>,
	args: { C },
	returns: { C }
): Func<C, A..., R...>
	local remoteFunction = fetchRemoteFunction(parent, name)

	local self = setmetatable({}, Func) :: Func<C, A..., R...>

	self.remote = remoteFunction
	self._args = assertWrapper(resolver, args)
	self._returns = assertWrapper(resolver, returns)

	return self
end

function Func.SetServerInvoke<C, A..., R...>(self: Func<C, A..., R...>, onInvoke: (Player, A...) -> R...)
	self.remote.OnServerInvoke = onInvoke
end

function Func.SetClientInvoke<C, A..., R...>(self: Func<C, A..., R...>, onInvoke: (A...) -> R...)
	self.remote.OnClientInvoke = onInvoke
end

function Func.InvokeServer<C, A..., R...>(self: Func<C, A..., R...>, ...: A...): R...
	return self._returns(self.remote:InvokeServer(self._args(...)))
end

function Func.InvokeClient<C, A..., R...>(self: Func<C, A..., R...>, player: Player, ...: A...): R...
	return self._returns(self.remote:InvokeClient(player, self._args(...)))
end

function Func.PredictionServerInvoker<C, A..., R...>(
	self: Func<C, A..., R...>,
	predictions: { Types.Prediction },
	timeout: number?
): (A...) -> R...
	assert(RunService:IsClient(), "RemoteFunction `PredictServerInvoker` can only run client-side")

	-- HACK: luau typesolver REALLY doesn't like these, have to spam 'any' type
	return function(...: any): ...any
		self._predictPromise = Promise.each(predictions, function(prediction: Types.Prediction)
			prediction.predict()
			return prediction.replicator
		end)

		local outputs = table.pack((self :: any):InvokeServer(...))

		self._predictPromise:andThen(function(replicators: { Types.SyncLike })
			for _, replicator in replicators do
				replicator:sync(timeout)
			end
		end)

		return table.unpack(outputs, 1, outputs.n)
	end
end

function Func.Destroy<C, A..., R...>(self: Func<C, A..., R...>)
	if self._predictPromise then
		self._predictPromise:cancel()
		self._predictPromise = nil
	end
	self.remote:Destroy()
end

return Func
