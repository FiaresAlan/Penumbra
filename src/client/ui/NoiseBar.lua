local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Theme = require(script.Parent:WaitForChild("Theme"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local NoiseBar = {}
local barFrame, barFill, spikeIndicator

function NoiseBar.Init()
    local gui = Instance.new("ScreenGui")
    gui.Name = "EcosHUD"
    gui.ResetOnSpawn = false
    gui.Parent = playerGui

    barFrame = Instance.new("Frame")
    barFrame.Size = UDim2.new(0, 320, 0, 26)
    barFrame.Position = UDim2.new(0.5, -160, 1, -64)
    barFrame.BackgroundColor3 = Theme.Color.PanelDark
    barFrame.BorderSizePixel = 0
    barFrame.Parent = gui

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 13)
    barCorner.Parent = barFrame

    local barStroke = Instance.new("UIStroke")
    barStroke.Color = Theme.Color.Cyan
    barStroke.Thickness = 2
    barStroke.Parent = barFrame

    local barTitle = Instance.new("TextLabel")
    barTitle.Size = UDim2.new(0, 200, 0, 16)
    barTitle.Position = UDim2.new(0, 6, 0, -18)
    barTitle.BackgroundTransparency = 1
    barTitle.Text = "PESO CARREGADO"
    barTitle.TextColor3 = Theme.Color.Cyan
    barTitle.Font = Theme.Font.Strong
    barTitle.TextSize = 13
    barTitle.TextXAlignment = Enum.TextXAlignment.Left
    barTitle.Parent = barFrame

    barFill = Instance.new("Frame")
    barFill.Size = UDim2.new(0, 0, 1, 0)
    barFill.BackgroundColor3 = Theme.Color.Success
    barFill.BorderSizePixel = 0
    barFill.Parent = barFrame

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 13)
    fillCorner.Parent = barFill

    spikeIndicator = Instance.new("TextLabel")
    spikeIndicator.Size = UDim2.new(0, 200, 0, 24)
    spikeIndicator.Position = UDim2.new(0.5, -100, 1, -95)
    spikeIndicator.BackgroundTransparency = 1
    spikeIndicator.TextColor3 = Theme.Color.Danger
    spikeIndicator.Text = ""
    spikeIndicator.Font = Theme.Font.Strong
    spikeIndicator.TextSize = 24
    spikeIndicator.Parent = gui
    local spikeStroke = Instance.new("UIStroke")
    spikeStroke.Color = Color3.new(0, 0, 0)
    spikeStroke.Thickness = 2
    spikeStroke.Parent = spikeIndicator

    RunService.RenderStepped:Connect(function()
        local char = player.Character
        if not char then return end
        local weight = char:GetAttribute("CarryWeight") or 0
        local normalized = math.clamp(weight / Config.MaxCarryWeight, 0, 1)
        barFill.Size = UDim2.new(normalized, 0, 1, 0)
        if normalized < 0.4 then
            barFill.BackgroundColor3 = Theme.Color.Success
        elseif normalized < 0.7 then
            barFill.BackgroundColor3 = Theme.Color.Amber
        else
            barFill.BackgroundColor3 = Theme.Color.Danger
        end
    end)
end

-- A barra só faz sentido na caverna; no lobby ela some.
function NoiseBar.SetVisible(visible)
    if barFrame then
        barFrame.Visible = visible
    end
end

function NoiseBar.ShowSpike()
    spikeIndicator.Text = "! BARULHO !"
    task.delay(1, function()
        if spikeIndicator then
            spikeIndicator.Text = ""
        end
    end)
end

return NoiseBar