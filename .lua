
local Players			= game:GetService("Players")
local RunService		= game:GetService("RunService")
local ReplicatedStorage	= game:GetService("ReplicatedStorage")

-- Blaze bone  →  Honey bone
local BONE_MAP = {
    -- Корень
    ["HumanoidRootPart"] = "HumanoidRootPart",
    ["Waist"]            = "Waist",
    ["MainBody"]         = "UpperBody",

    -- Голова
    ["Head"]             = "Head",

    -- Правая рука: Blaze RArm1→RArm2 → Honey RightShoulderPad→RArm5
    ["RArm1"]            = "RightShoulderPad",
    ["RArm2"]            = "RArm5",

    -- Левая рука: Blaze LArm1→LArm2 → Honey LeftShoulderPad→LArm5
    ["LArm1"]            = "LeftShoulderPad",
    ["LArm2"]            = "LArm5",

    -- Правая нога
    ["RLeg1"]            = "RLeg1",
    ["RLeg2"]            = "RLeg2",
    ["RLeg3"]            = "RLeg3",

    -- Левая нога: в Honey корень левой ноги — LFoot1 (не LLeg1!)
    ["LLeg1"]            = "LFoot1",
    ["LLeg2"]            = "LFoot2",   -- ← вот почему колено не гнулось
    ["LLeg3"]            = "LFoot3",
}

local BONE_OFFSETS = {
    ["UpperBody"] = CFrame.Angles(0, math.pi, 0),
    ["Head"]      = CFrame.Angles(0, math.pi, 0),
}

-- Кости, которые синхронизируют полностью (позиция + ротация)
local ROOT_BONES = {
    ["HumanoidRootPart"] = true,
    ["Waist"] = true,
    ["UpperBody"] = true,
}

local SKIN_ASSET_ID = "96857029798216"

local _skinModelCache = nil
local function getSkinModel()
	if _skinModelCache and _skinModelCache.Parent then
		return _skinModelCache
	end
	-- попробуем найти в ReplicatedStorage по имени
	local result = ReplicatedStorage:FindFirstChild("Honey da catoni", true)
	if result then
		_skinModelCache = result
		return result
	end
	-- если нет — инсертим по asset id
	local ok, ins = pcall(function()
		return game:GetObjects("rbxassetid://" .. SKIN_ASSET_ID)[1]
	end)
	if ok and ins then
		ins.Parent = ReplicatedStorage
		_skinModelCache = ins
		return ins
	end
	warn("[HoneySwap] не удалось загрузить модель " .. SKIN_ASSET_ID)
	return nil
end

local activeData = {}

local function resetState(playerName)
	local data = activeData[playerName]
	if not data then return end
	if data.syncConn then data.syncConn:Disconnect() end
	if data.descConn then data.descConn:Disconnect() end
	if data.mdl then data.mdl:Destroy() end
	activeData[playerName] = nil
end

local function hideDescendants(container, hiddenSet)
	for _, v in ipairs(container:GetDescendants()) do
		if v:IsA("BasePart") then
			v.Transparency = 1
			hiddenSet[v] = true
		end
	end
end

local function showDescendants(container)
	for _, v in ipairs(container:GetDescendants()) do
		if v:IsA("BasePart") then v.Transparency = 0 end
	end
end

