--!strict
-- Contratos diários e semanais. O progresso vem só de eventos do servidor; o cliente nunca informa progresso.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local systems = script.Parent :: Instance
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config") :: ModuleScript)
local Enums = require(Shared:WaitForChild("Enums") :: ModuleScript)
local ContractRules = require(Shared:WaitForChild("ContractRules") :: ModuleScript)
local PlayerState = require(systems:WaitForChild("PlayerState") :: ModuleScript)
local PlayerProfile = require(systems:WaitForChild("PlayerProfile") :: ModuleScript)
local ExpeditionSystem = require(systems:WaitForChild("ExpeditionSystem") :: ModuleScript)
local ExtractionSystem = require(systems:WaitForChild("ExtractionSystem") :: ModuleScript)
local NestSystem = require(systems:WaitForChild("NestSystem") :: ModuleScript)
local RateLimiter = require(systems:WaitForChild("RateLimiter") :: ModuleScript)

local Remotes = ReplicatedStorage:WaitForChild("EcosRemotes")
local OpenShop = Remotes:WaitForChild("OpenShop") :: RemoteEvent
local ClaimContract = Remotes:WaitForChild("ClaimContract") :: RemoteEvent

local ContractSystem = {}

local dayOffset = 0 -- só o QA mexe nisso, para simular a virada do dia

local function now(): number
    return os.time() + dayOffset * 86400
end

-- Garante que o perfil tem os contratos do dia e da semana atuais; zera o progresso na virada.
local function ensure(player: Player): { [string]: any }?
    local profile = PlayerProfile.Get(player)
    if not profile then
        return nil
    end
    local contracts = profile.contracts
    local dayKey = ContractRules.DayKey(now())
    local weekKey = ContractRules.WeekKey(now())
    local changed = false

    if contracts.dayKey ~= dayKey then
        contracts.dayKey = dayKey
        contracts.daily = ContractRules.Pick(dayKey, Config.DailyPool, 3)
        contracts.dailyProgress = {}
        contracts.dailyClaimed = {}
        changed = true
    end
    if contracts.weekKey ~= weekKey then
        contracts.weekKey = weekKey
        contracts.weekly = ContractRules.Pick(weekKey, Config.WeeklyPool, 1)
        contracts.weeklyProgress = {}
        contracts.weeklyClaimed = {}
        changed = true
    end
    if changed then
        PlayerProfile.Refresh(player)
    end
    return contracts
end

local function advance(player: Player, kind: string, amount: number)
    if amount <= 0 then
        return
    end
    local contracts = ensure(player)
    if not contracts then
        return
    end
    for _, scope in ipairs({ "daily", "weekly" }) do
        for _, id in ipairs(contracts[scope]) do
            local definition = Config.ContractDefs[id]
            if definition and definition.kind == kind then
                local progress = contracts[scope .. "Progress"]
                progress[id] = math.min(definition.goal, (progress[id] or 0) + amount)
            end
        end
    end
    PlayerProfile.Refresh(player)
end

local function nearBoard(player: Player): boolean
    local board = workspace:FindFirstChild("LobbyBoard")
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not board or not board:IsA("BasePart") or not root or not root:IsA("BasePart") then
        return false
    end
    return (root.Position - board.Position).Magnitude <= Config.MarketRadius
end

-- Só o QA: faz o próximo acesso cair em outro dia.
function ContractSystem.QAAdvanceDay()
    dayOffset += 1
end

function ContractSystem.Open(player: Player)
    ensure(player)
    OpenShop:FireClient(player, "contracts")
end

function ContractSystem.Init()
    local board = workspace:FindFirstChild("LobbyBoard")
    if board and board:IsA("BasePart") then
        local prompt = Instance.new("ProximityPrompt")
        prompt.ActionText = "Ver contratos"
        prompt.ObjectText = "Quadro de Contratos"
        prompt.HoldDuration = 0.3
        prompt.MaxActivationDistance = 12
        prompt.RequiresLineOfSight = false
        prompt.Parent = board
        prompt.Triggered:Connect(function(player)
            if PlayerState.Get(player) == Enums.PlayerLocation.Lobby then
                ContractSystem.Open(player)
            end
        end)
    else
        warn("[Contracts] LobbyBoard não encontrado.")
    end

    -- Progresso só por eventos do servidor
    ExtractionSystem.Extracted:Connect(function(player: Player, receipt: any)
        local items = #receipt.items
        if items <= 0 then
            return
        end
        local relics = 0
        for _, item in ipairs(receipt.items) do
            if item.type == "Relic" then
                relics += 1
            end
        end
        advance(player, "items", items)
        advance(player, "relic", relics)
        if (receipt.elapsed or ExpeditionSystem.GetElapsedTime()) >= Config.LateMinute * 60 then
            advance(player, "late", 1)
        end
    end)
    NestSystem.PlayerRescued:Connect(function(rescuer: Player)
        advance(rescuer, "rescue", 1)
    end)

    ClaimContract.OnServerEvent:Connect(function(player, contractId: unknown)
        if not RateLimiter.Allow(player, "ClaimContract", 2, 3) then
            return
        end
        if typeof(contractId) ~= "string" or #(contractId :: string) > 32 then
            return
        end
        if PlayerState.Get(player) ~= Enums.PlayerLocation.Lobby or not nearBoard(player) then
            return
        end
        local contracts = ensure(player)
        local definition = Config.ContractDefs[contractId :: string]
        if not contracts or not definition then
            return
        end
        for _, scope in ipairs({ "daily", "weekly" }) do
            if table.find(contracts[scope], contractId) then
                local progress = contracts[scope .. "Progress"]
                local claimed = contracts[scope .. "Claimed"]
                if claimed[contractId] or (progress[contractId] or 0) < definition.goal then
                    return
                end
                -- Marca como recebido antes de pagar: nunca paga duas vezes
                claimed[contractId] = true
                PlayerProfile.AddMoney(player, definition.reward)
                print(string.format("[Contracts] %s recebeu %s (+%d)", player.Name, contractId :: string, definition.reward))
                return
            end
        end
    end)
end

return ContractSystem
