--!strict
-- Troca a iluminação e os efeitos de tela conforme o lugar: lobby claro e seguro, caverna escura e fechada.
-- A mudança é só local ao jogador. A transição escurece a tela por um instante.
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("EcosRemotes"):WaitForChild("LocationChanged") :: RemoteEvent

local ZoneLighting = {}

local LOBBY: { [string]: any } = {
    Brightness = 2,
    Ambient = Color3.fromRGB(120, 120, 130),
    OutdoorAmbient = Color3.fromRGB(140, 140, 150),
    ClockTime = 16.8, -- fim de tarde sobre o vale
    FogColor = Color3.fromRGB(215, 195, 175),
    FogStart = 250,
    FogEnd = 1300,
    ExposureCompensation = -0.3,
}

local CAVE: { [string]: any } = {
    Brightness = 0,
    Ambient = Color3.fromRGB(34, 34, 46),
    OutdoorAmbient = Color3.fromRGB(24, 24, 34),
    ClockTime = 0,
    FogColor = Color3.fromRGB(8, 8, 14),
    FogStart = 14,
    FogEnd = 170,
    ExposureCompensation = 0.3,
}

local fadeFrame: Frame? = nil
local currentIsCave: boolean? = nil
local onChange: ((boolean) -> ())? = nil

-- Efeitos de tela: guarda como estavam no lobby para restaurar depois
local colorEffect: ColorCorrectionEffect? = nil
local atmosphere: Atmosphere? = nil
local bloom: BloomEffect? = nil
local depth: DepthOfFieldEffect? = nil
local sunRays: SunRaysEffect? = nil
local lobbyAtmosphere: { [string]: any } = {}
local lobbyBloom = 1
local lobbySunRays = true

local function applyInstant(settings: { [string]: any })
    for property, value in pairs(settings) do
        (Lighting :: any)[property] = value
    end
end

local function applyEffects(isCave: boolean)
    if colorEffect then
        colorEffect.Brightness = if isCave then -0.03 else 0
        colorEffect.Contrast = if isCave then 0.18 else 0
        colorEffect.Saturation = if isCave then -0.2 else 0
        colorEffect.TintColor = if isCave then Color3.fromRGB(205, 218, 255) else Color3.new(1, 1, 1)
    end
    if atmosphere then
        if isCave then
            atmosphere.Density = 0.42
            atmosphere.Offset = 0
            atmosphere.Color = Color3.fromRGB(18, 20, 28)
            atmosphere.Decay = Color3.fromRGB(8, 8, 12)
            atmosphere.Haze = 2.2
            atmosphere.Glare = 0
        else
            for property, value in pairs(lobbyAtmosphere) do
                (atmosphere :: any)[property] = value
            end
        end
    end
    if bloom then
        bloom.Intensity = if isCave then lobbyBloom * 0.7 else lobbyBloom
    end
    if depth then
        depth.Enabled = isCave
        depth.FarIntensity = 0.35
        depth.FocusDistance = 45
        depth.InFocusRadius = 30
        depth.NearIntensity = 0
    end
    if sunRays then
        sunRays.Enabled = if isCave then false else lobbySunRays
    end
end

-- S1: névoa e tom por zona da caverna. As colunas da grade têm 16 studs a partir de X 420: A até a coluna 9,
-- B até a 18 e C depois. A transição é suave (tween) e só roda dentro da caverna.
local CAVE_ORIGIN_X = 420
local CAVE_CELL = 16
local ZONE_LOOK: { [string]: { density: number, haze: number, color: Color3, decay: Color3, tint: Color3 } } = {
    A = { density = 0.40, haze = 2.0, color = Color3.fromRGB(46, 30, 20), decay = Color3.fromRGB(30, 16, 8), tint = Color3.fromRGB(255, 226, 190) },
    B = { density = 0.46, haze = 2.4, color = Color3.fromRGB(26, 22, 52), decay = Color3.fromRGB(14, 10, 30), tint = Color3.fromRGB(210, 205, 255) },
    C = { density = 0.54, haze = 3.0, color = Color3.fromRGB(12, 44, 50), decay = Color3.fromRGB(4, 22, 28), tint = Color3.fromRGB(190, 240, 245) },
}
local lastZone = ""

local function zoneNow(): string?
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") then
        return nil
    end
    local column = math.floor((root.Position.X - CAVE_ORIGIN_X) / CAVE_CELL)
    if column <= 9 then
        return "A"
    elseif column <= 18 then
        return "B"
    end
    return "C"
end

local function conditionLook(): { fog: number, tint: Color3? }
    local id = workspace:GetAttribute("ActiveCondition")
    local fog = workspace:GetAttribute("ConditionFog")
    local tint = workspace:GetAttribute("ConditionTint")
    return { fog = if typeof(id) == "string" and typeof(fog) == "number" then fog else 0, tint = if typeof(tint) == "Color3" then tint else nil }
end

