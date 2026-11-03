--!strict
-- P4 (Features.ShiftingRoute): uma vez por expedição, depois de um tempo sorteado, um desabamento fecha um corredor reto por
-- Config.RouteShift.Seconds. Antes cai um ronco de aviso. O corredor só é escolhido se TODAS as outras células abertas continuam
-- ligadas à entrada (a grade tem laços, então sempre há volta), se ninguém está perto e se não é sala especial. O caminho do
-- elevador, dos núcleos e do Ninho nunca fica fechado. Sem aviso de áudio ligado, nada cai.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local systems = script.Parent :: Instance
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local Layout = require(systems.Parent:WaitForChild("world"):WaitForChild("CaveLayout") :: ModuleScript)
local ExpeditionSystem = require(systems:WaitForChild("ExpeditionSystem") :: ModuleScript)
local AudioBroadcast = require(systems:WaitForChild("AudioBroadcast") :: ModuleScript)

local RouteShift = {}

local rng = Random.new()
local runId = 0
local current: Part? = nil

local DIRS = { { 0, -1 }, { 0, 1 }, { -1, 0 }, { 1, 0 } }

-- Quantas células abertas dá para alcançar a partir da entrada sem passar por `blocked`
local function reachable(grid: Layout.Grid, blocked: { number }): number
    local start = { Layout.ENTRANCE.c0 + 1, Layout.ENTRANCE.r0 + 1 }
    local seen: { [number]: boolean } = {}
    local function key(c: number, r: number): number
        return r * 100 + c
    end
    local queue = { start }
    seen[key(start[1], start[2])] = true
    local count = 0
    local head = 1
    while head <= #queue do
        local cell = queue[head]
        head += 1
        count += 1
        for _, d in ipairs(DIRS) do
            local c, r = cell[1] + d[1], cell[2] + d[2]
            if r >= 1 and r <= Layout.ROWS - 2 and c >= 1 and c <= Layout.COLS - 2 and grid[r][c] and not seen[key(c, r)]
                and not (c == blocked[1] and r == blocked[2]) then
                seen[key(c, r)] = true
                table.insert(queue, { c, r })
            end
        end
    end
    return count
end

local function pickCorridor(grid: Layout.Grid): ({ number }?, boolean)
    local total = 0
    for r = 1, Layout.ROWS - 2 do
        for c = 1, Layout.COLS - 2 do
            if grid[r][c] then
                total += 1
            end
        end
    end
    local candidates: { { number } } = {}
    for r = 1, Layout.ROWS - 2 do
        for c = 1, Layout.COLS - 2 do
            if grid[r][c] and not Layout.isSpecial(c, r) then
                local horizontal = grid[r][c - 1] and grid[r][c + 1] and not grid[r - 1][c] and not grid[r + 1][c]
                local vertical = grid[r - 1][c] and grid[r + 1][c] and not grid[r][c - 1] and not grid[r][c + 1]
                if horizontal or vertical then
                    table.insert(candidates, { c, r, if horizontal then 1 else 0 })
                end
            end
        end
    end
    -- embaralha e pega o primeiro que mantém tudo ligado e longe de jogadores
    for i = #candidates, 2, -1 do
        local j = rng:NextInteger(1, i)
        candidates[i], candidates[j] = candidates[j], candidates[i]
    end
    for _, cell in ipairs(candidates) do
        if reachable(grid, cell) == total - 1 then
            local center = Layout.cellCenter(cell[1], cell[2])
            local near = false
            for _, player in ipairs(Players:GetPlayers()) do
                local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if root and root:IsA("BasePart") and (root.Position - center).Magnitude < 40 then
                    near = true
                end
            end
            if not near then
                return cell, cell[3] == 1
            end
        end
    end
    return nil, false
end

local function release()
    local rock = current
    current = nil
    if rock then
        TweenService:Create(rock, TweenInfo.new(2.5), { Position = rock.Position - Vector3.new(0, rock.Size.Y + 2, 0), Transparency = 1 }):Play()
        task.delay(3, function()
            rock:Destroy()
        end)
    end
end

function RouteShift.Init()
    ExpeditionSystem.Started:Connect(function()
        if not Config.Features.ShiftingRoute then
            return
        end
        runId += 1
        local mine = runId
        task.spawn(function()
            local settings = Config.RouteShift
            local wait = rng:NextNumber(settings.MinDelay, settings.MaxDelay)
            local waited = 0
            while waited < wait do
                task.wait(1)
                waited += 1
                if mine ~= runId or ExpeditionSystem.GetPhase() ~= "Active" then
                    return
                end
            end
            local grid = Layout.siteGrid()
            local cell, horizontal = pickCorridor(grid)
            if not cell then
                print("[Route] nenhum corredor seguro para fechar")
                return
            end
            AudioBroadcast.Play("Rumble")
            task.wait(settings.WarnSeconds)
            if mine ~= runId or ExpeditionSystem.GetPhase() ~= "Active" then
                return
            end
            local center = Layout.cellCenter(cell[1], cell[2])
            local floorY = Layout.floorAt(center.X, center.Z)
            local ceilY = Layout.ceilingAt(center.X, center.Z)
            local height = ceilY - floorY + 6
            local rock = Instance.new("Part")
            rock.Name = "Desabamento"
            rock.Anchored = true
            rock.CanCollide = true
            rock.Material = Enum.Material.Rock
            rock.Color = Color3.fromRGB(78, 70, 64)
            local across = Layout.CELL + 12
            rock.Size = if horizontal then Vector3.new(6, height, across) else Vector3.new(across, height, 6)
            rock.Position = Vector3.new(center.X, floorY + height / 2 - 2, center.Z)
            rock.Parent = workspace
            current = rock
            print(string.format("[Route] corredor fechado em (%d, %d) por %d s", cell[1], cell[2], settings.Seconds))
            task.wait(settings.Seconds)
            if mine == runId then
                release()
                print("[Route] corredor reaberto")
            end
        end)
    end)

    ExpeditionSystem.Ended:Connect(function()
        runId += 1
        release()
    end)
end

return RouteShift
