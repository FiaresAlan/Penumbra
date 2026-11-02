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
getOrCreateRemote("WorldAudio", "RemoteEvent")
getOrCreateRemote("Receipt", "RemoteEvent")
getOrCreateRemote("NestUpdate", "RemoteEvent")
getOrCreateRemote("CaptiveBang", "RemoteEvent")

-- O mapa é gerado antes dos sistemas, que procuram as peças pelo nome
require(script:WaitForChild("world"):WaitForChild("MapBuilder")).Build()

-- Carrega sistemas na ordem correta
local systems = script:WaitForChild("systems")
local PlayerState = require(systems:WaitForChild("PlayerState"))
local NoiseSystem = require(systems:WaitForChild("NoiseSystem"))
local LootSystem = require(systems:WaitForChild("LootSystem"))
local GuardianAI = require(systems:WaitForChild("GuardianAI"))
local ExtractionSystem = require(systems:WaitForChild("ExtractionSystem"))
local ExpeditionSystem = require(systems:WaitForChild("ExpeditionSystem"))
local KidnapSystem = require(systems:WaitForChild("KidnapSystem"))
local NestSystem = require(systems:WaitForChild("NestSystem"))
local GuardianDirector = require(systems:WaitForChild("GuardianDirector"))
local CaveClock = require(systems:WaitForChild("CaveClock"))
local QACommands = require(systems:WaitForChild("QACommands"))

PlayerState.Init()
NoiseSystem.Init()
LootSystem.Init()
GuardianAI.Init()
ExtractionSystem.Init()
ExpeditionSystem.Init()
KidnapSystem.Init()
NestSystem.Init()
GuardianDirector.Init()
CaveClock.Init()
QACommands.Init()

print("[Ecos] Servidor inicializado. Aguardando jogadores.")
