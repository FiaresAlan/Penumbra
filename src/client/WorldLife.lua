--!strict
-- Vida da superfície, só visual e só no cliente: fumaça nas chaminés, vaga-lumes, folhas caindo, bando de pássaros e nuvens.
-- Tudo é criado ao entrar na superfície e destruído ao descer à caverna; nada roda na caverna.
-- Os efeitos de área (vaga-lumes, folhas) seguem o jogador, e a fumaça só liga nas chaminés a menos de SMOKE_RANGE.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local WorldLife = {}

local SMOKE_RANGE = 220
local UPDATE_INTERVAL = 0.5
local FLOCK_MIN_DELAY = 40
local FLOCK_MAX_DELAY = 90
local FLOCK_SIZE = 6
local FLOCK_SPEED = 22
local FLOCK_LENGTH = 700

type Chimney = { emitter: ParticleEmitter, position: Vector3 }
type Bird = { body: Part, left: Part, right: Part, offset: Vector3, phase: number }

local active = false
local connections: { RBXScriptConnection } = {}
local followPart: Part? = nil
local chimneys: { Chimney } = {}
local scanned: { [Instance]: boolean } = {}
local clouds: Clouds? = nil
local createdClouds = false
local flockFolder: Folder? = nil
local flockToken = 0

local function rootPosition(): Vector3?
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then
        return root.Position
    end
    return nil
end

-- Parte invisível que carrega os emissores de área
local function newCarrier(name: string, size: Vector3): Part
    local part = Instance.new("Part")
    part.Name = name
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.CastShadow = false
    part.Transparency = 1
    part.Size = size
    part.Parent = workspace
    return part
end

local function areaEmitter(parent: Part, rate: number, lifetime: number, color: Color3, size: number, lightEmission: number, speed: number, gravity: number)
    local emitter = Instance.new("ParticleEmitter")
    emitter.Shape = Enum.ParticleEmitterShape.Box
    emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
    emitter.Rate = rate
    emitter.Lifetime = NumberRange.new(lifetime * 0.7, lifetime)
    emitter.Speed = NumberRange.new(speed * 0.5, speed)
    emitter.Acceleration = Vector3.new(0, gravity, 0)
    emitter.Color = ColorSequence.new(color)
    emitter.LightEmission = lightEmission
    emitter.Size = NumberSequence.new(size)
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.2, 0.2),
        NumberSequenceKeypoint.new(0.8, 0.2),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.RotSpeed = NumberRange.new(-60, 60)
    emitter.SpreadAngle = Vector2.new(180, 180)
    emitter.LockedToPart = false
    emitter.Parent = parent
    return emitter
end

local function addChimney(model: Model)
    if scanned[model] then
        return
    end
    scanned[model] = true
    -- O modelo pode chegar ao cliente antes das peças: espera elas existirem
    local waited = 0
    while active and not model:FindFirstChildWhichIsA("BasePart", true) and waited < 10 do
        task.wait(0.25)
        waited += 0.25
    end
    if not active or not model:FindFirstChildWhichIsA("BasePart", true) then
        scanned[model] = nil
        return
    end
    local boxCFrame, boxSize = model:GetBoundingBox()
    local top = boxCFrame.Position + Vector3.new(0, boxSize.Y / 2, 0)

    local carrier = newCarrier("FumacaChamine", Vector3.new(1, 1, 1))
    carrier.Position = top
    local emitter = Instance.new("ParticleEmitter")
    emitter.Rate = 6
    emitter.Lifetime = NumberRange.new(4, 6)
    emitter.Speed = NumberRange.new(2, 3)
    emitter.Acceleration = Vector3.new(1.5, 1, 0)
    emitter.SpreadAngle = Vector2.new(12, 12)
    emitter.Color = ColorSequence.new(Color3.fromRGB(170, 170, 175))
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 6),
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.8),
        NumberSequenceKeypoint.new(0.4, 0.55),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.Enabled = false
    emitter.Parent = carrier
    table.insert(chimneys, { emitter = emitter, position = top })
end

local function scanChimneys(root: Instance)
    for _, descendant in ipairs(root:GetDescendants()) do
        if descendant:IsA("Model") and descendant.Name == "Prop_Chimney" then
            task.spawn(addChimney, descendant)
        end
    end
end

local function ensureClouds()
    local terrain = workspace.Terrain
    local existing = terrain:FindFirstChildOfClass("Clouds")
    if existing then
        clouds = existing
        return
    end
    local created = Instance.new("Clouds")
    created.Cover = 0.45
    created.Density = 0.55
    created.Color = Color3.fromRGB(255, 244, 232)
    created.Parent = terrain
    clouds = created
    createdClouds = true
end

