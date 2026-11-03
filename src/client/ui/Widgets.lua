--!strict
-- Peças de UI reutilizáveis, todas no tema de Theme.lua: botões, botões laterais com selo, abas, cartas,
-- linhas de atributo, barras de progresso e dica flutuante. Nada aqui fala com o servidor.
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Theme = require((script.Parent :: Instance):WaitForChild("Theme") :: ModuleScript)

local Widgets = {}

local C = Theme.Color
local QUICK = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local clickSound: Sound? = nil

local function playClick()
    if not clickSound then
        local sound = Instance.new("Sound")
        sound.Name = "EcosUIClick"
        sound.SoundId = "rbxasset://sounds/button.wav"
        sound.Volume = 0.35
        sound.Parent = SoundService
        clickSound = sound
    end
    local sound = clickSound
    if sound then
        sound:Play()
    end
end

local function addCorner(parent: Instance, radius: UDim?): UICorner
    local corner = Instance.new("UICorner")
    corner.CornerRadius = radius or Theme.CornerRadius
    corner.Parent = parent
    return corner
end

local function addStroke(parent: Instance, color: Color3, thickness: number): UIStroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = thickness
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

-- Resposta ao passar o mouse e ao apertar: cresce um pouco e escurece ao clicar
local function addFeedback(button: GuiButton, base: Color3, hover: Color3)
    local scale = Instance.new("UIScale")
    scale.Parent = button
    button.MouseEnter:Connect(function()
        TweenService:Create(scale, QUICK, { Scale = 1.04 }):Play()
        TweenService:Create(button, QUICK, { BackgroundColor3 = hover }):Play()
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(scale, QUICK, { Scale = 1 }):Play()
        TweenService:Create(button, QUICK, { BackgroundColor3 = base }):Play()
    end)
    button.MouseButton1Down:Connect(function()
        TweenService:Create(scale, QUICK, { Scale = 0.96 }):Play()
    end)
    button.MouseButton1Up:Connect(function()
        TweenService:Create(scale, QUICK, { Scale = 1.04 }):Play()
    end)
end

local function lighten(color: Color3, amount: number): Color3
    return color:Lerp(Color3.new(1, 1, 1), amount)
end

export type LabelOptions = {
    text: string?,
    size: UDim2?,
    position: UDim2?,
    font: Enum.Font?,
    textSize: number?,
    color: Color3?,
    alignX: Enum.TextXAlignment?,
    wrapped: boolean?,
}

function Widgets.Label(parent: Instance, opts: LabelOptions): TextLabel
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = opts.size or UDim2.new(1, 0, 0, 24)
    label.Position = opts.position or UDim2.new()
    label.Font = opts.font or Theme.Font.Body
    label.TextSize = opts.textSize or Theme.TextSize.Body
    label.TextColor3 = opts.color or C.Text
    label.TextXAlignment = opts.alignX or Enum.TextXAlignment.Left
    label.TextWrapped = opts.wrapped or false
    label.Text = opts.text or ""
    label.Parent = parent
    return label
end

export type ButtonOptions = {
    text: string,
    variant: string?, -- "primary" (padrão de ação), "normal" ou "danger"
    size: UDim2?,
    position: UDim2?,
    onClick: (() -> ())?,
}

function Widgets.Button(parent: Instance, opts: ButtonOptions): TextButton
    local variant = opts.variant or "normal"
    local base = if variant == "primary" then C.Amber elseif variant == "danger" then C.Danger else C.Wood
    local textColor = if variant == "primary" then C.TextDark else C.Text

    local button = Instance.new("TextButton")
    button.AutoButtonColor = false
    button.Size = opts.size or UDim2.new(0, 180, 0, 44)
    button.Position = opts.position or UDim2.new()
    button.BackgroundColor3 = base
    button.TextColor3 = textColor
    button.Font = Theme.Font.Strong
    button.TextSize = if variant == "primary" then Theme.TextSize.Heading else Theme.TextSize.Body
    button.Text = opts.text
    button.Parent = parent
    addCorner(button)
    addStroke(button, if variant == "primary" then C.Gold else C.Line, 2)
    addFeedback(button, base, lighten(base, 0.18))

    local onClick = opts.onClick
    button.Activated:Connect(function()
        playClick()
        if onClick then
            onClick()
        end
    end)
    return button
