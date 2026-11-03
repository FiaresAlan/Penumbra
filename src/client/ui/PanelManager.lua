--!strict
-- Painéis de tela cheia (mochila, lojas, perfil...). Um painel por vez; abre e fecha com animação rápida,
-- fecha pelo X, clicando fora ou ao abrir o menu do Roblox (Esc). Nunca pausa o jogo: o personagem segue andando.
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Theme = require((script.Parent :: Instance):WaitForChild("Theme") :: ModuleScript)
local Widgets = require((script.Parent :: Instance):WaitForChild("Widgets") :: ModuleScript)

local C = Theme.Color

export type PanelOptions = {
    title: string,
    tabs: { string }?,
    onTab: ((name: string, content: Frame) -> ())?,
    onOpen: (() -> ())?,
    onClose: (() -> ())?,
}

export type Panel = {
    id: string,
    Content: Frame,
    SetTitle: (text: string) -> (),
    Open: () -> (),
    Close: () -> (),
    IsOpen: () -> boolean,
    SelectTab: (name: string) -> (),
    Refresh: () -> (), -- redesenha a aba atual (ou o painel sem abas) com os dados mais novos
}

local PanelManager = {}

local screenGui: ScreenGui? = nil
local panels: { [string]: Panel } = {}
local openId: string? = nil
local menuConnected = false

local OPEN_TIME = 0.15

local function ensureGui(): ScreenGui
    local gui = screenGui
    if gui and gui.Parent then
        return gui
    end
    local created = Instance.new("ScreenGui")
    created.Name = "EcosPanels"
    created.ResetOnSpawn = false
    created.IgnoreGuiInset = true
    created.DisplayOrder = Theme.PanelOrder
    created.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    created.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    screenGui = created
    return created
end

function PanelManager.CloseAll()
    local current = openId
    if current and panels[current] then
        panels[current].Close()
    end
end

function PanelManager.Current(): string?
    return openId
end

