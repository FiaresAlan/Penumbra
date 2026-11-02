--!strict
-- Props do KayKit (meshes importados). O CreateMeshPartAsync espera a rede, então isto pode demorar.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetService = game:GetService("AssetService")

local Assets = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Assets") :: ModuleScript)
local Util = require(script.Parent:WaitForChild("WorldUtil") :: ModuleScript)
local Layout = require(script.Parent:WaitForChild("CaveLayout") :: ModuleScript)

type Grid = Layout.Grid
local addLight = Util.addLight
local CELL = Layout.CELL
local COLS = Layout.COLS
local ROWS = Layout.ROWS
local FLOOR_Y = Layout.FLOOR_Y
local ENTRANCE = Layout.ENTRANCE
local CHAMBER = Layout.CHAMBER
local cellCenter = Layout.cellCenter
local zoneOf = Layout.zoneOf
local inRect = Layout.inRect

local propWarned = false
local templates: { [string]: MeshPart } = {}

local function makeProp(name: string, cframe: CFrame, scale: number, collide: boolean, parent: Instance): MeshPart?
    local definition = Assets[name]
    if not definition then
        return nil
    end
    -- Cada mesh é pedido uma só vez ao serviço; as demais cópias saem de Clone
    local template = templates[name]
    if not template then
        local ok, created = pcall(function()
            return AssetService:CreateMeshPartAsync(Content.fromUri(definition.mesh))
        end)
        if not ok or not created then
            if not propWarned then
                propWarned = true
                warn("[Map] Não foi possível criar os props do KayKit: " .. tostring(created))
            end
            return nil
        end
        templates[name] = created
        template = created
    end
    local mesh = template:Clone()
    mesh.Name = name
    mesh.Anchored = true
    mesh.CanCollide = collide
    mesh.Size = definition.size * scale
    mesh.TextureID = definition.texture
    mesh.CFrame = cframe
    mesh.Parent = parent
    return mesh
end

local function buildProps(grid: Grid, rng: Random)
    local mapFolder = Util.MapFolder :: Folder
    local props = Instance.new("Folder")
    props.Name = "Props"
    props.Parent = mapFolder

    -- Altura de cada prop apoiado no chão, e a escala usada
    local storage = {
        { "barrel_large", 2.4 }, { "barrel_large", 2.4 }, { "barrel_small_stack", 2.2 }, { "crates_stacked", 2.2 },
        { "box_stacked", 1.7 }, { "box_large", 2.4 }, { "keg_decorated", 1.8 },
    }
    local ruins = { { "rubble_large", 1.8 }, { "rubble_half", 1.8 }, { "sword_shield_broken", 2.4 }, { "candle_triple", 2.8 } }

    local function onFloor(name: string, scale: number, x: number, z: number, yaw: number, collide: boolean): MeshPart?
        local definition = Assets[name]
        local height = definition.size.Y * scale
        return makeProp(name, CFrame.new(x, FLOOR_Y + height / 2, z) * CFrame.Angles(0, yaw, 0), scale, collide, props)
    end

    for r = 1, ROWS - 2 do
        for c = 1, COLS - 2 do
            if grid[r][c] then
                local center = cellCenter(c, r)
                local zone = zoneOf(c)
                for _, dir in ipairs({ { 0, -1 }, { 0, 1 }, { -1, 0 }, { 1, 0 } }) do
                    if not grid[r + dir[2]][c + dir[1]] then
                        -- Ponto encostado na parede, apontando para dentro da célula
                        local wallX = center.X + dir[1] * CELL / 2
                        local wallZ = center.Z + dir[2] * CELL / 2
                        local alongX = if dir[1] == 0 then (rng:NextNumber() - 0.5) * (CELL - 6) else 0
                        local alongZ = if dir[2] == 0 then (rng:NextNumber() - 0.5) * (CELL - 6) else 0
                        local x = wallX - dir[1] * 3 + alongX
                        local z = wallZ - dir[2] * 3 + alongZ
                        local yaw = rng:NextNumber() * math.pi * 2

                        if zone == "A" and not inRect(CHAMBER, c, r) and rng:NextNumber() < 0.09 then
                            local choice = storage[rng:NextInteger(1, #storage)]
                            onFloor(choice[1] :: string, choice[2] :: number, x, z, yaw, true)
                        elseif zone == "B" and rng:NextNumber() < 0.07 then
                            local choice = ruins[rng:NextInteger(1, #ruins)]
                            local prop = onFloor(choice[1] :: string, choice[2] :: number, x, z, yaw, choice[1] ~= "candle_triple")
                            if prop and choice[1] == "candle_triple" then
                                addLight(prop, Color3.fromRGB(255, 190, 110), 16, 0.9)
                            end
                        end

                        -- Tochas nas paredes da zona A e da sala de entrada
                        if (zone == "A" or inRect(ENTRANCE, c, r)) and rng:NextNumber() < 0.1 then
                            local position = Vector3.new(wallX - dir[1] * 1.2 + alongX, FLOOR_Y + 8.5, wallZ - dir[2] * 1.2 + alongZ)
                            local torch = makeProp("torch_lit", CFrame.lookAt(position, position - Vector3.new(dir[1], 0, dir[2])), 3.2, false, props)
                            if torch then
                                addLight(torch, Color3.fromRGB(255, 150, 70), 26, 1.6)
                            end
                        end
                        break
                    end
                end
            end
        end
    end

    -- Câmara do núcleo: colunas altas e bandeiras esfarrapadas na parede do fundo
    for _, cell in ipairs({ { 24, 5 }, { 24, 11 }, { 22, 8 }, { 26, 8 } }) do
        local center = cellCenter(cell[1], cell[2])
        local scale = 9
        local height = Assets.column.size.Y * scale
        makeProp("column", CFrame.new(center.X, FLOOR_Y + height / 2, center.Z), scale, true, props)
    end
    for _, column in ipairs({ 23, 25 }) do
        local center = cellCenter(column, 5)
        local position = Vector3.new(center.X, FLOOR_Y + 8, center.Z - CELL / 2 + 0.6)
        makeProp("banner_triple_brown", CFrame.lookAt(position, position + Vector3.new(0, 0, 1)), 2.6, false, props)
    end

    -- Tesouros decorativos nas saliências do gancho
    for _, cell in ipairs({ { 12, 3 }, { 15, 11 }, { 27, 11 } }) do
        local center = cellCenter(cell[1], cell[2])
        local scale = 2.6
        local height = Assets.chest_gold.size.Y * scale
        makeProp("chest_gold", CFrame.new(center.X - 4, FLOOR_Y + 10 + height / 2, center.Z), scale, true, props)
    end

    print(string.format("[Map] %d props do KayKit criados", #props:GetChildren()))
end

return { Build = buildProps }
