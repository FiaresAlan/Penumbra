--!strict
-- Mercado do Lobby: vende itens do baú por uma fração do valor, sem risco.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local systems = script.Parent :: Instance
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local Enums = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums") :: ModuleScript)
local PlayerState = require(systems:WaitForChild("PlayerState") :: ModuleScript)
local PlayerProfile = require(systems:WaitForChild("PlayerProfile") :: ModuleScript)
local RateLimiter = require(systems:WaitForChild("RateLimiter") :: ModuleScript)

local Remotes = ReplicatedStorage:WaitForChild("EcosRemotes")
local OpenShop = Remotes:WaitForChild("OpenShop") :: RemoteEvent
local SellItem = Remotes:WaitForChild("SellItem") :: RemoteEvent

local MarketSystem = {}

local function nearMarket(player: Player): boolean
    local market = workspace:FindFirstChild("LobbyMarket")
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not market or not market:IsA("BasePart") or not root or not root:IsA("BasePart") then
        return false
    end
    return (root.Position - market.Position).Magnitude <= Config.MarketRadius
end

function MarketSystem.Init()
    local market = workspace:FindFirstChild("LobbyMarket")
    if market and market:IsA("BasePart") then
        local prompt = Instance.new("ProximityPrompt")
        prompt.ActionText = "Negociar"
        prompt.ObjectText = "Mercado"
        prompt.HoldDuration = 0.3
        prompt.MaxActivationDistance = 12
        prompt.RequiresLineOfSight = false
        prompt.Parent = market
        prompt.Triggered:Connect(function(player)
            if PlayerState.Get(player) == Enums.PlayerLocation.Lobby then
                OpenShop:FireClient(player, "market")
            end
        end)
    else
        warn("[Market] LobbyMarket não encontrado.")
    end

    SellItem.OnServerEvent:Connect(function(player, itemId: unknown)
        if not RateLimiter.Allow(player, "SellItem", 5, 5) then
            return
        end
        if typeof(itemId) ~= "string" or #itemId > 64 then
            return
        end
        if PlayerState.Get(player) ~= Enums.PlayerLocation.Lobby or not nearMarket(player) then
            return
        end
        -- Remove primeiro: se o item não existir mais (clique duplo), nada é pago
        local item = PlayerProfile.RemoveStashItem(player, itemId)
        if not item then
            return
        end
        local payout = math.floor(item.value * Config.LobbyMarketRate)
        PlayerProfile.AddMoney(player, payout)
        print(string.format("[Market] %s vendeu %s por %d", player.Name, item.type, payout))
    end)
end

return MarketSystem
