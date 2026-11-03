--!strict
-- Seta no chão à frente do personagem, apontando para o próximo passo (GuideSteps). Só cliente e só na superfície.
-- Some quando o alvo está perto. Pode ser desligada em Ajustes.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local GuideState = require((script.Parent :: Instance):WaitForChild("GuideState") :: ModuleScript)
local GuideSteps = require((script.Parent :: Instance):WaitForChild("GuideSteps") :: ModuleScript)
local ProfileHUD = require((script.Parent :: Instance):WaitForChild("ProfileHUD") :: ModuleScript)
local Theme = require((script.Parent :: Instance):WaitForChild("Theme") :: ModuleScript)

local player = Players.LocalPlayer

local GuideArrow = {}

local HIDE_DISTANCE = 22
local AHEAD = 9 -- studs à frente do personagem

local active = false
local arrow: Part? = nil
local connection: RBXScriptConnection? = nil

local function destroyArrow()
    if connection then
        connection:Disconnect()
        connection = nil
    end
    if arrow then
        arrow:Destroy()
        arrow = nil
    end
end

local function createArrow(): Part
    local part = Instance.new("Part")
    part.Name = "SetaDoGuia"
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.CastShadow = false
    part.Transparency = 1
    part.Size = Vector3.new(5, 0.2, 5)
    part.Parent = workspace

    local gui = Instance.new("SurfaceGui")
    gui.Face = Enum.NormalId.Top
    gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    gui.PixelsPerStud = 12 -- a seta de texto tem no máximo ~100 px: 8 studs de largura
    gui.AlwaysOnTop = true
    gui.LightInfluence = 0
    gui.Parent = part

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Text = "▲"
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.TextColor3 = Theme.Color.Gold
    label.Parent = gui
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 4
    stroke.Color = Theme.Color.TextDark
    stroke.Parent = label
    return part
end

local function start()
    destroyArrow()
    arrow = createArrow()
    connection = RunService.RenderStepped:Connect(function()
        local part = arrow
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not part or not root or not root:IsA("BasePart") then
            return
        end
        local step = GuideSteps.Compute(ProfileHUD.GetProfile() :: any)
        local target = workspace:FindFirstChild(step.partName)
        local gui = part:FindFirstChildOfClass("SurfaceGui")
        if not target or not target:IsA("BasePart") then
            if gui then
                gui.Enabled = false
            end
            return
        end
        local flat = Vector3.new(target.Position.X - root.Position.X, 0, target.Position.Z - root.Position.Z)
        if flat.Magnitude < HIDE_DISTANCE then
            if gui then
                gui.Enabled = false
            end
            return
        end
        if gui then
            gui.Enabled = true
        end
        local direction = flat.Unit
        local position = Vector3.new(root.Position.X, root.Position.Y - 1.2, root.Position.Z) + direction * AHEAD
        -- um leve pulso para chamar a atenção sem atrapalhar
        local pulse = 1 + 0.08 * math.sin(os.clock() * 5)
        part.Size = Vector3.new(8 * pulse, 0.2, 8 * pulse)
        part.CFrame = CFrame.lookAt(position, position + direction)
    end)
end

local function refresh()
    if active and GuideState.IsEnabled() then
        start()
    else
        destroyArrow()
    end
end

function GuideArrow.SetSurface(onSurface: boolean)
    active = onSurface
    refresh()
end

function GuideArrow.Init()
    GuideState.OnChanged(function()
        refresh()
    end)
end

return GuideArrow
