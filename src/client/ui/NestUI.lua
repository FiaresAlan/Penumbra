--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("EcosRemotes")
local NestUpdate = Remotes:WaitForChild("NestUpdate") :: RemoteEvent
local CaptiveBang = Remotes:WaitForChild("CaptiveBang") :: RemoteEvent

local NestUI = {}

local function formatTime(seconds: number): string
    return string.format("%d:%02d", seconds // 60, seconds % 60)
end

function NestUI.Init()
    local gui = playerGui:WaitForChild("EcosHUD")
    local isCaptive = false

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 420, 0, 44)
    label.Position = UDim2.new(0.5, -210, 0, 80)
    label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    label.BackgroundTransparency = 0.45
    label.TextColor3 = Color3.fromRGB(255, 130, 110)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 20
    label.Text = ""
    label.Visible = false
    label.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = label

    -- Botão para quem joga no celular; no PC a tecla F faz o mesmo
    local bangButton = Instance.new("TextButton")
    bangButton.Size = UDim2.new(0, 220, 0, 48)
    bangButton.Position = UDim2.new(0.5, -110, 0.7, 0)
    bangButton.BackgroundColor3 = Color3.fromRGB(120, 30, 30)
    bangButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    bangButton.Font = Enum.Font.GothamBold
    bangButton.TextSize = 18
    bangButton.Text = "Bater nas grades (F)"
    bangButton.Visible = false
    bangButton.Parent = gui

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = bangButton

    bangButton.Activated:Connect(function()
        CaptiveBang:FireServer()
    end)

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed or not isCaptive then
            return
        end
        if input.KeyCode == Enum.KeyCode.F then
            CaptiveBang:FireServer()
        end
    end)

    NestUpdate.OnClientEvent:Connect(function(data: unknown)
        if typeof(data) ~= "table" then
            return
        end
        local info = data :: { none: boolean?, name: string?, timeLeft: number?, isYou: boolean? }
        if info.none then
            isCaptive = false
            label.Visible = false
            bangButton.Visible = false
            return
        end

        local timeLeft = info.timeLeft or 0
        isCaptive = info.isYou == true
        label.Visible = true
        bangButton.Visible = isCaptive
        if isCaptive then
            label.Text = string.format("Você está preso no Ninho — %s", formatTime(timeLeft))
        else
            label.Text = string.format("%s está no Ninho — %s", info.name or "Alguém", formatTime(timeLeft))
        end
    end)
end

return NestUI
