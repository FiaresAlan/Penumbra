--!strict
local Config = {}

-- Movimento
Config.SprintSpeed = 20

-- Ruído
Config.BaseNoise = 0
Config.RunNoiseMultiplier = 1.0
Config.WeightNoiseMultiplier = 0.5
Config.MaxCarryWeight = 10

-- Variação entre partidas. Desligue (false) para o teste com pessoas medir sempre o mesmo mapa.
-- Nível e XP (só mostram progresso: não dão poder). Recompensa diária: 7 dias, nunca zera por faltar um dia.
Config.Xp = { Extraction = 30, PerItem = 8, PerRelic = 40, Rescue = 50, Participation = 10 }
-- P13: a partir de ChainFrom extrações seguidas, cada extração dá XP extra (só XP, nunca moeda). Perder a cadeia não tira nada.
Config.Chain = { From = 3, XpBonus = 20 }
-- P12: marcos da vila. Ao atingir `at` no contador `stat`, o jogador ganha uma frase (só texto, uma vez).
Config.VillageEndings = {
    { stat = "extractions", at = 1, text = "Primeira volta: a vila já sabe seu nome." },
    { stat = "extractions", at = 10, text = "Dez descidas e dez voltas. Dizem que você tem sorte." },
    { stat = "rescues", at = 1, text = "Você trouxe alguém de volta. A taverna brindou à sua saúde." },
    { stat = "relics", at = 1, text = "Uma relíquia sua brilha na vitrine do mercado." },
    { stat = "relics", at = 5, text = "Cinco relíquias: o ferreiro quer ver todas elas." },
}
Config.DailyRewards = { 40, 60, 80, 100, 140, 180, 300 }

-- Falas dos moradores da vila (balões curtos). Algumas comentam a caverna, sem dar pista de onde está o Guardião.
Config.NpcLines = {
    merchant = { "Traga coisas boas da mina que eu pago bem!", "Quem desce com barulho não sobe.", "Núcleo raro vale ouro, viajante." },
    smith = { "Botas silenciosas salvam vidas.", "O gancho aguenta qualquer peso. Quase.", "A relíquia fica linda na vitrine!" },
    foreman = { "Tem contrato novo no quadro.", "Hoje o pessoal voltou calado da mina...", "Quem cumpre o combinado, recebe." },
    tavern = { "Aqui se conta cada história da caverna.", "Ouvi um grito vindo do fundo ontem.", "Sente, descanse. A mina espera." },
    villager = { "Lá embaixo o escuro escuta.", "Ande devagar e volte inteiro.", "Bom dia! Ou boa tarde, sei lá.", "Dizem que tem um ninho no fundo." },
    hooded = { "Psiu... tenho pedidos especiais.", "Aqui nunca esteve ninguém.", "Traga o que pedi e eu pago melhor." },
}

-- Mecânicas novas, todas DESLIGADAS até o Portão 1 (ver docs/PLANO-REFINO.md seção 10B). Ligue uma por vez.
Config.Features = {
    TensionDirector = false, -- P1
    SilenceMoment = false, -- P2 / J13
    DenseCore = false, -- P3 / J14 (testado ligado em 02/11: 2 núcleos densos por descida)
    ShiftingRoute = false, -- P4
    LearningGuardian = false, -- P5
    DescentCondition = false, -- P6
    VillageRumors = true, -- P7 (ligado a pedido do Alan em 03/11: só texto)
    DropItems = false, -- I2
    ThrowItems = false, -- I3
    VisibleBackpack = false, -- I4
    NightVisitor = true, -- P10 (ligado em 03/11; testado: vulto apareceu na zona B; inofensivo)
    ChainBonus = true, -- P13 (ligado em 03/11; testado: cadeia 3 e 4 deram +20 XP; só XP)
    VillageEndings = true, -- P12 (ligado em 03/11; testado: marcos de extração e relíquia; só texto)
}

-- P7: boatos da vila (só com Features.VillageRumors). Alguns são só meio certos de propósito.
Config.RumorChance = 0.4
Config.VillageRumors = {
    "dizem que o Guardião ouve passos de longe, mas quase não ouve quem anda devagar.",
    "ouvi que as relíquias ficam nos salões mais fundos.",
    "um mineiro jurou que o elevador demora mais quando a caverna está furiosa.",
    "falam de paredes que parecem pedra, mas cedem ao toque.",
    "dizem que o núcleo brilhante vale bem mais que os comuns.",
    "alguém contou que o Guardião vira mais bravo com o tempo.",
}

