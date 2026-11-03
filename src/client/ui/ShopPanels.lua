--!strict
-- Telas de Mercado, Oficina, Contratos, Mercado Negro e Perfil, no tema do jogo. Só mostram o estado recebido do servidor
-- (perfil e pedidos) e fazem os mesmos pedidos de antes pelos mesmos remotes: o servidor decide e confere a distância da bancada.
-- Pelo botão do HUD dá para ver tudo de longe; vender, comprar e receber só funciona junto da bancada na vila.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local Theme = require((script.Parent :: Instance):WaitForChild("Theme") :: ModuleScript)
local Widgets = require((script.Parent :: Instance):WaitForChild("Widgets") :: ModuleScript)
local PanelManager = require((script.Parent :: Instance):WaitForChild("PanelManager") :: ModuleScript)
local ItemInfo = require((script.Parent :: Instance):WaitForChild("ItemInfo") :: ModuleScript)
local LobbyHUD = require((script.Parent :: Instance):WaitForChild("LobbyHUD") :: ModuleScript)
local ProfileHUD = require((script.Parent :: Instance):WaitForChild("ProfileHUD") :: ModuleScript)

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("EcosRemotes")
local OpenShop = Remotes:WaitForChild("OpenShop") :: RemoteEvent
local SellItem = Remotes:WaitForChild("SellItem") :: RemoteEvent
local BuyUpgrade = Remotes:WaitForChild("BuyUpgrade") :: RemoteEvent
local DisplayRelic = Remotes:WaitForChild("DisplayRelic") :: RemoteEvent
local RetrieveRelic = Remotes:WaitForChild("RetrieveRelic") :: RemoteEvent
local ClaimContract = Remotes:WaitForChild("ClaimContract") :: RemoteEvent
local OrdersUpdate = Remotes:WaitForChild("OrdersUpdate") :: RemoteEvent
local FulfillOrder = Remotes:WaitForChild("FulfillOrder") :: RemoteEvent

local C = Theme.Color

local ShopPanels = {}

type Profile = {
    money: number,
    stash: { any },
    upgrades: { [string]: boolean },
    relicDisplay: { any }?,
    contracts: { [string]: any }?,
}

-- Bancada de cada loja, para saber se o jogador está perto o bastante para negociar
local BENCH: { [string]: string } = {
    market = "LobbyMarket",
    workshop = "LobbyWorkshop",
    contracts = "LobbyBoard",
    blackmarket = "BlackMarketStall",
}
local BENCH_NAME: { [string]: string } = {
    market = "o Mercado",
    workshop = "a Oficina",
    contracts = "o Quadro de Contratos",
    blackmarket = "a barraca escondida",
}
local UPGRADE_TEXT: { [string]: string } = {
    Boots = "Passos bem mais silenciosos na caverna.",
    Hook = "Lance o gancho (tecla Q) para alcançar saliências altas.",
}

local panels: { [string]: PanelManager.Panel } = {}
local selected: { [string]: string? } = {}
local lastOrders: { any } = {}
local lastMoney = 0
local pendingConfirm: string? = nil
local workshopTab = "Melhorias"

local function currentProfile(): Profile?
    return ProfileHUD.GetProfile() :: Profile?
end

local function isNear(shop: string): boolean
    local bench = workspace:FindFirstChild(BENCH[shop])
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if bench and bench:IsA("BasePart") and root and root:IsA("BasePart") then
        return (root.Position - bench.Position).Magnitude <= Config.MarketRadius
    end
    return false
end

local function refresh(shop: string)
    local panel = panels[shop]
    if panel then
        panel.Refresh()
    end
end

-- Texto flutuante ("+80 💎") sobe e some, para dar sensação de recompensa
local function floatText(parent: Instance, text: string)
    local label = Widgets.Label(parent, {
        text = text,
        size = UDim2.new(0, 160, 0, 30),
        position = UDim2.new(1, -190, 0, 10),
        font = Theme.Font.Strong,
        textSize = Theme.TextSize.Heading,
        color = C.Gold,
        alignX = Enum.TextXAlignment.Right,
    })
    label.ZIndex = 10
    TweenService:Create(label, TweenInfo.new(1.2), { Position = UDim2.new(1, -190, 0, -30), TextTransparency = 1 }):Play()
    task.delay(1.3, function()
        label:Destroy()
    end)
