local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Enums = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums"))
local NoiseSystem = require(script.Parent:WaitForChild("NoiseSystem"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))

local GuardianAI = {}

local caughtEvent = Instance.new("BindableEvent")
GuardianAI.PlayerCaught = caughtEvent.Event

local guardianModel, guardianHumanoid, guardianRoot
local homePosition
local homeCFrame
local currentState = Enums.GuardianState.Sleeping
local lastKnownPosition
local stateTimer = 0
local silenceTimer = 0
local sleptAt = os.clock()
local hearThreshold = Config.GuardianHearThreshold
local speedMultipliers = {}
local lastMoveAt = 0
local lastMoveTarget
local lastCatchCheck = 0

local function setState(newState)
    currentState = newState
    stateTimer = 0
    silenceTimer = 0
    if newState == Enums.GuardianState.Sleeping then
        sleptAt = os.clock()
    end
    print("[Guardian] -> " .. newState)
end

local function speedMultiplier()
    local total = 1
    for _, value in pairs(speedMultipliers) do
        total = total * value
    end
    return total
end

-- Chama MoveTo no máximo a cada Config.GuardianMoveInterval, e só se o destino mudou.
local function directMoveTo(target)
    local now = os.clock()
    if now - lastMoveAt < Config.GuardianMoveInterval then return end
    if lastMoveTarget and (lastMoveTarget - target).Magnitude < 1 then return end
    lastMoveAt = now
    lastMoveTarget = target
    guardianHumanoid:MoveTo(target)
end

-- Caminho calculado de forma assíncrona; só um cálculo por vez.
local pathState = {
    waypoints = nil,
    index = 1,
    target = nil,
    computing = false,
    lastCompute = 0,
    warned = false,
}

local function computePath(target)
    pathState.computing = true
    task.spawn(function()
        local path = PathfindingService:CreatePath({
            AgentRadius = Config.GuardianAgentRadius,
            AgentHeight = Config.GuardianAgentHeight,
            AgentCanJump = false,
            WaypointSpacing = 6,
        })
        local origin = guardianRoot.Position
        local ok, err = pcall(function()
            path:ComputeAsync(origin, target)
        end)
        if ok and path.Status == Enum.PathStatus.Success then
            pathState.waypoints = path:GetWaypoints()
            pathState.index = 2
            pathState.target = target
        else
            pathState.waypoints = nil
            pathState.target = nil
            if not pathState.warned then
                pathState.warned = true
                warn("[Guardian] Sem caminho até o alvo; usando movimento direto. " .. tostring(err))
            end
        end
        pathState.computing = false
    end)
end

local function moveTo(target)
    local now = os.clock()
    local stale = pathState.waypoints == nil or pathState.target == nil
        or (pathState.target - target).Magnitude > 4
    if stale and not pathState.computing and now - pathState.lastCompute >= Config.GuardianRepathInterval then
        pathState.lastCompute = now
        computePath(target)
    end

    local waypoints = pathState.waypoints
    local waypoint = waypoints and waypoints[pathState.index]
    if waypoint then
        local offset = guardianRoot.Position - waypoint.Position
        if Vector3.new(offset.X, 0, offset.Z).Magnitude < 4 then
            pathState.index = pathState.index + 1
            waypoint = waypoints[pathState.index]
        end
    end
    if waypoint then
        directMoveTo(waypoint.Position)
    else
        directMoveTo(target)
    end
end

local function clearPath()
    pathState.waypoints = nil
    pathState.target = nil
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

function GuardianAI.GetState()
    return currentState
end

-- Cada sistema usa a sua própria chave (tier de tempo, pity...) e os fatores se multiplicam.
function GuardianAI.SetSpeedMultiplier(key, value)
    speedMultipliers[key] = value
end

function GuardianAI.SetHearThreshold(value)
    hearThreshold = value
end

function GuardianAI.Reset()
    lastKnownPosition = nil
    lastMoveTarget = nil
    clearPath()
    setState(Enums.GuardianState.Sleeping)
    if guardianModel and guardianRoot and homeCFrame then
        guardianModel:PivotTo(homeCFrame)
        guardianRoot.AssemblyLinearVelocity = Vector3.zero
    end
end

-- Usado só pelo QA do Studio
function GuardianAI.TeleportTo(position)
    if guardianModel then
        guardianModel:PivotTo(CFrame.new(position))
        guardianRoot.AssemblyLinearVelocity = Vector3.zero
    end
end

local function checkCatch()
    for _, player in ipairs(PlayerState.GetPlayersIn(Enums.PlayerLocation.Cave)) do
        local char = player.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if humanoid and root and humanoid.Health > 0 then
            if (root.Position - guardianRoot.Position).Magnitude <= Config.GuardianCatchRadius then
                caughtEvent:Fire(player)
            end
        end
    end
end

local function update(dt)
    if not guardianModel or not guardianHumanoid or guardianHumanoid.Health <= 0 then
        return
    end
    stateTimer = stateTimer + dt

    local multiplier = speedMultiplier()
    local loudest, noise = NoiseSystem.GetLoudestPlayer()
    local loudestRoot = loudest and loudest.Character and loudest.Character:FindFirstChild("HumanoidRootPart")
    local hears = loudestRoot ~= nil and noise > hearThreshold

    if currentState == Enums.GuardianState.Sleeping then
        guardianHumanoid.WalkSpeed = 0
        if hears and workspace:GetAttribute("FirstCoreExtracted")
            and os.clock() - sleptAt >= Config.GuardianRestTime then
            setState(Enums.GuardianState.Alert)
        end

    elseif currentState == Enums.GuardianState.Alert then
        guardianHumanoid.WalkSpeed = 0
        if loudestRoot then
            if stateTimer >= Config.GuardianAlertDelay then
                lastKnownPosition = loudestRoot.Position
                setState(Enums.GuardianState.Hunting)
            end
        elseif stateTimer > 3 then
            setState(Enums.GuardianState.Returning)
        end

    elseif currentState == Enums.GuardianState.Hunting then
        guardianHumanoid.WalkSpeed = Config.GuardianChaseSpeed * multiplier
        if hears then
            lastKnownPosition = loudestRoot.Position
            silenceTimer = 0
        else
            silenceTimer = silenceTimer + dt
        end
        if lastKnownPosition then
            moveTo(lastKnownPosition)
        end
        if silenceTimer >= Config.GuardianLostScentTime then
            setState(Enums.GuardianState.LostScent)
        end

    elseif currentState == Enums.GuardianState.LostScent then
        guardianHumanoid.WalkSpeed = Config.GuardianWalkSpeed * multiplier
        if hears then
            lastKnownPosition = loudestRoot.Position
            setState(Enums.GuardianState.Hunting)
        else
            if lastKnownPosition then
                moveTo(lastKnownPosition)
            end
            if stateTimer > Config.GuardianInvestigateTime then
                setState(Enums.GuardianState.Returning)
            end
        end

    elseif currentState == Enums.GuardianState.Returning then
        guardianHumanoid.WalkSpeed = Config.GuardianWalkSpeed * multiplier
        if hears then
            setState(Enums.GuardianState.Alert)
        elseif homePosition then
            moveTo(homePosition)
            if (guardianRoot.Position - homePosition).Magnitude < 5 then
                setState(Enums.GuardianState.Sleeping)
            end
        end
    end

    if currentState == Enums.GuardianState.Hunting or currentState == Enums.GuardianState.LostScent then
        if os.clock() - lastCatchCheck >= 0.1 then
            lastCatchCheck = os.clock()
            checkCatch()
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
