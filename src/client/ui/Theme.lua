--!strict
-- Linguagem visual única das telas: aventura vibrante (índigo profundo com ciano, magenta, laranja, lima e dourado).
-- Nenhuma tela define cor, fonte ou tamanho por conta própria: tudo vem daqui.
local Theme = {}

Theme.Color = {
    Overlay = Color3.fromRGB(8, 4, 28),
    PanelBg = Color3.fromRGB(34, 24, 78),
    PanelDark = Color3.fromRGB(22, 14, 54),
    Wood = Color3.fromRGB(70, 48, 140),
    WoodLight = Color3.fromRGB(104, 76, 196),
    Amber = Color3.fromRGB(255, 176, 40),
    Gold = Color3.fromRGB(255, 226, 72),
    Tile = Color3.fromRGB(255, 96, 120),
    TileDark = Color3.fromRGB(196, 52, 104),
    Parchment = Color3.fromRGB(255, 246, 220),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(196, 186, 240),
    TextDark = Color3.fromRGB(28, 18, 62),
    Danger = Color3.fromRGB(255, 64, 100),
    Success = Color3.fromRGB(64, 228, 150),
    Line = Color3.fromRGB(136, 106, 236),
    Cyan = Color3.fromRGB(64, 222, 255),
    Lime = Color3.fromRGB(150, 236, 70),
    Magenta = Color3.fromRGB(255, 80, 220),
    Orange = Color3.fromRGB(255, 132, 48),
}

-- Cada botão lateral do lobby tem a sua cor (base, realce)
Theme.Accent = {
    bag = { Color3.fromRGB(230, 110, 30), Color3.fromRGB(255, 160, 70) },
    contracts = { Color3.fromRGB(30, 170, 200), Color3.fromRGB(80, 225, 255) },
    workshop = { Color3.fromRGB(120, 90, 230), Color3.fromRGB(170, 140, 255) },
    market = { Color3.fromRGB(40, 190, 110), Color3.fromRGB(100, 240, 160) },
    profile = { Color3.fromRGB(230, 60, 140), Color3.fromRGB(255, 120, 190) },
    board = { Color3.fromRGB(230, 180, 20), Color3.fromRGB(255, 225, 90) },
    settings = { Color3.fromRGB(70, 130, 230), Color3.fromRGB(130, 180, 255) },
    daily = { Color3.fromRGB(220, 50, 70), Color3.fromRGB(255, 110, 120) },
}

Theme.RarityColor = {
    Common = Color3.fromRGB(120, 200, 255),
    Rare = Color3.fromRGB(196, 110, 255),
    Legendary = Color3.fromRGB(255, 204, 40),
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
