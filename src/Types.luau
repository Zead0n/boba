export type Resolver<T> = (T, ...any) -> (boolean, string?)

export type SyncLike = {
	sync: (SyncLike, number?) -> ...any,
}

export type Prediction = {
	replicator: SyncLike,
	predict: () -> (),
}

return {}
