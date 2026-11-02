local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Enums = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums"))
local NoiseSystem = require(script.Parent:WaitForChild("NoiseSystem"))

local GuardianAI = {}

local guardianModel, guardianHumanoid, guardianRoot
local homePosition
local homeCFrame
local currentState = Enums.GuardianState.Sleeping
local lastKnownPosition
local stateTimer = 0

local function setState(newState)
    currentState = newState
    stateTimer = 0
    print("[Guardian] -> " .. newState)
end

local function findGuardian()
    local g = workspace:FindFirstChild("Guardian")
    if g then
        local hum = g:FindFirstChildOfClass("Humanoid")
        local root = g:FindFirstChild("HumanoidRootPart")
        if hum and root then
            guardianModel = g
            guardianHumanoid = hum
            guardianRoot = root
            homePosition = root.Position
            homeCFrame = g:GetPivot()
            return true
        end
    end
    return false
end

function GuardianAI.WakeUp()
    if currentState == Enums.GuardianState.Sleeping then
        setState(Enums.GuardianState.Alert)
    end
end

function GuardianAI.Reset()
    lastKnownPosition = nil
    setState(Enums.GuardianState.Sleeping)
    if guardianModel and guardianRoot and homeCFrame then
        guardianModel:PivotTo(homeCFrame)
        guardianRoot.AssemblyLinearVelocity = Vector3.zero
    end
end

local function update(dt)
    if not guardianModel or not guardianHumanoid or guardianHumanoid.Health <= 0 then
        return
    end
    stateTimer = stateTimer + dt

    if currentState == Enums.GuardianState.Sleeping then
        guardianHumanoid.WalkSpeed = 0

    elseif currentState == Enums.GuardianState.Alert then
        guardianHumanoid.WalkSpeed = 0
        local loudest = NoiseSystem.GetLoudestPlayer()
        if loudest and loudest.Character and loudest.Character.PrimaryPart then
            if stateTimer >= Config.GuardianAlertDelay then
                lastKnownPosition = loudest.Character.PrimaryPart.Position
                setState(Enums.GuardianState.Hunting)
            end
        elseif stateTimer > 3 then
            setState(Enums.GuardianState.Returning)
        end

    elseif currentState == Enums.GuardianState.Hunting then
        guardianHumanoid.WalkSpeed = Config.GuardianChaseSpeed
        local loudest, noise = NoiseSystem.GetLoudestPlayer()
        if loudest and loudest.Character and loudest.Character.PrimaryPart and noise > 1.5 then
            lastKnownPosition = loudest.Character.PrimaryPart.Position
            guardianHumanoid:MoveTo(lastKnownPosition)
        else
            if lastKnownPosition then
                guardianHumanoid:MoveTo(lastKnownPosition)
            end
            if stateTimer > Config.GuardianLostScentTime then
                setState(Enums.GuardianState.LostScent)
            end
        end

    elseif currentState == Enums.GuardianState.LostScent then
        guardianHumanoid.WalkSpeed = Config.GuardianWalkSpeed
        if lastKnownPosition then
            guardianHumanoid:MoveTo(lastKnownPosition)
        end
        if stateTimer > Config.GuardianInvestigateTime then
            setState(Enums.GuardianState.Returning)
        end

    elseif currentState == Enums.GuardianState.Returning then
        guardianHumanoid.WalkSpeed = Config.GuardianWalkSpeed
        if homePosition then
            guardianHumanoid:MoveTo(homePosition)
            if guardianRoot and (guardianRoot.Position - homePosition).Magnitude < 5 then
                setState(Enums.GuardianState.Sleeping)
            end
        end
    end
end

function GuardianAI.Init()
    workspace:GetAttributeChangedSignal("FirstCoreExtracted"):Connect(function()
        if workspace:GetAttribute("FirstCoreExtracted") then
            GuardianAI.WakeUp()
        end
    end)

    task.spawn(function()
        while not findGuardian() do
            task.wait(1)
        end
        print("[Guardian] Inicializado em " .. tostring(homePosition))
    end)

    RunService.Heartbeat:Connect(update)
end

return GuardianAI