end

local function banner(content: Frame, shop: string)
    if isNear(shop) then
        return
    end
    local label = Widgets.Label(content, {
        text = "Você está longe: vá até " .. BENCH_NAME[shop] .. ", na vila, para negociar.",
        size = UDim2.new(1, 0, 0, 26),
        color = C.Gold,
        font = Theme.Font.Strong,
        textSize = Theme.TextSize.Small,
    })
    label.BackgroundTransparency = 0.6
    label.BackgroundColor3 = C.Danger
    Widgets.AddCorner(label, UDim.new(0, 6))
end

local function setEnabled(button: TextButton, enabled: boolean)
    button.Active = enabled
    button.BackgroundTransparency = if enabled then 0 else 0.55
    button.TextTransparency = if enabled then 0 else 0.4
end

local function newRow(parent: Instance, height: number): Frame
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -8, 0, height)
    row.BackgroundColor3 = C.PanelDark
    row.Parent = parent
    Widgets.AddCorner(row, UDim.new(0, 8))
    Widgets.AddStroke(row, C.Line, 1)
    return row
end

local function newList(parent: Instance, top: number): ScrollingFrame
    local list = Instance.new("ScrollingFrame")
    list.BackgroundTransparency = 1
    list.BorderSizePixel = 0
    list.Position = UDim2.new(0, 0, 0, top)
    list.Size = UDim2.new(1, 0, 1, -top)
    list.ScrollBarThickness = 6
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.CanvasSize = UDim2.new()
    list.Parent = parent
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = list
    return list
end

local function rowButton(row: Frame, text: string, variant: string, enabled: boolean, onClick: () -> ()): TextButton
    local button = Widgets.Button(row, {
        text = text,
        variant = variant,
        size = UDim2.new(0, 130, 0, 38),
        position = UDim2.new(1, -140, 0.5, -19),
        onClick = onClick,
    })
    setEnabled(button, enabled)
    return button
end

-- Carta de item para as grades (mercado, relíquias); tocar escolhe o item
local function itemCard(parent: Instance, item: any, shop: string, isSelected: boolean)
    local card = Widgets.Card(parent, UDim2.new(), item.rarity)
    local stroke = card:FindFirstChildOfClass("UIStroke")
    if stroke then
        stroke.Thickness = if isSelected then 4 else 2
    end
    if isSelected then
        card.BackgroundColor3 = C.Wood
    end
    Widgets.Label(card, { text = ItemInfo.Emoji(item.type), size = UDim2.new(1, 0, 0.5, 0), position = UDim2.new(0, 0, 0, 4), textSize = 32, alignX = Enum.TextXAlignment.Center })
    Widgets.Label(card, {
        text = ItemInfo.Name(item.type, item.rarity),
        size = UDim2.new(1, -8, 0, 18),
        position = UDim2.new(0, 4, 0.5, 0),
        font = Theme.Font.Strong,
        textSize = Theme.TextSize.Small,
        color = Theme.ForRarity(item.rarity),
        alignX = Enum.TextXAlignment.Center,
    })
    Widgets.Label(card, {
        text = string.format("%d 💎", item.value),
        size = UDim2.new(1, -8, 0, 18),
        position = UDim2.new(0, 4, 0.5, 18),
        textSize = Theme.TextSize.Small,
        alignX = Enum.TextXAlignment.Center,
    })
    local tap = Instance.new("TextButton")
    tap.BackgroundTransparency = 1
    tap.Text = ""
    tap.Size = UDim2.fromScale(1, 1)
    tap.Parent = card
    tap.Activated:Connect(function()
        selected[shop] = item.id
        pendingConfirm = nil
        refresh(shop)
    end)
end