end

export type Badge = { label: TextLabel, Set: (value: string?) -> () }

-- Selo vermelho no canto de um botão. Set(nil) esconde; Set("!") ou Set("3") mostra.
function Widgets.Badge(parent: GuiObject): Badge
    local label = Instance.new("TextLabel")
    label.AnchorPoint = Vector2.new(1, 0)
    label.Position = UDim2.new(1, 6, 0, -6)
    label.Size = UDim2.new(0, 24, 0, 24)
    label.BackgroundColor3 = C.Danger
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Theme.Font.Strong
    label.TextSize = 14
    label.Visible = false
    label.ZIndex = parent.ZIndex + 5
    label.Parent = parent
    addCorner(label, UDim.new(1, 0))
    addStroke(label, Color3.new(1, 1, 1), 2)
    return {
        label = label,
        Set = function(value: string?)
            label.Visible = value ~= nil
            if value then
                label.Text = value
            end
        end,
    }
end

export type SideButtonOptions = { emoji: string, label: string, onClick: (() -> ())?, accent: { Color3 }? }
export type SideButton = { button: TextButton, badge: Badge }

-- Botão quadrado de lateral de tela: emoji grande, nome embaixo e selo opcional
function Widgets.SideButton(parent: Instance, opts: SideButtonOptions): SideButton
    local button = Instance.new("TextButton")
    button.AutoButtonColor = false
    button.Size = UDim2.new(0, 76, 0, 76)
    local base = if opts.accent then opts.accent[1] else C.TileDark
    local light = if opts.accent then opts.accent[2] else C.Tile
    button.BackgroundColor3 = base
    button.Text = ""
    button.Parent = parent
    addCorner(button)
    addStroke(button, C.Text, 2)
    addFeedback(button, base, light)

    Widgets.Label(button, {
        text = opts.emoji,
        size = UDim2.new(1, 0, 0, 44),
        position = UDim2.new(0, 0, 0, 6),
        textSize = 30,
        alignX = Enum.TextXAlignment.Center,
    })
    Widgets.Label(button, {
        text = opts.label,
        size = UDim2.new(1, -4, 0, 20),
        position = UDim2.new(0, 2, 1, -24),
        font = Theme.Font.Strong,
        textSize = Theme.TextSize.Small,
        alignX = Enum.TextXAlignment.Center,
    })

    local onClick = opts.onClick
    button.Activated:Connect(function()
        playClick()
        if onClick then
            onClick()
        end
    end)
    return { button = button, badge = Widgets.Badge(button) }
end

export type Tabs = { frame: Frame, Select: (name: string) -> (), Current: () -> string }

-- Linha de abas. onSelect é chamado só ao trocar de aba; `initial` escolhe a aba já marcada, sem chamar onSelect.
function Widgets.Tabs(parent: Instance, names: { string }, onSelect: (string) -> (), initial: string?): Tabs
    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 0, 44)
    frame.Parent = parent
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 8)
    layout.Parent = frame

    local buttons: { [string]: TextButton } = {}
    local current = initial or names[1] or ""

    local function paint()
        for name, button in pairs(buttons) do
            local selected = name == current
            button.BackgroundColor3 = if selected then C.Amber else C.Wood
            button.TextColor3 = if selected then C.TextDark else C.Text
        end
    end

    local function select(name: string)
        if not buttons[name] then
            return
        end
        current = name
        paint()
        onSelect(name)
    end

    for _, name in ipairs(names) do
        local button = Instance.new("TextButton")
        button.AutoButtonColor = false
        button.Size = UDim2.new(0, 130, 1, 0)
        button.Font = Theme.Font.Strong
        button.TextSize = Theme.TextSize.Body
        button.Text = name
        button.Parent = frame
        addCorner(button)
        buttons[name] = button
        button.Activated:Connect(function()
            playClick()
            select(name)
        end)
    end
    paint()
    return { frame = frame, Select = select, Current = function() return current end }
end

-- Moldura de carta com a cor da raridade na borda
function Widgets.Card(parent: Instance, size: UDim2, rarity: string?): Frame
    local card = Instance.new("Frame")
    card.Size = size
    card.BackgroundColor3 = C.PanelDark
    card.Parent = parent
    addCorner(card)
    addStroke(card, Theme.ForRarity(rarity), 2)
    return card
