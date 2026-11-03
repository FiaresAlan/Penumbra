--!strict
-- Teste do LevelRules. Cole em um Script no Studio (ou rode com TestEZ) e confira que não há erro.
local LevelRules = require(script.Parent.LevelRules)

assert(LevelRules.XpForLevel(1) == 0, "nivel 1 custa 0")
local previous = 0
for level = 2, 60 do
    local cost = LevelRules.XpForLevel(level)
    assert(cost > previous, "o custo precisa crescer a cada nivel")
    previous = cost
    -- nos limites, o nivel muda exatamente
    local atLevel = LevelRules.FromXp(cost)
    local justBefore = LevelRules.FromXp(cost - 1)
    assert(atLevel == level, "xp exato deve dar o nivel " .. level)
    assert(justBefore == level - 1, "um xp a menos deve dar o nivel anterior")
end
local level, into, needed = LevelRules.FromXp(0)
assert(level == 1 and into == 0 and needed == LevelRules.XpForLevel(2))
assert(LevelRules.FromXp(-50) == 1, "xp negativo vira nivel 1")
assert(LevelRules.Title(1) == "Novato" and LevelRules.Title(25) == "Lenda do Fundo")
print("[LevelRules] ok")
return true
