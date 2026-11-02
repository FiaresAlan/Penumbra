--!strict
-- Gera o lobby e a caverna em tempo de execução, de forma determinística.
-- Tudo que é criado aqui leva o Attribute Generated e é recriado a cada partida.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local AssetService = game:GetService("AssetService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local Assets = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Assets") :: ModuleScript)

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
    B = { material = Enum.Material.Slate, color = Color3.fromRGB(104, 112, 138), light = Color3.fromRGB(130, 170, 255) },
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
    local wallGui = Instance.new("SurfaceGui")
    wallGui.Name = "HighlightsGui"
    wallGui.Face = Enum.NormalId.Left
    wallGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    wallGui.PixelsPerStud = 30
    wallGui.Parent = wall
    local wallLabel = Instance.new("TextLabel")
    wallLabel.Name = "Text"
    wallLabel.Size = UDim2.fromScale(1, 1)
    wallLabel.BackgroundTransparency = 1
    wallLabel.TextColor3 = Color3.fromRGB(235, 235, 245)
    wallLabel.Font = Enum.Font.GothamBold
    wallLabel.TextScaled = true
    wallLabel.TextXAlignment = Enum.TextXAlignment.Left
    wallLabel.TextYAlignment = Enum.TextYAlignment.Top
    wallLabel.Text = "MURAL DE DESTAQUES"
    wallLabel.Parent = wallGui
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

-- Floresta e Mercado Negro (a oeste do lobby, a uma curta caminhada da Oficina) --------------

local function buildForest(rng: Random)
    newPart("ForestGround", Vector3.new(140, 1, 130), CFrame.new(-140, 0.5, 0), { Material = Enum.Material.Grass, Color = Color3.fromRGB(52, 92, 50) }, mapFolder)

    for _ = 1, 38 do
        local x = -75 - rng:NextNumber() * 130
        local z = (rng:NextNumber() - 0.5) * 120
        -- Deixa a clareira do mercado livre
        if (Vector3.new(x, 0, z) - Vector3.new(-135, 0, 0)).Magnitude > 22 then
            local height = 14 + rng:NextNumber() * 10
            newPart("TreeTrunk", Vector3.new(2.4, height, 2.4), CFrame.new(x, 1 + height / 2, z), { Material = Enum.Material.Wood, Color = Color3.fromRGB(86, 62, 40) }, mapFolder)
            newPart("TreeLeaves", Vector3.new(12, 10, 12), CFrame.new(x, 1 + height + 3, z), { Material = Enum.Material.Grass, Color = Color3.fromRGB(34, 78, 38), Shape = Enum.PartType.Ball }, mapFolder)
        end
    end

    -- Barraca do Mercado Negro
    local stall = newPart("BlackMarketStall", Vector3.new(12, 3, 5), CFrame.new(-135, 2.5, 0), { Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(70, 48, 40) }, workspace)
    stall:SetAttribute("Generated", true)
    newPart("StallRoof", Vector3.new(15, 1, 9), CFrame.new(-135, 10, 0), { Material = Enum.Material.Fabric, Color = Color3.fromRGB(40, 30, 50) }, mapFolder)
    for _, dx in ipairs({ -6, 6 }) do
        newPart("StallPole", Vector3.new(1, 9, 1), CFrame.new(-135 + dx, 5.5, -3), { Material = Enum.Material.Wood, Color = Color3.fromRGB(60, 44, 32) }, mapFolder)
    end
    local lantern = newPart("StallLantern", Vector3.new(1.5, 1.5, 1.5), CFrame.new(-135, 8.5, 2), { Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 150, 70), CanCollide = false }, mapFolder)
    addLight(lantern, Color3.fromRGB(255, 150, 70), 30, 1.4)

    -- Quadro de pedidos, junto ao elevador do lobby: o texto é atualizado pelo BlackMarketSystem
    local ordersBoard = workspace:FindFirstChild("OrdersBoard")
    if ordersBoard then
        local gui = Instance.new("SurfaceGui")
        gui.Name = "OrdersGui"
        gui.Face = Enum.NormalId.Left
        gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
        gui.PixelsPerStud = 30
        gui.Parent = ordersBoard
        local label = Instance.new("TextLabel")
        label.Name = "Orders"
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(255, 230, 170)
        label.Font = Enum.Font.GothamBold
        label.TextScaled = true
        label.Text = "PEDIDOS"
        label.Parent = gui
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
            if grid[r][c] and (c * 3 + r * 5) % 6 == 0 then
                local style = STYLES[zoneOf(c)]
                local center = cellCenter(c, r)
                local lamp = newPart("CaveLamp", Vector3.new(1.5, 1.5, 1.5), CFrame.new(center.X, FLOOR_Y + WALL_H - 1, center.Z), { Material = Enum.Material.Neon, Color = style.light, CanCollide = false }, cave)
                addLight(lamp, style.light, 24, 1.0)
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

