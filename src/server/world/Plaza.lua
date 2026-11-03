--!strict
-- Praças da superfície: a da Mina (spawn e elevador) e a da Vila. Chão de tijolo em manchas irregulares no Terrain,
-- fogueira, estandartes, bancos e barris. Gravado em workspace.WorldBaked.Village pelo BakeVillage, como o resto da vila.
-- Terrain: o material Brick é só das praças (a tabela de materiais da seção 6 do plano).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)

local Plaza = {}

local FLOOR = Config.WorldFloorY
local WOOD = Color3.fromRGB(92, 62, 40)
local WOOD_DARK = Color3.fromRGB(64, 44, 30)

local function newPart(name: string, size: Vector3, cframe: CFrame, material: Enum.Material, color: Color3, parent: Instance): Part
    local part = Instance.new("Part")
    part.Name = name
    part.Anchored = true
    part.Size = size
    part.CFrame = cframe
    part.Material = material
    part.Color = color
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent
    return part
end

-- Chão: um miolo e manchas em volta, para a borda nunca ser um círculo perfeito
local function paintGround(cx: number, cz: number, radius: number, rng: Random)
    local terrain = workspace.Terrain
    -- o cilindro vai de FLOOR-4 até FLOOR: troca só o material da superfície das áreas planas
    terrain:FillCylinder(CFrame.new(cx, FLOOR - 2, cz), 4, radius * 0.7, Enum.Material.Brick)
    for _ = 1, 12 do
        local angle = rng:NextNumber(0, math.pi * 2)
        local distance = rng:NextNumber(radius * 0.45, radius * 0.9)
        local blob = rng:NextNumber(radius * 0.22, radius * 0.45)
        terrain:FillCylinder(CFrame.new(cx + math.cos(angle) * distance, FLOOR - 2, cz + math.sin(angle) * distance), 4, blob, Enum.Material.Brick)
    end
end

-- Banco de madeira: assento e duas pernas, com a frente virada para `yaw` graus
local function bench(x: number, z: number, yaw: number, parent: Instance)
    local base = CFrame.new(x, FLOOR, z) * CFrame.Angles(0, math.rad(yaw), 0)
    newPart("BancoAssento", Vector3.new(6, 0.5, 2), base * CFrame.new(0, 1.9, 0), Enum.Material.WoodPlanks, WOOD, parent)
    newPart("BancoEncosto", Vector3.new(6, 1.6, 0.4), base * CFrame.new(0, 3.1, 0.8) * CFrame.Angles(math.rad(-8), 0, 0), Enum.Material.WoodPlanks, WOOD, parent)
    for _, dx in ipairs({ -2.4, 2.4 }) do
        newPart("BancoPerna", Vector3.new(0.5, 1.7, 1.6), base * CFrame.new(dx, 0.85, 0), Enum.Material.Wood, WOOD_DARK, parent)
    end
end

-- Barril: cilindro de madeira com duas cintas de metal
local function barrel(x: number, z: number, parent: Instance)
    local body = newPart("Barril", Vector3.new(3.6, 3, 3), CFrame.new(x, FLOOR + 1.8, z) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.WoodPlanks, Color3.fromRGB(110, 76, 48), parent)
    body.Shape = Enum.PartType.Cylinder
    for _, dy in ipairs({ -0.9, 0.9 }) do
        local band = newPart("BarrilCinta", Vector3.new(0.25, 3.1, 3.1), CFrame.new(x, FLOOR + 1.8 + dy, z) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Metal, Color3.fromRGB(60, 60, 64), parent)
        band.Shape = Enum.PartType.Cylinder
        band.CanCollide = false
    end
end

