--!strict
-- Carroças entre a mina e a vila. O cliente só aciona o ProximityPrompt; o servidor confere local, distância,
-- descoberta e tempo de espera, e é o único que move o jogador. A vila só libera depois de o jogador ter ido lá a pé.
-- O Mercado Negro não tem carroça: a caminhada é o preço de achar os pedidos.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local systems = script.Parent :: Instance
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local Enums = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums") :: ModuleScript)
local PlayerState = require(systems:WaitForChild("PlayerState") :: ModuleScript)
local PlayerProfile = require(systems:WaitForChild("PlayerProfile") :: ModuleScript)
local MovementGuard = require(systems:WaitForChild("MovementGuard") :: ModuleScript)

local TravelFade = ReplicatedStorage:WaitForChild("EcosRemotes"):WaitForChild("TravelFade") :: RemoteEvent

local TravelSystem = {}

local FADE_TIME = 0.35

local lastTravel: { [Player]: number } = {}
local traveling: { [Player]: boolean } = {}

local function getRoot(player: Player): BasePart?
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then
        return root
    end
    return nil
end

local function getPart(name: string): BasePart?
    local found = workspace:FindFirstChild(name)
    if found and found:IsA("BasePart") then
        return found
    end
    return nil
end

local function flatDistance(a: Vector3, b: Vector3): number
    local delta = a - b
    return Vector3.new(delta.X, 0, delta.Z).Magnitude
end

-- Leva o jogador até o ponto de chegada, com a tela escurecendo no meio
local function teleport(player: Player, arrival: BasePart)
    local character = player.Character
    if not character then
        return
    end
    TravelFade:FireClient(player)
    task.wait(FADE_TIME)
    if player.Character ~= character or not character.Parent or PlayerState.Get(player) ~= Enums.PlayerLocation.Lobby then
        return
    end
    local target = arrival.CFrame + Vector3.new(0, Config.TeleportHeight, 0)
    MovementGuard.Exempt(player, Config.StreamTimeout + 3)
    if workspace.StreamingEnabled then
        local ok, err = pcall(function()
            player:RequestStreamAroundAsync(target.Position, Config.StreamTimeout)
        end)
        if not ok then
            warn("[Travel] RequestStreamAroundAsync falhou: " .. tostring(err))
        end
    end
    if player.Character == character and character.Parent then
        MovementGuard.Exempt(player, 3)
        character:PivotTo(target)
    end
end

-- `destination` é "Mina" ou "Vila"; `fromCart` é a carroça que o jogador acionou.
local function travel(player: Player, fromCart: BasePart, destination: string)
    if traveling[player] or PlayerState.Get(player) ~= Enums.PlayerLocation.Lobby then
        return
    end
    local root = getRoot(player)
    if not root or flatDistance(root.Position, fromCart.Position) > Config.CartPromptRadius + 10 then
        return
    end
    if destination == "Vila" and not PlayerProfile.HasDiscovered(player, "village") then
        PlayerProfile.Notify(player, "Você ainda não conhece o caminho da vila. Vá a pé uma vez.")
        return
    end
    local now = os.clock()
    local remaining = (lastTravel[player] or -math.huge) + Config.CartCooldown - now
    if remaining > 0 then
        PlayerProfile.Notify(player, string.format("A carroça está descansando (%d s)", math.ceil(remaining)))
        return
    end
    local arrival = getPart("CartArrival" .. destination)
    if not arrival then
        warn("[Travel] ponto de chegada não encontrado: CartArrival" .. destination)
        return
    end

    lastTravel[player] = now
    traveling[player] = true
    teleport(player, arrival)
    traveling[player] = nil
    print(string.format("[Travel] %s foi de carroça para %s", player.Name, destination))
end

-- Quem pisa na área da vila passa a poder voltar a ela de carroça
local function checkDiscovery()
    local pad = Config.WorldPads.Vila
    local center = Vector3.new(pad.x, 0, pad.z)
    for _, player in ipairs(Players:GetPlayers()) do
        if PlayerState.Get(player) == Enums.PlayerLocation.Lobby and not PlayerProfile.HasDiscovered(player, "village") then
            local root = getRoot(player)
            if root and flatDistance(root.Position, center) <= pad.r then
                PlayerProfile.SetDiscovered(player, "village", true)
                PlayerProfile.Notify(player, "Vila descoberta: agora a carroça da mina leva até aqui.")
            end
        end
    end
end

function TravelSystem.Init()
    local mineCart = getPart("CartMina")
    local villageCart = getPart("CartVila")
    if not mineCart or not villageCart then
        warn("[Travel] CartMina ou CartVila não encontrada.")
        return
    end

    local function connect(cart: BasePart, destination: string)
        local prompt = cart:FindFirstChildOfClass("ProximityPrompt")
        if prompt then
            prompt.Triggered:Connect(function(player)
                travel(player, cart, destination)
            end)
        end
    end
    connect(mineCart, "Vila")
    connect(villageCart, "Mina")

    Players.PlayerRemoving:Connect(function(player)
        lastTravel[player] = nil
        traveling[player] = nil
    end)

    task.spawn(function()
        while true do
            task.wait(1)
            checkDiscovery()
        end
    end)
end

-- Usado só pelo QA do Studio: apaga a descoberta da vila.
function TravelSystem.QAForget(player: Player)
    PlayerProfile.SetDiscovered(player, "village", false)
    lastTravel[player] = nil
end

return TravelSystem
