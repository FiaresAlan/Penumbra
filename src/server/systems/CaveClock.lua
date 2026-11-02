--!strict
-- Aplica o tier de agressividade do Guardião e o multiplicador de valor conforme o tempo da expedição.
local systems = script.Parent :: Instance
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Enums = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums") :: ModuleScript)
local CaveRules = require(systems:WaitForChild("CaveRules") :: ModuleScript)
local ExpeditionSystem = require(systems:WaitForChild("ExpeditionSystem") :: ModuleScript)
local GuardianAI = require(systems:WaitForChild("GuardianAI") :: ModuleScript)
local NoiseSystem = require(systems:WaitForChild("NoiseSystem") :: ModuleScript)
local LootSystem = require(systems:WaitForChild("LootSystem") :: ModuleScript)
local PlayerState = require(systems:WaitForChild("PlayerState") :: ModuleScript)
local PitySystem = require(systems:WaitForChild("PitySystem") :: ModuleScript)
local AudioBroadcast = require(systems:WaitForChild("AudioBroadcast") :: ModuleScript)

local CaveClock = {}

local currentTier = ""
local ticksSinceHud = 0

local function apply(tier: CaveRules.Tier, announce: boolean)
    currentTier = tier.name
    -- O cliente usa o tier só para a intensidade do drone de fundo
    workspace:SetAttribute("GuardianTier", tier.name)
    GuardianAI.SetSpeedMultiplier("tier", tier.speed)
    GuardianAI.SetHearThreshold(tier.hear)
    NoiseSystem.SetFury(tier.name == "Fury")
    print("[CaveRules] tier " .. tier.name)
    if announce then
        -- Aviso antes da mudança de comportamento: o jogador precisa sentir a virada
        AudioBroadcast.Play("Rumble")
    end
end

function CaveClock.Init()
    apply(CaveRules.GetTier(0), false)

    ExpeditionSystem.Started:Connect(function()
        apply(CaveRules.GetTier(0), false)
        LootSystem.SetValueMultiplier(1)
        GuardianAI.SetSpeedMultiplier("pity", PitySystem.GetGuardianSpeedMultiplier())
    end)

    -- O resultado alimenta o pity; se ativo, um núcleo Common espera na primeira sala
    ExpeditionSystem.Ended:Connect(function(outcome: string)
        PitySystem.RecordResult(outcome)
        local active = PitySystem.IsActive()
        if active then
            LootSystem.SpawnGuaranteedCore()
        else
            LootSystem.RemoveGuaranteedCore()
        end
        print(string.format("[Pity] falhas=%d, %s", PitySystem.GetConsecutiveFailures(), if active then "ativo" else "inativo"))
    end)

    task.spawn(function()
        while true do
            task.wait(1)
            if ExpeditionSystem.GetPhase() == "Active" then
                local elapsed = ExpeditionSystem.GetElapsedTime()

                local tier = CaveRules.GetTier(elapsed)
                if tier.name ~= currentTier then
                    apply(tier, true)
                end

                LootSystem.SetValueMultiplier(CaveRules.GetValueMultiplier(elapsed))
                ticksSinceHud += 1
                if ticksSinceHud >= 5 then
                    ticksSinceHud = 0
                    for _, player in ipairs(PlayerState.GetPlayersIn(Enums.PlayerLocation.Cave)) do
                        LootSystem.PushHud(player)
                    end
                end
            end
        end
    end)
end

return CaveClock
