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
local SneakInput = require(script:WaitForChild("SneakInput"))
local GuardianPresence = require(script:WaitForChild("GuardianPresence"))
local TutorialHints = require(script:WaitForChild("ui"):WaitForChild("TutorialHints"))
local ClipPrompt = require(script:WaitForChild("ui"):WaitForChild("ClipPrompt"))
local ClipExporter = require(script:WaitForChild("clips"):WaitForChild("ClipExporter"))
local VoiceNoise = require(script:WaitForChild("VoiceNoise"))
local WorldAudio = require(script:WaitForChild("audio"):WaitForChild("WorldAudio"))

NoiseBar.Init()
ExtractionUI.Init()
QAPanel.Init()
NestUI.Init()
ProfileHUD.Init()
ShopUI.Init()
HookController.Init()
ClipPrompt.Init()
ClipExporter.Init()
SneakInput.Init()
GuardianPresence.Init()
TutorialHints.Init()
ZoneLighting.Init(function(isCave)
    NoiseBar.SetVisible(isCave)
    GuardianPresence.SetActive(isCave)
    if isCave then
        TutorialHints.OnEnterCave()
    end
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
