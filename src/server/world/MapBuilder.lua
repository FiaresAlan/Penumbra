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
local CaveScatter = require(script.Parent:WaitForChild("CaveScatter") :: ModuleScript)
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

-- Limite de luzes da caverna (também usado quando a caverna é refeita)
local function limitLights(mapFolder: Folder)
    -- Limite de luzes (Config.CaveMaxLights): as de enfeite (lâmpadas, cristais, velas) são apagadas além do limite;
    -- as de jogo (núcleos, tochas dos props) ficam sempre
    local lights: { Instance } = {}
    local decorative: { Instance } = {}
    local byName: { [string]: number } = {}
    for _, descendant in ipairs(mapFolder:GetDescendants()) do
        if descendant:IsA("PointLight") or descendant:IsA("SpotLight") then
            table.insert(lights, descendant)
            local owner = if descendant.Parent then descendant.Parent.Name else "?"
            byName[owner] = (byName[owner] or 0) + 1
            if owner == "CaveLamp" or owner == "Crystal" or string.find(owner, "Candle", 1, true) then
                table.insert(decorative, descendant)
            end
        end
    end
    -- Apaga de duas em duas (para não deixar uma área inteira escura) até chegar ao limite
    local order: { Instance } = {}
    for index = 2, #decorative, 2 do
        table.insert(order, decorative[index])
    end
    for index = 1, #decorative, 2 do
        table.insert(order, decorative[index])
    end
    local removed = 0
    for _, light in ipairs(order) do
        if #lights - removed <= Config.CaveMaxLights then
            break
        end
        light:Destroy()
        removed += 1
    end
    local detail = {}
    for name, count in pairs(byName) do
        table.insert(detail, string.format("%s=%d", name, count))
    end
    table.sort(detail)
    print(string.format("[Map] %d luzes na caverna antes do corte, %d apagadas (limite %d): %s", #lights, removed, Config.CaveMaxLights, table.concat(detail, " ")))
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

    -- Local da caverna deste servidor: fixo (Config.ActiveCaveSite) ou sorteado entre os locais (Config.CavePickMode = "random")
    local siteName = Config.ActiveCaveSite
    if Config.CavePickMode == "random" then
        local names: { string } = {}
        for name in pairs(Config.CaveSites) do
            table.insert(names, name)
        end
        table.sort(names)
        siteName = names[Random.new(os.time()):NextInteger(1, #names)]
    end
    Layout.SetSite(Config.CaveSites[siteName])
    workspace:SetAttribute("CaveSite", siteName)
    print("[Map] caverna deste servidor: " .. siteName)
    local rng = Random.new(Layout.Site.seed)
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
    CaveScatter.Build(grid, Random.new(Config.MapSeed + 4))

    local propsRng = Random.new(Config.MapSeed + 3)
    if opts and opts.waitForProps then
        Props.Build(grid, propsRng)
    else
        task.spawn(Props.Build, grid, propsRng)
    end

    limitLights(mapFolder)
    print(string.format("[Map] Mapa gerado (seed %d, %d partes)", Config.MapSeed, #mapFolder:GetDescendants()))
    local count, hash, cores = signature(mapFolder)
    print(string.format("[Map] assinatura partes=%d hash=%d nucleos=%d", count, hash, cores))
end

-- V3: refaz só a caverna (outro local) sem tocar no lobby nem na floresta. Quem guarda referências (elevador, Guardião, Ninho)
-- precisa de Rebind depois (ExtractionSystem, GuardianAI e NestSystem têm). Chamado pela votação de caverna, antes da descida.
local CAVE_TOP_LEVEL = { "Map", "Elevator", "CaveArrival", "PitySpawnPoint", "FuryZones", "NestSlots", "FakeWallSlots", "HookPoints", "Guardian" }

function MapBuilder.RebuildCave(siteName: string)
    local site = Config.CaveSites[siteName]
    if not site then
        warn("[Map] local de caverna desconhecido: " .. tostring(siteName))
        return false
    end
    local startedAt = os.clock()
    for _, name in ipairs(CAVE_TOP_LEVEL) do
        local old = workspace:FindFirstChild(name)
        if old then
            old:Destroy()
        end
    end
    local oldTemplate = ServerStorage:FindFirstChild("CoreTemplate")
    if oldTemplate then
        oldTemplate:Destroy()
    end

    local mapFolder = Instance.new("Folder")
    mapFolder.Name = "Map"
    Util.topLevel(mapFolder)
    Util.MapFolder = mapFolder

    Layout.SetSite(site)
    workspace:SetAttribute("CaveSite", siteName)
    local rng = Random.new(Layout.Site.seed)
    local grid = Layout.carveCave(rng)
    CaveShape.Bind(grid)
    CaveGeometry.Build(grid)
    CaveDecor.Build(grid, Random.new(Config.MapSeed + 2))
    Cores.placeCores(grid, rng)
    Cores.makeCore("CoreTemplate", Vector3.zero, "Common", "A", "Core", ServerStorage)
    CaveMarkers.Build(grid, rng)
    CaveMarkers.BuildLedges()
    GuardianModel.Build()
    CaveScatter.Build(grid, Random.new(Config.MapSeed + 4))
    task.spawn(Props.Build, grid, Random.new(Config.MapSeed + 3))
    limitLights(mapFolder)
    print(string.format("[Map] caverna refeita: %s em %.1f s", siteName, os.clock() - startedAt))
    return true
end

return MapBuilder
