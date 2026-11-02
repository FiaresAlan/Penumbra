--!strict
-- Regras puras dos contratos: escolha determinística por data. Só números e textos entram e saem.
local ContractRules = {}

local function seedFrom(text: string): number
    local hash = 7
    for index = 1, #text do
        hash = (hash * 31 + string.byte(text, index)) % 2147483647
    end
    return hash
end

-- Chave do dia (UTC) e da semana a partir de um instante em segundos.
function ContractRules.DayKey(now: number): string
    return tostring(math.floor(now / 86400))
end

function ContractRules.WeekKey(now: number): string
    return tostring(math.floor(now / 604800))
end

-- Escolhe `count` ids do conjunto, sempre os mesmos para a mesma chave.
function ContractRules.Pick(key: string, ids: { string }, count: number): { string }
    local rng = Random.new(seedFrom(key))
    local pool = table.clone(ids)
    for index = #pool, 2, -1 do
        local other = rng:NextInteger(1, index)
        pool[index], pool[other] = pool[other], pool[index]
    end
    local result: { string } = {}
    for index = 1, math.min(count, #pool) do
        table.insert(result, pool[index])
    end
    return result
end

return ContractRules
