--!strict
-- Nível e XP: puro, sem Roblox, para o servidor e o cliente usarem a mesma conta. Nível é só mostrar: não dá poder.
local LevelRules = {}

-- XP total acumulado para chegar ao nível. Nível 1 = 0. Cresce devagar no começo e mais depois.
function LevelRules.XpForLevel(level: number): number
    if level <= 1 then
        return 0
    end
    return math.floor(60 * (level - 1) ^ 1.5)
end

-- Devolve (nível, xp dentro do nível, xp que falta para o próximo nível no total do degrau)
function LevelRules.FromXp(xp: number): (number, number, number)
    local safe = math.max(0, math.floor(xp))
    local level = 1
    while LevelRules.XpForLevel(level + 1) <= safe do
        level += 1
    end
    local base = LevelRules.XpForLevel(level)
    return level, safe - base, LevelRules.XpForLevel(level + 1) - base
end

function LevelRules.Title(level: number): string
    if level < 5 then
        return "Novato"
    elseif level < 10 then
        return "Mineiro"
    elseif level < 20 then
        return "Veterano"
    end
    return "Lenda do Fundo"
end

return LevelRules