-- Estandarte vermelho e dourado em um mastro de madeira, com leve inclinação
local function banner(x: number, z: number, yaw: number, parent: Instance)
    local base = CFrame.new(x, FLOOR, z) * CFrame.Angles(0, math.rad(yaw), math.rad(1.5))
    newPart("EstandarteMastro", Vector3.new(0.7, 16, 0.7), base * CFrame.new(0, 8, 0), Enum.Material.Wood, WOOD_DARK, parent)
    newPart("EstandarteBarra", Vector3.new(5.4, 0.5, 0.5), base * CFrame.new(0, 15, 0), Enum.Material.Wood, WOOD_DARK, parent)
    local cloth = newPart("EstandartePano", Vector3.new(4.4, 8, 0.25), base * CFrame.new(0, 10.8, 0), Enum.Material.Fabric, Color3.fromRGB(150, 44, 36), parent)
    cloth.CanCollide = false
    local stripe = newPart("EstandarteFaixa", Vector3.new(1.2, 8.05, 0.3), base * CFrame.new(0, 10.8, 0), Enum.Material.Fabric, Color3.fromRGB(230, 180, 70), parent)
    stripe.CanCollide = false
    local tip = newPart("EstandartePonta", Vector3.new(4.4, 1.4, 0.25), base * CFrame.new(0, 6.1, 0), Enum.Material.Fabric, Color3.fromRGB(150, 44, 36), parent)
    tip.CanCollide = false
end

-- Fogueira: anel de pedras, toras cruzadas, fogo e luz quente
local function campfire(x: number, z: number, parent: Instance)
    local model = Instance.new("Model")
    model.Name = "Fogueira"
    for index = 1, 9 do
        local angle = index / 9 * math.pi * 2
        newPart("FogueiraPedra", Vector3.new(1.6, 1, 1.4), CFrame.new(x + math.cos(angle) * 3, FLOOR + 0.4, z + math.sin(angle) * 3) * CFrame.Angles(0, angle, 0), Enum.Material.Slate, Color3.fromRGB(110, 108, 106), model)
    end
    newPart("FogueiraTora", Vector3.new(0.9, 0.9, 4.2), CFrame.new(x, FLOOR + 0.6, z) * CFrame.Angles(0, math.rad(30), math.rad(12)), Enum.Material.Wood, WOOD_DARK, model)
    newPart("FogueiraTora", Vector3.new(0.9, 0.9, 4.2), CFrame.new(x, FLOOR + 0.6, z) * CFrame.Angles(0, math.rad(-35), math.rad(-12)), Enum.Material.Wood, WOOD_DARK, model)
    local core = newPart("FogueiraFogo", Vector3.new(1.4, 1.4, 1.4), CFrame.new(x, FLOOR + 1.4, z), Enum.Material.Neon, Color3.fromRGB(255, 150, 60), model)
    core.CanCollide = false
    core.Transparency = 0.4
    local fire = Instance.new("Fire")
    fire.Heat = 8
    fire.Size = 7
    fire.Color = Color3.fromRGB(255, 150, 60)
    fire.SecondaryColor = Color3.fromRGB(200, 50, 20)
    fire.Parent = core
    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(255, 170, 90)
    light.Range = 38
    light.Brightness = 1.6
    light.Parent = core
    model.Parent = parent
end

function Plaza.Build(parent: Instance, log: (string) -> ())
    local folder = Instance.new("Folder")
    folder.Name = "Pracas"
    folder.Parent = parent
    local rng = Random.new(Config.MapSeed + 11)

    -- Mina: spawn e elevador
    paintGround(26, 0, 46, rng)
    campfire(10, -16, folder)
    banner(-12, -18, 20, folder)
    banner(-12, 18, -20, folder)
    banner(28, -28, 8, folder)
    bench(4, 12, 90, folder)
    bench(18, -30, 180, folder)
    barrel(8, 31, folder)
    barrel(11, 33, folder)
    barrel(6, 34, folder)

    -- Vila
    local vila = Config.WorldPads.Vila
    paintGround(vila.x, vila.z, 38, rng)
    campfire(vila.x - 18, vila.z + 14, folder)
    bench(vila.x + 16, vila.z + 14, 200, folder)
    bench(vila.x - 18, vila.z - 16, 20, folder)
    bench(vila.x + 20, vila.z - 16, -20, folder)
    banner(vila.x + 6, vila.z - 26, 12, folder)
    banner(vila.x - 8, vila.z + 28, 190, folder)
    barrel(vila.x - 22, vila.z - 36, folder)
    barrel(vila.x - 25, vila.z - 34, folder)

    log("praças: chão de tijolo, 2 fogueiras, 5 estandartes, 5 bancos e 5 barris")
end

return Plaza
