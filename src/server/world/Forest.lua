--!strict
-- Barraca do Mercado Negro, escondida no fim da trilha a oeste. A floresta e o chão são o Terrain do R4 (WorldBake).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local Util = require(script.Parent:WaitForChild("WorldUtil") :: ModuleScript)

local newPart = Util.newPart
local addLight = Util.addLight

local function buildForest(_rng: Random)
    local mapFolder = Util.MapFolder :: Folder
    local BX = Config.WorldPads.MercadoNegro.x
    local BZ = Config.WorldPads.MercadoNegro.z
    -- Barraca do Mercado Negro
    local stall = newPart("BlackMarketStall", Vector3.new(12, 3, 5), CFrame.new(BX, 2.5, BZ), { Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(70, 48, 40) }, workspace)
    stall:SetAttribute("Generated", true)
    newPart("StallRoof", Vector3.new(15, 1, 9), CFrame.new(BX, 10, BZ), { Material = Enum.Material.Fabric, Color = Color3.fromRGB(40, 30, 50) }, mapFolder)
    for _, dx in ipairs({ -6, 6 }) do
        newPart("StallPole", Vector3.new(1, 9, 1), CFrame.new(BX + dx, 5.5, BZ - 3), { Material = Enum.Material.Wood, Color = Color3.fromRGB(60, 44, 32) }, mapFolder)
    end
    local lantern = newPart("StallLantern", Vector3.new(1.5, 1.5, 1.5), CFrame.new(BX, 8.5, BZ + 2), { Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 150, 70), CanCollide = false }, mapFolder)
    addLight(lantern, Color3.fromRGB(255, 150, 70), 30, 1.4)

    -- Quadro de pedidos, junto ao elevador do lobby: o texto é atualizado pelo BlackMarketSystem
    local ordersBoard = workspace:FindFirstChild("OrdersBoard")
    if ordersBoard then
        local gui = Instance.new("SurfaceGui")
        gui.Name = "OrdersGui"
        gui.Face = Enum.NormalId.Left
        gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
        gui.PixelsPerStud = 30
        gui.Parent = ordersBoard
        local label = Instance.new("TextLabel")
        label.Name = "Orders"
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(255, 230, 170)
        label.Font = Enum.Font.GothamBold
        label.TextScaled = true
        label.Text = "PEDIDOS"
        label.Parent = gui
    end
end

return { Build = buildForest }
