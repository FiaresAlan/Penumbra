--!strict
-- Cria o modelo do Guardião e o põe na câmara do núcleo.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)

local Layout = require(script.Parent:WaitForChild("CaveLayout") :: ModuleScript)

local cellCenter = Layout.cellCenter

-- F1: troca o corpo escuro do R15 pelas poses do monstro (ServerStorage.EcosAssets.Monstros.GuardianPoses): cada pose é uma MeshPart
-- soldada à raiz; o GuardianAnimator mostra uma de cada vez (stop-motion). O R15 continua existindo, invisível, só como corpo físico.
local function attachSkin(model: Model, root: BasePart, humanoid: Humanoid?)
    local assets = ServerStorage:FindFirstChild("EcosAssets")
    local monsters = assets and assets:FindFirstChild("Monstros")
    local template = monsters and monsters:FindFirstChild("GuardianPoses")
    if not template then
        warn("[Map] GuardianPoses não encontrado: o Guardião fica com o corpo simples")
        return
    end
    local poses: { MeshPart } = {}
    for _, child in ipairs(template:GetChildren()) do
        if child:IsA("MeshPart") then
            table.insert(poses, child)
        end
    end
    table.sort(poses, function(a, b)
        return a.Name < b.Name
    end)
    if #poses == 0 then
        return
    end
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant ~= root then
            descendant.Transparency = 1
        end
    end
    root.Transparency = 1
    local folder = Instance.new("Folder")
    folder.Name = "Poses"
    folder.Parent = model
    local hip = if humanoid then humanoid.HipHeight else 2
    local feetY = -(hip + root.Size.Y / 2)
    local factor = Config.MonsterHeight / math.max(poses[1].Size.Y, 0.1)
    for index, source in ipairs(poses) do
        local pose = source:Clone()
        pose.Size = source.Size * factor
        pose.Name = "Pose" .. index
        pose.Anchored = false
        pose.CanCollide = false
        pose.CanTouch = false
        pose.CanQuery = false
        pose.Massless = true
        -- sem textura (as imagens do pacote ainda não foram enviadas), a pele ganha uma cor fria e fosca
        pose.Color = Color3.fromRGB(Config.MonsterColor[1], Config.MonsterColor[2], Config.MonsterColor[3])
        pose.Material = Enum.Material.SmoothPlastic
        pose.Reflectance = 0.08
        pose.Transparency = if index == 1 then 0 else 1
        pose.CFrame = root.CFrame * CFrame.new(0, feetY + pose.Size.Y / 2 + Config.MonsterYOffset, 0) * CFrame.Angles(0, math.rad(Config.MonsterYaw), 0)
        pose.Parent = folder
        local weld = Instance.new("Weld")
        weld.Name = "Corpo"
        weld.Part0 = root
        weld.Part1 = pose
        weld.C0 = root.CFrame:ToObjectSpace(pose.CFrame)
        weld.Parent = pose
    end
    model:SetAttribute("FeetY", feetY)
    -- Brilho: olhos que brilham (sempre virados para a câmera), luz de brasa e fagulhas subindo do corpo
    local head = Vector3.new(0, feetY + Config.MonsterHeight * 0.86, 0)
    local anchorPart = Instance.new("Part")
    anchorPart.Name = "Rosto"
    anchorPart.Size = Vector3.new(0.4, 0.4, 0.4)
    anchorPart.Transparency = 1
    anchorPart.CanCollide = false
    anchorPart.CanTouch = false
    anchorPart.CanQuery = false
    anchorPart.Massless = true
    anchorPart.CFrame = root.CFrame * CFrame.new(head)
    anchorPart.Parent = folder
    local anchorWeld = Instance.new("Weld")
    anchorWeld.Name = "Corpo"
    anchorWeld.Part0 = root
    anchorWeld.Part1 = anchorPart
    anchorWeld.C0 = root.CFrame:ToObjectSpace(anchorPart.CFrame)
    anchorWeld.Parent = anchorPart
    local eyes = Instance.new("BillboardGui")
    eyes.Size = UDim2.fromOffset(46, 16)
    eyes.AlwaysOnTop = false
    eyes.LightInfluence = 0
    eyes.MaxDistance = 140
    eyes.Parent = anchorPart
    for _, side in ipairs({ 0.05, 0.62 }) do
        local eye = Instance.new("Frame")
        eye.Size = UDim2.fromOffset(14, 9)
        eye.Position = UDim2.fromScale(side, 0.2)
        eye.BackgroundColor3 = Color3.fromRGB(255, 240, 80)
        eye.BorderSizePixel = 0
        eye.Parent = eyes
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = eye
    end
    local glow = Instance.new("PointLight")
    glow.Color = Color3.fromRGB(Config.MonsterGlow[1], Config.MonsterGlow[2], Config.MonsterGlow[3])
    glow.Range = 16
    glow.Brightness = 0.6
    glow.Parent = anchorPart
    local spores = Instance.new("ParticleEmitter")
    spores.Color = ColorSequence.new(Color3.fromRGB(255, 190, 60), Color3.fromRGB(255, 70, 20))
    spores.LightEmission = 0.8
    spores.Rate = 18
    spores.Lifetime = NumberRange.new(2, 4)
    spores.Speed = NumberRange.new(1, 3)
    spores.Acceleration = Vector3.new(0, 2, 0)
    spores.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
    spores.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
    spores.SpreadAngle = Vector2.new(60, 60)
    spores.Parent = anchorPart
    model:SetAttribute("Skinned", true)
end

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
            if Config.MonsterSkin then
                attachSkin(model, root, humanoid)
            end
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
