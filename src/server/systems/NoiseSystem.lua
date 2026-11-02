local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("EcosRemotes")
local VoiceSpike = Remotes:WaitForChild("VoiceSpike")

local NoiseSystem = {}

local playerNoise = {}
local voiceSpikes = {}

local function calculateNoise(player)
    local char = player.Character
    if not char then return 0 end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return 0 end

    local weight = char:GetAttribute("CarryWeight") or 0
    local speed = humanoid.WalkSpeed
    local baseNoise = Config.BaseNoise
    local runNoise = (speed / Config.SprintSpeed) * Config.RunNoiseMultiplier
    local weightNoise = (weight / Config.MaxCarryWeight) * Config.WeightNoiseMultiplier

    local spike = 0
    local vs = voiceSpikes[player]
    if vs and os.clock() < vs.expiresAt then
        spike = vs.amount
    end

    return baseNoise + runNoise + weightNoise + spike
end

function NoiseSystem.GetNoise(player)
    return playerNoise[player] or 0
end

function NoiseSystem.GetLoudestPlayer()
    local loudest = nil
    local maxNoise = -1
    for p, n in pairs(playerNoise) do
        local char = p.Character
        if char and char:FindFirstChildOfClass("Humanoid") and char.Humanoid.Health > 0 then
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
        local amount = math.clamp(intensity, 0, 10) / 10 * Config.VoiceSpikeAmount
        voiceSpikes[player] = {
            amount = amount,
            expiresAt = os.clock() + Config.VoiceSpikeDecay,
        }
    end)

    Players.PlayerRemoving:Connect(function(p)
        playerNoise[p] = nil
        voiceSpikes[p] = nil
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