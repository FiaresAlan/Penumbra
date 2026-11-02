--!strict
-- Forma do mundo da superfície: altura, material e distância das trilhas em qualquer ponto (x, z).
-- Funções puras, sem criar nada: servem para gerar o terreno e para posicionar árvores e construções.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)

local SurfaceShape = {}

local B = Config.WorldBounds
local SEED = Config.WorldSeed * 0.001
local FLOOR = Config.WorldFloorY
local STREAM = Config.WorldStream
local MOUNTAINS = Config.WorldMountains

local function smooth(t: number): number
    t = math.clamp(t, 0, 1)
    return t * t * (3 - 2 * t)
end

local function lerp(a: number, b: number, t: number): number
    return a + (b - a) * t
end

-- Segmentos das trilhas, calculados uma vez: { ax, az, dx, dz, comprimento ao quadrado, largura }
local segments: { { number } } = {}
for _, trail in ipairs(Config.WorldTrails) do
    for index = 1, #trail.points - 1 do
        local a, b = trail.points[index], trail.points[index + 1]
        local dx, dz = b[1] - a[1], b[2] - a[2]
        table.insert(segments, { a[1], a[2], dx, dz, dx * dx + dz * dz, trail.width })
    end
end

-- Distância até a trilha mais próxima (descontada a meia largura) e a largura dela.
function SurfaceShape.TrailDistance(x: number, z: number): (number, number)
    local best, bestWidth = 9999, 0
    for _, s in ipairs(segments) do
        local t = math.clamp(((x - s[1]) * s[3] + (z - s[2]) * s[4]) / s[5], 0, 1)
        local ex, ez = x - (s[1] + s[3] * t), z - (s[2] + s[4] * t)
        local d = math.sqrt(ex * ex + ez * ez) - s[6] / 2
        if d < best then
            best, bestWidth = d, s[6]
        end
    end
    return math.max(best, 0), bestWidth
end

function SurfaceShape.StreamX(z: number): number
    return STREAM.x + STREAM.amp * math.sin(z / STREAM.period)
end

-- Peso da área plana mais próxima: 1 dentro do raio, caindo a 0 em 60 studs.
local function padWeight(x: number, z: number): number
    local weight = 0
    for _, pad in pairs(Config.WorldPads) do
        local d = math.sqrt((x - pad.x) ^ 2 + (z - pad.z) ^ 2)
        weight = math.max(weight, 1 - smooth((d - pad.r) / 60))
    end
    return weight
end

function SurfaceShape.HeightAt(x: number, z: number): number
    local mina = Config.WorldPads.Mina
    local distMina = math.sqrt((x - mina.x) ^ 2 + (z - mina.z) ^ 2)
    -- Colinas crescem com a distância da mina: o vale perto do elevador é calmo
    local amplitude = 5 + 18 * smooth((distMina - 120) / 250)
    local trailDistance = SurfaceShape.TrailDistance(x, z)
    local soften = 0.2 + 0.8 * smooth((trailDistance - 3) / 26)
    local big = math.noise(x / 130, z / 130, SEED) * 0.5 + 0.5
    local small = math.noise(x / 45, z / 45, SEED + 10) * 0.5 + 0.5
    local h = FLOOR + amplitude * soften * (big + 0.3 * small) / 1.3

    h = lerp(h, FLOOR, padWeight(x, z))

    -- Montanhas ao longo da borda: altas e irregulares, para esconder o fim do mundo
    local edge = math.min(x - B.MinX, B.MaxX - x, z - B.MinZ, B.MaxZ - z)
    local ridgeWeight = smooth(1 - edge / MOUNTAINS.edge)
    if ridgeWeight > 0 then
        local ridge = 0.6 + 0.4 * (math.noise(x / 70, z / 70, SEED + 30) * 0.5 + 0.5) + 0.25 * math.noise(x / 24, z / 24, SEED + 31)
        h += ridgeWeight * ridgeWeight * MOUNTAINS.height * ridge
    end

    -- Riacho: leito afundado, que some perto das bordas norte e sul
    local streamFade = 1 - smooth((math.abs(z) - 300) / 60)
    if streamFade > 0 then
        local distance = math.abs(x - SurfaceShape.StreamX(z))
        if distance < STREAM.halfWidth + STREAM.bank then
            local bed = lerp(STREAM.bedY, h, smooth((distance - STREAM.halfWidth * 0.5) / (STREAM.halfWidth * 0.5 + STREAM.bank)))
            h = lerp(h, math.min(h, bed), streamFade)
        end
    end
    return math.max(h, STREAM.bedY)
end

-- Material da superfície. `slope` é a inclinação (diferença de altura por stud).
function SurfaceShape.MaterialAt(x: number, z: number, h: number, slope: number): Enum.Material
    local trailDistance, trailWidth = SurfaceShape.TrailDistance(x, z)
    if trailWidth > 0 and trailDistance < 1.5 then
        return Enum.Material.Mud
    end
    if math.abs(x - SurfaceShape.StreamX(z)) < STREAM.halfWidth + 5 and h < FLOOR + 1.2 and math.abs(z) < 340 then
        return Enum.Material.Sand
    end
    if slope > 1 or h > 70 then
        return Enum.Material.Rock
    end
    if math.noise(x / 25, z / 25, SEED + 40) > 0.15 then
        return Enum.Material.LeafyGrass
    end
    return Enum.Material.Grass
end

return SurfaceShape
