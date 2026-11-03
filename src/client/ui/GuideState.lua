--!strict
-- Liga e desliga o guia (seta no chão e marcadores nos lugares). Vale na sessão; o Ajustes mexe aqui.
local GuideState = {}

local enabled = true
local listeners: { (boolean) -> () } = {}

function GuideState.IsEnabled(): boolean
    return enabled
end

function GuideState.Set(value: boolean)
    if enabled == value then
        return
    end
    enabled = value
    for _, listener in ipairs(listeners) do
        listener(value)
    end
end

function GuideState.OnChanged(listener: (boolean) -> ())
    table.insert(listeners, listener)
end

return GuideState
