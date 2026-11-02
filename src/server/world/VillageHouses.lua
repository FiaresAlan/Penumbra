--!strict
-- Monta casas com as peças modulares do MegaKit (ver VillagePieces). A grade é de 2 metros do kit por módulo.
-- A fachada de cada peça aponta para -Z. O telhado tem a cumeeira ao longo de Z (as águas descem para os lados, em X),
-- então as empenas ficam nas paredes da frente e de trás.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VillageAssets = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("VillageAssets") :: ModuleScript)
local VillagePieces = require(script.Parent:WaitForChild("VillagePieces") :: ModuleScript)

local VillageHouses = {}

export type Spec = {
    w: number, -- módulos de largura (3 ou 4)
    d: number, -- módulos de profundidade (3, 4 ou 5 para largura 3; 4 para largura 4)
    wall: string?, -- "Plaster" (padrão) ou "Brick"
    chimney: boolean?,
    shutters: boolean?,
    doorOpen: boolean?, -- sem folha de porta: a abertura fica livre
}

-- O telhado e a empena de cada tamanho, conforme o que foi importado do kit
local ROOFS: { [string]: { roof: string, gable: string } } = {
    ["3x3"] = { roof = "Roof_RoundTiles_6x6", gable = "Roof_Front_Brick6" },
    ["3x4"] = { roof = "Roof_RoundTiles_6x8", gable = "Roof_Front_Brick6" },
    ["3x5"] = { roof = "Roof_RoundTiles_6x10", gable = "Roof_Front_Brick6" },
    ["4x4"] = { roof = "Roof_RoundTiles_8x8", gable = "Roof_Front_Brick8" },
}

local WALLS = {
    Plaster = { straight = "Wall_Plaster_Straight", door = "Wall_Plaster_Door_Round", window = "Wall_Plaster_Window_Wide_Round" },
    Brick = { straight = "Wall_UnevenBrick_Straight", door = "Wall_UnevenBrick_Door_Round", window = "Wall_UnevenBrick_Window_Wide_Round" },
}

local WALL_HEIGHT = 3.12

-- Tamanho da casa em studs (largura X, profundidade Z), para posicionar com o centro no lugar
function VillageHouses.Size(spec: Spec): (number, number)
    local unit = 2 * VillageAssets.Scale
    return spec.w * unit, spec.d * unit
end

-- Cria uma casa. `origin` é o canto da frente à esquerda; a frente (porta) olha para -Z do origin.
function VillageHouses.Build(origin: CFrame, spec: Spec, parent: Instance): Model
    local house = Instance.new("Model")
    house.Name = string.format("Casa%dx%d", spec.w, spec.d)
    local scale = VillageAssets.Scale
    local unit = 2 * scale
    local width, depth = spec.w * unit, spec.d * unit
    local kind = WALLS[spec.wall or "Plaster"]
    local roofs = ROOFS[spec.w .. "x" .. spec.d]
    assert(roofs, "tamanho de casa sem telhado: " .. spec.w .. "x" .. spec.d)
    local doorModule = (spec.w - 1) // 2 -- módulo da porta, no meio da frente

    local function at(x: number, z: number, facing: number): CFrame
        return origin * CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(facing), 0)
    end

    local function windowOn(x: number, z: number, facing: number)
        VillagePieces.Place("Window_Wide_Round1", at(x, z, facing), house)
        if spec.shutters then
            VillagePieces.Place("WindowShutters_Wide_Round_Open", at(x, z, facing), house)
        end
    end

    -- frente e fundo
    for i = 0, spec.w - 1 do
        local x = (i + 0.5) * unit
        if i == doorModule then
            VillagePieces.Place(kind.door, at(x, 0, 0), house)
            if not spec.doorOpen then
                VillagePieces.Place("Door_1_Round", at(x + 0.55 * scale, 0, 0), house)
            end
            VillagePieces.Place("DoorFrame_Round_WoodDark", at(x, 0, 0), house)
        else
            VillagePieces.Place(kind.window, at(x, 0, 0), house)
            windowOn(x, 0, 0)
        end
        VillagePieces.Place(kind.straight, at(x, depth, 180), house)
    end
    -- laterais: uma janela no meio de cada
    for j = 0, spec.d - 1 do
        local z = (j + 0.5) * unit
        local isWindow = j == spec.d // 2
        VillagePieces.Place(if isWindow then kind.window else kind.straight, at(0, z, 90), house)
        VillagePieces.Place(if isWindow then kind.window else kind.straight, at(width, z, -90), house)
        if isWindow then
            windowOn(0, z, 90)
            windowOn(width, z, -90)
        end
    end

    for _, corner in ipairs({ { 0, 0 }, { width, 0 }, { 0, depth }, { width, depth } }) do
        VillagePieces.Place("Corner_Exterior_Wood", origin * CFrame.new(corner[1], 0, corner[2]), house)
    end

    local wallHeight = WALL_HEIGHT * scale
    VillagePieces.Place(roofs.roof, origin * CFrame.new(width / 2, wallHeight - 0.5, depth / 2), house)
    -- empenas: tampam o triângulo da frente e do fundo
    VillagePieces.Place(roofs.gable, origin * CFrame.new(width / 2, wallHeight - 0.4, 0), house)
    VillagePieces.Place(roofs.gable, origin * CFrame.new(width / 2, wallHeight - 0.4, depth) * CFrame.Angles(0, math.rad(180), 0), house)

    if spec.chimney then
        VillagePieces.Place("Prop_Chimney", origin * CFrame.new(width * 0.3, wallHeight + 3, depth * 0.7), house)
    end

    house.Parent = parent
    return house
end

-- Atalho: centro (cx, cz) no mundo, altura y do chão, e para onde a frente olha
-- (0 = -Z norte, 180 = +Z sul, 90 = -X oeste, -90 = +X leste).
function VillageHouses.BuildCentered(cx: number, y: number, cz: number, facing: number, spec: Spec, parent: Instance): Model
    local width, depth = VillageHouses.Size(spec)
    local origin = CFrame.new(cx, y, cz) * CFrame.Angles(0, math.rad(facing), 0) * CFrame.new(-width / 2, 0, -depth / 2)
    return VillageHouses.Build(origin, spec, parent)
end

return VillageHouses
