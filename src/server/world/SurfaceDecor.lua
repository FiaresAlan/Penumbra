--!strict
-- Floresta e natureza da superfície, com as peças do Synty Nature Pack (ver NatureLibrary).
-- Tudo fica em workspace.WorldBaked, salvo no lugar. Nada daqui é criado durante o jogo.
-- Se o pacote não carregar, cai para árvores provisórias (tronco e bola).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local SurfaceShape = require(script.Parent:WaitForChild("SurfaceShape") :: ModuleScript)
local NatureLibrary = require(script.Parent:WaitForChild("NatureLibrary") :: ModuleScript)

local SurfaceDecor = {}

local B = Config.WorldBounds
local MAX_TREES = 3400
local MAX_DETAILS = 5200
local TREE_GRID = 19
local DETAIL_GRID = 12

-- Clareiras com adereços (ruína e acampamento abandonado): sem árvores nem detalhes dentro do raio
local CLEARINGS = {
    { name = "Ruina", x = -420, z = 210, r = 30 },
    { name = "Acampamento", x = -880, z = -190, r = 24 },
}

local CONIFERS = { "Pine_Tree_Pine", "Pine_Tree_Pine_Large", "Pine_Tree_Pine_Small", "PolygonNature_Tree_PolyPine" }
local BROADLEAF = { "PolygonNature_Tree", "PolygonNature_Tree_04", "PolygonNature_Tree_Round", "PolygonNature_Tree_TallRound" }
local BIRCH = { "Birch_Tree_Generic" }
local DEAD = { "PolygonNature_Tree_Swamp", "PolygonNature_Tree_Pine_Dead", "Leaves_Tree_Dead", "dead_branches", "small_dead_tree" }
local BUSHES = { "PolygonNature_Plant_Bush", "PolygonNature_Plant_Hedge_Bush", "PolygonNature_Plant_PalmBush" }
local FERNS = { "PolygonNature_Plant_Fern", "Fern_Plant_Fern_Leaves" }
local SMALL_PLANTS = { "PolygonNature_Plant", "PolygonNature_Plant_Grass" }
local FLOWERS = { "PolygonNature_Plant_Flowers", "PurpleFlower" }
local MUSHROOMS = { "PolygonNature_Plant_Mushrooms" }
local SMALL_ROCKS = { "PolygonNature_Rock", "PolygonNature_Rock_Small", "PolygonNature_Rock_Rounded", "PolygonNature_Rock_Boulder" }
local BIG_ROCKS = { "PolygonNature_Rock_Cluster_Large", "PolygonNature_Rock_Pile", "PolygonNature_Rock_Pile_Curved", "PolygonNature_Rock_Wall" }
local LOGS = { "PolygonNature_Tree_Log", "PolygonNature_Tree_Stump", "PolygonNature_Tree_Branch" }

type Library = { [string]: { MeshPart } }

local function inClearing(x: number, z: number, extra: number): boolean
    for _, clearing in ipairs(CLEARINGS) do
        if math.sqrt((x - clearing.x) ^ 2 + (z - clearing.z) ^ 2) < clearing.r + extra then
            return true
        end
    end
    return false
end

local function nearPad(x: number, z: number, extra: number): boolean
    for _, pad in pairs(Config.WorldPads) do
        if math.sqrt((x - pad.x) ^ 2 + (z - pad.z) ^ 2) < pad.r + extra then
            return true
        end
    end
    return false
end

