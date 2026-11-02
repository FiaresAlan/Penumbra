--!strict
-- Mina (elevador, mural, pedidos) e a Vila (mercado, oficina, contratos): peças de jogo com prompts. O chão é o Terrain do R4.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local Util = require(script.Parent:WaitForChild("WorldUtil") :: ModuleScript)

local newPart = Util.newPart
local marker = Util.marker
local newFolder = Util.newFolder
local addPrompt = Util.addPrompt
local addLight = Util.addLight

local function lampPost(x: number, z: number)
    local mapFolder = Util.MapFolder :: Folder
    newPart("LampPole", Vector3.new(1, 12, 1), CFrame.new(x, 7, z), { Material = Enum.Material.Metal, Color = Color3.fromRGB(60, 60, 65) }, mapFolder)
    local bulb = newPart("LampBulb", Vector3.new(2, 2, 2), CFrame.new(x, 13.5, z), { Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 240, 200), CanCollide = false }, mapFolder)
    addLight(bulb, Color3.fromRGB(255, 240, 200), 40, 1.5)
end

local function buildLobby()
    local mapFolder = Util.MapFolder :: Folder
    local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
    if not spawn then
        spawn = Instance.new("SpawnLocation")
        spawn.Anchored = true
        spawn.Neutral = true
        spawn.Parent = workspace
    end
    spawn.CFrame = CFrame.new(0, 1.5, 0)
    -- O chão agora é o Terrain: o SpawnLocation fica invisível e sem imagem
    spawn.Transparency = 1
    spawn.CanCollide = false
    for _, child in ipairs(spawn:GetChildren()) do
        if child:IsA("Decal") or child:IsA("Texture") then
            child:Destroy()
        end
    end

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

    -- Vila: mercado, oficina e contratos ficam em volta de VX (o centro da área plana da vila)
    local VX = Config.WorldPads.Vila.x
    local VZ = Config.WorldPads.Vila.z

    -- Mercado
    local market = newPart("LobbyMarket", Vector3.new(12, 3, 5), CFrame.new(VX - 30, 2.5, VZ - 46), { Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(150, 105, 60) }, workspace)
    market:SetAttribute("Generated", true)

    -- Oficina, com os suportes das Relíquias
    local workshop = newPart("LobbyWorkshop", Vector3.new(12, 3, 5), CFrame.new(VX - 30, 2.5, VZ + 47), { Material = Enum.Material.Metal, Color = Color3.fromRGB(95, 100, 110) }, workspace)
    workshop:SetAttribute("Generated", true)
    local displays = newFolder("RelicDisplays")
    for index, z in ipairs({ 24, 30, 36 }) do
        local stand = newPart("RelicStand" .. index, Vector3.new(3, 3, 3), CFrame.new(VX - 52, 2.5, VZ + z + 20), { Material = Enum.Material.Marble, Color = Color3.fromRGB(220, 220, 225) }, displays)
        stand:SetAttribute("Generated", true)
    end

    -- Quadro de contratos
    local board = newPart("LobbyBoard", Vector3.new(14, 8, 1), CFrame.new(VX + 22, 5, VZ - 44), { Material = Enum.Material.Wood, Color = Color3.fromRGB(110, 80, 50) }, workspace)
    board:SetAttribute("Generated", true)

    -- Carroças de viagem: uma na mina e uma na vila (a aparência da carroça vem da vila gravada em WorldBaked).
    -- O prompt fica na peça CartMina/CartVila; a chegada é uma marca ao lado da outra carroça.
    local function cart(name: string, x: number, z: number, arrivalName: string, arrivalX: number, arrivalZ: number)
        local pad = newPart(name, Vector3.new(8, 4, 8), CFrame.new(x, 3, z), { Transparency = 1, CanCollide = false }, workspace)
        pad:SetAttribute("Generated", true)
        addPrompt(pad, "Viajar de carroça", 0.5, Config.CartPromptRadius)
        marker(arrivalName, Vector3.new(4, 1, 4), CFrame.new(arrivalX, 2, arrivalZ), workspace):SetAttribute("Generated", true)
    end
    cart("CartMina", 20, 34, "CartArrivalMina", 20, 27)
    cart("CartVila", VX + 12, VZ + 36, "CartArrivalVila", VX + 12, VZ + 29)

    for _, point in ipairs({ { -55, -55 }, { 55, -55 }, { -55, 55 }, { 55, 55 }, { 0, 40 }, { 0, -40 }, { 30, -16 }, { -30, 0 }, { VX - 60, VZ - 40 }, { VX + 30, VZ - 40 }, { VX - 60, VZ + 40 }, { VX + 30, VZ + 40 }, { VX - 10, VZ } }) do
        lampPost(point[1], point[2])
    end
end

return { Build = buildLobby }
