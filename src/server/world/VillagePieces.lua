--!strict
-- Monta peças do Quaternius MegaKit: cada peça é um Model com uma MeshPart por material,
-- e a SurfaceAppearance de cada material vem de VillageAssets.Textures.
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VillageAssets = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("VillageAssets") :: ModuleScript)

local VillagePieces = {}

local USE_NORMALS = false

local meshTemplates: { [string]: MeshPart } = {}
local appearances: { [string]: SurfaceAppearance } = {}
local warned: { [string]: boolean } = {}

-- A madeira gasta usa as mesmas texturas da madeira
local MATERIAL_ALIAS: { [string]: string } = { MI_WoodTrim_Wear = "MI_WoodTrim" }

local function warnOnce(key: string, message: string)
    if not warned[key] then
        warned[key] = true
        warn("[Village] " .. message)
    end
end

local function meshFor(id: string): MeshPart?
    local cached = meshTemplates[id]
    if cached then
        return cached
    end
    local ok, created = pcall(function()
        return AssetService:CreateMeshPartAsync(Content.fromUri(id))
    end)
    if not ok or not created then
        warnOnce(id, "malha " .. id .. " não carregou: " .. tostring(created))
        return nil
    end
    meshTemplates[id] = created
    return created
end

local function appearanceFor(material: string): SurfaceAppearance?
    local textures = VillageAssets.Textures[MATERIAL_ALIAS[material] or material]
    if not textures then
        return nil
    end
    local key = MATERIAL_ALIAS[material] or material
    local template = appearances[key]
    if not template then
        template = Instance.new("SurfaceAppearance")
        -- A cor base do kit traz algo no canal alfa (máscara de desgaste): ignorá-lo evita o tom cinza-azulado por cima
        template.AlphaMode = Enum.AlphaMode.Opaque
        template.ColorMap = textures.color
        -- Os mapas normais do kit deixam as peças azuladas no Roblox (testado em 02/11/2026): ficam desligados.
        -- Para tentar de novo, importe as normais da pasta "Normals Godot-Unity" e mude USE_NORMALS.
        if USE_NORMALS then
            template.NormalMap = textures.normal
        end
        template.RoughnessMap = textures.roughness
        -- Só os materiais com mapa ORM do kit têm metalicidade de verdade; nos outros o mapa gerado deixava o telhado metálico
        if key == "MI_Plaster" or key == "MI_RockTrim" then
            template.MetalnessMap = textures.metalness
        end
        appearances[key] = template
    end
    return template:Clone()
end

-- Cria a peça no lugar `cframe` (o pivô é o centro da base). Devolve o Model, ou nil se a peça não existe.
function VillagePieces.Place(name: string, cframe: CFrame, parent: Instance): Model?
    local parts = VillageAssets.Pieces[name]
    if not parts then
        warnOnce("piece_" .. name, "peça desconhecida: " .. name)
        return nil
    end
    local scale = VillageAssets.Scale
    local model = Instance.new("Model")
    model.Name = name
    for _, part in ipairs(parts) do
        local template = meshFor(part.mesh)
        if template then
            local mesh = template:Clone()
            mesh.Name = part.material
            mesh.Anchored = true
            mesh.Size = part.size * scale
            mesh.CFrame = cframe * (CFrame.new(part.offset.Position * scale) * part.offset.Rotation)
            mesh.CollisionFidelity = Enum.CollisionFidelity.Box
            if part.material == "MI_WindowGlass" then
                mesh.Material = Enum.Material.Glass
                mesh.Color = Color3.fromRGB(190, 220, 235)
                mesh.Transparency = 0.55
                mesh.CanCollide = false
            else
                local appearance = appearanceFor(part.material)
                if appearance then
                    appearance.Parent = mesh
                end
            end
            mesh.Parent = model
        end
    end
    model.Parent = parent
    return model
end

return VillagePieces
