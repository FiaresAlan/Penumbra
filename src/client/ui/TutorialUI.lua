--!strict
-- T1: o lado do jogador da primeira descida guiada: faixa de dica no alto da tela e botão "Pular" enquanto durar.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Theme = require((script.Parent :: Instance):WaitForChild("Theme") :: ModuleScript)
local Widgets = require((script.Parent :: Instance):WaitForChild("Widgets") :: ModuleScript)

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("EcosRemotes")
local HintRemote = Remotes:WaitForChild("TutorialHint") :: RemoteEvent
local SkipRemote = Remotes:WaitForChild("TutorialSkip") :: RemoteEvent

local TutorialUI = {}

local token = 0

function TutorialUI.Init()
    local gui = Instance.new("ScreenGui")
    gui.Name = "EcosTutorial"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 15
    gui.Parent = player:WaitForChild("PlayerGui")

    local banner = Widgets.Label(gui, {
        text = "",
        position = UDim2.new(0.15, 0, 0.1, 0),
        size = UDim2.new(0.7, 0, 0, 60),
        font = Theme.Font.Strong,
        textSize = 26,
        color = Theme.Color.Parchment,
        alignX = Enum.TextXAlignment.Center,
    })
    banner.TextWrapped = true
    banner.TextTransparency = 1
    banner.TextStrokeTransparency = 1

    local skip = Widgets.Button(gui, {
        text = "Pular",
        size = UDim2.new(0, 120, 0, 36),
        position = UDim2.new(1, -140, 1, -60),
        onClick = function()
            SkipRemote:FireServer()
        end,
    })
    skip.Visible = false

    player:GetAttributeChangedSignal("InTutorial"):Connect(function()
        skip.Visible = player:GetAttribute("InTutorial") == true
    end)

    HintRemote.OnClientEvent:Connect(function(text: unknown, seconds: unknown)
        if typeof(text) ~= "string" then
            return
        end
        token += 1
        local mine = token
        banner.Text = text
        TweenService:Create(banner, TweenInfo.new(0.3), { TextTransparency = 0, TextStrokeTransparency = 0.5 }):Play()
        task.delay(if typeof(seconds) == "number" then seconds else 8, function()
            if mine == token then
                TweenService:Create(banner, TweenInfo.new(0.6), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
            end
        end)
    end)
end

return TutorialUI
