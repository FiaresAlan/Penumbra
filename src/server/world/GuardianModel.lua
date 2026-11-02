--!strict
-- Cria o modelo do Guardião e o põe na câmara do núcleo.
local Players = game:GetService("Players")

local Layout = require(script.Parent:WaitForChild("CaveLayout") :: ModuleScript)

local cellCenter = Layout.cellCenter

local function buildGuardian()
    local home = cellCenter(24, 8)
    task.spawn(function()
        local ok, model = pcall(function()
            return Players:CreateHumanoidModelFromDescription(Instance.new("HumanoidDescription"), Enum.HumanoidRigType.R15)
        end)
        if not ok or not model then
            warn("[Map] Não foi possível criar o Guardião: " .. tostring(model))
            return
        end
        model.Name = "Guardian"
        for _, descendant in ipairs(model:GetDescendants()) do
            if descendant:IsA("BasePart") then
                descendant.Color = Color3.fromRGB(22, 18, 28)
                descendant.Material = Enum.Material.Slate
            elseif descendant:IsA("Decal") then
                descendant:Destroy()
            end
        end
        local humanoid = model:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            humanoid.WalkSpeed = 0
        end
        model:ScaleTo(1.7)
        model:PivotTo(CFrame.new(home + Vector3.new(0, 6, 0)))
        model:SetAttribute("Generated", true)
        model.Parent = workspace
        local root = model:FindFirstChild("HumanoidRootPart")
        if root and root:IsA("BasePart") then
            -- Na prévia do Studio (sem jogo rodando) a API de rede não existe
            if game:GetService("RunService"):IsRunning() then
                root:SetNetworkOwner(nil)
            end
            local eyes = Instance.new("PointLight")
            eyes.Color = Color3.fromRGB(255, 60, 60)
            eyes.Range = 18
            eyes.Brightness = 1
            eyes.Parent = root
        end
    end)
end

return { Build = buildGuardian }
