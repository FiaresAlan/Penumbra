--!strict
-- Tela única do Mercado e da Oficina. Só mostra o estado recebido do servidor e faz pedidos.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("EcosRemotes")
local OpenShop = Remotes:WaitForChild("OpenShop") :: RemoteEvent
local SellItem = Remotes:WaitForChild("SellItem") :: RemoteEvent
local BuyUpgrade = Remotes:WaitForChild("BuyUpgrade") :: RemoteEvent
local DisplayRelic = Remotes:WaitForChild("DisplayRelic") :: RemoteEvent
local RetrieveRelic = Remotes:WaitForChild("RetrieveRelic") :: RemoteEvent
local ClaimContract = Remotes:WaitForChild("ClaimContract") :: RemoteEvent
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local ProfileHUD = require((script.Parent :: Instance):WaitForChild("ProfileHUD") :: ModuleScript)

local ShopUI = {}

local window: Frame
local titleLabel: TextLabel
local list: ScrollingFrame
local currentShop: string? = nil

local function clearList()
    for _, child in ipairs(list:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextLabel") then
            child:Destroy()
        end
    end
end

local function addRow(text: string, buttonText: string?, onClick: (() -> ())?)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -8, 0, 40)
    row.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
    row.BorderSizePixel = 0
    row.Parent = list

    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 6)
    rowCorner.Parent = row

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -120, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(235, 235, 240)
    label.Font = Enum.Font.Gotham
    label.TextSize = 15
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.Text = text
    label.Parent = row

    if buttonText then
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0, 100, 0, 30)
        button.Position = UDim2.new(1, -108, 0.5, -15)
        button.BackgroundColor3 = if onClick then Color3.fromRGB(70, 130, 80) else Color3.fromRGB(70, 70, 70)
        button.TextColor3 = Color3.new(1, 1, 1)
        button.Font = Enum.Font.GothamBold
        button.TextSize = 14
        button.Text = buttonText
        button.Parent = row
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 6)
        buttonCorner.Parent = button
        if onClick then
            button.Activated:Connect(onClick)
        end
    end
end

local function itemName(item: any): string
    local kind = if item.type == "Relic" then "Relíquia" else "Núcleo"
    return string.format("%s (%s)", kind, tostring(item.rarity))
end

local function render()
    if not window.Visible then
        return
    end
    clearList()
    local profile = ProfileHUD.GetProfile() :: any
    if not profile then
        titleLabel.Text = "Carregando..."
        return
    end

    if currentShop == "market" then
        titleLabel.Text = string.format("Mercado — Venda segura · %d 💎", profile.money)
        if #profile.stash == 0 then
            addRow("Seu baú está vazio. Extraia itens da caverna.", nil, nil)
        end
        for _, item in ipairs(profile.stash) do
            local price = math.floor(item.value * Config.LobbyMarketRate)
            addRow(string.format("%s — %d 💎", itemName(item), price), "Vender", function()
                SellItem:FireServer(item.id)
            end)
        end
    elseif currentShop == "contracts" then
        titleLabel.Text = string.format("Quadro de Contratos · %d 💎", profile.money)
        local contracts = profile.contracts or {}
        local function addScope(listName: string, label: string)
            for _, id in ipairs(contracts[listName] or {}) do
                local definition = Config.ContractDefs[id]
                if definition then
                    local progress = (contracts[listName .. "Progress"] or {})[id] or 0
                    local claimed = (contracts[listName .. "Claimed"] or {})[id] == true
                    local text = string.format("%s: %s (%d/%d) — +%d 💎", label, definition.text, progress, definition.goal, definition.reward)
                    if claimed then
                        addRow(text, "Recebido", nil)
                    elseif progress >= definition.goal then
                        addRow(text, "Receber", function()
                            ClaimContract:FireServer(id)
                        end)
                    else
                        addRow(text, nil, nil)
                    end
                end
            end
        end
        addScope("daily", "Diário")
        addScope("weekly", "Semanal")
    else
        titleLabel.Text = string.format("Oficina · %d 💎", profile.money)
        for id, definition in pairs(Config.Upgrades) do
            local owned = profile.upgrades[id] == true
            addRow(string.format("%s — %d 💎", definition.name, definition.price),
                if owned then "Comprado" else "Comprar",
                if owned then nil else function()
                    BuyUpgrade:FireServer(id)
                end)
        end
        for _, item in ipairs(profile.relicDisplay or {}) do
            addRow("Exposta: " .. itemName(item), "Retirar", function()
                RetrieveRelic:FireServer(item.id)
            end)
        end
        for _, item in ipairs(profile.stash) do
            if item.type == "Relic" then
                addRow(itemName(item) .. " — expor", "Expor", function()
                    DisplayRelic:FireServer(item.id)
                end)
            end
        end
    end
end

function ShopUI.Init()
    local gui = Instance.new("ScreenGui")
    gui.Name = "EcosShop"
    gui.ResetOnSpawn = false
    gui.Parent = playerGui

    window = Instance.new("Frame")
    window.Size = UDim2.new(0, 440, 0, 380)
    window.Position = UDim2.new(0.5, -220, 0.5, -190)
    window.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
    window.BorderSizePixel = 0
    window.Visible = false
    window.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = window

    titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -60, 0, 40)
    titleLabel.Position = UDim2.new(0, 14, 0, 6)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Color3.fromRGB(255, 225, 140)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 18
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Text = ""
    titleLabel.Parent = window

    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 36, 0, 32)
    close.Position = UDim2.new(1, -44, 0, 8)
    close.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
    close.TextColor3 = Color3.new(1, 1, 1)
    close.Font = Enum.Font.GothamBold
    close.TextSize = 16
    close.Text = "X"
    close.Parent = window
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = close
    close.Activated:Connect(function()
        window.Visible = false
    end)

    list = Instance.new("ScrollingFrame")
    list.Size = UDim2.new(1, -24, 1, -64)
    list.Position = UDim2.new(0, 12, 0, 52)
    list.BackgroundTransparency = 1
    list.BorderSizePixel = 0
    list.ScrollBarThickness = 6
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.CanvasSize = UDim2.new(0, 0, 0, 0)
    list.Parent = window

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.Parent = list

    OpenShop.OnClientEvent:Connect(function(shop: unknown)
        if shop ~= "market" and shop ~= "workshop" and shop ~= "contracts" then
            return
        end
        currentShop = shop :: string
        window.Visible = true
        render()
    end)

    ProfileHUD.OnChanged(render)
end

return ShopUI
