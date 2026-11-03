--!strict
-- Marcadores flutuantes sobre os lugares da superfície: emoji, nome e distância. Somem de perto, ficam menores de longe.
-- Só cliente. O Mercado Negro nunca aparece aqui: achá-lo faz parte do jogo.
local Players = game:GetService("Players")

local GuideState = require((script.Parent :: Instance):WaitForChild("GuideState") :: ModuleScript)
local Theme = require((script.Parent :: Instance):WaitForChild("Theme") :: ModuleScript)

local player = Players.LocalPlayer

local WorldMarkers = {}

local HIDE_DISTANCE = 15 -- studs
local STUDS_PER_METER = 3.5
local UPDATE_INTERVAL = 0.3

local TARGETS = {
    { part = "LobbyElevator", emoji = "⛏️", name = "Elevador" },
    { part = "LobbyMarket", emoji = "💰", name = "Mercado" },
    { part = "LobbyWorkshop", emoji = "🔨", name = "Oficina" },
    { part = "LobbyBoard", emoji = "📜", name = "Contratos" },
    { part = "HighlightsWall", emoji = "🏆", name = "Mural" },
    { part = "CartMina", emoji = "🛒", name = "Carroça" },
    { part = "CartVila", emoji = "🛒", name = "Carroça" },
}

type Marker = { gui: BillboardGui, distance: TextLabel, part: BasePart }

local markers: { Marker } = {}
local active = false
local token = 0

local function clearMarkers()
    for _, marker in ipairs(markers) do
        marker.gui:Destroy()
    end
    table.clear(markers)
end

local function build()
    clearMarkers()
    for _, target in ipairs(TARGETS) do
        local part = workspace:FindFirstChild(target.part)
        if part and part:IsA("BasePart") then
            local gui = Instance.new("BillboardGui")
            gui.Name = "MarcadorGuia"
            gui.Adornee = part
            gui.AlwaysOnTop = true
            gui.Size = UDim2.new(0, 130, 0, 50)
            gui.StudsOffsetWorldSpace = Vector3.new(0, 9, 0)
            gui.MaxDistance = 1800
            gui.LightInfluence = 0
            gui.ResetOnSpawn = false
            gui.Parent = player:WaitForChild("PlayerGui")

            local title = Instance.new("TextLabel")
            title.BackgroundTransparency = 1
            title.Size = UDim2.new(1, 0, 0.6, 0)
            title.Text = target.emoji .. " " .. target.name
            title.Font = Theme.Font.Strong
            title.TextSize = 18
            title.TextColor3 = Theme.Color.Gold
            title.TextStrokeTransparency = 0.3
            title.Parent = gui
            local distance = Instance.new("TextLabel")
            distance.BackgroundTransparency = 1
            distance.Position = UDim2.new(0, 0, 0.6, 0)
            distance.Size = UDim2.new(1, 0, 0.4, 0)
            distance.Font = Theme.Font.Body
            distance.TextSize = 14
            distance.TextColor3 = Theme.Color.Text
            distance.TextStrokeTransparency = 0.4
            distance.Parent = gui
            table.insert(markers, { gui = gui, distance = distance, part = part })
        end
    end
end

local function update()
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") then
        return
    end
    for _, marker in ipairs(markers) do
        local studs = (marker.part.Position - root.Position).Magnitude
        marker.gui.Enabled = studs > HIDE_DISTANCE
        marker.distance.Text = string.format("%d m", math.floor(studs / STUDS_PER_METER + 0.5))
        -- Menor quanto mais longe, mas nunca ilegível
        local scale = math.clamp(1 - studs / 2400, 0.55, 1)
        marker.gui.Size = UDim2.new(0, 130 * scale, 0, 50 * scale)
    end
end

local function run()
    token += 1
    local mine = token
    build()
    task.spawn(function()
        local sinceBuild = 0
        while active and GuideState.IsEnabled() and mine == token do
            -- Ao entrar, as peças do mapa ainda podem estar chegando: refaz até achar todas
            sinceBuild += UPDATE_INTERVAL
            if #markers < #TARGETS and sinceBuild >= 2 then
                sinceBuild = 0
                build()
            end
            update()
            task.wait(UPDATE_INTERVAL)
        end
    end)
end

function WorldMarkers.SetSurface(onSurface: boolean)
    active = onSurface
    if onSurface and GuideState.IsEnabled() then
        run()
    else
        token += 1
        clearMarkers()
    end
end

function WorldMarkers.Init()
    GuideState.OnChanged(function(enabled: boolean)
        if active and enabled then
            run()
        else
            token += 1
            clearMarkers()
        end
    end)
end

return WorldMarkers
