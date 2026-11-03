--!strict
-- Faixa com o nome da caverna sorteada ou votada quando o jogador desce ("Descendo para: Mina Abandonada"). Some em 4 s.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local Theme = require((script.Parent :: Instance):WaitForChild("Theme") :: ModuleScript)
local Widgets = require((script.Parent :: Instance):WaitForChild("Widgets") :: ModuleScript)

local player = Players.LocalPlayer

local SiteBanner = {}

local label: TextLabel? = nil
local token = 0

function SiteBanner.Init()
    local gui = Instance.new("ScreenGui")
    gui.Name = "EcosSiteBanner"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 14
    gui.Parent = player:WaitForChild("PlayerGui")
    local created = Widgets.Label(gui, {
        text = "",
        position = UDim2.new(0.1, 0, 0.18, 0),
        size = UDim2.new(0.8, 0, 0, 50),
        font = Theme.Font.Title,
        textSize = 34,
        color = Theme.Color.Gold,
        alignX = Enum.TextXAlignment.Center,
    })
    created.TextTransparency = 1
    label = created
end

-- Chamado quando o jogador entra na caverna
function SiteBanner.Show()
    local current = label
    if not current then
        return
    end
    local site = workspace:GetAttribute("CaveSite")
    local info = if typeof(site) == "string" then Config.CaveSiteInfo[site] else nil
    if not info then
        return
    end
    token += 1
    local mine = token
    current.Text = "Descendo para: " .. info.title
    TweenService:Create(current, TweenInfo.new(0.5), { TextTransparency = 0 }):Play()
    task.delay(4, function()
        if mine == token and current.Parent then
            TweenService:Create(current, TweenInfo.new(0.8), { TextTransparency = 1 }):Play()
        end
    end)
end

return SiteBanner