-- Bando de pássaros: poucas Parts cruzando o céu em linha reta, com as asas batendo
local function launchFlock()
    local origin = rootPosition()
    if not origin or not active then
        return
    end
    flockToken += 1
    local token = flockToken
    local folder = Instance.new("Folder")
    folder.Name = "BandoDePassaros"
    folder.Parent = workspace
    flockFolder = folder

    local angle = math.random() * math.pi * 2
    local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
    local side = Vector3.new(-direction.Z, 0, direction.X)
    local start = origin - direction * (FLOCK_LENGTH / 2) + side * math.random(-120, 120) + Vector3.new(0, math.random(70, 110), 0)

    local birds: { Bird } = {}
    for index = 1, FLOCK_SIZE do
        local function wing(name: string): Part
            local part = Instance.new("Part")
            part.Name = name
            part.Anchored = true
            part.CanCollide = false
            part.CanQuery = false
            part.CanTouch = false
            part.CastShadow = false
            part.Material = Enum.Material.SmoothPlastic
            part.Color = Color3.fromRGB(35, 32, 38)
            part.Size = Vector3.new(2.2, 0.15, 0.9)
            part.Parent = folder
            return part
        end
        local row = math.ceil(index / 2)
        local lateral = if index % 2 == 0 then row else -row
        table.insert(birds, {
            body = wing("Corpo"),
            left = wing("AsaEsq"),
            right = wing("AsaDir"),
            offset = side * (lateral * 5) - direction * (row * 4) + Vector3.new(0, math.random(-2, 2), 0),
            phase = math.random() * math.pi * 2,
        })
        birds[#birds].body.Size = Vector3.new(0.7, 0.5, 1.6)
    end

    local travelled = 0
    local connection: RBXScriptConnection
    connection = RunService.Heartbeat:Connect(function(dt)
        if token ~= flockToken or not active then
            connection:Disconnect()
            return
        end
        travelled += FLOCK_SPEED * dt
        if travelled >= FLOCK_LENGTH then
            connection:Disconnect()
            folder:Destroy()
            if flockFolder == folder then
                flockFolder = nil
            end
            return
        end
        local center = start + direction * travelled
        local facing = CFrame.lookAt(Vector3.zero, direction)
        for _, bird in ipairs(birds) do
            local flap = math.sin(os.clock() * 9 + bird.phase) * 0.7
            local base = CFrame.new(center + bird.offset) * facing.Rotation
            bird.body.CFrame = base
            bird.left.CFrame = base * CFrame.new(-1.2, 0, 0) * CFrame.Angles(0, 0, flap)
            bird.right.CFrame = base * CFrame.new(1.2, 0, 0) * CFrame.Angles(0, 0, -flap)
        end
    end)
    table.insert(connections, connection)
end

local function scheduleFlocks()
    local token = flockToken
    task.spawn(function()
        while active and token == flockToken do
            task.wait(math.random(FLOCK_MIN_DELAY, FLOCK_MAX_DELAY))
            if active and token == flockToken and not flockFolder then
                launchFlock()
                token = flockToken
            end
        end
    end)
end

local function update()
    local position = rootPosition()
    if not position then
        return
    end
    local carrier = followPart
    if carrier then
        carrier.Position = position
    end
    for _, chimney in ipairs(chimneys) do
        chimney.emitter.Enabled = (chimney.position - position).Magnitude <= SMOKE_RANGE
    end
end

function WorldLife.Start()
    if active then
        return
    end
    active = true

    -- Vaga-lumes e folhas: uma caixa em volta do jogador, que o acompanha
    local carrier = newCarrier("VidaDaSuperficie", Vector3.new(90, 14, 90))
    areaEmitter(carrier, 5, 6, Color3.fromRGB(255, 235, 140), 0.5, 1, 1.2, 0.1)
    local leaves = areaEmitter(carrier, 1.5, 9, Color3.fromRGB(190, 120, 50), 0.7, 0, 1.5, -0.8)
    leaves.Orientation = Enum.ParticleOrientation.FacingCamera
    followPart = carrier

    ensureClouds()
    if clouds then
        clouds.Enabled = true
    end

    local rootFolder = workspace:FindFirstChild("WorldBaked")
    if rootFolder then
        scanChimneys(rootFolder)
        table.insert(connections, rootFolder.DescendantAdded:Connect(function(descendant)
            if descendant:IsA("Model") and descendant.Name == "Prop_Chimney" then
                task.spawn(addChimney, descendant)
            end
        end))
    end

    local elapsed = 0
    table.insert(connections, RunService.Heartbeat:Connect(function(dt)
        elapsed += dt
        if elapsed >= UPDATE_INTERVAL then
            elapsed = 0
            update()
        end
    end))
    update()
    scheduleFlocks()
end

function WorldLife.Stop()
    if not active then
        return
    end
    active = false
    flockToken += 1
    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end
    table.clear(connections)
    if followPart then
        followPart:Destroy()
        followPart = nil
    end
    for _, chimney in ipairs(chimneys) do
        local carrier = chimney.emitter.Parent
        if carrier then
            carrier:Destroy()
        end
    end
    table.clear(chimneys)
    table.clear(scanned)
    if flockFolder then
        flockFolder:Destroy()
        flockFolder = nil
    end
    if clouds then
        clouds.Enabled = false
    end
end

function WorldLife.SetSurface(onSurface: boolean)
    if onSurface then
        WorldLife.Start()
    else
        WorldLife.Stop()
    end
end

return WorldLife
