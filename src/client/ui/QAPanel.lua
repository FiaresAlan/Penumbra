--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("EcosRemotes")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)

local QAPanel = {}

function QAPanel.Init()
    -- O remote só existe no Studio; fora dele o painel simplesmente não aparece.
    local remote = Remotes:WaitForChild("QACommand", 5)
    if not remote or not remote:IsA("RemoteEvent") then
        return
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "EcosQA"
    gui.ResetOnSpawn = false
    gui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 196, 0, 0)
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.Position = UDim2.new(1, -206, 0, 80)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.5
    frame.BorderSizePixel = 0
    frame.Parent = gui

    -- Duas colunas, para a lista de botões caber na tela
    local layout = Instance.new("UIGridLayout")
    layout.CellSize = UDim2.new(0, 84, 0, 34)
    layout.CellPadding = UDim2.new(0, 6, 0, 6)
    layout.Parent = frame

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 6)
    padding.PaddingBottom = UDim.new(0, 6)
    padding.PaddingLeft = UDim.new(0, 6)
    padding.PaddingRight = UDim.new(0, 6)
    padding.Parent = frame

    for _, definition in ipairs(Config.QAButtons) do
        local button = Instance.new("TextButton")
        button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.Font = Enum.Font.GothamBold
        button.TextSize = 11
        button.TextWrapped = true
        button.Text = definition.label
        button.Parent = frame

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = button

        button.Activated:Connect(function()
            remote:FireServer(definition.id)
        end)
    end
end

return QAPanel
