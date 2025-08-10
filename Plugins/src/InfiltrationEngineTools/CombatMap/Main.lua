local HttpService = game:GetService("HttpService")
local VisibilityToggle = require(script.Parent.Parent.Util.VisibilityToggle)

local module = {}

local DrawnModel = nil
local ClickConnection = nil
local CurrentMap = nil

local BLUE = Color3.fromRGB(110, 153, 202)
local BLACK = Color3.fromRGB(0, 0, 0)
local WHITE = Color3.new(1, 1, 1)

local function DrawLine(p0, p1, color)
	local p = Instance.new("Part")
	p.Size = Vector3.new(1, 1, (p0 - p1).Magnitude)
	p.CFrame = CFrame.new((p0 + p1) / 2, p0)
	p.Color = color
	p.CastShadow = false
	return p
end

local function LinkId(id0, id1)
	if id0 < id1 then
		return id0 .. "|" .. id1
	end
	return id1 .. "|" .. id0
end

function module.Init(mouse: PluginMouse)
	if module.Active then
		return
	end
	module.Active = true

	if workspace.DebugMission:FindFirstChild("CombatFlowMap") then
		VisibilityToggle.TempReveal(workspace.DebugMission.CombatFlowMap)
	end

	local function RedrawMap(id)
		if DrawnModel then
			DrawnModel:Destroy()
			DrawnModel = nil
		end

		DrawnModel = Instance.new("Model")
		DrawnModel.Parent = workspace

		local part = CurrentMap[id]
		local used = {}
		local blocked = part:GetAttribute("BlockedLinks") or "{}"
		blocked = game:GetService("HttpService"):JSONDecode(blocked)

		local FilteredLinks = {}

		local distLeft = {
			[id] = 3,
		}
		local expandFrom = { id }

		while #expandFrom > 0 do
			local checkId = expandFrom[1]
			table.remove(expandFrom, 1)

			local part = CurrentMap:FindFirstChild(checkId)
			local linkTo = HttpService:JSONDecode(part:GetAttribute("LinkedIds"))

			for _, targetId in linkTo do
				local linkName = LinkId(checkId, targetId)

				local linkPart = CurrentMap:FindFirstChild(targetId)
				local p = DrawLine(part.Position, linkPart.Position, Color3.new(0, 0, 0.8), BLUE)
				p.Parent = DrawnModel
				p.Name = linkName

				if blocked[linkName] then
					p.Color = BLACK
				else
					table.insert(FilteredLinks, targetId)
					if distLeft[checkId] > 1 and not distLeft[targetId] then
						table.insert(expandFrom, targetId)
					end
				end
				distLeft[targetId] = distLeft[checkId] - 1
			end
		end

		part:SetAttribute("FilteredLinks", HttpService:JSONEncode(FilteredLinks))
		part.Color = BLACK
	end

	ClickConnection = mouse.Button1Down:Connect(function(target)
		local part = mouse.Target
		if part:IsDescendantOf(workspace.DebugMission.CombatFlowMap) then
			CurrentMap = part.Parent
			for _, p in CurrentMap:GetChildren() do
				p.Name = p:GetAttribute("Id")
			end

			local id = part:GetAttribute("Id")
			game.Selection:Set({ part })

			RedrawMap(id)
		elseif part.Name:match("|") and #part.Name == 73 then
			local node = game.Selection:Get()[1]
			local blocked = node:GetAttribute("BlockedLinks") or "{}"
			blocked = game:GetService("HttpService"):JSONDecode(blocked)

			blocked[part.Name] = if not blocked[part.Name] then true else nil

			node:SetAttribute("BlockedLinks", HttpService:JSONEncode(blocked))
			RedrawMap(node.Name)
		else
			local id0, id1 = part.Name:match("|")

			if DrawnModel then
				DrawnModel:Destroy()
				DrawnModel = nil
			end
		end
	end)
end

function module.Clean()
	if DrawnModel then
		DrawnModel:Destroy()
		DrawnModel = nil
	end

	if ClickConnection then
		ClickConnection:Disconnect()
		ClickConnection = nil
	end

	module.Active = false
end

return module
