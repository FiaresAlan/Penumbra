--!strict
-- Mostra o ponto de gancho mais próximo e envia o pedido (tecla Q ou botão). Não decide nada: o servidor valida.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local UseHook = ReplicatedStorage:WaitForChild("EcosRemotes"):WaitForChild("UseHook") :: RemoteEvent
local ProfileHUD = require(script.Parent:WaitForChild("ui"):WaitForChild("ProfileHUD") :: ModuleScript)

local HookController = {}

local nearestName: string? = nil

local function ownsHook(): boolean
    local profile = ProfileHUD.GetProfile() :: any
    return profile ~= nil and profile.upgrades ~= nil and profile.upgrades.Hook == true
end

local function findNearest(): string?
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local folder = workspace:FindFirstChild("HookPoints")
    if not root or not root:IsA("BasePart") or not folder then
        return nil
    end
    local best: string? = nil
    local bestDistance = Config.HookRange
    for _, point in ipairs(folder:GetChildren()) do
        if point:IsA("BasePart") then
            local distance = (point.Position - root.Position).Magnitude
            if distance <= bestDistance then
                bestDistance = distance
                best = point.Name
            end
        end
    end
    return best
end

function HookController.Init()
    local gui = playerGui:WaitForChild("EcosHUD")

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 180, 0, 44)
    button.Position = UDim2.new(0, 20, 0.8, 0)
    button.BackgroundColor3 = Color3.fromRGB(30, 90, 120)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 16
    button.Text = "Gancho (Q)"
    button.Visible = false
    button.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button

    local function fire()
        if nearestName and ownsHook() then
            UseHook:FireServer(nearestName)
        end
    end

    button.Activated:Connect(fire)
    UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == Enum.KeyCode.Q then
            fire()
        end
    end)

    local accumulator = 0
    RunService.Heartbeat:Connect(function(dt)
        accumulator += dt
        if accumulator < 0.2 then
            return
        end
        accumulator = 0
        nearestName = if ownsHook() then findNearest() else nil
        button.Visible = nearestName ~= nil
    end)
end

return HookController
