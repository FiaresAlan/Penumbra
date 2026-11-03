--!strict
local Config = {}

-- Movimento
Config.SprintSpeed = 20

-- Ruído
Config.BaseNoise = 0
Config.RunNoiseMultiplier = 1.0
Config.WeightNoiseMultiplier = 0.5
Config.MaxCarryWeight = 10
Config.SlotWeight = 2 -- cada 2 de peso é 1 espaço na tela da mochila (só apresentação)
Config.VoiceSpikeDecay = 2.0
Config.VoiceSpikeAmount = 5.0

-- Núcleos
Config.CoreWeight = 2
Config.CoreValue = {
    Common = 10,
    Rare = 50,
    Legendary = 200,
}

-- Guardião
Config.GuardianWalkSpeed = 10
Config.GuardianChaseSpeed = 14
Config.GuardianAlertDelay = 1.5
Config.GuardianLostScentTime = 3.0
Config.GuardianInvestigateTime = 5.0
Config.GuardianHearThreshold = 0.5
Config.GuardianRestTime = 10
Config.GuardianCatchRadius = 6
Config.GuardianMoveInterval = 0.25
Config.GuardianRepathInterval = 0.5
Config.GuardianAgentRadius = 3
Config.GuardianAgentHeight = 9

-- Extração
Config.ElevatorArrivalTime = 20
Config.ElevatorCloseTime = 30
Config.ElevatorCooldown = 15

-- Expedição
Config.DescentCountdown = 10
Config.LobbyElevatorRadius = 15
Config.ExpeditionMaxTime = 900
Config.ExpeditionResetDelay = 5
Config.TeleportHeight = 3
Config.StreamTimeout = 5

-- Movimento
Config.NormalWalkSpeed = 16
Config.SneakSpeed = 8
Config.MovementMaxSpeed = 60
Config.SurfaceRunSpeed = 26 -- Shift na superfície (só em Lobby); na caverna não muda nada

-- Viagem de carroça entre a mina e a vila
Config.CartCooldown = 10
Config.CartPromptRadius = 14
Config.DescentCountdownFar = 30 -- contagem quando alguém do lobby está longe do elevador

-- Enganador
Config.DeceiverCoreInterval = 8
Config.DeceiverMaxFakeCores = 3
Config.DeceiverCoreLifetime = 20
Config.DeceiverMinDistance = 8
Config.DeceiverMaxDistance = 20
Config.DeceiverWallInterval = 20
Config.DeceiverWallLifetime = 5

-- Corista
Config.MimicTriggerIntensity = 5
Config.MimicCooldown = 12
Config.MimicMinDistance = 15
Config.MimicMaxDistance = 30

-- Contratos. kind: items, relic, late (extrair depois do minuto LateMinute) ou rescue
Config.LateMinute = 8
Config.ContractDefs = {
    extract5 = { text = "Extraia 5 itens", kind = "items", goal = 5, reward = 60 },
    extract8 = { text = "Extraia 8 itens", kind = "items", goal = 8, reward = 110 },
    relic1 = { text = "Extraia 1 Relíquia", kind = "relic", goal = 1, reward = 150 },
    late = { text = "Extraia depois do minuto 8", kind = "late", goal = 1, reward = 120 },
    rescue = { text = "Resgate um preso", kind = "rescue", goal = 1, reward = 100 },
    weekly20 = { text = "Semana: extraia 20 itens", kind = "items", goal = 20, reward = 350 },
    weeklyRelic3 = { text = "Semana: extraia 3 Relíquias", kind = "relic", goal = 3, reward = 500 },
}
Config.DailyPool = { "extract5", "extract8", "relic1", "late", "rescue" }
Config.WeeklyPool = { "weekly20", "weeklyRelic3" }

-- Mercado Negro e Mural
Config.BlackMarketRotation = 600
Config.HighlightsRefresh = 300

-- Baú, mercado e oficina
Config.StashMaxItems = 40
Config.StashHardLimit = 150
Config.LobbyMarketRate = 0.8
Config.MarketRadius = 20
Config.ElevatorBoardRadius = 15 -- distância para estar "dentro" do elevador da caverna
Config.ElevatorPromptRadius = 20 -- distância máxima para chamar o elevador
Config.RescueRadius = 12
Config.BootsMoveMultiplier = 0.6
Config.HookRange = 40
Config.HookCooldown = 10
Config.HookNoise = 1.2
Config.HookPullTime = 0.5
Config.Upgrades = {
    Boots = { name = "Botas Silenciosas", price = 500 },
    Hook = { name = "Gancho", price = 1500 },
}

