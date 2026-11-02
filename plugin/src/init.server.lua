--!nocheck
-- Ecos Tools: painel do Studio para o projeto Ecos da Penumbra.
-- Gera e limpa o mapa no modo de edição (sem dar Play), conta as peças e leva a câmera aos pontos principais.
-- Para instalar: rojo build plugin.project.json --plugin EcosTools.rbxm (grava na pasta de plugins do Studio).
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local toolbar = plugin:CreateToolbar("Ecos da Penumbra")
local toggle = toolbar:CreateButton("Ecos Tools", "Abre o painel de ferramentas do projeto", "")

local widget = plugin:CreateDockWidgetPluginGui(
    "EcosToolsWidget",
    DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Right, false, false, 280, 420, 240, 260)
)
widget.Title = "Ecos da Penumbra"
toggle.Click:Connect(function()
    widget.Enabled = not widget.Enabled
end)

local theme = settings().Studio.Theme
local function color(name, modifier)
    return theme:GetColor(name, modifier or Enum.StudioStyleGuideModifier.Default)
end

local root = Instance.new("ScrollingFrame")
root.Size = UDim2.fromScale(1, 1)
root.BackgroundColor3 = color(Enum.StudioStyleGuideColor.MainBackground)
root.BorderSizePixel = 0
root.CanvasSize = UDim2.new(0, 0, 0, 0)
root.AutomaticCanvasSize = Enum.AutomaticSize.Y
root.ScrollBarThickness = 6
root.Parent = widget

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.Parent = root
local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 8)
padding.PaddingLeft = UDim.new(0, 8)
padding.PaddingRight = UDim.new(0, 8)
padding.PaddingBottom = UDim.new(0, 8)
padding.Parent = root

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, 0, 0, 54)
status.BackgroundTransparency = 1
status.TextWrapped = true
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextYAlignment = Enum.TextYAlignment.Top
status.Font = Enum.Font.Gotham
status.TextSize = 13
status.TextColor3 = color(Enum.StudioStyleGuideColor.SubText)
status.Text = "Pronto. O mapa é gerado pelo MapBuilder (a mesma rotina do jogo)."
status.LayoutOrder = 100
status.Parent = root

local order = 0
local function say(text)
    status.Text = text
    print("[Ecos Tools] " .. text)
end

local function addButton(text, callback)
    order += 1
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 0, 32)
    button.LayoutOrder = order
    button.BackgroundColor3 = color(Enum.StudioStyleGuideColor.Button)
    button.TextColor3 = color(Enum.StudioStyleGuideColor.ButtonText)
    button.BorderColor3 = color(Enum.StudioStyleGuideColor.ButtonBorder)
    button.Font = Enum.Font.GothamMedium
    button.TextSize = 14
    button.Text = text
    button.Parent = root
    button.Activated:Connect(function()
        local ok, err = pcall(callback)
        if not ok then
            say("Erro: " .. tostring(err))
        end
    end)
end

local function findMapBuilder()
    local server = ServerScriptService:FindFirstChild("EcosServer")
    local world = server and server:FindFirstChild("world")
    return world and world:FindFirstChild("MapBuilder")
end

local function clearGenerated()
    local removed = 0
    for _, child in ipairs(workspace:GetChildren()) do
        if child:GetAttribute("Generated") then
            child:Destroy()
            removed += 1
        end
    end
    local template = ServerStorage:FindFirstChild("CoreTemplate")
    if template then
        template:Destroy()
    end
    return removed
end

addButton("Gerar mapa (modo edição)", function()
    local module = findMapBuilder()
    if not module then
        say("MapBuilder não encontrado. Conecte o Rojo e sincronize o projeto.")
        return
    end
    if game:GetService("RunService"):IsRunning() then
        say("Pare o jogo antes de gerar o mapa.")
        return
    end
    ChangeHistoryService:SetWaypoint("Antes de gerar o mapa")
    -- Uma cópia nova do módulo: assim mudanças recentes no código valem sem reiniciar o Studio
    local fresh = module:Clone()
    fresh.Parent = module.Parent
    local ok, result = pcall(require, fresh)
    fresh:Destroy()
    if not ok then
        say("Falha ao carregar o MapBuilder: " .. tostring(result))
        return
    end
    say("Gerando o mapa... (props e Guardião aparecem alguns segundos depois)")
    task.spawn(function()
        local built, err = pcall(function()
            result.Build()
        end)
        ChangeHistoryService:SetWaypoint("Mapa gerado")
        say(built and "Mapa gerado. Ao dar Play ele é recriado do zero." or ("Erro ao gerar: " .. tostring(err)))
    end)
end)

addButton("Limpar mapa gerado", function()
    ChangeHistoryService:SetWaypoint("Antes de limpar o mapa")
    local removed = clearGenerated()
    ChangeHistoryService:SetWaypoint("Mapa limpo")
    say(string.format("%d itens gerados removidos.", removed))
end)

addButton("Contar peças do mapa", function()
    local map = workspace:FindFirstChild("Map")
    local parts, lights, emitters = 0, 0, 0
    if map then
        for _, descendant in ipairs(map:GetDescendants()) do
            if descendant:IsA("BasePart") then
                parts += 1
            elseif descendant:IsA("Light") then
                lights += 1
            elseif descendant:IsA("ParticleEmitter") then
                emitters += 1
            end
        end
    end
    say(string.format("Mapa: %d peças, %d luzes, %d emissores de partículas.", parts, lights, emitters))
end)

local function moveCamera(position, lookAt, label)
    local camera = workspace.CurrentCamera
    if camera then
        camera.CFrame = CFrame.lookAt(position, lookAt)
        say("Câmera: " .. label)
    end
end

addButton("Câmera: lobby", function()
    moveCamera(Vector3.new(-40, 45, 70), Vector3.new(20, 5, 0), "lobby")
end)
addButton("Câmera: entrada da caverna", function()
    moveCamera(Vector3.new(470, 60, -30), Vector3.new(470, 5, 0), "entrada da caverna")
end)
addButton("Câmera: câmara do núcleo", function()
    moveCamera(Vector3.new(760, 70, 60), Vector3.new(812, 5, 0), "câmara do núcleo")
end)
addButton("Câmera: floresta e Mercado Negro", function()
    moveCamera(Vector3.new(-100, 40, 50), Vector3.new(-135, 3, 0), "floresta")
end)

addButton("Selecionar peças com Attribute Generated", function()
    local list = {}
    for _, child in ipairs(workspace:GetChildren()) do
        if child:GetAttribute("Generated") then
            table.insert(list, child)
        end
    end
    game:GetService("Selection"):Set(list)
    say(string.format("%d itens gerados selecionados.", #list))
end)

print("[Ecos Tools] plugin carregado. Use o botão Ecos Tools na aba Plugins.")