-- Decoração: quebra a geometria reta e dá identidade a cada zona. Gerador próprio, não mexe na seed da caverna.
local function buildCaveDecor(grid: Grid, rng: Random)
    local decor = Instance.new("Folder")
    decor.Name = "Decor"
    decor.Parent = mapFolder

    local function randomAngles(): CFrame
        return CFrame.Angles(rng:NextNumber() * math.pi, rng:NextNumber() * math.pi, rng:NextNumber() * math.pi)
    end

    -- Espinho de rocha feito de cilindros empilhados (estalactite para baixo, estalagmite para cima)
    local function spike(x: number, z: number, hangingFromCeiling: boolean, scale: number, color: Color3)
        local baseY = if hangingFromCeiling then FLOOR_Y + WALL_H else FLOOR_Y
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
                    newPart("Boulder", Vector3.new(size, size * 0.8, size), CFrame.new(center.X + (rng:NextNumber() - 0.5) * 10, FLOOR_Y + size * 0.15, center.Z + (rng:NextNumber() - 0.5) * 10) * randomAngles(),
                        { Material = Enum.Material.Rock, Color = rock, Shape = Enum.PartType.Ball }, decor)
                end

                -- Saliências nas paredes: blocos girados que quebram a superfície reta
                for _, dir in ipairs({ { 0, -1 }, { 0, 1 }, { -1, 0 }, { 1, 0 } }) do
                    if not grid[r + dir[2]][c + dir[1]] and rng:NextNumber() < 0.35 then
                        local along = (rng:NextNumber() - 0.5) * (CELL - 4)
                        local height = 2 + rng:NextNumber() * 10
                        local edge = Vector3.new(center.X + dir[1] * CELL / 2, 0, center.Z + dir[2] * CELL / 2)
                        local position = Vector3.new(
                            edge.X - dir[1] * 1.0 + (if dir[1] == 0 then along else 0),
                            FLOOR_Y + height,
                            edge.Z - dir[2] * 1.0 + (if dir[2] == 0 then along else 0))
                        newPart("WallRock", Vector3.new(3 + rng:NextNumber() * 3, 3 + rng:NextNumber() * 5, 3 + rng:NextNumber() * 3),
                            CFrame.new(position) * randomAngles(), { Material = Enum.Material.Rock, Color = rock }, decor)
                    end
                end

                -- Cristais luminosos na zona C
                if zoneOf(c) == "C" and not isSpecial(c, r) and rng:NextNumber() < 0.3 then
                    local base = Vector3.new(center.X + (rng:NextNumber() - 0.5) * 9, FLOOR_Y, center.Z + (rng:NextNumber() - 0.5) * 9)
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
        newPart("Pillar", Vector3.new(WALL_H, 4, 4), CFrame.new(center.X, FLOOR_Y + WALL_H / 2, center.Z) * CFrame.Angles(0, 0, math.pi / 2),
            { Material = Enum.Material.Rock, Color = ROCK_COLOR:Lerp(STYLES[zoneOf(cell[1])].color, 0.4), Shape = Enum.PartType.Cylinder }, decor)
    end

    -- Zona A: estacas e vigas de madeira nos corredores retos, como uma mina antiga
    local frames = 0
    for r = 1, ROWS - 2 do
        for c = 1, 9 do
            if frames < 12 and grid[r][c] and not isSpecial(c, r) and rng:NextNumber() < 0.35 then
                local center = cellCenter(c, r)
                local wood = { Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(96, 68, 42) }
                if grid[r][c - 1] and grid[r][c + 1] and not grid[r - 1][c] and not grid[r + 1][c] then
                    for _, side in ipairs({ -1, 1 }) do
                        newPart("MinePost", Vector3.new(1.4, WALL_H - 1, 1.4), CFrame.new(center.X, FLOOR_Y + (WALL_H - 1) / 2, center.Z + side * (CELL / 2 - 1.2)), wood, decor)
                    end
                    newPart("MineBeam", Vector3.new(1.4, 1.4, CELL - 1), CFrame.new(center.X, FLOOR_Y + WALL_H - 2, center.Z), wood, decor)
                    frames += 1
                elseif grid[r - 1][c] and grid[r + 1][c] and not grid[r][c - 1] and not grid[r][c + 1] then
                    for _, side in ipairs({ -1, 1 }) do
                        newPart("MinePost", Vector3.new(1.4, WALL_H - 1, 1.4), CFrame.new(center.X + side * (CELL / 2 - 1.2), FLOOR_Y + (WALL_H - 1) / 2, center.Z), wood, decor)
                    end
                    newPart("MineBeam", Vector3.new(CELL - 1, 1.4, 1.4), CFrame.new(center.X, FLOOR_Y + WALL_H - 2, center.Z), wood, decor)
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
            local box = newPart("DustEmitter", Vector3.new(CELL, 10, CELL), CFrame.new(center.X, FLOOR_Y + 7, center.Z), { Transparency = 1, CanCollide = false, CanTouch = false, CanQuery = false }, decor)
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
        newPart("Puddle", Vector3.new(CELL * 0.8, 0.1, CELL * 0.8), CFrame.new(center.X, FLOOR_Y + 0.05, center.Z), { Material = Enum.Material.Glass, Color = Color3.fromRGB(60, 120, 200), Transparency = 0.45, CanCollide = false, Reflectance = 0.35 }, mapFolder)
        -- Gotas caindo do teto sobre a poça
        local dripSource = newPart("DripEmitter", Vector3.new(2, 0.5, 2), CFrame.new(center.X, FLOOR_Y + WALL_H - 0.5, center.Z), { Transparency = 1, CanCollide = false, CanTouch = false, CanQuery = false }, mapFolder)
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

