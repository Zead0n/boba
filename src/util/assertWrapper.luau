local resolverType = require(script.Parent.resolverType)

return function(resolver: resolverType.Resolver)
	return function(matcher: any, ...)
		local ok, err = resolver(matcher, ...)
		if not ok then
			error(err or "Boba: unknown resolve", 4)
		end

		return ...
	end
end
