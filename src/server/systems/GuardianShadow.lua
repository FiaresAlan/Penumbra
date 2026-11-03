--!strict
-- Ideia maior do plano: o Guardião apaga as luzes de enfeite por onde passa. As luzes (lâmpadas, cristais, velas) a menos de
-- Config.GuardianShadow.Radius studs dele escurecem e voltam ao normal quando ele se afasta. Só aparência: não muda ruído, caça
-- nem velocidade. Só roda durante a expedição, olhando as luzes de enfeite de Map.
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local systems = script.Parent :: Instance
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local ExpeditionSystem = require(systems:WaitForChild("ExpeditionSystem") :: ModuleScript)

local GuardianShadow = {}

local original: { [PointLight]: number } = {}
local timer = 0

local function isDecorative(light: PointLight): boolean
    local owner = light.Parent
    if not owner then
        return false
    end
    return owner.Name == "CaveLamp" or owner.Name == "Crystal" or string.find(owner.Name, "Candle", 1, true) ~= nil
end

local function restoreAll()
    for light, brightness in pairs(original) do
        if light.Parent then
            light.Brightness = brightness
        end
    end
    table.clear(original)
end

function GuardianShadow.Init()
    ExpeditionSystem.Ended:Connect(restoreAll)
    RunService.Heartbeat:Connect(function(dt: number)
        if not Config.Features.GuardianShadow then
            return
        end
        timer += dt
        if timer < 0.4 then
            return
        end
        timer = 0
        if ExpeditionSystem.GetPhase() ~= "Active" then
            return
        end
        local guardian = workspace:FindFirstChild("Guardian")
        local root = guardian and guardian:FindFirstChild("HumanoidRootPart")
        local map = workspace:FindFirstChild("Map")
        if not root or not root:IsA("BasePart") or not map then
            return
        end
        local radius = Config.GuardianShadow.Radius
        for _, descendant in ipairs(map:GetDescendants()) do
            if descendant:IsA("PointLight") and isDecorative(descendant) then
                local owner = descendant.Parent
                if owner and owner:IsA("BasePart") then
                    local near = (owner.Position - root.Position).Magnitude < radius
                    local saved = original[descendant]
                    if near and not saved then
                        original[descendant] = descendant.Brightness
                        descendant.Brightness = descendant.Brightness * Config.GuardianShadow.Dim
                    elseif not near and saved then
                        descendant.Brightness = saved
                        original[descendant] = nil
                    end
                end
            end
        end
    end)
end

return GuardianShadow
