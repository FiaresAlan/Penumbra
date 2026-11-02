--!strict
-- Ninho: tempo limite do preso, resgate pelo grupo e batidas nas grades.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local systems = script.Parent :: Instance
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local Enums = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums") :: ModuleScript)
local PlayerState = require(systems:WaitForChild("PlayerState") :: ModuleScript)
local ExpeditionSystem = require(systems:WaitForChild("ExpeditionSystem") :: ModuleScript)
local KidnapSystem = require(systems:WaitForChild("KidnapSystem") :: ModuleScript)
local NoiseSystem = require(systems:WaitForChild("NoiseSystem") :: ModuleScript)
local AudioBroadcast = require(systems:WaitForChild("AudioBroadcast") :: ModuleScript)

local Remotes = ReplicatedStorage:WaitForChild("EcosRemotes")
local NestUpdate = Remotes:WaitForChild("NestUpdate") :: RemoteEvent
local CaptiveBang = Remotes:WaitForChild("CaptiveBang") :: RemoteEvent

local Location = Enums.PlayerLocation

local NestSystem = {}

local rescuedEvent = Instance.new("BindableEvent")
NestSystem.PlayerRescued = rescuedEvent.Event

type Captive = { slot: BasePart, deadline: number }

local captives: { [Player]: Captive } = {}
local prompts: { [BasePart]: ProximityPrompt } = {}
local lastBang: { [Player]: number } = {}
local shown: { [Player]: boolean } = {} -- quem está com a mensagem do Ninho na tela
local holding: { [Player]: { slot: BasePart, startedAt: number } } = {} -- quem segura o botão de soltar

local function getRoot(player: Player): BasePart?
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then
        return root
    end
    return nil
end

local function captiveOf(slot: BasePart): Player?
    for player, captive in pairs(captives) do
        if captive.slot == slot then
            return player
        end
    end
    return nil
end

local function setPrompt(slot: BasePart, enabled: boolean, label: string?)
    local prompt = prompts[slot]
    if prompt then
        prompt.Enabled = enabled
        prompt.ObjectText = label or ""
    end
end

local function stopHolding(rescuer: Player)
    holding[rescuer] = nil
    NoiseSystem.SetNoiseBoost(rescuer, "rescue", nil)
end

local function removeCaptive(player: Player)
    local captive = captives[player]
    if captive then
        captives[player] = nil
        setPrompt(captive.slot, false, nil)
        -- Quem ainda segurava o botão desta vaga não pode ficar com o ruído do resgate preso
        for rescuer, hold in pairs(holding) do
            if hold.slot == captive.slot then
                stopHolding(rescuer)
            end
        end
    end
end

-- Quem pode soltar: jogador livre na caverna, diferente do preso e perto da vaga.
local function validRescuer(rescuer: Player, slot: BasePart): Player?
    local captive = captiveOf(slot)
    if not captive or captive == rescuer then
        return nil
    end
    if PlayerState.Get(rescuer) ~= Location.Cave then
        return nil
    end
    local root = getRoot(rescuer)
    if not root or (root.Position - slot.Position).Magnitude > Config.RescueRadius then
        return nil
    end
    return captive
end

