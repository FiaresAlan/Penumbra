--!strict
-- Qual é o próximo passo útil do jogador na superfície? Só olha o perfil já recebido do servidor; nunca decide nada.
-- Ordem: vender o que está no baú, receber contratos prontos, comprar uma melhoria que dá para pagar, e então descer.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)

local GuideSteps = {}

export type Step = { id: string, partName: string, hint: string }

type Profile = { money: number, stash: { any }, upgrades: { [string]: boolean }, contracts: { [string]: any }? }

local function hasClaimable(profile: Profile): boolean
    local contracts = profile.contracts
    if not contracts then
        return false
    end
    for _, scope in ipairs({ "daily", "weekly" }) do
        local ids = contracts[scope]
        local progress = contracts[scope .. "Progress"]
        local claimed = contracts[scope .. "Claimed"]
        if typeof(ids) == "table" and typeof(progress) == "table" and typeof(claimed) == "table" then
            for _, id in ipairs(ids) do
                local definition = Config.ContractDefs[id]
                if definition and not claimed[id] and (progress[id] or 0) >= definition.goal then
                    return true
                end
            end
        end
    end
    return false
end

local function canAffordUpgrade(profile: Profile): boolean
    for id, definition in pairs(Config.Upgrades) do
        if profile.upgrades[id] ~= true and profile.money >= definition.price then
            return true
        end
    end
    return false
end

function GuideSteps.Compute(profile: Profile?): Step
    if profile then
        if #profile.stash > 0 then
            return { id = "market", partName = "LobbyMarket", hint = "Venda seus itens no Mercado, na vila" }
        end
        if hasClaimable(profile) then
            return { id = "contracts", partName = "LobbyBoard", hint = "Receba seus contratos no Quadro, na vila" }
        end
        if canAffordUpgrade(profile) then
            return { id = "workshop", partName = "LobbyWorkshop", hint = "Compre uma melhoria na Oficina, na vila" }
        end
    end
    return { id = "elevator", partName = "LobbyElevator", hint = "Pressione DESCER para começar a expedição" }
end

return GuideSteps
