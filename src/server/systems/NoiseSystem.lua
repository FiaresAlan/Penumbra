local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Enums = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums"))
local Remotes = ReplicatedStorage:WaitForChild("EcosRemotes")
local VoiceSpike = Remotes:WaitForChild("VoiceSpike")
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))

local NoiseSystem = {}

local voiceEvent = Instance.new("BindableEvent")
NoiseSystem.VoiceSpiked = voiceEvent.Event

local playerNoise = {}
local voiceSpikes = {}
local lastSamples = {}
local lastVoiceAt = {}
local furyActive = false

-- Velocidade horizontal medida no servidor pelo deslocamento entre duas leituras.
local function measureSpeed(player, root)
    local now = os.clock()
    local last = lastSamples[player]
    lastSamples[player] = { position = root.Position, time = now }
    if not last then return 0 end

    local dt = now - last.time
    if dt <= 0 then return 0 end

    local delta = root.Position - last.position
    local speed = Vector3.new(delta.X, 0, delta.Z).Magnitude / dt
    return math.min(speed, Config.SprintSpeed)
end

-- Na fúria, quem está dentro de uma Zona de Fúria é ouvido mesmo parado.
local function inFuryZone(position)
    local folder = workspace:FindFirstChild("FuryZones")
    if not folder then return false end
    for _, zone in ipairs(folder:GetChildren()) do
        if zone:IsA("BasePart") then
            local relative = zone.CFrame:PointToObjectSpace(position)
            local half = zone.Size / 2
            if math.abs(relative.X) <= half.X and math.abs(relative.Y) <= half.Y and math.abs(relative.Z) <= half.Z then
                return true
            end
        end
    end
    return false
end

local function calculateNoise(player)
    if PlayerState.Get(player) ~= Enums.PlayerLocation.Cave then
        lastSamples[player] = nil
        return 0
    end
    local char = player.Character
    if not char then return 0 end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root then return 0 end

    local weight = char:GetAttribute("CarryWeight") or 0
    local speed = measureSpeed(player, root)
    local baseNoise = Config.BaseNoise
    local runNoise = (speed / Config.SprintSpeed) * Config.RunNoiseMultiplier
    local weightNoise = (weight / Config.MaxCarryWeight) * Config.WeightNoiseMultiplier

    local spike = 0
    local vs = voiceSpikes[player]
    if vs and os.clock() < vs.expiresAt then
        spike = vs.amount
    end

    local total = baseNoise + runNoise + weightNoise + spike
    if furyActive and inFuryZone(root.Position) then
        total = math.max(total, Config.FuryZoneNoise)
    end
    return total
end

function NoiseSystem.GetNoise(player)
    return playerNoise[player] or 0
end

function NoiseSystem.SetFury(active)
    furyActive = active
end

function NoiseSystem.GetLoudestPlayer()
    local loudest = nil
    local maxNoise = -1
    for p, n in pairs(playerNoise) do
        local char = p.Character
        if PlayerState.Get(p) == Enums.PlayerLocation.Cave
            and char and char:FindFirstChildOfClass("Humanoid") and char.Humanoid.Health > 0 then
            if n > maxNoise then
                maxNoise = n
                loudest = p
            end
        end
    end
    return loudest, maxNoise
end

function NoiseSystem.Init()
    VoiceSpike.OnServerEvent:Connect(function(player, intensity)
        if typeof(intensity) ~= "number" then return end
        if intensity ~= intensity then return end -- NaN

        local location = PlayerState.Get(player)
        if location ~= Enums.PlayerLocation.Cave and location ~= Enums.PlayerLocation.Captive then return end

        -- No máximo 2 por segundo por jogador
        local now = os.clock()
        if lastVoiceAt[player] and now - lastVoiceAt[player] < 0.5 then return end
        lastVoiceAt[player] = now

        local clamped = math.clamp(intensity, 0, 10)
        voiceSpikes[player] = {
            amount = clamped / 10 * Config.VoiceSpikeAmount,
            expiresAt = now + Config.VoiceSpikeDecay,
        }
        voiceEvent:Fire(player, clamped)
    end)

    Players.PlayerRemoving:Connect(function(p)
        playerNoise[p] = nil
        voiceSpikes[p] = nil
        lastSamples[p] = nil
        lastVoiceAt[p] = nil
    end)

    task.spawn(function()
        while true do
            for _, player in ipairs(Players:GetPlayers()) do
                playerNoise[player] = calculateNoise(player)
            end
            task.wait(0.1)
        end
    end)
end

return NoiseSystem
