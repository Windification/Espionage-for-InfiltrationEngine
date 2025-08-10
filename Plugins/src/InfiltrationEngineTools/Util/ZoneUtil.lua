local ZoneUtil = {}

function ZoneUtil.InZone(zone, pos)
	local floorMatch = zone:FindFirstChild("Floor") == nil
	local roofMatch = false

	for _, part in pairs(zone:GetChildren()) do
		local rel = part.CFrame:PointToObjectSpace(pos)

		if math.abs(rel.X) <= part.Size.X / 2 and math.abs(rel.Z) <= part.Size.Z / 2 then
			if part.Name == "Roof" and rel.Y <= 0 then
				roofMatch = true
			elseif part.Name == "Floor" and rel.Y >= 0 then
				floorMatch = true
			end

			if floorMatch and roofMatch then
				return true
			end
		end
	end
	
	return false
end

function ZoneUtil.GetZone(pos)
	local LevelBase = workspace:FindFirstChild("DebugMission") or workspace:FindFirstChild("Level")
	for _, zone in pairs(LevelBase.Cells:GetChildren()) do
		if ZoneUtil.InZone(zone, pos) then
			return zone
		end
	end
end

return ZoneUtil