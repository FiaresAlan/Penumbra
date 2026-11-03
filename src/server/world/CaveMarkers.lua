--!strict
-- Marcadores de jogo da caverna: elevador, chegada, zonas de fúria, Ninho, paredes falsas, poças e saliências do gancho.

local Util = require(script.Parent:WaitForChild("WorldUtil") :: ModuleScript)
local Layout = require(script.Parent:WaitForChild("CaveLayout") :: ModuleScript)
local Cores = require(script.Parent:WaitForChild("Cores") :: ModuleScript)

type Grid = Layout.Grid
local newPart = Util.newPart
local marker = Util.marker
local newFolder = Util.newFolder
local addPrompt = Util.addPrompt
local CELL = Layout.CELL
local ROWS = Layout.ROWS
local WALL_H = Layout.WALL_H
local FLOOR_Y = Layout.FLOOR_Y
local floorAt = Layout.floorAt
local ceilingAt = Layout.ceilingAt
local CaveShape = require(script.Parent:WaitForChild("CaveShape") :: ModuleScript)
local ENTRANCE = Layout.ENTRANCE
local CHAMBER = Layout.CHAMBER
local STYLES = Layout.STYLES
local cellCenter = Layout.cellCenter
local POND_WATER = 11
local isSpecial = Layout.isSpecial
local shuffle = Layout.shuffle
local openCellsByZone = Layout.openCellsByZone

