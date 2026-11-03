--!strict
-- Placar: maiores saques da semana (top 10) e histórias recentes do servidor. O cliente pede os dados ao abrir e só mostra.
-- Sem dados ou com o DataStore fora do ar, aparece uma mensagem neutra e o jogo segue.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require((script.Parent :: Instance):WaitForChild("Theme") :: ModuleScript)
local Widgets = require((script.Parent :: Instance):WaitForChild("Widgets") :: ModuleScript)
local PanelManager = require((script.Parent :: Instance):WaitForChild("PanelManager") :: ModuleScript)
local LobbyHUD = require((script.Parent :: Instance):WaitForChild("LobbyHUD") :: ModuleScript)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("EcosRemotes")
local RequestBoard = remotes:WaitForChild("RequestBoard") :: RemoteEvent
local BoardData = remotes:WaitForChild("BoardData") :: RemoteEvent

local C = Theme.Color

local BoardUI = {}

type Entry = { rank: number, userId: number, name: string, value: number }

local top: { Entry } = {}
local stories: { string } = {}
local failed = false
local loaded = false
local panel: PanelManager.Panel? = nil

local MEDALS = { "🥇", "🥈", "🥉" }

local function draw(name: string, content: Frame)
    if not loaded then
        Widgets.Label(content, { text = "Buscando o placar...", size = UDim2.new(1, 0, 0, 30), color = C.TextDim })
        return
    end
    if name == "Histórias" then
        if #stories == 0 then
            Widgets.Label(content, { text = "Nenhuma história ainda. Extraia ou resgate alguém para aparecer aqui!", size = UDim2.new(1, 0, 0, 50), wrapped = true, color = C.TextDim })
            return
        end
        local list = Instance.new("UIListLayout")
        list.Padding = UDim.new(0, 8)
        list.SortOrder = Enum.SortOrder.LayoutOrder
        list.Parent = content
        for _, story in ipairs(stories) do
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 46)
            row.BackgroundColor3 = C.PanelDark
            row.Parent = content
            Widgets.AddCorner(row, UDim.new(0, 8))
            Widgets.Label(row, { text = "📜 " .. story, position = UDim2.new(0, 12, 0, 0), size = UDim2.new(1, -24, 1, 0), wrapped = true })
        end
        return
    end
    if failed or #top == 0 then
        Widgets.Label(content, {
            text = if failed then "O placar está indisponível agora. Tente de novo mais tarde." else "Ninguém no placar desta semana ainda. Seja o primeiro a trazer um saque!",
            size = UDim2.new(1, 0, 0, 50),
            wrapped = true,
            color = C.TextDim,
        })
        return
    end
    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 6)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = content
    for _, entry in ipairs(top) do
        local mine = entry.userId == player.UserId
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 34)
        row.BackgroundColor3 = if mine then C.Wood else C.PanelDark
        row.Parent = content
        Widgets.AddCorner(row, UDim.new(0, 8))
        Widgets.Label(row, { text = MEDALS[entry.rank] or tostring(entry.rank), position = UDim2.new(0, 12, 0, 0), size = UDim2.new(0, 40, 1, 0), textSize = Theme.TextSize.Heading, font = Theme.Font.Strong })
        Widgets.Label(row, { text = entry.name, position = UDim2.new(0, 60, 0, 0), size = UDim2.new(0.55, 0, 1, 0), font = Theme.Font.Strong, color = if mine then C.Gold else C.Text })
        Widgets.Label(row, { text = string.format("%d 💎", entry.value), position = UDim2.new(0.6, 0, 0, 0), size = UDim2.new(0.4, -12, 1, 0), alignX = Enum.TextXAlignment.Right, color = C.Gold, font = Theme.Font.Strong })
    end
end

function BoardUI.Init()
    local created = PanelManager.Create("board", {
        title = "Placar da semana",
        tabs = { "Maiores saques", "Histórias" },
        onTab = draw,
        onOpen = function()
            RequestBoard:FireServer()
        end,
    })
    panel = created
    LobbyHUD.Register("board", function()
        PanelManager.Toggle("board")
    end)
    BoardData.OnClientEvent:Connect(function(data: unknown)
        if typeof(data) ~= "table" then
            return
        end
        local info = data :: { [string]: any }
        top = {}
        if typeof(info.top) == "table" then
            for _, raw in ipairs(info.top) do
                if typeof(raw) == "table" and typeof(raw.name) == "string" and typeof(raw.value) == "number" and typeof(raw.rank) == "number" then
                    table.insert(top, { rank = raw.rank, userId = if typeof(raw.userId) == "number" then raw.userId else 0, name = raw.name, value = raw.value })
                end
            end
        end
        stories = {}
        if typeof(info.stories) == "table" then
            for _, story in ipairs(info.stories) do
                if typeof(story) == "string" then
                    table.insert(stories, story)
                end
            end
        end
        failed = info.failed == true
        loaded = true
        local active = panel
        if active then
            active.Refresh()
        end
    end)
end

return BoardUI
