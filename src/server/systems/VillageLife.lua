--!strict
-- V1: coisas para tocar na vila. Sentar nos bancos, aquecer as mãos nas fogueiras, fazer um desejo no poço, tocar o sino da
-- praça e ler o quadro de recados (que muda a cada expedição). Tudo é cosmético: nada dá moeda, poder nem item.
-- Os objetos já existem em workspace.WorldBaked (Plaza.lua e Village.lua); aqui só entram os prompts e os efeitos.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local systems = script.Parent :: Instance
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local Enums = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums") :: ModuleScript)
local ExpeditionSystem = require(systems:WaitForChild("ExpeditionSystem") :: ModuleScript)
local MovementGuard = require(systems:WaitForChild("MovementGuard") :: ModuleScript)
local PlayerState = require(systems:WaitForChild("PlayerState") :: ModuleScript)

local VillageLife = {}

local FLOOR = Config.WorldFloorY
local rng = Random.new()

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

local function inLobby(player: Player): boolean
    return PlayerState.Get(player) == Enums.PlayerLocation.Lobby
end

-- Balão de texto flutuante sobre uma peça
local function say(anchor: BasePart, text: string, seconds: number)
    local gui = Instance.new("BillboardGui")
    gui.Adornee = anchor
    gui.Size = UDim2.new(0, 230, 0, 56)
    gui.StudsOffset = Vector3.new(0, 5, 0)
    gui.MaxDistance = 70
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

local function attachBench(seat: BasePart)
    local p = prompt(seat, "Sentar", "Banco", 9)
    p.Triggered:Connect(function(player: Player)
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not character or not humanoid or not inLobby(player) then
            return
        end
        MovementGuard.Exempt(player, 3)
        character:PivotTo(seat.CFrame * CFrame.new(0, 2.4, 0))
        humanoid.Sit = true
        print("[Vila] " .. player.Name .. " sentou no banco")
    end)
end

local function attachFire(core: BasePart)
    local last = 0
    local p = prompt(core, "Aquecer as mãos", "Fogueira", 9)
    p.Triggered:Connect(function(_player: Player)
        if os.clock() - last < 6 then
            return
        end
        last = os.clock()
        local light = core.Parent and core.Parent:FindFirstChildWhichIsA("PointLight", true)
        if light then
            local normal = light.Brightness
            light.Brightness = normal * 2
            task.delay(4, function()
                light.Brightness = normal
            end)
        end
        for _, descendant in ipairs(core.Parent and core.Parent:GetDescendants() or {}) do
            if descendant:IsA("ParticleEmitter") then
                descendant:Emit(20)
            end
        end
    end)
end

