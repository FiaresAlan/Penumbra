--!strict
-- Mochila e Baú. A mochila mostra ESPAÇOS que representam o peso (cada Config.SlotWeight de peso é 1 espaço: 5 Núcleos,
-- ou 1 Relíquia de 3 espaços e 2 Núcleos). O baú é só consulta: vender continua sendo na loja da vila.
-- Só mostra estado recebido do servidor (HUDUpdate e ProfileUpdate) e nunca pede nada. Tecla I, ou o botão Mochila.
-- Na caverna aparece uma barrinha de espaços acima da barra de ruído; tocar nela também abre a tela.
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local Theme = require((script.Parent :: Instance):WaitForChild("Theme") :: ModuleScript)
local Widgets = require((script.Parent :: Instance):WaitForChild("Widgets") :: ModuleScript)
local PanelManager = require((script.Parent :: Instance):WaitForChild("PanelManager") :: ModuleScript)
local LobbyHUD = require((script.Parent :: Instance):WaitForChild("LobbyHUD") :: ModuleScript)
local ProfileHUD = require((script.Parent :: Instance):WaitForChild("ProfileHUD") :: ModuleScript)

local player = Players.LocalPlayer
local HUDUpdate = ReplicatedStorage:WaitForChild("EcosRemotes"):WaitForChild("HUDUpdate") :: RemoteEvent

local C = Theme.Color

local InventoryUI = {}

type BackpackItem = {
    id: string,
    type: string,
    rarity: string,
    depthZone: string?,
    baseValue: number,
    value: number,
    weight: number,
}

local backpack: { items: { BackpackItem }, weight: number, maxWeight: number, totalValue: number } = {
    items = {},
    weight = 0,
    maxWeight = Config.MaxCarryWeight,
    totalValue = 0,
}

local panel: PanelManager.Panel? = nil
local currentTab = "Mochila"
local chestFilter = "Todos"
local detailLabel: TextLabel? = nil
local barButton: TextButton? = nil
local barSquares: { Frame } = {}
local barText: TextLabel? = nil
local barScale: UIScale? = nil
local lastCount = 0

local function slotCount(): number
    return math.max(1, math.floor(backpack.maxWeight / Config.SlotWeight + 0.5))
end

local function slotsOf(weight: number): number
    return math.max(1, math.ceil(weight / Config.SlotWeight))
end

local RARITY_ADJECTIVE: { [string]: string } = { Common = "", Rare = " raro", Legendary = " lendário" }

local function itemName(itemType: string, rarity: string): string
    if itemType == "Relic" then
        return "Relíquia"
    elseif itemType == "DenseCore" then
        return "Núcleo denso"
    end
    return "Núcleo" .. (RARITY_ADJECTIVE[rarity] or "")
end

local function itemEmoji(itemType: string): string
    return if itemType == "Relic" then "🏺" elseif itemType == "DenseCore" then "🔷" else "💎"
end

local function describeBackpack(item: BackpackItem): string
    return string.format("%s · zona %s · base %d · agora %d · peso %d", itemName(item.type, item.rarity), item.depthZone or "?", item.baseValue, item.value, item.weight)
end

local function describeChest(item: { type: string, rarity: string, value: number }): string
    return string.format("%s · valor %d · a loja paga %d", itemName(item.type, item.rarity), item.value, math.floor(item.value * Config.LobbyMarketRate))
end

local function clear(frame: Instance)
    for _, child in ipairs(frame:GetChildren()) do
        child:Destroy()
    end
end

