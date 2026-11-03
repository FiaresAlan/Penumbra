--!strict
-- Linguagem visual única das telas: medieval quente (madeira, âmbar, dourado, vermelho telha, pergaminho).
-- Nenhuma tela define cor, fonte ou tamanho por conta própria: tudo vem daqui.
local Theme = {}

Theme.Color = {
    Overlay = Color3.fromRGB(8, 5, 4),
    PanelBg = Color3.fromRGB(38, 28, 22),
    PanelDark = Color3.fromRGB(26, 19, 15),
    Wood = Color3.fromRGB(86, 58, 38),
    WoodLight = Color3.fromRGB(122, 84, 54),
    Amber = Color3.fromRGB(232, 168, 64),
    Gold = Color3.fromRGB(246, 206, 96),
    Tile = Color3.fromRGB(176, 72, 48),
    TileDark = Color3.fromRGB(128, 48, 32),
    Parchment = Color3.fromRGB(236, 222, 192),
    Text = Color3.fromRGB(244, 236, 220),
    TextDim = Color3.fromRGB(176, 164, 146),
    TextDark = Color3.fromRGB(40, 28, 20),
    Danger = Color3.fromRGB(196, 62, 50),
    Success = Color3.fromRGB(98, 168, 92),
    Line = Color3.fromRGB(96, 70, 48),
}

Theme.RarityColor = {
    Common = Color3.fromRGB(168, 168, 172),
    Rare = Color3.fromRGB(84, 156, 236),
    Legendary = Color3.fromRGB(246, 196, 72),
}

Theme.Font = {
    Title = Enum.Font.Fondamento,
    Body = Enum.Font.GothamMedium,
    Strong = Enum.Font.GothamBold,
}

Theme.TextSize = {
    Title = 30,
    Heading = 22,
    Body = 16,
    Small = 13,
}

Theme.CornerRadius = UDim.new(0, 10)
Theme.PanelOrder = 20 -- acima do HUD, abaixo da cortina de transição (100)

-- Cor da borda de uma carta conforme a raridade; qualquer valor desconhecido vira comum
function Theme.ForRarity(rarity: string?): Color3
    if rarity == "Rare" then
        return Theme.RarityColor.Rare
    elseif rarity == "Legendary" then
        return Theme.RarityColor.Legendary
    end
    return Theme.RarityColor.Common
end

return Theme
