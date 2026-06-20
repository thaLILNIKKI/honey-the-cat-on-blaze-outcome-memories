print("[Honey-da-catoni] Now loading... Made by lil2kki <3")
print("[Honey-da-catoni] Model used: https://create.roblox.com/store/asset/96857029798216")
print("[Honey-da-catoni] Original script (where i took asset id): https://scriptblox.com/script/Outcome-Memories-v0.2-HONEY-da-cat-honey-honey-da-cat-FOR-blAZE-153452")

-- idk if thats helps
local function makeWeakRef(obj) return setmetatable({obj = obj}, {__mode = "v"}) end

-- MODEL SETUP IN ReplicatedStorage (for UI and overlay ref)

    -- tar
    local tar = game:GetService("ReplicatedStorage")
    tar = tar:FindFirstChild("Characters", true)
    tar = tar:FindFirstChild("Blaze", true)
    tar = tar:FindFirstChild("Skins", true)

    local OLD_THERE_ALR = tar:FindFirstChild("_OLD", true)
    if OLD_THERE_ALR then
        warn("[Honey-da-catoni] Restoring original skin")
        tar:FindFirstChild("Default", true):Destroy()
        OLD_THERE_ALR.Name = "Default"
    end

    tar = tar:FindFirstChild("Default", true)

    -- src
    local src = game:GetObjects("rbxassetid://96857029798216")[1]

    -- model setup
    local model = src:Clone()

    src:Destroy()

    model.Name = tar.Name
    model.Parent = tar.Parent

    tar.Name = "_OLD"

    local function find(name) return model:FindFirstChild(name, true) end

    -- rename parts
    local function rename(oldName, newName)
        local obj = find(oldName)
        while obj do
            -- print("renaming: "..obj.Name.." -> "..newName.." //"..obj.ClassName)
            obj.Name = newName
            obj:SetAttribute("rename_oldName", oldName)
            obj:SetAttribute("rename_newName", newName)
            obj = find(oldName)
        end 
    end
        rename("Torso", "MainBody")
        rename("UpperBody", "MainBody")
        rename("RightShoulderPad", "RArm1")
        rename("RArm4", "RArm2")
        rename("LeftShoulderPad", "LArm1")
        rename("LArm4", "LArm2")
        rename("LFoot1", "LLeg1")
        rename("LFoot2", "LLeg2")
        rename("LFoot3", "LLeg3")
    --

    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = false end
        if part:IsA("Motor6D") and (part.Name == "RArm1" or part.Name == "LArm1") then
            part:Destroy()
        end
    end


    local upperBody = find("MainBody")
    local leftArm = find("LArm1")
    local rightArm = find("RArm1")

    if upperBody and leftArm then
        local newMotor = Instance.new("Motor6D")
        newMotor.Name = "LArm1"
        newMotor.Part0 = upperBody
        newMotor.Part1 = leftArm
        newMotor.C0 = CFrame.new(0.6, 0.3, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-50))
        newMotor.C1 = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0))
        newMotor.Parent = leftArm
    end

    if upperBody and rightArm then
        local newMotor = Instance.new("Motor6D")
        newMotor.Name = "RArm1"
        newMotor.Part0 = upperBody
        newMotor.Part1 = rightArm
        newMotor.C0 = CFrame.new(-0.6, 0.3, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(50))
        newMotor.C1 = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0))
        newMotor.Parent = rightArm
    end

    local function setupHairStrand(hairMesh, boneRootName)
        if not hairMesh or not hairMesh:IsA("MeshPart") then return end
        
        game:GetService("CollectionService"):AddTag(hairMesh, "SmartBone")
        
        hairMesh:SetAttribute("Roots", boneRootName)
        
        hairMesh:SetAttribute("Damping", 2)
        hairMesh:SetAttribute("Stiffness", 0.7)
        hairMesh:SetAttribute("Elasticity", 2)
        hairMesh:SetAttribute("Inertia", 122)
        hairMesh:SetAttribute("Gravity", Vector3.new(0, -222, 0))
        hairMesh:SetAttribute("AnchorsRotate", true)
        hairMesh:SetAttribute("AnchorDepth", 1)
        
        game:GetService("CollectionService"):AddTag(model:FindFirstChild("Head", true), "SmartCollider")
    end
    setupHairStrand(find("Hair1"), "Hair.R")
    setupHairStrand(find("Hair2"), "Hair.L")

    local tailm = find("TailEnd")
    if tailm then
        game:GetService("CollectionService"):AddTag(tailm, "SmartBone")
        
        tailm:SetAttribute("Roots", "Tail")
        
        tailm:SetAttribute("Damping", 1)
        tailm:SetAttribute("Stiffness", 0.5)
        tailm:SetAttribute("Elasticity", 1)
        tailm:SetAttribute("Inertia", 666)
        tailm:SetAttribute("Gravity", Vector3.new(0, -22, 0))
        tailm:SetAttribute("AnchorsRotate", true)
        tailm:SetAttribute("AnchorDepth", 1)
        
        game:GetService("CollectionService"):AddTag(model:FindFirstChild("Waist", true), "SmartCollider")
    end

    print("[Honey-da-catoni] Model setup done...")
--