Config.Variation = {
    ShuffleItems = true, -- núcleos e relíquias normais mudam de lugar a cada expedição
}
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
Config.ItemWeights = { Core = 2, Relic = 6, DenseCore = 4 } -- DenseCore só aparece com Config.Features.DenseCore
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
    -- A2: música e ambiente da superfície (Creator Store, DistrokidOfficial e outros; ver docs/CREDITOS.md)
    MineMusic = "rbxassetid://109148793011225", -- "Fading Sunlight"
    VillageMusic = "rbxassetid://74917475529683", -- "A Medieval Village"
    Campfire = "rbxassetid://134379431802298", -- fogo crepitando
    Tavern = "rbxassetid://80388954716054", -- burburinho de taverna, só na vila
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
    { asset = "MineMusic", zone = "mine", volume = 0.35, music = true },
    { asset = "VillageMusic", zone = "village", volume = 0.35, music = true },
    { asset = "Campfire", zone = "lobby", volume = 0.12 },
    { asset = "Tavern", zone = "village", volume = 0.1 },
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
-- X0: pontos de foto da superfície (x, z, alvo tx/tz, altura do olho e do alvo acima do chão). A caverna usa os marcadores.
Config.PhotoSpots = {
    { name = "Pedestal do campeão", x = 22, z = -22, tx = 48, tz = -22, eye = 4, ty = 6 },
    { name = "Vila: sino e quadro de recados", x = -598, z = 0, tx = -624, tz = 0, eye = 4, ty = 6 },
    { name = "Mina: praça e elevador", x = 55, z = 25, tx = 0, tz = 0, eye = 4, ty = 6 },
    { name = "Mina: de perto, no chão", x = 14, z = -6, tx = -2, tz = 6, eye = 2.5, ty = 5 },
    { name = "Trilha para a vila", x = -150, z = 48, tx = -250, tz = -20, eye = 3, ty = 3 },
    { name = "Ruína na floresta", x = -405, z = 175, tx = -420, tz = 210, eye = 4, ty = 5 },
    { name = "Vila: praça", x = -600, z = 30, tx = -640, tz = 0, eye = 4, ty = 5 },
    { name = "Vila: taverna e lojas", x = -600, z = -50, tx = -662, tz = -50, eye = 4, ty = 6 },
    { name = "Floresta funda", x = -860, z = -35, tx = -940, tz = 60, eye = 3, ty = 5 },
    { name = "Mercado Negro", x = -1092, z = 72, tx = -1120, tz = 60, eye = 3, ty = 3 },
}
-- C1: forma da caverna em Terrain. Parede com reentrâncias (no máximo 4 studs, para o corredor de 16 nunca fechar) e relevo do chão.
-- V1: frases do poço e recados do quadro da vila (cosméticos)
Config.VillageWishes = {
    "Que o elevador suba sempre.", "Quero um núcleo azul bem grande.", "Que ninguém fique para trás.",
    "Que o Guardião durma hoje.", "Moedas para a oficina!", "Que a lanterna não apague.",
}
Config.VillageNotices = {
    "Procura-se: alguém que traga uma relíquia inteira.", "O capataz pede silêncio na zona B.",
    "Perdi meu chapéu na mina. Recompensa: um sorriso.", "Dica: andar devagar (Ctrl) acalma a caverna.",
    "A taverna abre quando o sino toca.", "Ninguém desce sozinho no escuro. Chame o grupo.",
}
Config.CaveWarp = 4
-- C3: locais de caverna. Cada um é a mesma grade em outro Z (mesmo X, para as zonas por coluna valerem). O Terrain de todos fica
-- salvo no lugar (um "Gerar caverna" por local); a cada partida só o local ativo recebe núcleos, marcadores e Guardião.
Config.ActiveCaveSite = "Mina"
Config.CavePickMode = "fixed" -- "random" sorteia o local a cada servidor (V3 em versão simples; a votação entre expedições ficou bloqueada)
Config.CaveSites = {
    Mina = { name = "Mina", originZ = -136, seed = Config.MapSeed, theme = "mine" },
    Masmorra = { name = "Masmorra", originZ = 200, seed = 4021, theme = "dungeon", relief = 1.5 },
    Gruta = { name = "Gruta", originZ = -472, seed = 8803, loops = 80, warp = 5, relief = 6, theme = "grotto" },
}
Config.CaveMaxLights = 60
Config.CaveScatterDensity = 1 -- C2: multiplica a chance das peças de zona (0 desliga)
Config.CaveVersion = 2 -- mude ao mudar CaveWarp, CaveFloorRelief ou a grade; e rode "Gerar caverna" (WorldBake.BakeCave)
Config.CaveFloorRelief = 4.5
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
    { id = "CaveStats", label = "Medir caverna" },
    { id = "Photo", label = "Foto" },
    { id = "PhotoLit", label = "Foto + luz" },
    { id = "ShuffleItems", label = "Embaralhar itens" },
    { id = "EndPreview", label = "Tela de fim" },
}

return Config