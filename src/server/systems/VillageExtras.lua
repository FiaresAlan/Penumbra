--!strict
-- V1 (resto): portas que abrem, taverna com interior, carrinho de mercador e um cachorro que segue quem passa pela vila.
-- Tudo cosmético: nada dá moeda, item ou poder. As portas e a taverna usam as peças que Village.lua já gravou em
-- workspace.WorldBaked.Village; o carrinho e o cachorro procuram chão livre com FreeSpot antes de nascer.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local systems = script.Parent :: Instance
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local Enums = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums") :: ModuleScript)
local FreeSpot = require(systems.Parent:WaitForChild("world"):WaitForChild("FreeSpot") :: ModuleScript)
local MovementGuard = require(systems:WaitForChild("MovementGuard") :: ModuleScript)
local PlayerState = require(systems:WaitForChild("PlayerState") :: ModuleScript)

local VillageExtras = {}

local FLOOR = Config.WorldFloorY
local rng = Random.new(Config.MapSeed + 99)
local WOOD = Color3.fromRGB(104, 72, 46)
local DARK_WOOD = Color3.fromRGB(70, 48, 32)

local function part(name: string, size: Vector3, cframe: CFrame, material: Enum.Material, color: Color3, parent: Instance): Part
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cframe
    p.Material = material
    p.Color = color
    p.Anchored = true
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

local function prompt(parent: Instance, action: string, object: string, distance: number): ProximityPrompt
    local p = Instance.new("ProximityPrompt")
    p.ActionText = action
    p.ObjectText = object
    p.HoldDuration = 0
    p.MaxActivationDistance = distance
    p.RequiresLineOfSight = false
    p.Parent = parent
    return p
end

local function bubble(anchor: BasePart, text: string, seconds: number)
    local gui = Instance.new("BillboardGui")
    gui.Adornee = anchor
    gui.Size = UDim2.new(0, 230, 0, 56)
    gui.StudsOffset = Vector3.new(0, 4, 0)
    gui.MaxDistance = 60
    gui.LightInfluence = 0
    gui.Parent = anchor
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundColor3 = Color3.fromRGB(244, 236, 220)
    label.TextColor3 = Color3.fromRGB(40, 28, 20)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 14
    label.TextWrapped = true
    label.Text = text
    label.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = label
    task.delay(seconds, function()
        gui:Destroy()
    end)
end

local function inLobby(player: Player): boolean
    return PlayerState.Get(player) == Enums.PlayerLocation.Lobby
end

-- Portas: a folha desliza para o lado e volta sozinha. Sem colisão enquanto aberta.
local function attachDoor(door: Model)
    local anchor = door:FindFirstChildWhichIsA("BasePart", true)
    if not anchor then
        return
    end
    local closed = door:GetPivot()
    local width = math.max(door:GetExtentsSize().X, door:GetExtentsSize().Z)
    local open = closed * CFrame.new(width * 0.9, 0, 0)
    local busy = false
    local p = prompt(anchor, "Abrir", "Porta", 9)
    p.Triggered:Connect(function(_player: Player)
        if busy then
            return
        end
        busy = true
        for _, descendant in ipairs(door:GetDescendants()) do
            if descendant:IsA("BasePart") then
                descendant.CanCollide = false
            end
        end
        local value = Instance.new("CFrameValue")
        value.Value = closed
        value.Changed:Connect(function(cf: CFrame)
            door:PivotTo(cf)
        end)
        TweenService:Create(value, TweenInfo.new(0.6, Enum.EasingStyle.Sine), { Value = open }):Play()
        task.delay(6, function()
            TweenService:Create(value, TweenInfo.new(0.6, Enum.EasingStyle.Sine), { Value = closed }):Play()
            task.delay(0.7, function()
                for _, descendant in ipairs(door:GetDescendants()) do
                    if descendant:IsA("BasePart") then
                        descendant.CanCollide = true
                    end
                end
                value:Destroy()
                busy = false
            end)
        end)
    end)
end

-- Banco ou banquinho da taverna: sentar
local function attachSeat(seat: BasePart)
    local p = prompt(seat, "Sentar", "Banquinho", 8)
    p.Triggered:Connect(function(player: Player)
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not character or not humanoid or not inLobby(player) then
            return
        end
        MovementGuard.Exempt(player, 3)
        character:PivotTo(seat.CFrame * CFrame.new(0, 2.6, 0))
        humanoid.Sit = true
    end)
end