local function itemGrid(parent: Instance, items: { any }, shop: string, width: UDim): ScrollingFrame
    local list = Instance.new("ScrollingFrame")
    list.BackgroundTransparency = 1
    list.BorderSizePixel = 0
    list.Position = UDim2.new(0, 0, 0, 34)
    list.Size = UDim2.new(width.Scale, width.Offset, 1, -34)
    list.ScrollBarThickness = 6
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.CanvasSize = UDim2.new()
    list.Parent = parent
    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.new(0, 112, 0, 96)
    grid.CellPadding = UDim2.new(0, 8, 0, 8)
    grid.Parent = list
    for _, item in ipairs(items) do
        itemCard(list, item, shop, item.id == selected[shop])
    end
    return list
end

-- Coluna do detalhe à direita das grades
local function detailColumn(parent: Instance): Frame
    local column = Instance.new("Frame")
    column.BackgroundColor3 = C.PanelDark
    column.Position = UDim2.new(0.66, 8, 0, 34)
    column.Size = UDim2.new(0.34, -8, 1, -34)
    column.Parent = parent
    Widgets.AddCorner(column, UDim.new(0, 10))
    Widgets.AddStroke(column, C.Line, 1)
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.Parent = column
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = column
    return column
end

local function findItem(items: { any }, id: string?): any?
    if not id then
        return nil
    end
    for _, item in ipairs(items) do
        if item.id == id then
            return item
        end
    end
    return nil
end

-- Vende todos os itens iguais ao escolhido, um por vez (o servidor limita 5 pedidos por segundo)
local function sellAll(items: { any })
    task.spawn(function()
        for _, item in ipairs(items) do
            SellItem:FireServer(item.id)
            task.wait(0.25)
        end
    end)
end

