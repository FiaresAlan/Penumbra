--!strict
-- V2: a praça da mina ganha placares gigantes (semana e hoje), o altar das relíquias, a estátua do Guardião e um varal de
-- lanternas. As posições vêm de FreeSpot (procura chão livre em volta de uma âncora e só coloca se achar), então nada nasce
-- dentro de árvore, casa ou prompt. Tudo é cosmético: nenhuma peça dá moeda, item ou poder.
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local systems = script.Parent :: Instance
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local FreeSpot = require(systems.Parent:WaitForChild("world"):WaitForChild("FreeSpot") :: ModuleScript)
local HighlightsSystem = require(systems:WaitForChild("HighlightsSystem") :: ModuleScript)
local ExtractionSystem = require(systems:WaitForChild("ExtractionSystem") :: ModuleScript)

local PlazaDecor = {}

local rng = Random.new(Config.MapSeed + 77)
local WOOD = Color3.fromRGB(92, 64, 42)
local STONE = Color3.fromRGB(110, 104, 96)
local DARK_STONE = Color3.fromRGB(58, 54, 56)
local GOLD = Color3.fromRGB(226, 178, 62)

local folder: Folder? = nil
local relicsToday = 0
local relicLabels: { TextLabel } = {}
local altarCrystals: { Part } = {}

local function part(name: string, size: Vector3, cframe: CFrame, material: Enum.Material, color: Color3, parent: Instance): Part
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cframe
    p.Material = material
    p.Color = color
    p.Anchored = true
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

local function textFace(board: Part, face: Enum.NormalId): TextLabel
    local gui = Instance.new("SurfaceGui")
    gui.Face = face
    gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    gui.PixelsPerStud = 40
    gui.Parent = board
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(246, 236, 210)
    label.Font = Enum.Font.Fondamento
    label.TextWrapped = true
    label.TextScaled = true
    label.Text = ""
    label.Parent = gui
    return label
end

-- Placar gigante: duas estacas e uma tábua larga virada para o centro da mina
local function buildBoard(name: string, spot: Vector3, parent: Instance): TextLabel
    local facing = CFrame.lookAt(spot, Vector3.new(0, spot.Y, 0)) -- a frente (-Z) olha para o elevador
    part(name .. "EstacaE", Vector3.new(1.6, 16, 1.6), facing * CFrame.new(-8, 8, 0), Enum.Material.WoodPlanks, WOOD, parent)
    part(name .. "EstacaD", Vector3.new(1.6, 16, 1.6), facing * CFrame.new(8, 8, 0), Enum.Material.WoodPlanks, WOOD, parent)
    local board = part(name, Vector3.new(19, 11, 0.8), facing * CFrame.new(0, 10.5, 0), Enum.Material.WoodPlanks, Color3.fromRGB(70, 48, 34), parent)
    part(name .. "Moldura", Vector3.new(20.4, 12.4, 0.5), facing * CFrame.new(0, 10.5, 0.2), Enum.Material.Wood, Color3.fromRGB(40, 28, 20), parent)
    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(255, 214, 150)
    light.Range = 40
    light.Brightness = 1.2
    light.Parent = board
    return textFace(board, Enum.NormalId.Front)
end

local function topText(): string
    local lines = { "PLACAR DA SEMANA" }
    local top = HighlightsSystem.GetTop()
    for index = 1, 5 do
        local entry = top[index]
        if entry then
            table.insert(lines, string.format("%d. %s  %d moedas", index, HighlightsSystem.NameOf(entry.userId), entry.value))
        end
    end
    if #top == 0 then
        table.insert(lines, "Ninguém no placar ainda. Seja o primeiro a voltar com uma relíquia.")
    end
    return table.concat(lines, "\n")
end

local function todayText(): string
    local phase = workspace:GetAttribute("ExpPhase")
    local inside = workspace:GetAttribute("ExpInside")
    local lines = { "HOJE NA MINA" }
    if phase == "Active" or phase == "Resetting" then
        table.insert(lines, string.format("Expedição em andamento: %d na caverna", if typeof(inside) == "number" then inside else 0))
    else
        table.insert(lines, "A mina está livre. O elevador espera.")
    end
    local condition = workspace:GetAttribute("NextConditionText")
    if typeof(condition) == "string" and condition ~= "" then
        table.insert(lines, condition)
    end
    table.insert(lines, string.format("Relíquias trazidas hoje: %d", relicsToday))
    return table.concat(lines, "\n")
end

