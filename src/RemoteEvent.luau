local fetchRemoteEvent = require(script.Parent.util.fetchRemoteEvent)
local resolverType = require(script.Parent.util.resolverType)

type Signal<A...> = {
	Connect: (self: Signal<A...>, fn: (A...) -> ()) -> RBXScriptConnection,
	ConnectParallel: (self: Signal<A...>, fn: (A...) -> ()) -> RBXScriptConnection,
	Once: (self: Signal<A...>, fn: (A...) -> ()) -> RBXScriptConnection,
	Wait: (self: Signal<A...>) -> A...,
}

type PlayerSignal<A...> = {
	Connect: (self: PlayerSignal<A...>, fn: (player: Player, A...) -> ()) -> RBXScriptConnection,
	ConnectParallel: (self: PlayerSignal<A...>, fn: (player: Player, A...) -> ()) -> RBXScriptConnection,
	Once: (self: PlayerSignal<A...>, fn: (player: Player, A...) -> ()) -> RBXScriptConnection,
	Wait: (self: PlayerSignal<A...>) -> (Player, A...),
}

local Event = {}
Event.__index = Event

export type Event<A...> = typeof(setmetatable(
	{} :: {
		OnServerEvent: PlayerSignal<A...>,
		OnClientEvent: Signal<A...>,
		remote: RemoteEvent,
		_resolver: resolverType.Resolver,
		_args: (A...) -> A...,
	},
	Event
))

function Event.new<A...>(name: string, parent: Instance, resolver: resolverType.Resolver, args: (A...) -> A...): Event<A...>
	local remoteEvent = fetchRemoteEvent(parent, name)

	local self = setmetatable({}, Event) :: Event<A...>

	self.OnServerEvent = remoteEvent.OnServerEvent
	self.OnClientEvent = remoteEvent.OnClientEvent

	self.remote = remoteEvent
	self._resolver = resolver
	self._args = args

	return self
end

function Event.FireServer<T, A...>(self: Event<A...>, ...: A...)
	local ok, err = self._resolver(self._args, ...)
	if not ok then
		error(err)
	end

	self.remote:FireServer(...)
end

function Event.FireClient<T, A...>(self: Event<A...>, player: Player, ...: A...)
	local ok, err = self._resolver(self._args, ...)
	if not ok then
		error(err)
	end

	self.remote:FireClient(player, ...)
end

function Event.FireAllClients<T, A...>(self: Event<A...>, ...: A...)
	local ok, err = self._resolver(self._args, ...)
	if not ok then
		error(err)
	end

	self.remote:FireAllClients(...)
end

function Event.Destroy(self: Event<...any>)
	self.remote:Destroy()
end

return Event
