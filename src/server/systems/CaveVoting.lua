--!strict
-- V3 (Features.CaveVoting): votação da caverna da próxima descida. Três tablados com banner perto do elevador da mina (um por
-- local); quem fica de pé em cima de um vota nele. Na hora da descida o servidor conta os votos dos jogadores no lobby: o local
-- mais votado vale, empate sorteia, sem votos fica o local atual. Se o vencedor é outro, a caverna é refeita (MapBuilder.RebuildCave)
-- e os sistemas que guardavam referências recebem Rebind, tudo antes de alguém descer. Quem joga sozinho vota por conta própria.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local systems = script.Parent :: Instance
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local Enums = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums") :: ModuleScript)
local FreeSpot = require(systems.Parent:WaitForChild("world"):WaitForChild("FreeSpot") :: ModuleScript)
local MapBuilder = require(systems.Parent:WaitForChild("world"):WaitForChild("MapBuilder") :: ModuleScript)
local ExpeditionSystem = require(systems:WaitForChild("ExpeditionSystem") :: ModuleScript)
local ExtractionSystem = require(systems:WaitForChild("ExtractionSystem") :: ModuleScript)
local GuardianAI = require(systems:WaitForChild("GuardianAI") :: ModuleScript)
local NestSystem = require(systems:WaitForChild("NestSystem") :: ModuleScript)
local PlayerState = require(systems:WaitForChild("PlayerState") :: ModuleScript)

local CaveVoting = {}

type Pad = { site: string, position: Vector3, label: TextLabel }

local rng = Random.new()
local pads: { Pad } = {}
local votes: { [number]: string } = {} -- UserId -> local votado

local function names(): { string }
    local list: { string } = {}
    for name in pairs(Config.CaveSites) do
        table.insert(list, name)
    end
    table.sort(list)
    return list
end

local function part(name: string, size: Vector3, cframe: CFrame, material: Enum.Material, color: Color3, parent: Instance): Part
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cframe
    p.Material = material
    p.Color = color
    p.Anchored = true
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

local function countFor(site: string): number
    local total = 0
    for _, voted in pairs(votes) do
        if voted == site then
            total += 1
        end
    end
    return total
end

local function refreshLabels()
    local current = workspace:GetAttribute("CaveSite")
    for _, pad in ipairs(pads) do
        local info = Config.CaveSiteInfo[pad.site]
        local title = if info then info.title else pad.site
        local mark = if current == pad.site then "\n(local atual)" else ""
        pad.label.Text = string.format("%s\n%d voto(s)%s", title, countFor(pad.site), mark)
    end
end

local function buildPad(site: string, spot: Vector3, parent: Instance): Pad
    local info = Config.CaveSiteInfo[site]
    local color = if info then Color3.fromRGB(info.color[1], info.color[2], info.color[3]) else Color3.fromRGB(200, 200, 200)
    local base = CFrame.lookAt(spot, Vector3.new(Config.WorldPads.Mina.x + 48, spot.Y, Config.WorldPads.Mina.z))
    local disc = part("TabladoVoto", Vector3.new(0.6, 8, 8), base * CFrame.new(0, 0.3, 0) * CFrame.Angles(0, 0, math.pi / 2), Enum.Material.Cobblestone, Color3.fromRGB(96, 90, 84), parent)
    disc.Shape = Enum.PartType.Cylinder
    local ring = part("TabladoAnel", Vector3.new(0.2, 8.6, 8.6), base * CFrame.new(0, 0.55, 0) * CFrame.Angles(0, 0, math.pi / 2), Enum.Material.Neon, color, parent)
    ring.Shape = Enum.PartType.Cylinder
    ring.CanCollide = false
    ring.Transparency = 0.45
    part("BannerPoste", Vector3.new(0.8, 12, 0.8), base * CFrame.new(0, 6, 4.6), Enum.Material.WoodPlanks, Color3.fromRGB(80, 56, 38), parent)
    local board = part("BannerPlaca", Vector3.new(8, 5, 0.5), base * CFrame.new(0, 11, 4.6), Enum.Material.WoodPlanks, Color3.fromRGB(60, 42, 30), parent)
    local gui = Instance.new("SurfaceGui")
    gui.Face = Enum.NormalId.Back
    gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    gui.PixelsPerStud = 40
    gui.Parent = board
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.TextColor3 = color
    label.Font = Enum.Font.Fondamento
    label.TextWrapped = true
    label.TextScaled = true
    label.Text = ""
    label.Parent = gui
    local light = Instance.new("PointLight")
    light.Color = color
    light.Range = 18
    light.Brightness = 1
    light.Parent = ring
    return { site = site, position = spot, label = label }
