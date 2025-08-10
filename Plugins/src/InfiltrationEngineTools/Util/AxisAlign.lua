local AxisAlign = {}

local VECTOR_UP = Vector3.new(0, 1, 0)

function AxisAlign.BestMatch(cfr, axis)
	local comp = axis or VECTOR_UP
	
	local v0, v1, v2 = cfr:VectorToWorldSpace(VECTOR_UP), cfr:VectorToWorldSpace(Vector3.new(1, 0, 0)), cfr:VectorToWorldSpace(Vector3.new(0, 0, 1))
	local d0, d1, d2 = v0:Dot(comp), v1:Dot(comp), v2:Dot(comp)
	
	if d0 < 0 then
		d0 = -d0
		v0 = -v0
	end
	if d1 < 0 then
		d1 = -d1
		v1 = -v1
	end
	if d2 < 0 then
		d2 = -d2
		v2 = -v2
	end
	
	if d1 > d0 then
		d1, d0 = d0, d1
		v1, v0 = v0, v1
	end
	if d2 > d0 then
		d2, d0 = d0, d2
		v2, v0 = v0, v2
	end
	
	return v0, v1, v2
end

function AxisAlign.CameraAlign(cfr, axis)
	local _, v0, v1 = AxisAlign.BestMatch(cfr, axis)
	
	local cam = workspace.CurrentCamera.CFrame.LookVector
	if math.abs(v1:Dot(cam)) > math.abs(v0:Dot(cam)) then
		v0 = v1
	end
	
	local flat = Vector3.new(v0.X, 0, v0.Z).Unit
	return flat, flat:Cross(VECTOR_UP)
end

return AxisAlign
