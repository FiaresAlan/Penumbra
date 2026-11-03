--!strict
-- HUD do lobby (só na superfície): botão DESCER no topo com a frase do próximo passo, moedas, botões laterais com selo
-- e a barra do próximo objetivo. Só mostra estado e faz pedidos: quem decide é o servidor.
-- Os painéis dos botões laterais são registrados pelos outros módulos com LobbyHUD.Register(id, abrir).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local LevelRules = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("LevelRules") :: ModuleScript)
local Theme = require((script.Parent :: Instance):WaitForChild("Theme") :: ModuleScript)
local Widgets = require((script.Parent :: Instance):WaitForChild("Widgets") :: ModuleScript)
local ProfileHUD = require((script.Parent :: Instance):WaitForChild("ProfileHUD") :: ModuleScript)
local GuideState = require((script.Parent :: Instance):WaitForChild("GuideState") :: ModuleScript)
local GuideSteps = require((script.Parent :: Instance):WaitForChild("GuideSteps") :: ModuleScript)

local player = Players.LocalPlayer
local RequestDescent = ReplicatedStorage:WaitForChild("EcosRemotes"):WaitForChild("RequestDescent") :: RemoteEvent

local C = Theme.Color

local LobbyHUD = {}

type Profile = {
    money: number,
    stash: { any },
    upgrades: { [string]: boolean },
    contracts: { [string]: any }?,
    xp: number?,
    daily: { index: number, amount: number, available: boolean }?,
}

local root: Frame? = nil
local descendButton: TextButton? = nil
local hintLabel: TextLabel? = nil
local moneyLabel: TextLabel? = nil
local objective: Widgets.ProgressBar? = nil
local xpBar: Widgets.ProgressBar? = nil
local toastLabel: TextLabel? = nil
local badges: { [string]: Widgets.Badge } = {}
local openers: { [string]: () -> () } = {}
local visible = false
local loopToken = 0
local toastToken = 0

local SIDE_BUTTONS = {
    { id = "bag", emoji = "🎒", label = "Mochila" },
    { id = "contracts", emoji = "📜", label = "Contratos" },
    { id = "workshop", emoji = "🔨", label = "Oficina" },
    { id = "market", emoji = "💰", label = "Mercado" },
    { id = "profile", emoji = "👤", label = "Perfil" },
    { id = "board", emoji = "🏆", label = "Placar" },
    { id = "settings", emoji = "⚙️", label = "Ajustes" },
    { id = "daily", emoji = "🎁", label = "Diária" },
}

-- Registra o que o botão lateral abre. Sem registro, o botão só mostra "em breve".
function LobbyHUD.Register(id: string, open: () -> ())
    openers[id] = open
end

function LobbyHUD.Toast(text: string)
    local label = toastLabel
    if not label then
        return
    end
    toastToken += 1
    local mine = toastToken
    label.Text = text
    label.Visible = true
    task.delay(2.5, function()
        if mine == toastToken then
            label.Visible = false
        end
    end)
end

function LobbyHUD.SetBadge(id: string, value: string?)
    local badge = badges[id]
    if badge then
        badge.Set(value)
    end
end

local function distanceToElevator(): number?
    local elevator = workspace:FindFirstChild("LobbyElevator")
    local character = player.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if elevator and elevator:IsA("BasePart") and rootPart and rootPart:IsA("BasePart") then
        return (rootPart.Position - elevator.Position).Magnitude
    end
    return nil
end

