local VisibilityToggle = require(script.Parent.Parent.Util.VisibilityToggle)
local sections = { "Barrier", "Cells", "Nodes", "LoudSpawns", "CombatFlowMap" }

local cache = {}

return {
	OpenMenu = function(plugin)
		local menu = cache.Menu or plugin:CreatePluginMenu("SectionVisibilityMenu")
		cache.Menu = menu
		menu:Clear()

		for _, section in sections do
			local instance = workspace:FindFirstChild("DebugMission") and workspace.DebugMission:FindFirstChild(section)
			if not instance then
				continue
			end
			local hidden = VisibilityToggle.IsHidden(instance)
			local action = if hidden then "Show" else "Hide"
			local id = `SectionVisibility_{section}_{action}`
			local option = cache[id]
			if not option then
				option = plugin:CreatePluginAction(id, `{action} {section}`, "")
				option.Triggered:Connect(function()
					if hidden then
						VisibilityToggle.Reveal(workspace.DebugMission:FindFirstChild(section))
					else
						VisibilityToggle.Hide(workspace.DebugMission:FindFirstChild(section))
					end
				end)
				cache[id] = option
			end
			menu:AddAction(option)
		end

		if not cache.ShowAll then
			local ShowAll = plugin:CreatePluginAction("SectionVisibility_ShowAll", "Show All", "")
			ShowAll.Triggered:Connect(function()
				if not workspace:FindFirstChild("DebugMission") then
					return
				end
				for _, section in sections do
					local part = workspace.DebugMission:FindFirstChild(section)
					if part then
						VisibilityToggle.Reveal(part)
					end
				end
			end)
			local HideAll = plugin:CreatePluginAction("SectionVisibility_HideAll", "Hide All", "")
			HideAll.Triggered:Connect(function()
				if not workspace:FindFirstChild("DebugMission") then
					return
				end
				for _, section in sections do
					local part = workspace.DebugMission:FindFirstChild(section)
					if part then
						VisibilityToggle.Hide(part)
					end
				end
			end)

			cache.ShowAll = ShowAll
			cache.HideAll = HideAll
		end

		menu:AddAction(cache.ShowAll)
		menu:AddAction(cache.HideAll)
		menu:ShowAsync()
	end,
}
