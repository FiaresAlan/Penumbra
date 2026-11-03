--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent:WaitForChild("Theme") :: ModuleScript) :: any

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local ProfileUpdate = ReplicatedStorage:WaitForChild("EcosRemotes"):WaitForChild("ProfileUpdate") :: RemoteEvent

local ProfileHUD = {}

-- Último perfil recebido do servidor, para as telas de mercado e oficina lerem
local lastProfile: { money: number, stash: { any }, upgrades: { [string]: boolean } }? = nil
local listeners: { (any) -> () } = {}
local profileLabel: TextLabel? = nil

-- O HUD do lobby mostra as moedas por conta própria; este texto fica só para a caverna
function ProfileHUD.SetLabelVisible(visible: boolean)
    local label = profileLabel
    if label then
        label.Visible = visible
    end
end

function ProfileHUD.GetProfile()
    return lastProfile
end

function ProfileHUD.OnChanged(callback: (any) -> ())
    table.insert(listeners, callback)
end

function ProfileHUD.Init()
    local gui = playerGui:WaitForChild("EcosHUD")

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 300, 0, 26)
    label.Position = UDim2.new(0, 20, 0, 50)
    label.BackgroundTransparency = 1
    label.TextColor3 = Theme.Color.Gold
    label.Font = Theme.Font.Strong
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = "Moedas: 0 · Baú: 0 itens"
    label.Parent = gui
    profileLabel = label

    local notice = Instance.new("TextLabel")
    notice.Size = UDim2.new(0, 340, 0, 30)
    notice.Position = UDim2.new(0.5, -170, 0.55, 0)
    notice.BackgroundColor3 = Theme.Color.PanelBg
    notice.BackgroundTransparency = 0.08
    notice.TextColor3 = Theme.Color.Gold
    notice.Font = Enum.Font.GothamBold
    notice.TextSize = 16
    notice.Visible = false
    notice.Parent = gui
    local noticeToken = 0

    ProfileUpdate.OnClientEvent:Connect(function(data: unknown)
        if typeof(data) ~= "table" then
            return
        end
        local info = data :: { money: number, stash: { any }, upgrades: { [string]: boolean }, notice: string? }
        lastProfile = info
        label.Text = string.format("Moedas: %d · Baú: %d itens", info.money, #info.stash)
        for _, callback in ipairs(listeners) do
            callback(info)
        end
        if info.notice then
            noticeToken += 1
            local mine = noticeToken
            notice.Text = info.notice
            notice.Visible = true
            task.delay(4, function()
                if mine == noticeToken then
                    notice.Visible = false
                end
            end)
        end
    end)
end

return ProfileHUD
