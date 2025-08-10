local toolbar = plugin:CreateToolbar("Mission Exporter")
local ExportButton = toolbar:CreateButton("Exporter", "Exporter", "rbxassetid://86828934223336")

local Exporter = require(script.Parent.Writing.Main)
local CurrentPlugin = nil

ExportButton.Click:Connect(function()
	if CurrentPlugin ~= Exporter then
		if CurrentPlugin then
			CurrentPlugin.Clean()
		end
		CurrentPlugin = Exporter
		plugin:Activate(true)
		Exporter.Init(plugin:GetMouse())
	else
		plugin:Deactivate()
	end
end)

local function disablePlugin()
	Exporter.Clean()
	CurrentPlugin = nil
end

plugin.Unloading:Connect(disablePlugin)
plugin.Deactivation:Connect(disablePlugin)
