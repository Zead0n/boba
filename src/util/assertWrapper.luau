local Types = require(script.Parent.Parent.Types)

return function<T>(resolver: Types.Resolver<T>)
	return function(matcher: any, ...)
		local ok, err = resolver(matcher, ...)
		if not ok then
			error(err or "Boba: unknown resolve", 4)
		end

		return ...
	end
end
