--!strict
-- Tela de Ajustes. Por enquanto: ligar e desligar o guia (seta no chão e marcadores). O volume da música entra no módulo de som.
-- Vale na sessão; guardar no perfil fica para quando houver mais opções.
local Theme = require((script.Parent :: Instance):WaitForChild("Theme") :: ModuleScript)
local Widgets = require((script.Parent :: Instance):WaitForChild("Widgets") :: ModuleScript)
local PanelManager = require((script.Parent :: Instance):WaitForChild("PanelManager") :: ModuleScript)
local LobbyHUD = require((script.Parent :: Instance):WaitForChild("LobbyHUD") :: ModuleScript)
local GuideState = require((script.Parent :: Instance):WaitForChild("GuideState") :: ModuleScript)
local AmbientAudio = require(((script.Parent :: Instance).Parent :: Instance):WaitForChild("audio"):WaitForChild("AmbientAudio") :: ModuleScript)

local SettingsUI = {}

local C = Theme.Color

local panel: PanelManager.Panel? = nil

local function draw(content: Frame)
    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 10)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = content

    local row = Instance.new("Frame")
    row.LayoutOrder = 1
    row.Size = UDim2.new(1, 0, 0, 70)
    row.BackgroundColor3 = C.PanelDark
    row.Parent = content
    Widgets.AddCorner(row, UDim.new(0, 8))
    Widgets.AddStroke(row, C.Line, 1)
    Widgets.Label(row, { text = "Guia", position = UDim2.new(0, 14, 0, 8), size = UDim2.new(1, -200, 0, 26), font = Theme.Font.Strong, textSize = Theme.TextSize.Heading, color = C.Gold })
    Widgets.Label(row, { text = "Seta no chão e nomes sobre os lugares da superfície.", position = UDim2.new(0, 14, 0, 36), size = UDim2.new(1, -200, 0, 24), color = C.TextDim, textSize = Theme.TextSize.Small })
    local enabled = GuideState.IsEnabled()
    Widgets.Button(row, {
        text = if enabled then "Ligado" else "Desligado",
        variant = if enabled then "primary" else "normal",
        size = UDim2.new(0, 150, 0, 40),
        position = UDim2.new(1, -164, 0.5, -20),
        onClick = function()
            GuideState.Set(not GuideState.IsEnabled())
            local active = panel
            if active then
                active.Refresh()
            end
        end,
    })

    local musicRow = Instance.new("Frame")
    musicRow.Size = UDim2.new(1, 0, 0, 70)
    musicRow.BackgroundColor3 = C.PanelDark
    musicRow.LayoutOrder = 2
    musicRow.Parent = content
    Widgets.AddCorner(musicRow, UDim.new(0, 8))
    Widgets.AddStroke(musicRow, C.Line, 1)
    Widgets.Label(musicRow, { text = "Música", position = UDim2.new(0, 14, 0, 8), size = UDim2.new(1, -200, 0, 26), font = Theme.Font.Strong, textSize = Theme.TextSize.Heading, color = C.Gold })
    Widgets.Label(musicRow, { text = "Música da mina e da vila. O som da caverna não muda.", position = UDim2.new(0, 14, 0, 36), size = UDim2.new(1, -200, 0, 24), color = C.TextDim, textSize = Theme.TextSize.Small })
    local scale = AmbientAudio.GetMusicScale()
    Widgets.Button(musicRow, {
        text = if scale >= 1 then "Alta" elseif scale > 0 then "Baixa" else "Desligada",
        variant = if scale > 0 then "primary" else "normal",
        size = UDim2.new(0, 150, 0, 40),
        position = UDim2.new(1, -164, 0.5, -20),
        onClick = function()
            local current = AmbientAudio.GetMusicScale()
            AmbientAudio.SetMusicScale(if current >= 1 then 0.5 elseif current > 0 then 0 else 1)
            local active = panel
            if active then
                active.Refresh()
            end
        end,
    })
end

function SettingsUI.Init()
    panel = PanelManager.Create("settings", {
        title = "Ajustes",
        onTab = function(_name: string, content: Frame)
            draw(content)
        end,
    })
    LobbyHUD.Register("settings", function()
        PanelManager.Toggle("settings")
    end)
end

return SettingsUI
