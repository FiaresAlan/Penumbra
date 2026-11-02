--!strict
-- Avisa cada cliente quando começar e parar de gravar o clipe: grava enquanto o jogador está fora do lobby.
-- O servidor só dá o sinal; quem grava é o cliente (CaptureService), e o cliente nunca envia nada de volta.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Enums = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums") :: ModuleScript)
local PlayerState = require((script.Parent :: Instance):WaitForChild("PlayerState") :: ModuleScript)

local ClipSignal = ReplicatedStorage:WaitForChild("EcosRemotes"):WaitForChild("ClipSignal") :: RemoteEvent

local ClipSystem = {}

local recording: { [Player]: boolean } = {}

function ClipSystem.Init()
    game:GetService("Players").PlayerRemoving:Connect(function(player)
        recording[player] = nil
    end)

    PlayerState.Changed:Connect(function(player: Player, location: string)
        if location == Enums.PlayerLocation.Lobby then
            if recording[player] then
                recording[player] = nil
                ClipSignal:FireClient(player, "stop")
            end
        elseif not recording[player] then
            recording[player] = true
            ClipSignal:FireClient(player, "start")
        end
    end)
end

return ClipSystem
