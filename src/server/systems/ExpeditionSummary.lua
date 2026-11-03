--!strict
-- Resumo do fim de cada expedição: quem extraiu, quanto saqueou e quem resgatou. O servidor junta tudo e manda a cada
-- participante; o cliente só mostra. Títulos de destaque: "Maior saque" e "Voltou para salvar".
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local systems = script.Parent :: Instance
local Enums = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums") :: ModuleScript)
local PlayerState = require(systems:WaitForChild("PlayerState") :: ModuleScript)
local ExpeditionSystem = require(systems:WaitForChild("ExpeditionSystem") :: ModuleScript)
local ExtractionSystem = require(systems:WaitForChild("ExtractionSystem") :: ModuleScript)
local NestSystem = require(systems:WaitForChild("NestSystem") :: ModuleScript)

local SummaryRemote = ReplicatedStorage:WaitForChild("EcosRemotes"):WaitForChild("ExpeditionSummary") :: RemoteEvent

local ExpeditionSummary = {}

type Entry = { name: string, userId: number, value: number, items: number, rescues: number, extracted: boolean }

local entries: { [number]: Entry } = {} -- por UserId, para sobreviver a quem sai do servidor

local function entryFor(player: Player): Entry
    local entry = entries[player.UserId]
    if not entry then
        entry = { name = player.DisplayName, userId = player.UserId, value = 0, items = 0, rescues = 0, extracted = false }
        entries[player.UserId] = entry
    end
    return entry
end

local function build(outcome: string): { [string]: any }
    local list: { Entry } = {}
    for _, entry in pairs(entries) do
        table.insert(list, entry)
    end
    table.sort(list, function(a: Entry, b: Entry)
        return a.value > b.value
    end)

    local highlights: { { title: string, name: string, userId: number, value: number } } = {}
    local top = list[1]
    if top and top.value > 0 then
        table.insert(highlights, { title = "Maior saque", name = top.name, userId = top.userId, value = top.value })
    end
    local savior: Entry? = nil
    for _, entry in ipairs(list) do
        if entry.rescues > 0 and (not savior or entry.rescues > savior.rescues) then
            savior = entry
        end
    end
    if savior then
        table.insert(highlights, { title = "Voltou para salvar", name = savior.name, userId = savior.userId, value = savior.rescues })
    end
    local players: { { [string]: any } } = {}
    for _, entry in ipairs(list) do
        table.insert(players, { name = entry.name, userId = entry.userId, value = entry.value, items = entry.items, extracted = entry.extracted })
    end
    return { outcome = outcome, players = players, highlights = highlights }
end

function ExpeditionSummary.Init()
    ExpeditionSystem.Started:Connect(function()
        entries = {}
        for _, player in ipairs(PlayerState.GetPlayersIn(Enums.PlayerLocation.Cave)) do
            entryFor(player)
        end
    end)
    ExtractionSystem.Extracted:Connect(function(player: Player, receipt: any)
        local entry = entryFor(player)
        entry.extracted = true
        entry.value += receipt.total
        entry.items += #receipt.items
    end)
    NestSystem.PlayerRescued:Connect(function(rescuer: Player)
        entryFor(rescuer).rescues += 1
    end)
    ExpeditionSystem.Ended:Connect(function(outcome: string)
        local summary = build(outcome)
        for userId in pairs(entries) do
            local player = Players:GetPlayerByUserId(userId)
            if player then
                SummaryRemote:FireClient(player, summary)
            end
        end
    end)
end

return ExpeditionSummary
