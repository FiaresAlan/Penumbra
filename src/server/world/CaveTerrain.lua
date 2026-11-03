--!strict
-- C1: escreve a caverna em Terrain (paredes, chão e teto) a partir do CaveShape. Roda uma vez, por botão no modo de edição
-- (WorldBake.BakeCave), e o resultado é salvo no lugar. Nunca roda durante uma partida. Não usa Terrain:Clear():
-- cada voxel da região é reescrito (ar ou sólido), então só a região da caverna é tocada.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local Layout = require(script.Parent:WaitForChild("CaveLayout") :: ModuleScript)
local CaveShape = require(script.Parent:WaitForChild("CaveShape") :: ModuleScript)

local CaveTerrain = {}

local RES = 4
local MARGIN = 24 -- rocha sólida em volta da grade
local BELOW = 20 -- rocha sob o chão mais baixo
local ABOVE = 20 -- rocha sobre o teto mais alto
-- Medido no Studio: o Terrain desenha o sólido 2 studs maior que a ocupação pedida (chão 2 acima, teto 2 abaixo, paredes
-- 2 para dentro). Por isso o chão e o teto são pedidos 2 studs mais afastados e a parede é testada com abertura dilatada.
local BIAS = 2

-- Aberto se o ponto, ou um ponto a BIAS studs dele, é aberto (dilata o vazio)
local function isOpenDilated(x: number, z: number): boolean
    return CaveShape.IsOpen(x, z) or CaveShape.IsOpen(x + BIAS, z) or CaveShape.IsOpen(x - BIAS, z) or CaveShape.IsOpen(x, z + BIAS) or CaveShape.IsOpen(x, z - BIAS)
end

-- Cada tema tem materiais próprios. SetMaterialColor vale para o Terrain inteiro, então um material só tem uma cor: o que
-- se repete entre temas (Sandstone, Limestone, Salt, Slate, Basalt) fica com a mesma cor nos dois.
local THEMES: { [string]: { [string]: { floor: Enum.Material, wall: Enum.Material } } } = {
    mine = {
        A = { floor = Enum.Material.Cobblestone, wall = Enum.Material.Sandstone },
        B = { floor = Enum.Material.Slate, wall = Enum.Material.Basalt },
        C = { floor = Enum.Material.Salt, wall = Enum.Material.Limestone },
    },
    dungeon = {
        A = { floor = Enum.Material.Concrete, wall = Enum.Material.Asphalt },
        B = { floor = Enum.Material.Pavement, wall = Enum.Material.Asphalt },
        C = { floor = Enum.Material.Pavement, wall = Enum.Material.Concrete },
    },
    grotto = {
        A = { floor = Enum.Material.Sandstone, wall = Enum.Material.Limestone },
        B = { floor = Enum.Material.Ice, wall = Enum.Material.Glacier },
        C = { floor = Enum.Material.Salt, wall = Enum.Material.Glacier },
    },
}

local MATERIAL_COLORS: { [Enum.Material]: Color3 } = {
    [Enum.Material.Cobblestone] = Color3.fromRGB(104, 92, 80),
    [Enum.Material.Sandstone] = Color3.fromRGB(112, 90, 68),
    [Enum.Material.Slate] = Color3.fromRGB(74, 82, 100),
    [Enum.Material.Basalt] = Color3.fromRGB(46, 50, 60),
    [Enum.Material.Salt] = Color3.fromRGB(78, 104, 112),
    [Enum.Material.Limestone] = Color3.fromRGB(52, 74, 72),
    [Enum.Material.Concrete] = Color3.fromRGB(84, 82, 82),
    [Enum.Material.Asphalt] = Color3.fromRGB(40, 40, 46),
    [Enum.Material.Pavement] = Color3.fromRGB(58, 56, 64),
    [Enum.Material.Ice] = Color3.fromRGB(120, 168, 196),
    [Enum.Material.Glacier] = Color3.fromRGB(84, 128, 160),
}

