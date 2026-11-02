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

-- Extração
Config.ElevatorArrivalTime = 20
Config.ElevatorCloseTime = 30

return Config