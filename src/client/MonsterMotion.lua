--!strict
-- F1: movimento do corpo do monstro. As poses do Guardião são peças rígidas; aqui o cliente mexe no Weld de cada peça
-- (pivô nos pés) para dar vida: respiração parado, balanço e inclinação ao andar, passada pesada ao caçar.
-- Só aparência neste cliente; o servidor nunca lê isso.
local RunService = game:GetService("RunService")

local MonsterMotion = {}

type Entry = { weld: Weld, base: CFrame }

local entries: { [Weld]: Entry } = {}
local phase = 0

local function collect(guardian: Instance)
    local folder = guardian:FindFirstChild("Poses")
    if not folder then
        return
    end
    for _, descendant in ipairs(folder:GetDescendants()) do
        if descendant:IsA("Weld") and descendant.Name == "Corpo" and not entries[descendant] then
            entries[descendant] = { weld = descendant, base = descendant.C0 }
        end
    end
end

function MonsterMotion.Init()
    RunService.RenderStepped:Connect(function(dt: number)
        local guardian = workspace:FindFirstChild("Guardian")
        local root = guardian and guardian:FindFirstChild("HumanoidRootPart")
        if not guardian or not root or not root:IsA("BasePart") then
            return
        end
        collect(guardian)
        local velocity = root.AssemblyLinearVelocity
        local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
        local moving = math.clamp(speed / 10, 0, 1)
        local rushing = math.clamp((speed - 8) / 12, 0, 1)
        -- a passada acelera com a velocidade; parado, só respira devagar
        phase += dt * (1.4 + speed * 0.55)
        local now = os.clock()
        local step = math.sin(phase)
        local bob = math.abs(step) * 0.4 * moving + math.sin(now * 1.5) * 0.05 * (1 - moving)
        local roll = step * 0.09 * moving + math.sin(now * 0.8) * 0.02 * (1 - moving)
        local pitch = -(0.1 * moving + 0.22 * rushing) + math.sin(now * 1.5) * 0.015
        local feetY = guardian:GetAttribute("FeetY")
        local pivot = CFrame.new(0, if typeof(feetY) == "number" then feetY else 0, 0)
        local motion = pivot * CFrame.new(0, bob, 0) * CFrame.Angles(pitch, 0, roll) * pivot:Inverse()
        for weld, entry in pairs(entries) do
            if not weld.Parent then
                entries[weld] = nil
            else
                weld.C0 = motion * entry.base
            end
        end
    end)
end

return MonsterMotion
