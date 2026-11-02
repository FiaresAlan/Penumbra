--!strict
-- Mercado Negro (floresta): pedidos de NPCs com preço de 100% a 150%. Sem PvP nesta fase.
-- Os pedidos ficam só em memória, por servidor, e giram a cada Config.BlackMarketRotation segundos.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local systems = script.Parent :: Instance
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config") :: ModuleScript)
local Enums = require(Shared:WaitForChild("Enums") :: ModuleScript)
local BlackMarketRules = require(Shared:WaitForChild("BlackMarketRules") :: ModuleScript)
local PlayerState = require(systems:WaitForChild("PlayerState") :: ModuleScript)
local PlayerProfile = require(systems:WaitForChild("PlayerProfile") :: ModuleScript)
local RateLimiter = require(systems:WaitForChild("RateLimiter") :: ModuleScript)

local Remotes = ReplicatedStorage:WaitForChild("EcosRemotes")
local OpenShop = Remotes:WaitForChild("OpenShop") :: RemoteEvent
local OrdersUpdate = Remotes:WaitForChild("OrdersUpdate") :: RemoteEvent
local FulfillOrder = Remotes:WaitForChild("FulfillOrder") :: RemoteEvent

local BlackMarketSystem = {}

local rng = Random.new()
local orders: { BlackMarketRules.Order } = {}
local fulfilled: { [string]: boolean } = {}

local function describe(order: BlackMarketRules.Order): string
    return string.format("%dx %s — %d%%", order.quantity, order.label, math.floor(order.priceRate * 100 + 0.5))
end

-- Atualiza o painel do lobby (perto do elevador) e avisa os clientes
local function publish()
    local view: { { [string]: any } } = {}
    local lines: { string } = {}
    for _, order in ipairs(orders) do
        table.insert(view, {
            id = order.id,
            label = order.label,
            itemType = order.itemType,
            rarity = order.rarity,
            quantity = order.quantity,
            priceRate = order.priceRate,
            done = fulfilled[order.id] == true,
        })
        table.insert(lines, (if fulfilled[order.id] then "✔ " else "") .. describe(order))
    end
    OrdersUpdate:FireAllClients(view)

    local board = workspace:FindFirstChild("OrdersBoard")
    local gui = board and board:FindFirstChild("OrdersGui")
    local label = gui and gui:FindFirstChild("Orders")
    if label and label:IsA("TextLabel") then
        label.Text = "PEDIDOS\n" .. table.concat(lines, "\n")
    end
end

function BlackMarketSystem.Rotate()
    orders = BlackMarketRules.Generate(rng, 3)
    fulfilled = {}
    publish()
    print("[BlackMarket] pedidos girados: " .. #orders)
end

local function nearStall(player: Player): boolean
    local stall = workspace:FindFirstChild("BlackMarketStall")
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not stall or not stall:IsA("BasePart") or not root or not root:IsA("BasePart") then
        return false
    end
    return (root.Position - stall.Position).Magnitude <= Config.MarketRadius
end

function BlackMarketSystem.Init()
    BlackMarketSystem.Rotate()

    local stall = workspace:FindFirstChild("BlackMarketStall")
    if stall and stall:IsA("BasePart") then
        local prompt = Instance.new("ProximityPrompt")
        prompt.ActionText = "Negociar"
        prompt.ObjectText = "Mercado Negro"
        prompt.HoldDuration = 0.3
        prompt.MaxActivationDistance = 12
        prompt.RequiresLineOfSight = false
        prompt.Parent = stall
        prompt.Triggered:Connect(function(player)
            if PlayerState.Get(player) == Enums.PlayerLocation.Lobby then
                OpenShop:FireClient(player, "blackmarket")
            end
        end)
    else
        warn("[BlackMarket] BlackMarketStall não encontrado.")
    end

    -- Quem entra recebe os pedidos atuais
    Players.PlayerAdded:Connect(function(player)
        task.delay(3, function()
            if player.Parent == Players then
                publish()
            end
        end)
    end)

    FulfillOrder.OnServerEvent:Connect(function(player, orderId: unknown)
        if not RateLimiter.Allow(player, "FulfillOrder", 2, 3) then
            return
        end
        if typeof(orderId) ~= "string" or #(orderId :: string) > 32 then
            return
        end
        if PlayerState.Get(player) ~= Enums.PlayerLocation.Lobby or not nearStall(player) then
            return
        end
        if fulfilled[orderId :: string] then
            return
        end
        local profile = PlayerProfile.Get(player)
        if not profile then
            return
        end

        for _, order in ipairs(orders) do
            if order.id == orderId then
                local items = BlackMarketRules.PickItems(order, profile.stash)
                if not items then
                    return -- faltam itens: nada é removido
                end
                local payout = BlackMarketRules.Payout(order, items)
                -- Marca o pedido, remove todos os itens e só então paga
                fulfilled[order.id] = true
                for _, item in ipairs(items) do
                    PlayerProfile.RemoveStashItem(player, item.id)
                end
                PlayerProfile.AddMoney(player, payout)
                print(string.format("[BlackMarket] %s entregou %s e recebeu %d", player.Name, describe(order), payout))
                publish()
                return
            end
        end
    end)

    task.spawn(function()
        while true do
            task.wait(Config.BlackMarketRotation)
            BlackMarketSystem.Rotate()
        end
    end)
end

return BlackMarketSystem