local function buildCaveMarkers(grid: Grid, rng: Random)
    local mapFolder = Util.MapFolder :: Folder
    -- Elevador de extração e pontos de chegada (sala de entrada)
    local elevatorPos = cellCenter(5, 8)
    local elevator = newPart("Elevator", Vector3.new(8, 14, 8), CFrame.new(elevatorPos.X, elevatorPos.Y + 7, elevatorPos.Z), { Material = Enum.Material.Metal, Color = Color3.fromRGB(225, 180, 60) }, workspace)
    elevator:SetAttribute("Generated", true)
    addPrompt(elevator, "Chamar elevador", 1, 12)

    local arrival = cellCenter(2, 8)
    marker("CaveArrival", Vector3.new(4, 1, 4), CFrame.new(arrival.X, arrival.Y + 1, arrival.Z), workspace):SetAttribute("Generated", true)

    local pity = cellCenter(4, 6)
    marker("PitySpawnPoint", Vector3.new(2, 1, 2), CFrame.new(pity.X, pity.Y + 2, pity.Z), workspace):SetAttribute("Generated", true)

    -- Zonas de fúria: sala de entrada (perto do elevador) e câmara do núcleo
    local fury = newFolder("FuryZones")
    for index, rect in ipairs({ ENTRANCE, CHAMBER }) do
        local a = cellCenter(rect.c0, rect.r0)
        local b = cellCenter(rect.c1, rect.r1)
        local center = (a + b) / 2
        local size = Vector3.new(b.X - a.X + CELL, WALL_H + 12, b.Z - a.Z + CELL)
        marker("FuryZone" .. index, size, CFrame.new(center.X, FLOOR_Y + (WALL_H + 12) / 2 - 6, center.Z), fury)
        -- Rachaduras vermelhas no chão marcam a zona para o jogador
        for step = 0, 3 do
            local cx = a.X - CELL / 2 + (size.X) * (step + 0.5) / 4
            newPart("FuryCrack", Vector3.new(size.X / 6, 0.1, 0.8), CFrame.new(cx, floorAt(cx, a.Z - CELL / 2 + 1) + 0.08, a.Z - CELL / 2 + 1), { Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 40, 40), CanCollide = false, Transparency = 0.35 }, mapFolder)
        end
    end

    -- Ninho: vagas dos presos
    local nest = newFolder("NestSlots")
    for index, cell in ipairs({ { 23, 14 }, { 25, 14 }, { 27, 14 }, { 25, 13 } }) do
        local center = cellCenter(cell[1], cell[2])
        marker("NestSlot" .. index, Vector3.new(4, 1, 4), CFrame.new(center.X, center.Y + 2, center.Z), nest)
        newPart("NestMark", Vector3.new(10, 0.15, 10), CFrame.new(center.X, center.Y + 0.08, center.Z), { Material = Enum.Material.Neon, Color = Color3.fromRGB(150, 20, 30), CanCollide = false, Transparency = 0.5 }, mapFolder)
    end

    -- Vagas de paredes falsas: corredores retos da zona B
    local walls = newFolder("FakeWallSlots")
    local candidates: { { any } } = {}
    for r = 1, ROWS - 2 do
        for c = 10, 18 do
            if grid[r][c] and not isSpecial(c, r) then
                if grid[r][c - 1] and grid[r][c + 1] and not grid[r - 1][c] and not grid[r + 1][c] then
                    table.insert(candidates, { c, r, "ew" })
                elseif grid[r - 1][c] and grid[r + 1][c] and not grid[r][c - 1] and not grid[r][c + 1] then
                    table.insert(candidates, { c, r, "ns" })
                end
            end
        end
    end
    shuffle(candidates, rng)
    for index = 1, math.min(4, #candidates) do
        local candidate = candidates[index]
        local center = cellCenter(candidate[1] :: number, candidate[2] :: number)
        -- Mais alta e mais larga que o corredor, para entrar no Terrain dos dois lados, no chão e no teto, sem deixar fresta
        local tall = WALL_H * 1.7
        local size = if candidate[3] == "ew" then Vector3.new(2, tall, CELL + 10) else Vector3.new(CELL + 10, tall, 2)
        marker("FakeWallSlot" .. index, size, CFrame.new(center.X, FLOOR_Y + tall / 2 - 4, center.Z), walls)
    end

    -- Poças na zona B
    local puddles: { { number } } = {}
    for _, cell in ipairs(openCellsByZone(grid).B) do
        if CaveShape.IsPond(cell[1], cell[2]) then
            table.insert(puddles, cell)
        end
    end
    shuffle(puddles, rng)
    for index = 1, math.min(8, #puddles) do
        local center = cellCenter(puddles[index][1], puddles[index][2])
        newPart("Puddle", Vector3.new(0.1, POND_WATER, POND_WATER), CFrame.new(center.X, CaveShape.PondLevel(), center.Z) * CFrame.Angles(0, 0, math.pi / 2), { Material = Enum.Material.Glass, Color = Color3.fromRGB(60, 120, 200), Transparency = 0.45, CanCollide = false, Reflectance = 0.35, Shape = Enum.PartType.Cylinder }, mapFolder)
        -- Gotas caindo do teto sobre a poça
        local dripSource = newPart("DripEmitter", Vector3.new(2, 0.5, 2), CFrame.new(center.X, ceilingAt(center.X, center.Z) - 0.5, center.Z), { Transparency = 1, CanCollide = false, CanTouch = false, CanQuery = false }, mapFolder)
        local drip = Instance.new("ParticleEmitter")
        drip.Rate = 1.2
        drip.Lifetime = NumberRange.new(0.8, 1.0)
        drip.Speed = NumberRange.new(0, 0)
        drip.Acceleration = Vector3.new(0, -45, 0)
        drip.Size = NumberSequence.new(0.25)
        drip.Color = ColorSequence.new(Color3.fromRGB(140, 190, 255))
        drip.Transparency = NumberSequence.new(0.2)
        drip.LightEmission = 0.3
        drip.Parent = dripSource
    end
end

local function buildLedges()
    local mapFolder = Util.MapFolder :: Folder
    local hooks = newFolder("HookPoints")
    local ledges = { { 12, 3, "B", "Rare" }, { 15, 11, "B", "Rare" }, { 27, 11, "C", "Legendary" } }
    for index, ledge in ipairs(ledges) do
        local center = cellCenter(ledge[1] :: number, ledge[2] :: number)
        local zone = ledge[3] :: string
        local topY = center.Y + 10
        newPart("Ledge", Vector3.new(CELL * 1.5, 1, CELL * 1.2), CFrame.new(center.X, topY - 0.5, center.Z),
            { Material = Enum.Material.Slate, Color = STYLES[zone].color:Lerp(Color3.new(0, 0, 0), 0.3) }, mapFolder)
        -- Faixa luminosa na borda: marca visualmente onde o gancho pode prender
        newPart("HookGlow", Vector3.new(CELL * 1.5, 0.3, 0.6), CFrame.new(center.X, topY + 0.15, center.Z + CELL * 0.6 - 0.3),
            { Material = Enum.Material.Neon, Color = Color3.fromRGB(80, 220, 255), CanCollide = false }, mapFolder)
        -- O ponto fica na borda da frente, fora do bloco, para haver linha de visão vinda do chão.
        -- O atributo Land diz onde o jogador aterrissa em relação ao ponto (para dentro da saliência).
        local hook = marker("Hook" .. index, Vector3.new(4, 1, 4), CFrame.new(center.X, topY + 1, center.Z + CELL * 0.6 + 0.5), hooks)
        hook:SetAttribute("Land", Vector3.new(0, 3, -4.5))
        Cores.makeCore("LedgeCore" .. index, Vector3.new(center.X + 4, topY + 2.4, center.Z), ledge[4] :: string, zone)
    end
end

return { Build = buildCaveMarkers, BuildLedges = buildLedges }
