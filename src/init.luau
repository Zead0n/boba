local Types = require(script.Types)

-- remotes
local Event = require(script.RemoteEvent)
local Func = require(script.RemoteFunction)

export type RemoteEvent<C, A...> = Event.Event<C, A...>
export type RemoteFunction<C, T..., R...> = Func.PseudoFunc<C, T..., R...>

-- replicators
local GlobablReplicator = require(script.GlobalReplicator)
local LocalReplicator = require(script.LocalReplicator)

export type PlayerReplicator<C, T, P> = LocalReplicator.LocalReplicator<C, T, P>
export type GlobalReplicator<C, T, P> = GlobablReplicator.GlobalReplicator<C, T, P>

export type PatchConfig<C, T, P> = Types.PatchConfig<C, T, P>

local Boba = {}

function Boba.define<C>(parent: Instance, resolver: Types.Resolver<C>)
	return {
		unreliableRemoteEvent = function(name: string)
			return Boba.unreliableRemoteEvent(name, parent, resolver)
		end,
		remoteEvent = function(name: string)
			return Boba.remoteEvent(name, parent, resolver)
		end,
		remoteFunction = function(name: string)
			return Boba.remoteFunction(name, parent, resolver)
		end,
		playerReplicator = function<T>(name: string)
			return Boba.playerReplicator(name, parent, resolver)
		end,
		globalReplicator = function<T>(name: string)
			return Boba.globalReplicator(name, parent, resolver)
		end,
	}
end

function Boba.unreliableRemoteEvent<C>(name: string, parent: Instance, resolver: Types.Resolver<C>)
	return function<A...>(...: A...): RemoteEvent<C, A...>
		local argTypes = table.pack(...) :: any
		argTypes.n = nil

		return Event.new(name, parent, resolver, argTypes, true)
	end
end

function Boba.remoteEvent<C>(name: string, parent: Instance, resolver: Types.Resolver<C>)
	return function<A...>(...: A...): RemoteEvent<C, A...>
		local argTypes = table.pack(...) :: any
		argTypes.n = nil

		return Event.new(name, parent, resolver, argTypes, false)
	end
end

function Boba.remoteFunction<C>(name: string, parent: Instance, resolver: Types.Resolver<C>)
	return function<A...>(...: A...)
		local argTypes = table.pack(...) :: any
		argTypes.n = nil

		return function<R...>(...: R...): RemoteFunction<C, A..., R...>
			local returnTypes = table.pack(...) :: any
			returnTypes.n = nil

			return Func.new(name, parent, resolver, argTypes, table.pack(...) :: any) :: any
		end
	end
end

function Boba.playerReplicator<C>(name: string, parent: Instance, resolver: Types.Resolver<C>)
	return function<T, P>(dataType: T, initialValue: T, patchConfig: Types.PatchConfig<C, T, P>?)
		return LocalReplicator.new(parent, name, initialValue, patchConfig)
	end
end

function Boba.globalReplicator<C>(name: string, parent: Instance, resolver: Types.Resolver<C>)
	return function<T, P>(dataType: T, initialValue: T, patchConfig: Types.PatchConfig<C, T, P>?)
		return GlobablReplicator.new(parent, name, initialValue, patchConfig)
	end
end

local net = Boba.define(script, function(any: any)
	return true
end)

local testEvent = net.remoteEvent("TestEvent")(45, "str")
local testFunc = net.remoteFunction("TestFunc")(54, "str")(true)

return Boba
