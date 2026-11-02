--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local systems = script.Parent :: Instance
local Enums = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums") :: ModuleScript)
local ExpeditionSystem = require(systems:WaitForChild("ExpeditionSystem") :: ModuleScript)
local ExtractionSystem = require(systems:WaitForChild("ExtractionSystem") :: ModuleScript)
local LootSystem = require(systems:WaitForChild("LootSystem") :: ModuleScript)
local GuardianAI = require(systems:WaitForChild("GuardianAI") :: ModuleScript)

local QACommands = {}

-- Para criar um botão novo: adicione o id aqui e em Config.QAButtons.
local commands: { [string]: (player: Player) -> () } = {
    EndFailure = function(_player)
        ExpeditionSystem.End(Enums.ExpeditionOutcome.Failure)
    end,
    EndSuccess = function(_player)
        ExpeditionSystem.End(Enums.ExpeditionOutcome.Success)
    end,
    DescendNow = function(player)
        ExpeditionSystem.ForceStart(player)
    end,
    GiveCore = function(player)
        LootSystem.GrantCore(player, Enums.CoreRarity.Common)
    end,
    GoToCaveElevator = function(player)
        local elevator = workspace:FindFirstChild("Elevator")
        local character = player.Character
        if elevator and elevator:IsA("BasePart") and character then
            character:PivotTo(CFrame.new(elevator.Position + Vector3.new(-9, 4 - elevator.Size.Y / 2, 0)))
        end
    end,
    CallCaveElevator = function(player)
        ExtractionSystem.QACall(player)
    end,
    Minute3 = function(_player)
        ExpeditionSystem.SetElapsedForQA(180)
    end,
    Minute8 = function(_player)
        ExpeditionSystem.SetElapsedForQA(480)
    end,
    GuardianNear = function(player)
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if root and root:IsA("BasePart") then
            GuardianAI.TeleportTo(root.Position + Vector3.new(25, 6, 0))
        end
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