local function setupSlotPrompts()
    local folder = workspace:FindFirstChild("NestSlots")
    if not folder then
        warn("[Nest] NestSlots não encontrado.")
        return
    end
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("BasePart") then
            local slot = child
            local prompt = Instance.new("ProximityPrompt")
            prompt.ActionText = "Soltar"
            prompt.HoldDuration = Config.RescueHoldTime
            prompt.MaxActivationDistance = 10
            prompt.RequiresLineOfSight = false
            prompt.Enabled = false
            prompt.Parent = slot
            prompts[slot] = prompt

            -- Soltar é barulhento: o ruído sobe enquanto o jogador segura o botão
            prompt.PromptButtonHoldBegan:Connect(function(rescuer)
                if validRescuer(rescuer, slot) then
                    holding[rescuer] = { slot = slot, startedAt = os.clock() }
                    NoiseSystem.SetNoiseBoost(rescuer, "rescue", Config.RescueNoise)
                end
            end)
            prompt.PromptButtonHoldEnded:Connect(function(rescuer)
                stopHolding(rescuer)
            end)
            prompt.Triggered:Connect(function(rescuer)
                -- O tempo de segurar é medido no servidor: o cliente poderia disparar o resgate sem esperar
                local hold = holding[rescuer]
                stopHolding(rescuer)
                if not hold or hold.slot ~= slot or os.clock() - hold.startedAt < Config.RescueHoldTime - 0.5 then
                    return
                end
                local captive = validRescuer(rescuer, slot)
                if not captive then
                    return
                end
                print(string.format("[Nest] %s soltou %s", rescuer.Name, captive.Name))
                removeCaptive(captive)
                KidnapSystem.Release(captive)
                rescuedEvent:Fire(rescuer, captive)
            end)
        end
    end
end

-- Cada jogador recebe a lista de presos, com o tempo de cada um. Quem deixa de ver o Ninho recebe a ordem de limpar.
local function broadcast()
    local list: { { name: string, timeLeft: number, userId: number } } = {}
    for player, captive in pairs(captives) do
        table.insert(list, { name = player.Name, timeLeft = math.max(0, math.ceil(captive.deadline - os.clock())), userId = player.UserId })
    end
    table.sort(list, function(a, b)
        return a.timeLeft < b.timeLeft
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        local location = PlayerState.Get(player)
        if #list > 0 and (location == Location.Cave or location == Location.Captive) then
            local entries = {}
            for _, entry in ipairs(list) do
                table.insert(entries, { name = entry.name, timeLeft = entry.timeLeft, isYou = entry.userId == player.UserId })
            end
            shown[player] = true
            NestUpdate:FireClient(player, { captives = entries })
        elseif shown[player] then
            shown[player] = nil
            NestUpdate:FireClient(player, { none = true })
        end
    end
end

-- Usado só pelos comandos de QA: faz o tempo do preso quase acabar.
function NestSystem.QAHurry(seconds: number)
    for _, captive in pairs(captives) do
        captive.deadline = os.clock() + seconds
    end
end

function NestSystem.Init()
    setupSlotPrompts()

    KidnapSystem.PlayerCaptive:Connect(function(player: Player, slot: BasePart)
        captives[player] = { slot = slot, deadline = os.clock() + Config.CaptiveTimeLimit }
        setPrompt(slot, true, player.Name)
        -- Quem está no lobby ouve o rugido abafado do Ninho
        AudioBroadcast.PlayToLobby("Rumble")
    end)

    PlayerState.Changed:Connect(function(player: Player, location: string)
        if location ~= Location.Captive then
            removeCaptive(player)
        end
    end)

    Players.PlayerRemoving:Connect(function(player)
        removeCaptive(player)
        holding[player] = nil
        shown[player] = nil
        lastBang[player] = nil
    end)

    -- Bater nas grades guia o grupo, mas também atrai o Guardião
    CaptiveBang.OnServerEvent:Connect(function(player)
        if PlayerState.Get(player) ~= Location.Captive then
            return
        end
        local now = os.clock()
        if lastBang[player] and now - lastBang[player] < Config.CaptiveBangCooldown then
            return
        end
        lastBang[player] = now
        NoiseSystem.AddPulse(player, Config.CaptivePulse, 2)
        local captive = captives[player]
        if captive then
            AudioBroadcast.Play("Bang", captive.slot.Position)
        end
    end)

    task.spawn(function()
        while true do
            task.wait(1)
            for player, captive in pairs(captives) do
                if os.clock() >= captive.deadline then
                    print("[Nest] Tempo esgotado: " .. player.Name .. " perdeu a mochila e voltou ao lobby.")
                    removeCaptive(player)
                    ExpeditionSystem.ReturnToLobby(player, false)
                end
            end
            broadcast()
        end
    end)
end

return NestSystem
