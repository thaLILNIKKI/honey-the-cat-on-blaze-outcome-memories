print("[Honey-da-catoni] Now loading... Made by lil2kki <3")

local honeyAssetId = "rbxassetid://96857029798216"
local honeyModel = game:GetObjects(honeyAssetId)[1]
if not honeyModel then
    warn("Failed to load Honey model from asset")
    return
end

local function prepareHoneyModel()
    local model = honeyModel:Clone()
	
    for _, v in ipairs(model:GetDescendants()) do
        if v:IsA("Humanoid") then
            v:Destroy()
        end
    end

    local function find(obj, name)
        return obj:FindFirstChild(name, true)
    end
    local function rename(obj, newName)
        if obj and obj.Name ~= newName then
            obj.Name = newName
        end
    end

    rename(find(model, "UpperBody"), "MainBody")
    rename(find(model, "RightShoulderPad"), "RArm1")
    rename(find(model, "RArm4"), "RArm2")
    rename(find(model, "LeftShoulderPad"), "LArm1")
    rename(find(model, "LArm4"), "LArm2")
    rename(find(model, "LFoot1"), "LLeg1")
    rename(find(model, "LFoot2"), "LLeg2")
    rename(find(model, "LFoot3"), "LLeg3")

    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end

    return model
end

local replicatedStorage = game:GetService("ReplicatedStorage")
local blazePath = replicatedStorage:FindFirstChild("Characters", true)
if not blazePath then
    warn("Characters folder not found")
    return
end
blazePath = blazePath:FindFirstChild("Blaze", true)
if not blazePath then
    warn("Blaze folder not found")
    return
end
local skins = blazePath:FindFirstChild("Skins", true)
if not skins then
    warn("Skins folder not found")
    return
end

local oldDefault = skins:FindFirstChild("_OLD", true)
if oldDefault then
    warn("OLD_THERE_ALR - restoring original Blaze skin")
    local currentDefault = skins:FindFirstChild("Default", true)
    if currentDefault then currentDefault:Destroy() end
    oldDefault.Name = "Default"
end

local originalDefault = skins:FindFirstChild("Default", true)
if not originalDefault then
    warn("Default skin for Blaze not found")
    return
end

local honeySkin = prepareHoneyModel()
honeySkin.Name = "Default"
honeySkin.Parent = skins

for _, obj in ipairs(originalDefault:GetChildren()) do
    if not honeySkin:FindFirstChild(obj.Name) then
        local cloned = obj:Clone()
        cloned.Parent = honeySkin
        if cloned:IsA("BasePart") then
            cloned.Transparency = 1
            cloned.LocalTransparencyModifier = 1
            cloned.CFrame = CFrame.new(0, -99999, 0)
        end
    end
end

originalDefault.Name = "_OLD"

print("Blaze skin replaced with Honey (Default)")

local function replaceCharacter(playerName)
    local playerModel = workspace:FindFirstChild("Players", true):FindFirstChild(playerName)
    if not playerModel then return end

    if playerModel:GetAttribute("Character") ~= "Blaze" then return end

    local honeySkinSrc = replicatedStorage:FindFirstChild("Characters", true)
        :FindFirstChild("Blaze", true)
        :FindFirstChild("Skins", true)
        :FindFirstChild("Default", true)
    if not honeySkinSrc then
        warn("Honey skin not found in ReplicatedStorage")
        return
    end

    local hrp = playerModel:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local mdl = honeySkinSrc:Clone()
    mdl.Parent = playerModel

    for _, v in ipairs(mdl:GetDescendants()) do
        if v:IsA("Humanoid") then
            v:Destroy()
        elseif v:IsA("BasePart") then
            v.CanCollide = false
            v.Anchored = false
        end
    end

    local newHrp = mdl:FindFirstChild("HumanoidRootPart", true)
    if not newHrp then
        mdl:Destroy()
        return
    end

    local toRestoreTransparency = {}
    for _, part in ipairs(mdl:GetDescendants()) do
        if part:IsA("BasePart") then
            toRestoreTransparency[part] = part.Transparency
        end
    end

    local hrpOffset = Vector3.new(0, 0.52, 0)

    local syncConn
    syncConn = game:GetService("RunService").Heartbeat:Connect(function()
        if not mdl or not mdl.Parent then
            syncConn:Disconnect()
            replaceCharacter(playerName)
            return
        end

        if playerModel:GetAttribute("Character") ~= "Blaze" then
            syncConn:Disconnect()
            mdl:Destroy()
            return
        end

        newHrp.CFrame = hrp.CFrame + hrpOffset

        for _, v in ipairs(playerModel:GetDescendants()) do
            if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
                v.Transparency = 1
            end
        end

        for part, trans in pairs(toRestoreTransparency) do
            part.Transparency = trans
        end
    end)

    return playerModel
end

local function onPlayerModelAdded(model)
    if not model:IsA("Model") then return end
    task.wait(1)
    replaceCharacter(model.Name)
end

workspace:WaitForChild("GameProperties"):WaitForChild("State").Changed:Connect(function(newState)
    if newState ~= "ING" then return end
    task.wait(1)

    for _, model in ipairs(workspace:WaitForChild("Players"):GetChildren()) do
        onPlayerModelAdded(model)
    end
end)

print("[Honey-da-catoni] ready")
