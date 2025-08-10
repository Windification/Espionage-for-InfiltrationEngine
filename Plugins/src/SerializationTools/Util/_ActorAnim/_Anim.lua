local RunService = game:GetService("RunService")
local Update = require(script.Parent.Parent._ActorState._Update)

local Anim = {}
Anim._List = {}
Anim._Active = false

function Anim:Start(data)
	self._List[data] = true
	data._Active = true
	if self._Active then return end
	self._Active = true
	self._StepEvent = RunService.RenderStepped:Connect(function(dt)
		for data in pairs(self._List) do
			if data:_Step(dt) then
				self._List[data] = nil
				data._Active = false
			end
			Update(data)
		end
		if not next(self._List) then
			self._Active = false
			self._StepEvent:Disconnect()
			self._StepEvent = nil
		end
	end)
end

return Anim