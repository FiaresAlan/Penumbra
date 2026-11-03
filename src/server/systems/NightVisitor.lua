--!strict
-- P10 (desligado em Config.Features.NightVisitor): em 1 de cada 6 expedições aparece um vulto azulado e inofensivo que
-- atravessa um salão do meio da caverna e some. Não ataca, não leva nada, não dá item: é só descoberta.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local systems = script.Parent :: Instance
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local Layout = require(systems.Parent:WaitForChild("world"):WaitForChild("CaveLayout") :: ModuleScript)
local ExpeditionSystem = require(systems:WaitForChild("ExpeditionSystem") :: ModuleScript)

local NightVisitor = {}

local CHANCE = 1 / 6
local LIFETIME = 30
local rng = Random.new()

local function pickCells(): (Vector3?, Vector3?)
    local grid = Layout.siteGrid()
    local cells: { Vector3 } = {}
    for r = 1, Layout.ROWS - 2 do
        for c = 1, Layout.COLS - 2 do
            if grid[r][c] and Layout.zoneOf(c) == "B" and not Layout.isSpecial(c, r) then
                table.insert(cells, Layout.cellCenter(c, r))
            end
        end
    end
    if #cells < 2 then
        return nil, nil
    end
    local first = cells[rng:NextInteger(1, #cells)]
    local second = cells[rng:NextInteger(1, #cells)]
    return first + Vector3.new(0, 4, 0), second + Vector3.new(0, 4, 0)
end

local function appear()
    local from, to = pickCells()
    if not from or not to then
        return
    end
    local wisp = Instance.new("Part")
    wisp.Name = "VisitanteDaNoite"
    wisp.Shape = Enum.PartType.Ball
    wisp.Size = Vector3.new(2.4, 2.4, 2.4)
    wisp.Material = Enum.Material.Neon
    wisp.Color = Color3.fromRGB(150, 190, 255)
    wisp.Transparency = 0.35
    wisp.Anchored = true
    wisp.CanCollide = false
    wisp.CanQuery = false
    wisp.CanTouch = false
    wisp.Position = from
    wisp.Parent = workspace
    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(150, 190, 255)
    light.Range = 22
    light.Brightness = 1.4
    light.Parent = wisp
    TweenService:Create(wisp, TweenInfo.new(LIFETIME, Enum.EasingStyle.Sine), { Position = to }):Play()
    task.delay(LIFETIME - 4, function()
        TweenService:Create(wisp, TweenInfo.new(4), { Transparency = 1 }):Play()
        TweenService:Create(light, TweenInfo.new(4), { Brightness = 0 }):Play()
    end)
    task.delay(LIFETIME, function()
        wisp:Destroy()
    end)
    print("[NightVisitor] vulto apareceu na zona B")
end

function NightVisitor.Init()
    ExpeditionSystem.Started:Connect(function()
        if not Config.Features.NightVisitor then
            return
        end
        if rng:NextNumber() < CHANCE then
            task.delay(20, appear)
        end
    end)
end

return NightVisitor
