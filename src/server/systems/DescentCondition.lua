--!strict
-- P6 + P9 (Features.DescentCondition): sorteia a condição da PRÓXIMA descida e a deixa visível no lobby (NextConditionText);
-- ao descer ela vira a condição ativa (ActiveCondition, ConditionFog, ConditionTint) e muda só o quanto o Guardião escuta. Some no fim.
-- Todas têm um lado bom e um ruim, sempre escritos no texto. Nunca mexe em preço, valor ou velocidade.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local systems = script.Parent :: Instance
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local ExpeditionSystem = require(systems:WaitForChild("ExpeditionSystem") :: ModuleScript)
local GuardianAI = require(systems:WaitForChild("GuardianAI") :: ModuleScript)

local DescentCondition = {}

local rng = Random.new()
local nextIndex = 0

local function pickNext()
    nextIndex = rng:NextInteger(1, #Config.DescentConditions)
    local condition = Config.DescentConditions[nextIndex]
    workspace:SetAttribute("NextConditionText", condition.text)
    print("[Condition] próxima descida: " .. condition.name)
end

local function activate()
    local condition = Config.DescentConditions[nextIndex]
    if not condition then
        return
    end
    workspace:SetAttribute("ConditionFog", condition.fog)
    local tint = condition.tint
    workspace:SetAttribute("ConditionTint", if tint then Color3.fromRGB(tint[1], tint[2], tint[3]) else nil)
    workspace:SetAttribute("ActiveCondition", condition.id)
    GuardianAI.SetHearBias(condition.hearBias)
    print("[Condition] ativa: " .. condition.name)
end

local function clear()
    workspace:SetAttribute("ActiveCondition", nil)
    workspace:SetAttribute("ConditionFog", nil)
    workspace:SetAttribute("ConditionTint", nil)
    GuardianAI.SetHearBias(1)
end

function DescentCondition.Init()
    if not Config.Features.DescentCondition then
        return
    end
    pickNext()
    ExpeditionSystem.Started:Connect(activate)
    ExpeditionSystem.Ended:Connect(function()
        clear()
        pickNext()
    end)
end

return DescentCondition
