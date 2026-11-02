--!strict
-- Escolhe qual Guardião aparece em cada expedição. A variante fica só no servidor.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local systems = script.Parent :: Instance
local Enums = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums") :: ModuleScript)
local ExpeditionSystem = require(systems:WaitForChild("ExpeditionSystem") :: ModuleScript)
local MimicGuardian = require(systems:WaitForChild("MimicGuardian") :: ModuleScript)
local DeceiverGuardian = require(systems:WaitForChild("DeceiverGuardian") :: ModuleScript)

local GuardianDirector = {}

type Variant = { Start: () -> (), Stop: () -> () }

-- Blind não tem módulo: é o Guardião base, sem truques. Para uma variante nova, uma linha aqui.
local variants: { [string]: Variant? } = {
    [Enums.GuardianVariant.Blind] = nil,
    [Enums.GuardianVariant.Mimic] = MimicGuardian,
    [Enums.GuardianVariant.Deceiver] = DeceiverGuardian,
}
local available: { string } = { Enums.GuardianVariant.Blind, Enums.GuardianVariant.Mimic, Enums.GuardianVariant.Deceiver }

local lastVariant: string? = nil
local forced: string? = nil
local current: Variant? = nil

-- Lógica pura: sorteia entre as disponíveis sem repetir a anterior.
function GuardianDirector.PickVariant(last: string?, rng: Random, options: { string }): string
    local pool: { string } = {}
    for _, name in ipairs(options) do
        if name ~= last then
            table.insert(pool, name)
        end
    end
    if #pool == 0 then
        return options[1]
    end
    return pool[rng:NextInteger(1, #pool)]
end

-- Usado só pelos comandos de QA do Studio.
function GuardianDirector.ForceNext(name: string)
    forced = name
end

function GuardianDirector.Init()
    local rng = Random.new()

    ExpeditionSystem.Started:Connect(function()
        local choice = forced or GuardianDirector.PickVariant(lastVariant, rng, available)
        forced = nil
        lastVariant = choice
        print("[Director] " .. choice)
        current = variants[choice]
        if current then
            current.Start()
        end
    end)

    ExpeditionSystem.Ended:Connect(function()
        if current then
            current.Stop()
            current = nil
        end
    end)
end

return GuardianDirector
