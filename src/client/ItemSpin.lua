--!strict
-- F2: no mundo, cada núcleo e relíquia (peça com o atributo IsCore) ganha no cliente um modelo 3D que gira e flutua no lugar da
-- esfera (a esfera fica invisível só para este jogador, com LocalTransparencyModifier). A peça do servidor continua sendo a
-- fonte de verdade: prompt, luz, posição e atributos. O visual existe só no cliente e some junto com a peça.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ItemVisuals = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ItemVisuals") :: ModuleScript)

local ItemSpin = {}

type Entry = { core: BasePart, visual: MeshPart, phase: number }

local entries: { [BasePart]: Entry } = {}

local function seedOf(core: BasePart): number
    local total = 0
    for index = 1, #core.Name do
        total += string.byte(core.Name, index)
    end
    return total
end

local function build(core: BasePart)
    local existing = entries[core]
    if existing then
        existing.visual:Destroy()
        entries[core] = nil
    end
    local itemType = core:GetAttribute("ItemType")
    local rarity = core:GetAttribute("Rarity")
    local visual = ItemVisuals.Create(if typeof(itemType) == "string" then itemType else "Core", if typeof(rarity) == "string" then rarity else "Common", seedOf(core))
    if not visual then
        return
    end
    visual.Parent = core
    core.LocalTransparencyModifier = 1
    entries[core] = { core = core, visual = visual, phase = (seedOf(core) % 100) / 16 }
end

local function track(core: Instance)
    if not core:IsA("BasePart") or not core:GetAttribute("IsCore") then
        return
    end
    build(core)
    core:GetAttributeChangedSignal("Rarity"):Connect(function()
        build(core)
    end)
    core:GetAttributeChangedSignal("ItemType"):Connect(function()
        build(core)
    end)
end

function ItemSpin.Init()
    for _, descendant in ipairs(workspace:GetDescendants()) do
        track(descendant)
    end
    workspace.DescendantAdded:Connect(function(descendant: Instance)
        -- os atributos podem chegar um instante depois da peça
        task.defer(track, descendant)
    end)
    RunService.RenderStepped:Connect(function()
        local now = os.clock()
        for core, entry in pairs(entries) do
            if not core.Parent or not entry.visual.Parent then
                entries[core] = nil
            else
                local bob = math.sin(now * 2 + entry.phase) * 0.25
                entry.visual.CFrame = CFrame.new(core.Position + Vector3.new(0, 0.2 + bob, 0)) * CFrame.Angles(0, now * 1.1 + entry.phase, 0) * ItemVisuals.StandUp
            end
        end
    end)
end

return ItemSpin