-- Texto e estado do botão DESCER conforme a expedição e a distância até o elevador
local function refreshDescend()
    local button, hint = descendButton, hintLabel
    if not button or not hint then
        return
    end
    local phase = workspace:GetAttribute("ExpPhase")
    local descending = workspace:GetAttribute("ExpDescending") == true
    local ends = workspace:GetAttribute("ExpDescentEnds")
    local inside = workspace:GetAttribute("ExpInside")
    local distance = distanceToElevator()
    local near = distance ~= nil and distance <= Config.LobbyElevatorRadius

    local enabled = false
    if descending then
        local remaining = if typeof(ends) == "number" then math.max(0, math.ceil(ends - workspace:GetServerTimeNow())) else 0
        button.Text = string.format("DESCENDO EM %d s", remaining)
        hint.Text = if near then "Fique perto do elevador" else "Corra até o elevador ou volte de carroça!"
    elseif phase == "Active" or phase == "Resetting" then
        button.Text = "EM EXPEDIÇÃO"
        hint.Text = string.format("%d na caverna: espere o grupo voltar", if typeof(inside) == "number" then inside else 0)
    else
        enabled = true
        button.Text = "DESCER"
        -- Com o guia ligado, a frase mostra o próximo passo útil (vender, receber, comprar); senão, o de sempre
        local step = if GuideState.IsEnabled() then GuideSteps.Compute(ProfileHUD.GetProfile() :: any) else nil
        if step and step.id ~= "elevator" then
            hint.Text = step.hint
        else
            hint.Text = if near then "Pressione DESCER para começar a expedição" else "Você está longe: te levamos de carroça até o elevador"
        end
        local condition = workspace:GetAttribute("NextConditionText")
        if typeof(condition) == "string" and condition ~= "" then
            hint.Text = hint.Text .. "  ·  " .. condition
        end
    end
    button.Active = enabled
    button.BackgroundTransparency = if enabled then 0 else 0.45
    button.TextTransparency = if enabled then 0 else 0.3
end

-- Barra do próximo objetivo: a melhoria mais barata que ainda não foi comprada
local function refreshObjective(profile: Profile?)
    local bar = objective
    if not bar then
        return
    end
    if not profile then
        bar.Set(0, "")
        return
    end
    local chosenName: string? = nil
    local chosenPrice = math.huge
    for id, definition in pairs(Config.Upgrades) do
        if profile.upgrades[id] ~= true and definition.price < chosenPrice then
            chosenPrice = definition.price
            chosenName = definition.name
        end
    end
    if not chosenName then
        bar.Set(1, "Todas as melhorias compradas")
    elseif profile.money >= chosenPrice then
        bar.Set(1, string.format("Pode comprar: %s (%d)", chosenName, chosenPrice))
    else
        bar.Set(profile.money / chosenPrice, string.format("Faltam %d para %s", chosenPrice - profile.money, chosenName))
    end
end

local function claimableContracts(profile: Profile): number
    local contracts = profile.contracts
    if not contracts then
        return 0
    end
    local count = 0
    for _, scope in ipairs({ "daily", "weekly" }) do
        local ids = contracts[scope]
        local progress = contracts[scope .. "Progress"]
        local claimed = contracts[scope .. "Claimed"]
        if typeof(ids) == "table" and typeof(progress) == "table" and typeof(claimed) == "table" then
            for _, id in ipairs(ids) do
                local definition = Config.ContractDefs[id]
                if definition and not claimed[id] and (progress[id] or 0) >= definition.goal then
                    count += 1
                end
            end
        end
    end
    return count
end

