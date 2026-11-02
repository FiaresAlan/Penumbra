--!strict
-- Oficina: upgrades permanentes (Botas Silenciosas) e exposição de Relíquias.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local systems = script.Parent :: Instance
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local Enums = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums") :: ModuleScript)
local PlayerState = require(systems:WaitForChild("PlayerState") :: ModuleScript)
local PlayerProfile = require(systems:WaitForChild("PlayerProfile") :: ModuleScript)
local RateLimiter = require(systems:WaitForChild("RateLimiter") :: ModuleScript)

local Remotes = ReplicatedStorage:WaitForChild("EcosRemotes")
local OpenShop = Remotes:WaitForChild("OpenShop") :: RemoteEvent
local BuyUpgrade = Remotes:WaitForChild("BuyUpgrade") :: RemoteEvent
local DisplayRelic = Remotes:WaitForChild("DisplayRelic") :: RemoteEvent
local RetrieveRelic = Remotes:WaitForChild("RetrieveRelic") :: RemoteEvent

local WorkshopSystem = {}

local function nearWorkshop(player: Player): boolean
    local bench = workspace:FindFirstChild("LobbyWorkshop")
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not bench or not bench:IsA("BasePart") or not root or not root:IsA("BasePart") then
        return false
    end
    return (root.Position - bench.Position).Magnitude <= Config.MarketRadius
end

local function validId(value: unknown): boolean
    return typeof(value) == "string" and #(value :: string) <= 64
end

local function standCount(): number
    local folder = workspace:FindFirstChild("RelicDisplays")
    return if folder then #folder:GetChildren() else 0
end

-- Mostra as relíquias expostas nos suportes. Os suportes são compartilhados no servidor.
local function refreshStands()
    local folder = workspace:FindFirstChild("RelicDisplays")
    if not folder then
        return
    end
    local stands: { BasePart } = {}
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("BasePart") then
            local shown = child:FindFirstChild("ShownRelic")
            if shown then
                shown:Destroy()
            end
            table.insert(stands, child)
        end
    end
    table.sort(stands, function(a, b)
        return a.Name < b.Name
    end)

    local index = 1
    for _, player in ipairs(Players:GetPlayers()) do
        local profile = PlayerProfile.Get(player)
        if profile then
            for _ in ipairs(profile.relicDisplay) do
                local stand = stands[index]
                if not stand then
                    return
                end
                local relic = Instance.new("Part")
                relic.Name = "ShownRelic"
                relic.Shape = Enum.PartType.Ball
                relic.Size = Vector3.new(2.4, 2.4, 2.4)
                relic.Anchored = true
                relic.CanCollide = false
                relic.Material = Enum.Material.Neon
                relic.Color = Color3.fromRGB(255, 120, 210)
                relic.Position = stand.Position + Vector3.new(0, stand.Size.Y / 2 + 1.8, 0)
                relic.Parent = stand
                index += 1
            end
        end
    end
end

function WorkshopSystem.Init()
    local bench = workspace:FindFirstChild("LobbyWorkshop")
    if bench and bench:IsA("BasePart") then
        local prompt = Instance.new("ProximityPrompt")
        prompt.ActionText = "Abrir bancada"
        prompt.ObjectText = "Oficina"
        prompt.HoldDuration = 0.3
        prompt.MaxActivationDistance = 12
        prompt.RequiresLineOfSight = false
        prompt.Parent = bench
        prompt.Triggered:Connect(function(player)
            if PlayerState.Get(player) == Enums.PlayerLocation.Lobby then
                OpenShop:FireClient(player, "workshop")
            end
        end)
    else
        warn("[Workshop] LobbyWorkshop não encontrado.")
    end

    -- Os suportes refletem o perfil: atualizam quando um perfil carrega ou muda e quando alguém sai
    PlayerProfile.Updated:Connect(refreshStands)
    Players.PlayerRemoving:Connect(function()
        task.defer(refreshStands)
    end)

    BuyUpgrade.OnServerEvent:Connect(function(player, upgradeId: unknown)
        if not RateLimiter.Allow(player, "BuyUpgrade", 3, 3) then
            return
        end
        if not validId(upgradeId) then
            return
        end
        if PlayerState.Get(player) ~= Enums.PlayerLocation.Lobby or not nearWorkshop(player) then
            return
        end
        local definition = Config.Upgrades[upgradeId :: string]
        if not definition or PlayerProfile.HasUpgrade(player, upgradeId :: string) then
            return
        end
        -- O preço vem do catálogo do servidor; o upgrade só é concedido se o pagamento passar
        if PlayerProfile.SpendMoney(player, definition.price) then
            PlayerProfile.SetUpgrade(player, upgradeId :: string)
            print(string.format("[Workshop] %s comprou %s", player.Name, upgradeId :: string))
        end
    end)

    DisplayRelic.OnServerEvent:Connect(function(player, itemId: unknown)
        if not RateLimiter.Allow(player, "DisplayRelic", 3, 3) or not validId(itemId) then
            return
        end
        if PlayerState.Get(player) ~= Enums.PlayerLocation.Lobby or not nearWorkshop(player) then
            return
        end
        if PlayerProfile.MoveToDisplay(player, itemId :: string, standCount()) then
            refreshStands()
        end
    end)

    RetrieveRelic.OnServerEvent:Connect(function(player, itemId: unknown)
        if not RateLimiter.Allow(player, "RetrieveRelic", 3, 3) or not validId(itemId) then
            return
        end
        if PlayerState.Get(player) ~= Enums.PlayerLocation.Lobby or not nearWorkshop(player) then
            return
        end
        if PlayerProfile.MoveFromDisplay(player, itemId :: string) then
            refreshStands()
        end
    end)
end

return WorkshopSystem
