--!strict
-- R7c: vida da caverna, só visual e só no cliente. Morcegos pendurados no teto que fogem quando o jogador passa perto,
-- e poeira caindo do teto quando o Guardião está por perto. É enfeite: a poeira não diz nada além do que a presença do
-- Guardião já diz, e some quando ele se afasta. Ligado só dentro da caverna; ao subir, tudo é destruído.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local CaveLife = {}

local BAT_COUNT = 7
local BAT_MIN = 14
local BAT_MAX = 40
local BAT_FLEE_DISTANCE = 11
local BAT_DESPAWN_DISTANCE = 80
local FLY_TIME = 4
local DUST_DISTANCE = 38

type Bat = {
    model: Model,
    left: Part,
    right: Part,
    position: Vector3,
    state: string, -- "hang" | "fly"
    velocity: Vector3,
    flyUntil: number,
    phase: number,
}

local active = false
local connection: RBXScriptConnection? = nil
local folder: Folder? = nil
local dustPart: Part? = nil
local dustEmitter: ParticleEmitter? = nil
local bats: { Bat } = {}
local rng = Random.new()
local sinceScan = 0

local function piece(parent: Model, name: string, size: Vector3, color: Color3): Part
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.Color = color
    p.Material = Enum.Material.Fabric
    p.Anchored = true
    p.CanCollide = false
    p.CanQuery = false
    p.CanTouch = false
    p.CastShadow = false
    p.Parent = parent
    return p
end

local function buildBat(): (Model, Part, Part)
    local model = Instance.new("Model")
    model.Name = "Morcego"
    local dark = Color3.fromRGB(28, 24, 30)
    local body = piece(model, "Corpo", Vector3.new(0.5, 0.7, 0.5), dark)
    local left = piece(model, "AsaE", Vector3.new(1.4, 0.08, 0.7), dark)
    local right = piece(model, "AsaD", Vector3.new(1.4, 0.08, 0.7), dark)
    model.PrimaryPart = body
    return model, left, right
end

local function rayParams(): RaycastParams
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local ignore: { Instance } = {}
    local character = player.Character
    if character then
        table.insert(ignore, character)
    end
    if folder then
        table.insert(ignore, folder)
    end
    local guardian = workspace:FindFirstChild("Guardian")
    if guardian then
        table.insert(ignore, guardian)
    end
    rp.FilterDescendantsInstances = ignore
    return rp
end

-- Ponto no teto perto do jogador (sobe um raio de uma posição qualquer em volta dele)
local function ceilingNear(center: Vector3, rp: RaycastParams): Vector3?
    for _ = 1, 6 do
        local angle = rng:NextNumber(0, math.pi * 2)
        local distance = rng:NextNumber(BAT_MIN, BAT_MAX)
        local origin = center + Vector3.new(math.cos(angle) * distance, 1.5, math.sin(angle) * distance)
        local result = workspace:Raycast(origin, Vector3.new(0, 40, 0), rp)
        if result and result.Position.Y - origin.Y > 6 then
            return result.Position - Vector3.new(0, 0.5, 0)
        end
    end
    return nil
end

local function place(bat: Bat, flapping: boolean, time: number)
    local base = CFrame.new(bat.position)
    if bat.state == "fly" then
        base = CFrame.lookAt(bat.position, bat.position + bat.velocity)
    end
    bat.model:PivotTo(base)
    local flap = if flapping then math.sin(time * 18 + bat.phase) * 0.9 else -0.3
    bat.left.CFrame = base * CFrame.new(-0.9, 0.1, 0) * CFrame.Angles(0, 0, flap)
    bat.right.CFrame = base * CFrame.new(0.9, 0.1, 0) * CFrame.Angles(0, 0, -flap)
end

