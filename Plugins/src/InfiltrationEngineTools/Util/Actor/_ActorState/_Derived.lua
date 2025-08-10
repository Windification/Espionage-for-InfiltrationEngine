local Derived = {
	_Update = function(self)
		local values = {}
		for k, v in pairs(self._Dependencies) do
			values[k] = v._Value or false
		end
		local newValue = self._Eval(unpack(values))
		if newValue ~= self._Value then
			self._Value = newValue
			return true
		end
		return false
	end,
	_GetDependencies = function(self)
		return self._Dependencies
	end,
	_Init = function(self)
		if self._Initialized then return end
		self._Initialized = true
		for _, v in pairs(self._Dependencies) do
			v._Dependent[self] = true
			if v._Init then
				v:_Init()
			end
		end
		self:_Update()
	end
}
Derived.__index = Derived

return function(eval, ...)
	local self = {}
	self._StateType = "_Derived"
	self._Eval = eval
	self._Dependencies = {...}

	local priority = 0
	local temp = false
	for k, v in pairs(self._Dependencies) do
		priority = math.max(priority, v._Priority)
		temp = temp or v._Temp
	end

	self._Priority = priority + 1
	self._Temp = temp

	self._Dependent = {}
	self._Link = {}

	setmetatable(self, Derived)
	return self
end