--!strict
-- A vila e os lugares de jogo ao redor dela, feitos com as peças do Quaternius MegaKit (ver VillageHouses):
-- mercado, oficina, taverna, casas, poço, placas, a torre da mina e a cabana do Mercado Negro.
-- Fica em workspace.WorldBaked.Village, salvo no lugar. Os balcões com prompt (LobbyMarket, LobbyWorkshop,
-- LobbyBoard, BlackMarketStall) continuam sendo criados pelo jogo, em frente às portas.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local VillageHouses = require(script.Parent:WaitForChild("VillageHouses") :: ModuleScript)
local VillagePieces = require(script.Parent:WaitForChild("VillagePieces") :: ModuleScript)

local Village = {}

local FLOOR = Config.WorldFloorY

local function newPart(name: string, size: Vector3, cframe: CFrame, material: Enum.Material, color: Color3, parent: Instance): Part
    local part = Instance.new("Part")
    part.Name = name
    part.Anchored = true
    part.Size = size
    part.CFrame = cframe
    part.Material = material
    part.Color = color
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent
    return part
end

-- Placa de madeira com texto nos dois lados
local function sign(text: string, cframe: CFrame, parent: Instance, width: number?, backText: string?)
    local board = newPart("Placa", Vector3.new(width or 9, 2.4, 0.5), cframe, Enum.Material.WoodPlanks, Color3.fromRGB(96, 64, 38), parent)
    board.CanCollide = false
    for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
        local faceText = if face == Enum.NormalId.Back and backText then backText else text
        local gui = Instance.new("SurfaceGui")
        gui.Face = face
        gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
        gui.PixelsPerStud = 40
        gui.Parent = board
        local label = Instance.new("TextLabel")
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
        label.Text = faceText
        label.TextScaled = true
        label.Font = Enum.Font.GothamBold
        label.TextColor3 = Color3.fromRGB(245, 225, 180)
        label.Parent = gui
    end
end

-- Poço de pedra no centro da praça
local function well(x: number, z: number, parent: Instance)
    local stone = Color3.fromRGB(125, 122, 118)
    local ring = newPart("PocoBase", Vector3.new(2.6, 8, 8), CFrame.new(x, FLOOR + 1.3, z) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Cobblestone, stone, parent)
    ring.Shape = Enum.PartType.Cylinder
    local water = newPart("PocoAgua", Vector3.new(0.4, 6, 6), CFrame.new(x, FLOOR + 2.4, z) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Glass, Color3.fromRGB(70, 120, 170), parent)
    water.Shape = Enum.PartType.Cylinder
    water.CanCollide = false
    for _, dx in ipairs({ -3.4, 3.4 }) do
        newPart("PocoPoste", Vector3.new(0.8, 8, 0.8), CFrame.new(x + dx, FLOOR + 5, z), Enum.Material.Wood, Color3.fromRGB(86, 58, 36), parent)
    end
    newPart("PocoViga", Vector3.new(9, 0.7, 1), CFrame.new(x, FLOOR + 9, z), Enum.Material.Wood, Color3.fromRGB(86, 58, 36), parent)
    local roof = Instance.new("WedgePart")
    roof.Name = "PocoTelhado"
    roof.Anchored = true
    roof.Size = Vector3.new(10, 3, 5)
    roof.CFrame = CFrame.new(x, FLOOR + 10.5, z - 2.5) * CFrame.Angles(0, math.rad(180), 0)
    roof.Color = Color3.fromRGB(165, 70, 45)
    roof.Material = Enum.Material.Slate
    roof.Parent = parent
    local roofBack = roof:Clone()
    roofBack.CFrame = CFrame.new(x, FLOOR + 10.5, z + 2.5)
    roofBack.Parent = parent
end

