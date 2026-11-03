--!strict
-- F1: pele do monstro. As poses do Guardião são MeshParts sem textura; aqui o cliente desenha uma pele de escamas violeta
-- com rachaduras de brasa (EditableImage, gerada por código) e aplica em TextureContent. Só aparência, só neste cliente.
-- Se a API não estiver liberada (jogo publicado sem "Allow Mesh & Image APIs"), nada acontece e fica a cor lisa do servidor.
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript) :: any

local MonsterTexture = {}

local SIZE = 256
local CELLS = 16

local function hash(x: number, y: number, salt: number): number
    local n = math.sin(x * 127.1 + y * 311.7 + salt * 74.7) * 43758.5453
    return n - math.floor(n)
end

local function mix(a: number, b: number, t: number): number
    return a + (b - a) * t
end

-- Escamas: células de Voronoi que se repetem nas bordas (a textura emenda sem costura)
local function build(): any?
    local ok, image = pcall(function()
        return AssetService:CreateEditableImage({ Size = Vector2.new(SIZE, SIZE) })
    end)
    if not ok or not image then
        return nil
    end
    local pixels = buffer.create(SIZE * SIZE * 4)
    local cell = SIZE / CELLS
    for py = 0, SIZE - 1 do
        for px = 0, SIZE - 1 do
            local gx, gy = px / cell, py / cell
            local cx, cy = math.floor(gx), math.floor(gy)
            local best, second, bestId = 9, 9, 0
            for oy = -1, 1 do
                for ox = -1, 1 do
                    local nx, ny = cx + ox, cy + oy
                    local wx, wy = nx % CELLS, ny % CELLS
                    local fx = nx + hash(wx, wy, 1) * 0.8 + 0.1
                    local fy = ny + hash(wx, wy, 2) * 0.8 + 0.1
                    local dist = math.sqrt((gx - fx) ^ 2 + (gy - fy) ^ 2)
                    if dist < best then
                        second = best
                        best = dist
                        bestId = wx * 97 + wy
                    elseif dist < second then
                        second = dist
                    end
                end
            end
            local edge = second - best
            local tone = hash(bestId, 3, 5)
            local lit = math.clamp(edge * 2.2, 0, 1)
            -- escama: violeta escuro no miolo variando para magenta; borda mais escura
            local r = mix(70, 190, tone) * mix(0.35, 1, lit)
            local g = mix(14, 46, tone) * mix(0.35, 1, lit)
            local b = mix(110, 210, tone) * mix(0.4, 1, lit)
            -- brasa laranja só em algumas bordas
            if edge < 0.09 and hash(bestId, 7, 9) > 0.78 then
                r, g, b = 255, 120, 30
            end
            local offset = (py * SIZE + px) * 4
            buffer.writeu8(pixels, offset, math.clamp(r, 0, 255))
            buffer.writeu8(pixels, offset + 1, math.clamp(g, 0, 255))
            buffer.writeu8(pixels, offset + 2, math.clamp(b, 0, 255))
            buffer.writeu8(pixels, offset + 3, 255)
        end
    end
    image:WritePixelsBuffer(Vector2.zero, Vector2.new(SIZE, SIZE), pixels)
    return image
end

local image: any? = nil
local failed = false

local function paint(part: Instance)
    if failed or not part:IsA("MeshPart") then
        return
    end
    if not image then
        local built, result = pcall(build)
        if built then
            image = result
        else
            warn("[MonsterTexture] " .. tostring(result))
        end
        if not image then
            failed = true
            warn("[MonsterTexture] EditableImage indisponível; a pele fica lisa")
            return
        end
    end
    local ok, err = pcall(function()
        (part :: any).TextureContent = Content.fromObject(image :: any)
        part.Color = Color3.new(1, 1, 1)
    end)
    if not ok then
        failed = true
        warn("[MonsterTexture] não foi possível aplicar a textura: " .. tostring(err))
    else
        print("[MonsterTexture] pele aplicada em " .. part.Name)
    end
end

local function watch(guardian: Instance)
    local poses = guardian:WaitForChild("Poses", 30)
    if not poses then
        warn("[MonsterTexture] Guardião sem pasta Poses")
        return
    end
    print("[MonsterTexture] poses encontradas: " .. #poses:GetChildren())
    for _, pose in ipairs(poses:GetChildren()) do
        paint(pose)
    end
    poses.ChildAdded:Connect(paint)
end

function MonsterTexture.Init()
    if not Config.MonsterSkin or not Config.MonsterTexture then
        return
    end
    local existing = workspace:FindFirstChild("Guardian")
    if existing then
        task.spawn(watch, existing)
    end
    workspace.ChildAdded:Connect(function(child: Instance)
        if child.Name == "Guardian" then
            task.spawn(watch, child)
        end
    end)
end

return MonsterTexture
