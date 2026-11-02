--!strict
-- Aviso "O grupo vai descer": aparece para quem está longe do elevador durante a contagem, com o tempo restante
-- e um botão para voltar de carroça. O botão só pede; o servidor confere fase, estado e espera.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("EcosRemotes")
local GroupCall = remotes:WaitForChild("GroupCall") :: RemoteEvent
local CallCart = remotes:WaitForChild("CallCart") :: RemoteEvent

local GroupCallUI = {}

function GroupCallUI.Init()
    local gui = player:WaitForChild("PlayerGui"):WaitForChild("EcosHUD")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 340, 0, 92)
    frame.Position = UDim2.new(0.5, -170, 0.12, 0)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    frame.BackgroundTransparency = 0.15
    frame.Visible = false
    frame.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -16, 0, 40)
    label.Position = UDim2.new(0, 8, 0, 6)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 210, 130)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 18
    label.TextWrapped = true
    label.Parent = frame

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -32, 0, 34)
    button.Position = UDim2.new(0, 16, 0, 50)
    button.BackgroundColor3 = Color3.fromRGB(60, 110, 70)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 16
    button.Text = "Voltar de carroça"
    button.Parent = frame
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = button

    local token = 0
    button.Activated:Connect(function()
        CallCart:FireServer()
        frame.Visible = false
        token += 1
    end)

    GroupCall.OnClientEvent:Connect(function(seconds: unknown)
        if typeof(seconds) ~= "number" or seconds ~= seconds or seconds <= 0 or seconds > 120 then
            return
        end
        token += 1
        local mine = token
        local deadline = os.clock() + seconds
        frame.Visible = true
        task.spawn(function()
            while mine == token do
                local remaining = deadline - os.clock()
                if remaining <= 0 then
                    break
                end
                label.Text = string.format("O grupo vai descer em %d s", math.ceil(remaining))
                task.wait(0.25)
            end
            if mine == token then
                frame.Visible = false
            end
        end)
    end)
end

return GroupCallUI
