--!strict
-- T1: primeira descida guiada. Uma galeria curta e separada, feita de peças no alto do mundo, onde o novato pega um núcleo,
-- sente o chão tremer, foge de uma sombra roteirizada seguindo o bipe do elevador e volta ao lobby com um núcleo comum no baú.
-- Não toca na expedição do servidor: o jogador continua "no lobby" para o resto do jogo (ruído, Guardião e extração reais nem
-- o enxergam). Só vale para perfis novos (sem moedas, itens nem melhorias) que ainda não fizeram nem pularam; o prêmio sai uma
-- única vez e nunca se repete. "Pular" funciona a qualquer momento e também marca como feito.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local systems = script.Parent :: Instance
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local Enums = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums") :: ModuleScript)
local MovementGuard = require(systems:WaitForChild("MovementGuard") :: ModuleScript)
local PlayerProfile = require(systems:WaitForChild("PlayerProfile") :: ModuleScript)
local PlayerState = require(systems:WaitForChild("PlayerState") :: ModuleScript)
local RateLimiter = require(systems:WaitForChild("RateLimiter") :: ModuleScript)

local TutorialSystem = {}

local Remotes = ReplicatedStorage:WaitForChild("EcosRemotes")
local StartRemote = Remotes:WaitForChild("TutorialStart") :: RemoteEvent
local SkipRemote = Remotes:WaitForChild("TutorialSkip") :: RemoteEvent
local HintRemote = Remotes:WaitForChild("TutorialHint") :: RemoteEvent

-- A galeria fica acima de tudo (Y 400), no meio da vila, para ninguém tocar nela
local ORIGIN = Vector3.new(-640, 400, 0)
local LENGTH = 100
local WIDTH = 14
local HEIGHT = 12
local CORE_X = 55
local EXIT_X = 95

type Run = { stage: string, caught: boolean, shade: Model?, beep: Sound?, core: Part?, token: number }

local runs: { [Player]: Run } = {}
local gallery: Model? = nil
local tokenCounter = 0

local function part(name: string, size: Vector3, position: Vector3, material: Enum.Material, color: Color3, parent: Instance): Part
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.Position = position
    p.Material = material
    p.Color = color
    p.Anchored = true
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

local function hint(player: Player, text: string, seconds: number?)
    HintRemote:FireClient(player, text, seconds or 8)
end

local function build(): Model
    local existing = gallery
    if existing then
        return existing
    end
    local model = Instance.new("Model")
    model.Name = "GaleriaDoTutorial"
    local rock = Color3.fromRGB(58, 56, 66)
    part("Piso", Vector3.new(LENGTH + 10, 2, WIDTH), ORIGIN + Vector3.new(LENGTH / 2, -1, 0), Enum.Material.Slate, rock, model)
    part("Teto", Vector3.new(LENGTH + 10, 2, WIDTH), ORIGIN + Vector3.new(LENGTH / 2, HEIGHT + 1, 0), Enum.Material.Slate, rock, model)
    for _, side in ipairs({ -1, 1 }) do
        part("Parede", Vector3.new(LENGTH + 10, HEIGHT + 4, 2), ORIGIN + Vector3.new(LENGTH / 2, HEIGHT / 2, side * (WIDTH / 2 + 1)), Enum.Material.Basalt, Color3.fromRGB(46, 44, 54), model)
    end
    part("ParedeFundo", Vector3.new(2, HEIGHT + 4, WIDTH + 4), ORIGIN + Vector3.new(LENGTH + 4, HEIGHT / 2, 0), Enum.Material.Basalt, Color3.fromRGB(46, 44, 54), model)
    part("ParedeInicio", Vector3.new(2, HEIGHT + 4, WIDTH + 4), ORIGIN + Vector3.new(-6, HEIGHT / 2, 0), Enum.Material.Basalt, Color3.fromRGB(46, 44, 54), model)
    -- cristais fracos de luz ao longo do caminho
    for index = 1, 8 do
        local crystal = part("Cristal", Vector3.new(1, 2.4, 1), ORIGIN + Vector3.new(index * 12, 1.2, if index % 2 == 0 then 5.5 else -5.5), Enum.Material.Neon,
            if index % 2 == 0 then Color3.fromRGB(80, 200, 255) else Color3.fromRGB(170, 110, 255), model)
        crystal.CanCollide = false
        local light = Instance.new("PointLight")
        light.Color = crystal.Color
        light.Range = 16
        light.Brightness = 0.9
        light.Parent = crystal
    end
    -- pedestal do núcleo
    part("Pedestal", Vector3.new(3, 2, 3), ORIGIN + Vector3.new(CORE_X, 1, 0), Enum.Material.Cobblestone, Color3.fromRGB(110, 104, 96), model)
    -- elevador de saída (marca visual no fundo)
    local exit = part("Saida", Vector3.new(6, 9, 10), ORIGIN + Vector3.new(EXIT_X, 4.5, 0), Enum.Material.WoodPlanks, Color3.fromRGB(112, 78, 50), model)
    exit.CanCollide = false
    local exitLight = Instance.new("PointLight")
    exitLight.Color = Color3.fromRGB(255, 190, 110)
    exitLight.Range = 26
    exitLight.Brightness = 1.4
    exitLight.Parent = exit
    local gate = Instance.new("Part")
    gate.Name = "SaidaSensor"
    gate.Size = Vector3.new(8, 9, 12)
    gate.Position = ORIGIN + Vector3.new(EXIT_X - 3, 4.5, 0)
    gate.Anchored = true
    gate.CanCollide = false
    gate.Transparency = 1
    gate.Parent = model
    model.Parent = workspace
    gallery = model
    return model
