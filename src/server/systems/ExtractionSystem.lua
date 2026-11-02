local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("EcosRemotes")
local ElevatorUpdate = Remotes:WaitForChild("ElevatorUpdate")
local LootSystem = require(script.Parent:WaitForChild("LootSystem"))

local ExtractionSystem = {}

local elevatorPart
local isCalled = false

local function getElevator()
    local e = workspace:FindFirstChild("Elevator")
    if e and e:IsA("BasePart") then return e end
    return nil
end

local function isInsideElevator(player)
    if not elevatorPart then return false end
    local char = player.Character
    if not char or not char.PrimaryPart then return false end
    return (char.PrimaryPart.Position - elevatorPart.Position).Magnitude < 15
end

local function startExtraction()
    if isCalled then return end
    isCalled = true

    ElevatorUpdate:FireAllClients({ stage = "arriving", timeLeft = Config.ElevatorArrivalTime })
    for t = Config.ElevatorArrivalTime, 1, -1 do
        ElevatorUpdate:FireAllClients({ stage = "arriving", timeLeft = t })
        task.wait(1)
    end

    ElevatorUpdate:FireAllClients({ stage = "open", timeLeft = Config.ElevatorCloseTime })
    for t = Config.ElevatorCloseTime, 1, -1 do
        ElevatorUpdate:FireAllClients({ stage = "open", timeLeft = t })
        task.wait(1)
    end

    ElevatorUpdate:FireAllClients({ stage = "closed", timeLeft = 0 })

    for _, player in ipairs(Players:GetPlayers()) do
        local inv = LootSystem.GetInventory(player)
        if isInsideElevator(player) then
            if #inv.cores > 0 then
                print(string.format("[Extraction] %s EXTRAIU %d núcleos (%d 💎)",
                    player.Name, #inv.cores, inv.totalValue))
            end
        else
            if #inv.cores > 0 then
                print(string.format("[Extraction] %s PERDEU %d núcleos",
                    player.Name, #inv.cores))
            end
        end
        LootSystem.ClearInventory(player)
    end

    task.wait(5)
    isCalled = false
end

function ExtractionSystem.Init()
    elevatorPart = getElevator()
    if not elevatorPart then
        warn("[Ecos] Elevator não encontrado. Rode o Command Bar de setup.")
        return
    end

    local prompt = elevatorPart:FindFirstChildOfClass("ProximityPrompt")
    if prompt then
        prompt.Triggered:Connect(function(player)
            if isCalled then return end
            task.spawn(startExtraction)
        end)
    else
        warn("[Ecos] Elevator sem ProximityPrompt. Rode o Command Bar de setup.")
    end
end

return ExtractionSystem