end

-- Quem está de pé em cima de um tablado vota nele. Sair não tira o voto; pisar em outro troca.
local function scan()
    for _, player in ipairs(Players:GetPlayers()) do
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if root and root:IsA("BasePart") and PlayerState.Get(player) == Enums.PlayerLocation.Lobby then
            for _, pad in ipairs(pads) do
                local flat = Vector3.new(root.Position.X - pad.position.X, 0, root.Position.Z - pad.position.Z).Magnitude
                if flat < 4.2 and math.abs(root.Position.Y - pad.position.Y) < 8 and votes[player.UserId] ~= pad.site then
                    votes[player.UserId] = pad.site
                    print(string.format("[Voto] %s votou em %s", player.Name, pad.site))
                end
            end
        end
    end
    refreshLabels()
end

local function winner(): string?
    local best = 0
    local leaders: { string } = {}
    for _, name in ipairs(names()) do
        local count = countFor(name)
        if count > best then
            best = count
            leaders = { name }
        elseif count == best and count > 0 then
            table.insert(leaders, name)
        end
    end
    if best == 0 then
        return nil
    end
    return leaders[rng:NextInteger(1, #leaders)]
end

-- Antes da descida: conta os votos de quem ainda está no servidor e refaz a caverna se outro local ganhou
local function decide()
    for userId in pairs(votes) do
        if not Players:GetPlayerByUserId(userId) then
            votes[userId] = nil
        end
    end
    local chosen = winner()
    local current = workspace:GetAttribute("CaveSite")
    votes = {}
    refreshLabels()
    if not chosen or chosen == current then
        return
    end
    print(string.format("[Voto] local escolhido: %s (era %s)", chosen, tostring(current)))
    if MapBuilder.RebuildCave(chosen) then
        ExtractionSystem.Rebind()
        GuardianAI.Rebind()
        NestSystem.Rebind()
    end
end

function CaveVoting.Init()
    if not Config.Features.CaveVoting then
        return
    end
    ExpeditionSystem.SetPreLaunchHook(decide)
    task.spawn(function()
        local baked = workspace:WaitForChild("WorldBaked", 30)
        if not baked then
            return
        end
        local folder = Instance.new("Folder")
        folder.Name = "VotoDeCaverna"
        folder.Parent = baked
        local pad = Config.WorldPads.Mina
        local anchors = { Vector3.new(pad.x + 14, 0, pad.z - 36), Vector3.new(pad.x + 14, 0, pad.z), Vector3.new(pad.x + 14, 0, pad.z + 36) }
        for index, site in ipairs(names()) do
            local anchor = anchors[index]
            local spot = if anchor then FreeSpot.Find(anchor, 9, 9, 4, 14, rng) else nil
            if spot then
                table.insert(pads, buildPad(site, spot, folder))
            else
                print("[Voto] sem espaço para o tablado de " .. site)
            end
        end
        refreshLabels()
        print("[Voto] tablados criados: " .. #pads)
        while true do
            task.wait(0.5)
            scan()
        end
    end)
    Players.PlayerRemoving:Connect(function(player: Player)
        votes[player.UserId] = nil
    end)
end

return CaveVoting
