--!strict
-- V5: o item girando dentro de um ViewportFrame (no lugar do emoji): núcleo é uma esfera de néon na cor da raridade,
-- núcleo denso é maior e roxo, relíquia é um cristal rosa com uma esfera. Uma só rotina gira todos os que estão na tela.
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require((script.Parent :: Instance):WaitForChild("Theme") :: ModuleScript)
local ItemVisuals = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ItemVisuals") :: ModuleScript)

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
                local rotation = CFrame.Angles(0.25, angle * spinner.speed, 0)
                if spinner.model:FindFirstChild("ItemVisual") then
                    rotation = rotation * ItemVisuals.StandUp
                end
                spinner.model:PivotTo(rotation)
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
    -- F2: o modelo 3D do item (ItemVisuals); sem ele, as formas simples de antes
    local visual = ItemVisuals.Create(itemType, rarity, #spinners + (string.byte(rarity, 1) or 0))
    if visual then
        visual.CFrame = ItemVisuals.StandUp
        visual.Parent = model
    elseif itemType == "Relic" then
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

-- V4: baú 3D com tampa que abre e um brilho dourado dentro. Devolve o ViewportFrame e a função que abre a tampa.
function ItemViewport.CreateChest(parent: Instance, size: UDim2, position: UDim2): (ViewportFrame, () -> ())
    local frame = Instance.new("ViewportFrame")
    frame.BackgroundTransparency = 1
    frame.Size = size
    frame.Position = position
    frame.Ambient = Color3.fromRGB(150, 150, 160)
    frame.LightColor = Color3.fromRGB(255, 244, 220)
    frame.LightDirection = Vector3.new(-1, -1, -1)
    frame.Parent = parent

    local model = Instance.new("Model")
    model.Name = "Bau"
    local wood = Color3.fromRGB(112, 74, 44)
    local gold = Color3.fromRGB(226, 178, 62)
    local function block(name: string, blockSize: Vector3, cframe: CFrame, color: Color3, material: Enum.Material): Part
        local p = Instance.new("Part")
        p.Name = name
        p.Size = blockSize
        p.CFrame = cframe
        p.Color = color
        p.Material = material
        p.Anchored = true
        p.CanCollide = false
        p.Parent = model
        return p
    end
    block("Corpo", Vector3.new(3, 1.6, 2), CFrame.new(0, 0.8, 0), wood, Enum.Material.Wood)
    block("FaixaE", Vector3.new(0.3, 1.7, 2.1), CFrame.new(-1.1, 0.8, 0), gold, Enum.Material.Metal)
    block("FaixaD", Vector3.new(0.3, 1.7, 2.1), CFrame.new(1.1, 0.8, 0), gold, Enum.Material.Metal)
    local glow = block("Brilho", Vector3.new(2.4, 0.2, 1.4), CFrame.new(0, 1.62, 0), Color3.fromRGB(255, 220, 120), Enum.Material.Neon)
    glow.Transparency = 1
    local lid = block("Tampa", Vector3.new(3.1, 0.7, 2.1), CFrame.new(0, 1.95, 0), wood, Enum.Material.Wood)
    local hinge = CFrame.new(0, 1.6, -1)
    local opened = 0
    model.Parent = frame

    local camera = Instance.new("Camera")
    camera.FieldOfView = 40
    camera.CFrame = CFrame.lookAt(Vector3.new(0, 4.2, 7), Vector3.new(0, 1.2, 0))
    camera.Parent = frame
    frame.CurrentCamera = camera

    local function open()
        task.spawn(function()
            for step = 1, 20 do
                opened = step / 20
                lid.CFrame = hinge * CFrame.Angles(-math.rad(75) * opened, 0, 0) * CFrame.new(0, 0.35 + 0.0, 1) * CFrame.new(0, 0, 0)
                glow.Transparency = 1 - opened * 0.7
                task.wait(0.03)
            end
        end)
    end
    return frame, open
end

return ItemViewport
