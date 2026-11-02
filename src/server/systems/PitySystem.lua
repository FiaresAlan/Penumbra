--!strict
-- Pity disfarçado: depois de falhas seguidas, a caverna "ajuda" o grupo sem mostrar contador.
-- Lógica pura e só em memória (por servidor). Nada aqui é replicado ao cliente.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local Enums = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums") :: ModuleScript)

local PitySystem = {}

local consecutiveFailures = 0

-- Failure soma 1, Success zera, Abandoned não muda nada.
function PitySystem.RecordResult(outcome: string)
    if outcome == Enums.ExpeditionOutcome.Failure then
        consecutiveFailures += 1
    elseif outcome == Enums.ExpeditionOutcome.Success then
        consecutiveFailures = 0
    end
end

-- Fica ativo a partir do limite e continua até uma extração bem-sucedida.
function PitySystem.IsActive(): boolean
    return consecutiveFailures >= Config.PityFailureThreshold
end

function PitySystem.GetGuardianSpeedMultiplier(): number
    if PitySystem.IsActive() then
        return Config.PityGuardianSpeedMultiplier
    end
    return 1
end

-- Só para logs de servidor e QA
function PitySystem.GetConsecutiveFailures(): number
    return consecutiveFailures
end

return PitySystem
