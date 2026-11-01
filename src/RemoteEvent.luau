local assertWrapper = require(script.Parent.util.assertWrapper)
local fetchRemoteEvent = require(script.Parent.util.fetchRemoteEvent)
local fetchUnreliableRemoteEvent = require(script.Parent.util.fetchUnreliableRemoteEvent)
local Types = require(script.Parent.Types)

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

export type Event<C, A...> = typeof(setmetatable(
	{} :: {
		OnServerEvent: PlayerSignal<A...>,
		OnClientEvent: Signal<A...>,
		remote: RemoteEvent,
		_args: (...any) -> ...any,
	},
	Event
))

function Event.new<C, A...>(
	name: string,
	parent: Instance,
	resolver: Types.Resolver<C>,
	args: { C },
	unreliable: boolean?
): Event<C, A...>
	local remoteInstance: Instance = if unreliable
		then fetchUnreliableRemoteEvent(parent, name)
		else fetchRemoteEvent(parent, name)
	local remoteEvent: RemoteEvent = remoteInstance :: RemoteEvent

	local self = setmetatable({}, Event) :: Event<C, A...>

	self.OnServerEvent = remoteEvent.OnServerEvent
	self.OnClientEvent = remoteEvent.OnClientEvent

	self.remote = remoteEvent
	self._args = assertWrapper(resolver, args)

	return self
end

function Event.FireServer<C, A...>(self: Event<C, A...>, ...: A...)
	self.remote:FireServer(self._args(...))
end

function Event.FireClient<C, A...>(self: Event<C, A...>, player: Player, ...: A...)
	self.remote:FireServer(player, self._args(...))
end

function Event.FireAllClients<C, A...>(self: Event<C, A...>, ...: A...)
	self.remote:FireAllClients(self._args(...))
end

function Event.Destroy<C, A...>(self: Event<C, A...>)
	self.remote:Destroy()
end

return Event
