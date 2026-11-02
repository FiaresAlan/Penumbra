--!strict
-- Monta casas com as peças modulares do MegaKit (ver VillagePieces). A grade é de 2 metros do kit por módulo.
-- A fachada exterior de cada parede aponta para -Z da peça.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VillageAssets = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("VillageAssets") :: ModuleScript)
local VillagePieces = require(script.Parent:WaitForChild("VillagePieces") :: ModuleScript)

local VillageHouses = {}

-- Uma parede do módulo, com o rosto de fora virado para `facing` (graus em torno de Y: 0 = -Z, 90 = -X, 180 = +Z, -90 = +X)
local function wall(piece: string, origin: CFrame, x: number, z: number, facing: number, parent: Instance)
    VillagePieces.Place(piece, origin * CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(facing), 0), parent)
end

-- Casa de 4 x 4 módulos, um andar, com porta no meio da frente e telhado de telhas.
-- `origin` é o canto da frente à esquerda (olhando para a casa pelo lado de fora, -Z).
function VillageHouses.Small(origin: CFrame, parent: Instance): Model
    local house = Instance.new("Model")
    house.Name = "CasaPequena"
    local unit = 2 * VillageAssets.Scale
    local size = 4

    for i = 0, size - 1 do
        local center = (i + 0.5) * unit
        -- frente: duas janelas, porta, janela
        local front = if i == 2 then "Wall_Plaster_Door_Round" else "Wall_Plaster_Window_Wide_Round"
        wall(front, origin, center, 0, 0, house)
        wall("Wall_Plaster_Straight", origin, center, size * unit, 180, house)
        wall(if i == 1 then "Wall_Plaster_Window_Wide_Round" else "Wall_Plaster_Straight", origin, 0, center, 90, house)
        wall(if i == 2 then "Wall_Plaster_Window_Wide_Round" else "Wall_Plaster_Straight", origin, size * unit, center, -90, house)
    end

    for _, corner in ipairs({ { 0, 0 }, { size * unit, 0 }, { 0, size * unit }, { size * unit, size * unit } }) do
        VillagePieces.Place("Corner_Exterior_Wood", origin * CFrame.new(corner[1], 0, corner[2]), house)
    end

    for i = 0, size - 1 do
        for j = 0, size - 1 do
            VillagePieces.Place("Floor_WoodDark", origin * CFrame.new((i + 0.5) * unit, 0.05, (j + 0.5) * unit), house)
        end
    end

    local wallHeight = 3.12 * VillageAssets.Scale
    local center = size * unit / 2
    VillagePieces.Place("Roof_RoundTiles_6x6", origin * CFrame.new(center, wallHeight - 0.5, center), house)
    VillagePieces.Place("Prop_Chimney", origin * CFrame.new(center + 6, wallHeight + 6, center + 4), house)

    house.Parent = parent
    return house
end

return VillageHouses
