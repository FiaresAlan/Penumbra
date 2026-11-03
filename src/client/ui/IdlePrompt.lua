--!strict
-- Convite "Elevador pronto": se o jogador ficar parado 90 s no lobby, sem painel aberto, com a descida livre, aparece
-- "Descer agora?". SIM pede a descida (o servidor decide); NÃO silencia por 5 minutos. Só cliente.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require((script.Parent :: Instance):WaitForChild("Theme") :: ModuleScript)
local Widgets = require((script.Parent :: Instance):WaitForChild("Widgets") :: ModuleScript)
local PanelManager = require((script.Parent :: Instance):WaitForChild("PanelManager") :: ModuleScript)

local player = Players.LocalPlayer
local RequestDescent = ReplicatedStorage:WaitForChild("EcosRemotes"):WaitForChild("RequestDescent") :: RemoteEvent

local C = Theme.Color

local IdlePrompt = {}

local IDLE_SECONDS = 90
local SNOOZE_SECONDS = 300
local MOVE_THRESHOLD = 1.5 -- studs

local frame: Frame? = nil
local active = false
local token = 0
local snoozeUntil = 0

local function hide()
    local current = frame
    if current then
        current.Visible = false
    end
end

local function runLoop()
    token += 1
    local mine = token
    task.spawn(function()
        local lastPosition: Vector3? = nil
        local idleFor = 0
        while active and mine == token do
            task.wait(1)
            local character = player.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if root and root:IsA("BasePart") then
                local last = lastPosition
                if last and (root.Position - last).Magnitude > MOVE_THRESHOLD then
                    idleFor = 0
                    hide()
                else
                    idleFor += 1
                end
                lastPosition = root.Position
            end
            local free = workspace:GetAttribute("ExpPhase") == "Waiting" and workspace:GetAttribute("ExpDescending") ~= true
            if idleFor >= IDLE_SECONDS and free and PanelManager.Current() == nil and os.clock() >= snoozeUntil then
                local current = frame
                if current and not current.Visible then
                    current.Visible = true
                end
            elseif not free then
                hide()
            end
        end
    end)
end

-- Ligado só na superfície
function IdlePrompt.SetSurface(onSurface: boolean)
    active = onSurface
    if onSurface then
        runLoop()
    else
        token += 1
        hide()
    end
end

function IdlePrompt.Init()
    local gui = Instance.new("ScreenGui")
    gui.Name = "EcosIdlePrompt"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 6
    gui.Parent = player:WaitForChild("PlayerGui")

    local box = Instance.new("Frame")
    box.AnchorPoint = Vector2.new(0.5, 0.5)
    box.Position = UDim2.fromScale(0.5, 0.5)
    box.Size = UDim2.new(0, 380, 0, 150)
    box.BackgroundColor3 = C.PanelBg
    box.Visible = false
    box.Parent = gui
    Widgets.AddCorner(box, UDim.new(0, 12))
    Widgets.AddStroke(box, C.Amber, 3)
    Widgets.Label(box, {
        text = "Elevador pronto",
        position = UDim2.new(0, 16, 0, 10),
        size = UDim2.new(1, -32, 0, 36),
        font = Theme.Font.Title,
        textSize = Theme.TextSize.Title,
        color = C.Gold,
        alignX = Enum.TextXAlignment.Center,
    })
    Widgets.Label(box, {
        text = "Que tal descer agora?",
        position = UDim2.new(0, 16, 0, 50),
        size = UDim2.new(1, -32, 0, 26),
        alignX = Enum.TextXAlignment.Center,
    })
    Widgets.Button(box, {
        text = "SIM",
        variant = "primary",
        size = UDim2.new(0, 150, 0, 44),
        position = UDim2.new(0, 30, 1, -60),
        onClick = function()
            hide()
            RequestDescent:FireServer()
        end,
    })
    Widgets.Button(box, {
        text = "NÃO",
        variant = "danger",
        size = UDim2.new(0, 150, 0, 44),
        position = UDim2.new(1, -180, 1, -60),
        onClick = function()
            snoozeUntil = os.clock() + SNOOZE_SECONDS
            hide()
        end,
    })
    frame = box
end

return IdlePrompt