-- Interior da taverna: piso de tábuas, balcão, mesas com banquinhos, barris e um lustre quente.
-- A casa "Casa4x4" é a única desse tamanho; a frente da porta dá a direção, e o centro fica 12 studs para dentro.
local function buildTavern(village: Instance)
    local house = village:FindFirstChild("Casa4x4")
    local door = house and house:FindFirstChild("Door_1_Round")
    if not house or not door or not door:IsA("Model") then
        print("[Vila] taverna não encontrada: interior não criado")
        return
    end
    local doorCf = door:GetPivot()
    local outward = doorCf.LookVector
    local center = doorCf.Position - outward * 12
    local base = CFrame.lookAt(Vector3.new(center.X, FLOOR, center.Z), Vector3.new(center.X, FLOOR, center.Z) + outward)
    local folder = Instance.new("Model")
    folder.Name = "TavernaInterior"
    folder.Parent = village

    part("TavernaPiso", Vector3.new(21, 0.3, 21), base * CFrame.new(0, 0.2, 0), Enum.Material.WoodPlanks, Color3.fromRGB(120, 84, 54), folder)
    part("TavernaTapete", Vector3.new(8, 0.1, 6), base * CFrame.new(0, 0.42, -3), Enum.Material.Fabric, Color3.fromRGB(120, 36, 36), folder)
    -- balcão no fundo (+Z local), com garrafas e canecas
    part("TavernaBalcao", Vector3.new(14, 3.4, 2.4), base * CFrame.new(0, 1.9, 8), Enum.Material.WoodPlanks, DARK_WOOD, folder)
    part("TavernaBalcaoTopo", Vector3.new(14.6, 0.4, 3), base * CFrame.new(0, 3.8, 8), Enum.Material.Wood, WOOD, folder)
    for index = -2, 2 do
        local mug = part("TavernaCaneca", Vector3.new(0.9, 0.7, 0.7), base * CFrame.new(index * 2.4, 4.45, 8), Enum.Material.Metal, Color3.fromRGB(176, 150, 96), folder)
        mug.Shape = Enum.PartType.Cylinder
        mug.CFrame = mug.CFrame * CFrame.Angles(0, 0, math.pi / 2)
        mug.CanCollide = false
    end
    -- barris no canto
    for index = 0, 2 do
        local barrel = part("TavernaBarril", Vector3.new(3.2, 2.6, 2.6), base * CFrame.new(-8.5 + (index % 2) * 2.7, 1.9 + math.floor(index / 2) * 3, 8.6), Enum.Material.Wood, WOOD, folder)
        barrel.Shape = Enum.PartType.Cylinder
        barrel.CFrame = barrel.CFrame * CFrame.Angles(0, 0, math.pi / 2)
    end
    -- mesas redondas com banquinhos
    for _, spot in ipairs({ { -6, -4 }, { 6, -4 }, { -6, 2 }, { 6, 2 } }) do
        local tabletop = part("TavernaMesa", Vector3.new(0.4, 3.6, 3.6), base * CFrame.new(spot[1], 2.9, spot[2]), Enum.Material.Wood, WOOD, folder)
        tabletop.Shape = Enum.PartType.Cylinder
        tabletop.CFrame = tabletop.CFrame * CFrame.Angles(0, 0, math.pi / 2)
        local leg = part("TavernaPeMesa", Vector3.new(0.8, 2.6, 0.8), base * CFrame.new(spot[1], 1.5, spot[2]), Enum.Material.Wood, DARK_WOOD, folder)
        leg.CanCollide = false
        for _, side in ipairs({ { 2.6, 0 }, { -2.6, 0 }, { 0, 2.6 }, { 0, -2.6 } }) do
            local stool = part("TavernaBanquinho", Vector3.new(1.2, 1.6, 1.6), base * CFrame.new(spot[1] + side[1], 0.9, spot[2] + side[2]), Enum.Material.Wood, DARK_WOOD, folder)
            stool.Shape = Enum.PartType.Cylinder
            stool.CFrame = stool.CFrame * CFrame.Angles(0, 0, math.pi / 2)
            attachSeat(stool)
        end
    end
    -- lustre: argola com velas e luz quente
    local ring = part("TavernaLustre", Vector3.new(0.4, 5, 5), base * CFrame.new(0, 10, 0) * CFrame.Angles(0, 0, math.pi / 2), Enum.Material.Metal, Color3.fromRGB(40, 36, 34), folder)
    ring.Shape = Enum.PartType.Cylinder
    ring.CanCollide = false
    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(255, 190, 110)
    light.Range = 28
    light.Brightness = 1.6
    light.Parent = ring
    for index = 1, 6 do
        local angle = index / 6 * math.pi * 2
        local flame = part("TavernaVela", Vector3.new(0.3, 0.8, 0.3), base * CFrame.new(math.cos(angle) * 2.4, 10.5, math.sin(angle) * 2.4), Enum.Material.Neon, Color3.fromRGB(255, 200, 110), folder)
        flame.CanCollide = false
    end
    print("[Vila] interior da taverna criado")
