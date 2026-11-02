--!strict
-- Gera o cenário no modo de edição do Studio (sem Play) e o remove depois. Chamado pelo plugin Ecos Tools.
-- Recusa rodar com o jogo em andamento: durante a partida quem gera o mapa é o MapBuilder, sozinho.
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local MapBuilder = require(script.Parent:WaitForChild("MapBuilder") :: ModuleScript)

local WorldBake = {}

-- Cria o mapa inteiro, igual ao do jogo. As peças levam Generated e são recriadas ao dar Play.
function WorldBake.Preview(): (boolean, string)
    if RunService:IsRunning() then
        return false, "Pare o jogo antes de gerar a prévia."
    end
    MapBuilder.Build({ waitForProps = true })
    return true, "Prévia gerada. Ao dar Play o mapa é recriado do zero."
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