-- Escolhe uma peça do grupo de nomes, que existam na biblioteca
local function pick(library: Library, names: { string }, rng: Random): MeshPart?
    for _ = 1, 4 do
        local group = library[names[rng:NextInteger(1, #names)]]
        if group and #group > 0 then
            return group[rng:NextInteger(1, #group)]
        end
    end
    return nil
end

-- Cria uma cópia da peça no chão, com altura-alvo (ou escala fixa se targetHeight for nil)
local function plant(template: MeshPart, x: number, z: number, targetHeight: number?, rng: Random, parent: Instance, collide: boolean): MeshPart
    local scale = if targetHeight then math.clamp(targetHeight / math.max(template.Size.Y, 0.1), 0.4, 3) else rng:NextNumber(0.85, 1.25)
    local mesh = template:Clone()
    mesh.Anchored = true
    mesh.CanCollide = collide
    mesh.CanTouch = false
    mesh.CanQuery = false
    mesh.Size = template.Size * scale
    local h = SurfaceShape.HeightAt(x, z)
    mesh.CFrame = CFrame.new(x, h + mesh.Size.Y / 2 - 0.35, z) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
    mesh.Parent = parent
    return mesh
end

-- Colisão só no tronco: uma peça invisível, para não pesar com a malha inteira
local function trunkCollider(mesh: MeshPart, parent: Instance)
    local height = mesh.Size.Y
    local width = math.clamp(math.min(mesh.Size.X, mesh.Size.Z) * 0.16, 1.2, 4)
    local collider = Instance.new("Part")
    collider.Name = "Tronco"
    collider.Anchored = true
    collider.Transparency = 1
    collider.CanQuery = false
    collider.CanTouch = false
    collider.Size = Vector3.new(width, height * 0.55, width)
    collider.CFrame = CFrame.new(mesh.Position.X, mesh.Position.Y - height / 2 + height * 0.275, mesh.Position.Z)
    collider.Parent = parent
end

-- Região do mapa: define a mistura de espécies e a densidade
local function biome(x: number, z: number): (string, number)
    local black = Config.WorldPads.MercadoNegro
    local distBlack = math.sqrt((x - black.x) ^ 2 + (z - black.z) ^ 2)
    if distBlack < 230 then
        return "sombria", 0.95
    elseif x > -140 then
        return "campo", 0.3
    elseif x > -540 then
        return "mista", 0.65
    elseif x > -760 then
        return "vila", 0.22
    end
    return "profunda", 0.9
end

local function chooseTree(library: Library, region: string, rng: Random): (MeshPart?, number, boolean)
    local roll = rng:NextNumber()
    if region == "campo" then
        if roll < 0.7 then
            return pick(library, BROADLEAF, rng), rng:NextNumber(20, 34), true
        end
        return pick(library, BIRCH, rng), rng:NextNumber(22, 30), true
    elseif region == "mista" then
        if roll < 0.5 then
            return pick(library, CONIFERS, rng), rng:NextNumber(26, 46), true
        elseif roll < 0.9 then
            return pick(library, BROADLEAF, rng), rng:NextNumber(22, 36), true
        end
        return pick(library, BIRCH, rng), rng:NextNumber(22, 30), true
    elseif region == "vila" then
        if roll < 0.6 then
            return pick(library, BROADLEAF, rng), rng:NextNumber(20, 32), true
        end
        return pick(library, CONIFERS, rng), rng:NextNumber(24, 40), true
    elseif region == "sombria" then
        if roll < 0.55 then
            return pick(library, DEAD, rng), rng:NextNumber(14, 28), true
        end
        return pick(library, CONIFERS, rng), rng:NextNumber(30, 52), true
    end
    if roll < 0.86 then
        return pick(library, CONIFERS, rng), rng:NextNumber(28, 52), true
    end
    return pick(library, DEAD, rng), rng:NextNumber(14, 26), true
end

-- Árvores, em grade com deslocamento: bosques e clareiras por ruído, nada sobre trilhas, riacho ou áreas planas
local function buildTrees(library: Library, forest: Folder, rng: Random, log: (string) -> ())
    local placed = 0
    local seed = Config.WorldSeed * 0.001
    local cellCount = 0
    local x0 = B.MinX + 40
    while x0 < B.MaxX - 40 and placed < MAX_TREES do
        local z0 = B.MinZ + 40
        while z0 < B.MaxZ - 40 and placed < MAX_TREES do
            cellCount += 1
            if cellCount % 200 == 0 then
                task.wait()
            end
            local x = x0 + rng:NextNumber(-TREE_GRID / 2, TREE_GRID / 2)
            local z = z0 + rng:NextNumber(-TREE_GRID / 2, TREE_GRID / 2)
            local region, density = biome(x, z)
            local grove = math.noise(x / 160, z / 160, seed + 3) * 0.5 + 0.5
            density *= math.clamp(grove * 1.3 + 0.25, 0.15, 1.4)
            if math.noise(x / 90, z / 90, seed + 5) > 0.42 then
                density *= 0.15 -- clareira
            end
            if rng:NextNumber() < density and not inClearing(x, z, 12) and not nearPad(x, z, 12) then
                local h = SurfaceShape.HeightAt(x, z)
                local trailDistance = SurfaceShape.TrailDistance(x, z)
                local streamDistance = math.abs(x - SurfaceShape.StreamX(z))
                local slope = (math.abs(SurfaceShape.HeightAt(x + 3, z) - h) + math.abs(SurfaceShape.HeightAt(x, z + 3) - h)) / 3
                if h < 60 and slope < 0.7 and trailDistance > 8 and (streamDistance > 22 or math.abs(z) > 330) then
                    local template, height, collide = chooseTree(library, region, rng)
                    if template then
                        local mesh = plant(template, x, z, height, rng, forest, false)
                        if collide and mesh.Size.Y >= 14 then
                            trunkCollider(mesh, forest)
                        end
                        placed += 1
                    end
                end
            end
            z0 += TREE_GRID
        end
        x0 += TREE_GRID
    end
    log(string.format("%d árvores", placed))
end

-- Arbustos, samambaias, flores, cogumelos, pedras e troncos caídos, em manchas
local function buildDetails(library: Library, details: Folder, rng: Random, log: (string) -> ())
    local placed = 0
    local seed = Config.WorldSeed * 0.001
    local cellCount = 0
    local x0 = B.MinX + 40
    while x0 < B.MaxX - 40 and placed < MAX_DETAILS do
        local z0 = B.MinZ + 40
        while z0 < B.MaxZ - 40 and placed < MAX_DETAILS do
            cellCount += 1
            if cellCount % 300 == 0 then
                task.wait()
            end
            local x = x0 + rng:NextNumber(-DETAIL_GRID / 2, DETAIL_GRID / 2)
            local z = z0 + rng:NextNumber(-DETAIL_GRID / 2, DETAIL_GRID / 2)
            local patch = math.noise(x / 55, z / 55, seed + 9) * 0.5 + 0.5
            local region, forestDensity = biome(x, z)
            if rng:NextNumber() < (0.18 + 0.55 * patch) * math.clamp(forestDensity + 0.3, 0.3, 1) and not inClearing(x, z, 4) and not nearPad(x, z, 6) then
                local h = SurfaceShape.HeightAt(x, z)
                local trailDistance = SurfaceShape.TrailDistance(x, z)
                local streamDistance = math.abs(x - SurfaceShape.StreamX(z))
                local slope = (math.abs(SurfaceShape.HeightAt(x + 3, z) - h) + math.abs(SurfaceShape.HeightAt(x, z + 3) - h)) / 3
                if h < 70 and trailDistance > 2.5 and (streamDistance > 6 or math.abs(z) > 330) then
                    local roll = rng:NextNumber()
                    local template: MeshPart? = nil
                    local height: number? = nil
                    local collide = false
                    if streamDistance < 18 and math.abs(z) < 330 then
                        template = pick(library, { "PolygonNature_Plant_Reeds" }, rng)
                    elseif slope > 0.35 then
                        template = pick(library, if roll < 0.15 then BIG_ROCKS else SMALL_ROCKS, rng)
                        collide = template ~= nil and template.Size.Y > 6
                    elseif roll < 0.30 then
                        template = pick(library, BUSHES, rng)
                    elseif roll < 0.45 then
                        template = pick(library, FERNS, rng)
                    elseif roll < 0.62 then
                        template = pick(library, SMALL_PLANTS, rng)
                    elseif roll < 0.74 then
                        template = pick(library, if region == "campo" or trailDistance < 12 then FLOWERS else MUSHROOMS, rng)
                    elseif roll < 0.88 then
                        template = pick(library, SMALL_ROCKS, rng)
                    elseif roll < 0.96 then
                        template = pick(library, LOGS, rng)
                    else
                        template = pick(library, BIG_ROCKS, rng)
                        collide = true
                        height = nil
                    end
                    if template then
                        plant(template, x, z, height, rng, details, collide)
                        placed += 1
                    end
                end
            end
            z0 += DETAIL_GRID
        end
        x0 += DETAIL_GRID
    end
    log(string.format("%d detalhes", placed))
end

-- Adereços das clareiras: ruína de pedra e acampamento abandonado
local function buildClearings(library: Library, props: Folder, rng: Random)
    local ruin = { "PolygonNature_Prop_Pillar", "PolygonNature_Prop_Pillar_Broken", "PolygonNature_Prop_Pillar_Moss", "PolygonNature_Prop_Pillar_Broken_Moss", "PolygonNature_Prop_Pillar_Arch_Broken", "PolygonNature_Prop_Pillar_Arch_Moss", "PolygonNature_Prop_StoneWall", "PolygonNature_Prop_Brick" }
    local camp = { "PolygonNature_Prop_Fence", "PolygonNature_Prop_TorchStick", "PolygonNature_Prop_RoadSign", "PolygonNature_Prop_Chest_Wood" }
    for index, clearing in ipairs(CLEARINGS) do
        local names = if index == 1 then ruin else camp
        for step = 1, if index == 1 then 11 else 6 do
            local angle = (step / 11) * math.pi * 2 + rng:NextNumber(-0.3, 0.3)
            local radius = rng:NextNumber(5, clearing.r - 6)
            local template = pick(library, names, rng)
            if template then
                plant(template, clearing.x + math.cos(angle) * radius, clearing.z + math.sin(angle) * radius, nil, rng, props, true)
            end
        end
        if index == 2 then
            local fire = pick(library, { "PolygonNature_Prop_CampFire" }, rng)
            if fire then
                plant(fire, clearing.x, clearing.z, nil, rng, props, false)
            end
        end
        for _ = 1, 5 do
            local angle = rng:NextNumber(0, math.pi * 2)
            local rock = pick(library, SMALL_ROCKS, rng)
            if rock then
                plant(rock, clearing.x + math.cos(angle) * rng:NextNumber(8, clearing.r), clearing.z + math.sin(angle) * rng:NextNumber(8, clearing.r), nil, rng, props, false)
            end
        end
    end
end

-- Ponte curva sobre o riacho, no ponto onde a trilha principal o cruza
local function buildBridge(library: Library, props: Folder, log: (string) -> ())
    local bridge = library["PolygonNature_Prop_Bridge_Curved"]
    if not bridge or #bridge == 0 then
        return
    end
    local best, bx, bz = 9999, 0, 0
    local points = Config.WorldTrails[1].points
    for index = 1, #points - 1 do
        local a, b = points[index], points[index + 1]
        for step = 0, 40 do
            local t = step / 40
            local x, z = a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t
            local d = math.abs(x - SurfaceShape.StreamX(z))
            if d < best then
                best, bx, bz = d, x, z
            end
        end
    end
    -- Direção perpendicular ao riacho (a tangente do riacho tem inclinação dx/dz)
    local slope = Config.WorldStream.amp / Config.WorldStream.period * math.cos(bz / Config.WorldStream.period)
    local direction = Vector3.new(1, 0, -slope).Unit
    local base = math.max(SurfaceShape.HeightAt(bx + direction.X * 16, bz + direction.Z * 16), SurfaceShape.HeightAt(bx - direction.X * 16, bz - direction.Z * 16))
    local template = bridge[1]
    local mesh = template:Clone()
    mesh.Anchored = true
    mesh.CanCollide = true
    mesh.CanTouch = false
    mesh.CanQuery = true
    mesh.Size = template.Size * 1.25
    mesh.CFrame = CFrame.lookAt(Vector3.new(bx, base + mesh.Size.Y / 2 - 0.9, bz), Vector3.new(bx, base + mesh.Size.Y / 2 - 0.9, bz) + direction)
    mesh.Parent = props
    log(string.format("ponte em (%.0f, %.0f)", bx, bz))
end

-- Árvores provisórias, usadas só se o pacote Synty não carregar
local function buildProvisional(forest: Folder, rng: Random)
    for _ = 1, 300 do
        local x = rng:NextNumber(B.MinX + 60, B.MaxX - 60)
        local z = rng:NextNumber(B.MinZ + 60, B.MaxZ - 60)
        local h = SurfaceShape.HeightAt(x, z)
        if h < 40 and SurfaceShape.TrailDistance(x, z) > 9 and not nearPad(x, z, 14) then
            local height = rng:NextNumber(16, 30)
            local trunk = Instance.new("Part")
            trunk.Name = "TreeTrunk"
            trunk.Anchored = true
            trunk.Size = Vector3.new(2.6, height, 2.6)
            trunk.CFrame = CFrame.new(x, h + height / 2 - 0.5, z)
            trunk.Color = Color3.fromRGB(86, 62, 40)
            trunk.Parent = forest
            local leaves = Instance.new("Part")
            leaves.Name = "TreeLeaves"
            leaves.Anchored = true
            leaves.Shape = Enum.PartType.Ball
            leaves.Size = Vector3.new(14, 11, 14)
            leaves.CFrame = CFrame.new(x, h + height + 2, z)
            leaves.Color = Color3.fromRGB(34, 78, 38)
            leaves.CanCollide = false
            leaves.Parent = forest
        end
    end
end

function SurfaceDecor.Build(root: Folder, log: (string) -> ())
    -- Refaz só a floresta, os detalhes e os adereços: a vila (outra pasta) fica como está
    for _, name in ipairs({ "Forest", "Details", "Props" }) do
        local existing = root:FindFirstChild(name)
        if existing then
            existing:Destroy()
        end
    end
    local forest = Instance.new("Folder")
    forest.Name = "Forest"
    forest.Parent = root
    local details = Instance.new("Folder")
    details.Name = "Details"
    details.Parent = root
    local props = Instance.new("Folder")
    props.Name = "Props"
    props.Parent = root

    local rng = Random.new(Config.WorldSeed + 7)
    local library = NatureLibrary.Load(log)
    if not library then
        log("usando árvores provisórias")
        buildProvisional(forest, rng)
        return
    end
    buildTrees(library, forest, rng, log)
    buildDetails(library, details, rng, log)
    buildClearings(library, props, rng)
    buildBridge(library, props, log)
end

-- Conta scripts onde não pode haver nenhum: o cenário salvo e a biblioteca de assets
function SurfaceDecor.CountScripts(): number
    local count = 0
    for _, container in ipairs({ workspace:FindFirstChild("WorldBaked"), game:GetService("ServerStorage"):FindFirstChild("EcosAssets") }) do
        if container then
            for _, descendant in ipairs(container:GetDescendants()) do
                if descendant:IsA("LuaSourceContainer") then
                    count += 1
                end
            end
        end
    end
    return count
end

return SurfaceDecor
