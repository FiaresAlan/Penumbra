--!strict
-- Gera o lobby e a caverna em tempo de execução, de forma determinística.
-- Tudo que é criado aqui leva o Attribute Generated e é recriado a cada partida.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)

local MapBuilder = {}

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

local LEGACY_NAMES = { "Core1", "Core2", "Elevator", "CaveFloor", "LobbyElevator", "LobbyArrival", "CaveArrival", "Guardian" }

type Grid = { [number]: { [number]: boolean } }
type Style = { material: Enum.Material, color: Color3, light: Color3 }
type Rect = { c0: number, r0: number, c1: number, r1: number }

local STYLES: { [string]: Style } = {
    A = { material = Enum.Material.Pebble, color = Color3.fromRGB(150, 140, 125), light = Color3.fromRGB(255, 170, 90) },
    B = { material = Enum.Material.Slate, color = Color3.fromRGB(70, 75, 90), light = Color3.fromRGB(130, 170, 255) },
    C = { material = Enum.Material.Grass, color = Color3.fromRGB(35, 60, 45), light = Color3.fromRGB(90, 255, 190) },
}
local ROCK_COLOR = Color3.fromRGB(45, 42, 48)

local RARITY_COLORS: { [string]: Color3 } = {
    Common = Color3.fromRGB(120, 255, 220),
    Rare = Color3.fromRGB(190, 110, 255),
    Legendary = Color3.fromRGB(255, 200, 60),
}

local mapFolder: Folder

local function newPart(name: string, size: Vector3, cframe: CFrame, props: { [string]: any }?, parent: Instance): Part
    local part = Instance.new("Part")
    part.Name = name
    part.Anchored = true
    part.Size = size
    part.CFrame = cframe
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    if props then
        for key, value in pairs(props) do
            (part :: any)[key] = value
        end
    end
    part.Parent = parent
    return part
end

local function marker(name: string, size: Vector3, cframe: CFrame, parent: Instance): Part
    return newPart(name, size, cframe, { Transparency = 1, CanCollide = false, CanTouch = false }, parent)
end

local function topLevel(instance: Instance)
    instance:SetAttribute("Generated", true)
    instance.Parent = workspace
end

local function newFolder(name: string): Folder
    local folder = Instance.new("Folder")
    folder.Name = name
    topLevel(folder)
    return folder
end

local function addPrompt(parent: Instance, actionText: string, hold: number, distance: number): ProximityPrompt
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = actionText
    prompt.HoldDuration = hold
    prompt.MaxActivationDistance = distance
    prompt.RequiresLineOfSight = false
    prompt.Parent = parent
    return prompt
end

local function addLight(part: BasePart, color: Color3, range: number, brightness: number)
    local light = Instance.new("PointLight")
    light.Color = color
    light.Range = range
    light.Brightness = brightness
    light.Parent = part
end

local function clearPrevious()
    for _, child in ipairs(workspace:GetChildren()) do
        if child:GetAttribute("Generated") then
            child:Destroy()
        end
    end
    local oldTemplate = ServerStorage:FindFirstChild("CoreTemplate")
    if oldTemplate then
        oldTemplate:Destroy()
    end
    for _, name in ipairs(LEGACY_NAMES) do
        local old = workspace:FindFirstChild(name)
        if old and not old:GetAttribute("Generated") then
            old:Destroy()
        end
    end
end

-- Lobby ---------------------------------------------------------------------

local function lampPost(x: number, z: number)
    newPart("LampPole", Vector3.new(1, 12, 1), CFrame.new(x, 7, z), { Material = Enum.Material.Metal, Color = Color3.fromRGB(60, 60, 65) }, mapFolder)
    local bulb = newPart("LampBulb", Vector3.new(2, 2, 2), CFrame.new(x, 13.5, z), { Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 240, 200), CanCollide = false }, mapFolder)
    addLight(bulb, Color3.fromRGB(255, 240, 200), 40, 1.5)
end

