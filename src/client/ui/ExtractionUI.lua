local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("EcosRemotes")
local ElevatorUpdate = Remotes:WaitForChild("ElevatorUpdate")
local HUDUpdate = Remotes:WaitForChild("HUDUpdate")
local Receipt = Remotes:WaitForChild("Receipt")

local ExtractionUI = {}
local statusLabel, inventoryLabel, noticeLabel, receiptLabel

-- O HUD do lobby tem a própria mochila e moedas: este texto fica só para a caverna
function ExtractionUI.SetInventoryVisible(visible)
    if inventoryLabel then
        inventoryLabel.Visible = visible
    end
end

-- A faixa do elevador só aparece quando há mensagem
local function setStatus(text)
    statusLabel.Text = text
    statusLabel.Visible = text ~= ""
end
local noticeToken = 0
local receiptToken = 0

local function newLabel(parent, size, position)
    local label = Instance.new("TextLabel")
    label.Size = size
    label.Position = position
    label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    label.BackgroundTransparency = 0.5
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.Text = ""
    label.Visible = false
    label.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = label
    return label
end

local function showTemporarily(label, text, seconds, tokenName)
    label.Text = text
    label.Visible = true
    if tokenName == "notice" then
        noticeToken = noticeToken + 1
        local mine = noticeToken
        task.delay(seconds, function()
            if mine == noticeToken then label.Visible = false end
        end)
    else
        receiptToken = receiptToken + 1
        local mine = receiptToken
        task.delay(seconds, function()
            if mine == receiptToken then label.Visible = false end
        end)
    end
end

function ExtractionUI.Init()
    local gui = playerGui:WaitForChild("EcosHUD")

    statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(0, 400, 0, 50)
    statusLabel.Position = UDim2.new(0.5, -200, 0, 20)
    statusLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    statusLabel.BackgroundTransparency = 0.5
    statusLabel.TextColor3 = Color3.fromRGB(255, 220, 80)
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.TextSize = 24
    statusLabel.Text = ""
    statusLabel.Visible = false
    statusLabel.Parent = gui

    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 8)
    statusCorner.Parent = statusLabel

    inventoryLabel = Instance.new("TextLabel")
    inventoryLabel.Size = UDim2.new(0, 300, 0, 30)
    inventoryLabel.Position = UDim2.new(0, 20, 0, 20)
    inventoryLabel.BackgroundTransparency = 1
    inventoryLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    inventoryLabel.Font = Enum.Font.Gotham
    inventoryLabel.TextSize = 18
    inventoryLabel.TextXAlignment = Enum.TextXAlignment.Left
    inventoryLabel.Text = "Mochila: 0 itens · 0 💎"
    inventoryLabel.Parent = gui

    noticeLabel = newLabel(gui, UDim2.new(0, 300, 0, 36), UDim2.new(0.5, -150, 0.62, 0))
    noticeLabel.TextColor3 = Color3.fromRGB(255, 120, 100)

    receiptLabel = newLabel(gui, UDim2.new(0, 360, 0, 120), UDim2.new(0.5, -180, 0.25, 0))
    receiptLabel.TextColor3 = Color3.fromRGB(180, 255, 200)

    ElevatorUpdate.OnClientEvent:Connect(function(data)
        if data.stage == "arriving" then
            setStatus(string.format("⏳ Elevador chegando em %ds", data.timeLeft))
        elseif data.stage == "open" then
            setStatus(string.format("🚪 PORTAS ABERTAS — %ds", data.timeLeft))
        elseif data.stage == "cooldown" then
            setStatus(string.format("🔁 Elevador voltando em %ds", data.timeLeft))
        elseif data.stage == "idle" then
            setStatus("")
        elseif data.stage == "closed" then
            setStatus("🚫 Portas fechadas")
            task.delay(3, function()
                setStatus("")
            end)
        end
    end)

    HUDUpdate.OnClientEvent:Connect(function(data)
        inventoryLabel.Text = string.format("Mochila: %d itens · %d 💎",
            data.itemsCount, data.totalValue)
        if data.notice then
            showTemporarily(noticeLabel, data.notice, 2, "notice")
        end
    end)

    Receipt.OnClientEvent:Connect(function(receipt)
        if typeof(receipt) ~= "table" then return end
        local text = string.format("Extração concluída\n%d itens · %d 💎 (x%.2f)",
            #receipt.items, receipt.total, receipt.multiplier)
        -- V5: o recibo visual (ReceiptUI) mostra os itens girando; o texto só aparece se ele não existir
        if not ReplicatedStorage:GetAttribute("ReceiptUI") then
            showTemporarily(receiptLabel, text, 6, "receipt")
        end
    end)
end

return ExtractionUI
