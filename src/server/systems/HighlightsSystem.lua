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

local HighlightsSystem = {}

local pending: { [number]: number } = {} -- UserId -> melhor saque desta sessão, ainda não salvo
local stories: { string } = {}
local nameCache: { [number]: string } = {}
local lastTop: { { userId: number, value: number } } = {}
local topFailed = false

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
        task.spawn(function()
            local ok, err = pcall(function()
                store:UpdateAsync(tostring(userId), function(old: number?)
                    if old and old >= value then
                        return nil
                    end
                    return value
                end)
            end)
            if not ok then
                warn("[Highlights] gravação falhou: " .. tostring(err))
            end
        end)
    end
    task.delay(3, HighlightsSystem.Refresh)
end

function HighlightsSystem.Init()
    ExtractionSystem.Extracted:Connect(function(player: Player, receipt: any)
        local total = math.floor(receipt.total or 0)
        if total <= 0 then
            return
        end
        pending[player.UserId] = math.max(pending[player.UserId] or 0, total)

        local minute = math.floor(ExpeditionSystem.GetElapsedTime() / 60)
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

    task.spawn(function()
        while true do
            HighlightsSystem.Refresh()
            task.wait(Config.HighlightsRefresh)
        end
    end)
end

return HighlightsSystem
