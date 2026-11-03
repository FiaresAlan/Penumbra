--!strict
-- Nome e ícone dos itens (Núcleo e Relíquia), em um lugar só para todas as telas.
local ItemInfo = {}

local ADJECTIVE: { [string]: string } = { Common = "", Rare = " raro", Legendary = " lendário" }

function ItemInfo.Name(itemType: string, rarity: string): string
    if itemType == "Relic" then
        return "Relíquia"
    elseif itemType == "DenseCore" then
        return "Núcleo denso"
    end
    return "Núcleo" .. (ADJECTIVE[rarity] or "")
end

function ItemInfo.Emoji(itemType: string): string
    return if itemType == "Relic" then "🏺" elseif itemType == "DenseCore" then "🔷" else "💎"
end

return ItemInfo
