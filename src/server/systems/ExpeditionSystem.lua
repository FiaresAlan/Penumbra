--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local systems = script.Parent :: Instance

local Config = require(Shared:WaitForChild("Config") :: ModuleScript)
local Enums = require(Shared:WaitForChild("Enums") :: ModuleScript)
local PlayerState = require(systems:WaitForChild("PlayerState") :: ModuleScript)
local LootSystem = require(systems:WaitForChild("LootSystem") :: ModuleScript)
local GuardianAI = require(systems:WaitForChild("GuardianAI") :: ModuleScript)
local MovementGuard = require(systems:WaitForChild("MovementGuard") :: ModuleScript)

local Location = Enums.PlayerLocation
local Phase = Enums.ExpeditionPhase
local Outcome = Enums.ExpeditionOutcome

local ExpeditionSystem = {}

local startedEvent = Instance.new("BindableEvent")
local endedEvent = Instance.new("BindableEvent")

ExpeditionSystem.Started = startedEvent.Event
ExpeditionSystem.Ended = endedEvent.Event

local phase: string = Phase.Waiting
local startTime = 0
local descending = false
local hasExtraction = false
local extracted: { [Player]: boolean } = {}
local lobbyElevator: BasePart? = nil
local lobbyPrompt: ProximityPrompt? = nil

local function getPart(name: string): BasePart?
    local found = workspace:FindFirstChild(name)
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

local function isInExpedition(player: Player): boolean
    local location = PlayerState.Get(player)
    return location == Location.Cave or location == Location.Dragged or location == Location.Captive
end

local function updatePrompt()
    if lobbyPrompt then
        lobbyPrompt.Enabled = phase == Phase.Waiting and not descending
    end
end

-- Com StreamingEnabled, pede ao servidor para carregar o destino antes de teleportar.
local function teleportTo(player: Player, destination: BasePart)
    local character = player.Character
    if not character then
        return
    end
    local target = destination.CFrame + Vector3.new(0, Config.TeleportHeight, 0)
    -- A espera pelo carregamento do destino pode demorar: o anti-teleporte não pode agir nesse intervalo
    MovementGuard.Exempt(player, Config.StreamTimeout + 3)

    if workspace.StreamingEnabled then
        local ok, err = pcall(function()
            player:RequestStreamAroundAsync(target.Position, Config.StreamTimeout)
        end)
        if not ok then
            warn("[Expedition] RequestStreamAroundAsync falhou: " .. tostring(err))
        end
    end

    if player.Character == character and character.Parent then
        MovementGuard.Exempt(player, 3)
        character:PivotTo(target)
    end
end

function ExpeditionSystem.GetPhase(): string
    return phase
end

function ExpeditionSystem.GetElapsedTime(): number
    if phase ~= Phase.Active then
        return 0
    end
    return os.clock() - startTime
end

-- Usado só pelos comandos de QA do Studio: finge que a expedição já dura `seconds`.
function ExpeditionSystem.SetElapsedForQA(seconds: number)
    if phase == Phase.Active then
        startTime = os.clock() - seconds
    end
end

function ExpeditionSystem.RecordExtraction(player: Player)
    if phase ~= Phase.Active then
        return
    end
    extracted[player] = true
    hasExtraction = true
end

function ExpeditionSystem.ReturnToLobby(player: Player, keepLoot: boolean)
    if not keepLoot then
        LootSystem.ClearInventory(player)
    end
    PlayerState.Set(player, Location.Lobby)

    local arrival = getPart("LobbyArrival")
    if arrival then
        task.spawn(teleportTo, player, arrival)
    else
        warn("[Expedition] LobbyArrival não encontrado.")
    end
end

local function resetWorld()
    LootSystem.ResetCores()
    GuardianAI.Reset()
    workspace:SetAttribute("FirstCoreExtracted", false)
    extracted = {}
    hasExtraction = false
    phase = Phase.Waiting
    updatePrompt()
    print("[Expedition] Aguardando")
end

