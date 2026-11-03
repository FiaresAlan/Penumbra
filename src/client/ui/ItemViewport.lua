--!strict
-- V5: o item girando dentro de um ViewportFrame (no lugar do emoji): núcleo é uma esfera de néon na cor da raridade,
-- núcleo denso é maior e roxo, relíquia é um cristal rosa com uma esfera. Uma só rotina gira todos os que estão na tela.
local RunService = game:GetService("RunService")

local Theme = require((script.Parent :: Instance):WaitForChild("Theme") :: ModuleScript)

local ItemViewport = {}

type Spinner = { frame: ViewportFrame, model: Model, speed: number }

local spinners: { Spinner } = {}
local connection: RBXScriptConnection? = nil
local angle = 0

local function neon(parent: Instance, shape: Enum.PartType, size: Vector3, color: Color3, cframe: CFrame): Part
    local part = Instance.new("Part")
    part.Shape = shape
    part.Size = size
    part.Color = color
    part.Material = Enum.Material.Neon
    part.Anchored = true
    part.CanCollide = false
    part.CFrame = cframe
    part.Parent = parent
    return part
end

local function ensureLoop()
    if connection then
        return
    end
    connection = RunService.RenderStepped:Connect(function(dt: number)
        angle += dt
        for index = #spinners, 1, -1 do
            local spinner = spinners[index]
            if not spinner.frame.Parent then
                table.remove(spinners, index)
            else
                spinner.model:PivotTo(CFrame.Angles(0.25, angle * spinner.speed, 0))
            end
        end
        if #spinners == 0 and connection then
            connection:Disconnect()
            connection = nil
        end
    end)
end

-- Cria o ViewportFrame dentro de `parent`. itemType: "Core", "DenseCore" ou "Relic".
function ItemViewport.Create(parent: Instance, itemType: string, rarity: string, size: UDim2, position: UDim2): ViewportFrame
    local frame = Instance.new("ViewportFrame")
    frame.BackgroundTransparency = 1
    frame.Size = size
    frame.Position = position
    frame.Ambient = Color3.fromRGB(150, 150, 160)
    frame.LightColor = Color3.fromRGB(255, 244, 220)
    frame.LightDirection = Vector3.new(-1, -1, -1)
    frame.Parent = parent

    local model = Instance.new("Model")
    model.Name = "Item"
    local color = Theme.ForRarity(rarity)
    if itemType == "Relic" then
        local body = neon(model, Enum.PartType.Block, Vector3.new(1.6, 1.6, 1.6), Color3.fromRGB(255, 120, 210), CFrame.Angles(math.rad(45), 0, math.rad(45)))
        body.Name = "Cristal"
        neon(model, Enum.PartType.Ball, Vector3.new(0.9, 0.9, 0.9), Color3.fromRGB(255, 230, 250), CFrame.new())
    elseif itemType == "DenseCore" then
        neon(model, Enum.PartType.Ball, Vector3.new(2.6, 2.6, 2.6), Color3.fromRGB(110, 50, 190), CFrame.new())
        neon(model, Enum.PartType.Block, Vector3.new(0.5, 3.1, 0.5), Color3.fromRGB(190, 140, 255), CFrame.new())
    else
        neon(model, Enum.PartType.Ball, Vector3.new(2, 2, 2), color, CFrame.new())
        neon(model, Enum.PartType.Block, Vector3.new(0.35, 2.4, 0.35), color:Lerp(Color3.new(1, 1, 1), 0.5), CFrame.new())
    end
    model.Parent = frame

    local camera = Instance.new("Camera")
    camera.FieldOfView = 40
    camera.CFrame = CFrame.lookAt(Vector3.new(0, 0.4, 5.2), Vector3.zero)
    camera.Parent = frame
    frame.CurrentCamera = camera

    table.insert(spinners, { frame = frame, model = model, speed = if itemType == "Relic" then 1.4 else 1.0 })
    ensureLoop()
    return frame
end

return ItemViewport