end

-- Carrinho de mercador: caixa de madeira, duas rodas, toldo e um prompt que conta uma curiosidade
local function buildCart(village: Instance)
    local pad = Config.WorldPads.Vila
    local spot = FreeSpot.Find(Vector3.new(pad.x - 8, 0, pad.z + 22), 9, 6, 8, 14, rng)
    if not spot then
        print("[Vila] sem espaço para o carrinho de mercador")
        return
    end
    local facing = rng:NextNumber(0, 360)
    local base = CFrame.new(spot) * CFrame.Angles(0, math.rad(facing), 0)
    local cart = Instance.new("Model")
    cart.Name = "CarrinhoMercador"
    cart.Parent = village
    local box = part("CarrinhoCaixa", Vector3.new(6, 2.4, 3.6), base * CFrame.new(0, 2.6, 0), Enum.Material.WoodPlanks, WOOD, cart)
    for _, side in ipairs({ -1, 1 }) do
        local wheel = part("CarrinhoRoda", Vector3.new(0.5, 3.4, 3.4), base * CFrame.new(0, 1.7, side * 2.1), Enum.Material.Wood, DARK_WOOD, cart)
        wheel.Shape = Enum.PartType.Cylinder
        wheel.CFrame = wheel.CFrame * CFrame.Angles(0, math.pi / 2, 0)
    end
    for _, corner in ipairs({ { -2.6, -1.5 }, { 2.6, -1.5 }, { -2.6, 1.5 }, { 2.6, 1.5 } }) do
        part("CarrinhoPoste", Vector3.new(0.3, 4, 0.3), base * CFrame.new(corner[1], 5.6, corner[2]), Enum.Material.Wood, DARK_WOOD, cart)
    end
    local awning = part("CarrinhoToldo", Vector3.new(6.8, 0.3, 4.2), base * CFrame.new(0, 7.7, 0) * CFrame.Angles(0, 0, 0.08), Enum.Material.Fabric, Color3.fromRGB(150, 54, 44), cart)
    awning.CanCollide = false
    for index = 1, 3 do
        local goods = part("CarrinhoMercadoria", Vector3.new(1.4, 1.2, 1.4), base * CFrame.new(-2 + index * 1.6, 4.4, 0), Enum.Material.Plastic,
            Color3.fromHSV(rng:NextNumber(), 0.45, 0.8), cart)
        goods.CanCollide = false
    end
    local last = 0
    local p = prompt(box, "Ver mercadorias", "Carrinho", 9)
    p.Triggered:Connect(function(player: Player)
        if os.clock() - last < 5 then
            return
        end
        last = os.clock()
        local lines = Config.CartLines
        bubble(box, lines[rng:NextInteger(1, #lines)], 6)
        print("[Vila] " .. player.Name .. " olhou o carrinho")
    end)
    print("[Vila] carrinho de mercador criado")
end

-- Cachorro da vila: segue o jogador do lobby mais perto (se estiver na vila), volta para casa quando ninguém está por perto
local function buildDog(village: Instance)
    local pad = Config.WorldPads.Vila
    local home = FreeSpot.Find(Vector3.new(pad.x + 6, 0, pad.z + 8), 3, 3, 2.5, 14, rng)
    if not home then
        print("[Vila] sem espaço para o cachorro")
        return
    end
    local dog = Instance.new("Model")
    dog.Name = "CachorroDaVila"
    dog.Parent = village
    local fur = Color3.fromRGB(150, 104, 62)
    local body = part("Corpo", Vector3.new(1.4, 1.4, 3), CFrame.new(home + Vector3.new(0, 1.5, 0)), Enum.Material.Fabric, fur, dog)
    local head = part("Cabeca", Vector3.new(1.2, 1.2, 1.3), CFrame.new(home + Vector3.new(0, 2.3, -1.9)), Enum.Material.Fabric, fur, dog)
    part("Focinho", Vector3.new(0.6, 0.5, 0.7), head.CFrame * CFrame.new(0, -0.2, -0.9), Enum.Material.Fabric, Color3.fromRGB(70, 46, 30), dog)
    for _, side in ipairs({ -0.45, 0.45 }) do
        part("Orelha", Vector3.new(0.3, 0.7, 0.4), head.CFrame * CFrame.new(side, 0.7, 0.1), Enum.Material.Fabric, Color3.fromRGB(96, 64, 38), dog)
    end
    local tail = part("Rabo", Vector3.new(0.3, 0.3, 1.2), body.CFrame * CFrame.new(0, 0.6, 1.9) * CFrame.Angles(0.6, 0, 0), Enum.Material.Fabric, fur, dog)
    for _, leg in ipairs({ { -0.5, -1 }, { 0.5, -1 }, { -0.5, 1 }, { 0.5, 1 } }) do
        part("Pata", Vector3.new(0.4, 1, 0.4), body.CFrame * CFrame.new(leg[1], -1.1, leg[2]), Enum.Material.Fabric, fur, dog)
    end
    for _, descendant in ipairs(dog:GetChildren()) do
        if descendant:IsA("BasePart") then
            descendant.CanCollide = false
        end
    end
    dog.PrimaryPart = body
    local _ = tail

    local last = 0
    local pat = prompt(body, "Fazer carinho", "Cachorro", 9)
    pat.Triggered:Connect(function(player: Player)
        if os.clock() - last < 4 then
            return
        end
        last = os.clock()
        bubble(body, "Au! (" .. player.DisplayName .. " ganhou um amigo)", 4)
    end)

    local terrainOnly = RaycastParams.new()
    terrainOnly.FilterType = Enum.RaycastFilterType.Include
    terrainOnly.FilterDescendantsInstances = { workspace.Terrain }
    local position = home
    local heading = 0
    local elapsed = 0
    local groundTimer = 0
    local groundY = home.Y
    RunService.Heartbeat:Connect(function(dt: number)
        elapsed += dt
        groundTimer += dt
        -- alvo: jogador do lobby mais perto dentro da vila
        local target: Vector3? = nil
        local best = 60
        for _, player in ipairs(Players:GetPlayers()) do
            local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if root and root:IsA("BasePart") and inLobby(player) then
                local flatToVillage = Vector3.new(root.Position.X - pad.x, 0, root.Position.Z - pad.z).Magnitude
                local flat = Vector3.new(root.Position.X - position.X, 0, root.Position.Z - position.Z).Magnitude
                if flatToVillage < pad.r - 10 and flat < best then
                    best = flat
                    target = root.Position
                end
            end
        end
        local goal = target or home
        local toGoal = Vector3.new(goal.X - position.X, 0, goal.Z - position.Z)
        local distance = toGoal.Magnitude
        local stopAt = if target then 6 else 1.5
        if distance > stopAt then
            local speed = if distance > 18 then 14 else 8
            local step = math.min(speed * dt, distance - stopAt)
            position += toGoal.Unit * step
            heading = math.atan2(-toGoal.X, -toGoal.Z)
        end
        if groundTimer >= 0.15 then
            groundTimer = 0
            local hit = workspace:Raycast(Vector3.new(position.X, 120, position.Z), Vector3.new(0, -240, 0), terrainOnly)
            if hit then
                groundY = hit.Position.Y
            end
        end
        local moving = distance > stopAt
        local bob = if moving then math.abs(math.sin(elapsed * 10)) * 0.25 else 0
        local wag = math.sin(elapsed * 12) * 0.5
        dog:PivotTo(CFrame.new(position.X, groundY + 0.1 + bob, position.Z) * CFrame.Angles(0, heading, wag * 0.05) * CFrame.new(0, 0, 0))
    end)
    print("[Vila] cachorro criado")
end

function VillageExtras.Init()
    task.spawn(function()
        local baked = workspace:WaitForChild("WorldBaked", 30)
        local village = baked and baked:WaitForChild("Village", 30)
        if not village then
            return
        end
        task.wait(2)
        local doors = 0
        for _, descendant in ipairs(village:GetDescendants()) do
            if descendant:IsA("Model") and descendant.Name == "Door_1_Round" then
                attachDoor(descendant)
                doors += 1
            end
        end
        print("[Vila] portas que abrem: " .. doors)
        buildTavern(village)
        buildCart(village)
        buildDog(village)
    end)
end

return VillageExtras
