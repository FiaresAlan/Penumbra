--!strict
-- Gera o cenário no modo de edição do Studio (sem Play) e o remove depois. Chamado pelo plugin Ecos Tools.
-- Recusa rodar com o jogo em andamento: durante a partida quem gera o mapa é o MapBuilder, sozinho.
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local MapBuilder = require(script.Parent:WaitForChild("MapBuilder") :: ModuleScript)
local SurfaceTerrain = require(script.Parent:WaitForChild("SurfaceTerrain") :: ModuleScript)
local SurfaceDecor = require(script.Parent:WaitForChild("SurfaceDecor") :: ModuleScript)
local Village = require(script.Parent:WaitForChild("Village") :: ModuleScript)
local CaveTerrain = require(script.Parent:WaitForChild("CaveTerrain") :: ModuleScript)
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)

local WorldBake = {}

-- Cria o mapa inteiro, igual ao do jogo. As peças levam Generated e são recriadas ao dar Play.
function WorldBake.Preview(): (boolean, string)
    if RunService:IsRunning() then
        return false, "Pare o jogo antes de gerar a prévia."
    end
    MapBuilder.Build({ waitForProps = true })
    return true, "Prévia gerada. Ao dar Play o mapa é recriado do zero."
end

-- Gera o cenário da superfície (Terrain e árvores) e o guarda no lugar. Demora; chame de uma thread própria.
-- Apaga o Terrain que existir. Depois, salve o lugar no Studio (File > Save to Roblox).
function WorldBake.BakeWorld(): (boolean, string)
    if RunService:IsRunning() then
        return false, "Pare o jogo antes de gerar o mundo."
    end
    local startedAt = os.clock()
    local function log(text: string)
        print("[World] " .. text)
    end
    local old = workspace:FindFirstChild("WorldBaked")
    if old then
        old:Destroy()
    end
    SurfaceTerrain.Build(log)
    local root = Instance.new("Folder")
    root.Name = "WorldBaked"
    SurfaceDecor.Build(root, log)
    Village.Build(root, log)
    root.Parent = workspace
    workspace:SetAttribute("WorldVersion", Config.WorldVersion)
    return true, string.format("Mundo gerado em %.0f s (versão %d). Salve o lugar com File > Save to Roblox.", os.clock() - startedAt, Config.WorldVersion)
end

-- Só refaz a floresta e a natureza, sem mexer no Terrain nem na vila. Mais rápido que BakeWorld.
function WorldBake.BakeForest(): (boolean, string)
    if RunService:IsRunning() then
        return false, "Pare o jogo antes de gerar a floresta."
    end
    local startedAt = os.clock()
    local function log(text: string)
        print("[World] " .. text)
    end
    local root = workspace:FindFirstChild("WorldBaked")
    if not root then
        root = Instance.new("Folder")
        root.Name = "WorldBaked"
        root.Parent = workspace
    end
    SurfaceDecor.Build(root :: Folder, log)
    return true, string.format("Floresta gerada em %.0f s: %d peças no total.", os.clock() - startedAt, #(root :: Folder):GetDescendants())
end

-- Só refaz a vila (casas, poço, placas, torre da mina e cabana do Mercado Negro).
function WorldBake.BakeVillage(): (boolean, string)
    if RunService:IsRunning() then
        return false, "Pare o jogo antes de gerar a vila."
    end
    local startedAt = os.clock()
    local function log(text: string)
        print("[World] " .. text)
    end
    local root = workspace:FindFirstChild("WorldBaked")
    if not root then
        root = Instance.new("Folder")
        root.Name = "WorldBaked"
        root.Parent = workspace
    end
    Village.Build(root :: Folder, log)
    return true, string.format("Vila gerada em %.0f s.", os.clock() - startedAt)
end

-- Escreve só a caverna em Terrain (região X a partir de 396). Não apaga o resto do Terrain. Depois, salve o lugar.
-- Atenção: "Gerar mundo" (BakeWorld) apaga todo o Terrain, a caverna inclusive: rode BakeCave de novo depois dele.
function WorldBake.BakeCave(): (boolean, string)
    if RunService:IsRunning() then
        return false, "Pare o jogo antes de gerar a caverna."
    end
    local startedAt = os.clock()
    CaveTerrain.Build(function(text: string)
        print("[Caverna] " .. text)
    end)
    workspace:SetAttribute("CaveVersion", Config.CaveVersion)
    return true, string.format("Caverna gerada em %.0f s (versão %d). Salve o lugar com File > Save to Roblox.", os.clock() - startedAt, Config.CaveVersion)
end

-- Falha se houver qualquer script no cenário salvo ou na biblioteca de assets.
function WorldBake.AuditAssets(): (boolean, string)
    local count = SurfaceDecor.CountScripts()
    if count > 0 then
        return false, string.format("Auditoria FALHOU: %d scripts em WorldBaked ou EcosAssets. Apague-os.", count)
    end
    return true, "Auditoria ok: nenhum script em WorldBaked nem em EcosAssets."
end

-- Remove a prévia e devolve quantos itens saíram do Workspace.
function WorldBake.ClearPreview(): (boolean, string)
    if RunService:IsRunning() then
        return false, "Pare o jogo antes de limpar a prévia."
    end
    local removed = 0
    for _, child in ipairs(workspace:GetChildren()) do
        if child:GetAttribute("Generated") then
            child:Destroy()
            removed += 1
        end
    end
    local template = ServerStorage:FindFirstChild("CoreTemplate")
    if template then
        template:Destroy()
    end
    return true, string.format("%d itens gerados removidos.", removed)
end

return WorldBake
