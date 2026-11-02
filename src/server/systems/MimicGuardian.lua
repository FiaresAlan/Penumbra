--!strict
-- Guardião Corista: quando alguém fala alto, uma voz falsa toca em outro ponto da caverna.
-- Nesta fase usa uma voz genérica distorcida (Config.Audio.MimicVoice); a voz real fica para depois.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local systems = script.Parent :: Instance
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local Enums = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums") :: ModuleScript)
local PlayerState = require(systems:WaitForChild("PlayerState") :: ModuleScript)
local NoiseSystem = require(systems:WaitForChild("NoiseSystem") :: ModuleScript)
local AudioBroadcast = require(systems:WaitForChild("AudioBroadcast") :: ModuleScript)
local FloorPicker = require(systems:WaitForChild("FloorPicker") :: ModuleScript)

local MimicGuardian = {}

local connection: RBXScriptConnection? = nil
local lastTrigger = 0

local function groupCenter(): Vector3?
    local sum = Vector3.zero
    local count = 0
    for _, player in ipairs(PlayerState.GetPlayersIn(Enums.PlayerLocation.Cave)) do
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if root and root:IsA("BasePart") then
            sum += root.Position
            count += 1
        end
    end
    if count == 0 then
        return nil
    end
    return sum / count
end

function MimicGuardian.Start()
    MimicGuardian.Stop()
    lastTrigger = 0
    connection = NoiseSystem.VoiceSpiked:Connect(function(player: Player, intensity: number)
        if intensity < Config.MimicTriggerIntensity then
            return
        end
        if PlayerState.Get(player) ~= Enums.PlayerLocation.Cave then
            return
        end
        local now = os.clock()
        if now - lastTrigger < Config.MimicCooldown then
            return
        end
        local center = groupCenter()
        if not center then
            return
        end
        local floor = FloorPicker.Pick(center, Config.MimicMinDistance, Config.MimicMaxDistance)
        if not floor then
            return
        end
        lastTrigger = now
        local point = floor + Vector3.new(0, 2, 0)
        print(string.format("[Mimic] voz falsa a %.0f studs do grupo", (point - center).Magnitude))
        AudioBroadcast.Play("MimicVoice", point)
    end)
end

function MimicGuardian.Stop()
    if connection then
        connection:Disconnect()
        connection = nil
    end
end

return MimicGuardian
