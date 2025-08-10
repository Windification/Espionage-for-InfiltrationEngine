local PhysicsService = game:GetService("PhysicsService")

local COLLISON_GROUP = "PluginNoCollision"

local ModelFolder = game.ReplicatedStorage:FindFirstChild("Assets")
ModelFolder = ModelFolder and ModelFolder:FindFirstChild("Props")

local Button = require(script.Parent.Parent.Util.Button)

local Actor = require(script.Parent.Parent.Util.Actor)
local Create = Actor.Create
local State = Actor.State
local Derived = Actor.Derived
local DerivedTable = Actor.DerivedTable

local CustomPropsFolder = State(false)

local module = {}

local ColorMap = {}
local Prop = {}

-- Position/Color
function module:RepositionProp(part)
	local model = Prop[part]
	model = model and model.Model
	local base = model and model:FindFirstChild("Base", true)

	if not base then
		return
	end

	local diff = part.CFrame * base.CFrame:Inverse()
	for _, p in pairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.CFrame = diff * p.CFrame
		end
	end
end

function module:RecolorProp(part)
	local model = Prop[part]
	model = model and model.Model
	if not model then return end
	
	local index = 0	
	local search = true
	local colors = {}
	while true do
		local colour = part:GetAttribute("Color"..index)
		if colour then
			if typeof(colour) == "string" then
				colour = ColorMap[colour]
			end
			colors["Part"..index] = {
				Color = colour,
				Material = part:GetAttribute("Material"..index)
			}
			index += 1
		else
			break
		end
	end
	
	for _, p in pairs(model:GetDescendants()) do
		if p:IsA("BasePart") and colors[p.Name] then
			for prop, value in pairs(colors[p.Name]) do
				p[prop] = value
			end
		end
	end
end

-- Add/Remove

function module:AddProp(basePart)
	if not basePart:IsA("BasePart") then
		return
	end
	
	if Prop[basePart] then
		return
	end
	
	local storedModel = CustomPropsFolder._Value and CustomPropsFolder._Value:FindFirstChild(basePart.Name) or ModelFolder and ModelFolder:FindFirstChild(basePart.Name)
	if storedModel then
		basePart.Transparency = 1
		
		local model = storedModel:Clone()
		for _, p in pairs(model:GetDescendants()) do
			if p:IsA("BasePart") then
				p.Archivable = false
				p.CollisionGroup = COLLISON_GROUP
			end
		end
		
		Prop[basePart] = {
			Model = model,
			Events = {
				basePart:GetPropertyChangedSignal("CFrame"):Connect(function()
					self:RepositionProp(basePart)
				end),
				basePart.AttributeChanged:Connect(function()
					self:RecolorProp(basePart)
				end)
			}
		}
		model.Parent = self.Folder
		self:RepositionProp(basePart)
		self:RecolorProp(basePart)
	end
end

function module:RemoveProp(basePart)
	if basePart:IsA("BasePart") then
		basePart.Transparency = 0.5
	end
	
	local propData = Prop[basePart]
	if propData then
		propData.Model:Destroy()
		for _, event in pairs(propData.Events) do
			event:Disconnect()
		end
		Prop[basePart] = nil
	end
end

module.OverlaysEnabled = false
module.EnabledState = State(false)

function module:SetEnabled()
	if self.Enabled then return end
	self.Enabled = true

	if workspace.DebugMission:FindFirstChild("MissionSetup") then
		local missionData = require(workspace.DebugMission.MissionSetup:Clone())
		ColorMap = missionData.Colors or {}
	end
	
	module.Folder = workspace:FindFirstChild("PropPreviewModels") or Instance.new("Folder")
	module.Folder.Archivable = false
	module.Folder.Parent = workspace
	module.Folder.Name = "PropPreviewModels"

	PhysicsService:RegisterCollisionGroup(COLLISON_GROUP)
	PhysicsService:CollisionGroupSetCollidable("Default", COLLISON_GROUP, false)

	for _, prop in pairs(workspace.DebugMission.Props:GetDescendants()) do
		module:AddProp(prop)
	end
	
	local HiddenModel = nil
	
	module.AddEvents = {
		workspace.DebugMission.Props.ChildAdded:Connect(function(p)
			self:AddProp(p)
		end),
		workspace.DebugMission.Props.ChildRemoved:Connect(function(p)
			self:RemoveProp(p)
		end),
		game.Selection.SelectionChanged:Connect(function()
			if HiddenModel then
				HiddenModel.Parent = workspace
				HiddenModel = nil
			end
			local s = game.Selection:Get()
			if #s == 1 then
				local target = s[1]
				if Prop[target] then
					Prop[target].Model.Parent = nil
					HiddenModel = Prop[target].Model
				elseif target.ClassName == "Model" then
					for base, data in Prop do
						if data.Model == target then
							game.Selection:Set({ base })
						end
					end
				end
			end
		end)
	}
