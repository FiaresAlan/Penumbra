--!strict
-- P11 (Features.EchoOthers): quando um jogador faz um barulho de voz na caverna, os OUTROS jogadores que estão na caverna às vezes
-- ouvem um eco distorcido e distante (sem posição: nada revela onde o colega está). Só com 2 ou mais jogadores na caverna,
-- com chance e tempo de espera por jogador. Não afeta o ruído que o Guardião escuta.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local systems = script.Parent :: Instance
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local Enums = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums") :: ModuleScript)
local NoiseSystem = require(systems:WaitForChild("NoiseSystem") :: ModuleScript)
local PlayerState = require(systems:WaitForChild("PlayerState") :: ModuleScript)

local EchoOthers = {}

local remote = ReplicatedStorage:WaitForChild("EcosRemotes"):WaitForChild("WorldAudio") :: RemoteEvent
local rng = Random.new()
local lastEcho: { [number]: number } = {}

function EchoOthers.Init()
    NoiseSystem.VoiceSpiked:Connect(function(player: Player)
        if not Config.Features.EchoOthers then
            return
        end
        local others: { Player } = {}
        for _, other in ipairs(PlayerState.GetPlayersIn(Enums.PlayerLocation.Cave)) do
            if other ~= player then
                table.insert(others, other)
            end
        end
        if #others == 0 or PlayerState.Get(player) ~= Enums.PlayerLocation.Cave then
            return
        end
        local now = os.clock()
        if now - (lastEcho[player.UserId] or -math.huge) < Config.EchoOthers.Cooldown then
            return
        end
        if rng:NextNumber() > Config.EchoOthers.Chance then
            return
        end
        lastEcho[player.UserId] = now
        for _, other in ipairs(others) do
            remote:FireClient(other, Config.EchoOthers.SoundKey, nil)
        end
        print("[Echo] eco enviado a " .. #others .. " colega(s)")
    end)
end

return EchoOthers