local function updateZoneLook()
    local zone = zoneNow()
    if not zone or zone == lastZone then
        return
    end
    lastZone = zone
    local look = ZONE_LOOK[zone]
    local info = TweenInfo.new(2.5, Enum.EasingStyle.Sine)
    local condition = conditionLook()
    if atmosphere then
        TweenService:Create(atmosphere, info, { Density = math.clamp(look.density + condition.fog, 0.1, 0.9), Haze = look.haze, Color = look.color, Decay = look.decay }):Play()
    end
    if colorEffect then
        local tint = look.tint
        if condition.tint then
            tint = tint:Lerp(condition.tint, 0.5)
        end
        TweenService:Create(colorEffect, info, { TintColor = tint }):Play()
    end
end

local function setupEffects()
    colorEffect = Lighting:FindFirstChild("EcosColor") :: ColorCorrectionEffect?
    if not colorEffect then
        local created = Instance.new("ColorCorrectionEffect")
        created.Name = "EcosColor"
        created.Parent = Lighting
        colorEffect = created
    end
    atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    if atmosphere then
        for _, property in ipairs({ "Density", "Offset", "Color", "Decay", "Haze", "Glare" }) do
            lobbyAtmosphere[property] = (atmosphere :: any)[property]
        end
    end
    bloom = Lighting:FindFirstChildOfClass("BloomEffect")
    if bloom then
        lobbyBloom = bloom.Intensity
    end
    depth = Lighting:FindFirstChildOfClass("DepthOfFieldEffect")
    if not depth then
        local created = Instance.new("DepthOfFieldEffect")
        created.Enabled = false
        created.Parent = Lighting
        depth = created
    end
    sunRays = Lighting:FindFirstChildOfClass("SunRaysEffect")
    if sunRays then
        lobbySunRays = sunRays.Enabled
    end
end

local function transitionTo(isCave: boolean)
    if currentIsCave == isCave then
        return
    end
    currentIsCave = isCave
    lastZone = ""
    if onChange then
        onChange(isCave)
    end
    local settings = if isCave then CAVE else LOBBY

    local frame = fadeFrame
    if not frame then
        applyInstant(settings)
        applyEffects(isCave)
        return
    end

    -- Escurece, troca a iluminação por baixo e volta
    TweenService:Create(frame, TweenInfo.new(0.25), { BackgroundTransparency = 0 }):Play()
    task.delay(0.3, function()
        applyInstant(settings)
        applyEffects(isCave)
        TweenService:Create(frame, TweenInfo.new(0.9), { BackgroundTransparency = 1 }):Play()
    end)
end

-- onZoneChange(isCave) avisa outros módulos quando o jogador entra ou sai da caverna.
function ZoneLighting.Init(onZoneChange: ((boolean) -> ())?)
    onChange = onZoneChange
    if onChange then
        onChange(false)
    end
    setupEffects()

    local gui = Instance.new("ScreenGui")
    gui.Name = "EcosFade"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 100
    gui.Parent = player:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromScale(1, 1)
    frame.BackgroundColor3 = Color3.new(0, 0, 0)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Active = false
    frame.Parent = gui
    fadeFrame = frame

    -- Começa no lobby
    currentIsCave = false
    applyInstant(LOBBY)
    applyEffects(false)

    -- Viagem de carroça: a tela escurece enquanto o servidor move o jogador e volta depois
    local travelFade = ReplicatedStorage:WaitForChild("EcosRemotes"):WaitForChild("TravelFade") :: RemoteEvent
    travelFade.OnClientEvent:Connect(function(lookTarget: unknown)
        TweenService:Create(frame, TweenInfo.new(0.3), { BackgroundTransparency = 0 }):Play()
        if typeof(lookTarget) == "Vector3" then
            -- Depois do teleporte, vira a câmera para a carroça de chegada (o prompt só aparece com ela à vista)
            task.delay(0.8, function()
                local camera = workspace.CurrentCamera
                local character = player.Character
                local root = character and character:FindFirstChild("HumanoidRootPart")
                if not camera or not root or not root:IsA("BasePart") then
                    return
                end
                local flat = Vector3.new(lookTarget.X - root.Position.X, 0, lookTarget.Z - root.Position.Z)
                if flat.Magnitude < 0.1 then
                    return
                end
                local direction = flat.Unit
                local previousType = camera.CameraType
                camera.CameraType = Enum.CameraType.Scriptable
                camera.CFrame = CFrame.lookAt(root.Position - direction * 14 + Vector3.new(0, 7, 0), root.Position + direction * 6)
                task.wait()
                camera.CameraType = previousType
            end)
        end
        task.delay(0.9, function()
            TweenService:Create(frame, TweenInfo.new(0.7), { BackgroundTransparency = 1 }):Play()
        end)
    end)

    task.spawn(function()
        while true do
            task.wait(0.6)
            if currentIsCave then
                updateZoneLook()
            end
        end
    end)

    workspace:GetAttributeChangedSignal("ActiveCondition"):Connect(function()
        lastZone = ""
    end)

    remote.OnClientEvent:Connect(function(location: unknown)
        if typeof(location) ~= "string" then
            return
        end
        transitionTo(location ~= "Lobby")
    end)
end

return ZoneLighting
