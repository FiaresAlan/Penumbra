--!strict
-- C2: biblioteca de peças de caverna: os pacotes oficiais Synty Dungeon (@Roblox, grátis, licenciados para qualquer jogo Roblox):
-- Cave & Castle Interiors, Skeletons & Bones, Basement & Goblin Camp e Weapons & Props.
-- Na primeira geração as peças são copiadas para ServerStorage.EcosAssets.Cave (salvo no lugar), sem nenhum script.
-- Só roda no modo de edição (WorldBake): durante o jogo as peças já estão em EcosAssets e em Workspace.
local InsertService = game:GetService("InsertService")
local ServerStorage = game:GetService("ServerStorage")

local CaveLibrary = {}

local PACKS: { { id: number, name: string } } = {
    { id = 6934021345, name = "Cave & Castle Interiors" },
    { id = 6934081776, name = "Skeletons & Bones" },
    { id = 6933905899, name = "Basement & Goblin Camp" },
    { id = 6933790012, name = "Weapons & Props" },
}

-- "Meshes/PolygonDungeon_Prop_Torch_03" -> "PolygonDungeon_Prop_Torch"
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
    local cave = assets:FindFirstChild("Cave")
    if not cave then
        cave = Instance.new("Folder")
        cave.Name = "Cave"
        cave.Parent = assets
    end
    return cave :: Folder
end

-- Copia o que ainda não está na pasta. Devolve quantas peças entraram.
function CaveLibrary.Import(log: (string) -> ()): number
    local cave = container()
    local total = 0
    for _, pack in ipairs(PACKS) do
        if cave:FindFirstChild("_pack_" .. pack.id) then
            continue
        end
        local ok, model = pcall(function()
            return InsertService:LoadAsset(pack.id)
        end)
        if not ok or not model then
            log(string.format("não consegui carregar %s: %s", pack.name, tostring(model)))
            continue
        end
        local removed = 0
        for _, descendant in ipairs(model:GetDescendants()) do
            if descendant:IsA("LuaSourceContainer") then
                descendant:Destroy()
                removed += 1
            end
        end
        local copied = 0
        for _, descendant in ipairs(model:GetDescendants()) do
            if descendant:IsA("MeshPart") then
                local part = descendant:Clone()
                part.Name = (string.match(part.Name, "([^/]+)$") or part.Name)
                part.Anchored = true
                part.CanCollide = false
                part.CanTouch = false
                part.CanQuery = false
                part:SetAttribute("Pack", pack.name)
                part.Parent = cave
                copied += 1
            end
        end
        model:Destroy()
        local mark = Instance.new("BoolValue")
        mark.Name = "_pack_" .. pack.id
        mark.Parent = cave
        total += copied
        log(string.format("%s: %d peças copiadas, %d scripts removidos", pack.name, copied, removed))
    end
    return total
end

-- Peças agrupadas por nome base
function CaveLibrary.Groups(): { [string]: { MeshPart } }
    local groups: { [string]: { MeshPart } } = {}
    for _, child in ipairs(container():GetChildren()) do
        if child:IsA("MeshPart") then
            local key = baseName(child.Name)
            groups[key] = groups[key] or {}
            table.insert(groups[key], child)
        end
    end
    return groups
end

-- Nomes de grupo que contêm uma das palavras (sem diferenciar maiúsculas), ordenados
function CaveLibrary.Find(words: { string }): { string }
    local found: { string } = {}
    for name in pairs(CaveLibrary.Groups()) do
        local lower = string.lower(name)
        for _, word in ipairs(words) do
            if string.find(lower, string.lower(word), 1, true) then
                table.insert(found, name)
                break
            end
        end
    end
    table.sort(found)
    return found
end

-- Quantos Scripts há na biblioteca (a auditoria de assets deve achar zero)
function CaveLibrary.CountScripts(): number
    local count = 0
    for _, descendant in ipairs(container():GetDescendants()) do
        if descendant:IsA("LuaSourceContainer") then
            count += 1
        end
    end
    return count
end

return CaveLibrary
