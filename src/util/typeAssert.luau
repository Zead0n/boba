return function(ok: boolean, err: string?, ...)
	if not ok then
		error(err or "Boba: Types does not match", 3)
	end

	return ...
end
