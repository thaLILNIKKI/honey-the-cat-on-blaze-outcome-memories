_G.HoneySkinGameStateConnection = _G.HoneySkinGameStateConnection or nil
if _G.HoneySkinGameStateConnection then
	_G.HoneySkinGameStateConnection:Disconnect()
	_G.HoneySkinGameStateConnection = nil
	print("[Honey-da-catoni] Previous connection destroyed")
end

print("[Honey-da-catoni] Now loading... Made by lil2kki <3")

local honeyAssetId = "rbxassetid://96857029798216"
local honeyModel = game:GetObjects(honeyAssetId)[1]
if not honeyModel then warn("Failed to load Honey model from asset") return end

local function prepareHoneyModel()
    local model = honeyModel:Clone()
	
    for _, v in ipairs(model:GetDescendants()) do
        if v:IsA("Humanoid") then v:Destroy() end
    end

    local function find(obj, name) return obj:FindFirstChild(name, true) end
    local function rename(oldName, newName)
        local obj = find(model, oldName)
        while obj do
            print("renaming: "..obj.Name.." -> "..newName.." //"..obj.ClassName)
            obj.Name = newName
            obj = find(model, oldName)
        end 
    end

    rename("UpperBody", "MainBody")
    rename("RightShoulderPad", "RArm1")
    rename("RArm4", "RArm2")
    rename("LeftShoulderPad", "LArm1")
    rename("LArm4", "LArm2")
    rename("LFoot1", "LLeg1")
    rename("LFoot2", "LLeg2")
    rename("LFoot3", "LLeg3")

    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = false end
        if part:IsA("Motor6D") and (part.Name == "RArm1" or part.Name == "LArm1") then
            part:Destroy()
        end
    end

    local upperBody = find(model, "MainBody")
    local leftArm = find(model, "LArm1")
    local rightArm = find(model, "RArm1")

    if upperBody and leftArm then
        local newMotor = Instance.new("Motor6D")
        newMotor.Name = "LArm1"
        newMotor.Part0 = upperBody
        newMotor.Part1 = leftArm
        newMotor.C0 = CFrame.new(-0.6, 0.3, 0)
        newMotor.C1 = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(180), math.rad(-75))
        newMotor.Parent = leftArm
    end

    if upperBody and rightArm then
        local newMotor = Instance.new("Motor6D")
        newMotor.Name = "RArm1"
        newMotor.Part0 = upperBody
        newMotor.Part1 = rightArm
        newMotor.C0 = CFrame.new(0.6, 0.3, 0)
        newMotor.C1 = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(180), math.rad(45))
        newMotor.Parent = rightArm
    end

    local function setupHairStrand(hairMesh, boneRootName)
        if not hairMesh or not hairMesh:IsA("MeshPart") then return end
        
        game:GetService("CollectionService"):AddTag(hairMesh, "SmartBone")
        
        hairMesh:SetAttribute("Roots", boneRootName)
        
        hairMesh:SetAttribute("Damping", 2)
        hairMesh:SetAttribute("Stiffness", 0.7)
        hairMesh:SetAttribute("Elasticity", 2)
        hairMesh:SetAttribute("Inertia", 0.1)
        hairMesh:SetAttribute("Gravity", Vector3.new(0, -15, 0))
        hairMesh:SetAttribute("AnchorDepth", 1)
        hairMesh:SetAttribute("AnchorsRotate", true)
        
        game:GetService("CollectionService"):AddTag(model:FindFirstChild("Head", true), "SmartCollider")
    end
    setupHairStrand(find(model, "Hair1"), "Hair.R")
    setupHairStrand(find(model, "Hair2"), "Hair.L")

    return model
end

local blazePath = game:GetService("ReplicatedStorage"):FindFirstChild("Characters", true)
if not blazePath then warn("Characters folder not found") return end
blazePath = blazePath:FindFirstChild("Blaze", true)
if not blazePath then warn("Blaze folder not found") return end
local skins = blazePath:FindFirstChild("Skins", true)
if not skins then warn("Skins folder not found") return end

local oldDefault = skins:FindFirstChild("_OLD", true)
if oldDefault then
    warn(oldDefault:GetFullName())
    warn("Restoring original Blaze skin")
    local currentDefault = skins:FindFirstChild("Default", true)
    if currentDefault then currentDefault:Destroy() end
    oldDefault.Name = "Default"
end

local originalDefault = skins:FindFirstChild("Default", true)
if not originalDefault then warn("Default skin for Blaze not found") return end

local honeySkin = prepareHoneyModel()
honeySkin.Name = "Default"
honeySkin.Parent = skins

for _, obj in ipairs(originalDefault:GetChildren()) do
    if not honeySkin:FindFirstChild(obj.Name) then
        local cloned = obj:Clone()
        cloned.Parent = honeySkin
        if cloned:IsA("BasePart") then
			cloned.CanCollide = false
            cloned.Transparency = 1
            cloned.LocalTransparencyModifier = 1
    		cloned.Size = Vector3.new(0, 0, 0)
        	cloned.CFrame = CFrame.new(0, 0, 0)
        end
    end
end

originalDefault.Name = "_OLD"

print("Blaze skin replaced with Honey (Default)")

local function replaceCharacter(playerName)
    local playerModel = workspace:FindFirstChild("Players", true):FindFirstChild(playerName)
    if not playerModel then return end

    if playerModel:GetAttribute("Character") ~= "Blaze" then return end

    local honeySkinSrc = game:GetService("ReplicatedStorage"):FindFirstChild("Characters", true)
        :FindFirstChild("Blaze", true)
        :FindFirstChild("Skins", true)
        :FindFirstChild("Default", true)
    if not honeySkinSrc then
        warn("Honey skin not found in ReplicatedStorage")
        return
    end

	for _, v in ipairs(playerModel:GetDescendants()) do if v:IsA("BasePart") then
		v.Transparency = 1
	end end

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
    if not newHrp then mdl:Destroy() return end

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
    end)

    return playerModel
end

local function walkPlayers()
    task.wait(1)
    for _, model in ipairs(workspace:WaitForChild("Players"):GetChildren()) do
    	if not model:IsA("Model") then continue end
    	if model:GetAttribute("Character") ~= "Blaze" then continue end
    	replaceCharacter(model.Name)
    end
end

_G.HoneySkinGameStateConnection = workspace:WaitForChild("GameProperties"):WaitForChild("State").Changed:Connect(function(newState)
    if newState ~= "ING" then return end
	walkPlayers()
end)

walkPlayers()

print("[Honey-da-catoni] ready")
