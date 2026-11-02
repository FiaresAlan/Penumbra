--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Enums = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums") :: ModuleScript)

local PlayerState = {}

local locations: { [Player]: string } = {}
local changedEvent = Instance.new("BindableEvent")

PlayerState.Changed = changedEvent.Event

function PlayerState.Get(player: Player): string
    return locations[player] or Enums.PlayerLocation.Lobby
end

function PlayerState.Set(player: Player, location: string)
    if PlayerState.Get(player) == location then
        return
    end
    locations[player] = location
    changedEvent:Fire(player, location)
end

function PlayerState.GetPlayersIn(location: string): { Player }
    local result: { Player } = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if PlayerState.Get(player) == location then
            table.insert(result, player)
        end
    end
    return result
end

function PlayerState.Init()
    Players.PlayerRemoving:Connect(function(player)
        locations[player] = nil
    end)
end

return PlayerState