local function buildLobby()
    newPart("LobbyFloor", Vector3.new(140, 1, 140), CFrame.new(0, 0.5, 0), { Material = Enum.Material.Concrete, Color = Color3.fromRGB(190, 190, 195) }, mapFolder)

    local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
    if not spawn then
        spawn = Instance.new("SpawnLocation")
        spawn.Anchored = true
        spawn.Neutral = true
        spawn.Parent = workspace
    end
    spawn.CFrame = CFrame.new(0, 1.5, 0)

    -- Plataforma do elevador (leste)
    newPart("ElevatorDeck", Vector3.new(24, 0.4, 24), CFrame.new(48, 1.2, 0), { Material = Enum.Material.DiamondPlate, Color = Color3.fromRGB(110, 115, 125) }, mapFolder)
    local lobbyElevator = newPart("LobbyElevator", Vector3.new(10, 5, 10), CFrame.new(48, 3.7, 0), { Material = Enum.Material.Metal, Color = Color3.fromRGB(70, 140, 220) }, workspace)
    lobbyElevator:SetAttribute("Generated", true)
    addPrompt(lobbyElevator, "Descer", 1, 14)

    -- Painel de estado do elevador (face voltada para o spawn); o texto é atualizado pelo LocationSync
    local statusGui = Instance.new("SurfaceGui")
    statusGui.Name = "StatusGui"
    statusGui.Face = Enum.NormalId.Left
    statusGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    statusGui.PixelsPerStud = 40
    statusGui.Parent = lobbyElevator
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "Status"
    statusLabel.Size = UDim2.fromScale(1, 1)
    statusLabel.BackgroundTransparency = 1
    statusLabel.TextColor3 = Color3.new(1, 1, 1)
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.TextScaled = true
    statusLabel.Text = "Pronto para descer"
    statusLabel.Parent = statusGui
    for _, dz in ipairs({ -7, 7 }) do
        newPart("ElevatorPillar", Vector3.new(2, 14, 2), CFrame.new(48, 8, dz), { Material = Enum.Material.Metal, Color = Color3.fromRGB(50, 55, 65) }, mapFolder)
    end
    marker("LobbyArrival", Vector3.new(4, 1, 4), CFrame.new(36, 2, 12), workspace):SetAttribute("Generated", true)

    -- Mural de destaques e quadro de pedidos (preparados para os módulos de UI)
    local wall = newPart("HighlightsWall", Vector3.new(1, 10, 22), CFrame.new(64, 7, -22), { Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(30, 30, 38) }, workspace)
    wall:SetAttribute("Generated", true)
    local orders = newPart("OrdersBoard", Vector3.new(1, 8, 14), CFrame.new(64, 6, 24), { Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(40, 30, 25) }, workspace)
    orders:SetAttribute("Generated", true)

    -- Mercado do Lobby (noroeste)
    local market = newPart("LobbyMarket", Vector3.new(12, 3, 5), CFrame.new(-30, 2.5, -30), { Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(150, 105, 60) }, workspace)
    market:SetAttribute("Generated", true)
    newPart("MarketRoof", Vector3.new(15, 1, 9), CFrame.new(-30, 10, -30), { Material = Enum.Material.Fabric, Color = Color3.fromRGB(200, 70, 60) }, mapFolder)
    for _, dx in ipairs({ -6, 6 }) do
        newPart("MarketPole", Vector3.new(1, 9, 1), CFrame.new(-30 + dx, 5.5, -33), { Material = Enum.Material.Wood, Color = Color3.fromRGB(100, 70, 40) }, mapFolder)
    end

    -- Oficina (sudoeste), com os suportes das Relíquias
    local workshop = newPart("LobbyWorkshop", Vector3.new(12, 3, 5), CFrame.new(-30, 2.5, 30), { Material = Enum.Material.Metal, Color = Color3.fromRGB(95, 100, 110) }, workspace)
    workshop:SetAttribute("Generated", true)
    newPart("WorkshopRoof", Vector3.new(15, 1, 9), CFrame.new(-30, 10, 30), { Material = Enum.Material.Metal, Color = Color3.fromRGB(70, 75, 85) }, mapFolder)
    local displays = newFolder("RelicDisplays")
    for index, z in ipairs({ 24, 30, 36 }) do
        local stand = newPart("RelicStand" .. index, Vector3.new(3, 3, 3), CFrame.new(-48, 2.5, z), { Material = Enum.Material.Marble, Color = Color3.fromRGB(220, 220, 225) }, displays)
        stand:SetAttribute("Generated", true)
    end

    -- Quadro de contratos (norte)
    local board = newPart("LobbyBoard", Vector3.new(14, 8, 1), CFrame.new(0, 5, -60), { Material = Enum.Material.Wood, Color = Color3.fromRGB(110, 80, 50) }, workspace)
    board:SetAttribute("Generated", true)

    for _, point in ipairs({ { -55, -55 }, { 55, -55 }, { -55, 55 }, { 55, 55 }, { 0, 40 }, { 0, -40 }, { 30, -16 }, { -30, 0 } }) do
        lampPost(point[1], point[2])
    end
