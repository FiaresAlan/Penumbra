--!strict
-- Núcleo Denso (P3 do plano, seção 10B): alguns núcleos viram "densos": valem 3x, pesam 4 (dois espaços) e fazem mais barulho
-- pelo peso. É uma escolha de risco clara: pegar o pesado ou os leves. Ligado por Config.Features.DenseCore (desligado por padrão).
-- Restaura os normais a cada expedição; o servidor decide tudo (o item é só um atributo do núcleo).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local systems = script.Parent :: Instance
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local ExpeditionSystem = require(systems:WaitForChild("ExpeditionSystem") :: ModuleScript)

local DenseCore = {}

local COUNT = 2
local DENSE_COLOR = Color3.fromRGB(96, 40, 160)

local changed: { BasePart } = {}

local function restore()
    for _, part in ipairs(changed) do
        if part.Parent then
            part:SetAttribute("ItemType", "Core")
            part.Size = Vector3.new(2.4, 2.4, 2.4)
            local original = part:GetAttribute("OriginalColor")
            if typeof(original) == "Color3" then
                part.Color = original
            end
        end
    end
    table.clear(changed)
end

function DenseCore.Run(): number
    restore()
    local map = workspace:FindFirstChild("Map")
    if not map then
        return 0
    end
    local rng = Random.new(os.time() + math.floor(os.clock() * 1000))
    local candidates: { BasePart } = {}
    for _, descendant in ipairs(map:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant:GetAttribute("IsCore") and descendant:GetAttribute("ItemType") == "Core" then
            local zone = descendant:GetAttribute("DepthZone")
            if zone == "B" or zone == "C" then
                table.insert(candidates, descendant)
            end
        end
    end
    for index = #candidates, 2, -1 do
        local other = rng:NextInteger(1, index)
        candidates[index], candidates[other] = candidates[other], candidates[index]
    end
    local made = 0
    for index = 1, math.min(COUNT, #candidates) do
        local part = candidates[index]
        part:SetAttribute("OriginalColor", part.Color)
        part:SetAttribute("ItemType", "DenseCore")
        part.Size = Vector3.new(3.4, 3.4, 3.4)
        part.Color = DENSE_COLOR
        table.insert(changed, part)
        made += 1
    end
    print(string.format("[Dense] %d núcleos densos nesta expedição", made))
    return made
end

function DenseCore.Init()
    ExpeditionSystem.Started:Connect(function()
        if Config.Features.DenseCore then
            DenseCore.Run()
        else
            restore()
        end
    end)
end

return DenseCore
