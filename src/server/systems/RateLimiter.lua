--!strict
-- Limite de pedidos por jogador e por chave (balde de fichas). Todo RemoteEvent de cliente passa por aqui.
local Players = game:GetService("Players")

local RateLimiter = {}

type Bucket = { tokens: number, last: number }

local buckets: { [Player]: { [string]: Bucket } } = {}

function RateLimiter.Allow(player: Player, key: string, ratePerSecond: number, burst: number): boolean
    local now = os.clock()
    local playerBuckets = buckets[player]
    if not playerBuckets then
        playerBuckets = {}
        buckets[player] = playerBuckets
    end
    local bucket = playerBuckets[key]
    if not bucket then
        bucket = { tokens = burst, last = now }
        playerBuckets[key] = bucket
    end
    bucket.tokens = math.min(burst, bucket.tokens + (now - bucket.last) * ratePerSecond)
    bucket.last = now
    if bucket.tokens < 1 then
        return false
    end
    bucket.tokens -= 1
    return true
end

Players.PlayerRemoving:Connect(function(player)
    buckets[player] = nil
end)

return RateLimiter