end

local SearchText = State("")
local SearchResults = Derived(function(text, customProps)
	local list = {}
	if ModelFolder then
		for _, item in pairs(ModelFolder:GetChildren()) do
			if string.lower(item.Name):match(string.lower(text)) then
				table.insert(list, item.Name)
			end
		end
		if customProps then
			for _, item in customProps:GetChildren() do
				if not ModelFolder:FindFirstChild(item.Name) and string.lower(item.Name):match(string.lower(text)) then
					table.insert(list, item.Name)
				end	
			end
		end
	end
	return list
end, SearchText, CustomPropsFolder)

function module:SetDisabled()
	if not self.Enabled then return end
	self.Enabled = false

	module.Folder:Destroy()
	
	for _, e in pairs(self.AddEvents) do
		e:Disconnect()
	end
	self.AddEvents = nil
	
	PhysicsService:RemoveCollisionGroup(COLLISON_GROUP)

	for _, prop in pairs(workspace.DebugMission.Props:GetChildren()) do
		module:RemoveProp(prop)
	end
end

-- Init/Cleanup
module.Init = function(mouse: PluginMouse)
	if module.Active then return end
	module.Active = true
	
	CustomPropsFolder:set(workspace:FindFirstChild("DebugMission") and workspace.DebugMission:FindFirstChild("CustomProps") or false)
	
	local searchBox
	searchBox = Create("TextBox", {
		PlaceholderText = "Search For Prop",
		Text = "",
		Size = UDim2.new(0, 300, 0, 30),
		Position = UDim2.new(0, 50, 0, 80),
		BorderSizePixel = 0,
		Changed = function()
			if searchBox then
				SearchText:set(searchBox.Text)
			end
		end,
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.5,
	})
	
	module.UI = Create("ScreenGui", {
		Parent = game.StarterGui,
		Archivable = false,
	}, {
		Button({
			Size = UDim2.new(0, 300, 0, 30),
			Enabled = module.EnabledState,
			Position = UDim2.new(0, 50, 0, 50),
			Text = Derived(function(e)
				return e and "Disable Prop Preview" or "Enable Prop Preview"
			end, module.EnabledState),
			Activated = function()
				module.OverlaysEnabled = not module.OverlaysEnabled
				module.EnabledState:set(module.OverlaysEnabled)
				if module.OverlaysEnabled then
					module:SetEnabled()
				else
					module:SetDisabled()
				end
			end,
		}),
		searchBox,
		Create("ScrollingFrame", {
			Size = UDim2.new(0, 300, 0.8, -100),
			Position = UDim2.new(0, 50, 0.9, 0),
			AnchorPoint = Vector2.new(0, 1),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1
		}, {
			Create("UIListLayout", {}),
			DerivedTable(function(index, value)
				return Button({
					Text = value,
					Enabled = State(false),
					Activated = function()
						local model = CustomPropsFolder._Value and CustomPropsFolder._Value:FindFirstChild(value) or ModelFolder[value]
						local base = model and model:FindFirstChild("Base")
						if base then 
							local prop = base:Clone()
							prop.Name = value
							prop.Transparency = 0.5
							prop.Parent = workspace.DebugMission.Props
							prop.CFrame = CFrame.new((workspace.CurrentCamera.CFrame * CFrame.new(0, 0, -5)).Position)
						end
					end,
					Size = UDim2.new(1, 0, 0, 30),
				})
			end, SearchResults)
		})
	})
end

module.Clean = function()
	if not module.Active then return end
	module.Active = false
	
	module.UI:Destroy()
	module.UI = nil	
end

return module
