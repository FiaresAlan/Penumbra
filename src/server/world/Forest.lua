--!strict
-- Floresta a oeste do lobby e a barraca do Mercado Negro.

local Util = require(script.Parent:WaitForChild("WorldUtil") :: ModuleScript)

local newPart = Util.newPart
local addLight = Util.addLight

local function buildForest(rng: Random)
    local mapFolder = Util.MapFolder :: Folder
    newPart("ForestGround", Vector3.new(140, 1, 130), CFrame.new(-140, 0.5, 0), { Material = Enum.Material.Grass, Color = Color3.fromRGB(52, 92, 50) }, mapFolder)

    for _ = 1, 38 do
        local x = -75 - rng:NextNumber() * 130
        local z = (rng:NextNumber() - 0.5) * 120
        -- Deixa a clareira do mercado livre
        if (Vector3.new(x, 0, z) - Vector3.new(-135, 0, 0)).Magnitude > 22 then
            local height = 14 + rng:NextNumber() * 10
            newPart("TreeTrunk", Vector3.new(2.4, height, 2.4), CFrame.new(x, 1 + height / 2, z), { Material = Enum.Material.Wood, Color = Color3.fromRGB(86, 62, 40) }, mapFolder)
            newPart("TreeLeaves", Vector3.new(12, 10, 12), CFrame.new(x, 1 + height + 3, z), { Material = Enum.Material.Grass, Color = Color3.fromRGB(34, 78, 38), Shape = Enum.PartType.Ball }, mapFolder)
        end
    end

    -- Barraca do Mercado Negro
    local stall = newPart("BlackMarketStall", Vector3.new(12, 3, 5), CFrame.new(-135, 2.5, 0), { Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(70, 48, 40) }, workspace)
    stall:SetAttribute("Generated", true)
    newPart("StallRoof", Vector3.new(15, 1, 9), CFrame.new(-135, 10, 0), { Material = Enum.Material.Fabric, Color = Color3.fromRGB(40, 30, 50) }, mapFolder)
    for _, dx in ipairs({ -6, 6 }) do
        newPart("StallPole", Vector3.new(1, 9, 1), CFrame.new(-135 + dx, 5.5, -3), { Material = Enum.Material.Wood, Color = Color3.fromRGB(60, 44, 32) }, mapFolder)
    end
    local lantern = newPart("StallLantern", Vector3.new(1.5, 1.5, 1.5), CFrame.new(-135, 8.5, 2), { Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 150, 70), CanCollide = false }, mapFolder)
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
