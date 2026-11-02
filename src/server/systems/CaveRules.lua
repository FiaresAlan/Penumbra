--!strict
-- Regras de tempo da caverna. Lógica pura: só números entram e saem.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)

export type Tier = { name: string, from: number, speed: number, hear: number }

local CaveRules = {}

-- Devolve o tier em vigor para o tempo decorrido (em segundos).
function CaveRules.GetTier(elapsedSeconds: number, tiers: { Tier }?): Tier
    local list: { Tier } = tiers or Config.GuardianTiers
    local result = list[1]
    for _, tier in ipairs(list) do
        if elapsedSeconds >= tier.from then
            result = tier
        end
    end
    return result
end

-- O valor dos itens sobe de 1.0 a 1.5, em linha reta, até ValueMaxMinute.
function CaveRules.GetValueMultiplier(elapsedSeconds: number, maxMinute: number?): number
    local limit = (maxMinute or Config.ValueMaxMinute) * 60
    return 1 + 0.5 * math.clamp(elapsedSeconds / limit, 0, 1)
end

return CaveRules