-- Altar: base de pedra, quatro colunas e cinco cristais que acendem a cada relíquia trazida neste servidor
local function buildAltar(spot: Vector3, parent: Instance)
    local base = CFrame.new(spot)
    part("AltarBase", Vector3.new(11, 1.2, 11), base * CFrame.new(0, 0.6, 0), Enum.Material.Cobblestone, STONE, parent)
    part("AltarDegrau", Vector3.new(8, 1.2, 8), base * CFrame.new(0, 1.8, 0), Enum.Material.Cobblestone, STONE, parent)
    part("AltarMesa", Vector3.new(6, 1.4, 6), base * CFrame.new(0, 3.1, 0), Enum.Material.Marble, Color3.fromRGB(170, 166, 160), parent)
    for _, corner in ipairs({ { 4.4, 4.4 }, { -4.4, 4.4 }, { 4.4, -4.4 }, { -4.4, -4.4 } }) do
        part("AltarColuna", Vector3.new(1.4, 7, 1.4), base * CFrame.new(corner[1], 4.2, corner[2]), Enum.Material.Cobblestone, DARK_STONE, parent)
    end
    for index = 1, 5 do
        local angle = (index - 1) / 5 * math.pi * 2
        local crystal = part("AltarCristal", Vector3.new(0.9, 1.8, 0.9), base * CFrame.new(math.cos(angle) * 2, 5.2, math.sin(angle) * 2) * CFrame.Angles(0.2, angle, 0.2),
            Enum.Material.Neon, Color3.fromRGB(70, 60, 90), parent)
        crystal.CanCollide = false
        table.insert(altarCrystals, crystal)
    end
    local sign = part("AltarPlaca", Vector3.new(5, 1.6, 0.3), base * CFrame.new(0, 2.4, -4.3) * CFrame.Angles(0.3, 0, 0), Enum.Material.Metal, GOLD, parent)
    local label = textFace(sign, Enum.NormalId.Front)
    label.TextColor3 = Color3.fromRGB(46, 30, 10)
    table.insert(relicLabels, label)
end

local function refreshAltar()
    for index, crystal in ipairs(altarCrystals) do
        local lit = index <= relicsToday
        crystal.Color = if lit then Color3.fromRGB(255, 120, 210) else Color3.fromRGB(70, 60, 90)
        local light = crystal:FindFirstChildOfClass("PointLight")
        if lit and not light then
            local created = Instance.new("PointLight")
            created.Color = Color3.fromRGB(255, 140, 220)
            created.Range = 12
            created.Parent = crystal
        end
    end
    for _, label in ipairs(relicLabels) do
        label.Text = string.format("Altar das Relíquias\n%d trazidas hoje", relicsToday)
    end
end

-- Estátua do Guardião: pedra escura, olhos que brilham em vermelho fraco e uma placa
local function buildStatue(spot: Vector3, parent: Instance)
    local base = CFrame.lookAt(spot, Vector3.new(0, spot.Y, 0))
    part("EstatuaBase", Vector3.new(11, 1.6, 11), base * CFrame.new(0, 0.8, 0), Enum.Material.Slate, DARK_STONE, parent)
    part("EstatuaPernas", Vector3.new(5, 7, 3.4), base * CFrame.new(0, 5.1, 0), Enum.Material.Slate, DARK_STONE, parent)
    part("EstatuaTronco", Vector3.new(7.6, 8, 4.4), base * CFrame.new(0, 12.6, 0), Enum.Material.Slate, DARK_STONE, parent)
    for _, side in ipairs({ -1, 1 }) do
        part("EstatuaBraco", Vector3.new(2.2, 9, 2.4), base * CFrame.new(side * 5, 11.4, 0.6) * CFrame.Angles(-0.25, 0, side * 0.12), Enum.Material.Slate, DARK_STONE, parent)
    end
    local head = part("EstatuaCabeca", Vector3.new(4.6, 4.6, 4.6), base * CFrame.new(0, 18.4, 0), Enum.Material.Slate, DARK_STONE, parent)
    head.Shape = Enum.PartType.Ball
    for _, side in ipairs({ -0.9, 0.9 }) do
        local eye = part("EstatuaOlho", Vector3.new(0.6, 0.4, 0.3), base * CFrame.new(side, 18.9, -2.1), Enum.Material.Neon, Color3.fromRGB(190, 40, 30), parent)
        eye.CanCollide = false
    end
    local glow = Instance.new("PointLight")
    glow.Color = Color3.fromRGB(190, 50, 40)
    glow.Range = 16
    glow.Brightness = 0.8
    glow.Parent = head
    local plaque = part("EstatuaPlaca", Vector3.new(6, 1.8, 0.3), base * CFrame.new(0, 1.9, -5.4) * CFrame.Angles(-0.3, 0, 0), Enum.Material.Metal, GOLD, parent)
    local label = textFace(plaque, Enum.NormalId.Front)
    label.TextColor3 = Color3.fromRGB(46, 30, 10)
    label.Text = "O Guardião\nEle escuta tudo"