end

function Widgets.StatRow(parent: Instance, name: string, value: string, valueColor: Color3?): Frame
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 30)
    row.BackgroundColor3 = C.PanelDark
    row.Parent = parent
    addCorner(row, UDim.new(0, 6))
    Widgets.Label(row, { text = name, position = UDim2.new(0, 10, 0, 0), size = UDim2.new(0.6, 0, 1, 0), color = C.TextDim })
    Widgets.Label(row, {
        text = value,
        position = UDim2.new(0.5, 0, 0, 0),
        size = UDim2.new(0.5, -10, 1, 0),
        font = Theme.Font.Strong,
        color = valueColor or C.Text,
        alignX = Enum.TextXAlignment.Right,
    })
    return row
end

export type ProgressBar = { frame: Frame, Set: (fraction: number, text: string?) -> () }

function Widgets.ProgressBar(parent: Instance, size: UDim2): ProgressBar
    local frame = Instance.new("Frame")
    frame.Size = size
    frame.BackgroundColor3 = C.PanelDark
    frame.Parent = parent
    addCorner(frame, UDim.new(0, 8))
    addStroke(frame, C.Line, 1)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.fromScale(0, 1)
    fill.BackgroundColor3 = C.Amber
    fill.Parent = frame
    addCorner(fill, UDim.new(0, 8))

    local text = Widgets.Label(frame, {
        size = UDim2.fromScale(1, 1),
        font = Theme.Font.Strong,
        textSize = Theme.TextSize.Small,
        alignX = Enum.TextXAlignment.Center,
    })
    text.ZIndex = 2

    return {
        frame = frame,
        Set = function(fraction: number, label: string?)
            local clamped = math.clamp(fraction, 0, 1)
            if clamped ~= clamped then
                clamped = 0
            end
            TweenService:Create(fill, TweenInfo.new(0.25), { Size = UDim2.fromScale(clamped, 1) }):Play()
            text.Text = label or ""
        end,
    }
end

-- Dica flutuante junto ao mouse. Só existe com mouse: no toque, o detalhe deve abrir por toque na própria tela.
local tooltipGui: ScreenGui? = nil
local tooltipLabel: TextLabel? = nil

local function ensureTooltip(): TextLabel
    if tooltipLabel and tooltipGui and tooltipGui.Parent then
        return tooltipLabel
    end
    local gui = Instance.new("ScreenGui")
    gui.Name = "EcosTooltip"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = Theme.PanelOrder + 5
    gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    local label = Instance.new("TextLabel")
    label.AutomaticSize = Enum.AutomaticSize.XY
    label.BackgroundColor3 = C.PanelDark
    label.TextColor3 = C.Text
    label.Font = Theme.Font.Body
    label.TextSize = Theme.TextSize.Small
    label.TextWrapped = false
    label.Visible = false
    label.Parent = gui
    addCorner(label, UDim.new(0, 6))
    addStroke(label, C.Amber, 1)
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 8)
    padding.PaddingRight = UDim.new(0, 8)
    padding.PaddingTop = UDim.new(0, 5)
    padding.PaddingBottom = UDim.new(0, 5)
    padding.Parent = label
    tooltipGui = gui
    tooltipLabel = label
    return label
end

function Widgets.Tooltip(target: GuiObject, getText: () -> string)
    target.MouseEnter:Connect(function()
        local label = ensureTooltip()
        label.Text = getText()
        label.Visible = true
    end)
    target.MouseMoved:Connect(function()
        local label = ensureTooltip()
        local mouse = UserInputService:GetMouseLocation()
        -- GetMouseLocation conta a barra superior; o ScreenGui ignora o inset, então as coordenadas batem
        label.Position = UDim2.fromOffset(mouse.X + 14, mouse.Y + 6)
    end)
    local function hide()
        if tooltipLabel then
            tooltipLabel.Visible = false
        end
    end
    target.MouseLeave:Connect(hide)
    -- A carta pode ser destruída com o mouse em cima (troca de aba): sem isso a dica ficaria presa
    target.Destroying:Connect(hide)
end

Widgets.AddCorner = addCorner
Widgets.AddStroke = addStroke

return Widgets
