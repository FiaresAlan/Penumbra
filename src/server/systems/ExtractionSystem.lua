--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local systems = script.Parent :: Instance

local Config = require(Shared:WaitForChild("Config") :: ModuleScript)
local Enums = require(Shared:WaitForChild("Enums") :: ModuleScript)
local ElevatorUpdate = ReplicatedStorage:WaitForChild("EcosRemotes"):WaitForChild("ElevatorUpdate") :: RemoteEvent
local PlayerState = require(systems:WaitForChild("PlayerState") :: ModuleScript)
local LootSystem = require(systems:WaitForChild("LootSystem") :: ModuleScript)
local ExpeditionSystem = require(systems:WaitForChild("ExpeditionSystem") :: ModuleScript)

local Location = Enums.PlayerLocation
local Phase = Enums.ExpeditionPhase

local ExtractionSystem = {}

local extractedEvent = Instance.new("BindableEvent")
ExtractionSystem.Extracted = extractedEvent.Event

local State = {
    Idle = "Idle",
    Arriving = "Arriving",
    Open = "Open",
    Cooldown = "Cooldown",
}

local state: string = State.Idle
local generation = 0
local elevatorPart: BasePart? = nil
local elevatorPrompt: ProximityPrompt? = nil

local function getElevator(): BasePart?
    local found = workspace:FindFirstChild("Elevator")
    if found and found:IsA("BasePart") then
        return found
    end
    return nil
end

local function getRoot(player: Player): BasePart?
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then
        return root
    end
    return nil
end

local function isInsideElevator(player: Player): boolean
    local elevator = elevatorPart
    local root = getRoot(player)
    if not elevator or not root then
        return false
    end
    return (root.Position - elevator.Position).Magnitude < 15
end

local function updatePrompt()
    if elevatorPrompt then
        elevatorPrompt.Enabled = state == State.Idle and ExpeditionSystem.GetPhase() == Phase.Active
    end
end

-- Só quem está na caverna recebe o estado do elevador.
local function broadcast(stage: string, timeLeft: number)
    for _, player in ipairs(PlayerState.GetPlayersIn(Location.Cave)) do
        ElevatorUpdate:FireClient(player, { stage = stage, timeLeft = timeLeft })
    end
end

local function countdown(gen: number, stage: string, seconds: number): boolean
    for timeLeft = seconds, 1, -1 do
        if gen ~= generation then
            return false
        end
        broadcast(stage, timeLeft)
        task.wait(1)
    end
    return gen == generation
end

-- Quem estiver dentro do elevador quando as portas fecham sobe com a mochila.
local function carryPassengers()
    local passengers: { Player } = {}
    for _, player in ipairs(PlayerState.GetPlayersIn(Location.Cave)) do
        if isInsideElevator(player) then
            table.insert(passengers, player)
        end
    end

    for _, player in ipairs(passengers) do
        local inventory = LootSystem.GetInventory(player)
        local count = #inventory.cores
        print(string.format("[Extraction] %s subiu com %d núcleos (%d 💎)", player.Name, count, inventory.totalValue))
        if count > 0 then
            ExpeditionSystem.RecordExtraction(player)
        end
        extractedEvent:Fire(player, count)
        ExpeditionSystem.ReturnToLobby(player, true)
        LootSystem.ClearInventory(player)
    end
end

local function runCycle()
    if state ~= State.Idle or ExpeditionSystem.GetPhase() ~= Phase.Active then
        return
    end
    local gen = generation

    state = State.Arriving
    updatePrompt()
    if not countdown(gen, "arriving", Config.ElevatorArrivalTime) then
        return
    end

    state = State.Open
    if not countdown(gen, "open", Config.ElevatorCloseTime) then
        return
    end

    broadcast("closed", 0)
    carryPassengers()
    if gen ~= generation then
        return
    end

    state = State.Cooldown
    if not countdown(gen, "cooldown", Config.ElevatorCooldown) then
        return
    end

    state = State.Idle
    updatePrompt()
end

-- Usado só pelos comandos de QA do Studio.
function ExtractionSystem.QACall(player: Player)
    if PlayerState.Get(player) == Location.Cave then
        task.spawn(runCycle)
    end
end

function ExtractionSystem.Init()
    local elevator = getElevator()
    if not elevator then
        warn("[Ecos] Elevator não encontrado.")
        return
    end
    elevatorPart = elevator
    elevatorPrompt = elevator:FindFirstChildOfClass("ProximityPrompt")

    local prompt = elevatorPrompt
    if prompt then
        prompt.Triggered:Connect(function(player)
            if state ~= State.Idle or ExpeditionSystem.GetPhase() ~= Phase.Active then
                return
            end
            if PlayerState.Get(player) ~= Location.Cave then
                return
            end
            local root = getRoot(player)
            if not root or (root.Position - elevator.Position).Magnitude > 20 then
                return
            end
            task.spawn(runCycle)
        end)
    else
        warn("[Ecos] Elevator sem ProximityPrompt.")
    end

    ExpeditionSystem.Started:Connect(function()
        generation += 1
        state = State.Idle
        updatePrompt()
    end)
    ExpeditionSystem.Ended:Connect(function()
        generation += 1
        state = State.Idle
        updatePrompt()
        ElevatorUpdate:FireAllClients({ stage = "idle", timeLeft = 0 })
    end)
    updatePrompt()
end

return ExtractionSystem
