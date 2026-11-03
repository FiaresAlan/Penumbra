--!strict
-- Procura um lugar livre no mundo da superfície para uma peça de decoração, sem ninguém precisar ver o mapa: sorteia pontos
-- perto de uma âncora, mede o chão no Terrain (e a inclinação) e confere se a caixa da peça não encosta em nada que já exista
-- (árvores, casas, bancos, prompts). Devolve nil se não achar; quem chama simplesmente não coloca a peça.
local FreeSpot = {}

local TERRAIN_ONLY = RaycastParams.new()
TERRAIN_ONLY.FilterType = Enum.RaycastFilterType.Include
TERRAIN_ONLY.FilterDescendantsInstances = { workspace.Terrain }

local function groundAt(x: number, z: number): number?
    local hit = workspace:Raycast(Vector3.new(x, 120, z), Vector3.new(0, -240, 0), TERRAIN_ONLY)
    return if hit then hit.Position.Y else nil
end

local function isFree(x: number, y: number, z: number, footprintX: number, footprintZ: number, height: number): boolean
    local overlap = OverlapParams.new()
    overlap.FilterType = Enum.RaycastFilterType.Exclude
    local ignore: { Instance } = {}
    for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
        if player.Character then
            table.insert(ignore, player.Character)
        end
    end
    overlap.FilterDescendantsInstances = ignore
    local box = CFrame.new(x, y + height / 2 + 0.6, z)
    local parts = workspace:GetPartBoundsInBox(box, Vector3.new(footprintX, height, footprintZ), overlap)
    return #parts == 0
end

-- anchor: ponto de referência; footprint: (largura X, largura Z); height: altura da peça; radius: quanto procurar em volta
-- Devolve a posição no chão (x, y do Terrain, z) ou nil.
function FreeSpot.Find(anchor: Vector3, footprintX: number, footprintZ: number, height: number, radius: number, rng: Random): Vector3?
    for attempt = 1, 60 do
        local distance = if attempt == 1 then 0 else rng:NextNumber(0, radius)
        local angle = rng:NextNumber(0, math.pi * 2)
        local x = anchor.X + math.cos(angle) * distance
        local z = anchor.Z + math.sin(angle) * distance
        local y = groundAt(x, z)
        if y then
            local hx, hz = footprintX / 2, footprintZ / 2
            local lowest, highest = y, y
            for _, corner in ipairs({ { hx, hz }, { -hx, hz }, { hx, -hz }, { -hx, -hz } }) do
                local cy = groundAt(x + corner[1], z + corner[2])
                if not cy then
                    lowest = -math.huge
                    break
                end
                lowest = math.min(lowest, cy)
                highest = math.max(highest, cy)
            end
            if lowest > -math.huge and highest - lowest <= 1.5 and isFree(x, highest, z, footprintX, footprintZ, height) then
                return Vector3.new(x, highest, z)
            end
        end
    end
    return nil
end

return FreeSpot
