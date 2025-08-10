local AxisAlign = require(script.Parent.Parent.Util.AxisAlign)
local GetZone = require(script.Parent.GetZone)
local VisibilityToggle = require(script.Parent.Parent.Util.VisibilityToggle)

local UserInputService = game:GetService("UserInputService")

local MAX_PROJECT = 50
local SIZE_PADDING = 1
local POSITION_SINK = 0.3

local CellFolder
local Events = {}
local Ghost
local MouseDown = false

local GhostCfr
local GhostSize
local GhostMax
local GhostMin

local CastParams = RaycastParams.new()
local function GetProjectionDist(basePos, axis)
	local result = workspace:Raycast(basePos, axis * MAX_PROJECT, CastParams)
	if result then
		return (result.Position - basePos).magnitude
	else
		return MAX_PROJECT
	end
end

local function UpdateGhost(basePos, axis0, axis1)
	local z0, z1 = GetProjectionDist(basePos, axis0), GetProjectionDist(basePos, -axis0)
	local x0, x1 = GetProjectionDist(basePos, axis1), GetProjectionDist(basePos, -axis1)
	
	local pos = basePos + axis0 * (z0 - z1) / 2 + axis1 * (x0 - x1) / 2
	GhostCfr = CFrame.new(pos, pos + axis0)
	GhostSize = Vector3.new(x0 + x1, 0.2, z0 + z1)
	GhostMax = GetProjectionDist(basePos, Vector3.new(0, 1, 0))
	GhostMin = GetProjectionDist(basePos, Vector3.new(0, -1, 0))
	
	if GhostMax == MAX_PROJECT then
		GhostMax = GhostMax - GhostMin
	end
	
	Ghost.CFrame = GhostCfr
	Ghost.Size = GhostSize
end

local function ReoptimizeCells()
	print("Reoptimize cell floors")
	local LevelBase = workspace:FindFirstChild("DebugMission") or workspace:FindFirstChild("Level")
	for _, cell in pairs(LevelBase.Cells:GetChildren()) do
		if cell:IsA("Model") then
			local canFit = true
			local floorPart

			local baseRef = cell:FindFirstChild("Roof")
			local minX, maxX = baseRef.Position.X, baseRef.Position.X
			local minZ, maxZ = baseRef.Position.Z, baseRef.Position.Z

			for _, part in pairs(cell:GetChildren()) do
				if part.Name=="Roof" then
					for xo = -1, 1, 2 do
						for zo = -1, 1, 2 do
							local ref = part.CFrame:pointToWorldSpace(Vector3.new(part.Size.X * 0.5 * xo, 0, part.Size.Z * 0.5 * zo))
							minX = math.min(minX, ref.X)
							maxX = math.max(maxX, ref.X)
							minZ = math.min(minZ, ref.Z)
							maxZ = math.max(maxZ, ref.Z)
						end
					end
				elseif part.Name=="Floor" then
					if floorPart==nil then
						floorPart = part
					else
						canFit = false
						break
					end
				end
			end

			if floorPart and canFit then
				floorPart.Size = Vector3.new(maxX - minX, floorPart.Size.Y, maxZ - minZ)
				floorPart.CFrame = CFrame.new((maxX + minX)/2, floorPart.Position.Y, (maxZ + minZ)/2)
			end
		end
	end
end

local function ShowCells()
	for _, cell in pairs(CellFolder:GetChildren()) do
		for _, part in pairs(cell:GetChildren()) do
			part.Size = Vector3.new(part.Size.X, 1, part.Size.Z)
			part.Transparency = 0.5
			part.Locked = false
		end
	end
end

local function ShowLinks()
	for _, cell in pairs(CellFolder:GetChildren()) do
		if cell.Name ~= "Links" then continue end
		for _, part in pairs(cell:GetChildren()) do
			part.Size = Vector3.new(part.Size.X, 1, part.Size.Z)
			part.Transparency = 0.5
			part.Locked = false
		end
	end
end

local function HideCells()
	for _, cell in pairs(CellFolder:GetChildren()) do
		for _, part in pairs(cell:GetChildren()) do
			part.Size = Vector3.new(part.Size.X, 0, part.Size.Z)
			part.Transparency = 1
			part.Locked = true
		end
	end
end

local function HideNamedCells()
	for _, cell in pairs(CellFolder:GetChildren()) do
		if cell.Name ~= "Default" then
			for _, part in pairs(cell:GetChildren()) do
				part.Size = Vector3.new(part.Size.X, 0, part.Size.Z)
				part.Transparency = 1
				part.Locked = true
			end
		end
	end
