return function(base)
	local list = {}

	for instance, prop in pairs(base._Link) do
		instance[prop] = base._Value
	end

	for dep in pairs(base._Dependent) do
		list[dep] = true
	end

	local best = next(list)
	while best do
		local priority = best._Priority
		for dep in pairs(list) do
			if dep._Priority < priority then
				best = dep
				priority = best._Priority
			end
		end
		list[best] = nil

		if best:_Update() then -- this updated and we need to change it's dependencies
			for instance, prop in pairs(best._Link) do
				instance[prop] = best._Value
			end
			for dep in pairs(best._Dependent) do
				list[dep] = true
			end
		end

		best = next(list)
	end
end