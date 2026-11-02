--!strict
-- Grava vídeo com CaptureService (cliente) enquanto o jogador está na expedição e oferece o clipe ao sair.
-- Não usa VideoCaptureService. Qualquer falha só é registrada no Output: o jogo nunca depende da gravação.
-- Limites conhecidos: não há buffer retroativo, 9:16, watermark gravado no arquivo nem mixagem de voz.
local CaptureService = game:GetService("CaptureService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local ClipSignal = ReplicatedStorage:WaitForChild("EcosRemotes"):WaitForChild("ClipSignal") :: RemoteEvent
local clientRoot = (script.Parent :: Instance).Parent :: Instance
local ClipPrompt = require(clientRoot:WaitForChild("ui"):WaitForChild("ClipPrompt") :: ModuleScript)

local ClipExporter = {}

local recordings: { any } = {} -- as duas gravações mais recentes
local active = false -- queremos estar gravando
local starting = false
local watermark: TextLabel? = nil

local function isUsable(result: any): boolean
    return result == Enum.VideoCaptureResult.Success or result == Enum.VideoCaptureResult.TimeLimitReached
end

local startRecording: () -> ()

local function onCaptureReady(result: any, capture: any)
    if isUsable(result) and capture then
        table.insert(recordings, capture)
        while #recordings > 2 do
            table.remove(recordings, 1)
        end
    else
        print("[Clips] Gravação descartada: " .. tostring(result))
    end
    -- O tempo máximo da gravação foi atingido: guarda e começa outra, para cobrir a expedição inteira
    if result == Enum.VideoCaptureResult.TimeLimitReached and active then
        task.defer(startRecording)
    end
end

startRecording = function()
    if starting or not active then
        return
    end
    starting = true
    local startResult: any = nil
    local ok, err = pcall(function()
        startResult = CaptureService:StartVideoCaptureAsync(onCaptureReady, {})
    end)
    starting = false
    if ok then
        print("[Clips] Gravação: " .. tostring(startResult))
    else
        print("[Clips] Gravação indisponível: " .. tostring(err))
    end
end

function ClipExporter.Init()
    local gui = Instance.new("ScreenGui")
    gui.Name = "EcosRecording"
    gui.ResetOnSpawn = false
    gui.Parent = playerGui

    -- Texto discreto no canto: aparece na tela durante a gravação (se a interface entrar no vídeo, ele vai junto)
    local mark = Instance.new("TextLabel")
    mark.Size = UDim2.new(0, 160, 0, 20)
    mark.Position = UDim2.new(1, -170, 1, -26)
    mark.BackgroundTransparency = 1
    mark.TextColor3 = Color3.fromRGB(255, 255, 255)
    mark.TextTransparency = 0.4
    mark.Font = Enum.Font.GothamBold
    mark.TextSize = 12
    mark.TextXAlignment = Enum.TextXAlignment.Right
    mark.Text = "Ecos da Penumbra"
    mark.Visible = false
    mark.Parent = gui
    watermark = mark

    ClipSignal.OnClientEvent:Connect(function(signal: unknown)
        if signal == "start" then
            active = true
            recordings = {}
            ClipPrompt.Hide()
            if watermark then
                watermark.Visible = true
            end
            task.spawn(startRecording)
        elseif signal == "stop" then
            active = false
            if watermark then
                watermark.Visible = false
            end
            pcall(function()
                CaptureService:StopVideoCapture()
            end)
            -- Dá um instante para a gravação ser entregue ao callback e então oferece o clipe
            task.delay(1.5, function()
                local latest = recordings[#recordings]
                if latest and not active then
                    ClipPrompt.Show(latest)
                end
            end)
        end
    end)
end

return ClipExporter
