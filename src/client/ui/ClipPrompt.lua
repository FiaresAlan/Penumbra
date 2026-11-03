--!strict
-- Tela de clipe: oferece Salvar e Compartilhar a gravação mais recente. Aparece só se houver gravação válida.
local CaptureService = game:GetService("CaptureService")
local Players = game:GetService("Players")

local Theme = require(script.Parent:WaitForChild("Theme") :: ModuleScript) :: any

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ClipPrompt = {}

local frame: Frame? = nil
local statusLabel: TextLabel? = nil
local currentCapture: any = nil

local function setStatus(text: string)
    if statusLabel then
        statusLabel.Text = text
    end
end

local function makeButton(parent: Instance, text: string, x: number, onClick: () -> ()): TextButton
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 120, 0, 36)
    button.Position = UDim2.new(0, x, 0, 44)
    button.BackgroundColor3 = Theme.Accent.market[1]
    button.TextColor3 = Theme.Color.Text
    button.Font = Enum.Font.GothamBold
    button.TextSize = 14
    button.Text = text
    button.Parent = parent
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button
    button.Activated:Connect(onClick)
    return button
end

function ClipPrompt.Init()
    local gui = Instance.new("ScreenGui")
    gui.Name = "EcosClipPrompt"
    gui.ResetOnSpawn = false
    gui.Parent = playerGui

    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(0, 280, 0, 120)
    panel.Position = UDim2.new(0.5, -140, 0.72, 0)
    panel.BackgroundColor3 = Theme.Color.PanelBg
    panel.BackgroundTransparency = 0.05
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.Parent = gui
    frame = panel

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = panel
    local panelStroke = Instance.new("UIStroke")
    panelStroke.Color = Theme.Color.Magenta
    panelStroke.Thickness = 2
    panelStroke.Parent = panel

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -16, 0, 30)
    title.Position = UDim2.new(0, 8, 0, 6)
    title.BackgroundTransparency = 1
    title.TextColor3 = Theme.Color.Gold
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.Text = "Seu clipe está pronto"
    title.Parent = panel

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -16, 0, 24)
    status.Position = UDim2.new(0, 8, 0, 88)
    status.BackgroundTransparency = 1
    status.TextColor3 = Theme.Color.TextDim
    status.Font = Enum.Font.Gotham
    status.TextSize = 13
    status.Text = ""
    status.Parent = panel
    statusLabel = status

    makeButton(panel, "Salvar", 14, function()
        if not currentCapture then
            return
        end
        local capture = currentCapture
        local ok, err = pcall(function()
            CaptureService:PromptSaveCapturesToGallery({ capture }, function()
                setStatus("Clipe salvo")
            end)
        end)
        if not ok then
            setStatus("Não foi possível salvar")
            warn("[Clips] salvar falhou: " .. tostring(err))
        end
    end)

    makeButton(panel, "Compartilhar", 146, function()
        if not currentCapture then
            return
        end
        local capture = currentCapture
        local ok, err = pcall(function()
            local content = Content.fromObject(capture)
            CaptureService:PromptShareCapture(content, "ecos-clipe", function()
                setStatus("Compartilhado")
            end, function()
                setStatus("Compartilhamento cancelado")
            end)
        end)
        if not ok then
            setStatus("Não foi possível compartilhar")
            warn("[Clips] compartilhar falhou: " .. tostring(err))
        end
    end)

    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 26, 0, 26)
    close.Position = UDim2.new(1, -32, 0, 6)
    close.BackgroundColor3 = Theme.Color.Danger
    close.TextColor3 = Theme.Color.Text
    close.Font = Enum.Font.GothamBold
    close.TextSize = 14
    close.Text = "X"
    close.Parent = panel
    close.Activated:Connect(function()
        panel.Visible = false
    end)
end

function ClipPrompt.Show(capture: any)
    currentCapture = capture
    setStatus("")
    if frame then
        frame.Visible = true
    end
end

function ClipPrompt.Hide()
    currentCapture = nil
    if frame then
        frame.Visible = false
    end
end

return ClipPrompt