end

-- Caverna -------------------------------------------------------------------

local function cellCenter(c: number, r: number): Vector3
    return Vector3.new(ORIGIN_X + (c + 0.5) * CELL, FLOOR_Y, ORIGIN_Z + (r + 0.5) * CELL)
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
    for _ = 1, 45 do
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

-- Percorre linhas de itens e emite trechos contínuos que passam no teste e têm a mesma zona.
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
            if grid[r][c] and (c * 3 + r * 5) % 4 == 0 then
                local style = STYLES[zoneOf(c)]
                local center = cellCenter(c, r)
                local lamp = newPart("CaveLamp", Vector3.new(1.5, 1.5, 1.5), CFrame.new(center.X, FLOOR_Y + WALL_H - 1, center.Z), { Material = Enum.Material.Neon, Color = style.light, CanCollide = false }, cave)
                addLight(lamp, style.light, 28, 1.2)
            end
        end
    end
end

local function shuffle<T>(list: { T }, rng: Random)
    for i = #list, 2, -1 do
        local j = rng:NextInteger(1, i)
        list[i], list[j] = list[j], list[i]
    end
end

local function makeCore(name: string, position: Vector3, rarity: string, depthZone: string, itemType: string?, parent: Instance?): Part
    local core = Instance.new("Part")
    core.Name = name
    core.Shape = Enum.PartType.Ball
    local isRelic = itemType == "Relic"
    core.Size = if isRelic then Vector3.new(3.4, 3.4, 3.4) else Vector3.new(2.4, 2.4, 2.4)
    core.Position = position
    core.Anchored = true
    core.Material = Enum.Material.Neon
    core.Color = if isRelic then Color3.fromRGB(255, 120, 210) else RARITY_COLORS[rarity]
    core:SetAttribute("IsCore", true)
    core:SetAttribute("Rarity", rarity)
    core:SetAttribute("DepthZone", depthZone)
    core:SetAttribute("ItemType", itemType or "Core")
    addLight(core, RARITY_COLORS[rarity], 14, 1.5)
    addPrompt(core, "Pegar", 0.5, 10)
    core.Parent = parent or mapFolder
    return core
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

local function placeCores(grid: Grid, rng: Random)
    local lists = openCellsByZone(grid)
    local counter = 0
    local function spawnIn(zone: string, rarities: { string })
        local cells = lists[zone]
        shuffle(cells, rng)
        for index, rarity in ipairs(rarities) do
            local cell = cells[index]
            if cell then
                counter += 1
                local center = cellCenter(cell[1], cell[2])
                makeCore("Core" .. counter, center + Vector3.new(0, 2.2, 0), rarity, zone)
            end
        end
    end
    spawnIn("A", { "Common", "Common", "Common", "Common", "Common", "Common" })
    spawnIn("B", { "Common", "Common", "Common", "Common", "Rare", "Rare" })
    spawnIn("C", { "Rare", "Rare" })

    -- Relíquias: uma na zona B, uma na zona C e uma na câmara do núcleo
    local relicCells = { { lists.B[7], "B" }, { lists.C[3], "C" } }
    for _, entry in ipairs(relicCells) do
        local cell = entry[1] :: { number }?
        if cell then
            counter += 1
            makeCore("Relic" .. counter, cellCenter(cell[1], cell[2]) + Vector3.new(0, 2.4, 0), "Legendary", entry[2] :: string, "Relic")
        end
    end
    counter += 1
    makeCore("Relic" .. counter, cellCenter(21, 8) + Vector3.new(0, 2.4, 0), "Legendary", "C", "Relic")

    local veins = { { 22, 6, "Rare" }, { 26, 6, "Legendary" }, { 22, 10, "Rare" }, { 26, 10, "Legendary" }, { 24, 6, "Rare" }, { 24, 10, "Legendary" } }
    for _, vein in ipairs(veins) do
        counter += 1
        makeCore("Core" .. counter, cellCenter(vein[1] :: number, vein[2] :: number) + Vector3.new(0, 2.2, 0), vein[3] :: string, "C")
    end
