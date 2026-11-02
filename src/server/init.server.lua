local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Garante que a pasta de remotes existe
local Remotes = ReplicatedStorage:FindFirstChild("EcosRemotes")
if not Remotes then
    Remotes = Instance.new("Folder")
    Remotes.Name = "EcosRemotes"
    Remotes.Parent = ReplicatedStorage
end

local function getOrCreateRemote(name, class)
    local r = Remotes:FindFirstChild(name)
    if not r then
        r = Instance.new(class)
        r.Name = name
        r.Parent = Remotes
    end
    return r
end

getOrCreateRemote("VoiceSpike", "RemoteEvent")
getOrCreateRemote("ElevatorUpdate", "RemoteEvent")
getOrCreateRemote("HUDUpdate", "RemoteEvent")

-- Carrega sistemas na ordem correta
local systems = script:WaitForChild("systems")
local NoiseSystem = require(systems:WaitForChild("NoiseSystem"))
local LootSystem = require(systems:WaitForChild("LootSystem"))
local GuardianAI = require(systems:WaitForChild("GuardianAI"))
local ExtractionSystem = require(systems:WaitForChild("ExtractionSystem"))

NoiseSystem.Init()
LootSystem.Init()
GuardianAI.Init()
ExtractionSystem.Init()

print("[Ecos] Servidor inicializado. Aguardando jogadores.")