-- Carta de um item: emoji, nome e valor. Tocar ou passar o mouse mostra o detalhe.
local function itemCard(parent: Instance, size: UDim2, itemType: string, rarity: string, valueText: string, detail: string): Frame
    local card = Widgets.Card(parent, size, rarity)
    Widgets.Label(card, { text = itemEmoji(itemType), size = UDim2.new(1, 0, 0.5, 0), position = UDim2.new(0, 0, 0, 4), textSize = 34, alignX = Enum.TextXAlignment.Center })
    Widgets.Label(card, {
        text = itemName(itemType, rarity),
        size = UDim2.new(1, -8, 0, 20),
        position = UDim2.new(0, 4, 0.5, 0),
        font = Theme.Font.Strong,
        textSize = Theme.TextSize.Small,
        color = Theme.ForRarity(rarity),
        alignX = Enum.TextXAlignment.Center,
    })
    Widgets.Label(card, {
        text = valueText,
        size = UDim2.new(1, -8, 0, 20),
        position = UDim2.new(0, 4, 0.5, 20),
        textSize = Theme.TextSize.Small,
        alignX = Enum.TextXAlignment.Center,
    })
    local tap = Instance.new("TextButton")
    tap.BackgroundTransparency = 1
    tap.Text = ""
    tap.Size = UDim2.fromScale(1, 1)
    tap.Parent = card
    tap.Activated:Connect(function()
        local label = detailLabel
        if label then
            label.Text = detail
        end
    end)
    Widgets.Tooltip(card, function()
        return detail
    end)
    return card
end

local function drawBackpack(content: Frame)
    local total = slotCount()
    local row = Instance.new("Frame")
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, 0, 0, 130)
    row.Parent = content
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 8)
    layout.Parent = row

    -- Cada item ocupa slotsOf(peso) espaços; a largura é uma fração da linha para caber em telas pequenas
    local used = 0
    for _, item in ipairs(backpack.items) do
        local slots = math.min(slotsOf(item.weight), total - used)
        if slots <= 0 then
            break
        end
        used += slots
        local fraction = slots / total
        itemCard(row, UDim2.new(fraction, 8 * (fraction - 1), 1, 0), item.type, item.rarity, string.format("%d 💎", item.value), describeBackpack(item))
    end
    for _ = used + 1, total do
        local empty = Widgets.Card(row, UDim2.new(1 / total, 8 * (1 / total - 1), 1, 0), "Common")
        empty.BackgroundTransparency = 0.5
    end

    local weightBar = Widgets.ProgressBar(content, UDim2.new(1, 0, 0, 28))
    weightBar.frame.Position = UDim2.new(0, 0, 0, 144)
    weightBar.Set(backpack.weight / math.max(backpack.maxWeight, 1), string.format("Peso %d / %d", backpack.weight, backpack.maxWeight))

    local stats = Instance.new("Frame")
    stats.BackgroundTransparency = 1
    stats.Position = UDim2.new(0, 0, 0, 184)
    stats.Size = UDim2.new(1, 0, 0, 70)
    stats.Parent = content
    local statLayout = Instance.new("UIListLayout")
    statLayout.Padding = UDim.new(0, 6)
    statLayout.Parent = stats
    Widgets.StatRow(stats, "Valor na mochila", string.format("%d 💎", backpack.totalValue), C.Gold)
    local noise = math.floor(backpack.weight / math.max(backpack.maxWeight, 1) * Config.WeightNoiseMultiplier * 100 + 0.5)
    Widgets.StatRow(stats, "Barulho extra pelo peso", string.format("+%d%%", noise), if noise > 25 then C.Danger else C.Text)

    local detail = Widgets.Label(content, {
        text = "Toque em um item para ver os detalhes. Volte ao elevador para extrair.",
        position = UDim2.new(0, 0, 0, 266),
        size = UDim2.new(1, 0, 0, 44),
        color = C.Parchment,
        wrapped = true,
    })
    detailLabel = detail
end