local function attachWell(water: BasePart)
    local last = 0
    local p = prompt(water, "Fazer um desejo", "Poço", 11)
    p.Triggered:Connect(function(player: Player)
        if os.clock() - last < 8 then
            return
        end
        last = os.clock()
        print("[Vila] desejo no poço de " .. player.Name)
        local wishes = Config.VillageWishes
        say(water, string.format("%s: \"%s\"", player.DisplayName, wishes[rng:NextInteger(1, #wishes)]), 6)
    end)
end

-- Sino da praça: um poste de madeira com sino dourado. Quem toca faz soar para quem está por perto.
local function buildBell(): BasePart
    local pad = Config.WorldPads.Vila
    local x, z = pad.x + 16, pad.z + 9
    local model = Instance.new("Model")
    model.Name = "SinoDaPraca"
    local function part(name: string, size: Vector3, cframe: CFrame, material: Enum.Material, color: Color3): Part
        local p = Instance.new("Part")
        p.Name = name
        p.Size = size
        p.CFrame = cframe
        p.Material = material
        p.Color = color
        p.Anchored = true
        p.TopSurface = Enum.SurfaceType.Smooth
        p.BottomSurface = Enum.SurfaceType.Smooth
        p.Parent = model
        return p
    end
    local wood = Color3.fromRGB(86, 58, 36)
    part("SinoPoste", Vector3.new(1, 11, 1), CFrame.new(x - 3, FLOOR + 5.5, z), Enum.Material.Wood, wood)
    part("SinoPoste", Vector3.new(1, 11, 1), CFrame.new(x + 3, FLOOR + 5.5, z), Enum.Material.Wood, wood)
    part("SinoViga", Vector3.new(7.4, 0.8, 1), CFrame.new(x, FLOOR + 11, z), Enum.Material.Wood, wood)
    local bell = part("Sino", Vector3.new(2.6, 3, 3), CFrame.new(x, FLOOR + 8.6, z) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Metal, Color3.fromRGB(214, 168, 64))
    bell.Shape = Enum.PartType.Cylinder
    local sound = Instance.new("Sound")
    sound.SoundId = Config.Audio.Chime
    sound.Volume = 1
    sound.PlaybackSpeed = 0.55
    sound.RollOffMode = Enum.RollOffMode.Linear
    sound.RollOffMinDistance = 30
    sound.RollOffMaxDistance = 260
    sound.Parent = bell
    model.Parent = workspace.WorldBaked

    local last = 0
    local home = bell.CFrame
    local p = prompt(bell, "Tocar o sino", "Sino da praça", 12)
    p.Triggered:Connect(function(_player: Player)
        if os.clock() - last < 15 then
            return
        end
        last = os.clock()
        print("[Vila] sino tocado por " .. _player.Name)
        sound:Play()
        say(bell, "DONG!", 2)
        local swing = TweenService:Create(bell, TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { CFrame = home * CFrame.Angles(math.rad(22), 0, 0) })
        swing:Play()
        swing.Completed:Connect(function()
            TweenService:Create(bell, TweenInfo.new(1.4, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), { CFrame = home }):Play()
        end)
    end)
    return bell
end

-- Quadro de recados ao lado do sino: um texto novo a cada expedição que termina
local function buildNotice(): TextLabel
    local pad = Config.WorldPads.Vila
    local x, z = pad.x + 16, pad.z - 9
    local board = Instance.new("Part")
    board.Name = "QuadroDeRecados"
    board.Size = Vector3.new(7, 5, 0.6)
    board.CFrame = CFrame.new(x, FLOOR + 5.2, z) * CFrame.Angles(0, math.rad(-90), 0)
    board.Anchored = true
    board.Material = Enum.Material.WoodPlanks
    board.Color = Color3.fromRGB(112, 80, 50)
    board.Parent = workspace.WorldBaked
    for _, dz in ipairs({ -2.8, 2.8 }) do
        local leg = Instance.new("Part")
        leg.Name = "QuadroPerna"
        leg.Size = Vector3.new(0.6, 5.4, 0.6)
        leg.CFrame = CFrame.new(x, FLOOR + 2.7, z + dz)
        leg.Anchored = true
        leg.Material = Enum.Material.Wood
        leg.Color = Color3.fromRGB(86, 58, 36)
        leg.Parent = workspace.WorldBaked
    end
    local gui = Instance.new("SurfaceGui")
    gui.Face = Enum.NormalId.Front
    gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    gui.PixelsPerStud = 50
    gui.Parent = board
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(250, 236, 200)
    label.Font = Enum.Font.Fondamento
    label.TextWrapped = true
    label.TextScaled = true
    label.Text = "Recados da vila"
    label.Parent = gui
    return label
end

function VillageLife.Init()
    task.spawn(function()
        local baked = workspace:WaitForChild("WorldBaked", 30)
        if not baked then
            warn("[Vila] WorldBaked não apareceu; sem interações")
            return
        end
        local counts = { bench = 0, fire = 0, well = 0 }
        for _, descendant in ipairs(baked:GetDescendants()) do
            if descendant:IsA("BasePart") then
                if descendant.Name == "BancoAssento" then
                    attachBench(descendant)
                    counts.bench += 1
                elseif descendant.Name == "FogueiraFogo" then
                    attachFire(descendant)
                    counts.fire += 1
                elseif descendant.Name == "PocoAgua" then
                    attachWell(descendant)
                    counts.well += 1
                end
            end
        end
        buildBell()
        local notice = buildNotice()
        local notices = Config.VillageNotices
        notice.Text = notices[rng:NextInteger(1, #notices)]
        ExpeditionSystem.Ended:Connect(function()
            notice.Text = notices[rng:NextInteger(1, #notices)]
        end)
        print(string.format("[Vila] interações: %d bancos, %d fogueiras, %d poço, sino e quadro de recados", counts.bench, counts.fire, counts.well))
    end)
end

return VillageLife
