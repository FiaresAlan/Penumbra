local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Enums = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums"))
local Remotes = ReplicatedStorage:WaitForChild("EcosRemotes")
local HUDUpdate = Remotes:WaitForChild("HUDUpdate")

local LootSystem = {}

local playerInventory = {}

local function getOrCreateInventory(player)
    if not playerInventory[player] then
        playerInventory[player] = { cores = {}, totalValue = 0 }
    end
    return playerInventory[player]
end

local function updateCarryWeight(player)
    local inv = getOrCreateInventory(player)
    local weight = #inv.cores * Config.CoreWeight
    if player.Character then
        player.Character:SetAttribute("CarryWeight", weight)
    end
end

local function sendInventoryUpdate(player)
    local inv = getOrCreateInventory(player)
    HUDUpdate:FireClient(player, {
        coresCount = #inv.cores,
        totalValue = inv.totalValue,
        weight = #inv.cores * Config.CoreWeight,
    })
end

function LootSystem.GetInventory(player)
    return getOrCreateInventory(player)
end

function LootSystem.ClearInventory(player)
    playerInventory[player] = { cores = {}, totalValue = 0 }
    updateCarryWeight(player)
    sendInventoryUpdate(player)
end

-- Estado original de cada núcleo, para ResetCores restaurar entre expedições
local coreOriginals = setmetatable({}, { __mode = "k" })

local function connectCore(corePart, prompt)
    coreOriginals[corePart] = {
        collected = corePart:GetAttribute("Collected"),
        transparency = corePart.Transparency,
        canCollide = corePart.CanCollide,
        prompt = prompt,
        promptEnabled = prompt.Enabled,
    }

    prompt.Triggered:Connect(function(player)
        if corePart:GetAttribute("Collected") then return end
        if corePart:GetAttribute("IsFake") then
            corePart:Destroy()
            return
        end

        local rarity = corePart:GetAttribute("Rarity") or Enums.CoreRarity.Common
        local value = Config.CoreValue[rarity] or 10

        local inv = getOrCreateInventory(player)
        table.insert(inv.cores, { rarity = rarity, value = value })
        inv.totalValue = inv.totalValue + value

        corePart:SetAttribute("Collected", true)
        corePart.Transparency = 1
        corePart.CanCollide = false
        prompt.Enabled = false

        updateCarryWeight(player)
        sendInventoryUpdate(player)

        if not workspace:GetAttribute("FirstCoreExtracted") then
            workspace:SetAttribute("FirstCoreExtracted", true)
        end
    end)
end

function LootSystem.ResetCores()
    for corePart, original in pairs(coreOriginals) do
        if corePart.Parent then
            corePart:SetAttribute("Collected", original.collected)
            corePart.Transparency = original.transparency
            corePart.CanCollide = original.canCollide
            original.prompt.Enabled = original.promptEnabled
        else
            coreOriginals[corePart] = nil
        end
    end
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