--!strict
-- Envia sons de mundo aos jogadores que estão na expedição. O cliente é quem toca.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Enums = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums") :: ModuleScript)
local PlayerState = require((script.Parent :: Instance):WaitForChild("PlayerState") :: ModuleScript)

local AudioBroadcast = {}

local remote = ReplicatedStorage:WaitForChild("EcosRemotes"):WaitForChild("WorldAudio") :: RemoteEvent

function AudioBroadcast.Play(soundKey: string, position: Vector3?)
    for _, location in ipairs({ Enums.PlayerLocation.Cave, Enums.PlayerLocation.Dragged, Enums.PlayerLocation.Captive }) do
        for _, player in ipairs(PlayerState.GetPlayersIn(location)) do
            remote:FireClient(player, soundKey, position)
        end
    end
end

-- Som sem posição para quem está no lobby (por exemplo, o rugido abafado vindo da caverna).
function AudioBroadcast.PlayToLobby(soundKey: string)
    for _, player in ipairs(PlayerState.GetPlayersIn(Enums.PlayerLocation.Lobby)) do
        remote:FireClient(player, soundKey, nil)
    end
end

return AudioBroadcast
