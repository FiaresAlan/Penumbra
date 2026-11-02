--!strict
-- Procura um ponto de chão ao redor de uma posição. Usado pelos Guardiões que criam coisas no mundo.
local Players = game:GetService("Players")

local FloorPicker = {}

-- Devolve um ponto de chão entre minRadius e maxRadius de `center`, ou nil se não achar em 12 tentativas.
function FloorPicker.Pick(center: Vector3, minRadius: number, maxRadius: number): Vector3?
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local ignored: { Instance } = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            table.insert(ignored, player.Character)
        end
    end
    local guardian = workspace:FindFirstChild("Guardian")
    if guardian then
        table.insert(ignored, guardian)
    end
    params.FilterDescendantsInstances = ignored

    for _ = 1, 12 do
        local angle = math.random() * math.pi * 2
        local radius = minRadius + math.random() * (maxRadius - minRadius)
        local origin = center + Vector3.new(math.cos(angle) * radius, 6, math.sin(angle) * radius)
        local result = workspace:Raycast(origin, Vector3.new(0, -30, 0), params)
        if result and result.Normal.Y > 0.9 then
            return result.Position
        end
    end
    return nil
end

return FloorPicker
