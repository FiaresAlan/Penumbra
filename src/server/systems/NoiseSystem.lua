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
local boosts = {} -- boosts[player][chave] = quantidade somada ao ruído
local pulses = {} -- pulses[player] = { amount, expiresAt }
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

-- Voz, picos e reforços temporários (resgate, batidas nas grades)
local function extraNoise(player)
    local total = 0
    local now = os.clock()

    local vs = voiceSpikes[player]
    if vs and now < vs.expiresAt then
        total = total + vs.amount
    end
    local pulse = pulses[player]
    if pulse and now < pulse.expiresAt then
        total = total + pulse.amount
    end
    if boosts[player] then
        for _, amount in pairs(boosts[player]) do
            total = total + amount
        end
    end
    return total
end

local function calculateNoise(player)
    local location = PlayerState.Get(player)
    local isCave = location == Enums.PlayerLocation.Cave
    local isCaptive = location == Enums.PlayerLocation.Captive
    if not isCave and not isCaptive then
        lastSamples[player] = nil
        return 0
    end

    -- O preso não se move nem carrega peso: só faz barulho por voz e batidas
    if isCaptive then
        lastSamples[player] = nil
        return extraNoise(player)
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

    local total = baseNoise + runNoise + weightNoise + extraNoise(player)
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

-- amount = nil remove o reforço daquela chave
function NoiseSystem.SetNoiseBoost(player, key, amount)
    boosts[player] = boosts[player] or {}
    boosts[player][key] = amount
end

function NoiseSystem.AddPulse(player, amount, seconds)
    pulses[player] = { amount = amount, expiresAt = os.clock() + seconds }
end

function NoiseSystem.GetLoudestPlayer()
    local loudest = nil
    local maxNoise = -1
    for p, n in pairs(playerNoise) do
        local char = p.Character
        local location = PlayerState.Get(p)
        local eligible = location == Enums.PlayerLocation.Cave
            or (location == Enums.PlayerLocation.Captive and n > 0)
        if eligible and char and char:FindFirstChildOfClass("Humanoid") and char.Humanoid.Health > 0 then
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
        boosts[p] = nil
        pulses[p] = nil
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
