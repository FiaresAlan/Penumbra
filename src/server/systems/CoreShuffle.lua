--!strict
-- A cada expedição, núcleos e relíquias normais mudam de lugar: o mapa é o mesmo (dá para aprender o labirinto),
-- mas o caminho do saque nunca se repete. Quantidade e raridade por zona seguem iguais. As veias da câmara e os
-- núcleos de saliência (sem o atributo Shuffle) ficam onde estão. Só o servidor sorteia; o cliente nunca sabe antes.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local systems = script.Parent :: Instance
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local ExpeditionSystem = require(systems:WaitForChild("ExpeditionSystem") :: ModuleScript)
local Layout = require((systems.Parent :: Instance):WaitForChild("world"):WaitForChild("CaveLayout") :: ModuleScript)

local CoreShuffle = {}

local cellsByZone: { [string]: { { number } } }? = nil

-- As células abertas vêm da mesma grade do mapa (mesma semente), então são as mesmas que o gerador usou
local function zoneCells(): { [string]: { { number } } }
    local cached = cellsByZone
    if cached then
        return cached
    end
    local grid = Layout.siteGrid()
    local lists = Layout.openCellsByZone(grid)
    cellsByZone = lists
    return lists
end

-- A célula está livre se nada sólido (pilar, rocha, espinho, prop) ocupa o espaço em volta do centro:
-- sem isso um item pode cair sobre a decoração e bloquear o caminho do Guardião.
local function isClear(center: Vector3): boolean
    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local parts = workspace:GetPartBoundsInBox(CFrame.new(center.X, center.Y + 3.5, center.Z), Vector3.new(9, 5, 9), params)
    for _, part in ipairs(parts) do
        if part.CanCollide and not part:GetAttribute("IsCore") and not part:FindFirstAncestorWhichIsA("Model") then
            return false
        end
        if part.CanCollide and not part:GetAttribute("IsCore") then
            local model = part:FindFirstAncestorWhichIsA("Model")
            if model and not model:FindFirstChildOfClass("Humanoid") then
                return false
            end
        end
    end
    return true
end

-- Devolve quantos itens foram movidos
function CoreShuffle.Run(): number
    local map = workspace:FindFirstChild("Map")
    if not map then
        return 0
    end
    local rng = Random.new(os.time() + math.floor(os.clock() * 1000))
    local byZone: { [string]: { BasePart } } = {}
    for _, descendant in ipairs(map:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant:GetAttribute("Shuffle") == true then
            local zone = descendant:GetAttribute("DepthZone")
            if typeof(zone) == "string" then
                byZone[zone] = byZone[zone] or {}
                table.insert(byZone[zone], descendant)
            end
        end
    end

    local lists = zoneCells()
    local moved = 0
    for zone, parts in pairs(byZone) do
        local source = lists[zone]
        if source then
            local cells: { { number } } = table.clone(source)
            Layout.shuffle(cells, rng)
            -- Só células livres, na ordem sorteada; se faltarem, completa com as outras
            local usable: { { number } } = {}
            local rest: { { number } } = {}
            for _, cell in ipairs(cells) do
                if #usable < #parts and isClear(Layout.cellCenter(cell[1], cell[2])) then
                    table.insert(usable, cell)
                else
                    table.insert(rest, cell)
                end
            end
            for _, cell in ipairs(rest) do
                if #usable >= #parts then
                    break
                end
                table.insert(usable, cell)
            end
            for index, part in ipairs(parts) do
                local cell = usable[index]
                if cell then
                    local height = if part:GetAttribute("ItemType") == "Relic" then 2.4 else 2.2
                    part.Position = Layout.cellCenter(cell[1], cell[2]) + Vector3.new(0, height, 0)
                    moved += 1
                end
            end
        end
    end
    print(string.format("[Shuffle] %d itens mudaram de lugar", moved))
    return moved
end

function CoreShuffle.Init()
    ExpeditionSystem.Started:Connect(function()
        if Config.Variation.ShuffleItems then
            CoreShuffle.Run()
        end
    end)
end

return CoreShuffle
