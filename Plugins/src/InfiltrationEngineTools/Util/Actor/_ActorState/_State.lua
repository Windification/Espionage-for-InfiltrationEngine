local Update = require(script.Parent:WaitForChild("_Update"))

local State = {
	set = function(self, value)
		if self._Value == value then return end
		self._Value = value
		Update(self)
	end
}
State.__index = State

return function(value)
	local self = {}
	self._StateType = "_State"
	self._State = true
	self._Value = value
	self._Priority = 0
	self._Dependent = {}
	self._Link = {}
	self._Temp = false
	--setmetatable(self._Link, WEAK_KEYS)

	setmetatable(self, State)
	return self
end