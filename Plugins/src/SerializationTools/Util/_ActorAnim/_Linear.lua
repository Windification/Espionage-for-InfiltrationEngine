local DEFAULT_LINEAR_TRANSITION_RATE = 4

local AnimRunner = require(script.Parent.Parent._ActorAnim._Anim)

local Cubic = {
	_Update = function(self)
		self.T = self._Follow._Value
		if self._Active then return true end
		AnimRunner:Start(self)
	end,
	_Step = function(self, dt)
		local shift = dt * self._Speed
		local done = false
		if math.abs(self.T - self.P) < shift then
			self.P = self.T
			done = true
		elseif self.P < self.T then
			self.P += shift
		else
			self.P -= shift
		end
		local a = self.P
		self._Value = a * a * (-2 * a + 3)
		return done
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
		local a = self._Follow._Value
		self.P = a -- Position
		self.T = a -- Target
		self._Value = a * a * (-2 * a + 3)
	end
}
Cubic.__index = Cubic

return function(follow, speed)
	local self = {}
	self._StateType = "_Cubic"
	self._Active = false
	self._Follow = follow
	self._Speed =  DEFAULT_LINEAR_TRANSITION_RATE
	if speed then
		self._Speed = self._Speed * speed
	end
	self._Temp = follow._Temp

	self._Priority = follow._Priority + 1
	self._Dependent = {}
	self._Link = {}

	setmetatable(self, Cubic)
	return self
end