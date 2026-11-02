--!strict
-- Lanterna do jogador: um cone de luz curto que segue a câmera, só na caverna. Tecla L liga e desliga.
-- A luz existe apenas no cliente de quem a usa; não é um segredo nem um recurso de jogo.
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Flashlight = {}

local lightPart: Part? = nil
local spot: SpotLight? = nil
local inCave = false
local wanted = true

local function refresh()
    if spot then
        spot.Enabled = inCave and wanted
    end
end

function Flashlight.SetActive(isCave: boolean)
    inCave = isCave
    refresh()
end

function Flashlight.Init()
    local part = Instance.new("Part")
    part.Name = "EcosFlashlight"
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.Transparency = 1
    part.Size = Vector3.new(0.2, 0.2, 0.2)
    part.Parent = workspace
    lightPart = part

    local light = Instance.new("SpotLight")
    light.Face = Enum.NormalId.Front
    light.Angle = 62
    light.Range = 54
    light.Brightness = 3.6
    light.Color = Color3.fromRGB(255, 232, 195)
    light.Shadows = false
    light.Enabled = false
    light.Parent = part
    spot = light

    RunService:BindToRenderStep("EcosFlashlight", Enum.RenderPriority.Camera.Value + 2, function()
        local camera = workspace.CurrentCamera
        if camera and lightPart then
            lightPart.CFrame = camera.CFrame
        end
    end)

    UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == Enum.KeyCode.L then
            wanted = not wanted
            refresh()
        end
    end)
end

return Flashlight
