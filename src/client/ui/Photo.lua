--!strict
-- X0: modo foto, só para o QA no Studio. Esconde toda a interface, solta a câmera e mostra um ponto por vez
-- (surface: Config.PhotoSpots; caverna: chegada, um núcleo de cada zona e o Ninho). Tecla N avança, P sai.
-- Só mexe na câmera do cliente: o personagem não sai do lugar. "Foto + luz" acende uma luz de estúdio na câmera.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)

local player = Players.LocalPlayer

local Photo = {}

type Spot = { name: string, position: Vector3, target: Vector3? }

local active = false
local spots: { Spot } = {}
local index = 0
local hiddenGuis: { [ScreenGui]: boolean } = {}
local keyConnection: RBXScriptConnection? = nil
local lightPart: Part? = nil
local savedCameraType: Enum.CameraType = Enum.CameraType.Custom

local function rayParams(): RaycastParams
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local ignore: { Instance } = {}
    if player.Character then
        table.insert(ignore, player.Character)
    end
    if lightPart then
        table.insert(ignore, lightPart)
    end
    local guardian = workspace:FindFirstChild("Guardian")
    if guardian then
        table.insert(ignore, guardian)
    end
    params.FilterDescendantsInstances = ignore
    return params
end

local function groundAt(x: number, z: number): number
    local result = workspace:Raycast(Vector3.new(x, 400, z), Vector3.new(0, -800, 0), rayParams())
    return if result then result.Position.Y else 0
end

-- Direção com mais espaço livre ao redor de um ponto (para fotografar o corredor, não a parede)
local function freestDirection(eye: Vector3): Vector3
    local best = Vector3.new(0, 0, -1)
    local bestDistance = -1
    local params = rayParams()
    for step = 0, 15 do
        local angle = step / 16 * math.pi * 2
        local direction = Vector3.new(math.sin(angle), 0, -math.cos(angle))
        local result = workspace:Raycast(eye, direction * 150, params)
        local distance = if result then (result.Position - eye).Magnitude else 150
        if distance > bestDistance then
            bestDistance = distance
            best = direction
        end
    end
    return best
end

local function caveSpots(): { Spot }
    local list: { Spot } = {}
    local arrival = workspace:FindFirstChild("CaveArrival")
    if arrival and arrival:IsA("BasePart") then
        table.insert(list, { name = "Caverna: chegada e elevador", position = arrival.Position + Vector3.new(0, 4, 0) })
    end
    local seen: { [string]: boolean } = {}
    for _, child in ipairs(workspace:GetDescendants()) do
        if child:IsA("BasePart") and child:GetAttribute("IsCore") == true then
            local zone = child:GetAttribute("DepthZone")
            if typeof(zone) == "string" and not seen[zone] then
                seen[zone] = true
                table.insert(list, { name = "Caverna: zona " .. zone .. " (corredor)", position = child.Position + Vector3.new(0, 4, 0) })
            end
        end
    end
    table.sort(list, function(a, b)
        return a.name < b.name
    end)
    local nest = workspace:FindFirstChild("NestSlots")
    local slot = nest and nest:FindFirstChild("NestSlot1")
    if slot and slot:IsA("BasePart") then
        table.insert(list, { name = "Caverna: Ninho", position = slot.Position + Vector3.new(0, 5, 0) })
    end
    return list
end

local function surfaceSpots(): { Spot }
    local list: { Spot } = {}
    for _, spot in ipairs(Config.PhotoSpots) do
        local ground = groundAt(spot.x, spot.z)
        table.insert(list, {
            name = spot.name,
            position = Vector3.new(spot.x, ground + spot.eye, spot.z),
            target = Vector3.new(spot.tx, ground + spot.ty, spot.tz),
        })
    end
    return list
end

local function show(position: number)
    local spot = spots[position]
    local camera = workspace.CurrentCamera
    if not spot or not camera then
        return
    end
    local look: Vector3
    local target = spot.target
    if target then
        look = target
    else
        look = spot.position + freestDirection(spot.position) * 40
    end
    camera.CameraType = Enum.CameraType.Scriptable
    camera.CFrame = CFrame.lookAt(spot.position, look)
    local carrier = lightPart
    if carrier then
        carrier.Position = spot.position
    end
    print(string.format("[Foto] %d/%d %s", position, #spots, spot.name))
end

function Photo.Stop()
    if not active then
        return
    end
    active = false
    local connection = keyConnection
    if connection then
        connection:Disconnect()
        keyConnection = nil
    end
    for gui in pairs(hiddenGuis) do
        gui.Enabled = true
    end
    table.clear(hiddenGuis)
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
    end)
    local carrier = lightPart
    if carrier then
        carrier:Destroy()
        lightPart = nil
    end
    local camera = workspace.CurrentCamera
    if camera then
        camera.CameraType = savedCameraType
    end
    print("[Foto] fim")
end

function Photo.Start(withLight: boolean)
    if active then
        Photo.Stop()
        return
    end
    active = true
    local camera = workspace.CurrentCamera
    if camera then
        savedCameraType = camera.CameraType
    end
    for _, gui in ipairs((player:WaitForChild("PlayerGui")):GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled then
            hiddenGuis[gui] = true
            gui.Enabled = false
        end
    end
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
    end)
    if withLight then
        local carrier = Instance.new("Part")
        carrier.Name = "LuzDeEstudio"
        carrier.Anchored = true
        carrier.CanCollide = false
        carrier.CanQuery = false
        carrier.Transparency = 1
        carrier.Size = Vector3.new(1, 1, 1)
        carrier.Parent = workspace
        local light = Instance.new("PointLight")
        light.Range = 60
        light.Brightness = 2.5
        light.Color = Color3.fromRGB(255, 240, 220)
        light.Shadows = false
        light.Parent = carrier
        lightPart = carrier
    end
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local inCave = root ~= nil and root:IsA("BasePart") and root.Position.X > Config.WorldBounds.MaxX
    spots = if inCave then caveSpots() else surfaceSpots()
    index = 1
    print(string.format("[Foto] %d pontos (%s). N = próximo, P = sair", #spots, if inCave then "caverna" else "superfície"))
    show(index)
    keyConnection = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then
            return
        end
        if input.KeyCode == Enum.KeyCode.N then
            index = index % math.max(#spots, 1) + 1
            show(index)
        elseif input.KeyCode == Enum.KeyCode.P then
            Photo.Stop()
        end
    end)
end

return Photo
