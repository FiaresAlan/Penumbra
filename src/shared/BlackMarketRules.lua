--!strict
-- Regras puras do Mercado Negro: geração de pedidos e escolha dos itens a entregar. Sem serviços do Roblox.
local BlackMarketRules = {}

export type Order = {
    id: string,
    label: string,
    itemType: string,
    rarity: string?,
    quantity: number,
    priceRate: number,
}

type StashItem = { id: string, type: string, rarity: string, value: number }

-- Modelos de pedido. `rng` é injetado para o resultado ser repetível em testes.
local TEMPLATES = {
    { label = "Núcleos", itemType = "Core", rarity = nil, min = 3, max = 6 },
    { label = "Núcleos raros", itemType = "Core", rarity = "Rare", min = 1, max = 3 },
    { label = "Relíquia", itemType = "Relic", rarity = nil, min = 1, max = 1 },
}

function BlackMarketRules.Generate(rng: Random, count: number): { Order }
    local orders: { Order } = {}
    for index = 1, count do
        local template = TEMPLATES[((index - 1) % #TEMPLATES) + 1]
        local quantity = rng:NextInteger(template.min, template.max)
        -- Preço entre 100% e 150%, em passos de 5%
        local rate = 1 + rng:NextInteger(0, 10) * 0.05
        table.insert(orders, {
            id = string.format("order%d_%d", index, rng:NextInteger(1000, 9999)),
            label = template.label,
            itemType = template.itemType,
            rarity = template.rarity,
            quantity = quantity,
            priceRate = rate,
        })
    end
    return orders
end

local function matches(order: Order, item: StashItem): boolean
    if item.type ~= order.itemType then
        return false
    end
    return order.rarity == nil or item.rarity == order.rarity
end

-- Escolhe os itens de MENOR valor que servem ao pedido (guarda os melhores para o jogador).
-- Devolve nil se não houver itens suficientes.
function BlackMarketRules.PickItems(order: Order, stash: { StashItem }): { StashItem }?
    local candidates: { StashItem } = {}
    for _, item in ipairs(stash) do
        if matches(order, item) then
            table.insert(candidates, item)
        end
    end
    if #candidates < order.quantity then
        return nil
    end
    table.sort(candidates, function(a, b)
        return a.value < b.value
    end)
    local picked: { StashItem } = {}
    for index = 1, order.quantity do
        table.insert(picked, candidates[index])
    end
    return picked
end

function BlackMarketRules.Payout(order: Order, items: { StashItem }): number
    local sum = 0
    for _, item in ipairs(items) do
        sum += item.value
    end
    return math.floor(sum * order.priceRate)
end

return BlackMarketRules
