--!strict
-- Forma do labirinto da caverna: grade de células, zonas, salas especiais e funções puras (sem criar peças).

local CELL = 16
local COLS = 29
local ROWS = 17
local WALL_H = 16
local ORIGIN_X = 420
local ORIGIN_Z = -136
local FLOOR_Y = 1

-- Células especiais (colunas e linhas inclusivas)
local ENTRANCE = { c0 = 1, r0 = 6, c1 = 5, r1 = 10 }
local CHAMBER = { c0 = 21, r0 = 5, c1 = 27, r1 = 11 }
local NEST = { c0 = 23, r0 = 13, c1 = 27, r1 = 15 }

export type Grid = { [number]: { [number]: boolean } }
export type Style = { material: Enum.Material, color: Color3, light: Color3 }
export type Rect = { c0: number, r0: number, c1: number, r1: number }

local STYLES: { [string]: Style } = {
    A = { material = Enum.Material.Pebble, color = Color3.fromRGB(150, 140, 125), light = Color3.fromRGB(255, 170, 90) },
    B = { material = Enum.Material.Slate, color = Color3.fromRGB(104, 112, 138), light = Color3.fromRGB(130, 170, 255) },
    C = { material = Enum.Material.Grass, color = Color3.fromRGB(35, 60, 45), light = Color3.fromRGB(90, 255, 190) },
}
local ROCK_COLOR = Color3.fromRGB(45, 42, 48)

local RARITY_COLORS: { [string]: Color3 } = {
    Common = Color3.fromRGB(120, 255, 220),
    Rare = Color3.fromRGB(190, 110, 255),
    Legendary = Color3.fromRGB(255, 200, 60),
}

-- Local da caverna (C3): a mesma grade em outro lugar do mapa (mesmo X, outro Z). SetSite troca a origem, a semente e os parâmetros.
local Site: { name: string, originZ: number, seed: number, loops: number, warp: number?, relief: number?, theme: string } = {
    name = "Mina", originZ = ORIGIN_Z, seed = 0, loops = 45, warp = nil, relief = nil, theme = "mine",
}

-- Alturas da caverna: começam planas e passam a vir do CaveShape quando ele é ligado (CaveShape.Bind)
local Hooks = {
    floorAt = function(_x: number, _z: number): number
        return FLOOR_Y
    end,
    ceilingAt = function(_x: number, _z: number): number
        return FLOOR_Y + WALL_H
    end,
}

local function floorAt(x: number, z: number): number
    return Hooks.floorAt(x, z)
end

local function ceilingAt(x: number, z: number): number
    return Hooks.ceilingAt(x, z)
end

local function cellCenter(c: number, r: number): Vector3
    local x = ORIGIN_X + (c + 0.5) * CELL
    local z = ORIGIN_Z + (r + 0.5) * CELL
    return Vector3.new(x, floorAt(x, z), z)
end

local function zoneOf(c: number): string
    if c <= 9 then
        return "A"
    elseif c <= 18 then
        return "B"
    end
    return "C"
end

local function inRect(rect: Rect, c: number, r: number): boolean
    return c >= rect.c0 and c <= rect.c1 and r >= rect.r0 and r <= rect.r1
end

local function isSpecial(c: number, r: number): boolean
    return inRect(ENTRANCE, c, r) or inRect(CHAMBER, c, r) or inRect(NEST, c, r)
end

local function newGrid(): Grid
    local grid: Grid = {}
    for r = 0, ROWS - 1 do
        grid[r] = {}
        for c = 0, COLS - 1 do
            grid[r][c] = false
        end
    end
    return grid
end

