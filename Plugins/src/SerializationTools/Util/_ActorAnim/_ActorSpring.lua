local AnimRunner = require(script.Parent._Anim)

local numberClose = function(x, y)
	return math.abs(x - y) < 0.01
end
local vectorClose = function(x, y)
	return (x - y).magnitude < 0.01
end
local udim2Close = function(x, y)
	local rel = x - y
	return math.abs(rel.X.Offset) <= 1 and math.abs(rel.Y.Offset) <= 1 and math.abs(rel.X.Scale) < 0.01 and math.abs(rel.Y.Scale) < 0.01 
end

local function getStartingVelocityByType(value)
	if typeof(value) == "number" then
		return 0, numberClose
	elseif typeof(value) == "Vector3" then
		return Vector3.new(), vectorClose
	--elseif typeof(value) == "UDim2" then
	--	return UDim2.new(), udim2Close
	end
end

local Spring = {
	_Update = function(self)
		self.T = self._Follow._Value
		if self._Active then return true end
		AnimRunner:Start(self)
	end,
	_Step = function(self, dt)
		if self._IsClose(self._Value, self.T) then
			self._Value = self.T
			return true
		end
		if dt > 0.03 then dt = 0.03 end
		local accel = (self.T - self._Value) * self._Force - self.V * self._Damping
		local vel = self.V
		self.V = self.V + accel * dt * self._Speed
		self._Value = self._Value + (self.V + vel) * dt * 0.5 * self._Speed
		return false
	end,
	_GetDependencies = function(self)
		return { self._Follow }
	end,
	_Init = function(self)
		if self._Initialized then return end
		self._Initialized = true
		self._Follow._Dependent[self] = true
		if self._Follow._Init then
			self._Follow:_Init()
		end
		self._Value = self._Follow._Value -- Position
		self.T = self._Follow._Value -- Target
		self.V, self._IsClose = getStartingVelocityByType(self._Follow._Value)
	end
}
Spring.__index = Spring

return function(follow, force, damping, speed)
	local self = {}
	self._StateType = "_Spring"
	self._Active = false
	self._Follow = follow
	self._Force = force or 50
	self._Damping = damping or 10
	self._Speed = speed or 1
	self._Temp = follow._Temp

	self._Priority = follow._Priority + 1
	self._Dependent = {}
	self._Link = {}

	setmetatable(self, Spring)
	return self
end