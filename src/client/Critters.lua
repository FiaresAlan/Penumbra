--!strict
-- R7c: coelhos na floresta. Só visual e só no cliente: andam aos pulinhos, e fogem quando o jogador chega perto.
-- Ligado só na superfície, longe das praças. Ao descer, tudo é destruído e a conexão é solta.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)

local player = Players.LocalPlayer

local Critters = {}

local COUNT = 14
local SPAWN_MIN = 40
local SPAWN_MAX = 120
local DESPAWN_DISTANCE = 150
local FLEE_DISTANCE = 22
local CALM_DISTANCE = 42
local WALK_SPEED = 4
local FLEE_SPEED = 20

type Rabbit = {
    model: Model,
    position: Vector3,
    heading: Vector3, -- direção horizontal atual
    state: string, -- "idle" | "walk" | "flee"
    untilTime: number,
    groundY: number,
    hopPhase: number,
}

local active = false
local connection: RBXScriptConnection? = nil
local folder: Folder? = nil
local rabbits: { Rabbit } = {}
local rng = Random.new()
local sinceScan = 0

local FUR = { Color3.fromRGB(150, 118, 84), Color3.fromRGB(196, 176, 150), Color3.fromRGB(110, 92, 74) }

local function part(parent: Model, name: string, size: Vector3, offset: Vector3, color: Color3, shape: Enum.PartType): Part
    local piece = Instance.new("Part")
    piece.Name = name
    piece.Shape = shape
    piece.Size = size
    piece.Color = color
    piece.Material = Enum.Material.Fabric
    piece.Anchored = true
    piece.CanCollide = false
    piece.CanQuery = false
    piece.CanTouch = false
    piece.CastShadow = false
    piece.CFrame = CFrame.new(offset)
    piece.Parent = parent
    return piece
end

local function buildModel(color: Color3): Model
    local model = Instance.new("Model")
    model.Name = "Coelho"
    local body = part(model, "Corpo", Vector3.new(1.1, 1, 1.7), Vector3.new(0, 0.5, 0), color, Enum.PartType.Ball)
    part(model, "Cabeca", Vector3.new(0.8, 0.8, 0.8), Vector3.new(0, 0.9, -0.9), color, Enum.PartType.Ball)
    part(model, "OrelhaE", Vector3.new(0.18, 0.8, 0.25), Vector3.new(-0.2, 1.6, -0.95), color, Enum.PartType.Block)
    part(model, "OrelhaD", Vector3.new(0.18, 0.8, 0.25), Vector3.new(0.2, 1.6, -0.95), color, Enum.PartType.Block)
    part(model, "Rabo", Vector3.new(0.4, 0.4, 0.4), Vector3.new(0, 0.7, 0.9), Color3.fromRGB(240, 235, 225), Enum.PartType.Ball)
    model.PrimaryPart = body
    return model
end

local function params(): RaycastParams
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local ignore: { Instance } = {}
    local character = player.Character
    if character then
        table.insert(ignore, character)
    end
    if folder then
        table.insert(ignore, folder)
    end
    rayParams.FilterDescendantsInstances = ignore
    return rayParams
end

local function groundAt(x: number, z: number, rayParams: RaycastParams): number?
    local result = workspace:Raycast(Vector3.new(x, 120, z), Vector3.new(0, -240, 0), rayParams)
    if result and result.Instance:IsA("Terrain") then
        return result.Position.Y
    end
    return nil
end

local function onPad(x: number, z: number, extra: number): boolean
    for _, pad in pairs(Config.WorldPads) do
        if math.sqrt((x - pad.x) ^ 2 + (z - pad.z) ^ 2) < pad.r + extra then
            return true
        end
    end
    return false
end

