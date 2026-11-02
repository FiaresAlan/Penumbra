--!strict
-- Avisa cada jogador onde ele está (para o cliente trocar a iluminação) e atualiza o painel do elevador do lobby.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local systems = script.Parent :: Instance
local Enums = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums") :: ModuleScript)
local PlayerState = require(systems:WaitForChild("PlayerState") :: ModuleScript)
local ExpeditionSystem = require(systems:WaitForChild("ExpeditionSystem") :: ModuleScript)

local LocationSync = {}

local remote = ReplicatedStorage:WaitForChild("EcosRemotes"):WaitForChild("LocationChanged") :: RemoteEvent

local function updateElevatorPanel()
    local elevator = workspace:FindFirstChild("LobbyElevator")
    local gui = elevator and elevator:FindFirstChild("StatusGui")
    local label = gui and gui:FindFirstChild("Status")
    if not label or not label:IsA("TextLabel") then
        return
    end

    local phase = ExpeditionSystem.GetPhase()
    if phase == Enums.ExpeditionPhase.Waiting then
        label.Text = "Pronto para descer"
    else
        local inside = #PlayerState.GetPlayersIn(Enums.PlayerLocation.Cave)
            + #PlayerState.GetPlayersIn(Enums.PlayerLocation.Dragged)
            + #PlayerState.GetPlayersIn(Enums.PlayerLocation.Captive)
        label.Text = string.format("Expedição em andamento\n%d na caverna", inside)
    end
end

function LocationSync.Init()
    PlayerState.Changed:Connect(function(player: Player, location: string)
        remote:FireClient(player, location)
    end)

    -- Quem entra com o personagem já carregado recebe o estado atual
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function()
            remote:FireClient(player, PlayerState.Get(player))
        end)
    end)

    task.spawn(function()
        while true do
            updateElevatorPanel()
            task.wait(1)
        end
    end)
end

return LocationSync