local function refreshProfile()
    local profile = ProfileHUD.GetProfile() :: Profile?
    local label = moneyLabel
    if label then
        if profile then
            label.Text = string.format("💎 %d  ·  Baú %d", profile.money, #profile.stash)
        else
            label.Text = "💎 ..."
        end
    end
    refreshObjective(profile)
    local xp = xpBar
    if xp and profile then
        local level, into, needed = LevelRules.FromXp(profile.xp or 0)
        xp.Set(into / math.max(needed, 1), string.format("Nível %d · %s · %d / %d XP", level, LevelRules.Title(level), into, needed))
    end
    if profile then
        local daily = profile.daily
        LobbyHUD.SetBadge("daily", if daily and daily.available then "!" else nil)
        local count = claimableContracts(profile)
        LobbyHUD.SetBadge("contracts", if count > 0 then tostring(count) else nil)
    end
end

local function startLoop()
    loopToken += 1
    local mine = loopToken
    task.spawn(function()
        while visible and mine == loopToken do
            refreshDescend()
            task.wait(0.25)
        end
    end)
end

function LobbyHUD.SetVisible(value: boolean)
    visible = value
    local frame = root
    if frame then
        frame.Visible = value
    end
    ProfileHUD.SetLabelVisible(not value)
    if value then
        refreshProfile()
        startLoop()
    else
        loopToken += 1
    end
end

function LobbyHUD.Init()
    local gui = Instance.new("ScreenGui")
    gui.Name = "EcosLobbyHUD"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 5
    gui.Parent = player:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.fromScale(1, 1)
    frame.Visible = false
    frame.Parent = gui
    root = frame

    -- Moedas (canto superior esquerdo, abaixo da barra do Roblox)
    local pill = Instance.new("Frame")
    pill.Size = UDim2.new(0, 190, 0, 34)
    pill.Position = UDim2.new(0, 12, 0.27, 0)
    pill.BackgroundColor3 = C.PanelDark
    pill.BackgroundTransparency = 0.15
    pill.Parent = frame
    Widgets.AddCorner(pill, UDim.new(0, 17))
    Widgets.AddStroke(pill, C.Amber, 2)
    moneyLabel = Widgets.Label(pill, {
        text = "💎 ...",
        size = UDim2.new(1, -16, 1, 0),
        position = UDim2.new(0, 12, 0, 0),
        font = Theme.Font.Strong,
        color = C.Gold,
    })

    -- Botões laterais em duas colunas (a bússola fica entre as moedas e os botões)
    local sides = Instance.new("Frame")
    sides.BackgroundTransparency = 1
    sides.Position = UDim2.new(0, 12, 0.27, 122)
    sides.Size = UDim2.new(0, 164, 0, 340)
    sides.Parent = frame
    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.new(0, 76, 0, 76)
    grid.CellPadding = UDim2.new(0, 10, 0, 10)
    grid.SortOrder = Enum.SortOrder.LayoutOrder
    grid.Parent = sides
    for index, entry in ipairs(SIDE_BUTTONS) do
        local id = entry.id
        local side = Widgets.SideButton(sides, { emoji = entry.emoji, label = entry.label, accent = Theme.Accent[entry.id], onClick = function()
            local open = openers[id]
            if open then
                open()
            else
                LobbyHUD.Toast(entry.label .. ": em breve")
            end
        end })
        side.button.LayoutOrder = index
        badges[id] = side.badge
    end

    -- Topo central: DESCER, frase e objetivo
    local top = Instance.new("Frame")
    top.BackgroundTransparency = 1
    top.AnchorPoint = Vector2.new(0.5, 0)
    top.Position = UDim2.new(0.5, 0, 0, 6)
    top.Size = UDim2.new(0, 320, 0, 150)
    top.Parent = frame
    descendButton = Widgets.Button(top, {
        text = "DESCER",
        variant = "primary",
        size = UDim2.new(1, 0, 0, 58),
        onClick = function()
            local button = descendButton
            if button and button.Active then
                RequestDescent:FireServer()
            end
        end,
    })
    hintLabel = Widgets.Label(top, {
        position = UDim2.new(0, 0, 0, 64),
        size = UDim2.new(1, 0, 0, 24),
        font = Theme.Font.Strong,
        textSize = Theme.TextSize.Small,
        alignX = Enum.TextXAlignment.Center,
        color = C.Parchment,
    })
    local hintBack = hintLabel
    if hintBack then
        hintBack.BackgroundTransparency = 0.45
        hintBack.BackgroundColor3 = C.PanelDark
        Widgets.AddCorner(hintBack, UDim.new(0, 8))
    end
    objective = Widgets.ProgressBar(top, UDim2.new(1, 0, 0, 24))
    local bar = objective
    if bar then
        bar.frame.Position = UDim2.new(0, 0, 0, 96)
    end

    xpBar = Widgets.ProgressBar(frame, UDim2.new(0, 360, 0, 22))
    local xpFrame = xpBar
    if xpFrame then
        xpFrame.frame.AnchorPoint = Vector2.new(0.5, 1)
        xpFrame.frame.Position = UDim2.new(0.5, 0, 1, -22)
    end

    toastLabel = Widgets.Label(frame, {
        position = UDim2.new(0.5, -160, 0, 160),
        size = UDim2.new(0, 320, 0, 30),
        font = Theme.Font.Strong,
        alignX = Enum.TextXAlignment.Center,
        color = C.Gold,
    })
    local toast = toastLabel
    if toast then
        toast.BackgroundTransparency = 0.3
        toast.BackgroundColor3 = C.PanelDark
        toast.Visible = false
        Widgets.AddCorner(toast, UDim.new(0, 8))
    end

    ProfileHUD.OnChanged(function()
        if visible then
            refreshProfile()
        end
    end)
    workspace:GetAttributeChangedSignal("ExpPhase"):Connect(refreshDescend)
    workspace:GetAttributeChangedSignal("ExpDescending"):Connect(refreshDescend)
end

return LobbyHUD
