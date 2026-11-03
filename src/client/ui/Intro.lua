--!strict
-- T1 (parcial): abertura de 5 s para quem chega sem moedas, itens nem melhorias. Tela escura, o nome do jogo e uma frase
-- que ensina o essencial sem texto longo. Dá para pular com o botão ou com qualquer tecla. Só cliente, não mexe no jogo.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Theme = require((script.Parent :: Instance):WaitForChild("Theme") :: ModuleScript)
local Widgets = require((script.Parent :: Instance):WaitForChild("Widgets") :: ModuleScript)
local ProfileHUD = require((script.Parent :: Instance):WaitForChild("ProfileHUD") :: ModuleScript)

local player = Players.LocalPlayer

local Intro = {}

local SHOW_SECONDS = 5
local LINES = {
    "Cada passo faz barulho.",
    "O Guardião ouve tudo.",
    "Pegue os núcleos. Volte vivo.",
}

local shown = false

local function play()
    local gui = Instance.new("ScreenGui")
    gui.Name = "EcosIntro"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 20
    gui.Parent = player:WaitForChild("PlayerGui")

    local backdrop = Instance.new("Frame")
    backdrop.Size = UDim2.fromScale(1, 1)
    backdrop.BackgroundColor3 = Color3.fromRGB(4, 4, 8)
    backdrop.BorderSizePixel = 0
    backdrop.Parent = gui

    local title = Widgets.Label(backdrop, {
        text = "ECOS DA PENUMBRA",
        position = UDim2.fromScale(0.1, 0.34),
        size = UDim2.fromScale(0.8, 0.14),
        font = Theme.Font.Title,
        textSize = 54,
        color = Theme.Color.Gold,
        alignX = Enum.TextXAlignment.Center,
    })
    title.TextTransparency = 1
    local line = Widgets.Label(backdrop, {
        text = LINES[1],
        position = UDim2.fromScale(0.1, 0.52),
        size = UDim2.fromScale(0.8, 0.07),
        textSize = 26,
        alignX = Enum.TextXAlignment.Center,
    })
    line.TextTransparency = 1

    local finished = false
    local function finish()
        if finished then
            return
        end
        finished = true
        TweenService:Create(backdrop, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
        TweenService:Create(title, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
        TweenService:Create(line, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
        task.delay(0.7, function()
            gui:Destroy()
        end)
    end

    local connection: RBXScriptConnection
    connection = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            connection:Disconnect()
            finish()
        end
    end)
    Widgets.Button(backdrop, {
        text = "Pular",
        size = UDim2.new(0, 120, 0, 36),
        position = UDim2.new(1, -140, 1, -56),
        onClick = function()
            connection:Disconnect()
            finish()
        end,
    })

    TweenService:Create(title, TweenInfo.new(1.2), { TextTransparency = 0 }):Play()
    task.spawn(function()
        local per = (SHOW_SECONDS - 1.2) / #LINES
        for index, text in ipairs(LINES) do
            if finished then
                return
            end
            line.Text = text
            line.TextTransparency = 1
            TweenService:Create(line, TweenInfo.new(0.5), { TextTransparency = 0 }):Play()
            task.wait(per)
        end
        connection:Disconnect()
        finish()
    end)
end

function Intro.Init()
    ProfileHUD.OnChanged(function(info: any)
        if shown then
            return
        end
        shown = true
        local fresh = info.money == 0 and #info.stash == 0 and next(info.upgrades) == nil
        if fresh then
            play()
        end
    end)
end

return Intro
