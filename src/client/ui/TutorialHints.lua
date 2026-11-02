--!strict
-- Dicas curtas na primeira descida da sessão. Só texto na tela; não decide nada.
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local TutorialHints = {}

local HINTS = {
    "O Guardião não enxerga: ele ouve.",
    "Parado você está seguro. Andar faz barulho. Segure Ctrl para andar devagar.",
    "Núcleos e Relíquias pesam e aumentam o barulho. Volte ao elevador para extrair.",
    "Quanto mais tempo na caverna, mais valem os itens, e mais furioso fica o Guardião.",
}

local shown = false
local label: TextLabel? = nil

function TutorialHints.Init()
    local gui = playerGui:WaitForChild("EcosHUD")
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(0, 520, 0, 52)
    text.Position = UDim2.new(0.5, -260, 0.3, 0)
    text.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    text.BackgroundTransparency = 0.45
    text.TextColor3 = Color3.fromRGB(235, 235, 245)
    text.Font = Enum.Font.GothamMedium
    text.TextSize = 18
    text.TextWrapped = true
    text.Visible = false
    text.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = text
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
