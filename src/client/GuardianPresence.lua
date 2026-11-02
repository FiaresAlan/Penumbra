--!strict
-- Faz o jogador sentir o Guardião antes de vê-lo: tremor leve na câmera e vinheta vermelha que crescem
-- conforme a distância diminui. Só lê o que já é visível (o modelo do Guardião); não revela nenhum segredo.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GuardianPresence = {}

local FAR = 70 -- além disso não sente nada
local NEAR = 14 -- perto disso é o máximo

local active = false
local intensity = 0
local vignette: Frame? = nil

-- 0 (longe) a 1 (colado). Outros módulos usam para o batimento cardíaco.
function GuardianPresence.GetIntensity(): number
    return intensity
end

function GuardianPresence.SetActive(isActive: boolean)
    active = isActive
    if not isActive then
        intensity = 0
        if vignette then
            vignette.BackgroundTransparency = 1
        end
    end
end

function GuardianPresence.Init()
    local gui = Instance.new("ScreenGui")
    gui.Name = "EcosPresence"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 50
    gui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromScale(1, 1)
    frame.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Active = false
    frame.Parent = gui
    vignette = frame

    local elapsed = 0
    RunService.Heartbeat:Connect(function(dt)
        elapsed += dt
        if elapsed < 0.1 then
            return
        end
        elapsed = 0

        local target = 0
        if active then
            local guardian = workspace:FindFirstChild("Guardian")
            local guardianRoot = guardian and guardian:FindFirstChild("HumanoidRootPart")
            local character = player.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if guardianRoot and guardianRoot:IsA("BasePart") and root and root:IsA("BasePart") then
                local distance = (guardianRoot.Position - root.Position).Magnitude
                target = math.clamp(1 - (distance - NEAR) / (FAR - NEAR), 0, 1)
            end
        end
        -- Suaviza para a sensação subir e descer sem saltos
        intensity += (target - intensity) * 0.4
        if vignette then
            vignette.BackgroundTransparency = 1 - intensity * 0.22
        end
    end)

    RunService:BindToRenderStep("EcosPresenceShake", Enum.RenderPriority.Camera.Value + 1, function()
        if intensity < 0.15 then
            return
        end
        local camera = workspace.CurrentCamera
        if not camera then
            return
        end
        local amount = intensity * 0.12
        local offset = Vector3.new(math.random() - 0.5, math.random() - 0.5, 0) * amount
        camera.CFrame = camera.CFrame * CFrame.new(offset)
    end)
end

return GuardianPresence
