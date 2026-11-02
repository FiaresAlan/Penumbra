--!strict
-- Escreve o Terrain da superfície (vale, colinas, trilhas, riacho e montanhas) com WriteVoxels, em blocos.
-- Só roda no modo de edição, chamado por WorldBake.BakeWorld. Apaga o Terrain existente antes de escrever.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local SurfaceShape = require(script.Parent:WaitForChild("SurfaceShape") :: ModuleScript)

local SurfaceTerrain = {}

local VOXEL = 4
local CHUNK = 32 -- colunas por bloco
local B = Config.WorldBounds
local STREAM = Config.WorldStream

function SurfaceTerrain.Build(log: (string) -> ())
    local terrain = workspace.Terrain
    terrain:Clear()
    local startedAt = os.clock()

    local nx = (B.MaxX - B.MinX) // VOXEL
    local nz = (B.MaxZ - B.MinZ) // VOXEL
    local ny = (B.MaxY - B.MinY) // VOXEL

    -- Alturas de cada coluna, com uma borda extra para calcular a inclinação
    local heights: { [number]: { [number]: number } } = {}
    for i = 0, nx + 1 do
        local row: { [number]: number } = {}
        for k = 0, nz + 1 do
            row[k] = SurfaceShape.HeightAt(B.MinX + (i - 0.5) * VOXEL, B.MinZ + (k - 0.5) * VOXEL)
        end
        heights[i] = row
        if i % 20 == 0 then
            task.wait()
        end
    end
    log(string.format("alturas calculadas (%d x %d colunas) em %.1f s", nx, nz, os.clock() - startedAt))

    local done, total = 0, math.ceil(nx / CHUNK) * math.ceil(nz / CHUNK)
    for i0 = 1, nx, CHUNK do
        for k0 = 1, nz, CHUNK do
            local cx, cz = math.min(CHUNK, nx - i0 + 1), math.min(CHUNK, nz - k0 + 1)
            local materials = table.create(cx)
            local occupancy = table.create(cx)
            for a = 1, cx do
                local i = i0 + a - 1
                local matColumn, occColumn = table.create(ny), table.create(ny)
                for j = 1, ny do
                    matColumn[j] = table.create(cz)
                    occColumn[j] = table.create(cz)
                end
                for b = 1, cz do
                    local k = k0 + b - 1
                    local h = heights[i][k]
                    local slope = (math.abs(heights[i + 1][k] - heights[i - 1][k]) + math.abs(heights[i][k + 1] - heights[i][k - 1])) / (2 * VOXEL)
                    local x, z = B.MinX + (i - 0.5) * VOXEL, B.MinZ + (k - 0.5) * VOXEL
                    local top = SurfaceShape.MaterialAt(x, z, h, slope)
                    local inStream = h < STREAM.waterY and math.abs(z) < 340 and math.abs(x - SurfaceShape.StreamX(z)) < STREAM.halfWidth + STREAM.bank
                    for j = 1, ny do
                        local y0 = B.MinY + (j - 1) * VOXEL
                        local depth = h - y0
                        local occ = math.clamp(depth / VOXEL, 0, 1)
                        local material = Enum.Material.Air
                        if occ > 0 then
                            if depth <= VOXEL * 2 then
                                material = top
                            elseif depth > 16 then
                                material = Enum.Material.Rock
                            else
                                material = Enum.Material.Ground
                            end
                        elseif inStream and y0 < STREAM.waterY then
                            material, occ = Enum.Material.Water, 1
                        end
                        matColumn[j][b] = material
                        occColumn[j][b] = occ
                    end
                end
                materials[a], occupancy[a] = matColumn, occColumn
            end
            local min = Vector3.new(B.MinX + (i0 - 1) * VOXEL, B.MinY, B.MinZ + (k0 - 1) * VOXEL)
            terrain:WriteVoxels(Region3.new(min, min + Vector3.new(cx * VOXEL, ny * VOXEL, cz * VOXEL)), VOXEL, materials, occupancy)
            done += 1
            if done % 6 == 0 then
                log(string.format("terreno %d/%d", done, total))
                task.wait()
            end
        end
    end
    log(string.format("terreno pronto em %.1f s", os.clock() - startedAt))
end

return SurfaceTerrain
