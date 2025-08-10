local TABLE = "table"
local SCRIPT_SIGNAL = "RBXScriptSignal"
local INST = "Instance"
local DEBUG = "Debug"
local TEMP_STATE = "TempState"

local HandleStateCleanup = require(script.Parent:WaitForChild("_HandleStateCleanup"))


local function processChildren(parent, item, stateLink)
	if typeof(item) == INST then
		item.Parent = parent
		return
	end
	if item._DerivedTable then
		item:_Init()
		item.OnAdd = function(_, instance)
			if typeof(instance) == INST then
				instance.Parent = parent
			end
		end
		item.OnRemove = function(_, instance)
			if typeof(instance) == INST then
				instance:Destroy()
			end
		end
		for _, instance in pairs(item._Value) do
			if typeof(instance) == INST then
				instance.Parent = parent
			end
		end
		if stateLink then
			table.insert(stateLink, item)
		end
	else
		for _, c in pairs(item) do
			processChildren(parent, c, stateLink)
		end
	end
end

return function(className, props, children, autoCleanup)
	local instance = Instance.new(className)

	local stateLink
	if autoCleanup then
		stateLink = {}
	end

	for name, value in pairs(props) do
		if name == DEBUG or name == TEMP_STATE then continue end

		if typeof(value) == TABLE then
			if value._StateType then
				value._Link[instance] = name
				if value._Init then
					value:_Init()
				end
				instance[name] = value._Value
				if autoCleanup then
					table.insert(stateLink, value)
				end
			end
		elseif typeof(name) == TABLE then
			if name._OnChange then
				local propName = name._Property
				instance:GetPropertyChangedSignal(propName):Connect(function() value(instance[propName]) end)
				value(props[propName] or instance[propName])
			end
		elseif typeof(instance[name]) == SCRIPT_SIGNAL then
			instance[name]:Connect(value)
		else
			instance[name] = value
		end
	end

	if children then
		processChildren(instance, children, autoCleanup and stateLink)
	end

	if autoCleanup and next(stateLink) then
		instance.AncestryChanged:Connect(function()
			if instance.Parent == nil then
				if props.Debug then
					warn("Cleanup:", props.Debug, stateLink)
				end
				for _, dep in pairs(stateLink) do
					dep._Link[instance] = nil
					HandleStateCleanup(dep)
				end
			end
		end)
	end

	return instance
end