function ExpeditionSystem.End(outcome: string)
    if phase ~= Phase.Active then
        return
    end
    phase = Phase.Resetting

    for _, player in ipairs(Players:GetPlayers()) do
        if isInExpedition(player) then
            ExpeditionSystem.ReturnToLobby(player, false)
        end
    end

    local extractedPlayers: { Player } = {}
    for player in pairs(extracted) do
        if player.Parent == Players then
            table.insert(extractedPlayers, player)
        end
    end

    print(string.format("[Expedition] Encerrada: %s (%d extraíram, %.0fs)",
        outcome, #extractedPlayers, os.clock() - startTime))

    updatePrompt()
    endedEvent:Fire(outcome, extractedPlayers)
    task.delay(Config.ExpeditionResetDelay, resetWorld)
end

-- `leaving` é o jogador que está saindo do servidor, se for o caso.
local function checkForEnd(leaving: Player?)
    if phase ~= Phase.Active then
        return
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= leaving and isInExpedition(player) then
            return
        end
    end

    if hasExtraction then
        ExpeditionSystem.End(Outcome.Success)
    elseif leaving then
        ExpeditionSystem.End(Outcome.Abandoned)
    else
        ExpeditionSystem.End(Outcome.Failure)
    end
end

local function launch(passengers: { Player })
    local arrival = getPart("CaveArrival")
    if phase ~= Phase.Waiting then
        return
    end
    if not arrival then
        warn("[Expedition] CaveArrival não encontrado. Descida cancelada.")
        return
    end

    phase = Phase.Active
    startTime = os.clock()
    extracted = {}
    hasExtraction = false

    for _, player in ipairs(passengers) do
        PlayerState.Set(player, Location.Cave)
        task.spawn(teleportTo, player, arrival)
    end

    print(string.format("[Expedition] Iniciada com %d jogador(es)", #passengers))
    startedEvent:Fire()
end

local function startExpedition()
    local elevator = lobbyElevator
    if not elevator or phase ~= Phase.Waiting then
        return
    end

    local passengers: { Player } = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if PlayerState.Get(player) == Location.Lobby then
            local root = getRoot(player)
            if root and (root.Position - elevator.Position).Magnitude <= Config.LobbyElevatorRadius then
                table.insert(passengers, player)
            end
        end
    end

    if #passengers == 0 then
        print("[Expedition] Ninguém no elevador. Descida cancelada.")
        return
    end
    launch(passengers)
end

-- Usado só pelos comandos de QA do Studio: desce sem contagem nem proximidade.
function ExpeditionSystem.ForceStart(player: Player)
    if PlayerState.Get(player) == Location.Lobby and not descending then
        launch({ player })
    end
end

local function beginDescent()
    descending = true
    updatePrompt()
    print(string.format("[Expedition] Descida em %ds", Config.DescentCountdown))

    task.delay(Config.DescentCountdown, function()
        descending = false
        startExpedition()
        updatePrompt()
    end)
end

local function onCharacterAdded(player: Player, character: Model)
    character:SetAttribute("CarryWeight", 0)

    local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
    if not humanoid then
        return
    end

    humanoid.Died:Connect(function()
        if PlayerState.Get(player) == Location.Lobby then
            return
        end
        print("[Expedition] " .. player.Name .. " morreu. Mochila perdida.")
        LootSystem.ClearInventory(player)
        PlayerState.Set(player, Location.Lobby)
    end)
end

local function hookPlayer(player: Player)
    player.CharacterAdded:Connect(function(character)
        onCharacterAdded(player, character)
    end)
    if player.Character then
        task.spawn(onCharacterAdded, player, player.Character)
    end
end

function ExpeditionSystem.Init()
    for _, player in ipairs(Players:GetPlayers()) do
        hookPlayer(player)
    end
    Players.PlayerAdded:Connect(hookPlayer)
    Players.PlayerRemoving:Connect(function(player)
        extracted[player] = nil
        checkForEnd(player)
    end)

    PlayerState.Changed:Connect(function()
        checkForEnd(nil)
    end)

    lobbyElevator = getPart("LobbyElevator")
    if lobbyElevator then
        lobbyPrompt = lobbyElevator:FindFirstChildOfClass("ProximityPrompt")
    end
    local elevator = lobbyElevator
    local prompt = lobbyPrompt
    if elevator and prompt then
        prompt.Triggered:Connect(function(player)
            if phase ~= Phase.Waiting or descending then
                return
            end
            if PlayerState.Get(player) ~= Location.Lobby then
                return
            end
            local root = getRoot(player)
            if not root or (root.Position - elevator.Position).Magnitude > Config.LobbyElevatorRadius then
                return
            end
            beginDescent()
        end)
    else
        warn("[Expedition] LobbyElevator (com ProximityPrompt) não encontrado.")
    end

    task.spawn(function()
        while true do
            task.wait(1)
            if phase == Phase.Active and os.clock() - startTime >= Config.ExpeditionMaxTime then
                print("[Expedition] Tempo máximo atingido.")
                ExpeditionSystem.End(hasExtraction and Outcome.Success or Outcome.Failure)
            end
        end
    end)

    print("[Expedition] Aguardando")
end

return ExpeditionSystem
