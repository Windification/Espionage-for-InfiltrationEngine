local Watch = {
	_Update = function(self)
		local values = {}
		for k, v in pairs(self._Dependencies) do
			values[k] = v._Value or false
		end
		-- Make Watch Callback
        self._Eval(unpack(values))
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
Watch.__index = Watch

return function(eval, ...)
	local self = {}
	self._StateType = "_Watch"
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

	setmetatable(self, Watch)

    -- Unlike other state components, we want to init this one immediataly as it will never connect to an instance
    -- Any dependencies will never be released, only use this for debugging or if you're sure those state components don't need to be gced
    self:_Init()

	return self
end