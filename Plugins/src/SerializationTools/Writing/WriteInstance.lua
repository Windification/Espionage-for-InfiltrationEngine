local StringConversion = require(script.Parent.Parent.StringConversion)
local InstanceProperties = require(script.Parent.Parent.Types.InstanceProperties)
local AttributeTypes = require(script.Parent.Parent.Types.AttributeTypes)
local AttributeValidation = require(script.Parent.Parent.AttributeValidation)

local WithAttributes = function(DefaultWriter)
	return function(object, Write, colorMap, stringMap)
		local str = DefaultWriter(object, Write, colorMap, stringMap)
		local attributes = object:GetAttributes()
		attributes = AttributeValidation.Validate(object.ClassName, object.Name, attributes, false)
		local attString = ""

		-- Encoding Attributes
		for i, v in pairs(attributes) do
			if i:match("^RBX_") then
				continue
			end

			local attributeType = typeof(v) -- Changing attribute type names to match as they are in the Write file
			if typeof(v) == "number" then
				if v ~= math.round(v) or v < 0 then
					attributeType = "Float"
				else
					attributeType = "LongInt"
				end
			elseif typeof(v) == "boolean" then
				attributeType = "bool"
			end
			attributeType = (string.upper(string.sub(attributeType, 1, 1)) .. string.sub(attributeType, 2, -1))
			if AttributeTypes[attributeType] == nil then -- if the attribute is not in the table, ignore it
				continue
			end

			local index = nil
			for ind, val in pairs(stringMap) do -- Check if the attribute is in the stringMap. use the index if it is
				if val == i then
					index = ind
					continue
				end
			end
			if index == nil then -- Otherwise, create a new value in the stringMap and use it
				stringMap[#stringMap + 1] = i
				index = #stringMap
			end
			attString = attString
				.. StringConversion.NumberToString(AttributeTypes[attributeType], 1)
				.. Write.ShortInt(index)

			if attributeType == "Color3" then
				local index = nil
				for ind, val in pairs(colorMap) do
					if v == val then
						index = ind
						continue
					end
				end
				if index == nil then
					colorMap[#colorMap + 1] = v
					index = #colorMap
				end
				attString = attString .. Write.ShortInt(index)
			elseif attributeType == "String" then
				local index = nil
				for ind, val in pairs(stringMap) do
					if val == v then
						index = ind
						continue
					end
				end
				if index == nil then
					stringMap[#stringMap + 1] = v
					index = #stringMap
				end
				attString = attString .. Write.ShortInt(index)
			else
				attString = attString .. Write[attributeType](v)
			end
		end
		str = str .. attString .. StringConversion.NumberToString(0, 1)
		return str, colorMap, stringMap
	end
end

local CreateInstanceWriter = function(properties)
	local WriteInstance = function(object, Write, colorMap, stringMap)
		local str = ""
		for i, v in pairs(properties) do
			local value
			if v[1] == "MeshId" and object.ClassName == "UnionOperation" then
				value = object:GetAttribute("MeshId")
			else
				value = object[v[1]]
			end
			local valueType = v[2]
			local defaultValue = v[3]
			if (valueType == "Color3") and (value ~= defaultValue) then
				local index = nil
				for i, v in pairs(colorMap) do
					if v == value then
						index = i
						continue
					end
				end
				if index == nil then
					colorMap[#colorMap + 1] = value
					index = #colorMap
				end
				str = str .. StringConversion.NumberToString(i, 1)
				str = str .. Write.ShortInt(index)
				continue
			elseif (valueType == "String") and (value ~= defaultValue) then
				local index = nil
				for i, v in pairs(stringMap) do
					if v == value then
						index = i
						continue
					end
				end
				if index == nil then
					stringMap[#stringMap + 1] = value
					index = #stringMap
				end
				str = str .. StringConversion.NumberToString(i, 1)
				str = str .. Write.ShortInt(index)
				continue
			elseif value ~= defaultValue then
				str = str .. StringConversion.NumberToString(i, 1)
				str = str .. Write[valueType](value)
			end
		end

		str = str .. StringConversion.NumberToString(0, 1)
		return str, colorMap, stringMap
	end
	return WriteInstance
end

local WriteInstance

WriteInstance = {
	Model = WithAttributes(CreateInstanceWriter(InstanceProperties.Model)),
	Folder = WithAttributes(CreateInstanceWriter(InstanceProperties.Folder)),
	Part = WithAttributes(CreateInstanceWriter(InstanceProperties.Part)),
	PartNoAttributes = CreateInstanceWriter(InstanceProperties.Part),
	BoolValue = WithAttributes(CreateInstanceWriter(InstanceProperties.BoolValue)),
	WedgePart = CreateInstanceWriter(InstanceProperties.WedgePart),
	StringValue = CreateInstanceWriter(InstanceProperties.StringValue),
	MeshPart = WithAttributes(CreateInstanceWriter(InstanceProperties.MeshPart)),
	UnionOperation = WithAttributes(CreateInstanceWriter(InstanceProperties.UnionOperation)),
	Texture = CreateInstanceWriter(InstanceProperties.Texture),
	BlockMesh = CreateInstanceWriter(InstanceProperties.BlockMesh),
	PointLight = CreateInstanceWriter(InstanceProperties.PointLight),
	SpotLight = CreateInstanceWriter(InstanceProperties.SpotLight),
	SurfaceLight = CreateInstanceWriter(InstanceProperties.SurfaceLight),
	SpecialMesh = CreateInstanceWriter(InstanceProperties.SpecialMesh),
	Decal = CreateInstanceWriter(InstanceProperties.Decal),
	Fire = CreateInstanceWriter(InstanceProperties.Fire),
	Smoke = CreateInstanceWriter(InstanceProperties.Smoke),
	Attachment = CreateInstanceWriter(InstanceProperties.Attachment),
}

return WriteInstance
