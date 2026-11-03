--!strict
-- XP e recompensa diária. O XP vem só de eventos do servidor (extrair, resgatar, participar): o cliente nunca informa nada.
-- Nível só mostra progresso e não dá poder. Acima da cabeça, o nível aparece só no lobby, nunca na caverna.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local systems = script.Parent :: Instance
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local Enums = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums") :: ModuleScript)
local LevelRules = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("LevelRules") :: ModuleScript)
local PlayerState = require(systems:WaitForChild("PlayerState") :: ModuleScript)
local PlayerProfile = require(systems:WaitForChild("PlayerProfile") :: ModuleScript)
local ExpeditionSystem = require(systems:WaitForChild("ExpeditionSystem") :: ModuleScript)
local ExtractionSystem = require(systems:WaitForChild("ExtractionSystem") :: ModuleScript)
local NestSystem = require(systems:WaitForChild("NestSystem") :: ModuleScript)
local RateLimiter = require(systems:WaitForChild("RateLimiter") :: ModuleScript)

local ClaimDaily = ReplicatedStorage:WaitForChild("EcosRemotes"):WaitForChild("ClaimDaily") :: RemoteEvent

local XpSystem = {}

local participants: { [number]: boolean } = {}

local function applyTag(player: Player)
    local character = player.Character
    local head = character and character:FindFirstChild("Head")
    if not head or not head:IsA("BasePart") then
        return
    end
    local gui = head:FindFirstChild("NivelTag")
    if not gui then
        local created = Instance.new("BillboardGui")
        created.Name = "NivelTag"
        created.Adornee = head
        created.Size = UDim2.new(0, 130, 0, 26)
        created.StudsOffset = Vector3.new(0, 2.7, 0)
        created.MaxDistance = 70
        created.LightInfluence = 0
        created.Parent = head
        local label = Instance.new("TextLabel")
        label.Name = "Texto"
        label.BackgroundTransparency = 1
        label.Size = UDim2.fromScale(1, 1)
        label.Font = Enum.Font.GothamBold
        label.TextSize = 14
        label.TextColor3 = Color3.fromRGB(246, 206, 96)
        label.TextStrokeTransparency = 0.4
        label.Parent = created
        gui = created
    end
    local billboard = gui :: BillboardGui
    local text = billboard:FindFirstChild("Texto")
    local profile = PlayerProfile.Get(player)
    if text and text:IsA("TextLabel") and profile then
        local level = LevelRules.FromXp(profile.xp)
        text.Text = string.format("Nv %d · %s", level, LevelRules.Title(level))
    end
    -- Só no lobby: na caverna o nível não deve aparecer para ninguém
    billboard.Enabled = PlayerState.Get(player) == Enums.PlayerLocation.Lobby
end

local function hook(player: Player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        applyTag(player)
    end)
end

function XpSystem.Init()
    for _, player in ipairs(Players:GetPlayers()) do
        hook(player)
    end
    Players.PlayerAdded:Connect(hook)

    ExpeditionSystem.Started:Connect(function()
        participants = {}
        for _, player in ipairs(PlayerState.GetPlayersIn(Enums.PlayerLocation.Cave)) do
            participants[player.UserId] = true
        end
    end)

    ExtractionSystem.Extracted:Connect(function(player: Player, receipt: any)
        local amount = Config.Xp.Extraction
        for _, item in ipairs(receipt.items) do
            amount += if item.type == "Relic" then Config.Xp.PerRelic else Config.Xp.PerItem
        end
        participants[player.UserId] = nil -- já ganhou pela extração
        PlayerProfile.AddXp(player, amount)
    end)

    NestSystem.PlayerRescued:Connect(function(rescuer: Player)
        PlayerProfile.AddXp(rescuer, Config.Xp.Rescue)
    end)

    -- Quem desceu e não extraiu ainda ganha um pouco: tentar nunca deve render zero
    ExpeditionSystem.Ended:Connect(function()
        for userId in pairs(participants) do
            local player = Players:GetPlayerByUserId(userId)
            if player then
                PlayerProfile.AddXp(player, Config.Xp.Participation)
            end
        end
        participants = {}
    end)

    PlayerProfile.Updated:Connect(applyTag)
    PlayerState.Changed:Connect(applyTag)

    ClaimDaily.OnServerEvent:Connect(function(player)
        if not RateLimiter.Allow(player, "ClaimDaily", 1, 2) then
            return
        end
        if PlayerState.Get(player) ~= Enums.PlayerLocation.Lobby then
            return
        end
        if not PlayerProfile.ClaimDaily(player) then
            PlayerProfile.Notify(player, "Você já recebeu a recompensa de hoje")
        end
    end)
end

return XpSystem
