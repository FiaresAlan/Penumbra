--!strict
-- Tela de fim de expedição: o resultado, o que você trouxe e até 3 cartas de destaque com foto. Some sozinha em 9 s e
-- não bloqueia nada: dá para descer de novo na hora (o Portão 2 pede menos de 1 minuto na superfície).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Theme = require((script.Parent :: Instance):WaitForChild("Theme") :: ModuleScript)
local Widgets = require((script.Parent :: Instance):WaitForChild("Widgets") :: ModuleScript)
local ItemViewport = require((script.Parent :: Instance):WaitForChild("ItemViewport") :: ModuleScript)

local player = Players.LocalPlayer
local SummaryRemote = ReplicatedStorage:WaitForChild("EcosRemotes"):WaitForChild("ExpeditionSummary") :: RemoteEvent

local C = Theme.Color

local EndScreen = {}

local gui: ScreenGui? = nil
local token = 0

local SHOW_SECONDS = 14

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

-- V4: tablados de madeira com os 3 melhores do saque (foto, nome, valor) e coroa de MVP no primeiro.
-- Quem não extraiu não entra. Sozinho, aparece só o seu tablado.
local PODIUM_COLORS = { Color3.fromRGB(255, 214, 40), Color3.fromRGB(120, 220, 255), Color3.fromRGB(255, 130, 70) }

