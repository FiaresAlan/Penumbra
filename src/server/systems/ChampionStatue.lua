--!strict
-- V2: pedestal do campeão da semana ao lado do mural da praça da mina. Mostra o avatar de quem tem o maior saque semanal
-- (CreateHumanoidModelFromUserId, em pcall; sem campeão ou sem rede, fica um boneco dourado). Só decoração.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local systems = script.Parent :: Instance
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local HighlightsSystem = require(systems:WaitForChild("HighlightsSystem") :: ModuleScript)

local ChampionStatue = {}

local FLOOR = Config.WorldFloorY
local PEDESTAL_X, PEDESTAL_Z = 48, -22
local REFRESH_SECONDS = 90

local folder: Folder? = nil
local shownUserId: number? = nil -- 0 = boneco dourado
local pose: Model? = nil

local function part(name: string, size: Vector3, cframe: CFrame, material: Enum.Material, color: Color3, parent: Instance): Part
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cframe
    p.Material = material
    p.Color = color
    p.Anchored = true
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

local function buildPedestal(parent: Instance)
    local stone = Color3.fromRGB(150, 142, 128)
    local gold = Color3.fromRGB(226, 178, 62)
    part("PedestalBase", Vector3.new(9, 1, 9), CFrame.new(PEDESTAL_X, FLOOR + 0.5, PEDESTAL_Z), Enum.Material.Cobblestone, stone, parent)
    part("PedestalCorpo", Vector3.new(6.4, 3, 6.4), CFrame.new(PEDESTAL_X, FLOOR + 2.5, PEDESTAL_Z), Enum.Material.Cobblestone, stone, parent)
    part("PedestalTopo", Vector3.new(7, 0.6, 7), CFrame.new(PEDESTAL_X, FLOOR + 4.3, PEDESTAL_Z), Enum.Material.Metal, gold, parent)
    local plate = part("PedestalPlaca", Vector3.new(5, 1.4, 0.3), CFrame.new(PEDESTAL_X - 3.3, FLOOR + 2.6, PEDESTAL_Z) * CFrame.Angles(0, math.rad(90), 0), Enum.Material.Metal, gold, parent)
    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(255, 214, 130)
    light.Range = 24
    light.Brightness = 1.2
    light.Parent = plate
    local gui = Instance.new("SurfaceGui")
    gui.Face = Enum.NormalId.Front
    gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    gui.PixelsPerStud = 60
    gui.Parent = plate
    local label = Instance.new("TextLabel")
    label.Name = "Texto"
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(46, 30, 10)
    label.Font = Enum.Font.Fondamento
    label.TextScaled = true
    label.TextWrapped = true
    label.Text = "Campeão da semana"
    label.Parent = gui
end

local function setPlate(text: string)
    local current = folder
    local plate = current and current:FindFirstChild("PedestalPlaca")
    local label = plate and plate:FindFirstChild("Texto", true)
    if label and label:IsA("TextLabel") then
        label.Text = text
    end
end

local function showChampion(userId: number, name: string, value: number)
    local current = folder
    if not current then
        return
    end
    local old = pose
    if old then
        old:Destroy()
        pose = nil
    end
    local model: Model? = nil
    if userId > 0 then
        local ok, result = pcall(function()
            return Players:CreateHumanoidModelFromUserId(userId)
        end)
        if ok and result then
            model = result
        end
    end
    local golden = false
    if not model then
        local ok, result = pcall(function()
            local description = Instance.new("HumanoidDescription")
            local color = Color3.fromRGB(226, 178, 62)
            description.HeadColor = color
            description.TorsoColor = color
            description.LeftArmColor = color
            description.RightArmColor = color
            description.LeftLegColor = color
            description.RightLegColor = color
            return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
        end)
        if ok and result then
            model = result
            golden = true
        end
    end
    if not model then
        return
    end
    model.Name = "Campeao"
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    end
    model:PivotTo(CFrame.new(PEDESTAL_X, FLOOR + 4.6 + 3.2, PEDESTAL_Z) * CFrame.Angles(0, math.rad(-90), 0))
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.Anchored = true
        end
    end
    model.Parent = current
    pose = model
    if golden then
        setPlate("O pódio espera por você")
    else
        setPlate(string.format("Campeão da semana\n%s\n%d moedas", name, value))
    end
end

local function refresh()
    local top = HighlightsSystem.GetTop()
    local first = top[1]
    local userId = if first then first.userId else 0
    if shownUserId == userId then
        return
    end
    shownUserId = userId
    local name = if first then HighlightsSystem.NameOf(first.userId) else ""
    showChampion(userId, name, if first then first.value else 0)
end

function ChampionStatue.Init()
    task.spawn(function()
        local baked = workspace:WaitForChild("WorldBaked", 30)
        if not baked then
            return
        end
        local created = Instance.new("Folder")
        created.Name = "Pedestal"
        created.Parent = baked
        folder = created
        buildPedestal(created)
        while true do
            task.wait(REFRESH_SECONDS)
            refresh()
        end
    end)
    task.delay(12, refresh)
end

return ChampionStatue
