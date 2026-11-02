--!strict
-- Núcleos e Relíquias: criação de cada item e sorteio dos pontos na caverna.

local Util = require(script.Parent:WaitForChild("WorldUtil") :: ModuleScript)
local Layout = require(script.Parent:WaitForChild("CaveLayout") :: ModuleScript)

type Grid = Layout.Grid
local addPrompt = Util.addPrompt
local addLight = Util.addLight
local RARITY_COLORS = Layout.RARITY_COLORS
local cellCenter = Layout.cellCenter
local shuffle = Layout.shuffle
local openCellsByZone = Layout.openCellsByZone

local function makeCore(name: string, position: Vector3, rarity: string, depthZone: string, itemType: string?, parent: Instance?): Part
    local mapFolder = Util.MapFolder :: Folder
    local core = Instance.new("Part")
    core.Name = name
    core.Shape = Enum.PartType.Ball
    local isRelic = itemType == "Relic"
    core.Size = if isRelic then Vector3.new(3.4, 3.4, 3.4) else Vector3.new(2.4, 2.4, 2.4)
    core.Position = position
    core.Anchored = true
    core.Material = Enum.Material.Neon
    core.Color = if isRelic then Color3.fromRGB(255, 120, 210) else RARITY_COLORS[rarity]
    core:SetAttribute("IsCore", true)
    core:SetAttribute("Rarity", rarity)
    core:SetAttribute("DepthZone", depthZone)
    core:SetAttribute("ItemType", itemType or "Core")
    addLight(core, RARITY_COLORS[rarity], 14, 1.5)
    addPrompt(core, "Pegar", 0.5, 10)
    core.Parent = parent or mapFolder
    return core
end

local function placeCores(grid: Grid, rng: Random)
    local lists = openCellsByZone(grid)
    local counter = 0
    local function spawnIn(zone: string, rarities: { string })
        local cells = lists[zone]
        shuffle(cells, rng)
        for index, rarity in ipairs(rarities) do
            local cell = cells[index]
            if cell then
                counter += 1
                local center = cellCenter(cell[1], cell[2])
                makeCore("Core" .. counter, center + Vector3.new(0, 2.2, 0), rarity, zone)
            end
        end
    end
    spawnIn("A", { "Common", "Common", "Common", "Common", "Common", "Common" })
    spawnIn("B", { "Common", "Common", "Common", "Common", "Rare", "Rare" })
    spawnIn("C", { "Rare", "Rare" })

    -- Relíquias: uma na zona B, uma na zona C e uma na câmara do núcleo
    local relicCells = { { lists.B[7], "B" }, { lists.C[3], "C" } }
    for _, entry in ipairs(relicCells) do
        local cell = entry[1] :: { number }?
        if cell then
            counter += 1
            makeCore("Relic" .. counter, cellCenter(cell[1], cell[2]) + Vector3.new(0, 2.4, 0), "Legendary", entry[2] :: string, "Relic")
        end
    end
    counter += 1
    makeCore("Relic" .. counter, cellCenter(21, 8) + Vector3.new(0, 2.4, 0), "Legendary", "C", "Relic")

    local veins = { { 22, 6, "Rare" }, { 26, 6, "Legendary" }, { 22, 10, "Rare" }, { 26, 10, "Legendary" }, { 24, 6, "Rare" }, { 24, 10, "Legendary" } }
    for _, vein in ipairs(veins) do
        counter += 1
        makeCore("Core" .. counter, cellCenter(vein[1] :: number, vein[2] :: number) + Vector3.new(0, 2.2, 0), vein[3] :: string, "C")
    end
end

return { makeCore = makeCore, placeCores = placeCores }
