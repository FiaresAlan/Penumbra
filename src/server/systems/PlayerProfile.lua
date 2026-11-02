--!strict
-- Único módulo que toca DataStore. O resto do jogo lê e escreve só o perfil em memória.
-- Segue as regras de segurança de dados: UpdateAsync, trava de sessão (JobId), retry com espera,
-- autosave escalonado, salvamento ao sair e no BindToClose, e nunca joga com perfil vazio por falha de leitura.
-- No Studio, sem lugar publicado, o DataStore não responde: o perfil fica só em memória (com aviso).
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local ProfileUpdate = ReplicatedStorage:WaitForChild("EcosRemotes"):WaitForChild("ProfileUpdate") :: RemoteEvent

export type StashItem = { id: string, type: string, rarity: string, value: number }
export type Profile = {
    version: number,
    money: number,
    stash: { StashItem },
    upgrades: { [string]: boolean },
    relicDisplay: { StashItem },
    contracts: { [string]: any },
    discovered: { [string]: boolean }, -- lugares já visitados (ex.: village), liberam a carroça
}

local PlayerProfile = {}

local updatedEvent = Instance.new("BindableEvent")
PlayerProfile.Updated = updatedEvent.Event

local STORE_NAME = "EcosProfiles_v1"
local CURRENT_VERSION = 1
local AUTOSAVE_SECONDS = 60
local LOCK_STALE_SECONDS = 150

local isStudio = RunService:IsStudio()
local ATTEMPTS = if isStudio then 1 else 4

local store: DataStore? = nil
local profiles: { [Player]: Profile } = {}
local memoryOnly: { [Player]: boolean } = {}
local saving: { [number]: boolean } = {} -- UserId com salvamento de saída ainda em andamento

local function defaultProfile(): Profile
    return {
        version = CURRENT_VERSION,
        money = 0,
        stash = {},
        upgrades = {},
        relicDisplay = {},
        contracts = {},
        discovered = {},
    }
end

-- Migrações por versão. Nenhuma ainda; novas entram aqui como MIGRATIONS[versaoAntiga] = function(dados) ... end
local MIGRATIONS: { [number]: (any) -> any } = {}

local function migrate(data: any): any
    data.version = data.version or 1
    while data.version < CURRENT_VERSION do
        local step = MIGRATIONS[data.version]
        if not step then
            error("migração ausente a partir da versão " .. tostring(data.version))
        end
        data = step(data)
        data.version += 1
    end
    -- Garante campos que versões antigas não tinham
    data.money = data.money or 0
    data.stash = data.stash or {}
    data.upgrades = data.upgrades or {}
    data.relicDisplay = data.relicDisplay or {}
    data.contracts = data.contracts or {}
    data.discovered = data.discovered or {} -- perfis antigos não tinham
    return data
end

local function deepCopy(value: any): any
    if type(value) ~= "table" then
        return value
    end
    local copy = {}
    for key, inner in pairs(value) do
        copy[key] = deepCopy(inner)
    end
    return copy
end

local function keyFor(player: Player): string
    return "Player_" .. player.UserId
end

-- Chama fn até `attempts` vezes, esperando 1s, 2s, 4s... entre as tentativas.
local function withRetry(attempts: number, fn: () -> any): (boolean, any)
    local wait = 1
    for attempt = 1, attempts do
        local ok, result = pcall(fn)
        if ok then
            return true, result
        end
        warn(string.format("[Profile] tentativa %d/%d falhou: %s", attempt, attempts, tostring(result)))
        if attempt < attempts then
            task.wait(wait)
            wait = math.min(wait * 2, 8)
        end
    end
    return false, nil
end

-- Lê o perfil e assume a trava de sessão no mesmo UpdateAsync.
-- Devolve (perfil, travadoEmOutroServidor).
local function loadProfile(player: Player): (Profile?, boolean)
    local activeStore = store
    if not activeStore then
        return nil, false
    end

    local lockedElsewhere = false
    local ok, result = withRetry(ATTEMPTS, function()
        return activeStore:UpdateAsync(keyFor(player), function(old: any)
            lockedElsewhere = false
            local data = old or defaultProfile()
            local lock = data.lock
            if lock and lock.jobId ~= game.JobId and os.time() - lock.time < LOCK_STALE_SECONDS then
                lockedElsewhere = true
                return nil -- outro servidor ainda é o dono: não escreve nada
            end
            data.lock = { jobId = game.JobId, time = os.time() }
            return migrate(data)
        end)
    end)

    if ok and result then
        return result :: Profile, false
    end
    return nil, lockedElsewhere
end