local function spawnRabbit(center: Vector3, rayParams: RaycastParams)
    local current = folder
    if not current then
        return
    end
    for _ = 1, 6 do
        local angle = rng:NextNumber(0, math.pi * 2)
        local distance = rng:NextNumber(SPAWN_MIN, SPAWN_MAX)
        local x = center.X + math.cos(angle) * distance
        local z = center.Z + math.sin(angle) * distance
        local bounds = Config.WorldBounds
        if x > bounds.MinX + 20 and x < bounds.MaxX - 20 and z > bounds.MinZ + 20 and z < bounds.MaxZ - 20 and not onPad(x, z, -55) then
            local y = groundAt(x, z, rayParams)
            if y then
                local model = buildModel(FUR[rng:NextInteger(1, #FUR)])
                model.Parent = current
                table.insert(rabbits, {
                    model = model,
                    position = Vector3.new(x, y, z),
                    heading = Vector3.new(1, 0, 0),
                    state = "idle",
                    untilTime = os.clock() + rng:NextNumber(0.5, 4),
                    groundY = y,
                    hopPhase = 0,
                })
                if #rabbits == COUNT and RunService:IsStudio() then
                    print(string.format("[Critters] %d coelhos na floresta", #rabbits))
                end
                return
            end
        end
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
    local rayParams: RaycastParams? = nil

    sinceScan += dt
    local scan = sinceScan >= 0.2
    if scan then
        sinceScan = 0
        rayParams = params()
    end

    for index = #rabbits, 1, -1 do
        local rabbit = rabbits[index]
        local flat = Vector3.new(rabbit.position.X - playerPosition.X, 0, rabbit.position.Z - playerPosition.Z)
        local distance = flat.Magnitude

        if distance > DESPAWN_DISTANCE then
            rabbit.model:Destroy()
            table.remove(rabbits, index)
        else
            if distance < FLEE_DISTANCE and rabbit.state ~= "flee" then
                rabbit.state = "flee"
                rabbit.heading = if distance > 0.1 then flat.Unit else Vector3.new(1, 0, 0)
            elseif rabbit.state == "flee" and distance > CALM_DISTANCE then
                rabbit.state = "idle"
                rabbit.untilTime = now + rng:NextNumber(2, 6)
            elseif rabbit.state == "idle" and now >= rabbit.untilTime then
                local angle = rng:NextNumber(0, math.pi * 2)
                rabbit.heading = Vector3.new(math.cos(angle), 0, math.sin(angle))
                rabbit.state = "walk"
                rabbit.untilTime = now + rng:NextNumber(1, 2.5)
            elseif rabbit.state == "walk" and now >= rabbit.untilTime then
                rabbit.state = "idle"
                rabbit.untilTime = now + rng:NextNumber(2, 7)
            end

            local speed = 0
            if rabbit.state == "walk" then
                speed = WALK_SPEED
            elseif rabbit.state == "flee" then
                speed = FLEE_SPEED
            end
            if speed > 0 then
                rabbit.hopPhase += dt * (if rabbit.state == "flee" then 14 else 8)
                local moved = rabbit.position + rabbit.heading * speed * dt
                rabbit.position = Vector3.new(moved.X, rabbit.groundY, moved.Z)
                if onPad(moved.X, moved.Z, -60) then
                    rabbit.heading = -rabbit.heading
                end
            end
            if scan and rayParams then
                local y = groundAt(rabbit.position.X, rabbit.position.Z, rayParams)
                if y then
                    rabbit.groundY = y
                end
            end
            local hop = if speed > 0 then math.abs(math.sin(rabbit.hopPhase)) * (if rabbit.state == "flee" then 1.4 else 0.6) else 0
            local height = rabbit.groundY + hop
            rabbit.position = Vector3.new(rabbit.position.X, height, rabbit.position.Z)
            local look = if rabbit.heading.Magnitude > 0.01 then rabbit.heading else Vector3.new(1, 0, 0)
            rabbit.model:PivotTo(CFrame.lookAt(rabbit.position + Vector3.new(0, 0.5, 0), rabbit.position + Vector3.new(0, 0.5, 0) + look))
        end
    end

    if scan and #rabbits < COUNT and rayParams then
        spawnRabbit(playerPosition, rayParams)
    end
end

function Critters.SetSurface(onSurface: boolean)
    if onSurface then
        if active then
            return
        end
        active = true
        local created = Instance.new("Folder")
        created.Name = "Coelhos"
        created.Parent = workspace
        folder = created
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
        table.clear(rabbits)
    end
end

return Critters