local function applyToPlayer(playerName)
	resetState(playerName)

	local playerModel = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild(playerName)
	if not playerModel then return end
	if playerModel:GetAttribute("Character") ~= "Blaze" then return end

	local playerObj  = Players:FindFirstChild(playerName)
	local standardChar = playerObj and playerObj.Character
	local defaultFolder = playerModel:FindFirstChild("Default")
	local source = defaultFolder or standardChar
	if not source then return end

	local hrp = source:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- прячем оригинальную модель
	local hiddenSet = {}
	hideDescendants(playerModel, hiddenSet)
	if defaultFolder then hideDescendants(defaultFolder, hiddenSet) end
	if standardChar and standardChar ~= source then
		hideDescendants(standardChar, hiddenSet)
	end

	local descConn = nil
	if defaultFolder then
		descConn = defaultFolder.DescendantAdded:Connect(function(v)
			if v:IsA("BasePart") then
				v.Transparency = 1
				hiddenSet[v] = true
			end
		end)
	end

	local skinSource = getSkinModel()
	if not skinSource then return end

	local mdl = skinSource:Clone()
	mdl.Parent = playerModel

	local newHrp = mdl:FindFirstChild("HumanoidRootPart")
	if not newHrp then mdl:Destroy(); return end

	-- чистим лишнее
	for _, v in ipairs(mdl:GetDescendants()) do
		if v:IsA("Humanoid") or v:IsA("Animator") then
			v:Destroy()
		elseif v:IsA("BasePart") then
			v.CanCollide = false
			v.Anchored   = false
		elseif v:IsA("Trail") or v:IsA("Beam") then
			v.Enabled = false
		end
	end

	newHrp.Anchored     = true
	newHrp.Transparency = 1
	newHrp.CFrame       = hrp.CFrame

	-- строим пары костей
	local partPairs = {}
	local savedPositions = {} -- сохраняем исходные позиции конечностей
	
	for srcName, dstName in pairs(BONE_MAP) do
		local srcPart = source:FindFirstChild(srcName, true)
		local dstPart = mdl:FindFirstChild(dstName, true)
		if srcPart and dstPart then
			dstPart.Anchored = true
			
			-- Сохраняем исходную позицию для конечностей
			if not ROOT_BONES[dstName] then
				savedPositions[dstPart] = dstPart.Position
			end
			
			partPairs[#partPairs + 1] = {
				srcPart,
				dstPart,
				BONE_OFFSETS[dstName] or CFrame.identity,
				ROOT_BONES[dstName] or false, -- флаг для синхронизации позиции
			}
		end
	end

	local syncConn = RunService.Heartbeat:Connect(function()
		if not playerModel.Parent then
			resetState(playerName)
			return
		end
		for part in pairs(hiddenSet) do
			if part.Parent then
				part.Transparency = 1
			else
				hiddenSet[part] = nil
			end
		end
		for i = 1, #partPairs do
			local p = partPairs[i]
			if p[1].Parent and p[2].Parent then
				local srcCFrame = p[1].CFrame * p[3]
				local isRootBone = p[4]
				
				if isRootBone then
					-- Корни синхронизируем полностью (позиция + ротация)
					p[2].CFrame = srcCFrame
				else
					-- Конечности: берём только ротацию, позиция остаётся в сохранённом месте
					local rotation = srcCFrame - srcCFrame.Position
					p[2].CFrame = CFrame.new(savedPositions[p[2]]) * rotation
				end
			end
		end
	end)

	activeData[playerName] = {
		mdl       = mdl,
		syncConn  = syncConn,
		descConn  = descConn,
		hiddenSet = hiddenSet,
		partPairs = partPairs,
	}
end

local function removeFromPlayer(playerName)
	local data = activeData[playerName]
	if not data then return end

	local playerModel  = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild(playerName)
	local playerObj    = Players:FindFirstChild(playerName)
	local standardChar = playerObj and playerObj.Character
	local defaultFolder = playerModel and playerModel:FindFirstChild("Default")

	if defaultFolder  then showDescendants(defaultFolder)  end
	if standardChar   then showDescendants(standardChar)   end
	if playerModel    then showDescendants(playerModel)    end

	resetState(playerName)
end

local function onModelAdded(model)
	if not model:IsA("Model") then return end
	local name = model.Name
	if model:GetAttribute("Character") == "Blaze" then
		task.wait(0.5)
		applyToPlayer(name)
	end
	model.AttributeChanged:Connect(function(attr)
		if attr == "Character" then
			if model:GetAttribute("Character") == "Blaze" then
				applyToPlayer(name)
			else
				removeFromPlayer(name)
			end
		end
	end)
end

local function onModelRemoved(model)
	removeFromPlayer(model.Name)
end

local playersContainer = workspace:FindFirstChild("Players")
if playersContainer then
	for _, model in ipairs(playersContainer:GetChildren()) do
		onModelAdded(model)
	end
	playersContainer.ChildAdded:Connect(onModelAdded)
	playersContainer.ChildRemoved:Connect(onModelRemoved)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		local playerModel = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild(player.Name)
		if playerModel and playerModel:GetAttribute("Character") == "Blaze" then
			applyToPlayer(player.Name)
		end
	end)
end)
