--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local VoiceSpike = ReplicatedStorage:WaitForChild("EcosRemotes"):WaitForChild("VoiceSpike") :: RemoteEvent

local VoiceNoise = {}

-- Liga o microfone do jogador a um AudioAnalyzer e avisa o servidor quando a voz é alta.
-- A leitura é feita no cliente porque no servidor o analisador devolve zero.
function VoiceNoise.Init()
    task.spawn(function()
        local device = player:WaitForChild("AudioDeviceInput", 15)
        if not device or not device:IsA("AudioDeviceInput") then
            warn("[Voice] AudioDeviceInput não encontrado; o ruído de voz fica só na tecla V.")
            return
        end

        local analyzer = Instance.new("AudioAnalyzer")
        analyzer.Name = "EcosVoiceAnalyzer"
        analyzer.Parent = device

        local wire = Instance.new("Wire")
        wire.SourceInstance = device
        wire.TargetInstance = analyzer
        wire.Parent = analyzer

        local loudSince: number? = nil
        local lastSent = 0
        local lastLog = 0

        while true do
            task.wait(0.1)
            local rms = analyzer.RmsLevel
            local now = os.clock()

            if Config.VoiceDebug and rms >= 0.05 and now - lastLog >= 0.5 then
                lastLog = now
                print(string.format("[Voice] rms=%.3f", rms))
            end

            if rms >= Config.VoiceRmsThreshold then
                local started = loudSince or now
                loudSince = started
                if now - started >= Config.VoiceSustainTime and now - lastSent >= 1 then
                    lastSent = now
                    local intensity = math.clamp(rms / 0.5 * 10, 0, 10)
                    VoiceSpike:FireServer(intensity)
                    if Config.VoiceDebug then
                        print(string.format("[Voice] spike intensidade=%.1f", intensity))
                    end
                end
            else
                loudSince = nil
            end
        end
    end)
end

return VoiceNoise
