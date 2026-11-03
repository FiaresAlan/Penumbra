--!strict
-- Bússola simples da superfície: uma seta e a distância para a mina e para a vila. O Mercado Negro nunca aparece:
-- achá-lo faz parte do jogo. Some na caverna.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)

local player = Players.LocalPlayer

local Compass = {}

type Row = { arrow: TextLabel, distance: TextLabel, target: Vector3 }

local rows: { Row } = {}
local frame: Frame? = nil

local function makeRow(parent: Frame, name: string, target: Vector3, order: number): Row
    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 28, 0, 28)
    arrow.Position = UDim2.new(0, 6, 0, 4 + (order - 1) * 32)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▲"
    arrow.TextColor3 = Color3.fromRGB(255, 210, 130)
    arrow.Font = Enum.Font.GothamBold
    arrow.TextSize = 22
    arrow.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -44, 0, 28)
    label.Position = UDim2.new(0, 38, 0, 4 + (order - 1) * 32)
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 15
    label.Text = name
    label.Parent = parent
    return { arrow = arrow, distance = label, target = target }
end

local function rowName(row: Row): string
    return if row.target.X == Config.WorldPads.Mina.x then "Mina" else "Vila"
end

function Compass.SetVisible(visible: boolean)
    if frame then
        frame.Visible = visible
    end
end

function Compass.Init()
    local gui = player:WaitForChild("PlayerGui"):WaitForChild("EcosHUD")

    local box = Instance.new("Frame")
    box.Size = UDim2.new(0, 150, 0, 72)
    box.Position = UDim2.new(0, 12, 0.27, 42)
    box.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    box.BackgroundTransparency = 0.35
    box.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = box
    frame = box

    local mina = Config.WorldPads.Mina
    local vila = Config.WorldPads.Vila
    table.insert(rows, makeRow(box, "Mina", Vector3.new(mina.x, 0, mina.z), 1))
    table.insert(rows, makeRow(box, "Vila", Vector3.new(vila.x, 0, vila.z), 2))

    RunService.RenderStepped:Connect(function()
        if not box.Visible then
            return
        end
        local camera = workspace.CurrentCamera
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not camera or not root or not root:IsA("BasePart") then
            return
        end
        local look = camera.CFrame.LookVector
        local lx, lz = look.X, look.Z
        for _, row in ipairs(rows) do
            local dx = row.target.X - root.Position.X
            local dz = row.target.Z - root.Position.Z
            -- Ângulo horário da direção da câmera até o alvo, visto de cima
            local angle = math.atan2(lx * dz - lz * dx, lx * dx + lz * dz)
            row.arrow.Rotation = math.deg(angle)
            row.distance.Text = string.format("%s  %d m", rowName(row), math.floor(math.sqrt(dx * dx + dz * dz) / 3.5 + 0.5))
        end
    end)
end

return Compass