-- Zonas de fúria (entrada e câmara do núcleo): rachaduras de lava no chão, em manchas por ruído
local function isFuryFloor(x: number, z: number): boolean
    for _, rect in ipairs({ Layout.ENTRANCE, Layout.CHAMBER }) do
        local x0 = Layout.ORIGIN_X + rect.c0 * Layout.CELL
        local x1 = Layout.ORIGIN_X + (rect.c1 + 1) * Layout.CELL
        local z0 = Layout.ORIGIN_Z + rect.r0 * Layout.CELL
        local z1 = Layout.ORIGIN_Z + (rect.r1 + 1) * Layout.CELL
        if x >= x0 and x <= x1 and z >= z0 and z <= z1 then
            return math.noise(x / 7, z / 7, 11.3) + math.noise(x / 3, z / 3, 5.7) * 0.4 > 0.12
        end
    end
    return false
end

local currentTheme = THEMES.mine

local function zoneAtX(x: number): string
    local c = math.clamp(math.floor((x - Layout.ORIGIN_X) / Layout.CELL), 0, Layout.COLS - 1)
    return Layout.zoneOf(c)
end

function CaveTerrain.Build(log: (string) -> (), siteName: string?)
    local startedAt = os.clock()
    local site = Config.CaveSites[siteName or Config.ActiveCaveSite]
    Layout.SetSite(site)
    currentTheme = THEMES[site.theme] or THEMES.mine
    local grid = Layout.siteGrid()
    CaveShape.Bind(grid)

    local x0 = math.floor((Layout.ORIGIN_X - MARGIN) / RES) * RES
    local x1 = math.ceil((Layout.ORIGIN_X + Layout.COLS * Layout.CELL + MARGIN) / RES) * RES
    local z0 = math.floor((Layout.ORIGIN_Z - MARGIN) / RES) * RES
    local z1 = math.ceil((Layout.ORIGIN_Z + Layout.ROWS * Layout.CELL + MARGIN) / RES) * RES
    local y0 = math.floor((Layout.FLOOR_Y - BELOW) / RES) * RES
    local y1 = math.ceil((Layout.FLOOR_Y + Layout.WALL_H + 6 + ABOVE) / RES) * RES
    local nx = (x1 - x0) // RES
    local ny = (y1 - y0) // RES
    local nz = (z1 - z0) // RES

    local materials: { { { Enum.Material } } } = {}
    local occupancy: { { { number } } } = {}
    for xi = 1, nx do
        materials[xi] = {}
        occupancy[xi] = {}
        local x = x0 + (xi - 0.5) * RES
        for yi = 1, ny do
            materials[xi][yi] = {}
            occupancy[xi][yi] = {}
        end
        for zi = 1, nz do
            local z = z0 + (zi - 0.5) * RES
            -- Parede: 4 pontos por voxel dão ocupação parcial e uma superfície mais suave
            local closed = 0
            for _, offset in ipairs({ { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } }) do
                if not isOpenDilated(x + offset[1], z + offset[2]) then
                    closed += 1
                end
            end
            local wallOcc = closed / 4
            local floorY = CaveShape.FloorAt(x, z) - BIAS
            local ceilingY = CaveShape.CeilingAt(x, z) + BIAS
            local zone = currentTheme[zoneAtX(x)]
            for yi = 1, ny do
                local y = y0 + (yi - 0.5) * RES
                local floorOcc = math.clamp((floorY - (y - RES / 2)) / RES, 0, 1)
                local ceilingOcc = math.clamp(((y + RES / 2) - ceilingY) / RES, 0, 1)
                local occ = math.max(wallOcc, floorOcc, ceilingOcc)
                local material = Enum.Material.Air
                if occ > 0 then
                    if floorOcc >= wallOcc and floorOcc >= ceilingOcc then
                        material = if isFuryFloor(x, z) then Enum.Material.CrackedLava else zone.floor
                    else
                        material = zone.wall
                    end
                end
                materials[xi][yi][zi] = material
                occupancy[xi][yi][zi] = occ
            end
        end
        if xi % 12 == 0 then
            task.wait()
        end
    end

    local terrain = workspace.Terrain
    local region = Region3.new(Vector3.new(x0, y0, z0), Vector3.new(x1, y1, z1))
    terrain:WriteVoxels(region, RES, materials, occupancy)
    for material, color in pairs(MATERIAL_COLORS) do
        terrain:SetMaterialColor(material, color)
    end
    log(string.format("caverna em Terrain: %d x %d x %d voxels em %.1f s", nx, ny, nz, os.clock() - startedAt))
end

return CaveTerrain