local function saveProfile(player: Player, release: boolean)
    local profile = profiles[player]
    local activeStore = store
    if not profile or not activeStore or memoryOnly[player] then
        return
    end

    withRetry(ATTEMPTS, function()
        return activeStore:UpdateAsync(keyFor(player), function(old: any)
            if old and old.lock and old.lock.jobId ~= game.JobId and os.time() - old.lock.time < LOCK_STALE_SECONDS then
                return nil -- outro servidor assumiu a trava: não sobrescreve
            end
            local data = deepCopy(profile)
            if release then
                data.lock = nil
            else
                data.lock = { jobId = game.JobId, time = os.time() }
            end
            return data
        end)
    end)
end

local function sendUpdate(player: Player, notice: string?)
    local profile = profiles[player]
    if not profile then
        return
    end
    ProfileUpdate:FireClient(player, {
        money = profile.money,
        stash = profile.stash,
        upgrades = profile.upgrades,
        relicDisplay = profile.relicDisplay,
        contracts = profile.contracts,
        notice = notice,
    })
    updatedEvent:Fire(player)
end

-- API ------------------------------------------------------------------------

function PlayerProfile.Get(player: Player): Profile?
    return profiles[player]
end

local function isWholeNumber(value: unknown): boolean
    return typeof(value) == "number" and value == value and value >= 0 and value == math.floor(value) and value < 1e12
end

-- Reenvia o perfil ao dono depois de uma mudança feita direto em Get(player) (ex.: contratos).
function PlayerProfile.Refresh(player: Player)
    sendUpdate(player)
end

function PlayerProfile.AddMoney(player: Player, amount: number): boolean
    local profile = profiles[player]
    if not profile or not isWholeNumber(amount) then
        return false
    end
    profile.money += amount
    sendUpdate(player)
    return true
end

function PlayerProfile.SpendMoney(player: Player, amount: number): boolean
    local profile = profiles[player]
    if not profile or not isWholeNumber(amount) or profile.money < amount then
        return false
    end
    profile.money -= amount
    sendUpdate(player)
    return true
end

-- `items` vêm do recibo de extração: { type, rarity, value }. Os ids são gerados aqui, no servidor.
-- Nunca recusa: se o baú passar do limite o jogador é avisado para vender, mas nada se perde.
function PlayerProfile.AddStashItems(player: Player, items: { any })
    local profile = profiles[player]
    if not profile then
        warn("[Profile] perfil de " .. player.Name .. " ainda não carregou; itens não guardados!")
        return
    end
    for _, item in ipairs(items) do
        table.insert(profile.stash, {
            id = HttpService:GenerateGUID(false),
            type = item.type,
            rarity = item.rarity,
            value = item.value,
        })
    end
    -- Teto duro: o que passar vira moedas na hora, para o perfil nunca crescer até o limite do DataStore
    while #profile.stash > Config.StashHardLimit do
        -- Vende o item de menor valor; Relíquias nunca são vendidas automaticamente
        local lowest = 0
        for index, item in ipairs(profile.stash) do
            if item.type ~= "Relic" and (lowest == 0 or item.value < profile.stash[lowest].value) then
                lowest = index
            end
        end
        if lowest == 0 then
            break
        end
        local removed = table.remove(profile.stash, lowest)
        profile.money += math.floor(removed.value * Config.LobbyMarketRate)
    end
    local notice = if #profile.stash > Config.StashMaxItems then "Baú cheio: venda itens antes da próxima descida" else nil
    sendUpdate(player, notice)
end

function PlayerProfile.RemoveStashItem(player: Player, itemId: string): StashItem?
    local profile = profiles[player]
    if not profile then
        return nil
    end
    for index, item in ipairs(profile.stash) do
        if item.id == itemId then
            table.remove(profile.stash, index)
            sendUpdate(player)
            return item
        end
    end
    return nil
end

-- Relíquia exposta sai do baú (não pode ser vendida) e fica em relicDisplay. `maxCount` é o número de suportes.
function PlayerProfile.MoveToDisplay(player: Player, itemId: string, maxCount: number): boolean
    local profile = profiles[player]
    if not profile or #profile.relicDisplay >= maxCount then
        return false
    end
    for index, item in ipairs(profile.stash) do
        if item.id == itemId then
            if item.type ~= "Relic" then
                return false
            end
            table.remove(profile.stash, index)
            table.insert(profile.relicDisplay, item)
            sendUpdate(player)
            return true
        end
    end
    return false
end