local function drawChest(content: Frame)
    local profile = ProfileHUD.GetProfile() :: { money: number, stash: { any } }?
    local stash: { any } = if profile then profile.stash else {}

    local filtered: { any } = {}
    local totalValue = 0
    for _, item in ipairs(stash) do
        totalValue += item.value
        if chestFilter == "Todos" or (chestFilter == "Núcleos" and item.type ~= "Relic") or (chestFilter == "Relíquias" and item.type == "Relic") then
            table.insert(filtered, item)
        end
    end
    table.sort(filtered, function(a: any, b: any)
        return a.value > b.value
    end)

    local filters = Widgets.Tabs(content, { "Todos", "Núcleos", "Relíquias" }, function(name: string)
        chestFilter = name
        local active = panel
        if active and active.IsOpen() then
            active.SelectTab("Baú")
        end
    end, chestFilter)
    filters.frame.Name = "Filtros"
    Widgets.Label(content, {
        text = string.format("Baú: %d itens (limite %d) · valor total %d 💎", #stash, Config.StashMaxItems, totalValue),
        position = UDim2.new(0, 0, 0, 50),
        size = UDim2.new(1, 0, 0, 24),
        color = C.TextDim,
    })

    local list = Instance.new("ScrollingFrame")
    list.BackgroundTransparency = 1
    list.BorderSizePixel = 0
    list.Position = UDim2.new(0, 0, 0, 80)
    list.Size = UDim2.new(1, 0, 1, -80)
    list.ScrollBarThickness = 6
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.CanvasSize = UDim2.new()
    list.Parent = content
    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.new(0, 124, 0, 100)
    grid.CellPadding = UDim2.new(0, 8, 0, 8)
    grid.Parent = list
    if #filtered == 0 then
        Widgets.Label(content, { text = "Nada aqui ainda. Extraia itens da caverna!", position = UDim2.new(0, 0, 0, 100), size = UDim2.new(1, 0, 0, 30), color = C.TextDim })
    end
    for _, item in ipairs(filtered) do
        itemCard(list, UDim2.new(), item.type, item.rarity, string.format("%d 💎", item.value), describeChest(item))
    end
    detailLabel = nil
end

local function ensurePanel(): PanelManager.Panel
    local existing = panel
    if existing then
        return existing
    end
    local created = PanelManager.Create("inventory", {
        title = "Mochila e Baú",
        tabs = { "Mochila", "Baú" },
        onTab = function(name: string, content: Frame)
            currentTab = name
            clear(content)
            if name == "Mochila" then
                drawBackpack(content)
            else
                drawChest(content)
            end
        end,
    })
    panel = created
    return created
end

function InventoryUI.Toggle()
    local active = ensurePanel()
    if not active.IsOpen() then
        currentTab = "Mochila"
        active.SelectTab("Mochila") -- sempre abre na mochila, mesmo se o baú foi a última aba vista
    end
    PanelManager.Toggle("inventory")
end

-- Barrinha de espaços na caverna: um quadrado por espaço, colorido pela raridade do item que o ocupa
local function refreshBar()
    local button = barButton
    if not button then
        return
    end
    local total = slotCount()
    local colors: { Color3 } = {}
    for _, item in ipairs(backpack.items) do
        for _ = 1, slotsOf(item.weight) do
            table.insert(colors, Theme.ForRarity(item.rarity))
        end
    end
    for index, square in ipairs(barSquares) do
        local color = colors[index]
        square.BackgroundColor3 = color or C.PanelDark
        square.BackgroundTransparency = if color then 0 else 0.3
        square.Visible = index <= total
    end
    local text = barText
    if text then
        text.Text = string.format("%d 💎", backpack.totalValue)
    end
    if #backpack.items > lastCount then
        local scale = barScale
        if scale then
            scale.Scale = 1.18
            TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
        end
    end
    lastCount = #backpack.items
end

local function onBackpack(data: unknown)
    if typeof(data) ~= "table" then
        return
    end
    local info = data :: { [string]: any }
    local items: { BackpackItem } = {}
    if typeof(info.items) == "table" then
        for _, raw in ipairs(info.items) do
            if typeof(raw) == "table" and typeof(raw.id) == "string" and typeof(raw.type) == "string" and typeof(raw.rarity) == "string" then
                table.insert(items, {
                    id = raw.id,
                    type = raw.type,
                    rarity = raw.rarity,
                    depthZone = if typeof(raw.depthZone) == "string" then raw.depthZone else nil,
                    baseValue = if typeof(raw.baseValue) == "number" then raw.baseValue else 0,
                    value = if typeof(raw.value) == "number" then raw.value else 0,
                    weight = if typeof(raw.weight) == "number" then raw.weight else Config.SlotWeight,
                })
            end
        end
    end
    backpack.items = items
    backpack.weight = if typeof(info.weight) == "number" then info.weight else 0
    backpack.maxWeight = if typeof(info.maxWeight) == "number" then info.maxWeight else Config.MaxCarryWeight
    backpack.totalValue = if typeof(info.totalValue) == "number" then info.totalValue else 0
    refreshBar()
    local active = panel
    if active and active.IsOpen() and currentTab == "Mochila" then
        active.SelectTab("Mochila")
    end
end

-- Só a caverna mostra a barrinha; no lobby o HUD do lobby cuida da mochila
function InventoryUI.SetCave(isCave: boolean)
    local button = barButton
    if button then
        button.Visible = isCave
    end
end

function InventoryUI.Init()
    local gui = Instance.new("ScreenGui")
    gui.Name = "EcosBackpackBar"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 4
    gui.Parent = player:WaitForChild("PlayerGui")

    local button = Instance.new("TextButton")
    button.AutoButtonColor = false
    button.AnchorPoint = Vector2.new(0.5, 1)
    button.Position = UDim2.new(0.5, 0, 1, -104)
    button.Size = UDim2.new(0, 300, 0, 32)
    button.BackgroundColor3 = C.PanelDark
    button.BackgroundTransparency = 0.2
    button.Text = ""
    button.Visible = false
    button.Parent = gui
    Widgets.AddCorner(button, UDim.new(0, 8))
    Widgets.AddStroke(button, C.Amber, 2)
    local scale = Instance.new("UIScale")
    scale.Parent = button
    barScale = scale
    barButton = button

    local total = slotCount()
    local squares = Instance.new("Frame")
    squares.BackgroundTransparency = 1
    squares.Position = UDim2.new(0, 8, 0, 6)
    squares.Size = UDim2.new(0, 190, 1, -12)
    squares.Parent = button
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 6)
    layout.Parent = squares
    for _ = 1, math.max(total, 8) do
        local square = Instance.new("Frame")
        square.Size = UDim2.new(0, 32, 1, 0)
        square.BackgroundColor3 = C.PanelDark
        square.BackgroundTransparency = 0.3
        square.Parent = squares
        Widgets.AddCorner(square, UDim.new(0, 4))
        Widgets.AddStroke(square, C.Line, 1)
        table.insert(barSquares, square)
    end
    barText = Widgets.Label(button, {
        text = "0 💎",
        position = UDim2.new(0, 205, 0, 0),
        size = UDim2.new(1, -213, 1, 0),
        font = Theme.Font.Strong,
        color = C.Gold,
        alignX = Enum.TextXAlignment.Right,
    })
    button.Activated:Connect(InventoryUI.Toggle)

    HUDUpdate.OnClientEvent:Connect(onBackpack)
    ProfileHUD.OnChanged(function()
        local active = panel
        if active and active.IsOpen() and currentTab == "Baú" then
            active.SelectTab("Baú")
        end
    end)
    LobbyHUD.Register("bag", InventoryUI.Toggle)
    refreshBar()

    -- Tecla I. Pela ContextActionService, que não dispara enquanto se digita no chat
    ContextActionService:BindAction("EcosInventory", function(_name: string, state: Enum.UserInputState)
        if state == Enum.UserInputState.Begin then
            InventoryUI.Toggle()
        end
        return Enum.ContextActionResult.Pass
    end, false, Enum.KeyCode.I)
end

return InventoryUI