local function renderMarket(content: Frame, profile: Profile)
    banner(content, "market")
    local offset = if isNear("market") then 0 else 32
    local area = Instance.new("Frame")
    area.BackgroundTransparency = 1
    area.Position = UDim2.new(0, 0, 0, offset)
    area.Size = UDim2.new(1, 0, 1, -offset)
    area.Parent = content
    Widgets.Label(area, {
        text = string.format("Venda segura: a loja paga %d%% do valor. Suas moedas: %d 💎", math.floor(Config.LobbyMarketRate * 100), profile.money),
        size = UDim2.new(1, 0, 0, 26),
        color = C.TextDim,
    })
    local items: { any } = {}
    for _, item in ipairs(profile.stash) do
        table.insert(items, item)
    end
    table.sort(items, function(a: any, b: any)
        return a.value > b.value
    end)
    if #items == 0 then
        Widgets.Label(area, { text = "Seu baú está vazio. Extraia itens da caverna!", position = UDim2.new(0, 0, 0, 50), size = UDim2.new(1, 0, 0, 30), color = C.Parchment })
        return
    end
    itemGrid(area, items, "market", UDim.new(0.66, 0))
    local chosen = findItem(items, selected.market)
    local column = detailColumn(area)
    if not chosen then
        Widgets.Label(column, { text = "Escolha um item para vender.", size = UDim2.new(1, 0, 0, 40), wrapped = true, color = C.TextDim })
        return
    end
    Widgets.Label(column, {
        text = ItemInfo.Name(chosen.type, chosen.rarity),
        size = UDim2.new(1, 0, 0, 28),
        font = Theme.Font.Title,
        textSize = Theme.TextSize.Heading,
        color = Theme.ForRarity(chosen.rarity),
    })
    Widgets.StatRow(column, "Valor", string.format("%d 💎", chosen.value))
    local price = math.floor(chosen.value * Config.LobbyMarketRate)
    Widgets.StatRow(column, "A loja paga", string.format("%d 💎", price), C.Gold)
    local near = isNear("market")
    local sell = Widgets.Button(column, { text = "Vender", variant = "primary", size = UDim2.new(1, 0, 0, 44), onClick = function()
        SellItem:FireServer(chosen.id)
        selected.market = nil
    end })
    setEnabled(sell, near)

    local same: { any } = {}
    local total = 0
    for _, item in ipairs(items) do
        if item.type == chosen.type and item.rarity == chosen.rarity then
            table.insert(same, item)
            total += math.floor(item.value * Config.LobbyMarketRate)
        end
    end
    if #same > 1 then
        local key = "sellall:" .. chosen.type .. chosen.rarity
        local confirming = pendingConfirm == key
        local all = Widgets.Button(column, {
            text = if confirming then string.format("Confirmar: %d itens por %d 💎", #same, total) else string.format("Vender todos (%d)", #same),
            variant = if confirming then "danger" else "normal",
            size = UDim2.new(1, 0, 0, 44),
            onClick = function()
                if pendingConfirm == key then
                    pendingConfirm = nil
                    selected.market = nil
                    sellAll(same)
                else
                    pendingConfirm = key
                    refresh("market")
                    task.delay(3, function()
                        if pendingConfirm == key then
                            pendingConfirm = nil
                            refresh("market")
                        end
                    end)
                end
            end,
        })
        setEnabled(all, near)
    end
end

local function renderWorkshopUpgrades(content: Frame, profile: Profile)
    local list = newList(content, 0)
    local ids: { string } = {}
    for id in pairs(Config.Upgrades) do
        table.insert(ids, id)
    end
    table.sort(ids, function(a: string, b: string)
        return Config.Upgrades[a].price < Config.Upgrades[b].price
    end)
    local near = isNear("workshop")
    for _, id in ipairs(ids) do
        local definition = Config.Upgrades[id]
        local owned = profile.upgrades[id] == true
        local row = newRow(list, 86)
        Widgets.Label(row, { text = definition.name, position = UDim2.new(0, 14, 0, 8), size = UDim2.new(1, -170, 0, 26), font = Theme.Font.Strong, textSize = Theme.TextSize.Heading, color = C.Gold })
        Widgets.Label(row, { text = UPGRADE_TEXT[id] or "", position = UDim2.new(0, 14, 0, 34), size = UDim2.new(1, -170, 0, 20), color = C.TextDim, textSize = Theme.TextSize.Small })
        if owned then
            rowButton(row, "Comprado", "normal", false, function() end)
        else
            local bar = Widgets.ProgressBar(row, UDim2.new(1, -170, 0, 16))
            bar.frame.Position = UDim2.new(0, 14, 0, 60)
            bar.Set(profile.money / definition.price, if profile.money >= definition.price then string.format("%d 💎", definition.price) else string.format("Faltam %d 💎", definition.price - profile.money))
            rowButton(row, string.format("Comprar · %d", definition.price), "primary", near and profile.money >= definition.price, function()
                BuyUpgrade:FireServer(id)
            end)
        end
    end
end

local function renderWorkshopRelics(content: Frame, profile: Profile)
    local near = isNear("workshop")
    local list = newList(content, 0)
    local shown = profile.relicDisplay or {}
    local hasAny = false
    for _, item in ipairs(shown) do
        hasAny = true
        local row = newRow(list, 60)
        Widgets.Label(row, { text = "🏺 Exposta · " .. ItemInfo.Name(item.type, item.rarity), position = UDim2.new(0, 14, 0, 0), size = UDim2.new(1, -170, 1, 0), font = Theme.Font.Strong, color = Theme.ForRarity(item.rarity) })
        rowButton(row, "Retirar", "normal", near, function()
            RetrieveRelic:FireServer(item.id)
        end)
    end
    for _, item in ipairs(profile.stash) do
        if item.type == "Relic" then
            hasAny = true
            local row = newRow(list, 60)
            Widgets.Label(row, { text = "🏺 No baú · " .. ItemInfo.Name(item.type, item.rarity) .. string.format(" · %d 💎", item.value), position = UDim2.new(0, 14, 0, 0), size = UDim2.new(1, -170, 1, 0), font = Theme.Font.Strong, color = Theme.ForRarity(item.rarity) })
            rowButton(row, "Expor", "primary", near, function()
                DisplayRelic:FireServer(item.id)
            end)
        end
    end
    if not hasAny then
        Widgets.Label(list, { text = "Nenhuma Relíquia ainda. Elas ficam expostas na vitrine da oficina e não podem ser vendidas.", size = UDim2.new(1, 0, 0, 50), wrapped = true, color = C.TextDim })
    end
end

local function renderContracts(content: Frame, profile: Profile)
    banner(content, "contracts")
    local offset = if isNear("contracts") then 0 else 32
    local area = Instance.new("Frame")
    area.BackgroundTransparency = 1
    area.Position = UDim2.new(0, 0, 0, offset)
    area.Size = UDim2.new(1, 0, 1, -offset)
    area.Parent = content
    local list = newList(area, 0)
    local near = isNear("contracts")
    local contracts = profile.contracts or {}
    local shown = false
    for _, scope in ipairs({ { "daily", "Diário" }, { "weekly", "Semanal" } }) do
        local ids = contracts[scope[1]]
        if typeof(ids) == "table" then
            for _, id in ipairs(ids) do
                local definition = Config.ContractDefs[id]
                if definition then
                    shown = true
                    local progressTable = contracts[scope[1] .. "Progress"]
                    local claimedTable = contracts[scope[1] .. "Claimed"]
                    local progress = if typeof(progressTable) == "table" then (progressTable[id] or 0) else 0
                    local claimed = typeof(claimedTable) == "table" and claimedTable[id] == true
                    local row = newRow(list, 78)
                    Widgets.Label(row, { text = string.format("%s · %s", scope[2], definition.text), position = UDim2.new(0, 14, 0, 6), size = UDim2.new(1, -170, 0, 24), font = Theme.Font.Strong })
                    local bar = Widgets.ProgressBar(row, UDim2.new(1, -170, 0, 18))
                    bar.frame.Position = UDim2.new(0, 14, 0, 38)
                    bar.Set(progress / definition.goal, string.format("%d / %d · +%d 💎", math.min(progress, definition.goal), definition.goal, definition.reward))
                    if claimed then
                        rowButton(row, "Recebido", "normal", false, function() end)
                    else
                        rowButton(row, "Receber", "primary", near and progress >= definition.goal, function()
                            ClaimContract:FireServer(id)
                        end)
                    end
                end
            end
        end
    end
    if not shown then
        Widgets.Label(list, { text = "Sem contratos no momento.", size = UDim2.new(1, 0, 0, 30), color = C.TextDim })
    end
end

local function renderBlackMarket(content: Frame, profile: Profile)
    banner(content, "blackmarket")
    local offset = if isNear("blackmarket") then 0 else 32
    local area = Instance.new("Frame")
    area.BackgroundTransparency = 1
    area.Position = UDim2.new(0, 0, 0, offset)
    area.Size = UDim2.new(1, 0, 1, -offset)
    area.Parent = content
    local list = newList(area, 0)
    local near = isNear("blackmarket")
    if #lastOrders == 0 then
        Widgets.Label(list, { text = "Sem pedidos no momento. Volte mais tarde.", size = UDim2.new(1, 0, 0, 30), color = C.TextDim })
    end
    for _, order in ipairs(lastOrders) do
        local have = 0
        for _, item in ipairs(profile.stash) do
            if item.type == order.itemType and (order.rarity == nil or item.rarity == order.rarity) then
                have += 1
            end
        end
        local row = newRow(list, 70)
        row.BackgroundColor3 = Color3.fromRGB(20, 14, 18)
        Widgets.Label(row, { text = string.format("%dx %s", order.quantity, order.label), position = UDim2.new(0, 14, 0, 8), size = UDim2.new(1, -170, 0, 26), font = Theme.Font.Strong, textSize = Theme.TextSize.Heading })
        Widgets.Label(row, {
            text = string.format("Paga %d%% do valor · você tem %d", math.floor(order.priceRate * 100 + 0.5), have),
            position = UDim2.new(0, 14, 0, 38),
            size = UDim2.new(1, -170, 0, 22),
            color = C.TextDim,
            textSize = Theme.TextSize.Small,
        })
        if order.done then
            rowButton(row, "Entregue", "normal", false, function() end)
        else
            rowButton(row, "Entregar", "primary", near and have >= order.quantity, function()
                FulfillOrder:FireServer(order.id)
            end)
        end
    end
end

local function renderProfile(content: Frame, profile: Profile)
    local column = Instance.new("Frame")
    column.BackgroundTransparency = 1
    column.Size = UDim2.new(1, 0, 1, 0)
    column.Parent = content
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = column
    Widgets.Label(column, { text = player.DisplayName, size = UDim2.new(1, 0, 0, 36), font = Theme.Font.Title, textSize = Theme.TextSize.Title, color = C.Gold })
    Widgets.StatRow(column, "Moedas", string.format("%d 💎", profile.money), C.Gold)
    local relics = 0
    local totalValue = 0
    for _, item in ipairs(profile.stash) do
        totalValue += item.value
        if item.type == "Relic" then
            relics += 1
        end
    end
    Widgets.StatRow(column, "Itens no baú", string.format("%d (limite %d)", #profile.stash, Config.StashMaxItems))
    Widgets.StatRow(column, "Valor do baú", string.format("%d 💎", totalValue))
    Widgets.StatRow(column, "Relíquias guardadas", tostring(relics + #(profile.relicDisplay or {})))
    local owned: { string } = {}
    for id, definition in pairs(Config.Upgrades) do
        if profile.upgrades[id] == true then
            table.insert(owned, definition.name)
        end
    end
    table.sort(owned)
    Widgets.StatRow(column, "Melhorias", if #owned > 0 then table.concat(owned, ", ") else "nenhuma ainda")
end

local RENDERERS: { [string]: (Frame, Profile) -> () } = {
    market = renderMarket,
    contracts = renderContracts,
    blackmarket = renderBlackMarket,
    profile = renderProfile,
}

local function makePanel(shop: string, title: string)
    local tabs: { string }? = if shop == "workshop" then { "Melhorias", "Relíquias" } else nil
    panels[shop] = PanelManager.Create("shop_" .. shop, {
        title = title,
        tabs = tabs,
        onTab = function(name: string, content: Frame)
            local profile = currentProfile()
            if not profile then
                Widgets.Label(content, { text = "Carregando...", size = UDim2.new(1, 0, 0, 30) })
                return
            end
            if shop == "workshop" then
                workshopTab = if name == "" then workshopTab else name
                if workshopTab == "Relíquias" then
                    renderWorkshopRelics(content, profile)
                else
                    renderWorkshopUpgrades(content, profile)
                end
            else
                RENDERERS[shop](content, profile)
            end
        end,
        onClose = function()
            pendingConfirm = nil
        end,
    })
end

local function open(shop: string)
    local panel = panels[shop]
    if panel then
        pendingConfirm = nil
        panel.Open()
    end
end

function ShopPanels.Init()
    makePanel("market", "Mercado")
    makePanel("workshop", "Oficina")
    makePanel("contracts", "Quadro de Contratos")
    makePanel("blackmarket", "Mercado Negro")
    makePanel("profile", "Perfil")

    LobbyHUD.Register("market", function()
        open("market")
    end)
    LobbyHUD.Register("workshop", function()
        open("workshop")
    end)
    LobbyHUD.Register("contracts", function()
        open("contracts")
    end)
    LobbyHUD.Register("profile", function()
        open("profile")
    end)

    -- A bancada física pede a loja pelo OpenShop, como antes
    OpenShop.OnClientEvent:Connect(function(shop: unknown)
        if shop == "market" or shop == "workshop" or shop == "contracts" or shop == "blackmarket" then
            open(shop :: string)
        end
    end)

    local lastProfile = currentProfile()
    lastMoney = if lastProfile then lastProfile.money else 0
    ProfileHUD.OnChanged(function()
        local profile = currentProfile()
        if profile then
            if profile.money > lastMoney then
                for _, shop in ipairs({ "market", "contracts", "blackmarket" }) do
                    local panel = panels[shop]
                    if panel and panel.IsOpen() then
                        floatText(panel.Content, string.format("+%d 💎", profile.money - lastMoney))
                    end
                end
            end
            lastMoney = profile.money
        end
        for shop in pairs(panels) do
            refresh(shop)
        end
    end)
    OrdersUpdate.OnClientEvent:Connect(function(orders: unknown)
        if typeof(orders) == "table" then
            lastOrders = orders :: { any }
            refresh("blackmarket")
        end
    end)
end

return ShopPanels
