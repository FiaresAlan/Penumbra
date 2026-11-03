--!strict
-- P2: o lado do jogador do momento de silêncio. Aviso curto ("fique parado") e uma escuridão suave enquanto dura.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Theme = require((script.Parent :: Instance):WaitForChild("Theme") :: ModuleScript)
local Widgets = require((script.Parent :: Instance):WaitForChild("Widgets") :: ModuleScript)

local player = Players.LocalPlayer

local SilenceFx = {}

function SilenceFx.Init()
    local gui = Instance.new("ScreenGui")
    gui.Name = "EcosSilence"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 12
    gui.Parent = player:WaitForChild("PlayerGui")

    local dark = Instance.new("Frame")
    dark.Size = UDim2.fromScale(1, 1)
    dark.BackgroundColor3 = Color3.new(0, 0, 0)
    dark.BackgroundTransparency = 1
    dark.BorderSizePixel = 0
    dark.Active = false
    dark.Parent = gui

    local label = Widgets.Label(gui, {
        text = "",
        position = UDim2.fromScale(0.2, 0.32),
        size = UDim2.fromScale(0.6, 0.08),
        font = Theme.Font.Strong,
        textSize = 30,
        color = Theme.Color.Parchment,
        alignX = Enum.TextXAlignment.Center,
    })
    label.TextTransparency = 1

    local function show(text: string)
        label.Text = text
        TweenService:Create(label, TweenInfo.new(0.4), { TextTransparency = 0 }):Play()
    end
    local function hide()
        TweenService:Create(label, TweenInfo.new(0.6), { TextTransparency = 1 }):Play()
    end

    workspace:GetAttributeChangedSignal("SilenceWarn"):Connect(function()
        if workspace:GetAttribute("SilenceWarn") == true then
            show("Algo prende a respiração... fique parado")
        end
    end)
    workspace:GetAttributeChangedSignal("SilenceMoment"):Connect(function()
        if workspace:GetAttribute("SilenceMoment") == true then
            TweenService:Create(dark, TweenInfo.new(0.8), { BackgroundTransparency = 0.45 }):Play()
            show("Não se mova")
        else
            TweenService:Create(dark, TweenInfo.new(1.2), { BackgroundTransparency = 1 }):Play()
            hide()
        end
    end)
end

return SilenceFx
