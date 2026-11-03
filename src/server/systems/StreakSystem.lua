--!strict
-- P13 (Features.ChainBonus) e P12 (Features.VillageEndings): contadores de marcos e cadeia de extrações.
-- Cadeia: extrair sem ser capturado em Config.Chain.From expedições seguidas dá XP extra por extração. Quem desce e não extrai
-- volta a zero, sem perder nada. Marcos: ao atingir um número (extrações, relíquias, resgates) o jogador ganha uma frase, uma vez.
-- Os contadores sempre contam; os flags só ligam o bônus e as frases.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local systems = script.Parent :: Instance
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local Enums = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums") :: ModuleScript)
local PlayerProfile = require(systems:WaitForChild("PlayerProfile") :: ModuleScript)
local PlayerState = require(systems:WaitForChild("PlayerState") :: ModuleScript)
local ExpeditionSystem = require(systems:WaitForChild("ExpeditionSystem") :: ModuleScript)
local ExtractionSystem = require(systems:WaitForChild("ExtractionSystem") :: ModuleScript)
local NestSystem = require(systems:WaitForChild("NestSystem") :: ModuleScript)

local StreakSystem = {}

local participants: { [number]: boolean } = {}

local function bump(player: Player, stat: string, amount: number)
    local profile = PlayerProfile.Get(player)
    if not profile then
        return
    end
    local value = (profile.stats[stat] or 0) + amount
    profile.stats[stat] = value
    if not Config.Features.VillageEndings then
        return
    end
    for _, ending in ipairs(Config.VillageEndings) do
        if ending.stat == stat and value >= ending.at then
            local key = string.format("marco_%s_%d", ending.stat, ending.at)
            if not profile.discovered[key] then
                profile.discovered[key] = true
                PlayerProfile.Notify(player, ending.text)
                print("[Streak] marco " .. key)
            end
        end
    end
end

function StreakSystem.Init()
    ExpeditionSystem.Started:Connect(function()
        participants = {}
        for _, player in ipairs(PlayerState.GetPlayersIn(Enums.PlayerLocation.Cave)) do
            participants[player.UserId] = true
        end
    end)

    ExtractionSystem.Extracted:Connect(function(player: Player, receipt: any)
        participants[player.UserId] = nil
        local profile = PlayerProfile.Get(player)
        if not profile then
            return
        end
        profile.streak += 1
        local relics = 0
        for _, item in ipairs(receipt.items) do
            if item.type == "Relic" then
                relics += 1
            end
        end
        if Config.Features.ChainBonus and profile.streak >= Config.Chain.From then
            PlayerProfile.AddXp(player, Config.Chain.XpBonus)
            PlayerProfile.Notify(player, string.format("Sequência de %d voltas: +%d XP", profile.streak, Config.Chain.XpBonus))
            print("[Streak] cadeia " .. profile.streak)
        end
        bump(player, "extractions", 1)
        if relics > 0 then
            bump(player, "relics", relics)
        end
    end)

    NestSystem.PlayerRescued:Connect(function(rescuer: Player)
        bump(rescuer, "rescues", 1)
    end)

    -- Quem desceu e não extraiu perde a cadeia (e só isso)
    ExpeditionSystem.Ended:Connect(function()
        for userId in pairs(participants) do
            local player = Players:GetPlayerByUserId(userId)
            local profile = if player then PlayerProfile.Get(player) else nil
            if profile then
                profile.streak = 0
            end
        end
        participants = {}
    end)
end

return StreakSystem
