local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Enums = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums"))
local Remotes = ReplicatedStorage:WaitForChild("EcosRemotes")
local HUDUpdate = Remotes:WaitForChild("HUDUpdate")
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))

local LootSystem = {}

-- Cada item da mochila: { type = "Core" | "Relic", rarity, baseValue }
-- baseValue já inclui o bônus de profundidade do ponto onde foi coletado.
local playerInventory = {}
local valueMultiplier = 1

local function getOrCreateInventory(player)
    if not playerInventory[player] then
        playerInventory[player] = { items = {} }
    end
    return playerInventory[player]
end

local function weightOf(itemType)
    return Config.ItemWeights[itemType] or Config.CoreWeight
end

local function totalWeight(inv)
    local weight = 0
    for _, item in ipairs(inv.items) do
        weight = weight + weightOf(item.type)
    end
    return weight
end

local function backpackValue(inv, multiplier)
    local sum = 0
    for _, item in ipairs(inv.items) do
        sum = sum + item.baseValue
    end
    return math.floor(sum * multiplier)
end

local function updateCarryWeight(player)
    if player.Character then
        player.Character:SetAttribute("CarryWeight", totalWeight(getOrCreateInventory(player)))
    end
end

local function sendInventoryUpdate(player, notice)
    local inv = getOrCreateInventory(player)
    -- Lista só dos itens do próprio jogador, para a tela de mochila: o valor atual é calculado aqui, nunca no cliente
    local items = {}
    for _, item in ipairs(inv.items) do
        table.insert(items, {
            id = item.id,
            type = item.type,
            rarity = item.rarity,
            depthZone = item.depthZone,
            baseValue = item.baseValue,
            value = math.floor(item.baseValue * valueMultiplier),
            weight = weightOf(item.type),
        })
    end
    HUDUpdate:FireClient(player, {
        itemsCount = #inv.items,
        totalValue = backpackValue(inv, valueMultiplier),
        weight = totalWeight(inv),
        maxWeight = Config.MaxCarryWeight,
        items = items,
        notice = notice,
    })
end

function LootSystem.GetInventory(player)
    return getOrCreateInventory(player)
end

function LootSystem.ClearInventory(player)
    playerInventory[player] = { items = {} }
    updateCarryWeight(player)
    sendInventoryUpdate(player)
end

function LootSystem.GetBackpackValue(player, multiplier)
    return backpackValue(getOrCreateInventory(player), multiplier)
end

function LootSystem.SetValueMultiplier(multiplier)
    valueMultiplier = multiplier
end

function LootSystem.PushHud(player)
    sendInventoryUpdate(player)
end

-- Coloca um item na mochila. Devolve false (e avisa o jogador) se ficaria pesado demais.
function LootSystem.GrantItem(player, itemType, rarity, depthZone)
    itemType = itemType or "Core"
    rarity = rarity or Enums.CoreRarity.Common

    local inv = getOrCreateInventory(player)
    if totalWeight(inv) + weightOf(itemType) > Config.MaxCarryWeight then
        sendInventoryUpdate(player, "Mochila pesada demais")
        return false
    end

    local base
    if itemType == "Relic" then
        base = Config.RelicValue
    elseif itemType == "DenseCore" then
        base = (Config.CoreValue[rarity] or 10) * 3
    else
        base = Config.CoreValue[rarity] or 10
    end
    local bonus = Config.DepthBonus[depthZone or "A"] or 1

    table.insert(inv.items, {
        id = HttpService:GenerateGUID(false),
        type = itemType,
        rarity = rarity,
        depthZone = depthZone or "A",
        baseValue = math.floor(base * bonus),
    })

    updateCarryWeight(player)
    sendInventoryUpdate(player)

    if not workspace:GetAttribute("FirstCoreExtracted") then
        workspace:SetAttribute("FirstCoreExtracted", true)
    end
    return true
end

-- Atalho usado pelos comandos de QA.
function LootSystem.GrantCore(player, rarity)
    return LootSystem.GrantItem(player, "Core", rarity, "A")
end

-- Fecha a mochila: devolve o recibo com o valor final já travado e esvazia a mochila.
function LootSystem.FinalizeExtraction(player, multiplier)
    local inv = getOrCreateInventory(player)
    local receipt = { items = {}, total = 0, multiplier = multiplier }
    for _, item in ipairs(inv.items) do
        local finalValue = math.floor(item.baseValue * multiplier)
        table.insert(receipt.items, {
            type = item.type,
            rarity = item.rarity,
            baseValue = item.baseValue,
            value = finalValue,
        })
        receipt.total = receipt.total + finalValue
    end
    LootSystem.ClearInventory(player)
    return receipt
