--!strict
-- Biblioteca de natureza: o pacote oficial Synty Nature Pack (@Roblox, grátis, licenciado para qualquer jogo Roblox).
-- Na primeira geração, as peças são copiadas para ServerStorage.EcosAssets.Nature (salvo no lugar) já sem nenhum script.
-- Só roda no modo de edição (WorldBake): durante o jogo as árvores já existem em workspace.WorldBaked.
local InsertService = game:GetService("InsertService")
local ServerStorage = game:GetService("ServerStorage")

local NatureLibrary = {}

local SYNTY_NATURE_PACK = 6933438443

-- "Meshes/PolygonNature_Tree_Round_03" -> "PolygonNature_Tree_Round"
local function baseName(name: string): string
    local last = string.match(name, "([^/]+)$") or name
    return (string.gsub(last, "[_ ]?%d+$", ""))
end

local function container(): Folder
    local assets = ServerStorage:FindFirstChild("EcosAssets")
    if not assets then
        assets = Instance.new("Folder")
        assets.Name = "EcosAssets"
        assets.Parent = ServerStorage
    end
    local nature = assets:FindFirstChild("Nature")
    if not nature then
        nature = Instance.new("Folder")
        nature.Name = "Nature"
        nature.Parent = assets
    end
    return nature :: Folder
end

-- Garante o pacote em ServerStorage e devolve as peças agrupadas por nome base.
function NatureLibrary.Load(log: (string) -> ()): { [string]: { MeshPart } }?
    local nature = container()
    if #nature:GetChildren() == 0 then
        local ok, model = pcall(function()
            return InsertService:LoadAsset(SYNTY_NATURE_PACK)
        end)
        if not ok or not model then
            log("não consegui carregar o Synty Nature Pack: " .. tostring(model))
            return nil
        end
        local removed = 0
        for _, descendant in ipairs(model:GetDescendants()) do
            if descendant:IsA("LuaSourceContainer") then
                descendant:Destroy()
                removed += 1
            end
        end
        for _, descendant in ipairs(model:GetDescendants()) do
            if descendant:IsA("MeshPart") then
                local part = descendant:Clone()
                part.Name = (string.match(part.Name, "([^/]+)$") or part.Name)
                part.Anchored = true
                part.CanCollide = false
                part.CanTouch = false
                part.CanQuery = false
                part.Parent = nature
            end
        end
        model:Destroy()
        log(string.format("Synty Nature Pack copiado: %d peças, %d scripts removidos", #nature:GetChildren(), removed))
    end

    local groups: { [string]: { MeshPart } } = {}
    for _, child in ipairs(nature:GetChildren()) do
        if child:IsA("MeshPart") then
            local key = baseName(child.Name)
            groups[key] = groups[key] or {}
            table.insert(groups[key], child)
        end
    end
    return groups
end

return NatureLibrary
