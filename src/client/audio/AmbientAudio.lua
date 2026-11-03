--!strict
-- Ambiente sonoro: camadas em loop por zona (lobby, floresta, caverna), gotas aleatórias, passos do Guardião,
-- batimento cardíaco que cresce com a proximidade e o sino do elevador. Tudo é só som no cliente.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local ElevatorUpdate = ReplicatedStorage:WaitForChild("EcosRemotes"):WaitForChild("ElevatorUpdate") :: RemoteEvent
local audioFolder = script.Parent :: Instance
local clientRoot = audioFolder.Parent :: Instance
local WorldAudio = require(audioFolder:WaitForChild("WorldAudio") :: ModuleScript)
local GuardianPresence = require(clientRoot:WaitForChild("GuardianPresence") :: ModuleScript)

local AmbientAudio = {}

type Layer = { player: AudioPlayer, zone: string, base: number, current: number, name: string, music: boolean }

local layers: { Layer } = {}
local heartbeat: AudioPlayer? = nil
local heartbeatVolume = 0
local inCave = false
local forestFactor = 0
local mineFactor = 0
local villageFactor = 0
local musicScale = 1 -- Ajustes: 1, 0.5 ou 0
local debugEnabled = RunService:IsStudio()

local holder = Instance.new("Folder")
holder.Name = "EcosAmbient"

local function makeLoop(assetKey: string): AudioPlayer?
    local asset = Config.Audio[assetKey]
    if not asset or asset == "" then
        return nil
    end
    local audioPlayer = Instance.new("AudioPlayer")
    audioPlayer.Name = assetKey
    audioPlayer.Asset = asset
    audioPlayer.Looping = true
    audioPlayer.Volume = 0
    audioPlayer.Parent = holder

    local output = Instance.new("AudioDeviceOutput")
    output.Name = assetKey .. "Out"
    output.Parent = holder
    local wire = Instance.new("Wire")
    wire.SourceInstance = audioPlayer
    wire.TargetInstance = output
    wire.Parent = holder

    audioPlayer:Play()
    if debugEnabled then
        task.spawn(function()
            local waited = 0
            while not audioPlayer.IsReady and waited < 15 do
                task.wait(0.5)
                waited += 0.5
            end
            print(string.format("[Audio] %s: %s (%.1fs)", assetKey, if audioPlayer.IsReady then "pronto" else "NÃO carregou", audioPlayer.TimeLength))
        end)
    end
    return audioPlayer
end

-- Volume desejado de cada camada para o estado atual
local function targetVolume(layer: Layer): number
    local volume = 0
    if layer.zone == "cave" then
        volume = if inCave then layer.base else 0
        -- A tensão sobe com o tempo: o drone fica mais presente nos tiers mais agressivos
        if layer.name == "CaveDrone" then
            local tier = workspace:GetAttribute("GuardianTier")
            if tier == "Fury" then
                volume *= 1.8
            elseif tier == "Normal" then
                volume *= 1.25
            end
        end
    elseif layer.zone == "lobby" then
        volume = if inCave then 0 else layer.base * math.max(mineFactor, villageFactor)
    elseif layer.zone == "mine" then
        volume = if inCave then 0 else layer.base * mineFactor
    elseif layer.zone == "village" then
        volume = if inCave then 0 else layer.base * villageFactor
    elseif layer.zone == "forest" then
        volume = if inCave then 0 else layer.base * forestFactor
    end
    if layer.music then
        volume *= musicScale
    end
    return volume
end

-- 1 = música alta, 0.5 = baixa, 0 = desligada (só a música; o ambiente continua)
function AmbientAudio.SetMusicScale(scale: number)
    musicScale = math.clamp(scale, 0, 1)
end

function AmbientAudio.GetMusicScale(): number
    return musicScale
end

local function nearPad(position: Vector3, pad: { x: number, z: number, r: number }): number
    local distance = (Vector3.new(position.X, 0, position.Z) - Vector3.new(pad.x, 0, pad.z)).Magnitude
    return math.clamp((pad.r + 40 - distance) / 40, 0, 1)
end

function AmbientAudio.SetCave(isCave: boolean)
    inCave = isCave
end

function AmbientAudio.Init()
    holder.Parent = SoundService

    for _, definition in ipairs(Config.AmbientLayers) do
        local audioPlayer = makeLoop(definition.asset)
        if audioPlayer then
            table.insert(layers, { player = audioPlayer, zone = definition.zone, base = definition.volume, current = 0, name = definition.asset, music = definition.music == true })
        end
    end
    heartbeat = makeLoop("Heartbeat")

    -- Suaviza os volumes e calcula a mistura lobby/floresta pela posição
    local elapsed = 0
    RunService.Heartbeat:Connect(function(dt)
        elapsed += dt
        if elapsed < 0.1 then
            return
        end
        local step = elapsed
        elapsed = 0

        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if root and root:IsA("BasePart") then
            -- Mina e vila têm as suas camadas; fora das duas áreas planas é floresta
            mineFactor = nearPad(root.Position, Config.WorldPads.Mina)
            villageFactor = nearPad(root.Position, Config.WorldPads.Vila)
            forestFactor = 1 - math.max(mineFactor, villageFactor)
        end

        for _, layer in ipairs(layers) do
            local target = targetVolume(layer)
            layer.current += (target - layer.current) * math.min(1, step * 1.2) -- cerca de 1 segundo para virar
            layer.player.Volume = layer.current
        end

        local beat = heartbeat
        if beat then
            local want = if inCave then GuardianPresence.GetIntensity() * 0.9 else 0
            heartbeatVolume += (want - heartbeatVolume) * math.min(1, step * 3)
            beat.Volume = heartbeatVolume
            beat.PlaybackSpeed = 0.9 + GuardianPresence.GetIntensity() * 0.5 -- bate mais rápido quando ele está perto
        end
    end)

    -- Gotas aleatórias perto do jogador, só na caverna
    task.spawn(function()
        while true do
            task.wait(4 + math.random() * 8)
            local character = player.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if inCave and root and root:IsA("BasePart") then
                local angle = math.random() * math.pi * 2
                local radius = 8 + math.random() * 22
                WorldAudio.Play("Drip", root.Position + Vector3.new(math.cos(angle) * radius, 1, math.sin(angle) * radius))
            end
        end
    end)

    -- Passos pesados do Guardião: no ritmo da velocidade dele, em volta dele
    task.spawn(function()
        while true do
            local interval = 0.6
            local guardian = workspace:FindFirstChild("Guardian")
            local guardianRoot = guardian and guardian:FindFirstChild("HumanoidRootPart")
            local character = player.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if inCave and guardianRoot and guardianRoot:IsA("BasePart") and root and root:IsA("BasePart") then
                local velocity = guardianRoot.AssemblyLinearVelocity
                local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
                if speed > 2 and (guardianRoot.Position - root.Position).Magnitude < 90 then
                    WorldAudio.Play("Footstep", guardianRoot.Position - Vector3.new(0, 4, 0))
                    interval = math.clamp(0.55 * (14 / speed), 0.35, 0.9)
                end
            end
            task.wait(interval)
        end
    end)

    -- Sino quando as portas do elevador abrem
    ElevatorUpdate.OnClientEvent:Connect(function(data: unknown)
        if typeof(data) == "table" and (data :: any).stage == "open" and (data :: any).timeLeft == (workspace:GetAttribute("ElevatorWindow") or Config.ElevatorCloseTime) then
            WorldAudio.Play("Chime", nil)
        end
    end)
end

return AmbientAudio
