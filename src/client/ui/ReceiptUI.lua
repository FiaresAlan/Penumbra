--!strict
-- V5: recibo da extração com os itens girando (ItemViewport), o total e o multiplicador. Some sozinho em 9 s e pode ser pulado.
-- Substitui o texto simples do ExtractionUI (que só aparece se este módulo não estiver ativo).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Theme = require((script.Parent :: Instance):WaitForChild("Theme") :: ModuleScript)
local Widgets = require((script.Parent :: Instance):WaitForChild("Widgets") :: ModuleScript)
local ItemViewport = require((script.Parent :: Instance):WaitForChild("ItemViewport") :: ModuleScript)
local ItemInfo = require((script.Parent :: Instance):WaitForChild("ItemInfo") :: ModuleScript)

local player = Players.LocalPlayer
local Receipt = ReplicatedStorage:WaitForChild("EcosRemotes"):WaitForChild("Receipt") :: RemoteEvent

local C = Theme.Color

local ReceiptUI = {}

local gui: ScreenGui? = nil
local token = 0

local SHOW_SECONDS = 9
local MAX_CARDS = 8

local function clear()
    local current = gui
    if current then
        for _, child in ipairs(current:GetChildren()) do
            child:Destroy()
        end
    end
end

local function show(data: unknown)
    if typeof(data) ~= "table" then
        return
    end
    local receipt = data :: { [string]: any }
    local current = gui
    if not current or typeof(receipt.items) ~= "table" then
        return
    end
    clear()
    token += 1
    local mine = token

    local items = receipt.items :: { any }
    local frame = Instance.new("Frame")
    frame.AnchorPoint = Vector2.new(0.5, 0)
    frame.Position = UDim2.new(0.5, 0, 0.12, 0)
    frame.Size = UDim2.new(0, 520, 0, if #items > 0 then 250 else 120)
    frame.BackgroundColor3 = C.PanelBg
    frame.Parent = current
    Widgets.AddCorner(frame, UDim.new(0, 14))
    Widgets.AddStroke(frame, C.Amber, 3)
    local limit = Instance.new("UISizeConstraint")
    limit.MaxSize = Vector2.new(560, 280)
    limit.Parent = frame
    local scale = Instance.new("UIScale")
    scale.Scale = 0.9
    scale.Parent = frame
    TweenService:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()

    Widgets.Label(frame, {
        text = "Recibo da extração",
        position = UDim2.new(0, 16, 0, 8),
        size = UDim2.new(1, -32, 0, 30),
        font = Theme.Font.Title,
        textSize = Theme.TextSize.Heading,
        color = C.Gold,
        alignX = Enum.TextXAlignment.Center,
    })
    local total = if typeof(receipt.total) == "number" then receipt.total else 0
    local multiplier = if typeof(receipt.multiplier) == "number" then receipt.multiplier else 1
    Widgets.Label(frame, {
        text = string.format("%d itens · %d 💎 (x%.2f)", #items, total, multiplier),
        position = UDim2.new(0, 16, 0, 40),
        size = UDim2.new(1, -32, 0, 22),
        color = C.TextDim,
        alignX = Enum.TextXAlignment.Center,
    })

    if #items > 0 then
        local row = Instance.new("Frame")
        row.BackgroundTransparency = 1
        row.Position = UDim2.new(0, 16, 0, 70)
        row.Size = UDim2.new(1, -32, 0, 120)
        row.Parent = frame
        local layout = Instance.new("UIListLayout")
        layout.FillDirection = Enum.FillDirection.Horizontal
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.Padding = UDim.new(0, 8)
        layout.Parent = row
        for index, item in ipairs(items) do
            if index > MAX_CARDS then
                break
            end
            if typeof(item) == "table" then
                local info = item :: { [string]: any }
                local card = Widgets.Card(row, UDim2.new(0, 56, 1, 0), tostring(info.rarity))
                local shown = pcall(function()
                    ItemViewport.Create(card, tostring(info.type), tostring(info.rarity), UDim2.new(1, 0, 0.6, 0), UDim2.new(0, 0, 0, 2))
                end)
                if not shown then
                    Widgets.Label(card, { text = ItemInfo.Emoji(tostring(info.type)), size = UDim2.new(1, 0, 0.6, 0), textSize = 24, alignX = Enum.TextXAlignment.Center })
                end
                Widgets.Label(card, {
                    text = tostring(info.value or 0),
                    position = UDim2.new(0, 0, 0.62, 0),
                    size = UDim2.new(1, 0, 0, 18),
                    textSize = Theme.TextSize.Small,
                    color = C.Gold,
                    alignX = Enum.TextXAlignment.Center,
                })
            end
        end
        if #items > MAX_CARDS then
            Widgets.Label(frame, {
                text = string.format("+ %d itens", #items - MAX_CARDS),
                position = UDim2.new(0, 16, 0, 194),
                size = UDim2.new(1, -32, 0, 18),
                color = C.TextDim,
                alignX = Enum.TextXAlignment.Center,
            })
        end
    end

    Widgets.Button(frame, {
        text = "Pular",
        size = UDim2.new(0, 110, 0, 30),
        position = UDim2.new(0.5, -55, 1, -38),
        onClick = function()
            if mine == token then
                clear()
            end
        end,
    })
    task.delay(SHOW_SECONDS, function()
        if mine == token then
            clear()
        end
    end)
end

function ReceiptUI.Init()
    local created = Instance.new("ScreenGui")
    created.Name = "EcosReceipt"
    created.ResetOnSpawn = false
    created.DisplayOrder = 7
    created.Parent = player:WaitForChild("PlayerGui")
    gui = created
    ReplicatedStorage:SetAttribute("ReceiptUI", true) -- avisa o ExtractionUI de que o recibo visual está ativo
    Receipt.OnClientEvent:Connect(show)
end

return ReceiptUI
