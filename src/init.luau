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

export type PlayerReplicator<C, T, P> = LocalReplicator.LocalReplicator<C, T, P>
export type GlobalReplicator<C, T, P> = GlobablReplicator.GlobalReplicator<C, T, P>

local Tapioca = {}

function Tapioca.define<C>(parent: Instance, resolver: Types.Resolver<C>)
	return {
		unreliableRemoteEvent = function(name: string)
			return Tapioca.unreliableRemoteEvent(name, parent, resolver)
		end,
		remoteEvent = function(name: string)
			return Tapioca.remoteEvent(name, parent, resolver)
		end,
		remoteFunction = function(name: string)
			return Tapioca.remoteFunction(name, parent, resolver)
		end,
		playerReplicator = function<T>(name: string)
			return Tapioca.playerReplicator(name, parent, resolver)
		end,
		globalReplicator = function<T>(name: string)
			return Tapioca.globalReplicator(name, parent, resolver)
		end,
	}
end

function Tapioca.unreliableRemoteEvent<C>(name: string, parent: Instance, resolver: Types.Resolver<C>)
	return function<A...>(...: A...): RemoteEvent<C, A...>
		return Event.new(name, parent, resolver, castType(...), true)
	end
end

function Tapioca.remoteEvent<C>(name: string, parent: Instance, resolver: Types.Resolver<C>)
	return function<A...>(...: A...)
		return Event.new(name, parent, resolver, castType(...), false)
	end
end

function Tapioca.remoteFunction<C>(name: string, parent: Instance, resolver: Types.Resolver<C>)
	return function<A...>(...: A...)
		local argsType = castType(...)
		return function<R...>(...: R...)
			return Func.new(name, parent, resolver, argsType, castType(...))
		end
	end
end

function Tapioca.playerReplicator<C>(name: string, parent: Instance, resolver: Types.Resolver<C>)
	return function<T, P>(dataType: T, initialValue: T, patchConfig: Types.PatchConfig<C, T, P>)
		return LocalReplicator.new(parent, name, initialValue)
	end
end

function Tapioca.globalReplicator<C>(name: string, parent: Instance, resolver: Types.Resolver<C>)
	return function<T, P>(dataType: T, initialValue: T, patchConfig: Types.PatchConfig<C, T, P>)
		return GlobablReplicator.new(parent, name, initialValue)
	end
end

return Tapioca