-- Torre de madeira de mina sobre o elevador do lobby (o poço fica no meio)
local function mineTower(parent: Instance)
    local elevator = workspace:FindFirstChild("LobbyElevator")
    local center = if elevator and elevator:IsA("BasePart") then elevator.Position else Vector3.new(48, 0, 0)
    local wood = Color3.fromRGB(96, 66, 40)
    local x, z = center.X, center.Z
    for _, dx in ipairs({ -9, 9 }) do
        for _, dz in ipairs({ -9, 9 }) do
            newPart("TorrePoste", Vector3.new(2, 26, 2), CFrame.new(x + dx, FLOOR + 13, z + dz), Enum.Material.WoodPlanks, wood, parent)
        end
    end
    for _, y in ipairs({ 9, 18, 25 }) do
        newPart("TorreVigaX", Vector3.new(20, 1.2, 1.4), CFrame.new(x, FLOOR + y, z - 9), Enum.Material.WoodPlanks, wood, parent)
        newPart("TorreVigaX", Vector3.new(20, 1.2, 1.4), CFrame.new(x, FLOOR + y, z + 9), Enum.Material.WoodPlanks, wood, parent)
        newPart("TorreVigaZ", Vector3.new(1.4, 1.2, 20), CFrame.new(x - 9, FLOOR + y, z), Enum.Material.WoodPlanks, wood, parent)
        newPart("TorreVigaZ", Vector3.new(1.4, 1.2, 20), CFrame.new(x + 9, FLOOR + y, z), Enum.Material.WoodPlanks, wood, parent)
    end
    -- contraventos em X nas duas faces voltadas para o spawn e para o fundo
    for _, side in ipairs({ -9, 9 }) do
        for _, angle in ipairs({ 38, -38 }) do
            newPart("TorreContravento", Vector3.new(1.2, 21, 1), CFrame.new(x + side, FLOOR + 14, z) * CFrame.Angles(math.rad(angle), 0, 0), Enum.Material.WoodPlanks, wood, parent)
        end
    end
    VillagePieces.Place("Roof_RoundTiles_6x6", CFrame.new(x, FLOOR + 25.5, z) * CFrame.Angles(0, math.rad(90), 0), parent)
    local wheel = newPart("TorreRoda", Vector3.new(1.4, 10, 10), CFrame.new(x, FLOOR + 31, z) * CFrame.Angles(0, math.rad(90), 0), Enum.Material.Wood, Color3.fromRGB(72, 50, 32), parent)
    wheel.Shape = Enum.PartType.Cylinder
    wheel.CanCollide = false
    -- cerca de madeira em volta, com uma abertura para o lado do spawn
    for step = -2, 2 do
        if step ~= 0 then
            VillagePieces.Place("Prop_WoodenFence_Single", CFrame.new(x - 14 + 0, FLOOR, z + step * 6) * CFrame.Angles(0, math.rad(90), 0), parent)
            VillagePieces.Place("Prop_WoodenFence_Single", CFrame.new(x + 14, FLOOR, z + step * 6) * CFrame.Angles(0, math.rad(90), 0), parent)
        end
    end
end

-- Placas ao lado da trilha principal: quem vai para a vila lê "VILA", quem volta lê "MINA".
-- O Mercado Negro nunca aparece em placa. Precisa do Terrain já gerado para achar o chão.
local function trailSigns(parent: Instance): number
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = { workspace.Terrain }
    local points = Config.WorldTrails[1].points
    local count = 0
    for index = 2, #points - 1, 2 do
        local before, here, after = points[index - 1], points[index], points[index + 1]
        local tangent = Vector3.new(after[1] - before[1], 0, after[2] - before[2]).Unit
        local side = Vector3.new(-tangent.Z, 0, tangent.X)
        local x = here[1] + side.X * 8
        local z = here[2] + side.Z * 8
        local hit = workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -600, 0), params)
        local y = if hit then hit.Position.Y else FLOOR
        newPart("PlacaPoste", Vector3.new(0.8, 7, 0.8), CFrame.new(x, y + 3.5, z), Enum.Material.Wood, Color3.fromRGB(86, 58, 36), parent)
        local at = Vector3.new(x, y + 6.5, z)
        sign("▲ VILA", CFrame.lookAt(at, at - tangent), parent, 7, "▲ MINA")
        count += 1
    end
    return count
end