end

-- Varal de lanternas entre dois postes (a corda cai em curva, feita de segmentos)
local function buildLanternLine(first: Vector3, second: Vector3, parent: Instance)
    local height = 12
    local topA = first + Vector3.new(0, height, 0)
    local topB = second + Vector3.new(0, height, 0)
    for _, spot in ipairs({ first, second }) do
        part("VaralPoste", Vector3.new(1.2, height, 1.2), CFrame.new(spot + Vector3.new(0, height / 2, 0)), Enum.Material.WoodPlanks, WOOD, parent)
    end
    local segments = 10
    local sag = 3.2
    local function point(t: number): Vector3
        local straight = topA:Lerp(topB, t)
        return straight - Vector3.new(0, sag * 4 * t * (1 - t), 0)
    end
    for index = 1, segments do
        local a, b = point((index - 1) / segments), point(index / segments)
        local length = (b - a).Magnitude
        local rope = part("VaralCorda", Vector3.new(0.18, 0.18, length), CFrame.lookAt((a + b) / 2, b), Enum.Material.Fabric, Color3.fromRGB(60, 44, 30), parent)
        rope.CanCollide = false
    end
    for index = 1, 7 do
        local at = point(index / 8)
        local lantern = part("VaralLanterna", Vector3.new(1.1, 1.5, 1.1), CFrame.new(at - Vector3.new(0, 1.2, 0)), Enum.Material.Neon,
            if index % 2 == 0 then Color3.fromRGB(255, 190, 90) else Color3.fromRGB(255, 140, 70), parent)
        lantern.CanCollide = false
        if index % 2 == 1 then
            local light = Instance.new("PointLight")
            light.Color = Color3.fromRGB(255, 180, 90)
            light.Range = 14
            light.Brightness = 0.9
            light.Parent = lantern
        end
    end
end

local function build()
    local baked = workspace:WaitForChild("WorldBaked", 30)
    if not baked then
        return
    end
    local created = Instance.new("Folder")
    created.Name = "PraçaDecor"
    created.Parent = baked
    folder = created

    local pad = Config.WorldPads.Mina
    local function anchor(dx: number, dz: number): Vector3
        return Vector3.new(pad.x + dx, 0, pad.z + dz)
    end

    local weekLabel: TextLabel? = nil
    local todayLabel: TextLabel? = nil

    local spotA = FreeSpot.Find(anchor(30, -72), 22, 4, 17, 22, rng)
    if spotA then
        weekLabel = buildBoard("PlacarSemana", spotA, created)
    end
    local spotB = FreeSpot.Find(anchor(30, 72), 22, 4, 17, 22, rng)
    if spotB then
        todayLabel = buildBoard("PlacarHoje", spotB, created)
    end
    local altarSpot = FreeSpot.Find(anchor(-62, 52), 12, 12, 9, 22, rng)
    if altarSpot then
        buildAltar(altarSpot, created)
        refreshAltar()
    end
    local statueSpot = FreeSpot.Find(anchor(-62, -52), 12, 12, 22, 22, rng)
    if statueSpot then
        buildStatue(statueSpot, created)
    end
    local poleA = FreeSpot.Find(anchor(-20, -88), 2, 2, 13, 10, rng)
    if poleA then
        local poleB = FreeSpot.Find(poleA + Vector3.new(36, 0, 0), 2, 2, 13, 5, rng)
        if poleB and (poleB - poleA).Magnitude < 48 then
            buildLanternLine(poleA, poleB, created)
        end
    end
    print(string.format("[Praça] placares %s/%s, altar %s, estátua %s", tostring(spotA ~= nil), tostring(spotB ~= nil), tostring(altarSpot ~= nil), tostring(statueSpot ~= nil)))

    ExtractionSystem.Extracted:Connect(function(_player: Player, receipt: any)
        for _, item in ipairs(receipt.items) do
            if item.type == "Relic" then
                relicsToday += 1
            end
        end
        refreshAltar()
    end)

    task.spawn(function()
        while folder do
            if weekLabel then
                weekLabel.Text = topText()
            end
            if todayLabel then
                todayLabel.Text = todayText()
            end
            task.wait(if RunService:IsStudio() then 5 else 15)
        end
    end)
end

function PlazaDecor.Init()
    task.spawn(build)
end

return PlazaDecor
