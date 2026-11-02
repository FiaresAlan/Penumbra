--!strict
-- Auditoria de caminhos (só QA): confere se o Guardião, com o tamanho dele, chega do ponto de chegada da caverna
-- até cada núcleo, Relíquia, vaga do Ninho e o elevador. Núcleos em saliências do gancho são pulados.
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)

local PathAudit = {}

local running = false

type Target = { name: string, position: Vector3, hook: boolean }

-- Leva o ponto até o chão logo abaixo, para núcleos que flutuam acima dele
local function onFloor(position: Vector3): Vector3
    local hit = workspace:Raycast(position, Vector3.new(0, -30, 0))
    if hit then
        return hit.Position + Vector3.new(0, 3, 0)
    end
    return position
end

local function collectTargets(): { Target }
    local targets: { Target } = {}
    local map = workspace:FindFirstChild("Map")
    if map then
        for _, descendant in ipairs(map:GetDescendants()) do
            if descendant:IsA("BasePart") and descendant:GetAttribute("IsCore") then
                table.insert(targets, {
                    name = descendant.Name,
                    position = descendant.Position,
                    hook = string.sub(descendant.Name, 1, 9) == "LedgeCore",
                })
            end
        end
    end
    local slots = workspace:FindFirstChild("NestSlots")
    if slots then
        for _, slot in ipairs(slots:GetChildren()) do
            if slot:IsA("BasePart") then
                table.insert(targets, { name = slot.Name, position = slot.Position, hook = false })
            end
        end
    end
    local elevator = workspace:FindFirstChild("Elevator")
    if elevator and elevator:IsA("BasePart") then
        -- O elevador é maciço: o alvo é o lado de onde o jogador chega
        table.insert(targets, { name = "Elevator", position = elevator.Position + Vector3.new(-9, 0, 0), hook = false })
    end
    table.sort(targets, function(a, b)
        return a.name < b.name
    end)
    return targets
end

function PathAudit.Run()
    if running then
        return
    end
    local arrival = workspace:FindFirstChild("CaveArrival")
    if not arrival or not arrival:IsA("BasePart") then
        warn("[Audit] CaveArrival não encontrado: o mapa já foi gerado?")
        return
    end
    running = true
    task.spawn(function()
        local start = onFloor(arrival.Position)
        local ok, failed, hooks = 0, 0, 0
        local targets = collectTargets()
        for _, target in ipairs(targets) do
            if target.hook then
                hooks += 1
                print(string.format("[Audit] gancho  %s (só pelo gancho)", target.name))
            else
                -- O núcleo é uma esfera maciça e ocupa o próprio ponto do mapa de navegação:
                -- vale chegar ao ponto ou a um dos pontos a 5 studs de distância.
                local reached = false
                local lastStatus = "?"
                for _, offset in ipairs({ Vector3.zero, Vector3.new(5, 0, 0), Vector3.new(-5, 0, 0), Vector3.new(0, 0, 5), Vector3.new(0, 0, -5) }) do
                    local path = PathfindingService:CreatePath({
                        AgentRadius = Config.GuardianAgentRadius,
                        AgentHeight = Config.GuardianAgentHeight,
                        AgentCanJump = false,
                        WaypointSpacing = 6,
                    })
                    local computed, err = pcall(function()
                        path:ComputeAsync(start, onFloor(target.position + offset))
                    end)
                    lastStatus = if computed then tostring(path.Status) else tostring(err)
                    if computed and path.Status == Enum.PathStatus.Success then
                        reached = true
                        break
                    end
                end
                if reached then
                    ok += 1
                    print(string.format("[Audit] OK      %s", target.name))
                else
                    failed += 1
                    warn(string.format("[Audit] FALHOU  %s (%s)", target.name, lastStatus))
                end
            end
            task.wait()
        end
        print(string.format("[Audit] total %d: %d ok, %d falharam, %d só pelo gancho", #targets, ok, failed, hooks))
        running = false
    end)
end

return PathAudit