function PlayerProfile.MoveFromDisplay(player: Player, itemId: string): boolean
    local profile = profiles[player]
    if not profile then
        return false
    end
    for index, item in ipairs(profile.relicDisplay) do
        if item.id == itemId then
            table.remove(profile.relicDisplay, index)
            table.insert(profile.stash, item)
            sendUpdate(player)
            return true
        end
    end
    return false
end

function PlayerProfile.HasUpgrade(player: Player, upgradeId: string): boolean
    local profile = profiles[player]
    return profile ~= nil and profile.upgrades[upgradeId] == true
end

function PlayerProfile.SetUpgrade(player: Player, upgradeId: string)
    local profile = profiles[player]
    if profile then
        profile.upgrades[upgradeId] = true
        sendUpdate(player)
    end
end

function PlayerProfile.HasDiscovered(player: Player, place: string): boolean
    local profile = profiles[player]
    return profile ~= nil and profile.discovered[place] == true
end

function PlayerProfile.SetDiscovered(player: Player, place: string, discovered: boolean)
    local profile = profiles[player]
    if profile then
        profile.discovered[place] = if discovered then true else nil
    end
end

-- Mostra um aviso curto ao dono do perfil (o cliente já exibe `notice`).
function PlayerProfile.Notify(player: Player, text: string)
    sendUpdate(player, text)
end

-- Usado só pelos comandos de QA do Studio.
function PlayerProfile.QAReset(player: Player)
    if profiles[player] then
        profiles[player] = defaultProfile()
        sendUpdate(player)
    end
end

-- Ciclo de vida -------------------------------------------------------------------

local function onPlayerAdded(player: Player)
    task.spawn(function()
        local profile: Profile? = nil
        local locked = false
        -- Se a mesma pessoa acabou de sair, espera o salvamento dela terminar antes de ler (evita dados velhos)
        local waited = 0
        while saving[player.UserId] and waited < 30 do
            task.wait(0.5)
            waited += 0.5
        end
        for _ = 1, 3 do
            profile, locked = loadProfile(player)
            if profile or not locked then
                break
            end
            task.wait(5) -- o outro servidor pode estar terminando de salvar
        end

        if not profile then
            if isStudio then
                warn("[Profile] DataStore indisponível no Studio (lugar não publicado ou API desligada): perfil só em memória.")
                memoryOnly[player] = true
                profile = defaultProfile()
            else
                -- Nunca deixar jogar com perfil vazio: o próximo salvamento apagaria os dados reais
                player:Kick(if locked
                    then "Seus dados ainda estão sendo salvos em outro servidor. Entre de novo em instantes."
                    else "Não foi possível carregar seus dados. Entre de novo em instantes.")
                return
            end
        end

        if player.Parent ~= Players then
            -- Saiu durante o carregamento: a trava já foi tomada, então precisa ser liberada
            local activeStore = store
            if activeStore and not memoryOnly[player] then
                pcall(function()
                    activeStore:UpdateAsync(keyFor(player), function(old: any)
                        if old and old.lock and old.lock.jobId == game.JobId then
                            old.lock = nil
                            return old
                        end
                        return nil
                    end)
                end)
            end
            return
        end
        profiles[player] = profile :: Profile
        sendUpdate(player)

        -- Autosave escalonado pelo UserId, para os jogadores não salvarem todos no mesmo instante
        task.wait(player.UserId % AUTOSAVE_SECONDS)
        while profiles[player] do
            saveProfile(player, false)
            task.wait(AUTOSAVE_SECONDS)
        end
    end)
end

local function onPlayerRemoving(player: Player)
    local userId = player.UserId
    saving[userId] = true
    task.spawn(function()
        saveProfile(player, true)
        profiles[player] = nil
        memoryOnly[player] = nil
        saving[userId] = nil
    end)
end

function PlayerProfile.Init()
    local ok, result = pcall(function()
        return DataStoreService:GetDataStore(STORE_NAME)
    end)
    if ok then
        store = result
    else
        warn("[Profile] GetDataStore falhou: " .. tostring(result))
    end

    for _, player in ipairs(Players:GetPlayers()) do
        onPlayerAdded(player)
    end
    Players.PlayerAdded:Connect(onPlayerAdded)
    Players.PlayerRemoving:Connect(onPlayerRemoving)

    game:BindToClose(function()
        if isStudio then
            return
        end
        local pending = 0
        for _, player in ipairs(Players:GetPlayers()) do
            pending += 1
            task.spawn(function()
                saveProfile(player, true)
                pending -= 1
            end)
        end
        local deadline = os.clock() + 25
        while pending > 0 and os.clock() < deadline do
            task.wait(0.2)
        end
    end)
end

return PlayerProfile
