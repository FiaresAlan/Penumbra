--!strict
-- Mural de Destaques: maiores saques da semana (OrderedDataStore) e histórias recentes do servidor.
-- Qualquer falha de DataStore só deixa o mural com mensagem neutra: o jogo nunca depende dele.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local systems = script.Parent :: Instance
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config") :: ModuleScript)
local ContractRules = require(Shared:WaitForChild("ContractRules") :: ModuleScript)
local ExpeditionSystem = require(systems:WaitForChild("ExpeditionSystem") :: ModuleScript)
local ExtractionSystem = require(systems:WaitForChild("ExtractionSystem") :: ModuleScript)
local NestSystem = require(systems:WaitForChild("NestSystem") :: ModuleScript)
local RateLimiter = require(systems:WaitForChild("RateLimiter") :: ModuleScript)

local remotes = ReplicatedStorage:WaitForChild("EcosRemotes")
local RequestBoard = remotes:WaitForChild("RequestBoard") :: RemoteEvent
local BoardData = remotes:WaitForChild("BoardData") :: RemoteEvent

local HighlightsSystem = {}

local pending: { [number]: number } = {} -- UserId -> melhor saque desta sessão, ainda não salvo
local stories: { string } = {}
local nameCache: { [number]: string } = {}
local lastTop: { { userId: number, value: number } } = {}
local topFailed = false
local inFlight = 0 -- gravações em andamento (o desligamento espera por elas)

local function weekStore(): OrderedDataStore?
    local ok, store = pcall(function()
        return DataStoreService:GetOrderedDataStore("EcosWeeklyHaul_" .. ContractRules.WeekKey(os.time()))
    end)
    if ok then
        return store :: OrderedDataStore
    end
    return nil
end

local function nameOf(userId: number): string
    local cached = nameCache[userId]
    if cached then
        return cached
    end
    local ok, name = pcall(function()
        return Players:GetNameFromUserIdAsync(userId)
    end)
    local result = if ok and typeof(name) == "string" then name else ("Jogador " .. userId)
    nameCache[userId] = result
    return result
end

local function addStory(text: string)
    table.insert(stories, 1, text)
    while #stories > 5 do
        table.remove(stories)
    end
end

-- Escreve o painel de histórias e o ranking no SurfaceGui do mural
local function render()
    local wall = workspace:FindFirstChild("HighlightsWall")
    local gui = wall and wall:FindFirstChild("HighlightsGui")
    local label = gui and gui:FindFirstChild("Text")
    if not label or not label:IsA("TextLabel") then
        return
    end

    local lines: { string } = { "MURAL DE DESTAQUES", "" }
    if topFailed then
        table.insert(lines, "Ranking indisponível no momento")
    elseif #lastTop == 0 then
        table.insert(lines, "Ninguém extraiu nesta semana")
    else
        for rank, entry in ipairs(lastTop) do
            table.insert(lines, string.format("%d. %s — %d", rank, nameOf(entry.userId), entry.value))
        end
    end
    if #stories > 0 then
        table.insert(lines, "")
        for _, story in ipairs(stories) do
            table.insert(lines, "• " .. story)
        end
    end
    label.Text = table.concat(lines, "\n")
end

-- Ranking semanal já lido (para o pedestal do campeão) e nome por UserId
function HighlightsSystem.GetTop(): { { userId: number, value: number } }
    return lastTop
end

function HighlightsSystem.NameOf(userId: number): string
    return nameOf(userId)
end

function HighlightsSystem.Refresh()
    local store = weekStore()
    if not store then
        topFailed = true
        render()
        return
    end
    local ok, result = pcall(function()
        return store:GetSortedAsync(false, 10):GetCurrentPage()
    end)
    if ok then
        topFailed = false
        local top: { { userId: number, value: number } } = {}
        for _, entry in ipairs(result :: { any }) do
            table.insert(top, { userId = tonumber(entry.key) or 0, value = entry.value })
        end
        lastTop = top
    else
        topFailed = true
        warn("[Highlights] leitura do ranking falhou: " .. tostring(result))
    end
    render()
end

-- Grava no máximo uma vez por jogador, ao fim da expedição, e só se superar o melhor já guardado.
function HighlightsSystem.Flush()
    local store = weekStore()
    local toSave = pending
    pending = {}
    if not store then
        return
    end
    for userId, value in pairs(toSave) do
        inFlight += 1
        task.spawn(function()
            local saved = false
            local wait = 1
            for attempt = 1, 3 do
                local ok, err = pcall(function()
                    store:UpdateAsync(tostring(userId), function(old: number?)
                        if old and old >= value then
                            return nil
                        end
                        return value
                    end)
                end)
                if ok then
                    saved = true
                    break
                end
                warn(string.format("[Highlights] gravação falhou (%d/3): %s", attempt, tostring(err)))
                if attempt < 3 then
                    task.wait(wait)
                    wait *= 2
                end
            end
            if not saved then
                -- Não perde o saque: volta para a fila e tenta de novo no próximo fim de expedição
                pending[userId] = math.max(pending[userId] or 0, value)
            end
            inFlight -= 1
        end)
    end
    task.delay(3, HighlightsSystem.Refresh)
end

-- Manda ao jogador o ranking semanal e as histórias recentes, para a tela de Placar
function HighlightsSystem.SendBoard(player: Player)
    local top = {}
    for rank, entry in ipairs(lastTop) do
        table.insert(top, { rank = rank, userId = entry.userId, name = nameOf(entry.userId), value = entry.value })
    end
    BoardData:FireClient(player, { top = top, stories = stories, failed = topFailed })
end

function HighlightsSystem.Init()
    RequestBoard.OnServerEvent:Connect(function(player)
        if RateLimiter.Allow(player, "RequestBoard", 1, 2) then
            task.spawn(HighlightsSystem.SendBoard, player)
        end
    end)
    ExtractionSystem.Extracted:Connect(function(player: Player, receipt: any)
        local total = math.floor(receipt.total or 0)
        if total <= 0 then
            return
        end
        if not receipt.qa then -- extrações de teste do Studio não gravam no ranking real
            pending[player.UserId] = math.max(pending[player.UserId] or 0, total)
        end

        local minute = math.floor((receipt.elapsed or ExpeditionSystem.GetElapsedTime()) / 60)
        if minute >= 10 then
            addStory(string.format("%s extraiu no minuto %d", player.Name, minute))
        end
        for _, item in ipairs(receipt.items) do
            if item.type == "Relic" then
                addStory(player.Name .. " trouxe uma Relíquia")
                break
            end
        end
        render()
    end)

    NestSystem.PlayerRescued:Connect(function(rescuer: Player, captive: Player)
        addStory(string.format("%s resgatou %s do Ninho", rescuer.Name, captive.Name))
        render()
    end)

    ExpeditionSystem.Ended:Connect(function()
        HighlightsSystem.Flush()
    end)

    -- No desligamento do servidor, grava o que ficou pendente e espera as gravações terminarem
    game:BindToClose(function()
        if game:GetService("RunService"):IsStudio() then
            return
        end
        HighlightsSystem.Flush()
        local deadline = os.clock() + 20
        while inFlight > 0 and os.clock() < deadline do
            task.wait(0.2)
        end
    end)

    task.spawn(function()
        while true do
            HighlightsSystem.Refresh()
            task.wait(Config.HighlightsRefresh)
        end
    end)
end

return HighlightsSystem