end

local function hashName(name)
	if name == "Default" then
		return Color3.new(0, 0, 0)
	end
	
	local h = 5^7
	local n = 0
	for i = 1, #name do
		n = (n * 257 + string.byte(name, i, i)) % h 
	end
	local color = Color3.fromHSV((n % 1000) / 1000, 0.5, 0.5)
	return color
end

local function RecolorCells()
	for _, cell in pairs(CellFolder:GetChildren()) do
		local color = hashName(cell.Name)
		for _, part in pairs(cell:GetChildren()) do
			part.Color = color
		end
	end
end

local function CreateCell(mousePos)
	local cellModel = GetZone(mousePos)
	local addFloor = true
	
	if cellModel then
		addFloor = false
		print("Add to:", cellModel:GetFullName())
	else
		local LevelBase = workspace:FindFirstChild("DebugMission") or workspace:FindFirstChild("Level")
		print("Create new cell")
		cellModel = Instance.new("Model")
		cellModel.Name = "Default"
		cellModel.Parent = LevelBase.Cells
	end
	
	local roof = Ghost:Clone()
	roof.Size = roof.Size + Vector3.new(SIZE_PADDING * 2, 0.8, SIZE_PADDING * 2)
	roof.CFrame = GhostCfr * CFrame.new(0, GhostMax + POSITION_SINK, 0)
	roof.Name = "Roof"
	roof.Parent = cellModel
	roof.Anchored = true
	
	if addFloor then
		local floor = roof:Clone()
		floor.Name = "Floor"
		floor.CFrame = GhostCfr * CFrame.new(0, -GhostMin - POSITION_SINK, 0)
		floor.Parent = cellModel
		floor.Anchored = true
	else
		ReoptimizeCells()
	end
end

return {
	Init = function(mouse)
		if not workspace:FindFirstChild("Level") then
			local l = Instance.new("Folder")
			l.Name = "Level"
			l.Parent = workspace
		end
		local LevelBase = workspace:FindFirstChild("DebugMission") or workspace:FindFirstChild("Level")
		if not LevelBase:FindFirstChild("Cells") then
			local c = Instance.new("Folder")
			c.Name = "Cells"
			c.Parent = LevelBase
		end
		
		Ghost = Instance.new("Part")
		Ghost.Color = Color3.new(0, 0, 0)
		Ghost.Transparency = 0.5
		Ghost.Parent = LevelBase.Cells
		
		CellFolder = LevelBase.Cells
		mouse.TargetFilter = CellFolder
		CastParams.FilterType = Enum.RaycastFilterType.Blacklist
		CastParams.FilterDescendantsInstances = { CellFolder }
		
		Events[1] = game["Run Service"].RenderStepped:connect(function()
			if mouse.Target and not MouseDown then
				local v0, v1 = AxisAlign.CameraAlign(mouse.Target.CFrame)
				local origin = mouse.Hit.p - mouse.UnitRay.Direction * 0.5
				UpdateGhost(origin, v0, v1)
			end
		end)
		
		Events[2] = mouse.Button1Up:connect(function()
			CreateCell(mouse.Hit.p)
			MouseDown = false
		end)

		Events[3] = mouse.Button1Down:connect(function()
			MouseDown = true
		end)
		
		Events[3] = UserInputService.InputBegan:connect(function(io)
			if io.KeyCode == Enum.KeyCode.T then
				ReoptimizeCells()
			elseif io.KeyCode == Enum.KeyCode.G then
				ShowCells()
			elseif io.KeyCode == Enum.KeyCode.H then
				HideCells()
			elseif io.KeyCode == Enum.KeyCode.J then
				HideNamedCells()
			elseif io.KeyCode == Enum.KeyCode.K then
				RecolorCells()
			elseif io.KeyCode == Enum.KeyCode.L then
				ShowLinks()
			end
		end)

		VisibilityToggle.TempReveal(workspace.DebugMission.Cells)
		
		print([[T - Reoptimize Cell Floors
		G - Show All Cells
		H - Hide All Cells
		J - Hide Named Cells
		K - Recolor Cells
		L - Show Links]])
	end,
	Clean = function()
		if Events then
			for _, e in pairs(Events) do
				e:Disconnect()
			end
			Events = {}
		end
		if Ghost then
			Ghost:Destroy()
			Ghost = nil
		end
	end,
}