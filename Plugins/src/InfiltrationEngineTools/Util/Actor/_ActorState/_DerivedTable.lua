local DerivedTable = {
	_Update = function(self)
		local changed = false
		local input = self._Input._Value

		for k, v in pairs(input) do
			local li = self._LastInput[k]
			if v ~= li then
				changed = true
				if li and self.OnRemove then
					self.OnRemove(k, self._Value[k])
				end
				self._LastInput[k] = v
				self._Value[k] = self._Eval(k, v)
				if self.OnAdd then
					self.OnAdd(k, self._Value[k])
				end
			end
		end

		for k, v in pairs(self._LastInput) do
			if not input[k] then
				if self.OnRemove then
					self.OnRemove(k, self._Value[k])
				end
				self._LastInput[k] = nil
				changed = true
			end
		end

		return changed
	end,
	_GetDependencies = function(self)
		return { self._Input }
	end,
	_Init = function(self)
		if self._Initialized then return end
		self._Initialized = true
		self._Input._Dependent[self] = true
		if self._Input._Init then
			self._Input:_Init()
		end
		self:_Update()
	end
}
DerivedTable.__index = DerivedTable

return function(eval, input, onAdd, onRemove)
	local self = {}
	self._StateType = "_DerivedTable"
	self._DerivedTable = true
	self._Eval = eval
	self._Value = {}
	self._LastInput = {}
	self._Input = input
	self._Temp = input._Temp
	self._Priority = input._Priority + 1

	self.OnAdd = onAdd
	self.OnRemove = onRemove

	self._Dependent = {}
	self._Link = {}

	setmetatable(self, DerivedTable)
	return self
end