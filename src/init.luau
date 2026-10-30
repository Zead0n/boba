local Types = require(script.Types)

-- remotes
local Event = require(script.RemoteEvent)
local Func = require(script.RemoteFunction)

export type RemoteEvent<C, A...> = Event.Event<C, A...>
export type RemoteFunction<C, T..., R...> = Func.Func<C, T..., R...>

-- replicators
local GlobablReplicator = require(script.GlobalReplicator)
local LocalReplicator = require(script.LocalReplicator)
local castType = require(script.util.castType)

export type ScopedReplicator<T> = LocalReplicator.LocalReplicator<T>
export type GlobalReplicator<T> = GlobablReplicator.GlobalReplicator<T>

local Boba = {}

function Boba.define<C>(config: {
	parent: Instance,
	resolver: Types.Resolver<C>,
})
	return {
		unreliableRemoteEvent = function(name: string)
			return Boba.unreliableRemoteEvent(name, config.parent, config.resolver)
		end,
		remoteEvent = function(name: string)
			return Boba.remoteEvent(name, config.parent, config.resolver)
		end,
		remoteFunction = function(name: string)
			return Boba.remoteFunction(name, config.parent, config.resolver)
		end,
		scopedReplicator = function<T>(name: string, data: T)
			return Boba.scopedReplicator(name, config.parent, data)
		end,
		globalReplicator = function<T>(name: string, data: T)
			return Boba.globalReplicator(name, config.parent, data)
		end,
	}
end

function Boba.unreliableRemoteEvent<C>(name: string, parent: Instance, resolver: Types.Resolver<C>)
	return function<A...>(args: (A...) -> ...any): RemoteEvent<C, A...>
		return Event.new(name, parent, resolver, castType(args), true)
	end
end

function Boba.remoteEvent<C>(name: string, parent: Instance, resolver: Types.Resolver<C>)
	return function<A...>(args: (A...) -> ...any): RemoteEvent<C, A...>
		return Event.new(name, parent, resolver, castType(args))
	end
end

function Boba.remoteFunction<C>(name: string, parent: Instance, resolver: Types.Resolver<C>)
	return function<A..., R...>(args: (A...) -> ...any, ret: (...any) -> R...): RemoteFunction<C, A..., R...>
		-- HACK: luau typesolver doesn't like this for some reason, returning `any`
		return Func.new(name, parent, resolver, castType(args), castType(ret)) :: any
	end
end

function Boba.scopedReplicator<T>(name: string, parent: Instance, initialData: T): LocalReplicator.LocalReplicator<T>
	return LocalReplicator.new(parent, name, initialData)
end

function Boba.globalReplicator<T>(name: string, parent: Instance, initialData: T): GlobablReplicator.GlobalReplicator<T>
	return GlobablReplicator.new(parent, name, initialData)
end

return Boba
