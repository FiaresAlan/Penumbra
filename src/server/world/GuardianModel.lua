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
        pose.Material = Enum.Material.Slate
        pose.Transparency = if index == 1 then 0 else 1
        pose.CFrame = root.CFrame * CFrame.new(0, feetY + pose.Size.Y / 2 + Config.MonsterYOffset, 0) * CFrame.Angles(0, math.rad(Config.MonsterYaw), 0)
        pose.Parent = folder
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = root
        weld.Part1 = pose
        weld.Parent = pose
    end
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
