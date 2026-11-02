--!strict
-- Quando o cliente termina de iniciar, reenvia o estado que ele pode ter perdido (perfil, pedidos, local).
-- Sem isso, o que o servidor manda antes de o cliente conectar os eventos se perde.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local systems = script.Parent :: Instance
local PlayerProfile = require(systems:WaitForChild("PlayerProfile") :: ModuleScript)
local BlackMarketSystem = require(systems:WaitForChild("BlackMarketSystem") :: ModuleScript)
local LocationSync = require(systems:WaitForChild("LocationSync") :: ModuleScript)
local RateLimiter = require(systems:WaitForChild("RateLimiter") :: ModuleScript)

local ClientReady = ReplicatedStorage:WaitForChild("EcosRemotes"):WaitForChild("ClientReady") :: RemoteEvent

local ClientSync = {}

function ClientSync.Init()
    ClientReady.OnServerEvent:Connect(function(player)
        if not RateLimiter.Allow(player, "ClientReady", 0.5, 2) then
            return
        end
        PlayerProfile.Refresh(player)
        BlackMarketSystem.Publish()
        LocationSync.Send(player)
    end)
end

return ClientSync
