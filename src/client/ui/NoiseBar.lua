local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local NoiseBar = {}
local barFill, spikeIndicator

function NoiseBar.Init()
    local gui = Instance.new("ScreenGui")
    gui.Name = "EcosHUD"
    gui.ResetOnSpawn = false
    gui.Parent = playerGui

    local barFrame = Instance.new("Frame")
    barFrame.Size = UDim2.new(0, 300, 0, 20)
    barFrame.Position = UDim2.new(0.5, -150, 1, -60)
    barFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    barFrame.BorderSizePixel = 0
    barFrame.Parent = gui

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 10)
    barCorner.Parent = barFrame

    barFill = Instance.new("Frame")
    barFill.Size = UDim2.new(0, 0, 1, 0)
    barFill.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
    barFill.BorderSizePixel = 0
    barFill.Parent = barFrame

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 10)
    fillCorner.Parent = barFill

    spikeIndicator = Instance.new("TextLabel")
    spikeIndicator.Size = UDim2.new(0, 200, 0, 24)
    spikeIndicator.Position = UDim2.new(0.5, -100, 1, -95)
    spikeIndicator.BackgroundTransparency = 1
    spikeIndicator.TextColor3 = Color3.fromRGB(255, 80, 80)
    spikeIndicator.Text = ""
    spikeIndicator.Font = Enum.Font.GothamBold
    spikeIndicator.TextSize = 20
    spikeIndicator.Parent = gui

    RunService.RenderStepped:Connect(function()
        local char = player.Character
        if not char then return end
        local weight = char:GetAttribute("CarryWeight") or 0
        local normalized = math.clamp(weight / 10, 0, 1)
        barFill.Size = UDim2.new(normalized, 0, 1, 0)
        if normalized < 0.4 then
            barFill.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
        elseif normalized < 0.7 then
            barFill.BackgroundColor3 = Color3.fromRGB(220, 200, 60)
        else
            barFill.BackgroundColor3 = Color3.fromRGB(220, 80, 60)
        end
    end)
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