local function podium(parent: Instance, entries: { { [string]: any } })
    local ranked: { { [string]: any } } = {}
    for _, entry in ipairs(entries) do
        if entry.extracted == true and typeof(entry.value) == "number" then
            table.insert(ranked, entry)
        end
    end
    table.sort(ranked, function(a, b)
        return a.value > b.value
    end)
    if #ranked == 0 then
        return
    end
    local row = Instance.new("Frame")
    row.Name = "Podio"
    row.BackgroundTransparency = 1
    row.Position = UDim2.new(0, 20, 0, 118)
    row.Size = UDim2.new(1, -40, 0, 136)
    row.Parent = parent
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    layout.Padding = UDim.new(0, 10)
    layout.Parent = row
    -- ordem visual: 2º, 1º, 3º
    local order = { 2, 1, 3 }
    local heights = { 56, 80, 40 }
    for _, rank in ipairs(order) do
        local entry = ranked[rank]
        if entry then
            local column = Instance.new("Frame")
            column.BackgroundTransparency = 1
            column.Size = UDim2.new(0, 140, 1, 0)
            column.LayoutOrder = if rank == 2 then 1 elseif rank == 1 then 2 else 3
            column.Parent = row
            local stand = Instance.new("Frame")
            stand.AnchorPoint = Vector2.new(0, 1)
            stand.Position = UDim2.fromScale(0, 1)
            stand.Size = UDim2.new(1, 0, 0, heights[rank])
            stand.BackgroundColor3 = Color3.fromRGB(70, 48, 140)
            stand.Parent = column
            Widgets.AddCorner(stand, UDim.new(0, 6))
            Widgets.AddStroke(stand, PODIUM_COLORS[rank], 2)
            Widgets.Label(stand, {
                text = string.format("%dº  %d 💎", rank, entry.value),
                position = UDim2.new(0, 4, 0, 4),
                size = UDim2.new(1, -8, 0, 18),
                font = Theme.Font.Strong,
                textSize = Theme.TextSize.Small,
                color = PODIUM_COLORS[rank],
                alignX = Enum.TextXAlignment.Center,
            })
            Widgets.Label(stand, {
                text = tostring(entry.name),
                position = UDim2.new(0, 4, 0, 24),
                size = UDim2.new(1, -8, 0, 16),
                textSize = Theme.TextSize.Small,
                alignX = Enum.TextXAlignment.Center,
            })
            local photo = Instance.new("ImageLabel")
            photo.BackgroundTransparency = 1
            photo.Size = UDim2.new(0, 44, 0, 44)
            photo.AnchorPoint = Vector2.new(0.5, 1)
            photo.Position = UDim2.new(0.5, 0, 1, -(heights[rank] - 2))
            photo.Parent = column
            Widgets.AddCorner(photo, UDim.new(1, 0))
            if rank == 1 then
                Widgets.Label(column, {
                    text = "👑 MVP",
                    position = UDim2.new(0, 0, 1, -(heights[rank] + 66)),
                    size = UDim2.new(1, 0, 0, 18),
                    font = Theme.Font.Strong,
                    textSize = Theme.TextSize.Small,
                    color = C.Gold,
                    alignX = Enum.TextXAlignment.Center,
                })
            end
            task.spawn(function()
                local userId = entry.userId
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
    end
end

-- V4: baú que abre com raios dourados girando; o número do saque sobe ao lado.
local function chest(parent: Instance)
    local holder = Instance.new("Frame")
    holder.Name = "Bau"
    holder.BackgroundTransparency = 1
    holder.AnchorPoint = Vector2.new(0.5, 0.5)
    holder.Position = UDim2.new(0, 64, 0, 84)
    holder.Size = UDim2.new(0, 120, 0, 60)
    holder.ClipsDescendants = false
    holder.Parent = parent
    local rays = Instance.new("Frame")
    rays.BackgroundTransparency = 1
    rays.AnchorPoint = Vector2.new(0.5, 0.5)
    rays.Position = UDim2.fromScale(0.5, 0.5)
    rays.Size = UDim2.fromOffset(0, 0)
    rays.Parent = holder
    for index = 1, 6 do
        local ray = Instance.new("Frame")
        ray.AnchorPoint = Vector2.new(0.5, 0.5)
        ray.Position = UDim2.fromScale(0.5, 0.5)
        ray.Size = UDim2.new(0, 84, 0, 3)
        ray.Rotation = index * 30
        ray.BackgroundColor3 = C.Gold
        ray.BackgroundTransparency = 0.5
        ray.BorderSizePixel = 0
        ray.Parent = rays
    end
    -- V4: baú 3D com a tampa abrindo; sem ViewportFrame, volta para o emoji
    local chestFrame: ViewportFrame? = nil
    local openChest: (() -> ())? = nil
    local okChest = pcall(function()
        local frame, open = ItemViewport.CreateChest(holder, UDim2.fromScale(1.2, 1.6), UDim2.fromScale(-0.1, -0.3))
        chestFrame = frame
        openChest = open
    end)
    local icon = Widgets.Label(holder, {
        text = if okChest and chestFrame then "" else "📦",
        position = UDim2.fromScale(0, 0),
        size = UDim2.fromScale(1, 1),
        textSize = 44,
        alignX = Enum.TextXAlignment.Center,
    })
    task.delay(0.5, function()
        if icon.Parent then
            if openChest then
                openChest()
            else
                icon.Text = "🎁"
            end
            local spin = TweenService:Create(rays, TweenInfo.new(6, Enum.EasingStyle.Linear), { Rotation = 180 })
            spin:Play()
            for _, ray in ipairs(rays:GetChildren()) do
                if ray:IsA("Frame") then
                    TweenService:Create(ray, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, -1, true), { BackgroundTransparency = 0.9 }):Play()
                end
            end
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
    local hasPodium = false
    if typeof(summary.players) == "table" then
        for _, entry in ipairs(summary.players) do
            if typeof(entry) == "table" and entry.extracted == true then
                hasPodium = true
            end
        end
    end
    local hasHighlights = typeof(summary.highlights) == "table" and #summary.highlights > 0
    local height = 200 + (if hasPodium then 150 else 0) + (if hasHighlights then 140 else 0)
    frame.Size = UDim2.new(0, 520, 0, math.max(height, 250))
    frame.BackgroundColor3 = C.PanelBg
    frame.Parent = current
    Widgets.AddCorner(frame, UDim.new(0, 14))
    Widgets.AddStroke(frame, if success then C.Amber else C.Danger, 3)
    local limit = Instance.new("UISizeConstraint")
    limit.MaxSize = Vector2.new(560, 520)
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
        chest(frame)
    else
        line.Text = if success then "Você não extraiu desta vez" else "Nada foi trazido. O baú está seguro."
        line.TextColor3 = C.Parchment
        line.TextSize = Theme.TextSize.Body
    end

    if hasPodium then
        podium(frame, summary.players)
    end

    local highlights = summary.highlights
    if typeof(highlights) == "table" and #highlights > 0 then
        local row = Instance.new("Frame")
        row.BackgroundTransparency = 1
        row.Position = UDim2.new(0, 20, 0, if hasPodium then 272 else 126)
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
        text = "Pular",
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

-- Botão "Tela de fim" do painel QA: mostra a tela com dados inventados (só cliente, não toca no jogo)
function EndScreen.Preview()
    show({
        outcome = "success",
        players = {
            { name = player.DisplayName, userId = player.UserId, value = 640, items = 5, rescues = 0, extracted = true },
            { name = "Amiga", userId = 1, value = 910, items = 6, rescues = 1, extracted = true },
            { name = "Parceiro", userId = 156, value = 220, items = 2, rescues = 0, extracted = true },
        },
        highlights = {
            { title = "Maior saque", name = "Amiga", userId = 1, value = 910 },
        },
    })
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
