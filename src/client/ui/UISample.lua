--!strict
-- Tela de amostra dos componentes (botão "Amostra de UI" do painel QA, só no Studio): serve para conferir
-- o tema, a resposta dos botões, as abas e o encaixe em telas pequenas.
local Theme = require((script.Parent :: Instance):WaitForChild("Theme") :: ModuleScript)
local Widgets = require((script.Parent :: Instance):WaitForChild("Widgets") :: ModuleScript)
local PanelManager = require((script.Parent :: Instance):WaitForChild("PanelManager") :: ModuleScript)

local UISample = {}

local C = Theme.Color

local function buttonsTab(content: Frame)
    local row = Instance.new("Frame")
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, 0, 0, 60)
    row.Parent = content
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 12)
    layout.Parent = row

    local info = Widgets.Label(content, {
        text = "Clique nos botões: o som e a resposta devem ser claros.",
        position = UDim2.new(0, 0, 0, 74),
        size = UDim2.new(1, 0, 0, 24),
        color = C.TextDim,
    })
    Widgets.Button(row, { text = "DESCER", variant = "primary", size = UDim2.new(0, 190, 0, 56), onClick = function()
        info.Text = "Primário clicado"
    end })
    Widgets.Button(row, { text = "Normal", onClick = function()
        info.Text = "Normal clicado"
    end })
    Widgets.Button(row, { text = "Perigo", variant = "danger", onClick = function()
        info.Text = "Perigo clicado"
    end })

    local sides = Instance.new("Frame")
    sides.BackgroundTransparency = 1
    sides.Position = UDim2.new(0, 0, 0, 120)
    sides.Size = UDim2.new(1, 0, 0, 90)
    sides.Parent = content
    local sideLayout = Instance.new("UIListLayout")
    sideLayout.FillDirection = Enum.FillDirection.Horizontal
    sideLayout.Padding = UDim.new(0, 12)
    sideLayout.Parent = sides
    local names = { { "🎒", "Mochila" }, { "📜", "Contratos" }, { "🔨", "Oficina" }, { "💰", "Mercado" } }
    for index, entry in ipairs(names) do
        local side = Widgets.SideButton(sides, { emoji = entry[1], label = entry[2], onClick = function()
            info.Text = entry[2] .. " clicado"
        end })
        if index == 2 then
            side.badge.Set("!")
        elseif index == 3 then
            side.badge.Set("3")
        end
    end
end

local function cardsTab(content: Frame)
    local grid = Instance.new("Frame")
    grid.BackgroundTransparency = 1
    grid.Size = UDim2.new(1, 0, 0, 150)
    grid.Parent = content
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 12)
    layout.Parent = grid

    local specs = { { "Núcleo", "Common", 8 }, { "Núcleo raro", "Rare", 40 }, { "Relíquia", "Legendary", 400 } }
    for _, spec in ipairs(specs) do
        local card = Widgets.Card(grid, UDim2.new(0, 130, 1, 0), spec[2] :: string)
        Widgets.Label(card, { text = spec[1] :: string, position = UDim2.new(0, 8, 0, 8), size = UDim2.new(1, -16, 0, 22), font = Theme.Font.Strong, color = Theme.ForRarity(spec[2] :: string) })
        Widgets.Label(card, { text = "💎", position = UDim2.new(0, 0, 0, 36), size = UDim2.new(1, 0, 0, 54), textSize = 40, alignX = Enum.TextXAlignment.Center })
        Widgets.Label(card, { text = tostring(spec[3]) .. " moedas", position = UDim2.new(0, 8, 1, -30), size = UDim2.new(1, -16, 0, 22), color = C.Text })
        Widgets.Tooltip(card, function()
            return (spec[1] :: string) .. " (" .. (spec[2] :: string) .. ")"
        end)
    end

    local stats = Instance.new("Frame")
    stats.BackgroundTransparency = 1
    stats.Position = UDim2.new(0, 0, 0, 166)
    stats.Size = UDim2.new(1, 0, 0, 100)
    stats.Parent = content
    local statLayout = Instance.new("UIListLayout")
    statLayout.Padding = UDim.new(0, 6)
    statLayout.Parent = stats
    Widgets.StatRow(stats, "Valor agora", "420 💎", C.Gold)
    Widgets.StatRow(stats, "Peso", "3 espaços")
    Widgets.StatRow(stats, "Zona de origem", "B", C.TextDim)
end

local function barsTab(content: Frame)
    local weight = Widgets.ProgressBar(content, UDim2.new(1, 0, 0, 28))
    weight.Set(0.6, "Peso 6 / 10")
    local xp = Widgets.ProgressBar(content, UDim2.new(1, 0, 0, 28))
    xp.frame.Position = UDim2.new(0, 0, 0, 44)
    xp.Set(0.25, "XP 25 / 100")

    local fraction = 0.25
    Widgets.Button(content, { text = "+25% de XP", size = UDim2.new(0, 160, 0, 40), position = UDim2.new(0, 0, 0, 96), onClick = function()
        fraction = (fraction + 0.25) % 1.25
        xp.Set(fraction, string.format("XP %d / 100", math.floor(fraction * 100)))
    end })
end

local sample: PanelManager.Panel? = nil

function UISample.Toggle()
    if not sample then
        sample = PanelManager.Create("UISample", {
            title = "Amostra de UI",
            tabs = { "Botões", "Cartas", "Barras" },
            onTab = function(name: string, content: Frame)
                if name == "Botões" then
                    buttonsTab(content)
                elseif name == "Cartas" then
                    cardsTab(content)
                elseif name == "Barras" then
                    barsTab(content)
                end
            end,
        })
    end
    PanelManager.Toggle("UISample")
end

return UISample
