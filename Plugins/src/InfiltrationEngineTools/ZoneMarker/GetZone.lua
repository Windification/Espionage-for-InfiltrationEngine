return function(pos)
	local LevelBase = workspace:FindFirstChild("DebugMission") or workspace:FindFirstChild("Level")
	for _, zone in pairs(LevelBase.Cells:GetChildren()) do
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
					return zone
				end
			end
		end
	end
end