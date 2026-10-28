local resolverType = require(script.util.resolverType)

-- remotes
local Event = require(script.RemoteEvent)
local Func = require(script.RemoteFunction)

export type RemoteEvent<A...> = Event.Event<A...>
export type RemoteFunction<T..., R...> = Func.Func<T..., R...>

-- replicators
local GlobablReplicator = require(script.GlobablReplicator)
local LocalReplicator = require(script.LocalReplicator)

export type ScopedReplicator<T> = LocalReplicator.LocalReplicator<T>
export type GlobalReplicator<T> = GlobablReplicator.GlobalReplicator<T>

local Boba = {}

function Boba.define<T>(config: {
	parent: Instance,
	resolver: resolverType.Resolver,
})
	return {
		remoteEvent = function(name: string)
			return Boba.remoteEvent(name, config.resolver, config.parent)
		end,
		remoteFunction = function(name: string)
			return Boba.remoteFunction(name, config.resolver, config.parent)
		end,
		scopedReplicator = function<T>(name: string, data: T)
			return Boba.scopedReplicator(name, config.parent, data)
		end,
		globalReplicator = function<T>(name: string, data: T)
			return Boba.globalReplicator(name, config.parent, data)
		end,
	}
end

function Boba.remoteEvent(name: string, resolver: resolverType.Resolver, parent: Instance?)
	return function<A...>(args: (A...) -> ...any): RemoteEvent<A...>
		return Event.new(name, parent or script, resolver, args)
	end
end

function Boba.remoteFunction(name: string, resolver: resolverType.Resolver, parent: Instance?)
	return function<A..., R...>(args: (A...) -> ...any, ret: (...any) -> R...): RemoteFunction<(A...), (R...)>
		return Func.new(name, parent or script, resolver, args, ret)
	end
end

function Boba.scopedReplicator<T>(name: string, parent: Instance, initialData: T): LocalReplicator.LocalReplicator<T>
	return LocalReplicator.new(parent, name, initialData)
end

function Boba.globalReplicator<T>(name: string, parent: Instance, initialData: T): GlobablReplicator.GlobalReplicator<T>
	return GlobablReplicator.new(parent, name, initialData)
end

return Boba
