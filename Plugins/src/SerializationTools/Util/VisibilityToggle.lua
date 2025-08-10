local STASH_LINK_NAME = "StashLink"

local module = {}

module.GetStashRoot = function()
    local root = game.ReplicatedStorage:FindFirstChild("StashRoot")
    if not root then
        root = Instance.new("Folder")
        root.Name = "StashRoot"
        root.Parent = game.ReplicatedStorage
    end
    return root
end

module.Hide = function(part)
    if part:FindFirstChild(STASH_LINK_NAME) then
        return false
    end

    local originalParent = part.Parent
    part.Parent = module.GetStashRoot()
    local folder = Instance.new("Folder")
    folder.Parent = originalParent
    folder.Name = part.Name
    local link = Instance.new("ObjectValue")
    link.Value = part
    link.Name = STASH_LINK_NAME
    link.Parent = folder

    return folder
end

module.Reveal = function(part)
    local link = part:FindFirstChild(STASH_LINK_NAME)
    if not link then
        return false
    end

    local val = link.Value
    val.Parent = part.Parent
    part:Destroy()

    return val
end

module.IsHidden = function(part)
    return part:FindFirstChild(STASH_LINK_NAME) ~= nil
end

module.TempReveal = function(part)
    local revealed = module.Reveal(part)
    if revealed then
        revealed:SetAttribute("TempRevealed", true)
    end
end

module.HideTempRevealedParts = function(root)
    if not root then
        return
    end
    for _, part in root:GetChildren() do
        if part:GetAttribute("TempRevealed") then
            part:SetAttribute("TempRevealed", nil)
            module.Hide(part)
        end
    end
end

return module