end

local function lobbyPoint(): Vector3
    local elevator = workspace:FindFirstChild("LobbyElevator")
    if elevator and elevator:IsA("BasePart") then
        return elevator.Position + Vector3.new(-14, 4, 0)
    end
    return Vector3.new(30, Config.WorldFloorY + 4, 0)
end

local function endRun(player: Player, reward: boolean)
    local run = runs[player]
    if not run then
        return
    end
    runs[player] = nil
    player:SetAttribute("InTutorial", nil)
    if run.shade then
        run.shade:Destroy()
    end
    if run.beep then
        run.beep:Destroy()
    end
    if run.core then
        run.core:Destroy()
    end
    local character = player.Character
    if character then
        MovementGuard.Exempt(player, 5)
        character:PivotTo(CFrame.new(lobbyPoint()))
    end
    if reward then
        PlayerProfile.AddStashItems(player, { { type = "Core", rarity = "Common", value = Config.TutorialCoreValue } })
        PlayerProfile.Notify(player, "Você sobreviveu! Um núcleo foi para o seu baú")
    end
    PlayerProfile.SetOnboarded(player)
    hint(player, if reward then "Você sobreviveu à primeira descida. O mercado paga bem por núcleos." else "Tudo bem. O mercado fica ao lado do elevador.", 7)
end

local function spawnShade(player: Player, run: Run)
    local model = Instance.new("Model")
    model.Name = "SombraDoTutorial"
    local body = part("Corpo", Vector3.new(3, 9, 2), ORIGIN + Vector3.new(CORE_X - 38, 5.5, 0), Enum.Material.Neon, Color3.fromRGB(14, 10, 18), model)
    body.CanCollide = false
    body.Transparency = 0.1
    local eyes = part("Olhos", Vector3.new(0.4, 0.5, 1.6), body.Position + Vector3.new(0, 2.8, 0), Enum.Material.Neon, Color3.fromRGB(210, 40, 30), model)
    eyes.CanCollide = false
    local glow = Instance.new("PointLight")
    glow.Color = Color3.fromRGB(200, 40, 30)
    glow.Range = 14
    glow.Brightness = 1
    glow.Parent = eyes
    model.PrimaryPart = body
    model.Parent = gallery
    run.shade = model
    task.spawn(function()
        while runs[player] == run and run.shade == model do
            local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if root and root:IsA("BasePart") then
                local dx = root.Position.X - body.Position.X
                local step = math.min(Config.TutorialShadeSpeed / 20, math.max(dx, 0))
                body.Position += Vector3.new(step, 0, 0)
                eyes.Position = body.Position + Vector3.new(0, 2.8, 0)
                if dx < 6 and not run.caught then
                    run.caught = true
                    hint(player, "O Guardião te ouviu. Da próxima vez, ande devagar com Ctrl.", 6)
                    task.delay(2.5, function()
                        if runs[player] == run then
                            endRun(player, true)
                        end
                    end)
                    return
                end
            end
            task.wait(0.05)
        end
    end)
end

local function flicker(): boolean
    return math.random() < 0.5
end

