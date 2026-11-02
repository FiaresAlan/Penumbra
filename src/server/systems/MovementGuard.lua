--!strict
-- Anti-teleporte e anti-velocidade: o cliente controla o próprio personagem, então o servidor só pode
-- limitar o estrago. Amostra a posição de quem está livre na caverna e, se o deslocamento for impossível,
-- devolve o jogador ao último ponto válido. Movimentos feitos pelo próprio servidor entram como isenção.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local systems = script.Parent :: Instance
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local Enums = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums") :: ModuleScript)
local PlayerState = require(systems:WaitForChild("PlayerState") :: ModuleScript)

local MovementGuard = {}

type Sample = { position: Vector3, time: number }

local samples: { [Player]: Sample } = {}
local exemptUntil: { [Player]: number } = {}

-- Chamado antes de o servidor mover o jogador (teleporte, gancho, QA).
function MovementGuard.Exempt(player: Player, seconds: number)
    exemptUntil[player] = os.clock() + seconds
    samples[player] = nil
end

local function check(player: Player)
    if PlayerState.Get(player) ~= Enums.PlayerLocation.Cave then
        samples[player] = nil
        return
    end
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not character or not root or not root:IsA("BasePart") or root.Anchored then
        samples[player] = nil
        return
    end

    local now = os.clock()
    if (exemptUntil[player] or 0) > now then
        samples[player] = { position = root.Position, time = now }
        return
    end

    local last = samples[player]
    if last then
        local dt = now - last.time
        local delta = root.Position - last.position
        local speed = Vector3.new(delta.X, 0, delta.Z).Magnitude / math.max(dt, 0.05)
        if speed > Config.MovementMaxSpeed then
            warn(string.format("[Guard] %s moveu-se a %.0f studs/s; devolvido ao último ponto válido.", player.Name, speed))
            character:PivotTo(CFrame.new(last.position) * character:GetPivot().Rotation)
            return -- não atualiza a amostra: continua valendo o ponto anterior
        end
    end
    samples[player] = { position = root.Position, time = now }
end

function MovementGuard.Init()
    -- Qualquer troca de local é feita pelo servidor: dá uma folga curta
    PlayerState.Changed:Connect(function(player: Player)
        MovementGuard.Exempt(player, 3)
    end)
    Players.PlayerRemoving:Connect(function(player)
        samples[player] = nil
        exemptUntil[player] = nil
    end)

    task.spawn(function()
        while true do
            task.wait(0.25)
            for _, player in ipairs(Players:GetPlayers()) do
                check(player)
            end
        end
    end)
end

return MovementGuard
