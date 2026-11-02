--!strict
-- Andar devagar: segure Ctrl (ou use o botão no celular). O cliente só pede; o servidor define a velocidade.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Sneak = ReplicatedStorage:WaitForChild("EcosRemotes"):WaitForChild("Sneak") :: RemoteEvent

local SneakInput = {}

local Run = ReplicatedStorage:WaitForChild("EcosRemotes"):WaitForChild("Run") :: RemoteEvent

local sneaking = false
local running = false

local function set(value: boolean)
    if sneaking == value then
        return
    end
    sneaking = value
    Sneak:FireServer(value)
end

local function setRun(value: boolean)
    if running == value then
        return
    end
    running = value
    Run:FireServer(value)
end

function SneakInput.Init()
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then
            return
        end
        if input.KeyCode == Enum.KeyCode.LeftControl then
            set(true)
        elseif input.KeyCode == Enum.KeyCode.LeftShift then
            setRun(true)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.LeftControl then
            set(false)
        elseif input.KeyCode == Enum.KeyCode.LeftShift then
            setRun(false)
        end
    end)

    if UserInputService.TouchEnabled then
        local gui = playerGui:WaitForChild("EcosHUD")
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0, 120, 0, 44)
        button.Position = UDim2.new(1, -140, 0.72, 0)
        button.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        button.TextColor3 = Color3.new(1, 1, 1)
        button.Font = Enum.Font.GothamBold
        button.TextSize = 14
        button.Text = "Devagar: não"
        button.Parent = gui
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = button
        button.Activated:Connect(function()
            set(not sneaking)
            button.Text = if sneaking then "Devagar: sim" else "Devagar: não"
            button.BackgroundColor3 = if sneaking then Color3.fromRGB(60, 110, 70) else Color3.fromRGB(50, 50, 60)
        end)

        -- Correr só tem efeito na superfície; o servidor ignora o pedido na caverna
        local runButton = button:Clone()
        runButton.Position = UDim2.new(1, -140, 0.64, 0)
        runButton.Text = "Correr: não"
        runButton.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        runButton.Parent = gui
        runButton.Activated:Connect(function()
            setRun(not running)
            runButton.Text = if running then "Correr: sim" else "Correr: não"
            runButton.BackgroundColor3 = if running then Color3.fromRGB(60, 110, 70) else Color3.fromRGB(50, 50, 60)
        end)
    end
end

return SneakInput
