--!strict
-- C1: forma da caverna em Terrain. Funções puras sobre a grade do labirinto (a grade continua sendo a fonte da verdade):
-- IsOpen (parede com reentrâncias), FloorAt (relevo do chão) e CeilingAt (teto). Usadas na geração do Terrain e na partida,
-- para núcleos, decoração e marcadores ficarem sobre o chão de verdade.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local Layout = require(script.Parent:WaitForChild("CaveLayout") :: ModuleScript)

local CELL = Layout.CELL
local COLS = Layout.COLS
local ROWS = Layout.ROWS
local WALL_H = Layout.WALL_H
local ORIGIN_X = Layout.ORIGIN_X
local ORIGIN_Z = Layout.ORIGIN_Z
local FLOOR_Y = Layout.FLOOR_Y

local MIN_CLEARANCE = 13 -- o Guardião tem AgentHeight 9: o vão nunca fica abaixo disso
local POND_DEPTH = 1.0
local POND_RADIUS = 8

local CaveShape = {}

-- Parâmetros ajustáveis (o QA e a Command Bar podem mudá-los para testar). O padrão vem do Config; o "or" cobre o cache de
-- módulos do Studio, que pode devolver um Config antigo.
CaveShape.Params = {
    warp = Config.CaveWarp or 4,
    relief = Config.CaveFloorRelief or 3.5,
}

local grid: Layout.Grid? = nil
local seed = Config.MapSeed * 0.013

local function clamp1(value: number): number
    return math.clamp(value, -1, 1)
end

local function smooth(t: number): number
    t = math.clamp(t, 0, 1)
    return t * t * (3 - 2 * t)
end

local function cellOf(x: number, z: number): (number, number)
    return math.floor((x - ORIGIN_X) / CELL), math.floor((z - ORIGIN_Z) / CELL)
end

local function isOpenCell(c: number, r: number): boolean
    local g = grid
    if not g or c < 0 or c >= COLS or r < 0 or r >= ROWS then
        return false
    end
    return g[r][c]
end

-- Distância (em studs) de um ponto até um retângulo de células; 0 dentro
local function distanceToRect(x: number, z: number, rect: Layout.Rect): number
    local x0 = ORIGIN_X + rect.c0 * CELL
    local x1 = ORIGIN_X + (rect.c1 + 1) * CELL
    local z0 = ORIGIN_Z + rect.r0 * CELL
    local z1 = ORIGIN_Z + (rect.r1 + 1) * CELL
    local dx = math.max(x0 - x, 0, x - x1)
    local dz = math.max(z0 - z, 0, z - z1)
    return math.sqrt(dx * dx + dz * dz)
end

-- Zona B com lagoa: célula de lagoa é decidida só pelos índices, sem sorteio
function CaveShape.IsPond(c: number, r: number): boolean
    return c >= 10 and c <= 18 and isOpenCell(c, r) and not Layout.isSpecial(c, r) and (c * 7 + r * 3) % 4 == 0
end

function CaveShape.Bind(newGrid: Layout.Grid)
    grid = newGrid
    Layout.Hooks.floorAt = CaveShape.FloorAt
    Layout.Hooks.ceilingAt = CaveShape.CeilingAt
end

-- Parede: desloca o ponto com ruído (no máximo Config.CaveWarp studs) e só então consulta a célula
function CaveShape.IsOpen(x: number, z: number): boolean
    local warp = CaveShape.Params.warp
    local wx = x + clamp1(math.noise(x / 24, z / 24, seed + 1) * 2) * warp + clamp1(math.noise(x / 9, z / 9, seed + 7)) * warp * 0.3
    local wz = z + clamp1(math.noise(x / 24, z / 24, seed + 2) * 2) * warp + clamp1(math.noise(x / 9, z / 9, seed + 8)) * warp * 0.3
    local c, r = cellOf(wx, wz)
    return isOpenCell(c, r)
end

local function reliefMask(x: number, z: number): number
    local entrance = smooth(distanceToRect(x, z, Layout.ENTRANCE) / 14)
    local nest = smooth(distanceToRect(x, z, Layout.NEST) / 14)
    local chamber = 0.45 + 0.55 * smooth(distanceToRect(x, z, Layout.CHAMBER) / 14)
    return math.min(entrance, nest, chamber)