function PanelManager.Create(id: string, opts: PanelOptions): Panel
    local existing = panels[id]
    if existing then
        return existing
    end

    local gui = ensureGui()
    if not menuConnected then
        menuConnected = true
        -- Esc abre o menu do Roblox: o painel fecha para não ficar por baixo dele
        GuiService.MenuOpened:Connect(PanelManager.CloseAll)
    end

    local overlay = Instance.new("TextButton")
    overlay.Name = id
    overlay.AutoButtonColor = false
    overlay.Text = ""
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.BackgroundColor3 = C.Overlay
    overlay.BackgroundTransparency = 1
    overlay.Visible = false
    overlay.Parent = gui

    -- A janela é um botão mudo: um clique em área vazia dela não chega ao fundo (que fecha o painel)
    local window = Instance.new("TextButton")
    window.AutoButtonColor = false
    window.Text = ""
    window.AnchorPoint = Vector2.new(0.5, 0.5)
    window.Position = UDim2.fromScale(0.5, 0.5)
    window.Size = UDim2.fromScale(0.84, 0.82)
    window.BackgroundColor3 = C.PanelBg
    window.Parent = overlay
    Widgets.AddCorner(window, UDim.new(0, 14))
    Widgets.AddStroke(window, C.Amber, 3)
    local limit = Instance.new("UISizeConstraint")
    limit.MaxSize = Vector2.new(1040, 660)
    limit.MinSize = Vector2.new(300, 240)
    limit.Parent = window
    local scale = Instance.new("UIScale")
    scale.Scale = 0.92
    scale.Parent = window

    local titleLabel = Widgets.Label(window, {
        text = opts.title,
        position = UDim2.new(0, 20, 0, 10),
        size = UDim2.new(1, -90, 0, 44),
        font = Theme.Font.Title,
        textSize = Theme.TextSize.Title,
        color = C.Gold,
    })

    local panelRef: { value: Panel? } = { value = nil }
    local closeButton = Widgets.Button(window, {
        text = "X",
        variant = "danger",
        size = UDim2.new(0, 46, 0, 46),
        position = UDim2.new(1, -58, 0, 8),
        onClick = function()
            local panel = panelRef.value
            if panel then
                panel.Close()
            end
        end,
    })
    closeButton.TextSize = 22

    local top = 64
    local tabs: Widgets.Tabs? = nil
    local content = Instance.new("Frame")
    content.BackgroundTransparency = 1
    content.Parent = window

    local function layoutContent(withTabs: boolean)
        local offset = top + (if withTabs then 54 else 0)
        content.Position = UDim2.new(0, 20, 0, offset)
        content.Size = UDim2.new(1, -40, 1, -(offset + 20))
    end
    layoutContent(false)

    if opts.tabs and #opts.tabs > 0 then
        layoutContent(true)
        local onTab = opts.onTab
        local created = Widgets.Tabs(window, opts.tabs, function(name: string)
            for _, child in ipairs(content:GetChildren()) do
                child:Destroy()
            end
            if onTab then
                onTab(name, content)
            end
        end)
        created.frame.Position = UDim2.new(0, 20, 0, top)
        tabs = created
    end

    local isOpen = false
    local tweenToken = 0

    local panel: Panel = {
        id = id,
        Content = content,
        SetTitle = function(text: string)
            titleLabel.Text = text
        end,
        Open = function()
            if isOpen then
                return
            end
            local current = openId
            if current and current ~= id and panels[current] then
                panels[current].Close()
            end
            isOpen = true
            openId = id
            tweenToken += 1
            overlay.Visible = true
            scale.Scale = 0.92
            overlay.BackgroundTransparency = 1
            TweenService:Create(overlay, TweenInfo.new(OPEN_TIME), { BackgroundTransparency = 0.45 }):Play()
            TweenService:Create(scale, TweenInfo.new(OPEN_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
            if opts.onOpen then
                opts.onOpen()
            end
            local currentTabs = tabs
            if currentTabs then
                currentTabs.Select(currentTabs.Current())
            elseif opts.onTab then
                for _, child in ipairs(content:GetChildren()) do
                    child:Destroy() -- sem isso, reabrir o painel empilharia uma segunda cópia do conteúdo
                end
                opts.onTab("", content)
            end
        end,
        Close = function()
            if not isOpen then
                return
            end
            isOpen = false
            if openId == id then
                openId = nil
            end
            tweenToken += 1
            local mine = tweenToken
            TweenService:Create(overlay, TweenInfo.new(OPEN_TIME), { BackgroundTransparency = 1 }):Play()
            TweenService:Create(scale, TweenInfo.new(OPEN_TIME), { Scale = 0.92 }):Play()
            task.delay(OPEN_TIME, function()
                if mine == tweenToken then
                    overlay.Visible = false
                end
            end)
            if opts.onClose then
                opts.onClose()
            end
        end,
        IsOpen = function()
            return isOpen
        end,
        SelectTab = function(name: string)
            local currentTabs = tabs
            if currentTabs then
                currentTabs.Select(name)
            end
        end,
        Refresh = function()
            if not isOpen then
                return
            end
            local currentTabs = tabs
            if currentTabs then
                currentTabs.Select(currentTabs.Current())
            elseif opts.onTab then
                for _, child in ipairs(content:GetChildren()) do
                    child:Destroy()
                end
                opts.onTab("", content)
            end
        end,
    }
    panelRef.value = panel
    panels[id] = panel

    -- Clicar no fundo escuro, fora da janela, fecha
    overlay.Activated:Connect(function()
        panel.Close()
    end)
    return panel
end

function PanelManager.Toggle(id: string)
    local panel = panels[id]
    if not panel then
        return
    end
    if panel.IsOpen() then
        panel.Close()
    else
        panel.Open()
    end
end

function PanelManager.Get(id: string): Panel?
    return panels[id]
end

return PanelManager
