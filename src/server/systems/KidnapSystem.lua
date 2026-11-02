--!strict
-- Sequestro: o Guardião arrasta o jogador pego até o Ninho em vez de matá-lo.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local systems = script.Parent :: Instance
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local Enums = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums") :: ModuleScript)
local PlayerState = require(systems:WaitForChild("PlayerState") :: ModuleScript)
local ExpeditionSystem = require(systems:WaitForChild("ExpeditionSystem") :: ModuleScript)
local GuardianAI = require(systems:WaitForChild("GuardianAI") :: ModuleScript)

local Location = Enums.PlayerLocation

local KidnapSystem = {}

local captiveEvent = Instance.new("BindableEvent")
KidnapSystem.PlayerCaptive = captiveEvent.Event

type Drag = { player: Player, slot: BasePart, startedAt: number }

local drag: Drag? = nil
local slotOwner: { [BasePart]: Player } = {}
local frozen: { [Player]: boolean } = {}

local function getSlots(): { BasePart }
    local result: { BasePart } = {}
    local folder = workspace:FindFirstChild("NestSlots")
    if folder then
        for _, child in ipairs(folder:GetChildren()) do
            if child:IsA("BasePart") then
                table.insert(result, child)
            end
        end
    end
    table.sort(result, function(a, b)
        return a.Name < b.Name
    end)
    return result
end

local function freeSlot(): BasePart?
    for _, slot in ipairs(getSlots()) do
        if slotOwner[slot] == nil then
            return slot
        end
    end
    return nil
end

local function releaseSlot(player: Player)
    for slot, owner in pairs(slotOwner) do
        if owner == player then
            slotOwner[slot] = nil
        end
    end
end

-- Congela o personagem (preso ou sendo arrastado). O servidor o move por PivotTo.
local function setFrozen(player: Player, isFrozen: boolean)
    frozen[player] = if isFrozen then true else nil
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if root and root:IsA("BasePart") then
        root.Anchored = isFrozen
    end
    if humanoid then
        humanoid.PlatformStand = isFrozen
    end
end

function KidnapSystem.GetSlot(player: Player): BasePart?
    for slot, owner in pairs(slotOwner) do
        if owner == player then
            return slot
        end
    end
    return nil
end

-- Solta um preso: ele volta a ser jogador livre da caverna.
function KidnapSystem.Release(player: Player)
    local location = PlayerState.Get(player)
    if location ~= Location.Captive and location ~= Location.Dragged then
        return
    end
    releaseSlot(player)
    setFrozen(player, false)
    PlayerState.Set(player, Location.Cave)
end

local function finishDrag(player: Player, slot: BasePart)
    drag = nil
    local character = player.Character
    if character and PlayerState.Get(player) == Location.Dragged then
        character:PivotTo(slot.CFrame + Vector3.new(0, 3, 0))
        PlayerState.Set(player, Location.Captive)
        print(string.format("[Kidnap] %s está preso no Ninho (%s)", player.Name, slot.Name))
        captiveEvent:Fire(player, slot)
    end
    GuardianAI.EndDrag()
end

local function startDrag(player: Player, slot: BasePart)
    PlayerState.Set(player, Location.Dragged)
    setFrozen(player, true)
    slotOwner[slot] = player
    drag = { player = player, slot = slot, startedAt = os.clock() }
    GuardianAI.BeginDrag(slot.Position)
    print("[Kidnap] " .. player.Name .. " foi pego e está sendo arrastado")
end

local function onCaught(player: Player)
    if drag ~= nil or PlayerState.Get(player) ~= Location.Cave then
        return
    end

    local others = 0
    for _, other in ipairs(PlayerState.GetPlayersIn(Location.Cave)) do
        if other ~= player then
            others += 1
        end
    end

    if others == 0 then
        -- Ninguém livre para resgatar: o capturado e todos os presos voltam ao lobby sem mochila
        print("[Kidnap] Último jogador livre foi pego. Todos voltam ao lobby.")
        for _, captive in ipairs(PlayerState.GetPlayersIn(Location.Captive)) do
            ExpeditionSystem.ReturnToLobby(captive, false)
        end
        ExpeditionSystem.ReturnToLobby(player, false)
        return
    end

    local slot = freeSlot()
    if not slot then
        warn("[Kidnap] Nenhuma vaga livre no Ninho; devolvendo ao lobby.")
        ExpeditionSystem.ReturnToLobby(player, false)
        return
    end
    startDrag(player, slot)
end

-- Usado só pelos comandos de QA: sequestra mesmo sem outro jogador livre.
function KidnapSystem.QAForce(player: Player)
    if drag ~= nil or PlayerState.Get(player) ~= Location.Cave then
        return
    end
    local slot = freeSlot()
    if slot then
        startDrag(player, slot)
    end
end

function KidnapSystem.Init()
    GuardianAI.PlayerCaught:Connect(onCaught)

    -- Sempre que alguém deixa os estados de preso, descongela e libera a vaga
    PlayerState.Changed:Connect(function(player: Player, location: string)
        if location ~= Location.Dragged and location ~= Location.Captive then
            releaseSlot(player)
            if frozen[player] then
                setFrozen(player, false)
            end
        end
    end)

    Players.PlayerRemoving:Connect(function(player)
        releaseSlot(player)
        frozen[player] = nil
    end)

    RunService.Heartbeat:Connect(function()
        local current = drag
        if not current then
            return
        end
        local player = current.player
        if player.Parent ~= Players or PlayerState.Get(player) ~= Location.Dragged then
            releaseSlot(player)
            drag = nil
            GuardianAI.EndDrag()
            return
        end

        local guardianRoot = GuardianAI.GetRoot()
        local character = player.Character
        if not guardianRoot or not character then
            return
        end
        character:PivotTo(guardianRoot.CFrame * CFrame.new(0, 0, -4))

        local arrived = (guardianRoot.Position - current.slot.Position).Magnitude < 8
        if arrived or os.clock() - current.startedAt >= Config.DragMaxTime then
            finishDrag(player, current.slot)
        end
    end)
end

return KidnapSystem