local function startRun(player: Player)
    tokenCounter += 1
    local run: Run = { stage = "walk", caught = false, shade = nil, beep = nil, core = nil, token = tokenCounter }
    runs[player] = run
    player:SetAttribute("InTutorial", true)
    local model = build()
    local character = player.Character
    if character then
        MovementGuard.Exempt(player, 5)
        character:PivotTo(CFrame.new(ORIGIN + Vector3.new(2, 4, 0)))
    end
    hint(player, "Ande até o brilho no fim do corredor", 10)
    -- se o jogador reaparecer (caiu, resetou), a primeira descida guiada termina sem prêmio e volta a poder ser feita
    player.CharacterAdded:Once(function()
        if runs[player] == run then
            runs[player] = nil
            player:SetAttribute("InTutorial", nil)
            if run.shade then
                run.shade:Destroy()
            end
            if run.beep then
                run.beep:Destroy()
            end
            if run.core then
                run.core:Destroy()
            end
        end
    end)

    local core = Instance.new("Part")
    core.Name = "NucleoDoTutorial"
    core.Shape = Enum.PartType.Ball
    core.Size = Vector3.new(2, 2, 2)
    core.Material = Enum.Material.Neon
    core.Color = Color3.fromRGB(250, 250, 255)
    core.Anchored = true
    core.CanCollide = false
    core.Position = ORIGIN + Vector3.new(CORE_X, 3.6, 0)
    core.Parent = model
    run.core = core
    local pick = Instance.new("ProximityPrompt")
    pick.ActionText = "Pegar"
    pick.ObjectText = "Núcleo"
    pick.HoldDuration = 0
    pick.MaxActivationDistance = 10
    pick.RequiresLineOfSight = false
    pick.Parent = core
    pick.Triggered:Connect(function(who: Player)
        if who ~= player or runs[player] ~= run or run.stage ~= "walk" then
            return
        end
        run.stage = "flee"
        core:Destroy()
        run.core = nil
        hint(player, "Ele pesa e faz barulho! O chão treme... corra para o elevador, siga o bipe", 9)
        -- o chão treme: a galeria inteira balança um instante
        task.spawn(function()
            for _ = 1, 12 do
                for _, descendant in ipairs(model:GetDescendants()) do
                    if descendant:IsA("PointLight") then
                        descendant.Brightness = if flicker() then 0.1 else 0.9
                    end
                end
                task.wait(0.12)
            end
        end)
        local beep = Instance.new("Sound")
        beep.SoundId = Config.Audio.Chime
        beep.Looped = true
        beep.Volume = 1
        beep.RollOffMaxDistance = 140
        beep.Parent = model:FindFirstChild("Saida")
        beep:Play()
        run.beep = beep
        spawnShade(player, run)
    end)

    -- chegada ao elevador
    local sensor = model:FindFirstChild("SaidaSensor") :: BasePart
    local watcher: RBXScriptConnection? = nil
    watcher = RunService.Heartbeat:Connect(function()
        if runs[player] ~= run then
            if watcher then
                watcher:Disconnect()
            end
            return
        end
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if run.stage == "flee" and root and root:IsA("BasePart") and (root.Position - sensor.Position).Magnitude < 8 then
            if watcher then
                watcher:Disconnect()
            end
            endRun(player, true)
        end
    end)
end

local function eligible(player: Player): boolean
    local profile = PlayerProfile.Get(player)
    if not profile or profile.onboarded or runs[player] then
        return false
    end
    if PlayerState.Get(player) ~= Enums.PlayerLocation.Lobby then
        return false
    end
    return profile.money == 0 and #profile.stash == 0 and next(profile.upgrades) == nil and profile.xp == 0
end

function TutorialSystem.Init()
    StartRemote.OnServerEvent:Connect(function(player: Player)
        if not RateLimiter.Allow(player, "TutorialStart", 1, 2) then
            return
        end
        if eligible(player) then
            startRun(player)
        else
            -- perfil que já joga: marca como conhecido, para nunca mais oferecer
            local profile = PlayerProfile.Get(player)
            if profile and not profile.onboarded and not runs[player] then
                PlayerProfile.SetOnboarded(player)
            end
        end
    end)
    SkipRemote.OnServerEvent:Connect(function(player: Player)
        if not RateLimiter.Allow(player, "TutorialSkip", 1, 2) then
            return
        end
        if runs[player] then
            endRun(player, false)
        else
            PlayerProfile.SetOnboarded(player)
        end
    end)
    Players.PlayerRemoving:Connect(function(player: Player)
        runs[player] = nil
    end)
end

return TutorialSystem
