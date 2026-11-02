local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("EcosRemotes")
local VoiceSpike = Remotes:WaitForChild("VoiceSpike")

local NoiseBar = require(script:WaitForChild("ui"):WaitForChild("NoiseBar"))
local ExtractionUI = require(script:WaitForChild("ui"):WaitForChild("ExtractionUI"))
local QAPanel = require(script:WaitForChild("ui"):WaitForChild("QAPanel"))
local NestUI = require(script:WaitForChild("ui"):WaitForChild("NestUI"))
local ZoneLighting = require(script:WaitForChild("ZoneLighting"))
local ProfileHUD = require(script:WaitForChild("ui"):WaitForChild("ProfileHUD"))
local ShopUI = require(script:WaitForChild("ui"):WaitForChild("ShopUI"))
local HookController = require(script:WaitForChild("HookController"))
local VoiceNoise = require(script:WaitForChild("VoiceNoise"))
local WorldAudio = require(script:WaitForChild("audio"):WaitForChild("WorldAudio"))

NoiseBar.Init()
ExtractionUI.Init()
QAPanel.Init()
NestUI.Init()
ProfileHUD.Init()
ShopUI.Init()
HookController.Init()
ZoneLighting.Init(function(isCave)
    NoiseBar.SetVisible(isCave)
end)
VoiceNoise.Init()
WorldAudio.Init()

-- Tecla V = "grito" (simula voz por enquanto)
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.V then
        VoiceSpike:FireServer(10)
        NoiseBar.ShowSpike()
    end
end)
