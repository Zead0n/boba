export type Resolver<T> = (T, ...any) -> (boolean, string?)

export type SyncLike = {
	sync: (SyncLike) -> ...any,
}

export type Prediction = {
	replicator: SyncLike,
	predict: () -> (),
}

return {}