end

-- Estado original de cada item coletável, para ResetCores restaurar entre expedições
local coreOriginals = setmetatable({}, { __mode = "k" })

-- Núcleos falsos do Enganador. Só o servidor sabe quais são: nada marca o falso no cliente.
local fakeCores = setmetatable({}, { __mode = "k" })

-- Deve ser chamado antes de a peça entrar no Workspace. onTriggered(player, position).
function LootSystem.MarkFake(part, onTriggered)
    fakeCores[part] = onTriggered
end

local function triggerFake(corePart, player)
    local onTriggered = fakeCores[corePart]
    if not onTriggered then return false end
    fakeCores[corePart] = nil
    onTriggered(player, corePart.Position)
    corePart:Destroy()
    return true
end

-- Usado só pelo QA: aciona o falso mais próximo, como se o jogador o tivesse tocado.
function LootSystem.QATriggerNearestFake(player)
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local nearest, best = nil, 40
    for part in pairs(fakeCores) do
        if part.Parent then
            local distance = (part.Position - root.Position).Magnitude
            if distance < best then
                nearest, best = part, distance
            end
        end
    end
    if nearest then
        triggerFake(nearest, player)
    end
end

local function setCoreLights(corePart, enabled)
    for _, child in ipairs(corePart:GetChildren()) do
        if child:IsA("Light") then
            child.Enabled = enabled
        end
    end
end

local function connectCore(corePart, prompt)
    coreOriginals[corePart] = {
        collected = corePart:GetAttribute("Collected"),
        transparency = corePart.Transparency,
        canCollide = corePart.CanCollide,
        prompt = prompt,
        promptEnabled = prompt.Enabled,
    }

    prompt.Triggered:Connect(function(player)
        if PlayerState.Get(player) ~= Enums.PlayerLocation.Cave then return end
        if corePart:GetAttribute("Collected") then return end

        -- Além do limite do prompt, o servidor confere vida e distância
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not root or not humanoid or humanoid.Health <= 0 then return end
        if (root.Position - corePart.Position).Magnitude > prompt.MaxActivationDistance + 6 then return end
        if triggerFake(corePart, player) then
            return
        end

        local itemType = corePart:GetAttribute("ItemType") or "Core"
        local rarity = corePart:GetAttribute("Rarity") or Enums.CoreRarity.Common
        local depthZone = corePart:GetAttribute("DepthZone") or "A"
        if not LootSystem.GrantItem(player, itemType, rarity, depthZone) then
            return
        end

        corePart:SetAttribute("Collected", true)
        corePart.Transparency = 1
        corePart.CanCollide = false
        prompt.Enabled = false
        setCoreLights(corePart, false)
    end)
end

function LootSystem.ResetCores()
    for corePart, original in pairs(coreOriginals) do
        if corePart.Parent then
            corePart:SetAttribute("Collected", original.collected)
            corePart.Transparency = original.transparency
            corePart.CanCollide = original.canCollide
            original.prompt.Enabled = original.promptEnabled
            setCoreLights(corePart, true)
        else
            coreOriginals[corePart] = nil
        end
    end
end

-- Núcleo Common garantido na primeira sala (pity). Só existe um por vez.
local guaranteedCore = nil

function LootSystem.RemoveGuaranteedCore()
    if guaranteedCore then
        guaranteedCore:Destroy()
        guaranteedCore = nil
    end
end

function LootSystem.SpawnGuaranteedCore()
    LootSystem.RemoveGuaranteedCore()
    local template = game:GetService("ServerStorage"):FindFirstChild("CoreTemplate")
    local point = workspace:FindFirstChild("PitySpawnPoint")
    if not template or not point then
        warn("[Loot] CoreTemplate ou PitySpawnPoint não encontrado; sem núcleo garantido.")
        return false
    end
    local core = template:Clone()
    core.Name = "GuaranteedCore"
    core.Position = point.Position
    core.Parent = workspace -- por último, para os atributos já estarem no lugar
    guaranteedCore = core
    return true
end

function LootSystem.Init()
    local function tryConnect(parent)
        if parent and parent:GetAttribute("IsCore") then
            local prompt = parent:FindFirstChildOfClass("ProximityPrompt")
            if prompt then
                connectCore(parent, prompt)
            end
        end
    end

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            tryConnect(obj.Parent)
        end
    end

    workspace.DescendantAdded:Connect(function(obj)
        if obj:IsA("ProximityPrompt") then
            tryConnect(obj.Parent)
        end
    end)

    Players.PlayerRemoving:Connect(function(p)
        playerInventory[p] = nil
    end)
end

return LootSystem
