--!strict
-- Botão DESCER do HUD do lobby. O cliente só pede; o servidor decide: perto do elevador começa a contagem
-- (igual ao prompt físico); longe dele, leva o jogador de carroça até o elevador, e só então ele pode descer.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local systems = script.Parent :: Instance
local ExpeditionSystem = require(systems:WaitForChild("ExpeditionSystem") :: ModuleScript)
local TravelSystem = require(systems:WaitForChild("TravelSystem") :: ModuleScript)
local PlayerProfile = require(systems:WaitForChild("PlayerProfile") :: ModuleScript)
local RateLimiter = require(systems:WaitForChild("RateLimiter") :: ModuleScript)

local RequestDescent = ReplicatedStorage:WaitForChild("EcosRemotes"):WaitForChild("RequestDescent") :: RemoteEvent

local DescentRequest = {}

function DescentRequest.Init()
    RequestDescent.OnServerEvent:Connect(function(player)
        if not RateLimiter.Allow(player, "RequestDescent", 1, 2) then
            return
        end
        local result = ExpeditionSystem.TryBeginDescent(player)
        print(string.format("[Descent] pedido de %s: %s", player.Name, result))
        if result == "far" then
            TravelSystem.ToElevator(player)
        elseif result == "busy" then
            PlayerProfile.Notify(player, "A descida não está disponível agora")
        end
    end)
end

return DescentRequest
