--!strict
-- P1 (Features.TensionDirector): o Guardião alterna fases de silêncio e de caça, com durações sorteadas em faixas, para as
-- sustos não virarem relógio. Só muda o quanto ele escuta (e, no silêncio, anda um pouco mais devagar). A velocidade base e a de
-- fúria nunca sobem: a caça só deixa o ouvido mais atento. O início da caça avisa com um ronco, como a virada de tier.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local systems = script.Parent :: Instance
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local ExpeditionSystem = require(systems:WaitForChild("ExpeditionSystem") :: ModuleScript)
local GuardianAI = require(systems:WaitForChild("GuardianAI") :: ModuleScript)
local AudioBroadcast = require(systems:WaitForChild("AudioBroadcast") :: ModuleScript)

local TensionDirector = {}

local rng = Random.new()
local runId = 0

local function setPhase(phase: string)
    local settings = Config.Tension[phase]
    workspace:SetAttribute("TensionPhase", phase)
    GuardianAI.SetHearScale(settings.hearScale)
    GuardianAI.SetSpeedMultiplier("tension", settings.speed)
    print(string.format("[Tension] fase %s (escuta x%.2f)", phase, settings.hearScale))
end

local function reset()
    workspace:SetAttribute("TensionPhase", nil)
    GuardianAI.SetHearScale(1)
    GuardianAI.SetSpeedMultiplier("tension", 1)
end

function TensionDirector.Init()
    ExpeditionSystem.Started:Connect(function()
        if not Config.Features.TensionDirector then
            return
        end
        runId += 1
        local mine = runId
        task.spawn(function()
            -- A primeira fase é sempre silêncio: ninguém é caçado nos primeiros passos
            for _ = 1, 10 do -- o evento Started chega um instante antes da fase virar Active
                if ExpeditionSystem.GetPhase() == "Active" or mine ~= runId then
                    break
                end
                task.wait(0.5)
            end
            local phase = "Silence"
            while mine == runId and ExpeditionSystem.GetPhase() == "Active" do
                setPhase(phase)
                if phase == "Hunt" then
                    AudioBroadcast.Play("Rumble")
                end
                local range = Config.Tension[phase].seconds
                local waited = 0
                local total = rng:NextNumber(range[1], range[2])
                while waited < total and mine == runId and ExpeditionSystem.GetPhase() == "Active" do
                    task.wait(1)
                    waited += 1
                end
                phase = if phase == "Silence" then "Hunt" else "Silence"
            end
            if mine == runId then
                reset()
            end
        end)
    end)

    ExpeditionSystem.Ended:Connect(function()
        runId += 1
        reset()
    end)
end

return TensionDirector
