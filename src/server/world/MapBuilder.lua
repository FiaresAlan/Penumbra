--!strict
-- Gera o lobby e a caverna em tempo de execução, de forma determinística.
-- Tudo que é criado aqui leva o Attribute Generated e é recriado a cada partida.
-- O trabalho está dividido em módulos desta pasta; este arquivo só chama cada um na ordem certa.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local Util = require(script.Parent:WaitForChild("WorldUtil") :: ModuleScript)
local Layout = require(script.Parent:WaitForChild("CaveLayout") :: ModuleScript)
local Lobby = require(script.Parent:WaitForChild("Lobby") :: ModuleScript)
local Forest = require(script.Parent:WaitForChild("Forest") :: ModuleScript)
local CaveShape = require(script.Parent:WaitForChild("CaveShape") :: ModuleScript)
local CaveGeometry = require(script.Parent:WaitForChild("CaveGeometry") :: ModuleScript)
local CaveDecor = require(script.Parent:WaitForChild("CaveDecor") :: ModuleScript)
local Cores = require(script.Parent:WaitForChild("Cores") :: ModuleScript)
local CaveMarkers = require(script.Parent:WaitForChild("CaveMarkers") :: ModuleScript)
local Props = require(script.Parent:WaitForChild("Props") :: ModuleScript)
local GuardianModel = require(script.Parent:WaitForChild("GuardianModel") :: ModuleScript)

local MapBuilder = {}

local LEGACY_NAMES = { "Core1", "Core2", "Elevator", "CaveFloor", "LobbyElevator", "LobbyArrival", "CaveArrival", "Guardian" }

-- Remove tudo que uma geração anterior deixou (e as peças soltas das primeiras versões)
function MapBuilder.Clear()
    for _, child in ipairs(workspace:GetChildren()) do
        if child:GetAttribute("Generated") then
            child:Destroy()
        end
    end
    local oldTemplate = ServerStorage:FindFirstChild("CoreTemplate")
    if oldTemplate then
        oldTemplate:Destroy()
    end
    for _, name in ipairs(LEGACY_NAMES) do
        local old = workspace:FindFirstChild(name)
        if old and not old:GetAttribute("Generated") then
            old:Destroy()
        end
    end
end

-- Assinatura do mapa (sem os props, que chegam depois): prova que uma mudança no gerador não alterou nada.
local function signature(mapFolder: Folder): (number, number, number)
    local count, hash, cores = 0, 0, 0
    for _, descendant in ipairs(mapFolder:GetDescendants()) do
        if descendant:IsA("BasePart") and not descendant:FindFirstAncestor("Props") then
            count += 1
            local p, s = descendant.Position, descendant.Size
            hash = (hash + math.floor(p.X * 10 + 0.5) * 31 + math.floor(p.Y * 10 + 0.5) * 17 + math.floor(p.Z * 10 + 0.5) * 13 + math.floor(s.X * 10 + 0.5) * 7) % 2147483647
            if descendant:GetAttribute("IsCore") then
                cores += 1
            end
        end
    end
    return count, hash, cores
end

-- opts.waitForProps: espera os props ficarem prontos antes de voltar (usado na prévia do Studio, onde nada mais os espera).
function MapBuilder.Build(opts: { waitForProps: boolean? }?)
    MapBuilder.Clear()

    -- O cenário (Terrain, floresta, vila) é gerado por botão e salvo no lugar: avisa se veio de outra versão do Config
    local savedVersion = workspace:GetAttribute("WorldVersion")
    if savedVersion ~= Config.WorldVersion then
        warn(string.format("[Map] O mundo salvo é da versão %s, mas o Config pede a %d. Use \"Gerar mundo\" no plugin Ecos Tools e salve o lugar.",
            tostring(savedVersion), Config.WorldVersion))
    end

    if workspace:GetAttribute("CaveVersion") ~= Config.CaveVersion then
        warn(string.format("[Map] A caverna salva é da versão %s, mas o Config pede a %d. Rode WorldBake.BakeCave (Command Bar) e salve o lugar.",
            tostring(workspace:GetAttribute("CaveVersion")), Config.CaveVersion))
    end

    local mapFolder = Instance.new("Folder")
    mapFolder.Name = "Map"
    Util.topLevel(mapFolder)
    Util.MapFolder = mapFolder

    local rng = Random.new(Config.MapSeed)
    Lobby.Build()
    Forest.Build(Random.new(Config.MapSeed + 1)) -- gerador próprio: a caverna continua igual

    local grid = Layout.carveCave(rng)
    CaveShape.Bind(grid)
    CaveGeometry.Build(grid)
    CaveDecor.Build(grid, Random.new(Config.MapSeed + 2))
    Cores.placeCores(grid, rng)
    -- Modelo para núcleos criados em tempo de jogo (pity, Enganador)
    Cores.makeCore("CoreTemplate", Vector3.zero, "Common", "A", "Core", ServerStorage)
    CaveMarkers.Build(grid, rng)
    CaveMarkers.BuildLedges()
    GuardianModel.Build()

    local propsRng = Random.new(Config.MapSeed + 3)
    if opts and opts.waitForProps then
        Props.Build(grid, propsRng)
    else
        task.spawn(Props.Build, grid, propsRng)
    end

    print(string.format("[Map] Mapa gerado (seed %d, %d partes)", Config.MapSeed, #mapFolder:GetDescendants()))
    local count, hash, cores = signature(mapFolder)
    print(string.format("[Map] assinatura partes=%d hash=%d nucleos=%d", count, hash, cores))
end

return MapBuilder
