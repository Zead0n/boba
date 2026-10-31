export type Resolver<T> = (T, ...any) -> (boolean, string?)

export type SyncLike = {
	sync: (SyncLike, number?) -> ...any,
}

export type Prediction = {
	replicator: SyncLike,
	predict: () -> (),
}

export type PatchConfig<C, T, P> = {
	patchType: C?,
	diff: (T, T) -> P,
	apply: (T, P) -> T,
}

return {}
