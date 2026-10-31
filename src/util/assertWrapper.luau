local Types = require(script.Parent.Parent.Types)

local function assertArgsWrapper<T>(resolver: Types.Resolver<T>)
	return function(argMatchers: { T }, ...: any)
		local args = table.pack(...)

		for idx = 1, args.n do
			local argMatcher = argMatchers[idx]
			if not argMatcher then
				continue
			end

			local arg = args[idx]
			local ok, err = resolver(argMatcher, arg)
			if not ok then
				error(err or "Unknown resolve", 4)
			end
		end

		return ...
	end
end

return function<T>(resolver: Types.Resolver<T>)
	return function(matcher: any, ...)
		local ok, err = resolver(matcher, ...)
		if not ok then
			error(err or "unknown resolve", 4)
		end

		return ...
	end
end
