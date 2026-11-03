--!strict
-- C2, C4 e C5 (parte de código): detalhes de cada local por cima do Terrain, todos finos e sem colisão (menos os pilares dos
-- arcos, que ficam nas bordas do corredor): trilhos e dormentes na Mina, lama na zona B, crostas de sal na C, arcos de pedra e
-- símbolos no chão da Masmorra, poças rasas de água e marcas de garra no Ninho. Posição por raio contra o Terrain.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local Util = require(script.Parent:WaitForChild("WorldUtil") :: ModuleScript)
local Layout = require(script.Parent:WaitForChild("CaveLayout") :: ModuleScript)

local CaveExtras = {}

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = { workspace.Terrain }

local function groundAt(x: number, z: number, aroundY: number): number?
    local hit = workspace:Raycast(Vector3.new(x, aroundY + 14, z), Vector3.new(0, -40, 0), params)
    return if hit then hit.Position.Y else nil
end

local function make(name: string, size: Vector3, cframe: CFrame, material: Enum.Material, color: Color3, collide: boolean, parent: Instance): Part
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cframe
    p.Material = material
    p.Color = color
    p.Anchored = true
    p.CanCollide = collide
    p.CanTouch = false
    p.CanQuery = collide
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

-- Disco chato (cilindro deitado) sobre o chão
local function disc(name: string, x: number, z: number, radius: number, thickness: number, material: Enum.Material, color: Color3, aroundY: number, parent: Instance, transparency: number?): Part?
    local y = groundAt(x, z, aroundY)
    if not y then
        return nil
    end
    local p = make(name, Vector3.new(thickness, radius * 2, radius * 2), CFrame.new(x, y + thickness / 2 + 0.03, z) * CFrame.Angles(0, 0, math.pi / 2), material, color, false, parent)
    p.Shape = Enum.PartType.Cylinder
    if transparency then
        p.Transparency = transparency
    end
    return p
end

