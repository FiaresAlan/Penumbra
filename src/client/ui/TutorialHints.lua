--!strict
-- Dicas curtas na primeira descida da sessão. Só texto na tela; não decide nada.
local Players = game:GetService("Players")

local Theme = require(script.Parent:WaitForChild("Theme") :: ModuleScript) :: any

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local TutorialHints = {}

local HINTS = {
    "O Guardião não enxerga: ele ouve.",
    "Parado você está seguro. Andar faz barulho. Segure Ctrl para andar devagar.",
    "Núcleos e Relíquias pesam e aumentam o barulho. Volte ao elevador para extrair.",
    "Aperte I para ver os espaços da mochila e o baú. O jogo não pausa.",
    "Quanto mais tempo na caverna, mais valem os itens, e mais furioso fica o Guardião.",
}

local shown = false
local label: TextLabel? = nil

function TutorialHints.Init()
    local gui = playerGui:WaitForChild("EcosHUD")
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(0, 520, 0, 52)
    text.Position = UDim2.new(0.5, -260, 0.3, 0)
    text.BackgroundColor3 = Theme.Color.PanelBg
    text.BackgroundTransparency = 0.08
    text.TextColor3 = Theme.Color.Text
    text.Font = Theme.Font.Body
    text.TextSize = 18
    text.TextWrapped = true
    text.Visible = false
    text.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = text
    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.Color.Cyan
    stroke.Thickness = 2
    stroke.Parent = text
    label = text
end

-- Chamado quando o jogador entra na caverna
function TutorialHints.OnEnterCave()
    if shown or not label then
        return
    end
    shown = true
    task.spawn(function()
        for _, hint in ipairs(HINTS) do
            if label then
                label.Text = hint
                label.Visible = true
            end
            task.wait(6)
        end
        if label then
            label.Visible = false
        end
    end)
end

return TutorialHints
