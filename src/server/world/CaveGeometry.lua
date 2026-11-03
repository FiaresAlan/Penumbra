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

    -- Luzes de teto, quase sempre fracas. Cada zona tem a sua forma: lampião pendurado (A), cristal azul (B), cacho de fungos (C)
    local ceilingY = FLOOR_Y + WALL_H
    for r = 1, ROWS - 2 do
        for c = 1, COLS - 2 do
            if grid[r][c] and (c * 3 + r * 5) % 6 == 0 then
                local zone = zoneOf(c)
                local style = STYLES[zone]
                local center = cellCenter(c, r)
                local glow: Part
                if zone == "A" then
                    local chain = newPart("CaveLampChain", Vector3.new(0.15, 2.2, 0.15), CFrame.new(center.X, ceilingY - 1.1, center.Z), { Material = Enum.Material.Metal, Color = Color3.fromRGB(40, 36, 34), CanCollide = false }, cave)
                    chain.CastShadow = false
                    local cap = newPart("CaveLampCap", Vector3.new(1.3, 0.5, 1.3), CFrame.new(center.X, ceilingY - 2.3, center.Z), { Material = Enum.Material.Wood, Color = Color3.fromRGB(92, 62, 38), CanCollide = false }, cave)
                    cap.CastShadow = false
                    glow = newPart("CaveLamp", Vector3.new(0.9, 1.1, 0.9), CFrame.new(center.X, ceilingY - 3.1, center.Z), { Material = Enum.Material.Neon, Color = style.light, CanCollide = false, Shape = Enum.PartType.Ball }, cave)
                elseif zone == "B" then
                    glow = newPart("CaveLamp", Vector3.new(0.8, 2.6, 0.8), CFrame.new(center.X, ceilingY - 1.5, center.Z) * CFrame.Angles(math.rad(12), math.rad((c * 37 + r * 11) % 90), math.rad(45)), { Material = Enum.Material.Neon, Color = style.light, CanCollide = false }, cave)
                else
                    glow = newPart("CaveLamp", Vector3.new(0.9, 0.9, 0.9), CFrame.new(center.X, ceilingY - 1.2, center.Z), { Material = Enum.Material.Neon, Color = style.light, CanCollide = false, Shape = Enum.PartType.Ball }, cave)
                    for k = 1, 2 do
                        local angle = (c * 5 + r * 3 + k * 2.1) % 6.28
                        local small = newPart("CaveLampSpore", Vector3.new(0.5, 0.5, 0.5), CFrame.new(center.X + math.cos(angle) * 0.9, ceilingY - 0.8 - k * 0.4, center.Z + math.sin(angle) * 0.9), { Material = Enum.Material.Neon, Color = style.light:Lerp(Color3.new(1, 1, 1), 0.3), CanCollide = false, Shape = Enum.PartType.Ball }, cave)
                        small.CastShadow = false
                    end
                end
                glow.CastShadow = false
                addLight(glow, style.light, 24, 1.0)
            end
        end
    end
end

return { Build = buildCaveGeometry }