-- FUCKING SERVER SIDED PLAYER BUILD HOLY HELL
    local function updatePlayer(name)

        local player = workspace.Players:FindFirstChild(name)
        if not player then return end

        if player:GetAttribute("Character") ~= "Blaze" then return end

        print("[Honey-da-catoni] Updating model for " .. player.Name .. "...")

        if player:FindFirstChild("OverlayModel") then return end
        
        local hrp = player:FindFirstChild("HumanoidRootPart", true)
        if not hrp then return end

        local ogHead = player:FindFirstChildOfClass("Motor6D", true)

        for _, v in ipairs(player:GetDescendants()) do
            if v:IsA("Motor6D") and v.Name == "Head" then ogHead = v end
            if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
                v.Transparency = 1
                v.LocalTransparencyModifier = 1
            end
        end
        
        local src = game:GetService("ReplicatedStorage")
        src = src:FindFirstChild("Characters", true)
        src = src:FindFirstChild("Blaze", true)
        src = src:FindFirstChild("Skins", true)
        src = src:FindFirstChild("Default", true)

        local mdl = src:Clone()
        mdl.Parent = player
        mdl.Name = "OverlayModel"

        local newHrp = mdl:FindFirstChild("HumanoidRootPart", true)
        if not newHrp then mdl:Destroy() return end

        local myHead = mdl:FindFirstChildOfClass("Motor6D", true)

        for _, v in ipairs(mdl:GetDescendants()) do
            if v:IsA("Motor6D") and v.Name == "Head" then myHead = v end
            if v:IsA("Humanoid") then v:Destroy() end
            if v:IsA("Animator") then v:Destroy() end
            if v:IsA("BasePart") then
                v.CanCollide = false
            end
        end

        local mdlRef = makeWeakRef(mdl)
        local hrpRef = makeWeakRef(hrp)
        local newHrpRef = makeWeakRef(newHrp)
        local myHeadRef = makeWeakRef(myHead)
        local ogHeadRef = makeWeakRef(ogHead)
        local playerRef = makeWeakRef(player)

        coroutine.wrap(function()
        
            while true do
                local mdlCheck = mdlRef.obj
                local hrpCheck = hrpRef.obj
                local newHrpCheck = newHrpRef.obj
                local myHeadCheck = myHeadRef.obj
                local ogHeadCheck = ogHeadRef.obj
                local playerCheck = playerRef.obj

                if not mdlCheck or not mdlCheck.Parent or not hrpCheck or not newHrpCheck then
                    warn("[Honey-da-catoni] Player model fucked idk")
                    break
                end

                newHrpCheck:PivotTo(hrpCheck.CFrame * CFrame.new(0,  0.52, 0))
                myHeadCheck.C0 = CFrame.new(myHeadCheck.C0.Position) * (ogHeadCheck.C0 - ogHeadCheck.C0.Position)

                task.wait() -- heartbeat mayb
            end

            warn("[Honey-da-catoni] Model destroyed, trying to restart overlay")
            updatePlayer(name)

        end)()

    end

    local function tryUpdatePlayerModel(model)
        if model:GetAttribute("Character") ~= "Blaze" then return end
        updatePlayer(model.Name)
    end
--

-- all players
    local function walkPlayers()
        task.wait(1)
        for _, model in ipairs(workspace.Players:GetChildren()) do
            if not model:IsA("Model") then continue end
            if model.Name == game.Players.LocalPlayer.Name then continue end
            tryUpdatePlayerModel(model)
        end
    end

    walkPlayers()

    _G.HoneyBlazeSkinGameStateConn = _G.HoneyBlazeSkinGameStateConn or nil
    if _G.HoneyBlazeSkinGameStateConn then
        _G.HoneyBlazeSkinGameStateConn:Disconnect()
        _G.HoneyBlazeSkinGameStateConn = nil
        print("[Honey-da-catoni] Previous game state connection destroyed")
    end
    _G.HoneyBlazeSkinGameStateConn = workspace:WaitForChild("GameProperties"):WaitForChild("State").Changed:Connect(function(newState)
        if newState == "ING" then walkPlayers() end
    end)
--

-- my char
    _G.HoneyBlazeSkinCharacterConn = _G.HoneyBlazeSkinCharacterConn or nil
    if _G.HoneyBlazeSkinCharacterConn then
        _G.HoneyBlazeSkinCharacterConn:Disconnect()
        _G.HoneyBlazeSkinCharacterConn = nil
        print("[Honey-da-catoni] Previous game сharacter added connection destroyed")
    end
    _G.HoneyBlazeSkinCharacterConn = game.Players.LocalPlayer.CharacterAdded:Connect(function(character)
	    if character:GetAttribute("Character") ~= "Blaze" then return end
        -- wait player server build
        task.wait(3)
        -- overlay setup
        tryUpdatePlayerModel(character)
    end)

    tryUpdatePlayerModel(game.Players.LocalPlayer.Character)
--

print("[Honey-da-catoni] Players scanned, game state and your char being listened.")

local function loadCustomAsset(url, filename)
    if not isfile(filename) then writefile(filename, game:HttpGet(url)) end
    return getcustomasset(filename)
end
game:GetService("ReplicatedStorage"):FindFirstChild("BlazeSolo", true).SoundId = loadCustomAsset(
    "https://github.com/thaLILNIKKI/honey-the-cat-on-blaze-outcome-memories/releases/download/assets/BlazeSolo.mp3",
    "cache/BlazeSolo.mp3"
)

print("[Honey-da-catoni] Ready!")
