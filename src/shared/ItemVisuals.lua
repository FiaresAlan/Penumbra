--!strict
-- F2: o visual de cada item. Os modelos 3D (pacote "Treasure Pack", CC0) ficam em ReplicatedStorage.EcosItems; aqui se escolhe o
-- modelo conforme o tipo (Core, DenseCore, Relic) e a raridade, e se aplica cor, material e tamanho. Usado no mundo (ItemSpin,
-- cliente) e nas telas (ItemViewport). Sem o modelo, devolve nil e quem chama usa o visual simples de antes.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemVisuals = {}

type Style = { color: Color3, material: Enum.Material, transparency: number, reflectance: number, size: number }

local RARITY_COLORS: { [string]: Color3 } = {
    Common = Color3.fromRGB(110, 175, 255),
    Uncommon = Color3.fromRGB(110, 230, 160),
    Rare = Color3.fromRGB(176, 112, 255),
    Epic = Color3.fromRGB(255, 130, 200),
    Legendary = Color3.fromRGB(255, 196, 80),
}

local CORE_MODELS: { [string]: { string } } = {
    Common = { "gem-6", "gem-4-long", "gem-8" },
    Uncommon = { "gem-6", "gem-8" },
    Rare = { "gem-5-cut", "gem-heart", "gem-tear" },
    Epic = { "gem-heart", "gem-tear" },
    Legendary = { "gem-tear", "gem-heart", "gem-5-cut" },
}
local DENSE_MODELS = { "gem-5-cut" }
local RELIC_MODELS = { "ruin-fire", "ruin-water", "ruin-earth", "ruin-wind" }

local RELIC_COLORS: { [string]: Color3 } = {
    ["ruin-fire"] = Color3.fromRGB(255, 112, 62),
    ["ruin-water"] = Color3.fromRGB(78, 156, 255),
    ["ruin-earth"] = Color3.fromRGB(138, 178, 92),
    ["ruin-wind"] = Color3.fromRGB(206, 232, 255),
}

local function folder(): Instance?
    return ReplicatedStorage:FindFirstChild("EcosItems")
end

-- Nome do modelo para o item. `seed` (um número) varia entre itens do mesmo tipo e raridade.
function ItemVisuals.ModelFor(itemType: string, rarity: string, seed: number): string
    if itemType == "Relic" then
        return RELIC_MODELS[(seed % #RELIC_MODELS) + 1]
    elseif itemType == "DenseCore" then
        return DENSE_MODELS[1]
    end
    local list = CORE_MODELS[rarity] or CORE_MODELS.Common
    return list[(seed % #list) + 1]
end

local function styleFor(modelName: string, itemType: string, rarity: string): Style
    if itemType == "Relic" then
        return { color = RELIC_COLORS[modelName] or Color3.fromRGB(255, 120, 210), material = Enum.Material.Marble, transparency = 0, reflectance = 0.15, size = 4 }
    elseif itemType == "DenseCore" then
        return { color = Color3.fromRGB(150, 80, 230), material = Enum.Material.Glass, transparency = 0.1, reflectance = 0.25, size = 3.6 }
    end
    return { color = RARITY_COLORS[rarity] or RARITY_COLORS.Common, material = Enum.Material.Glass, transparency = 0.12, reflectance = 0.25, size = 2.6 }
end

-- Cria o visual (uma MeshPart nova, pronta para pôr em um Workspace ou ViewportFrame). Maior lado = o tamanho do estilo (studs).
function ItemVisuals.Create(itemType: string, rarity: string, seed: number): MeshPart?
    local items = folder()
    if not items then
        return nil
    end
    local modelName = ItemVisuals.ModelFor(itemType, rarity, seed)
    local model = items:FindFirstChild(modelName)
    local source = model and model:FindFirstChildWhichIsA("MeshPart", true)
    if not source then
        return nil
    end
    local style = styleFor(modelName, itemType, rarity)
    local part = source:Clone()
    part.Name = "ItemVisual"
    local largest = math.max(part.Size.X, part.Size.Z, 0.1)
    part.Size = part.Size * (style.size / largest)
    part.Color = style.color
    part.Material = style.material
    part.Transparency = style.transparency
    part.Reflectance = style.reflectance
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Massless = true
    return part
end

-- Inclinação base: os modelos do pacote nascem deitados; de pé mostram melhor a silhueta
ItemVisuals.StandUp = CFrame.Angles(math.rad(90), 0, 0)

return ItemVisuals
