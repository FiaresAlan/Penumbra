--!strict
-- Gancho: fuga vertical até pontos marcados no mapa. O cliente só pede; o servidor valida tudo e move o jogador.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local systems = script.Parent :: Instance
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local Enums = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums") :: ModuleScript)
local PlayerState = require(systems:WaitForChild("PlayerState") :: ModuleScript)
local PlayerProfile = require(systems:WaitForChild("PlayerProfile") :: ModuleScript)
local NoiseSystem = require(systems:WaitForChild("NoiseSystem") :: ModuleScript)
local RateLimiter = require(systems:WaitForChild("RateLimiter") :: ModuleScript)

local UseHook = ReplicatedStorage:WaitForChild("EcosRemotes"):WaitForChild("UseHook") :: RemoteEvent

local HookSystem = {}

local lastUse: { [Player]: number } = {}

local function getRoot(player: Player): BasePart?
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then
        return root
    end
    return nil
end

-- Há linha de visão até o ponto? O raio pode terminar no próprio ponto ou na saliência logo abaixo dele.
local function hasLineOfSight(player: Player, from: Vector3, point: BasePart): boolean
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { player.Character :: Instance }
    local result = workspace:Raycast(from, point.Position - from, params)
    if not result then
        return true
    end
    return (result.Position - point.Position).Magnitude < 4
end

-- O personagem é congelado e levado em passos pequenos; o servidor controla o movimento todo.
local function pull(player: Player, target: Vector3)
    local character = player.Character
    local root = getRoot(player)
    if not character or not root then
        return
    end
    local start = root.Position
    local rotation = character:GetPivot().Rotation
    root.Anchored = true

    local startedAt = os.clock()
    while true do
        if PlayerState.Get(player) ~= Enums.PlayerLocation.Cave or player.Parent ~= Players then
            -- Se foi sequestrado, o KidnapSystem é o dono do congelamento; nos demais casos libera aqui
            local location = PlayerState.Get(player)
            if location ~= Enums.PlayerLocation.Dragged and location ~= Enums.PlayerLocation.Captive then
                root.Anchored = false
            end
            return
        end
        local alpha = math.min((os.clock() - startedAt) / Config.HookPullTime, 1)
        local eased = 1 - (1 - alpha) ^ 2
        character:PivotTo(CFrame.new(start:Lerp(target, eased)) * rotation)
        if alpha >= 1 then
            break
        end
        RunService.Heartbeat:Wait()
    end
    root.Anchored = false
end

function HookSystem.Init()
    UseHook.OnServerEvent:Connect(function(player, pointName: unknown)
        if not RateLimiter.Allow(player, "UseHook", 2, 2) then
            return
        end
        if typeof(pointName) ~= "string" or #(pointName :: string) > 32 then
            return
        end
        if PlayerState.Get(player) ~= Enums.PlayerLocation.Cave then
            return
        end
        if not PlayerProfile.HasUpgrade(player, "Hook") then
            return
        end

        local now = os.clock()
        if lastUse[player] and now - lastUse[player] < Config.HookCooldown then
            return
        end

        local folder = workspace:FindFirstChild("HookPoints")
        local point = folder and folder:FindFirstChild(pointName :: string)
        local root = getRoot(player)
        if not point or not point:IsA("BasePart") or not root then
            return
        end
        if (root.Position - point.Position).Magnitude > Config.HookRange then
            return
        end
        if not hasLineOfSight(player, root.Position, point) then
            return
        end

        lastUse[player] = now
        -- O gancho faz barulho: o Guardião ouve
        NoiseSystem.AddPulse(player, Config.HookNoise, 2)
        print(string.format("[Hook] %s usou o gancho (%s)", player.Name, point.Name))
        local land = point:GetAttribute("Land")
        local offset = if typeof(land) == "Vector3" then land else Vector3.new(0, 3, 0)
        task.spawn(pull, player, point.Position + offset)
    end)

    Players.PlayerRemoving:Connect(function(player)
        lastUse[player] = nil
    end)
end

return HookSystem