local function carveMaze(grid: Grid, rng: Random)
    local stack: { { number } } = { { 1, 1 } }
    grid[1][1] = true
    local dirs = { { 2, 0 }, { -2, 0 }, { 0, 2 }, { 0, -2 } }
    while #stack > 0 do
        local cell = stack[#stack]
        local c, r = cell[1], cell[2]
        local order = table.clone(dirs)
        for i = #order, 2, -1 do
            local j = rng:NextInteger(1, i)
            order[i], order[j] = order[j], order[i]
        end
        local moved = false
        for _, d in ipairs(order) do
            local nc, nr = c + d[1], r + d[2]
            if nc >= 1 and nc <= COLS - 2 and nr >= 1 and nr <= ROWS - 2 and not grid[nr][nc] then
                grid[(r + nr) // 2][(c + nc) // 2] = true
                grid[nr][nc] = true
                table.insert(stack, { nc, nr })
                moved = true
                break
            end
        end
        if not moved then
            table.remove(stack)
        end
    end
end

local function carveRect(grid: Grid, rect: Rect)
    for r = rect.r0, rect.r1 do
        for c = rect.c0, rect.c1 do
            grid[r][c] = true
        end
    end
end

local function carveCave(rng: Random): Grid
    local grid = newGrid()
    carveMaze(grid, rng)
    carveRect(grid, ENTRANCE)
    carveRect(grid, CHAMBER)
    carveRect(grid, NEST)
    carveRect(grid, { c0 = 11, r0 = 3, c1 = 13, r1 = 5 })
    carveRect(grid, { c0 = 14, r0 = 11, c1 = 16, r1 = 13 })

    -- Laços extras: cada zona fica com rotas alternativas
    for _ = 1, Site.loops do
        local c = rng:NextInteger(2, COLS - 3)
        local r = rng:NextInteger(2, ROWS - 3)
        if not grid[r][c] and (r + c) % 2 == 1 then
            if (grid[r][c - 1] and grid[r][c + 1]) or (grid[r - 1][c] and grid[r + 1][c]) then
                grid[r][c] = true
            end
        end
    end
    return grid
end

local function shuffle<T>(list: { T }, rng: Random)
    for i = #list, 2, -1 do
        local j = rng:NextInteger(1, i)
        list[i], list[j] = list[j], list[i]
    end
end

local function openCellsByZone(grid: Grid): { [string]: { { number } } }
    local lists: { [string]: { { number } } } = { A = {}, B = {}, C = {} }
    for r = 1, ROWS - 2 do
        for c = 1, COLS - 2 do
            if grid[r][c] and not isSpecial(c, r) then
                table.insert(lists[zoneOf(c)], { c, r })
            end
        end
    end
    return lists
end

local exported = {
    CELL = CELL, COLS = COLS, ROWS = ROWS, WALL_H = WALL_H, ORIGIN_X = ORIGIN_X, ORIGIN_Z = ORIGIN_Z, FLOOR_Y = FLOOR_Y,
    ENTRANCE = ENTRANCE, CHAMBER = CHAMBER, NEST = NEST,
    STYLES = STYLES, ROCK_COLOR = ROCK_COLOR, RARITY_COLORS = RARITY_COLORS,
    cellCenter = cellCenter, zoneOf = zoneOf, inRect = inRect, isSpecial = isSpecial, newGrid = newGrid,
    carveMaze = carveMaze, carveRect = carveRect, carveCave = carveCave, shuffle = shuffle,
    openCellsByZone = openCellsByZone, Hooks = Hooks, floorAt = floorAt, ceilingAt = ceilingAt, Site = Site,
}

function exported.SetSite(info: { name: string, originZ: number, seed: number, loops: number?, warp: number?, relief: number?, theme: string? })
    Site.name = info.name
    Site.originZ = info.originZ
    Site.seed = info.seed
    Site.loops = info.loops or 45
    Site.warp = info.warp
    Site.relief = info.relief
    Site.theme = info.theme or "mine"
    ORIGIN_Z = info.originZ
    exported.ORIGIN_Z = info.originZ
end

-- Grade do local ativo (a mesma sempre, porque a semente é do local)
function exported.siteGrid(): Grid
    return carveCave(Random.new(Site.seed))
end

return exported
