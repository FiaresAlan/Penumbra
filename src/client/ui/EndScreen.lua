--!strict
-- Tela de fim de expedição: o resultado, o que você trouxe e até 3 cartas de destaque com foto. Some sozinha em 9 s e
-- não bloqueia nada: dá para descer de novo na hora (o Portão 2 pede menos de 1 minuto na superfície).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Theme = require((script.Parent :: Instance):WaitForChild("Theme") :: ModuleScript)
local Widgets = require((script.Parent :: Instance):WaitForChild("Widgets") :: ModuleScript)

local player = Players.LocalPlayer
local SummaryRemote = ReplicatedStorage:WaitForChild("EcosRemotes"):WaitForChild("ExpeditionSummary") :: RemoteEvent

local C = Theme.Color

local EndScreen = {}

local gui: ScreenGui? = nil
local token = 0

local SHOW_SECONDS = 9

local function clear()
    local current = gui
    if current then
        for _, child in ipairs(current:GetChildren()) do
            child:Destroy()
        end
    end
end

-- Números que sobem até o valor final
local function countUp(label: TextLabel, target: number, suffix: string)
    task.spawn(function()
        local steps = 20
        for step = 1, steps do
            label.Text = string.format("%d%s", math.floor(target * step / steps), suffix)
            task.wait(0.03)
        end
        label.Text = string.format("%d%s", target, suffix)
    end)
end

local function highlightCard(parent: Instance, info: { [string]: any })
    local card = Widgets.Card(parent, UDim2.new(0, 150, 1, 0), "Legendary")
    local photo = Instance.new("ImageLabel")
    photo.BackgroundTransparency = 1
    photo.Size = UDim2.new(0, 64, 0, 64)
    photo.Position = UDim2.new(0.5, -32, 0, 6)
    photo.Parent = card
    Widgets.AddCorner(photo, UDim.new(1, 0))
    Widgets.Label(card, {
        text = tostring(info.title),
        position = UDim2.new(0, 4, 0, 74),
        size = UDim2.new(1, -8, 0, 20),
        font = Theme.Font.Strong,
        textSize = Theme.TextSize.Small,
        color = C.Gold,
        alignX = Enum.TextXAlignment.Center,
    })
    Widgets.Label(card, {
        text = tostring(info.name),
        position = UDim2.new(0, 4, 0, 94),
        size = UDim2.new(1, -8, 0, 18),
        textSize = Theme.TextSize.Small,
        alignX = Enum.TextXAlignment.Center,
    })
    Widgets.Label(card, {
        text = if info.title == "Voltou para salvar" then string.format("%d resgate(s)", info.value) else string.format("%d 💎", info.value),
        position = UDim2.new(0, 4, 0, 112),
        size = UDim2.new(1, -8, 0, 18),
        textSize = Theme.TextSize.Small,
        color = C.TextDim,
        alignX = Enum.TextXAlignment.Center,
    })
    task.spawn(function()
        local userId = info.userId
        if typeof(userId) ~= "number" then
            return
        end
        local ok, content = pcall(function()
            return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
        end)
        if ok and photo.Parent then
            photo.Image = content
        end
    end)
end

local function show(data: unknown)
    if typeof(data) ~= "table" then
        return
    end
    local summary = data :: { [string]: any }
    local current = gui
    if not current then
        return
    end
    clear()
    token += 1
    local mine = token

    local mineEntry: { [string]: any }? = nil
    if typeof(summary.players) == "table" then
        for _, entry in ipairs(summary.players) do
            if typeof(entry) == "table" and entry.userId == player.UserId then
                mineEntry = entry
            end
        end
    end
    local success = summary.outcome == "success"
    local extracted = mineEntry ~= nil and mineEntry.extracted == true

    local frame = Instance.new("Frame")
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Position = UDim2.fromScale(0.5, 0.5)
    frame.Size = UDim2.new(0, 520, 0, 330)
    frame.BackgroundColor3 = C.PanelBg
    frame.Parent = current
    Widgets.AddCorner(frame, UDim.new(0, 14))
    Widgets.AddStroke(frame, if success then C.Amber else C.Danger, 3)
    local limit = Instance.new("UISizeConstraint")
    limit.MaxSize = Vector2.new(560, 360)
    limit.Parent = frame
    local scale = Instance.new("UIScale")
    scale.Scale = 0.9
    scale.Parent = frame
    TweenService:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()

    Widgets.Label(frame, {
        text = if success then "Expedição concluída" else "A expedição fracassou",
        position = UDim2.new(0, 20, 0, 12),
        size = UDim2.new(1, -40, 0, 40),
        font = Theme.Font.Title,
        textSize = Theme.TextSize.Title,
        color = if success then C.Gold else C.Danger,
        alignX = Enum.TextXAlignment.Center,
    })
    local line = Widgets.Label(frame, {
        text = "",
        position = UDim2.new(0, 20, 0, 58),
        size = UDim2.new(1, -40, 0, 30),
        font = Theme.Font.Strong,
        textSize = Theme.TextSize.Heading,
        alignX = Enum.TextXAlignment.Center,
    })
    if extracted and mineEntry then
        Widgets.Label(frame, {
            text = string.format("Você trouxe %d itens", mineEntry.items),
            position = UDim2.new(0, 20, 0, 90),
            size = UDim2.new(1, -40, 0, 22),
            color = C.TextDim,
            alignX = Enum.TextXAlignment.Center,
        })
        countUp(line, mineEntry.value, " 💎")
        line.TextColor3 = C.Gold
    else
        line.Text = if success then "Você não extraiu desta vez" else "Nada foi trazido. O baú está seguro."
        line.TextColor3 = C.Parchment
        line.TextSize = Theme.TextSize.Body
    end

    local highlights = summary.highlights
    if typeof(highlights) == "table" and #highlights > 0 then
        local row = Instance.new("Frame")
        row.BackgroundTransparency = 1
        row.Position = UDim2.new(0, 20, 0, 126)
        row.Size = UDim2.new(1, -40, 0, 136)
        row.Parent = frame
        local layout = Instance.new("UIListLayout")
        layout.FillDirection = Enum.FillDirection.Horizontal
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.Padding = UDim.new(0, 12)
        layout.Parent = row
        for index, info in ipairs(highlights) do
            if index > 3 then
                break
            end
            if typeof(info) == "table" then
                highlightCard(row, info)
            end
        end
    end

    Widgets.Button(frame, {
        text = "Fechar",
        size = UDim2.new(0, 150, 0, 38),
        position = UDim2.new(0.5, -75, 1, -52),
        onClick = function()
            if mine == token then
                clear()
            end
        end,
    })
    task.delay(SHOW_SECONDS, function()
        if mine == token then
            clear()
        end
    end)
end

function EndScreen.Init()
    local created = Instance.new("ScreenGui")
    created.Name = "EcosEndScreen"
    created.ResetOnSpawn = false
    created.DisplayOrder = 8
    created.Parent = player:WaitForChild("PlayerGui")
    gui = created
    SummaryRemote.OnClientEvent:Connect(show)
end

return EndScreen
