--!strict
-- C2: peças de cada zona da caverna, com os pacotes Synty Dungeon (CaveLibrary): mina com caixas, barris e vagonete (A),
-- galerias com ossos, gaiolas e caixões (B), jardim de pedra e cristal (C) e o Ninho com ossadas. Tudo encostado nas
-- paredes ou em cantos, sem colisão, para nunca fechar um corredor (a auditoria de caminhos tem de seguir limpa).
-- A posição vem de raios contra o Terrain, então acompanha o relevo e as reentrâncias da parede.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local Util = require(script.Parent:WaitForChild("WorldUtil") :: ModuleScript)
local Layout = require(script.Parent:WaitForChild("CaveLayout") :: ModuleScript)
local CaveLibrary = require(script.Parent:WaitForChild("CaveLibrary") :: ModuleScript)

local CaveScatter = {}

type Rule = { words: { string }, chance: number, height: { number }, light: boolean? }

-- chance: probabilidade por célula; height: altura-alvo em studs (min, max)
local RULES: { [string]: { Rule } } = {
    A = {
        { words = { "Barrel" }, chance = 0.16, height = { 3, 4.5 } },
        { words = { "Crate" }, chance = 0.16, height = { 2.4, 4 } },
        { words = { "Minecart" }, chance = 0.07, height = { 3.2, 3.8 } },
        { words = { "RockPile_Rounded", "RockPile_Square", "Rubble" }, chance = 0.2, height = { 2, 5 } },
        { words = { "Candle_Flame", "Prop_Candle" }, chance = 0.12, height = { 1.2, 2 }, light = true },
    },
    B = {
        { words = { "BonePile", "Bone_Cracked" }, chance = 0.2, height = { 1.2, 2.6 } },
        { words = { "Bone_Skull" }, chance = 0.1, height = { 1, 1.6 } },
        { words = { "Cage", "Rigcage" }, chance = 0.1, height = { 4, 6 } },
        { words = { "Coffin" }, chance = 0.05, height = { 2.4, 3 } },
        { words = { "Rubble", "RockPile_Pillar" }, chance = 0.2, height = { 3, 7 } },
        { words = { "Candle_Flame", "Prop_Candle" }, chance = 0.1, height = { 1.2, 2 }, light = true },
    },
    C = {
        { words = { "Stalagmite" }, chance = 0.3, height = { 5, 11 } },
        { words = { "RockPile_Pillar", "RockPile_Rounded", "RockPile_Square" }, chance = 0.28, height = { 4, 9 } },
        { words = { "Tech_Crystal" }, chance = 0.16, height = { 3, 6 } },
    },
}

local NEST_RULES: { Rule } = {
    { words = { "BonePile", "Bone_Cracked", "Bone_Horn" }, chance = 0.7, height = { 1.4, 3 } },
    { words = { "Bone_Skull" }, chance = 0.5, height = { 1, 1.8 } },
    { words = { "Cage", "Rigcage" }, chance = 0.3, height = { 4, 6 } },
}

local DIRECTIONS = { { 0, -1 }, { 0, 1 }, { -1, 0 }, { 1, 0 } }

function CaveScatter.Build(grid: Layout.Grid, rng: Random)
    local mapFolder = Util.MapFolder :: Folder
    local folder = Instance.new("Folder")
    folder.Name = "Scatter"
    folder.Parent = mapFolder

    local pools: { [Rule]: { MeshPart } } = {}
    local function poolOf(rule: Rule): { MeshPart }
        local cached = pools[rule]
        if cached then
            return cached
        end
        local list: { MeshPart } = {}
        for _, name in ipairs(CaveLibrary.Find(rule.words)) do
            for _, part in ipairs(CaveLibrary.Groups()[name]) do
                table.insert(list, part)
            end
        end
        pools[rule] = list
        return list
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = { workspace.Terrain }

    local density = Config.CaveScatterDensity
    local placed = 0

    local function place(rule: Rule, cell: { number }, towardWall: boolean)
        local pool = poolOf(rule)
        if #pool == 0 then
            return
        end
        local template = pool[rng:NextInteger(1, #pool)]
        local center = Layout.cellCenter(cell[1], cell[2])
        local scale = math.clamp(rng:NextNumber(rule.height[1], rule.height[2]) / math.max(template.Size.Y, 0.1), 0.2, 8)
        local size = template.Size * scale
        local radius = math.max(size.X, size.Z) / 2
        local x, z = center.X, center.Z
        if towardWall then
            local open: { { number } } = {}
            for _, dir in ipairs(DIRECTIONS) do
                if not grid[cell[2] + dir[2]][cell[1] + dir[1]] then
                    table.insert(open, dir)
                end
            end
            if #open == 0 then
                return
            end
            local dir = open[rng:NextInteger(1, #open)]
            local direction = Vector3.new(dir[1], 0, dir[2])
            local along = rng:NextNumber(-4, 4)
            local origin = Vector3.new(center.X + (if dir[1] == 0 then along else 0), center.Y + 3, center.Z + (if dir[2] == 0 then along else 0))
            local hit = workspace:Raycast(origin, direction * Layout.CELL, params)
            if not hit then
                return
            end
            local position = hit.Position - direction * (radius * 0.6 + 0.8)
            x, z = position.X, position.Z
        else
            x += rng:NextNumber(-5, 5)
            z += rng:NextNumber(-5, 5)
        end
        local ground = workspace:Raycast(Vector3.new(x, center.Y + 12, z), Vector3.new(0, -40, 0), params)
        if not ground then
            return
        end
        local clone = template:Clone()
        clone.Size = size
        clone.CFrame = CFrame.new(x, ground.Position.Y + size.Y / 2 - 0.15, z) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
        clone.Parent = folder
        placed += 1
        if rule.light then
            Util.addLight(clone, Color3.fromRGB(255, 190, 110), 14, 0.9)
        end
    end

    for r = 1, Layout.ROWS - 2 do
        for c = 1, Layout.COLS - 2 do
            if grid[r][c] then
                local cell = { c, r }
                if Layout.inRect(Layout.NEST, c, r) then
                    for _, rule in ipairs(NEST_RULES) do
                        if rng:NextNumber() < rule.chance * density then
                            place(rule, cell, false)
                        end
                    end
                elseif not Layout.isSpecial(c, r) then
                    for _, rule in ipairs(RULES[Layout.zoneOf(c)]) do
                        if rng:NextNumber() < rule.chance * density then
                            place(rule, cell, true)
                        end
                    end
                end
            end
        end
    end
    print(string.format("[Map] %d peças de zona (Synty Dungeon) na caverna", placed))
end

return CaveScatter
