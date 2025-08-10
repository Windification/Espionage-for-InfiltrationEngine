local cleanup
cleanup = function(state)
	if state.Debug then
		warn(state.Debug, state._Temp, state._GetDependencies ~= nil, next(state._Dependent), next(state._Link))
	end
	if not state._Persist and state._GetDependencies and not next(state._Dependent) and not next(state._Link) then
		if state.Debug then
			warn("Cleanup", state.Debug, state:_GetDependencies())
		end
		state._Initialized = false
		for _, dep in pairs(state:_GetDependencies()) do
			dep._Dependent[state] = nil
			cleanup(dep)
		end
	end
end

return cleanup