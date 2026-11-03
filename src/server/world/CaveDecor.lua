--!strict
-- Decoração da caverna: espinhos, pedras, cristais, pilares, vigas e poeira.

local Util = require(script.Parent:WaitForChild("WorldUtil") :: ModuleScript)
local Layout = require(script.Parent:WaitForChild("CaveLayout") :: ModuleScript)

type Grid = Layout.Grid
local newPart = Util.newPart
local addLight = Util.addLight
local CELL = Layout.CELL
local COLS = Layout.COLS
local ROWS = Layout.ROWS
local WALL_H = Layout.WALL_H
local floorAt = Layout.floorAt
local ceilingAt = Layout.ceilingAt
local STYLES = Layout.STYLES
local ROCK_COLOR = Layout.ROCK_COLOR
local cellCenter = Layout.cellCenter
local zoneOf = Layout.zoneOf
local isSpecial = Layout.isSpecial

local function buildCaveDecor(grid: Grid, rng: Random)
    local mapFolder = Util.MapFolder :: Folder
    local decor = Instance.new("Folder")
    decor.Name = "Decor"
    decor.Parent = mapFolder

    local function randomAngles(): CFrame
        return CFrame.Angles(rng:NextNumber() * math.pi, rng:NextNumber() * math.pi, rng:NextNumber() * math.pi)
    end

    -- Espinho de rocha feito de cilindros empilhados (estalactite para baixo, estalagmite para cima)
    local function spike(x: number, z: number, hangingFromCeiling: boolean, scale: number, color: Color3)
        local baseY = if hangingFromCeiling then ceilingAt(x, z) + 0.6 else floorAt(x, z) - 0.4
        local direction = if hangingFromCeiling then -1 else 1
        local levels = { { 2.4, 3.2 }, { 2.2, 2.2 }, { 2.0, 1.2 }, { 1.6, 0.5 } }
        local offset = 0
        for _, level in ipairs(levels) do
            local height = level[1] * scale
            local diameter = level[2] * scale
            local y = baseY + direction * (offset + height / 2)
            newPart("Spike", Vector3.new(height, diameter, diameter), CFrame.new(x, y, z) * CFrame.Angles(0, 0, math.pi / 2),
                { Material = Enum.Material.Rock, Color = color, CanCollide = false }, decor)
            offset += height
        end
    end

    for r = 1, ROWS - 2 do
        for c = 1, COLS - 2 do
            if grid[r][c] then
                local center = cellCenter(c, r)
                local style = STYLES[zoneOf(c)]
                local rock = ROCK_COLOR:Lerp(style.color, 0.5)

                -- Estalactites no teto e estalagmites no chão
                if rng:NextNumber() < 0.3 then
                    spike(center.X + (rng:NextNumber() - 0.5) * 10, center.Z + (rng:NextNumber() - 0.5) * 10, true, 0.7 + rng:NextNumber() * 1.1, rock)
                end
                if rng:NextNumber() < 0.15 and not isSpecial(c, r) then
                    spike(center.X + (rng:NextNumber() - 0.5) * 10, center.Z + (rng:NextNumber() - 0.5) * 10, false, 0.5 + rng:NextNumber() * 0.8, rock)
                end

                -- Pedras redondas no chão, em parte enterradas
                if rng:NextNumber() < 0.12 then
                    local size = 3 + rng:NextNumber() * 4
                    local bx = center.X + (rng:NextNumber() - 0.5) * 10
                    local bz = center.Z + (rng:NextNumber() - 0.5) * 10
                    newPart("Boulder", Vector3.new(size, size * 0.8, size), CFrame.new(bx, floorAt(bx, bz) + size * 0.15, bz) * randomAngles(),
                        { Material = Enum.Material.Rock, Color = rock, Shape = Enum.PartType.Ball }, decor)
                end

                -- Saliências nas paredes: blocos girados que quebram a superfície reta
                for _, dir in ipairs({ { 0, -1 }, { 0, 1 }, { -1, 0 }, { 1, 0 } }) do
                    if not grid[r + dir[2]][c + dir[1]] and rng:NextNumber() < 0.35 then
                        local along = (rng:NextNumber() - 0.5) * (CELL - 4)
                        local height = 2 + rng:NextNumber() * 10
                        local edge = Vector3.new(center.X + dir[1] * CELL / 2, 0, center.Z + dir[2] * CELL / 2)
                        local px = edge.X - dir[1] * 1.0 + (if dir[1] == 0 then along else 0)
                        local pz = edge.Z - dir[2] * 1.0 + (if dir[2] == 0 then along else 0)
                        local position = Vector3.new(px, floorAt(px, pz) + height, pz)
                        newPart("WallRock", Vector3.new(3 + rng:NextNumber() * 3, 3 + rng:NextNumber() * 5, 3 + rng:NextNumber() * 3),
                            CFrame.new(position) * randomAngles(), { Material = Enum.Material.Rock, Color = rock }, decor)
                    end
                end

                -- Cristais luminosos na zona C
                if zoneOf(c) == "C" and not isSpecial(c, r) and rng:NextNumber() < 0.3 then
                    local baseX = center.X + (rng:NextNumber() - 0.5) * 9
                    local baseZ = center.Z + (rng:NextNumber() - 0.5) * 9
                    local base = Vector3.new(baseX, floorAt(baseX, baseZ) - 0.3, baseZ)
                    local color = if rng:NextNumber() < 0.5 then Color3.fromRGB(80, 255, 200) else Color3.fromRGB(160, 110, 255)
                    for index = 1, 3 do
                        local height = 2.5 + rng:NextNumber() * 3.5
                        local crystal = newPart("Crystal", Vector3.new(0.9, height, 0.9),
                            CFrame.new(base + Vector3.new((index - 2) * 1.1, height / 2, rng:NextNumber() - 0.5)) * CFrame.Angles((rng:NextNumber() - 0.5) * 0.5, rng:NextNumber() * 3, (rng:NextNumber() - 0.5) * 0.5),
                            { Material = Enum.Material.Neon, Color = color, CanCollide = false, Transparency = 0.1 }, decor)
                        if index == 2 then
                            addLight(crystal, color, 14, 1.2)
                        end
                    end
                end
            end
        end
    end

    -- Pilares nas salas grandes
    local pillars = { { 2, 6 }, { 4, 6 }, { 2, 10 }, { 4, 10 }, { 21, 5 }, { 27, 5 }, { 21, 11 } }
    for _, cell in ipairs(pillars) do
        local center = cellCenter(cell[1], cell[2])
        local pillarFloor = floorAt(center.X, center.Z)
        local pillarCeiling = ceilingAt(center.X, center.Z)
        newPart("Pillar", Vector3.new(pillarCeiling - pillarFloor + 2, 4, 4), CFrame.new(center.X, (pillarFloor + pillarCeiling) / 2, center.Z) * CFrame.Angles(0, 0, math.pi / 2),
            { Material = Enum.Material.Rock, Color = ROCK_COLOR:Lerp(STYLES[zoneOf(cell[1])].color, 0.4), Shape = Enum.PartType.Cylinder }, decor)
    end

    -- Zona A: estacas e vigas de madeira nos corredores retos, como uma mina antiga
    local frames = 0
    for r = 1, ROWS - 2 do
        for c = 1, 9 do
            if frames < 12 and grid[r][c] and not isSpecial(c, r) and rng:NextNumber() < 0.35 then
                local center = cellCenter(c, r)
                local wood = { Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(96, 68, 42) }
                local postLength = ceilingAt(center.X, center.Z) - floorAt(center.X, center.Z) + 1
                local postY = (ceilingAt(center.X, center.Z) + floorAt(center.X, center.Z)) / 2
                local beamY = ceilingAt(center.X, center.Z) - 2
                if grid[r][c - 1] and grid[r][c + 1] and not grid[r - 1][c] and not grid[r + 1][c] then
                    for _, side in ipairs({ -1, 1 }) do
                        newPart("MinePost", Vector3.new(1.4, postLength, 1.4), CFrame.new(center.X, postY, center.Z + side * (CELL / 2 - 1.2)), wood, decor)
                    end
                    newPart("MineBeam", Vector3.new(1.4, 1.4, CELL - 1), CFrame.new(center.X, beamY, center.Z), wood, decor)
                    frames += 1
                elseif grid[r - 1][c] and grid[r + 1][c] and not grid[r][c - 1] and not grid[r][c + 1] then
                    for _, side in ipairs({ -1, 1 }) do
                        newPart("MinePost", Vector3.new(1.4, postLength, 1.4), CFrame.new(center.X + side * (CELL / 2 - 1.2), postY, center.Z), wood, decor)
                    end
                    newPart("MineBeam", Vector3.new(CELL - 1, 1.4, 1.4), CFrame.new(center.X, beamY, center.Z), wood, decor)
                    frames += 1
                end
            end
        end
    end

    -- Poeira flutuando em algumas células (volume invisível que emite partículas)
    for _ = 1, 24 do
        local c = rng:NextInteger(1, COLS - 2)
        local r = rng:NextInteger(1, ROWS - 2)
        if grid[r][c] then
            local center = cellCenter(c, r)
            local box = newPart("DustEmitter", Vector3.new(CELL, 10, CELL), CFrame.new(center.X, center.Y + 7, center.Z), { Transparency = 1, CanCollide = false, CanTouch = false, CanQuery = false }, decor)
            local dust = Instance.new("ParticleEmitter")
            dust.Rate = 3
            dust.Lifetime = NumberRange.new(7, 11)
            dust.Speed = NumberRange.new(0.2, 0.7)
            dust.Size = NumberSequence.new(0.12, 0.2)
            dust.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.55), NumberSequenceKeypoint.new(1, 1) })
            dust.Color = ColorSequence.new(Color3.fromRGB(190, 190, 200))
            dust.LightEmission = 0.15
            dust.RotSpeed = NumberRange.new(-20, 20)
            dust.Shape = Enum.ParticleEmitterShape.Box
            dust.Parent = box
        end
    end
end

return { Build = buildCaveDecor }
