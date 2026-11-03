--!strict
-- Recompensa diária: 7 dias de moedas, uma por dia. Faltar um dia não zera a sequência, só não avança.
-- O servidor decide se pode receber (um pedido por dia UTC); aqui só aparece o estado e o botão.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local Theme = require((script.Parent :: Instance):WaitForChild("Theme") :: ModuleScript)
local Widgets = require((script.Parent :: Instance):WaitForChild("Widgets") :: ModuleScript)
local PanelManager = require((script.Parent :: Instance):WaitForChild("PanelManager") :: ModuleScript)
local LobbyHUD = require((script.Parent :: Instance):WaitForChild("LobbyHUD") :: ModuleScript)
local ProfileHUD = require((script.Parent :: Instance):WaitForChild("ProfileHUD") :: ModuleScript)

local ClaimDaily = ReplicatedStorage:WaitForChild("EcosRemotes"):WaitForChild("ClaimDaily") :: RemoteEvent

local DailyUI = {}

local C = Theme.Color

local panel: PanelManager.Panel? = nil

local function draw(content: Frame)
    local profile = ProfileHUD.GetProfile() :: { daily: { index: number, amount: number, available: boolean }? }?
    local daily = if profile then profile.daily else nil
    if not daily then
        Widgets.Label(content, { text = "Carregando...", size = UDim2.new(1, 0, 0, 30) })
        return
    end
    Widgets.Label(content, {
        text = "Volte todo dia por um presente. Se faltar um dia, nada se perde: a sequência só espera por você.",
        size = UDim2.new(1, 0, 0, 40),
        wrapped = true,
        color = C.TextDim,
    })
    local row = Instance.new("Frame")
    row.BackgroundTransparency = 1
    row.Position = UDim2.new(0, 0, 0, 52)
    row.Size = UDim2.new(1, 0, 0, 120)
    row.Parent = content
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 8)
    layout.Parent = row
    local total = #Config.DailyRewards
    for day = 1, total do
        local isCurrent = day == daily.index
        local done = day < daily.index
        local card = Widgets.Card(row, UDim2.new(1 / total, -8 * (total - 1) / total, 1, 0), if isCurrent then "Legendary" else "Common")
        if isCurrent then
            card.BackgroundColor3 = C.Wood
        end
        Widgets.Label(card, { text = "Dia " .. day, position = UDim2.new(0, 0, 0, 6), size = UDim2.new(1, 0, 0, 22), font = Theme.Font.Strong, textSize = Theme.TextSize.Small, alignX = Enum.TextXAlignment.Center, color = if isCurrent then C.Gold else C.TextDim })
        Widgets.Label(card, { text = if done then "✅" else "🎁", position = UDim2.new(0, 0, 0, 30), size = UDim2.new(1, 0, 0, 40), textSize = 28, alignX = Enum.TextXAlignment.Center })
        Widgets.Label(card, { text = string.format("%d 💎", Config.DailyRewards[day]), position = UDim2.new(0, 0, 1, -30), size = UDim2.new(1, 0, 0, 22), textSize = Theme.TextSize.Small, alignX = Enum.TextXAlignment.Center })
    end
    local button = Widgets.Button(content, {
        text = if daily.available then string.format("Receber %d 💎", daily.amount) else "Volte amanhã",
        variant = if daily.available then "primary" else "normal",
        size = UDim2.new(0, 260, 0, 50),
        position = UDim2.new(0.5, -130, 0, 190),
        onClick = function()
            if daily.available then
                ClaimDaily:FireServer()
            end
        end,
    })
    button.Active = daily.available
    button.BackgroundTransparency = if daily.available then 0 else 0.5
end

function DailyUI.Init()
    local created = PanelManager.Create("daily", {
        title = "Recompensa diária",
        onTab = function(_name: string, content: Frame)
            draw(content)
        end,
    })
    panel = created
    LobbyHUD.Register("daily", function()
        PanelManager.Toggle("daily")
    end)
    ProfileHUD.OnChanged(function()
        local active = panel
        if active then
            active.Refresh()
        end
    end)
end

return DailyUI
