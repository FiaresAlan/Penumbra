--!strict
-- F1: anima o monstro em stop-motion. O Guardião tem uma pasta "Poses" com várias MeshParts (uma pose cada), só uma visível por vez.
-- Parado ou dormindo: a primeira pose. Em movimento: passa pelas outras em ritmo que acompanha a velocidade (mais rápido na caça).
-- Só aparência: lê a velocidade e o estado, nunca decide nada de jogo.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local systems = script.Parent :: Instance
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local Enums = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums") :: ModuleScript)
local GuardianAI = require(systems:WaitForChild("GuardianAI") :: ModuleScript)

local GuardianAnimator = {}

local shown = 0
local acc = 0
local cursor = 1

local function show(poses: { BasePart }, index: number)
    if index == shown then
        return
    end
    shown = index
    for position, pose in ipairs(poses) do
        pose.Transparency = if position == index then 0 else 1
    end
end

function GuardianAnimator.Init()
    RunService.Heartbeat:Connect(function(dt: number)
        acc += dt
        if acc < 0.05 then
            return
        end
        local step = acc
        acc = 0
        local guardian = workspace:FindFirstChild("Guardian")
        local folder = guardian and guardian:FindFirstChild("Poses")
        local root = guardian and guardian:FindFirstChild("HumanoidRootPart")
        if not folder or not root or not root:IsA("BasePart") then
            return
        end
        local poses: { BasePart } = {}
        for index = 1, #folder:GetChildren() do
            local pose = folder:FindFirstChild("Pose" .. index)
            if pose and pose:IsA("BasePart") then
                table.insert(poses, pose)
            end
        end
        if #poses < 2 then
            return
        end
        local velocity = root.AssemblyLinearVelocity
        local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
        local state = GuardianAI.GetState()
        if state == Enums.GuardianState.Sleeping or speed < 1 then
            show(poses, 1)
            cursor = 1
            return
        end
        -- tempo por pose: caça é rápida, andar é lento
        local interval = math.clamp(0.7 - speed / 40, Config.MonsterPoseMin, 0.7)
        cursor += step / interval
        local index = 2 + (math.floor(cursor) % (#poses - 1))
        show(poses, index)
    end)
end

return GuardianAnimator