-- Props do KayKit (meshes importados). O CreateMeshPartAsync espera a rede, então isto roda em segundo plano.
local propWarned = false

local function makeProp(name: string, cframe: CFrame, scale: number, collide: boolean, parent: Instance): MeshPart?
    local definition = Assets[name]
    if not definition then
        return nil
    end
    local ok, mesh = pcall(function()
        return AssetService:CreateMeshPartAsync(Content.fromUri(definition.mesh))
    end)
    if not ok or not mesh then
        if not propWarned then
            propWarned = true
            warn("[Map] Não foi possível criar os props do KayKit: " .. tostring(mesh))
        end
        return nil
    end
    mesh.Name = name
    mesh.Anchored = true
    mesh.CanCollide = collide
    mesh.Size = definition.size * scale
    mesh.TextureID = definition.texture
    mesh.CFrame = cframe
    mesh.Parent = parent
    return mesh
end

local function buildProps(grid: Grid, rng: Random)
    local props = Instance.new("Folder")
    props.Name = "Props"
    props.Parent = mapFolder

    -- Altura de cada prop apoiado no chão, e a escala usada
    local storage = {
        { "barrel_large", 2.4 }, { "barrel_large", 2.4 }, { "barrel_small_stack", 2.2 }, { "crates_stacked", 2.2 },
        { "box_stacked", 1.7 }, { "box_large", 2.4 }, { "keg_decorated", 1.8 },
    }
    local ruins = { { "rubble_large", 1.8 }, { "rubble_half", 1.8 }, { "sword_shield_broken", 2.4 }, { "candle_triple", 2.8 } }

    local function onFloor(name: string, scale: number, x: number, z: number, yaw: number, collide: boolean): MeshPart?
        local definition = Assets[name]
        local height = definition.size.Y * scale
        return makeProp(name, CFrame.new(x, FLOOR_Y + height / 2, z) * CFrame.Angles(0, yaw, 0), scale, collide, props)
    end

    for r = 1, ROWS - 2 do
        for c = 1, COLS - 2 do
            if grid[r][c] then
                local center = cellCenter(c, r)
                local zone = zoneOf(c)
                for _, dir in ipairs({ { 0, -1 }, { 0, 1 }, { -1, 0 }, { 1, 0 } }) do
                    if not grid[r + dir[2]][c + dir[1]] then
                        -- Ponto encostado na parede, apontando para dentro da célula
                        local wallX = center.X + dir[1] * CELL / 2
                        local wallZ = center.Z + dir[2] * CELL / 2
                        local alongX = if dir[1] == 0 then (rng:NextNumber() - 0.5) * (CELL - 6) else 0
                        local alongZ = if dir[2] == 0 then (rng:NextNumber() - 0.5) * (CELL - 6) else 0
                        local x = wallX - dir[1] * 3 + alongX
                        local z = wallZ - dir[2] * 3 + alongZ
                        local yaw = rng:NextNumber() * math.pi * 2

                        if zone == "A" and not inRect(CHAMBER, c, r) and rng:NextNumber() < 0.09 then
                            local choice = storage[rng:NextInteger(1, #storage)]
                            onFloor(choice[1] :: string, choice[2] :: number, x, z, yaw, true)
                        elseif zone == "B" and rng:NextNumber() < 0.07 then
                            local choice = ruins[rng:NextInteger(1, #ruins)]
                            local prop = onFloor(choice[1] :: string, choice[2] :: number, x, z, yaw, choice[1] ~= "candle_triple")
                            if prop and choice[1] == "candle_triple" then
                                addLight(prop, Color3.fromRGB(255, 190, 110), 16, 0.9)
                            end
                        end

                        -- Tochas nas paredes da zona A e da sala de entrada
                        if (zone == "A" or inRect(ENTRANCE, c, r)) and rng:NextNumber() < 0.1 then
                            local position = Vector3.new(wallX - dir[1] * 1.2 + alongX, FLOOR_Y + 8.5, wallZ - dir[2] * 1.2 + alongZ)
                            local torch = makeProp("torch_lit", CFrame.lookAt(position, position - Vector3.new(dir[1], 0, dir[2])), 3.2, false, props)
                            if torch then
                                addLight(torch, Color3.fromRGB(255, 150, 70), 26, 1.6)
                            end
                        end
                        break
                    end
                end
            end
        end
    end

    -- Câmara do núcleo: colunas altas e bandeiras esfarrapadas na parede do fundo
    for _, cell in ipairs({ { 24, 5 }, { 24, 11 }, { 22, 8 }, { 26, 8 } }) do
        local center = cellCenter(cell[1], cell[2])
        local scale = 9
        local height = Assets.column.size.Y * scale
        makeProp("column", CFrame.new(center.X, FLOOR_Y + height / 2, center.Z), scale, true, props)
    end
    for _, column in ipairs({ 23, 25 }) do
        local center = cellCenter(column, 5)
        local position = Vector3.new(center.X, FLOOR_Y + 8, center.Z - CELL / 2 + 0.6)
        makeProp("banner_triple_brown", CFrame.lookAt(position, position + Vector3.new(0, 0, 1)), 2.6, false, props)
    end

    -- Tesouros decorativos nas saliências do gancho
    for _, cell in ipairs({ { 12, 3 }, { 15, 11 }, { 27, 11 } }) do
        local center = cellCenter(cell[1], cell[2])
        local scale = 2.6
        local height = Assets.chest_gold.size.Y * scale
        makeProp("chest_gold", CFrame.new(center.X - 4, FLOOR_Y + 10 + height / 2, center.Z), scale, true, props)
    end

    print(string.format("[Map] %d props do KayKit criados", #props:GetChildren()))
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
    buildForest(Random.new(Config.MapSeed + 1)) -- gerador próprio: a caverna continua igual

    local grid = carveCave(rng)
    buildCaveGeometry(grid)
    buildCaveDecor(grid, Random.new(Config.MapSeed + 2))
    placeCores(grid, rng)
    -- Modelo para núcleos criados em tempo de jogo (pity, Enganador)
    makeCore("CoreTemplate", Vector3.zero, "Common", "A", "Core", ServerStorage)
    buildCaveMarkers(grid, rng)
    buildLedges()
    buildGuardian()
    task.spawn(buildProps, grid, Random.new(Config.MapSeed + 3))

    print(string.format("[Map] Mapa gerado (seed %d, %d partes)", Config.MapSeed, #mapFolder:GetDescendants()))
end

return MapBuilder
