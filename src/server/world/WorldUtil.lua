--!strict
-- Ajudantes para criar as peças do mapa. MapFolder é a pasta workspace.Map da geração em andamento.

local function newPart(name: string, size: Vector3, cframe: CFrame, props: { [string]: any }?, parent: Instance): Part
    local part = Instance.new("Part")
    part.Name = name
    part.Anchored = true
    part.Size = size
    part.CFrame = cframe
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    if props then
        for key, value in pairs(props) do
            (part :: any)[key] = value
        end
    end
    part.Parent = parent
    return part
end

local function marker(name: string, size: Vector3, cframe: CFrame, parent: Instance): Part
    return newPart(name, size, cframe, { Transparency = 1, CanCollide = false, CanTouch = false }, parent)
end

local function topLevel(instance: Instance)
    instance:SetAttribute("Generated", true)
    instance.Parent = workspace
end

local function newFolder(name: string): Folder
    local folder = Instance.new("Folder")
    folder.Name = name
    topLevel(folder)
    return folder
end

local function addPrompt(parent: Instance, actionText: string, hold: number, distance: number): ProximityPrompt
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = actionText
    prompt.HoldDuration = hold
    prompt.MaxActivationDistance = distance
    prompt.RequiresLineOfSight = false
    prompt.Parent = parent
    return prompt
end

local function addLight(part: BasePart, color: Color3, range: number, brightness: number)
    local light = Instance.new("PointLight")
    light.Color = color
    light.Range = range
    light.Brightness = brightness
    light.Parent = part
end

return {
    MapFolder = nil :: Folder?,
    newPart = newPart,
    marker = marker,
    topLevel = topLevel,
    newFolder = newFolder,
    addPrompt = addPrompt,
    addLight = addLight,
}