function Village.Build(root: Folder, log: (string) -> ())
    local old = root:FindFirstChild("Village")
    if old then
        old:Destroy()
    end
    local folder = Instance.new("Folder")
    folder.Name = "Village"
    folder.Parent = root

    local vila = Config.WorldPads.Vila
    local VX, VZ = vila.x, vila.z
    local houses = 0
    local function house(dx: number, dz: number, facing: number, w: number, d: number, extra: { wall: string?, chimney: boolean?, shutters: boolean? }?)
        local spec: VillageHouses.Spec = { w = w, d = d, wall = if extra then extra.wall else nil, chimney = if extra then extra.chimney else nil, shutters = if extra then extra.shutters else nil }
        VillageHouses.BuildCentered(VX + dx, FLOOR, VZ + dz, facing, spec, folder)
        houses += 1
    end

    -- Norte da praça (fachadas para o sul): mercado, taverna com anexo
    house(-30, -62, 180, 3, 4, { chimney = true, shutters = true }) -- mercado
    house(22, -64, 180, 4, 4, { wall = "Brick", chimney = true }) -- taverna
    house(50, -58, 180, 3, 3, { shutters = true })
    -- Sul da praça (fachadas para o norte): oficina e casas
    house(-30, 60, 0, 3, 3, { wall = "Brick", chimney = true }) -- oficina (forja)
    house(24, 64, 0, 3, 4, { chimney = true, shutters = true })
    house(60, 58, 0, 3, 3, { wall = "Brick" })
    -- Oeste e leste (fachadas para a praça)
    house(-80, 8, -90, 3, 3, { shutters = true, chimney = true })
    house(-72, -50, 180, 3, 3, { wall = "Brick" })
    house(84, 10, 90, 3, 4, { chimney = true })

    well(VX, VZ, folder)

    -- Placas sobre as portas (a fachada fica a 9 studs do centro da casa, e a placa fica na empena)
    sign("MERCADO", CFrame.new(VX - 30, FLOOR + 11.5, VZ - 62 + 12 + 0.8), folder)
    sign("OFICINA", CFrame.new(VX - 30, FLOOR + 11.5, VZ + 60 - 9 - 0.8), folder)
    sign("TAVERNA", CFrame.new(VX + 22, FLOOR + 11.5, VZ - 64 + 12 + 0.8), folder)

    -- Caixotes e carroça perto do mercado e da oficina
    VillagePieces.Place("Prop_Crate", CFrame.new(VX - 16, FLOOR, VZ - 44) * CFrame.Angles(0, math.rad(20), 0), folder)
    VillagePieces.Place("Prop_Crate", CFrame.new(VX - 14, FLOOR + 3.2, VZ - 44.5) * CFrame.Angles(0, math.rad(-12), 0), folder)
    VillagePieces.Place("Prop_Wagon", CFrame.new(VX + 12, FLOOR, VZ + 36) * CFrame.Angles(0, math.rad(70), 0), folder)
    VillagePieces.Place("Prop_Crate", CFrame.new(VX - 14, FLOOR, VZ + 42) * CFrame.Angles(0, math.rad(35), 0), folder)

    mineTower(folder)
    -- Carroça de viagem da mina (a da vila é a carroça da praça, acima); os prompts ficam em Lobby.lua
    VillagePieces.Place("Prop_Wagon", CFrame.new(20, FLOOR, 34) * CFrame.Angles(0, math.rad(70), 0), folder)

    -- Cabana do Mercado Negro, atrás da barraca, com a porta virada para ela
    local black = Config.WorldPads.MercadoNegro
    VillageHouses.BuildCentered(black.x - 26, FLOOR, black.z, -90, { w = 3, d = 3, wall = "Brick", shutters = true }, folder)
    VillagePieces.Place("Prop_Crate", CFrame.new(black.x + 9, FLOOR, black.z - 5) * CFrame.Angles(0, math.rad(25), 0), folder)
    VillagePieces.Place("Prop_Crate", CFrame.new(black.x - 6, FLOOR, black.z + 9) * CFrame.Angles(0, math.rad(-30), 0), folder)
    houses += 1

    local posts = trailSigns(folder)
    log(string.format("vila: %d casas, poço, placas, torre da mina, cabana do Mercado Negro e %d placas na trilha", houses, posts))
end

return Village
