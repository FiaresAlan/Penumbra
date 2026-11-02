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
}

return Config