-- Pity
Config.PityFailureThreshold = 2
Config.PityGuardianSpeedMultiplier = 0.9

-- Sequestro e Ninho
Config.DragMaxTime = 8
Config.CaptiveTimeLimit = 120
Config.RescueHoldTime = 5
Config.RescueNoise = 1.5
Config.CaptiveBangCooldown = 3
Config.CaptivePulse = 1.0

-- Itens e profundidade
Config.ItemWeights = { Core = 2, Relic = 6 }
Config.RelicValue = 500
Config.DepthBonus = { A = 1.0, B = 1.15, C = 1.3 }

-- Voz (limite em RmsLevel, 0 a 1; ajuste olhando os logs [Voice] com VoiceDebug ligado)
Config.VoiceRmsThreshold = 0.15
Config.VoiceSustainTime = 0.5
Config.VoiceDebug = true

-- Agressividade do Guardião por tempo de expedição (segundos)
Config.GuardianTiers = {
    { name = "Slow", from = 0, speed = 0.8, hear = 0.7 },
    { name = "Normal", from = 180, speed = 1.0, hear = 0.5 },
    { name = "Fury", from = 480, speed = 1.2, hear = 0.2 },
}
Config.FuryZoneNoise = 1.0
Config.ValueMaxMinute = 10

-- Sons de mundo. Valores provisórios do próprio Studio; troque pelos IDs da Creator Store.
-- Os IDs rbxassetid vêm da biblioteca de sons gratuita do Creator Store (lista em tools/assets/toolbox_sounds.json).
-- Para trocar um som, basta mudar o ID aqui.
Config.Audio = {
    Rumble = "rbxasset://sounds/impact_explosion_03.mp3",
    Bang = "rbxassetid://9125819208", -- batida de metal nas grades
    RockDrop = "rbxassetid://102757491685632", -- entulho caindo
    Laugh = "rbxassetid://17836221379", -- risada do núcleo falso
    MimicVoice = "rbxassetid://128699976960071", -- sussurro do Corista
    Growl = "rbxassetid://9114630281", -- rosnado ao começar a caçada
    Drip = "rbxassetid://9126190492", -- gota d'água na caverna
    Footstep = "rbxassetid://113663232024295", -- passo pesado do Guardião
    Chime = "rbxassetid://91728968749666", -- sino do elevador
    Heartbeat = "rbxassetid://71395510617597", -- batimento quando o Guardião está perto
    CaveAmbience = "rbxassetid://273398061",
    CaveDrone = "rbxassetid://9114353261",
    CaveWind = "rbxassetid://9113286969",
    LobbyBirds = "rbxassetid://9114892930",
    ForestInsects = "rbxassetid://9114894498",
}
-- Volume de cada som de evento (0 a 1) e variação de velocidade aleatória
Config.AudioVolume = {
    Bang = 0.9, RockDrop = 0.9, Laugh = 0.8, MimicVoice = 0.9, Growl = 1, Drip = 0.7, Footstep = 1, Chime = 0.7, Rumble = 1,
}
Config.AudioSpeed = {
    MimicVoice = { 0.85, 0.95 },
    Drip = { 0.9, 1.15 },
    Footstep = { 0.92, 1.05 },
}
-- Camadas de ambiente em loop: a zona define qual toca. volume é o máximo da camada.
Config.AmbientLayers = {
    { asset = "LobbyBirds", zone = "lobby", volume = 0.3 },
    { asset = "ForestInsects", zone = "forest", volume = 0.45 },
    { asset = "CaveAmbience", zone = "cave", volume = 0.4 },
    { asset = "CaveDrone", zone = "cave", volume = 0.28 },
    { asset = "CaveWind", zone = "cave", volume = 0.15 },
}

