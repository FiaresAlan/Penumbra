--!strict
-- Troca a iluminação conforme o lugar: lobby claro e seguro, caverna escura e fechada.
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
    ClockTime = 14,
    FogColor = Color3.fromRGB(190, 200, 215),
    FogStart = 0,
    FogEnd = 100000,
    ExposureCompensation = -0.3,
}

local CAVE: { [string]: any } = {
    Brightness = 0,
    Ambient = Color3.fromRGB(28, 28, 36),
    OutdoorAmbient = Color3.fromRGB(18, 18, 24),
    ClockTime = 0,
    FogColor = Color3.fromRGB(8, 8, 12),
    FogStart = 20,
    FogEnd = 190,
    ExposureCompensation = 0,
}

local fadeFrame: Frame? = nil
local currentIsCave: boolean? = nil
local onChange: ((boolean) -> ())? = nil

local function applyInstant(settings: { [string]: any })
    for property, value in pairs(settings) do
        (Lighting :: any)[property] = value
    end
end

local function transitionTo(isCave: boolean)
    if currentIsCave == isCave then
        return
    end
    currentIsCave = isCave
    if onChange then
        onChange(isCave)
    end
    local settings = if isCave then CAVE else LOBBY

    local frame = fadeFrame
    if not frame then
        applyInstant(settings)
        return
    end

    -- Escurece, troca a iluminação por baixo e volta
    TweenService:Create(frame, TweenInfo.new(0.25), { BackgroundTransparency = 0 }):Play()
    task.delay(0.3, function()
        applyInstant(settings)
        TweenService:Create(frame, TweenInfo.new(0.9), { BackgroundTransparency = 1 }):Play()
    end)
end

-- onZoneChange(isCave) avisa outros módulos de UI quando o jogador entra ou sai da caverna.
function ZoneLighting.Init(onZoneChange: ((boolean) -> ())?)
    onChange = onZoneChange
    if onChange then
        onChange(false)
    end
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

    remote.OnClientEvent:Connect(function(location: unknown)
        if typeof(location) ~= "string" then
            return
        end
        transitionTo(location ~= "Lobby")
    end)
end

return ZoneLighting