end

-- Influência das lagoas (0 a 1): 1 no centro de uma célula de lagoa, caindo suave até 0
local function pondInfluence(x: number, z: number): number
    local c, r = cellOf(x, z)
    local influence = 0
    for dc = -1, 1 do
        for dr = -1, 1 do
            if CaveShape.IsPond(c + dc, r + dr) then
                local cx = ORIGIN_X + (c + dc + 0.5) * CELL
                local cz = ORIGIN_Z + (r + dr + 0.5) * CELL
                local distance = math.sqrt((x - cx) ^ 2 + (z - cz) ^ 2)
                influence = math.max(influence, 1 - smooth((distance - POND_RADIUS * 0.3) / (POND_RADIUS * 1.4)))
            end
        end
    end
    return influence
end

function CaveShape.FloorAt(x: number, z: number): number
    local relief = CaveShape.Params.relief
    local pond = pondInfluence(x, z)
    local mask = reliefMask(x, z) * (1 - 0.85 * pond)
    -- Ondulações largas e suaves: o navegador de caminhos do Roblox não aguenta chão áspero (testado: relevo com
    -- inclinação de 32 graus fez 26 de 28 caminhos falharem; chão plano deu 27 de 28)
    local low = clamp1(math.noise(x / 46, z / 46, seed + 3) * 2.2)
    local mid = clamp1(math.noise(x / 22, z / 22, seed + 4) * 2)
    local fine = clamp1(math.noise(x / 6, z / 6, seed + 5) * 2)
    local height = FLOOR_Y + relief * mask * (0.8 * low + 0.12 * mid) + 0.1 * mask * fine
    -- Lagoas: bacia rasa e suave
    return height - POND_DEPTH * pond
end

function CaveShape.CeilingAt(x: number, z: number): number
    local variation = clamp1(math.noise(x / 30, z / 30, seed + 6) * 2) * 2.5 + clamp1(math.noise(x / 11, z / 11, seed + 9)) * 1.0
    return math.max(FLOOR_Y + WALL_H + variation, CaveShape.FloorAt(x, z) + MIN_CLEARANCE)
end

-- Nível da água de uma lagoa (plano único)
function CaveShape.PondLevel(): number
    return FLOOR_Y - POND_DEPTH * 0.55
end

-- Estatísticas para o QA: variação do chão por zona, maior inclinação (graus) e menor vão
function CaveShape.Stats(): { [string]: any }
    local zones: { [string]: { min: number, max: number } } = {
        A = { min = math.huge, max = -math.huge },
        B = { min = math.huge, max = -math.huge },
        C = { min = math.huge, max = -math.huge },
    }
    local maxSlope = 0
    local minGap = math.huge
    for r = 0, ROWS - 1 do
        for c = 0, COLS - 1 do
            if isOpenCell(c, r) then
                local zone = Layout.zoneOf(c)
                for step = 0, 15 do
                    local x = ORIGIN_X + c * CELL + (step % 4 + 0.5) * CELL / 4
                    local z = ORIGIN_Z + r * CELL + (step // 4 + 0.5) * CELL / 4
                    local floor = CaveShape.FloorAt(x, z)
                    zones[zone].min = math.min(zones[zone].min, floor)
                    zones[zone].max = math.max(zones[zone].max, floor)
                    local gx = math.abs(CaveShape.FloorAt(x + 2, z) - CaveShape.FloorAt(x - 2, z)) / 4
                    local gz = math.abs(CaveShape.FloorAt(x, z + 2) - CaveShape.FloorAt(x, z - 2)) / 4
                    maxSlope = math.max(maxSlope, math.deg(math.atan(math.max(gx, gz))))
                    minGap = math.min(minGap, CaveShape.CeilingAt(x, z) - floor)
                end
            end
        end
    end
    return {
        variationA = zones.A.max - zones.A.min,
        variationB = zones.B.max - zones.B.min,
        variationC = zones.C.max - zones.C.min,
        maxSlope = maxSlope,
        minGap = minGap,
    }
end

return CaveShape
