local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("EcosRemotes")
local ElevatorUpdate = Remotes:WaitForChild("ElevatorUpdate")
local HUDUpdate = Remotes:WaitForChild("HUDUpdate")

local ExtractionUI = {}
local statusLabel, inventoryLabel

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
    inventoryLabel.Text = "Mochila: 0 núcleos · 0 💎"
    inventoryLabel.Parent = gui

    ElevatorUpdate.OnClientEvent:Connect(function(data)
        if data.stage == "arriving" then
            statusLabel.Text = string.format("⏳ Elevador chegando em %ds", data.timeLeft)
        elseif data.stage == "open" then
            statusLabel.Text = string.format("🚪 PORTAS ABERTAS — %ds", data.timeLeft)
        elseif data.stage == "closed" then
            statusLabel.Text = "🚫 Portas fechadas"
            task.delay(3, function()
                statusLabel.Text = ""
            end)
        end
    end)

    HUDUpdate.OnClientEvent:Connect(function(data)
        inventoryLabel.Text = string.format("Mochila: %d núcleos · %d 💎",
            data.coresCount, data.totalValue)
    end)
end

return ExtractionUI