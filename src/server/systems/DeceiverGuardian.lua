--!strict
-- Guardião Enganador: cria núcleos falsos perto de quem faz barulho e paredes falsas atravessáveis.
-- Quais núcleos são falsos fica só no servidor (tabela em LootSystem): nada marca o falso para o cliente.
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local systems = script.Parent :: Instance
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local NoiseSystem = require(systems:WaitForChild("NoiseSystem") :: ModuleScript)
local LootSystem = require(systems:WaitForChild("LootSystem") :: ModuleScript)
local AudioBroadcast = require(systems:WaitForChild("AudioBroadcast") :: ModuleScript)
local FloorPicker = require(systems:WaitForChild("FloorPicker") :: ModuleScript)
local GuardianAI = require(systems:WaitForChild("GuardianAI") :: ModuleScript)

local DeceiverGuardian = {}

local generation = 0
local fakes: { Instance } = {}

local function liveFakeCount(): number
    local alive: { Instance } = {}
    for _, fake in ipairs(fakes) do
        if fake.Parent then
            table.insert(alive, fake)
        end
    end
    fakes = alive
    return #alive
end

-- Copia um núcleo comum de verdade que ainda esteja no chão, para o falso ser idêntico.
local function pickSource(): BasePart?
    local mapFolder = workspace:FindFirstChild("Map")
    local candidates: { BasePart } = {}
    if mapFolder then
        for _, child in ipairs(mapFolder:GetChildren()) do
            if child:IsA("BasePart") and child:GetAttribute("IsCore") and child:GetAttribute("ItemType") == "Core"
                and not child:GetAttribute("Collected") then
                table.insert(candidates, child)
            end
        end
    end
    if #candidates > 0 then
        return candidates[math.random(1, #candidates)]
    end
    local template = ServerStorage:FindFirstChild("CoreTemplate")
    if template and template:IsA("BasePart") then
        return template
    end
    return nil
end

local function spawnFakeCore()
    if liveFakeCount() >= Config.DeceiverMaxFakeCores then
        return
    end
    local loudest, noise = NoiseSystem.GetLoudestPlayer()
    if not loudest or noise <= Config.GuardianHearThreshold then
        return
    end
    local root = loudest.Character and loudest.Character:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") then
        return
    end
    local source = pickSource()
    local floor = FloorPicker.Pick(root.Position, Config.DeceiverMinDistance, Config.DeceiverMaxDistance)
    if not source or not floor then
        return
    end

    local position = floor + Vector3.new(0, 2.2, 0)
    local fake = source:Clone()
    fake.Position = position
    LootSystem.MarkFake(fake, function(_player: Player, at: Vector3)
        AudioBroadcast.Play("Laugh", at)
    end)
    fake.Parent = workspace:FindFirstChild("Map") or workspace
    table.insert(fakes, fake)
    Debris:AddItem(fake, Config.DeceiverCoreLifetime)
    print("[Deceiver] núcleo falso criado")
    AudioBroadcast.Play("RockDrop", position)
end

local function spawnFakeWall()
    local folder = workspace:FindFirstChild("FakeWallSlots")
    if not folder then
        return
    end
    local slots = folder:GetChildren()
    if #slots == 0 then
        return
    end
    local slot = slots[math.random(1, #slots)]
    if not slot:IsA("BasePart") then
        return
    end
    local wall = Instance.new("Part")
    wall.Name = "Wall"
    wall.Anchored = true
    wall.CanCollide = false
    wall.Transparency = 0
    wall.Material = Enum.Material.Rock
    wall.Color = Color3.fromRGB(70, 66, 74)
    wall.Size = slot.Size
    wall.CFrame = slot.CFrame
    wall.Parent = workspace:FindFirstChild("Map") or workspace
    table.insert(fakes, wall)
    Debris:AddItem(wall, Config.DeceiverWallLifetime)
    print("[Deceiver] parede falsa criada")
end

function DeceiverGuardian.Stop()
    generation += 1
    for _, fake in ipairs(fakes) do
        fake:Destroy()
    end
    fakes = {}
end

function DeceiverGuardian.Start()
    DeceiverGuardian.Stop()
    local gen = generation

    task.spawn(function()
        while gen == generation do
            task.wait(Config.DeceiverCoreInterval)
            if gen == generation then
                spawnFakeCore()
            end
        end
    end)
    task.spawn(function()
        while gen == generation do
            task.wait(Config.DeceiverWallInterval)
            if gen == generation then
                spawnFakeWall()
            end
        end
    end)
    -- O Enganador também é um Guardião que caça: nada muda na máquina de estados
    GuardianAI.SetSpeedMultiplier("variant", 1)
end

return DeceiverGuardian
