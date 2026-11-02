--!strict
-- Piso, teto, paredes e luzes de teto da caverna, a partir da grade.

local Util = require(script.Parent:WaitForChild("WorldUtil") :: ModuleScript)
local Layout = require(script.Parent:WaitForChild("CaveLayout") :: ModuleScript)

type Grid = Layout.Grid
local newPart = Util.newPart
local addLight = Util.addLight
local CELL = Layout.CELL
local COLS = Layout.COLS
local ROWS = Layout.ROWS
local WALL_H = Layout.WALL_H
local ORIGIN_X = Layout.ORIGIN_X
local ORIGIN_Z = Layout.ORIGIN_Z
local FLOOR_Y = Layout.FLOOR_Y
local STYLES = Layout.STYLES
local ROCK_COLOR = Layout.ROCK_COLOR
local cellCenter = Layout.cellCenter
local zoneOf = Layout.zoneOf

local function forEachRun(lines: number, items: number, test: (number, number) -> boolean, zoneAt: (number, number) -> string, emit: (number, number, number, string) -> ())
    for line = 0, lines - 1 do
        local start = -1
        local startZone = ""
        for item = 0, items do
            local passes = item < items and test(line, item)
            local zone = if item < items then zoneAt(line, item) else ""
            if start >= 0 and (not passes or zone ~= startZone) then
                emit(line, start, item - 1, startZone)
                start = -1
            end
            if passes and start < 0 then
                start = item
                startZone = zone
            end
        end
    end
end

local function buildCaveGeometry(grid: Grid)
    local mapFolder = Util.MapFolder :: Folder
    local cave = Instance.new("Folder")
    cave.Name = "Cave"
    cave.Parent = mapFolder

    -- Piso e teto, por trechos horizontais
    forEachRun(ROWS, COLS, function(r, c)
        return grid[r][c]
    end, function(_, c)
        return zoneOf(c)
    end, function(r, c0, c1, zone)
        local style = STYLES[zone]
        local length = (c1 - c0 + 1) * CELL
        local x = ORIGIN_X + c0 * CELL + length / 2
        local z = ORIGIN_Z + (r + 0.5) * CELL
        newPart("Floor", Vector3.new(length, 1, CELL), CFrame.new(x, FLOOR_Y - 0.5, z), { Material = style.material, Color = style.color }, cave)
        newPart("Ceiling", Vector3.new(length, 1, CELL), CFrame.new(x, FLOOR_Y + WALL_H + 0.5, z), { Material = Enum.Material.Rock, Color = ROCK_COLOR }, cave)
    end)

    -- Paredes norte e sul
    for _, dir in ipairs({ -1, 1 }) do
        forEachRun(ROWS, COLS, function(r, c)
            return grid[r][c] and not grid[r + dir][c]
        end, function(_, c)
            return zoneOf(c)
        end, function(r, c0, c1, zone)
            local length = (c1 - c0 + 1) * CELL
            local x = ORIGIN_X + c0 * CELL + length / 2
            local z = ORIGIN_Z + (r + (if dir == 1 then 1 else 0)) * CELL
            newPart("Wall", Vector3.new(length + 2, WALL_H, 2), CFrame.new(x, FLOOR_Y + WALL_H / 2, z), { Material = Enum.Material.Rock, Color = ROCK_COLOR:Lerp(STYLES[zone].color, 0.35) }, cave)
        end)
    end

    -- Paredes leste e oeste (linhas são colunas)
    for _, dir in ipairs({ -1, 1 }) do
        forEachRun(COLS, ROWS, function(c, r)
            return grid[r][c] and not grid[r][c + dir]
        end, function(c, _)
            return zoneOf(c)
        end, function(c, r0, r1, zone)
            local length = (r1 - r0 + 1) * CELL
            local z = ORIGIN_Z + r0 * CELL + length / 2
            local x = ORIGIN_X + (c + (if dir == 1 then 1 else 0)) * CELL
            newPart("Wall", Vector3.new(2, WALL_H, length + 2), CFrame.new(x, FLOOR_Y + WALL_H / 2, z), { Material = Enum.Material.Rock, Color = ROCK_COLOR:Lerp(STYLES[zone].color, 0.35) }, cave)
        end)
    end

    -- Luzes de teto, quase sempre fracas
    for r = 1, ROWS - 2 do
        for c = 1, COLS - 2 do
            if grid[r][c] and (c * 3 + r * 5) % 6 == 0 then
                local style = STYLES[zoneOf(c)]
                local center = cellCenter(c, r)
                local lamp = newPart("CaveLamp", Vector3.new(1.5, 1.5, 1.5), CFrame.new(center.X, FLOOR_Y + WALL_H - 1, center.Z), { Material = Enum.Material.Neon, Color = style.light, CanCollide = false }, cave)
                addLight(lamp, style.light, 24, 1.0)
            end
        end
    end
end

return { Build = buildCaveGeometry }