-- Mapa gerado por src/server/world/MapBuilder.lua
Config.MapSeed = 1337
-- Mundo da superfície (R4): o terreno é gerado uma vez por WorldBake.BakeWorld e salvo no lugar.
-- Mude WorldVersion quando mudar qualquer valor abaixo: o jogo avisa se o lugar foi gerado com outra versão.
Config.WorldVersion = 1
Config.WorldSeed = 4242
Config.WorldFloorY = 1 -- altura das áreas planas, a mesma do piso antigo do lobby
Config.WorldBounds = { MinX = -1400, MaxX = 380, MinZ = -600, MaxZ = 600, MinY = -20, MaxY = 180 }
-- Áreas planas: Mina (elevador, mural, pedidos), Vila (lojas) e Mercado Negro (escondido a oeste)
Config.WorldPads = {
    Mina = { x = 0, z = 0, r = 110 },
    Vila = { x = -640, z = 0, r = 100 },
    MercadoNegro = { x = -1120, z = 60, r = 45 },
}
-- Trilhas de terra: pontos {x, z}. A primeira liga a mina à vila; a segunda, mais estreita, leva ao Mercado Negro.
Config.WorldTrails = {
    { width = 9, points = { { -60, 12 }, { -150, 48 }, { -250, -20 }, { -330, -60 }, { -420, -40 }, { -500, 40 }, { -570, 28 }, { -620, 0 } } },
    { width = 4.5, points = { { -700, 0 }, { -770, -55 }, { -860, -35 }, { -940, 60 }, { -1020, 35 }, { -1090, 70 }, { -1112, 62 } } },
}
-- Riacho raso de norte a sul: dá para atravessar andando (água com 1,5 stud)
Config.WorldStream = { x = -300, amp = 45, period = 90, halfWidth = 8, bank = 14, bedY = -1.5, waterY = 0 }
Config.WorldMountains = { edge = 230, height = 150 }

-- X onde a caverna passa da zona A para a B e da B para a C (ORIGIN_X 420 + colunas 10 e 19 de 16 studs)
Config.ZoneBoundaryB = 580
Config.ZoneBoundaryC = 724

-- QA (botões do painel; só existem no Studio)
Config.QAButtons = {
    { id = "EndFailure", label = "Encerrar: falha" },
    { id = "EndSuccess", label = "Encerrar: sucesso" },
    { id = "DescendNow", label = "Descer agora" },
    { id = "GiveCore", label = "Dar núcleo" },
    { id = "GoToCaveElevator", label = "Ir ao elevador" },
    { id = "CallCaveElevator", label = "Chamar elevador" },
    { id = "GuardianNear", label = "Guardião perto" },
    { id = "GiveRelic", label = "Dar relíquia" },
    { id = "ForceKidnap", label = "Forçar sequestro" },
    { id = "HurryCaptive", label = "Acelerar preso" },
    { id = "ReleaseCaptive", label = "Soltar preso" },
    { id = "Minute3", label = "Minuto 3" },
    { id = "Minute8", label = "Minuto 8" },
    { id = "NextBlind", label = "Próximo: Cego" },
    { id = "NextMimic", label = "Próximo: Corista" },
    { id = "NextDeceiver", label = "Próximo: Enganador" },
    { id = "TouchFake", label = "Tocar falso" },
    { id = "GiveMoney", label = "Dar 100 moedas" },
    { id = "ResetProfile", label = "Resetar perfil" },
    { id = "FillStash", label = "Encher baú" },
    { id = "OpenMarket", label = "Ir ao mercado" },
    { id = "OpenWorkshop", label = "Ir à oficina" },
    { id = "GiveHook", label = "Dar gancho" },
    { id = "NearHook", label = "Perto do gancho" },
    { id = "NextDay", label = "Virar o dia" },
    { id = "OpenContracts", label = "Ir aos contratos" },
    { id = "GiveItemsQA", label = "Simular extração" },
    { id = "RotateOrders", label = "Girar pedidos" },
    { id = "OpenBlackMarket", label = "Ir ao mercado negro" },
    { id = "NextProp", label = "Ir a um prop" },
    { id = "RefreshWall", label = "Atualizar mural" },
    { id = "GoToWall", label = "Ir ao mural" },
    { id = "AuditPaths", label = "Auditar caminhos" },
    { id = "GoToVillage", label = "Ir à vila" },
    { id = "GoToCart", label = "Ir à carroça" },
    { id = "ForgetVillage", label = "Esquecer a vila" },
    { id = "CallGroup", label = "Chamar o grupo" },
    { id = "UISample", label = "Amostra de UI" },
}

return Config