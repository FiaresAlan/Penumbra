--!strict
-- Moradores da vila: mercador, ferreiro, capataz, taverneiro, três moradores que andam pela praça e um vulto no Mercado Negro.
-- São só enfeite: os prompts continuam nas bancadas. Cada um solta um balão de fala de vez em quando, e só se há
-- jogador por perto. Criados uma vez no servidor, sem consultar nada externo além do modelo de avatar do Roblox.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)

local NpcSystem = {}

local IDLE_ANIMATION = "rbxassetid://507766388"
local WALK_ANIMATION = "rbxassetid://507777826"
local FLOOR = Config.WorldFloorY

type Npc = {
    model: Model,
    humanoid: Humanoid,
    bubble: TextLabel,
    role: string,
    home: Vector3,
    wander: number, -- raio de passeio (0 = fica parado)
}

local npcs: { Npc } = {}

local TONES = {
    Color3.fromRGB(234, 184, 146), Color3.fromRGB(198, 134, 96), Color3.fromRGB(141, 85, 36), Color3.fromRGB(255, 204, 153),
}

local function description(rng: Random, dark: boolean): HumanoidDescription
    local desc = Instance.new("HumanoidDescription")
    local skin = TONES[rng:NextInteger(1, #TONES)]
    local cloth = if dark then Color3.fromRGB(30, 28, 34) else Color3.fromHSV(rng:NextNumber(0.02, 0.12), rng:NextNumber(0.35, 0.6), rng:NextNumber(0.45, 0.75))
    desc.HeadColor = skin
    desc.LeftArmColor = skin
    desc.RightArmColor = skin
    desc.TorsoColor = cloth
    desc.LeftLegColor = if dark then cloth else Color3.fromRGB(70, 55, 42)
    desc.RightLegColor = desc.LeftLegColor
    return desc
end

local function addBubble(model: Model): TextLabel
    local head = model:FindFirstChild("Head") :: BasePart
    local gui = Instance.new("BillboardGui")
    gui.Name = "Balao"
    gui.Adornee = head
    gui.Size = UDim2.new(0, 210, 0, 54)
    gui.StudsOffset = Vector3.new(0, 3.4, 0)
    gui.MaxDistance = 55
    gui.LightInfluence = 0
    gui.Enabled = false
    gui.Parent = head
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundColor3 = Color3.fromRGB(244, 236, 220)
    label.TextColor3 = Color3.fromRGB(40, 28, 20)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 14
    label.TextWrapped = true
    label.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = label
    return label
end

local function playAnimations(humanoid: Humanoid)
    local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
    local idle = Instance.new("Animation")
    idle.AnimationId = IDLE_ANIMATION
    local walk = Instance.new("Animation")
    walk.AnimationId = WALK_ANIMATION
    local ok, idleTrack, walkTrack = pcall(function()
        return animator:LoadAnimation(idle), animator:LoadAnimation(walk)
    end)
    if not ok then
        return
    end
    idleTrack.Looped = true
    walkTrack.Looped = true
    idleTrack:Play()
    humanoid.Running:Connect(function(speed: number)
        if speed > 0.5 then
            if not walkTrack.IsPlaying then
                walkTrack:Play()
            end
            idleTrack:Stop()
        else
            walkTrack:Stop()
            if not idleTrack.IsPlaying then
                idleTrack:Play()
            end
        end
    end)
end

local say: (Npc, Random) -> ()

local function spawnNpc(name: string, role: string, position: Vector3, facing: number, wander: number, dark: boolean, rng: Random, folder: Folder)
    local ok, model = pcall(function()
        return Players:CreateHumanoidModelFromDescription(description(rng, dark), Enum.HumanoidRigType.R15)
    end)
    if not ok or not model then
        warn("[Npc] não consegui criar " .. name .. ": " .. tostring(model))
        return
    end
    model.Name = name
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root or not root:IsA("BasePart") then
        model:Destroy()
        return
    end
    humanoid.WalkSpeed = 6
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    model:PivotTo(CFrame.new(position) * CFrame.Angles(0, math.rad(facing), 0))
    model.Parent = folder
    root:SetNetworkOwner(nil)
    playAnimations(humanoid)
    local entry: Npc = { model = model, humanoid = humanoid, bubble = addBubble(model), role = role, home = position, wander = wander }
    table.insert(npcs, entry)
    -- V1: conversar com o morador. Só faz o balão de fala aparecer na hora (sem custo, sem efeito de jogo)
    local talk = Instance.new("ProximityPrompt")
    talk.ActionText = "Conversar"
    talk.ObjectText = name
    talk.HoldDuration = 0
    talk.MaxActivationDistance = 8
    talk.RequiresLineOfSight = false
    talk.Parent = root
    talk.Triggered:Connect(function()
        say(entry, rng)
    end)
end

local function nearPlayer(position: Vector3, range: number): boolean
    for _, player in ipairs(Players:GetPlayers()) do
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if root and root:IsA("BasePart") and (root.Position - position).Magnitude <= range then
            return true
        end
    end
    return false
end

say = function(npc: Npc, rng: Random)
    local lines = Config.NpcLines[npc.role]
    if not lines or #lines == 0 then
        return
    end
    npc.bubble.Text = lines[rng:NextInteger(1, #lines)]
    -- P7: com o flag ligado, às vezes o morador conta um boato (sempre marcado, nunca a única pista de nada)
    if Config.Features.VillageRumors and rng:NextNumber() < Config.RumorChance then
        npc.bubble.Text = "Boato: " .. Config.VillageRumors[rng:NextInteger(1, #Config.VillageRumors)]
    end
    local gui = npc.bubble.Parent :: BillboardGui
    gui.Enabled = true
    task.delay(5, function()
        gui.Enabled = false
    end)
end

function NpcSystem.Init()
    local pad = Config.WorldPads.Vila
    local black = Config.WorldPads.MercadoNegro
    local rng = Random.new(Config.MapSeed + 31)
    local folder = Instance.new("Folder")
    folder.Name = "Moradores"
    folder:SetAttribute("Generated", true)
    folder.Parent = workspace

    local y = FLOOR + 3.1
    task.spawn(function()
        spawnNpc("Mercador", "merchant", Vector3.new(pad.x - 30, y, pad.z - 53), 0, 0, false, rng, folder)
        spawnNpc("Ferreiro", "smith", Vector3.new(pad.x - 30, y, pad.z + 53), 180, 0, false, rng, folder)
        spawnNpc("Capataz", "foreman", Vector3.new(pad.x + 22, y, pad.z - 38), 180, 0, false, rng, folder)
        spawnNpc("Taverneiro", "tavern", Vector3.new(pad.x + 22, y, pad.z - 50), 180, 0, false, rng, folder)
        for index = 1, 3 do
            local angle = index / 3 * math.pi * 2
            local home = Vector3.new(pad.x + math.cos(angle) * 14, y, pad.z + math.sin(angle) * 14)
            spawnNpc("Morador" .. index, "villager", home, rng:NextInteger(0, 359), 9, false, rng, folder)
        end
        spawnNpc("Vulto", "hooded", Vector3.new(black.x + 5, y, black.z + 8), 90, 0, true, rng, folder)
        print(string.format("[Npc] %d moradores criados", #npcs))
    end)

    task.spawn(function()
        local lastSpeech: { [Npc]: number } = {}
        while true do
            task.wait(3)
            for _, npc in ipairs(npcs) do
                local root = npc.model:FindFirstChild("HumanoidRootPart")
                if root and root:IsA("BasePart") then
                    local near = nearPlayer(root.Position, 45)
                    if npc.wander > 0 and near and npc.humanoid.MoveDirection.Magnitude < 0.1 then
                        local offset = Vector3.new(rng:NextNumber(-npc.wander, npc.wander), 0, rng:NextNumber(-npc.wander, npc.wander))
                        npc.humanoid:MoveTo(npc.home + offset)
                    end
                    local last = lastSpeech[npc] or 0
                    if near and os.clock() - last > 18 + rng:NextNumber(0, 20) then
                        lastSpeech[npc] = os.clock()
                        say(npc, rng)
                    end
                end
            end
        end
    end)
end

return NpcSystem
