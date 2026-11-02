--!strict
-- Andar devagar: o cliente só pede; o servidor decide a velocidade. O ruído já vem do deslocamento real,
-- então andar devagar fica silencioso sem nenhuma regra extra no NoiseSystem.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local systems = script.Parent :: Instance
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local RateLimiter = require(systems:WaitForChild("RateLimiter") :: ModuleScript)

local Sneak = ReplicatedStorage:WaitForChild("EcosRemotes"):WaitForChild("Sneak") :: RemoteEvent

local SneakSystem = {}

local sneaking: { [Player]: boolean } = {}

local function apply(player: Player)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = if sneaking[player] then Config.SneakSpeed else Config.NormalWalkSpeed
    end
end

local function hook(player: Player)
    player.CharacterAdded:Connect(function()
        task.defer(apply, player)
    end)
end

function SneakSystem.Init()
    for _, player in ipairs(Players:GetPlayers()) do
        hook(player)
    end
    Players.PlayerAdded:Connect(hook)
    Players.PlayerRemoving:Connect(function(player)
        sneaking[player] = nil
    end)

    Sneak.OnServerEvent:Connect(function(player, wantsSneak: unknown)
        if not RateLimiter.Allow(player, "Sneak", 4, 6) then
            return
        end
        if typeof(wantsSneak) ~= "boolean" then
            return
        end
        sneaking[player] = wantsSneak
        apply(player)
    end)
end

return SneakSystem
