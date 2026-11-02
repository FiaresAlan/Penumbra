--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Enums = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums") :: ModuleScript)
local ExpeditionSystem = require((script.Parent :: Instance):WaitForChild("ExpeditionSystem") :: ModuleScript)

local QACommands = {}

-- Para criar um botão novo: adicione o id aqui e em Config.QAButtons.
local commands: { [string]: (player: Player) -> () } = {
    EndFailure = function(_player)
        ExpeditionSystem.End(Enums.ExpeditionOutcome.Failure)
    end,
    EndSuccess = function(_player)
        ExpeditionSystem.End(Enums.ExpeditionOutcome.Success)
    end,
}

function QACommands.Init()
    if not RunService:IsStudio() then
        return
    end

    local remote = Instance.new("RemoteEvent")
    remote.Name = "QACommand"
    remote.Parent = ReplicatedStorage:WaitForChild("EcosRemotes")

    remote.OnServerEvent:Connect(function(player: Player, commandId: unknown)
        if not RunService:IsStudio() then
            return
        end
        if typeof(commandId) ~= "string" then
            return
        end
        local handler = commands[commandId]
        if handler then
            handler(player)
        end
    end)

    print("[QA] Comandos de teste habilitados (somente Studio)")
end

return QACommands
