--!strict
-- Andar devagar e correr: o cliente só pede; o servidor decide a velocidade. O ruído já vem do deslocamento real,
-- então andar devagar fica silencioso sem nenhuma regra extra no NoiseSystem.
-- Correr (Shift) só vale na superfície (Lobby); na caverna o pedido é ignorado. Devagar sempre vence correr.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local systems = script.Parent :: Instance
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local Enums = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums") :: ModuleScript)
local PlayerState = require(systems:WaitForChild("PlayerState") :: ModuleScript)
local RateLimiter = require(systems:WaitForChild("RateLimiter") :: ModuleScript)

local remotes = ReplicatedStorage:WaitForChild("EcosRemotes")
local Sneak = remotes:WaitForChild("Sneak") :: RemoteEvent
local Run = remotes:WaitForChild("Run") :: RemoteEvent

local SneakSystem = {}

local sneaking: { [Player]: boolean } = {}
local running: { [Player]: boolean } = {}

local function apply(player: Player)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end
    if sneaking[player] then
        humanoid.WalkSpeed = Config.SneakSpeed
    elseif running[player] and PlayerState.Get(player) == Enums.PlayerLocation.Lobby then
        humanoid.WalkSpeed = Config.SurfaceRunSpeed
    else
        humanoid.WalkSpeed = Config.NormalWalkSpeed
    end
end

local function hook(player: Player)
    player.CharacterAdded:Connect(function()
        task.defer(apply, player)
    end)
end

local function listen(remote: RemoteEvent, key: string, state: { [Player]: boolean })
    remote.OnServerEvent:Connect(function(player, wants: unknown)
        if not RateLimiter.Allow(player, key, 4, 6) then
            return
        end
        if typeof(wants) ~= "boolean" then
            return
        end
        state[player] = wants
        apply(player)
    end)
end

function SneakSystem.Init()
    -- Shift é a tecla de correr; sem isso ele também ligaria o travamento de câmera do Roblox
    StarterPlayer.EnableMouseLockOption = false

    for _, player in ipairs(Players:GetPlayers()) do
        hook(player)
    end
    Players.PlayerAdded:Connect(hook)
    Players.PlayerRemoving:Connect(function(player)
        sneaking[player] = nil
        running[player] = nil
    end)
    -- Ao descer ou voltar, a velocidade é reavaliada (correr acaba ao entrar na caverna)
    PlayerState.Changed:Connect(apply)

    listen(Sneak, "Sneak", sneaking)
    listen(Run, "Run", running)
end

return SneakSystem
