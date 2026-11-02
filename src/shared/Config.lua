local Config = {}

-- Movimento
Config.SprintSpeed = 20

-- Ruído
Config.BaseNoise = 0
Config.RunNoiseMultiplier = 1.0
Config.WeightNoiseMultiplier = 0.5
Config.MaxCarryWeight = 10
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

-- Baú, mercado e oficina
Config.StashMaxItems = 40
Config.LobbyMarketRate = 0.8
Config.MarketRadius = 20
Config.BootsPrice = 500
Config.BootsMoveMultiplier = 0.6
Config.HookPrice = 1500
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
Config.Audio = {
    Rumble = "rbxasset://sounds/impact_explosion_03.mp3",
    Bang = "rbxasset://sounds/impact_water.mp3",
    RockDrop = "rbxasset://sounds/impact_water.mp3",
    Laugh = "rbxasset://sounds/action_get_up.mp3",
    MimicVoice = "rbxasset://sounds/ouch.ogg",
}
Config.AudioSpeed = {
    MimicVoice = { 0.85, 0.95 },
}

-- Mapa gerado por src/server/world/MapBuilder.lua
Config.MapSeed = 1337

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
}

return Config