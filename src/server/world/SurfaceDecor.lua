--!strict
-- Decoração provisória da superfície: árvores simples (tronco e copa), até o R5 trazer o pacote Synty.
-- Fica em workspace.WorldBaked.Forest, salvo no lugar. Nada aqui é criado durante o jogo.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local SurfaceShape = require(script.Parent:WaitForChild("SurfaceShape") :: ModuleScript)

local SurfaceDecor = {}

local B = Config.WorldBounds
local MAX_TREES = 420

local function farFromPads(x: number, z: number, extra: number): boolean
    for _, pad in pairs(Config.WorldPads) do
        if math.sqrt((x - pad.x) ^ 2 + (z - pad.z) ^ 2) < pad.r + extra then
            return false
        end
    end
    return true
end

function SurfaceDecor.Build(root: Folder, log: (string) -> ())
    local forest = Instance.new("Folder")
    forest.Name = "Forest"
    forest.Parent = root

    local rng = Random.new(Config.WorldSeed + 7)
    local placed = 0
    local attempts = 0
    while placed < MAX_TREES and attempts < 8000 do
        attempts += 1
        local x = rng:NextNumber(B.MinX + 60, B.MaxX - 60)
        local z = rng:NextNumber(B.MinZ + 60, B.MaxZ - 60)
        local h = SurfaceShape.HeightAt(x, z)
        local trailDistance = SurfaceShape.TrailDistance(x, z)
        local streamDistance = math.abs(x - SurfaceShape.StreamX(z))
        local slope = math.abs(SurfaceShape.HeightAt(x + 3, z) - h) / 3 + math.abs(SurfaceShape.HeightAt(x, z + 3) - h) / 3
        -- Mais denso para o oeste, onde fica o Mercado Negro; clareiras perto das áreas planas
        local westness = math.clamp((Config.WorldPads.Vila.x - x) / 500 + 0.5, 0.15, 1)
        if h < 40 and slope < 0.45 and trailDistance > 9 and streamDistance > 22 and farFromPads(x, z, 14) and rng:NextNumber() < westness then
            local height = rng:NextNumber(16, 30)
            local trunk = Instance.new("Part")
            trunk.Name = "TreeTrunk"
            trunk.Anchored = true
            trunk.Size = Vector3.new(2.6, height, 2.6)
            trunk.CFrame = CFrame.new(x, h + height / 2 - 0.5, z)
            trunk.Material = Enum.Material.Wood
            trunk.Color = Color3.fromRGB(86, 62, 40)
            trunk.CanTouch = false
            trunk.Parent = forest
            local leaves = Instance.new("Part")
            leaves.Name = "TreeLeaves"
            leaves.Anchored = true
            leaves.Shape = Enum.PartType.Ball
            leaves.Size = Vector3.new(14, 11, 14) * rng:NextNumber(0.85, 1.3)
            leaves.CFrame = CFrame.new(x, h + height + 2, z)
            leaves.Material = Enum.Material.Grass
            leaves.Color = Color3.fromRGB(34, 78, 38)
            leaves.CanCollide = false
            leaves.CanTouch = false
            leaves.CanQuery = false
            leaves.Parent = forest
            placed += 1
        end
    end
    log(string.format("%d árvores provisórias", placed))
end

return SurfaceDecor
