--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local systems = script.Parent :: Instance
local Enums = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums") :: ModuleScript)
local ExpeditionSystem = require(systems:WaitForChild("ExpeditionSystem") :: ModuleScript)
local ExtractionSystem = require(systems:WaitForChild("ExtractionSystem") :: ModuleScript)
local LootSystem = require(systems:WaitForChild("LootSystem") :: ModuleScript)
local GuardianAI = require(systems:WaitForChild("GuardianAI") :: ModuleScript)
local KidnapSystem = require(systems:WaitForChild("KidnapSystem") :: ModuleScript)
local GuardianDirector = require(systems:WaitForChild("GuardianDirector") :: ModuleScript)
local PlayerProfile = require(systems:WaitForChild("PlayerProfile") :: ModuleScript)
local ContractSystem = require(systems:WaitForChild("ContractSystem") :: ModuleScript)
local BlackMarketSystem = require(systems:WaitForChild("BlackMarketSystem") :: ModuleScript)
local HighlightsSystem = require(systems:WaitForChild("HighlightsSystem") :: ModuleScript)
local MovementGuard = require(systems:WaitForChild("MovementGuard") :: ModuleScript)
local NestSystem = require(systems:WaitForChild("NestSystem") :: ModuleScript)
local PlayerState = require(systems:WaitForChild("PlayerState") :: ModuleScript)

local QACommands = {}

-- Leva o jogador até uma bancada do lobby e abre a tela correspondente.
local function goNear(player: Player, partName: string, shop: string)
    local part = workspace:FindFirstChild(partName)
    local character = player.Character
    local openShop = ReplicatedStorage:WaitForChild("EcosRemotes"):WaitForChild("OpenShop") :: RemoteEvent
    if part and part:IsA("BasePart") and character and PlayerState.Get(player) == Enums.PlayerLocation.Lobby then
        character:PivotTo(CFrame.new(part.Position + Vector3.new(8, 2, 0)))
        openShop:FireClient(player, shop)
    end
end

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
    GiveRelic = function(player)
        LootSystem.GrantItem(player, "Relic", Enums.CoreRarity.Legendary, "C")
    end,
    GoToCaveElevator = function(player)
        local elevator = workspace:FindFirstChild("Elevator")
        local character = player.Character
        if elevator and elevator:IsA("BasePart") and character then
            MovementGuard.Exempt(player, 3)
            character:PivotTo(CFrame.new(elevator.Position + Vector3.new(-9, 4 - elevator.Size.Y / 2, 0)))
        end
    end,
    CallCaveElevator = function(player)
        ExtractionSystem.QACall(player)
    end,
    ForceKidnap = function(player)
        KidnapSystem.QAForce(player)
    end,
    HurryCaptive = function(_player)
        NestSystem.QAHurry(5)
    end,
    ReleaseCaptive = function(player)
        if PlayerState.Get(player) == Enums.PlayerLocation.Captive then
            KidnapSystem.Release(player)
        end
    end,
    NextBlind = function(_player)
        GuardianDirector.ForceNext(Enums.GuardianVariant.Blind)
    end,
    NextDeceiver = function(_player)
        GuardianDirector.ForceNext(Enums.GuardianVariant.Deceiver)
    end,
    TouchFake = function(player)
        LootSystem.QATriggerNearestFake(player)
    end,
    GiveMoney = function(player)
        PlayerProfile.AddMoney(player, 100)
    end,
    ResetProfile = function(player)
        PlayerProfile.QAReset(player)
    end,
    RefreshWall = function(_player)
        HighlightsSystem.Flush()
    end,
    GoToWall = function(player)
        local wall = workspace:FindFirstChild("HighlightsWall")
        local character = player.Character
        if wall and wall:IsA("BasePart") and character and PlayerState.Get(player) == Enums.PlayerLocation.Lobby then
            character:PivotTo(CFrame.lookAt(wall.Position + Vector3.new(-14, -3, 0), wall.Position + Vector3.new(0, -3, 0)))
        end
    end,
    RotateOrders = function(_player)
        BlackMarketSystem.Rotate()
    end,
    OpenBlackMarket = function(player)
        goNear(player, "BlackMarketStall", "blackmarket")
    end,
    NextDay = function(player)
        ContractSystem.QAAdvanceDay()
        ContractSystem.Open(player)
    end,
    OpenContracts = function(player)
        goNear(player, "LobbyBoard", "contracts")
    end,
    GiveItemsQA = function(player)
        -- Simula uma extração: 5 itens, 1 relíquia, depois do minuto 8
        ExpeditionSystem.SetElapsedForQA(500)
        local receipt = { items = {
            { type = "Core", rarity = "Common", value = 10 }, { type = "Core", rarity = "Common", value = 10 },
            { type = "Core", rarity = "Rare", value = 50 }, { type = "Core", rarity = "Rare", value = 50 },
            { type = "Relic", rarity = "Legendary", value = 500 },
        }, total = 620, multiplier = 1 }
        ExtractionSystem.QAFireExtracted(player, receipt)
    end,
    GiveHook = function(player)
        PlayerProfile.SetUpgrade(player, "Hook")
    end,
    NearHook = function(player)
        local folder = workspace:FindFirstChild("HookPoints")
        local point = folder and folder:FindFirstChild("Hook1")
        local character = player.Character
        if point and point:IsA("BasePart") and character and PlayerState.Get(player) == Enums.PlayerLocation.Cave then
            MovementGuard.Exempt(player, 3)
            character:PivotTo(CFrame.new(point.Position.X, 4, point.Position.Z + 8))
        end
    end,
    FillStash = function(player)
        PlayerProfile.AddStashItems(player, {
            { type = "Core", rarity = "Common", value = 10 },
            { type = "Core", rarity = "Rare", value = 50 },
            { type = "Relic", rarity = "Legendary", value = 500 },
        })
    end,
    OpenMarket = function(player)
        goNear(player, "LobbyMarket", "market")
    end,
    OpenWorkshop = function(player)
        goNear(player, "LobbyWorkshop", "workshop")
    end,
    NextMimic = function(_player)
        GuardianDirector.ForceNext(Enums.GuardianVariant.Mimic)
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
