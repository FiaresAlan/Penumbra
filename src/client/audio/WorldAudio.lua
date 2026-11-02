--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local remote = ReplicatedStorage:WaitForChild("EcosRemotes"):WaitForChild("WorldAudio") :: RemoteEvent

local WorldAudio = {}

local listenerReady = false

-- Emissores só são ouvidos por um AudioListener. Cria um na câmera, uma única vez.
-- (SoundService.DefaultListenerLocation só pode ser lida por plugins, então não dá para checar.)
local function ensureListener()
    if listenerReady then
        return
    end
    listenerReady = true
    local camera = workspace.CurrentCamera
    if not camera then
        return
    end
    local listener = Instance.new("AudioListener")
    listener.Parent = camera
    local output = Instance.new("AudioDeviceOutput")
    output.Parent = camera
    local wire = Instance.new("Wire")
    wire.SourceInstance = listener
    wire.TargetInstance = output
    wire.Parent = output
end

local function shakeCamera(duration: number, intensity: number)
    local startedAt = os.clock()
    RunService:BindToRenderStep("EcosCameraShake", Enum.RenderPriority.Camera.Value + 1, function()
        local elapsed = os.clock() - startedAt
        local camera = workspace.CurrentCamera
        if elapsed >= duration or not camera then
            RunService:UnbindFromRenderStep("EcosCameraShake")
            return
        end
        local fade = 1 - elapsed / duration
        local offset = Vector3.new(math.random() - 0.5, math.random() - 0.5, 0) * intensity * fade
        camera.CFrame = camera.CFrame * CFrame.new(offset)
    end)
end

local function playSound(soundKey: string, position: Vector3?)
    local assetId = Config.Audio[soundKey]
    if not assetId or assetId == "" then
        return
    end

    local holder = Instance.new("Folder")
    holder.Name = "EcosWorldAudio"
    holder.Parent = SoundService

    local audioPlayer = Instance.new("AudioPlayer")
    audioPlayer.Asset = assetId
    audioPlayer.Looping = false
    local speeds = Config.AudioSpeed and Config.AudioSpeed[soundKey]
    if speeds then
        audioPlayer.PlaybackSpeed = speeds[1] + math.random() * (speeds[2] - speeds[1])
    end
    audioPlayer.Parent = holder

    local wire = Instance.new("Wire")
    wire.SourceInstance = audioPlayer
    wire.Parent = holder

    if position then
        -- Som espacial: um emissor numa peça invisível parada no ponto
        ensureListener()
        local anchor = Instance.new("Part")
        anchor.Anchored = true
        anchor.CanCollide = false
        anchor.CanQuery = false
        anchor.Transparency = 1
        anchor.Size = Vector3.new(1, 1, 1)
        anchor.Position = position
        anchor.Parent = holder
        local emitter = Instance.new("AudioEmitter")
        emitter.Parent = anchor
        wire.TargetInstance = emitter
    else
        local output = Instance.new("AudioDeviceOutput")
        output.Parent = holder
        wire.TargetInstance = output
    end

    local function start()
        audioPlayer:Play()
        task.delay(math.max(audioPlayer.TimeLength, 1) + 1, function()
            holder:Destroy()
        end)
    end

    if audioPlayer.IsReady then
        start()
    else
        local connection: RBXScriptConnection
        connection = audioPlayer:GetPropertyChangedSignal("IsReady"):Connect(function()
            if audioPlayer.IsReady then
                connection:Disconnect()
                start()
            end
        end)
        task.delay(10, function()
            if connection.Connected then
                connection:Disconnect()
                holder:Destroy()
            end
        end)
    end
end

function WorldAudio.Init()
    remote.OnClientEvent:Connect(function(soundKey: unknown, position: unknown)
        if typeof(soundKey) ~= "string" then
            return
        end
        local at = if typeof(position) == "Vector3" then position else nil
        if soundKey == "Rumble" then
            shakeCamera(1.6, 1.2)
        end
        playSound(soundKey, at)
    end)
end

return WorldAudio
