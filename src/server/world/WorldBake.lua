--!strict
-- Gera o cenário no modo de edição do Studio (sem Play) e o remove depois. Chamado pelo plugin Ecos Tools.
-- Recusa rodar com o jogo em andamento: durante a partida quem gera o mapa é o MapBuilder, sozinho.
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local MapBuilder = require(script.Parent:WaitForChild("MapBuilder") :: ModuleScript)
local VillageHouses = require(script.Parent:WaitForChild("VillageHouses") :: ModuleScript)
local SurfaceTerrain = require(script.Parent:WaitForChild("SurfaceTerrain") :: ModuleScript)
local SurfaceDecor = require(script.Parent:WaitForChild("SurfaceDecor") :: ModuleScript)
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
    root.Parent = workspace
    workspace:SetAttribute("WorldVersion", Config.WorldVersion)
    return true, string.format("Mundo gerado em %.0f s (versão %d). Salve o lugar com File > Save to Roblox.", os.clock() - startedAt, Config.WorldVersion)
end

-- Só refaz a floresta e a natureza (workspace.WorldBaked), sem mexer no Terrain. Mais rápido que BakeWorld.
function WorldBake.BakeForest(): (boolean, string)
    if RunService:IsRunning() then
        return false, "Pare o jogo antes de gerar a floresta."
    end
    local startedAt = os.clock()
    local function log(text: string)
        print("[World] " .. text)
    end
    local old = workspace:FindFirstChild("WorldBaked")
    if old then
        old:Destroy()
    end
    local root = Instance.new("Folder")
    root.Name = "WorldBaked"
    SurfaceDecor.Build(root, log)
    root.Parent = workspace
    local parts = #root:GetDescendants()
    return true, string.format("Floresta gerada em %.0f s: %d peças.", os.clock() - startedAt, parts)
end

-- Falha se houver qualquer script no cenário salvo ou na biblioteca de assets.
function WorldBake.AuditAssets(): (boolean, string)
    local count = SurfaceDecor.CountScripts()
    if count > 0 then
        return false, string.format("Auditoria FALHOU: %d scripts em WorldBaked ou EcosAssets. Apague-os.", count)
    end
    return true, "Auditoria ok: nenhum script em WorldBaked nem em EcosAssets."
end

-- Casa de teste feita com as peças do Quaternius, em um chão simples a oeste do mapa. Serve para ver as texturas e as medidas.
function WorldBake.PreviewTestHouse(): (boolean, string)
    if RunService:IsRunning() then
        return false, "Pare o jogo antes de gerar a casa de teste."
    end
    for _, old in ipairs(workspace:GetChildren()) do
        if old.Name == "CasaDeTeste" then
            old:Destroy()
        end
    end
    local folder = Instance.new("Folder")
    folder.Name = "CasaDeTeste"
    folder:SetAttribute("Generated", true)
    local ground = Instance.new("Part")
    ground.Name = "ChaoDeTeste"
    ground.Anchored = true
    ground.Size = Vector3.new(120, 1, 120)
    ground.Material = Enum.Material.Grass
    ground.Color = Color3.fromRGB(70, 110, 60)
    ground.CFrame = CFrame.new(-600, -0.5, 0)
    ground.Parent = folder
    -- A frente (-Z da casa) fica virada para +X, que é o lado da câmera padrão do Studio
    VillageHouses.Small(CFrame.new(-588, 0, -12) * CFrame.Angles(0, math.rad(-90), 0), folder)
    folder.Parent = workspace
    return true, "Casa de teste criada em X -600. Use F com a casa selecionada para enquadrar."
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