function CaveExtras.Build(grid: Layout.Grid, rng: Random)
    local folder = Instance.new("Folder")
    folder.Name = "Extras"
    folder.Parent = Util.MapFolder :: Folder
    local theme = Layout.Site.theme
    local counts: { [string]: number } = {}
    local function tally(key: string)
        counts[key] = (counts[key] or 0) + 1
    end

    for r = 1, Layout.ROWS - 2 do
        for c = 1, Layout.COLS - 2 do
            if grid[r][c] and not Layout.isSpecial(c, r) then
                local center = Layout.cellCenter(c, r)
                local zone = Layout.zoneOf(c)
                local horizontal = grid[r][c - 1] and grid[r][c + 1] and not grid[r - 1][c] and not grid[r + 1][c]
                local vertical = grid[r - 1][c] and grid[r + 1][c] and not grid[r][c - 1] and not grid[r][c + 1]
                local straight = horizontal or vertical
                -- eixo do corredor: X (horizontal) ou Z (vertical)
                local along = if horizontal then CFrame.new(center) else CFrame.new(center) * CFrame.Angles(0, math.pi / 2, 0)

                if theme == "mine" and zone == "A" and straight and rng:NextNumber() < 0.55 then
                    -- trilhos de mina: dois trilhos finos e dormentes a cada 3 studs
                    local y = groundAt(center.X, center.Z, center.Y)
                    if y then
                        local base = CFrame.new(center.X, y, center.Z) * (along - along.Position)
                        for _, side in ipairs({ -1.4, 1.4 }) do
                            make("Trilho", Vector3.new(15, 0.25, 0.25), base * CFrame.new(0, 0.2, side), Enum.Material.Metal, Color3.fromRGB(90, 84, 80), false, folder)
                        end
                        for step = -6, 6, 3 do
                            make("Dormente", Vector3.new(0.7, 0.2, 4), base * CFrame.new(step, 0.1, 0), Enum.Material.Wood, Color3.fromRGB(80, 56, 38), false, folder)
                        end
                        tally("trilhos")
                    end
                end

                if theme ~= "dungeon" and zone == "B" and rng:NextNumber() < 0.25 then
                    local x, z = center.X + rng:NextNumber(-4, 4), center.Z + rng:NextNumber(-4, 4)
                    if disc("Lama", x, z, rng:NextNumber(3, 5.5), 0.12, Enum.Material.Mud, Color3.fromRGB(64, 46, 34), center.Y, folder) then
                        tally("lama")
                    end
                end

                if theme ~= "dungeon" and zone == "C" and rng:NextNumber() < 0.3 then
                    local x, z = center.X + rng:NextNumber(-5, 5), center.Z + rng:NextNumber(-5, 5)
                    if disc("CrostaDeSal", x, z, rng:NextNumber(2.5, 4.5), 0.1, Enum.Material.Salt, Color3.fromRGB(226, 232, 236), center.Y, folder) then
                        tally("sal")
                    end
                end

                if theme == "grotto" and (zone == "B" or zone == "C") and rng:NextNumber() < 0.35 then
                    -- poça rasa de água (vidro azul, sem colisão)
                    local x, z = center.X + rng:NextNumber(-3, 3), center.Z + rng:NextNumber(-3, 3)
                    local pool = disc("PocaRasa", x, z, rng:NextNumber(5, 8), 0.1, Enum.Material.Glass, Color3.fromRGB(70, 140, 190), center.Y, folder, 0.45)
                    if pool then
                        pool.Reflectance = 0.3
                        tally("pocas")
                    end
                end

                if theme == "dungeon" and straight and rng:NextNumber() < 0.4 then
                    -- arco de pedra: dois pilares nas bordas e uma verga em cima
                    local y = groundAt(center.X, center.Z, center.Y)
                    if y then
                        local base = CFrame.new(center.X, y, center.Z) * (along - along.Position)
                        local stone = Color3.fromRGB(100, 96, 92)
                        for _, side in ipairs({ -7.2, 7.2 }) do
                            make("ArcoPilar", Vector3.new(1.8, 12, 1.8), base * CFrame.new(0, 6, side), Enum.Material.Cobblestone, stone, true, folder)
                        end
                        make("ArcoVerga", Vector3.new(2, 1.8, 16.6), base * CFrame.new(0, 12.8, 0), Enum.Material.Cobblestone, stone, false, folder)
                        make("ArcoChave", Vector3.new(2.4, 2.4, 3), base * CFrame.new(0, 11.2, 0), Enum.Material.Cobblestone, Color3.fromRGB(120, 114, 108), false, folder)
                        tally("arcos")
                    end
                end

                if theme == "dungeon" and zone == "B" and rng:NextNumber() < 0.2 then
                    -- símbolo no chão: anel e cruz de néon fraco
                    local x, z = center.X + rng:NextNumber(-4, 4), center.Z + rng:NextNumber(-4, 4)
                    local y = groundAt(x, z, center.Y)
                    if y then
                        local color = Color3.fromRGB(120, 90, 210)
                        local ring = make("SimboloAnel", Vector3.new(0.1, 5, 5), CFrame.new(x, y + 0.08, z) * CFrame.Angles(0, 0, math.pi / 2), Enum.Material.Neon, color, false, folder)
                        ring.Shape = Enum.PartType.Cylinder
                        ring.Transparency = 0.5
                        make("SimboloBarra", Vector3.new(6, 0.08, 0.3), CFrame.new(x, y + 0.1, z), Enum.Material.Neon, color, false, folder).Transparency = 0.5
                        make("SimboloBarra", Vector3.new(0.3, 0.08, 6), CFrame.new(x, y + 0.1, z), Enum.Material.Neon, color, false, folder).Transparency = 0.5
                        tally("simbolos")
                    end
                end
            end
        end
    end

    -- Ninho: marcas de garra irregulares no chão
    local nest = Layout.NEST
    for _ = 1, 24 do
        local c = rng:NextInteger(nest.c0, nest.c1)
        local r = rng:NextInteger(nest.r0, nest.r1)
        if grid[r] and grid[r][c] then
            local center = Layout.cellCenter(c, r)
            local x, z = center.X + rng:NextNumber(-6, 6), center.Z + rng:NextNumber(-6, 6)
            local y = groundAt(x, z, center.Y)
            if y then
                local mark = make("MarcaDeGarra", Vector3.new(rng:NextNumber(2, 4.5), 0.06, 0.25), CFrame.new(x, y + 0.06, z) * CFrame.Angles(0, rng:NextNumber(0, math.pi), 0),
                    Enum.Material.Slate, Color3.fromRGB(70, 20, 20), false, folder)
                mark.Transparency = 0.15
                tally("garras")
            end
        end
    end

    local detail: { string } = {}
    for key, value in pairs(counts) do
        table.insert(detail, string.format("%s=%d", key, value))
    end
    table.sort(detail)
    print("[Map] extras da caverna (" .. tostring(Config.ActiveCaveSite) .. "): " .. table.concat(detail, " "))
end

return CaveExtras
