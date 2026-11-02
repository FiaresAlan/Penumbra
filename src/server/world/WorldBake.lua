--!strict
-- Gera o cenário no modo de edição do Studio (sem Play) e o remove depois. Chamado pelo plugin Ecos Tools.
-- Recusa rodar com o jogo em andamento: durante a partida quem gera o mapa é o MapBuilder, sozinho.
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local MapBuilder = require(script.Parent:WaitForChild("MapBuilder") :: ModuleScript)
local VillageHouses = require(script.Parent:WaitForChild("VillageHouses") :: ModuleScript)

local WorldBake = {}

-- Cria o mapa inteiro, igual ao do jogo. As peças levam Generated e são recriadas ao dar Play.
function WorldBake.Preview(): (boolean, string)
    if RunService:IsRunning() then
        return false, "Pare o jogo antes de gerar a prévia."
    end
    MapBuilder.Build({ waitForProps = true })
    return true, "Prévia gerada. Ao dar Play o mapa é recriado do zero."
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
