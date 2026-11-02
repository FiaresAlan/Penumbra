--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local ProfileUpdate = ReplicatedStorage:WaitForChild("EcosRemotes"):WaitForChild("ProfileUpdate") :: RemoteEvent

local ProfileHUD = {}

-- Último perfil recebido do servidor, para as telas de mercado e oficina lerem
local lastProfile: { money: number, stash: { any }, upgrades: { [string]: boolean } }? = nil
local listeners: { (any) -> () } = {}

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
    label.TextColor3 = Color3.fromRGB(255, 220, 120)
    label.Font = Enum.Font.Gotham
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = "Moedas: 0 · Baú: 0 itens"
    label.Parent = gui

    local notice = Instance.new("TextLabel")
    notice.Size = UDim2.new(0, 340, 0, 30)
    notice.Position = UDim2.new(0.5, -170, 0.55, 0)
    notice.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    notice.BackgroundTransparency = 0.5
    notice.TextColor3 = Color3.fromRGB(255, 200, 120)
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