local function spawnBat(center: Vector3, rp: RaycastParams)
    local current = folder
    if not current then
        return
    end
    local point = ceilingNear(center, rp)
    if not point then
        return
    end
    local model, left, right = buildBat()
    model.Parent = current
    local bat: Bat = {
        model = model,
        left = left,
        right = right,
        position = point,
        state = "hang",
        velocity = Vector3.zero,
        flyUntil = 0,
        phase = rng:NextNumber(0, 6),
    }
    table.insert(bats, bat)
    place(bat, false, 0)
    if #bats == BAT_COUNT and RunService:IsStudio() then
        print(string.format("[CaveLife] %d morcegos no teto", #bats))
    end
end

local function step(dt: number)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") then
        return
    end
    local playerPosition = root.Position
    local now = os.clock()

    sinceScan += dt
    local scan = sinceScan >= 1.5
    local rp: RaycastParams? = nil
    if scan then
        sinceScan = 0
        rp = rayParams()
    end

    for index = #bats, 1, -1 do
        local bat = bats[index]
        local distance = (bat.position - playerPosition).Magnitude
        if bat.state == "hang" then
            if distance < BAT_FLEE_DISTANCE then
                bat.state = "fly"
                local away = bat.position - playerPosition
                away = Vector3.new(away.X, 0, away.Z)
                local direction = if away.Magnitude > 0.1 then away.Unit else Vector3.new(1, 0, 0)
                bat.velocity = (direction + Vector3.new(rng:NextNumber(-0.4, 0.4), -0.15, rng:NextNumber(-0.4, 0.4))).Unit * 16
                bat.flyUntil = now + FLY_TIME
            end
            if distance > BAT_DESPAWN_DISTANCE then
                bat.model:Destroy()
                table.remove(bats, index)
            else
                place(bat, false, now)
            end
        else
            bat.position += bat.velocity * dt + Vector3.new(0, math.sin(now * 9 + bat.phase) * dt * 2, 0)
            place(bat, true, now)
            if now >= bat.flyUntil then
                bat.model:Destroy()
                table.remove(bats, index)
            end
        end
    end

    if scan and rp and #bats < BAT_COUNT then
        spawnBat(playerPosition, rp)
    end

    -- Poeira: só com o Guardião a menos de DUST_DISTANCE
    local emitter = dustEmitter
    local carrier = dustPart
    if emitter and carrier then
        carrier.Position = playerPosition + Vector3.new(0, 8, 0)
        local guardian = workspace:FindFirstChild("Guardian")
        local guardianRoot = guardian and guardian:FindFirstChild("HumanoidRootPart")
        if guardianRoot and guardianRoot:IsA("BasePart") then
            local d = (guardianRoot.Position - playerPosition).Magnitude
            emitter.Enabled = d < DUST_DISTANCE
            emitter.Rate = math.clamp((DUST_DISTANCE - d) * 1.2, 0, 40)
        else
            emitter.Enabled = false
        end
    end
end

function CaveLife.SetCave(isCave: boolean)
    if isCave then
        if active then
            return
        end
        active = true
        local created = Instance.new("Folder")
        created.Name = "VidaDaCaverna"
        created.Parent = workspace
        folder = created

        local carrier = Instance.new("Part")
        carrier.Name = "Poeira"
        carrier.Anchored = true
        carrier.CanCollide = false
        carrier.CanQuery = false
        carrier.CanTouch = false
        carrier.CastShadow = false
        carrier.Transparency = 1
        carrier.Size = Vector3.new(40, 2, 40)
        carrier.Parent = created
        dustPart = carrier

        local emitter = Instance.new("ParticleEmitter")
        emitter.Shape = Enum.ParticleEmitterShape.Box
        emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
        emitter.Rate = 0
        emitter.Enabled = false
        emitter.Lifetime = NumberRange.new(2.5, 4)
        emitter.Speed = NumberRange.new(0.2, 0.8)
        emitter.Acceleration = Vector3.new(0, -4, 0)
        emitter.Size = NumberSequence.new(0.18)
        emitter.Color = ColorSequence.new(Color3.fromRGB(140, 126, 110))
        emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.55), NumberSequenceKeypoint.new(1, 1) })
        emitter.LightEmission = 0
        emitter.Parent = carrier
        dustEmitter = emitter

        connection = RunService.Heartbeat:Connect(step)
    else
        if not active then
            return
        end
        active = false
        local current = connection
        if current then
            current:Disconnect()
            connection = nil
        end
        local created = folder
        if created then
            created:Destroy()
            folder = nil
        end
        dustPart = nil
        dustEmitter = nil
        table.clear(bats)
    end
end

return CaveLife
