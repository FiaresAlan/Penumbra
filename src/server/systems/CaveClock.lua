--!strict
-- Aplica o tier de agressividade do Guardião conforme o tempo da expedição.
local systems = script.Parent :: Instance

local CaveRules = require(systems:WaitForChild("CaveRules") :: ModuleScript)
local ExpeditionSystem = require(systems:WaitForChild("ExpeditionSystem") :: ModuleScript)
local GuardianAI = require(systems:WaitForChild("GuardianAI") :: ModuleScript)
local NoiseSystem = require(systems:WaitForChild("NoiseSystem") :: ModuleScript)
local AudioBroadcast = require(systems:WaitForChild("AudioBroadcast") :: ModuleScript)

local CaveClock = {}

local currentTier = ""

local function apply(tier: CaveRules.Tier, announce: boolean)
    currentTier = tier.name
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
    end)

    task.spawn(function()
        while true do
            task.wait(1)
            if ExpeditionSystem.GetPhase() == "Active" then
                local tier = CaveRules.GetTier(ExpeditionSystem.GetElapsedTime())
                if tier.name ~= currentTier then
                    apply(tier, true)
                end
            end
        end
    end)
end

return CaveClock