end

local function buildCaveMarkers(grid: Grid, rng: Random)
    -- Elevador de extração e pontos de chegada (sala de entrada)
    local elevatorPos = cellCenter(5, 8)
    local elevator = newPart("Elevator", Vector3.new(8, 14, 8), CFrame.new(elevatorPos.X, FLOOR_Y + 7, elevatorPos.Z), { Material = Enum.Material.Metal, Color = Color3.fromRGB(225, 180, 60) }, workspace)
    elevator:SetAttribute("Generated", true)
    addPrompt(elevator, "Chamar elevador", 1, 12)

    local arrival = cellCenter(2, 8)
    marker("CaveArrival", Vector3.new(4, 1, 4), CFrame.new(arrival.X, FLOOR_Y + 1, arrival.Z), workspace):SetAttribute("Generated", true)

    local pity = cellCenter(4, 6)
    marker("PitySpawnPoint", Vector3.new(2, 1, 2), CFrame.new(pity.X, FLOOR_Y + 2, pity.Z), workspace):SetAttribute("Generated", true)

    -- Zonas de fúria: sala de entrada (perto do elevador) e câmara do núcleo
    local fury = newFolder("FuryZones")
    for index, rect in ipairs({ ENTRANCE, CHAMBER }) do
        local a = cellCenter(rect.c0, rect.r0)
        local b = cellCenter(rect.c1, rect.r1)
        local center = (a + b) / 2
        local size = Vector3.new(b.X - a.X + CELL, WALL_H, b.Z - a.Z + CELL)
        marker("FuryZone" .. index, size, CFrame.new(center.X, FLOOR_Y + WALL_H / 2, center.Z), fury)
        -- Rachaduras vermelhas no chão marcam a zona para o jogador
        for step = 0, 3 do
            local cx = a.X - CELL / 2 + (size.X) * (step + 0.5) / 4
            newPart("FuryCrack", Vector3.new(size.X / 6, 0.1, 0.8), CFrame.new(cx, FLOOR_Y + 0.05, a.Z - CELL / 2 + 1), { Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 40, 40), CanCollide = false, Transparency = 0.35 }, mapFolder)
        end
    end

    -- Ninho: vagas dos presos
    local nest = newFolder("NestSlots")
    for index, cell in ipairs({ { 23, 14 }, { 25, 14 }, { 27, 14 }, { 25, 13 } }) do
        local center = cellCenter(cell[1], cell[2])
        marker("NestSlot" .. index, Vector3.new(4, 1, 4), CFrame.new(center.X, FLOOR_Y + 2, center.Z), nest)
        newPart("NestMark", Vector3.new(10, 0.15, 10), CFrame.new(center.X, FLOOR_Y + 0.08, center.Z), { Material = Enum.Material.Neon, Color = Color3.fromRGB(150, 20, 30), CanCollide = false, Transparency = 0.5 }, mapFolder)
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
        local size = if candidate[3] == "ew" then Vector3.new(2, WALL_H * 0.9, CELL) else Vector3.new(CELL, WALL_H * 0.9, 2)
        marker("FakeWallSlot" .. index, size, CFrame.new(center.X, FLOOR_Y + size.Y / 2, center.Z), walls)
    end

    -- Poças na zona B
    local puddles = openCellsByZone(grid).B
    shuffle(puddles, rng)
    for index = 1, math.min(6, #puddles) do
        local center = cellCenter(puddles[index][1], puddles[index][2])
        newPart("Puddle", Vector3.new(CELL * 0.8, 0.1, CELL * 0.8), CFrame.new(center.X, FLOOR_Y + 0.05, center.Z), { Material = Enum.Material.Glass, Color = Color3.fromRGB(60, 120, 200), Transparency = 0.45, CanCollide = false }, mapFolder)
    end
end

-- Saliências altas que só o gancho alcança, com um núcleo em cima de cada uma.
local function buildLedges()
    local hooks = newFolder("HookPoints")
    local ledges = { { 12, 3, "B", "Rare" }, { 15, 11, "B", "Rare" }, { 27, 11, "C", "Legendary" } }
    for index, ledge in ipairs(ledges) do
        local center = cellCenter(ledge[1] :: number, ledge[2] :: number)
        local zone = ledge[3] :: string
        local topY = FLOOR_Y + 10
        newPart("Ledge", Vector3.new(CELL * 1.5, 1, CELL * 1.2), CFrame.new(center.X, topY - 0.5, center.Z),
            { Material = Enum.Material.Slate, Color = STYLES[zone].color:Lerp(Color3.new(0, 0, 0), 0.3) }, mapFolder)
        -- Faixa luminosa na borda: marca visualmente onde o gancho pode prender
        newPart("HookGlow", Vector3.new(CELL * 1.5, 0.3, 0.6), CFrame.new(center.X, topY + 0.15, center.Z + CELL * 0.6 - 0.3),
            { Material = Enum.Material.Neon, Color = Color3.fromRGB(80, 220, 255), CanCollide = false }, mapFolder)
        -- O ponto fica na borda da frente, fora do bloco, para haver linha de visão vinda do chão.
        -- O atributo Land diz onde o jogador aterrissa em relação ao ponto (para dentro da saliência).
        local hook = marker("Hook" .. index, Vector3.new(4, 1, 4), CFrame.new(center.X, topY + 1, center.Z + CELL * 0.6 + 0.5), hooks)
        hook:SetAttribute("Land", Vector3.new(0, 3, -4.5))
        makeCore("LedgeCore" .. index, Vector3.new(center.X + 4, topY + 2.4, center.Z), ledge[4] :: string, zone)
    end
end

local function buildGuardian()
    local home = cellCenter(24, 8)
    task.spawn(function()
        local ok, model = pcall(function()
            return Players:CreateHumanoidModelFromDescription(Instance.new("HumanoidDescription"), Enum.HumanoidRigType.R15)
        end)
        if not ok or not model then
            warn("[Map] Não foi possível criar o Guardião: " .. tostring(model))
            return
        end
        model.Name = "Guardian"
        for _, descendant in ipairs(model:GetDescendants()) do
            if descendant:IsA("BasePart") then
                descendant.Color = Color3.fromRGB(22, 18, 28)
                descendant.Material = Enum.Material.Slate
            elseif descendant:IsA("Decal") then
                descendant:Destroy()
            end
        end
        local humanoid = model:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            humanoid.WalkSpeed = 0
        end
        model:ScaleTo(1.7)
        model:PivotTo(CFrame.new(home + Vector3.new(0, 6, 0)))
        model:SetAttribute("Generated", true)
        model.Parent = workspace
        local root = model:FindFirstChild("HumanoidRootPart")
        if root and root:IsA("BasePart") then
            root:SetNetworkOwner(nil)
            local eyes = Instance.new("PointLight")
            eyes.Color = Color3.fromRGB(255, 60, 60)
            eyes.Range = 18
            eyes.Brightness = 1
            eyes.Parent = root
        end
    end)
end

function MapBuilder.Build()
    clearPrevious()

    mapFolder = Instance.new("Folder")
    mapFolder.Name = "Map"
    topLevel(mapFolder)

    local rng = Random.new(Config.MapSeed)
    buildLobby()

    local grid = carveCave(rng)
    buildCaveGeometry(grid)
    placeCores(grid, rng)
    -- Modelo para núcleos criados em tempo de jogo (pity, Enganador)
    makeCore("CoreTemplate", Vector3.zero, "Common", "A", "Core", ServerStorage)
    buildCaveMarkers(grid, rng)
    buildLedges()
    buildGuardian()

    print(string.format("[Map] Mapa gerado (seed %d, %d partes)", Config.MapSeed, #mapFolder:GetDescendants()))
end

return MapBuilder
