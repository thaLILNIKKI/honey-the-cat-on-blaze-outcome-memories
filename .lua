
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
    ["LLeg2"]            = "LFoot2",
    ["LLeg3"]            = "LFoot3",
}

local BONE_OFFSETS = {
    ["UpperBody"] = CFrame.Angles(0, math.pi, 0),
    ["RArm5"]      = CFrame.Angles(0, math.pi, 0),
    ["Head"]      = CFrame.Angles(0, math.pi, 0),
}

local SKIN_ASSET_ID = "96857029798216"

local _skinModelCache = nil

-- Исправляет структуру Honey модели для корректной работы
local function fixHoneyModel(model)
	print("[HoneySwap] Fixing Honey model structure...")
	
	-- Удаляем все SmartBone2 объекты которые вызывают ошибки
	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("Bone") then
			-- Оставляем bones но они не будут использоваться для синхронизации
			desc.Transparency = 1
		end
	end
	
	-- Убеждаемся что у модели есть правильная Humanoid структура
	local humanoid = model:FindFirstChild("Humanoid")
	if not humanoid then
		humanoid = Instance.new("Humanoid")
		humanoid.Parent = model
		print("[HoneySwap] Created Humanoid")
	end
	
	-- Убеждаемся что HumanoidRootPart существует и правильно установлен
	local hrp = model:FindFirstChild("HumanoidRootPart")
	if not hrp then
		hrp = Instance.new("Part")
		hrp.Name = "HumanoidRootPart"
		hrp.Shape = Enum.PartType.Ball
		hrp.Size = Vector3.new(2, 2, 1)
		hrp.CanCollide = false
		hrp.Transparency = 1
		hrp.Parent = model
		print("[HoneySwap] Created HumanoidRootPart")
	end
	
	-- Проверяем основные кости
	local requiredBones = {"Waist", "UpperBody", "Head", "RLeg1", "LFoot1", "RightShoulderPad", "LeftShoulderPad"}
	for _, boneName in ipairs(requiredBones) do
		if not model:FindFirstChild(boneName, true) then
			print("[HoneySwap] WARNING: Missing bone: " .. boneName)
		end
	end
	
	print("[HoneySwap] Model structure fixed")
	return model
end

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
	-- если нет — инсертим по asset id и исправляем
	print("[HoneySwap] Loading Honey model from asset ID...")
	if ok and ins then
		print("[HoneySwap] Model loaded, fixing structure...")
		ins = fixHoneyModel(ins)
		ins.Parent = ReplicatedStorage
		_skinModelCache = ins
		print("[HoneySwap] Model cached in ReplicatedStorage")
		return ins
	else
		warn("[HoneySwap] Failed to load model: " .. tostring(ins))
		return nil
	end
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

	-- строим пары костей - просто синхронизируем полностью как было в оригинале
	local partPairs = {}
	for srcName, dstName in pairs(BONE_MAP) do
		local srcPart = source:FindFirstChild(srcName, true)
		local dstPart = mdl:FindFirstChild(dstName, true)
		if srcPart and dstPart then
			dstPart.Anchored = true
			partPairs[#partPairs + 1] = {
				srcPart,
				dstPart,
				BONE_OFFSETS[dstName] or CFrame.identity,
			}
		end
	end

	print("[HoneySwap] Loaded " .. #partPairs .. " bone pairs for " .. playerName)

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
				p[2].CFrame = p[1].CFrame * p[3]
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
	
	print("[HoneySwap] Applied to " .. playerName)
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
