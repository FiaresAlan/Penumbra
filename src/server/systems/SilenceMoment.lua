--!strict
-- P2 (Features.SilenceMoment): uma vez por expedição, depois de um tempo sorteado, o jogo avisa (3 s) e faz um apagão curto.
-- Durante o apagão quem se mexe faz barulho extra; quem fica parado não é afetado. Quem está perto do elevador (extraindo)
-- fica de fora, e nada é tirado de ninguém. O cliente mostra o aviso e a escuridão pelos atributos SilenceWarn e SilenceMoment.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local systems = script.Parent :: Instance
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local Enums = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums") :: ModuleScript)
local ExpeditionSystem = require(systems:WaitForChild("ExpeditionSystem") :: ModuleScript)
local NoiseSystem = require(systems:WaitForChild("NoiseSystem") :: ModuleScript)
local PlayerState = require(systems:WaitForChild("PlayerState") :: ModuleScript)

local SilenceMoment = {}

local rng = Random.new()
local runId = 0

local function clearBoosts()
    for _, player in ipairs(Players:GetPlayers()) do
        NoiseSystem.SetNoiseBoost(player, "silence", nil)
    end
    workspace:SetAttribute("SilenceWarn", nil)
    workspace:SetAttribute("SilenceMoment", nil)
end

local function active(mine: number): boolean
    return mine == runId and ExpeditionSystem.GetPhase() == "Active"
end

local function waitSeconds(total: number, mine: number): boolean
    local waited = 0
    while waited < total do
        task.wait(0.5)
        waited += 0.5
        if not active(mine) then
            return false
        end
    end
    return true
end

local function applyBoosts()
    local settings = Config.Silence
    local elevator = workspace:FindFirstChild("Elevator")
    for _, player in ipairs(PlayerState.GetPlayersIn(Enums.PlayerLocation.Cave)) do
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local boost: number? = nil
        if root and root:IsA("BasePart") then
            local velocity = root.AssemblyLinearVelocity
            local flat = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
            local safe = elevator ~= nil and elevator:IsA("BasePart") and (root.Position - elevator.Position).Magnitude <= settings.ElevatorSafeRadius
            if flat > settings.MoveSpeed and not safe then
                boost = settings.Boost
            end
        end
        NoiseSystem.SetNoiseBoost(player, "silence", boost)
    end
end

function SilenceMoment.Init()
    ExpeditionSystem.Started:Connect(function()
        if not Config.Features.SilenceMoment then
            return
        end
        runId += 1
        local mine = runId
        task.spawn(function()
            local settings = Config.Silence
            if not waitSeconds(rng:NextNumber(settings.MinDelay, settings.MaxDelay), mine) then
                return
            end
            workspace:SetAttribute("SilenceWarn", true)
            print("[Silence] aviso")
            if not waitSeconds(settings.WarnSeconds, mine) then
                clearBoosts()
                return
            end
            workspace:SetAttribute("SilenceWarn", nil)
            workspace:SetAttribute("SilenceMoment", true)
            print("[Silence] apagão")
            local elapsed = 0
            while elapsed < settings.Seconds and active(mine) do
                applyBoosts()
                task.wait(0.5)
                elapsed += 0.5
            end
            clearBoosts()
            print("[Silence] fim")
        end)
    end)

    ExpeditionSystem.Ended:Connect(function()
        runId += 1
        clearBoosts()
    end)
end

return SilenceMoment
