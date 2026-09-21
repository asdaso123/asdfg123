local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 2)

task.spawn(function()
    local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = Character:WaitForChild("HumanoidRootPart", 5)
    if hrp then
        hrp.CFrame = CFrame.new(25000, 25000, 0)
        task.wait(3)
        hrp.Anchored = not hrp.Anchored
    end
end)

local gearTable = {
    ["HadesStaff"] = { ["name"] = "HadesStaff", ["id"] = 69210321 },
    ["KorbloxSwordAndShield"] = { ["name"] = "KorbloxSwordAndShield", ["id"] = 68539623 },
    ["icedagger"] = { ["name"] = "icedagger", ["id"] = 68539623 },
    ["StepGun"] = { ["name"] = "StepGun", ["id"] = 34898883 },
    ["SuperFlyGoldBoombox"] = { ["name"] = "SuperFlyGoldBoombox", ["id"] = 212641536 },
    ["StaffOfPitFire"] = { ["name"] = "StaffOfPitFire", ["id"] = 49491808 }
}

local function ToggleAsset(id)
    ReplicatedStorage:FindFirstChild("Remotes"):FindFirstChild("ToggleAsset"):InvokeServer(id)
end

local function playMusic(songid)
    pcall(function()
        local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        if not Character then return end
        local backpack = LocalPlayer:WaitForChild("Backpack", 2)
        if not backpack then return end
        local boombox = backpack:WaitForChild("SuperFlyGoldBoombox", 2)
        if not boombox then return end
        boombox.Parent = Character
        Character.SuperFlyGoldBoombox.Remote:FireServer("PlaySong", tonumber(songid))
        boombox.DescendantAdded:Wait()
        task.wait()
        boombox.Parent = backpack
        local Sound = boombox:FindFirstChildWhichIsA("Sound", true)
        repeat task.wait() until not Sound.IsPlaying
        Sound:Play()
    end)
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BoomboxAndGearsGui"
ScreenGui.ResetOnSpawn = false

pcall(function()
    ScreenGui.Parent = CoreGui
end)
if not ScreenGui.Parent then
    ScreenGui.Parent = PlayerGui
end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 300, 0, 280)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -140)
MainFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 35)
TitleBar.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = TitleBar

local TitleFix = Instance.new("Frame")
TitleFix.Size = UDim2.new(1, 0, 0, 10)
TitleFix.Position = UDim2.new(0, 0, 1, -10)
TitleFix.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
TitleFix.BorderSizePixel = 0
TitleFix.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -40, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Boombox & Gears"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 16
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 25, 0, 25)
CloseBtn.Position = UDim2.new(1, -30, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.TextSize = 14
CloseBtn.Parent = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 4)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

local TargetInput = Instance.new("TextBox")
TargetInput.Name = "TargetInput"
TargetInput.Size = UDim2.new(1, -20, 0, 30)
TargetInput.Position = UDim2.new(0, 10, 0, 50)
TargetInput.BackgroundColor3 = Color3.fromRGB(38, 38, 45)
TargetInput.BorderSizePixel = 0
TargetInput.PlaceholderText = "Song ID"
TargetInput.Text = ""
TargetInput.TextColor3 = Color3.fromRGB(255, 255, 255)
TargetInput.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
TargetInput.Font = Enum.Font.SourceSans
TargetInput.TextSize = 14
TargetInput.Parent = MainFrame

local InputCorner = Instance.new("UICorner")
InputCorner.CornerRadius = UDim.new(0, 6)
InputCorner.Parent = TargetInput

local PlayBtn = Instance.new("TextButton")
PlayBtn.Name = "PlayBtn"
PlayBtn.Size = UDim2.new(1, -20, 0, 35)
PlayBtn.Position = UDim2.new(0, 10, 0, 95)
PlayBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
PlayBtn.BorderSizePixel = 0
PlayBtn.Text = "Play Music"
PlayBtn.TextColor3 = Color3.fromRGB(230, 230, 230)
PlayBtn.Font = Enum.Font.SourceSansSemibold
PlayBtn.TextSize = 14
PlayBtn.Parent = MainFrame

local PlayCorner = Instance.new("UICorner")
PlayCorner.CornerRadius = UDim.new(0, 6)
PlayCorner.Parent = PlayBtn

PlayBtn.MouseButton1Click:Connect(function()
    local songId = TargetInput.Text
    if songId ~= "" then
        playMusic(songId)
    end
end)

local GearBtn = Instance.new("TextButton")
GearBtn.Name = "GearBtn"
GearBtn.Size = UDim2.new(1, -20, 0, 35)
GearBtn.Position = UDim2.new(0, 10, 0, 140)
GearBtn.BackgroundColor3 = Color3.fromRGB(55, 80, 120)
GearBtn.BorderSizePixel = 0
GearBtn.Text = "Get All Gears"
GearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
GearBtn.Font = Enum.Font.SourceSansSemibold
GearBtn.TextSize = 14
GearBtn.Parent = MainFrame

local GearCorner = Instance.new("UICorner")
GearCorner.CornerRadius = UDim.new(0, 6)
GearCorner.Parent = GearBtn

GearBtn.MouseButton1Click:Connect(function()
    for _, gearInfo in pairs(gearTable) do
        task.spawn(function()
            ToggleAsset(gearInfo["id"])
        end)
    end
end)

local EquipComboBtn = Instance.new("TextButton")
EquipComboBtn.Size = UDim2.new(1, -20, 0, 35)
EquipComboBtn.Position = UDim2.new(0, 10, 0, 185)
EquipComboBtn.BackgroundColor3 = Color3.fromRGB(120, 55, 120)
EquipComboBtn.BorderSizePixel = 0
EquipComboBtn.Text = "Equip Sword & Dagger"
EquipComboBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
EquipComboBtn.Font = Enum.Font.SourceSansSemibold
EquipComboBtn.TextSize = 14
EquipComboBtn.Parent = MainFrame

local EquipCorner = Instance.new("UICorner")
EquipCorner.CornerRadius = UDim.new(0, 6)
EquipCorner.Parent = EquipComboBtn

EquipComboBtn.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if char and bp then
        local sword = bp:FindFirstChild("KorbloxSwordAndShield") or char:FindFirstChild("KorbloxSwordAndShield")
        local dagger = bp:FindFirstChild("icedagger") or char:FindFirstChild("icedagger")
        if sword then sword.Parent = char end
        if dagger then dagger.Parent = char end
    end
end)

local BringBtn = Instance.new("TextButton")
BringBtn.Size = UDim2.new(1, -20, 0, 35)
BringBtn.Position = UDim2.new(0, 10, 0, 230)
BringBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 55)
BringBtn.BorderSizePixel = 0
BringBtn.Text = "Toggle Bring Players"
BringBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
BringBtn.Font = Enum.Font.SourceSansSemibold
BringBtn.TextSize = 14
BringBtn.Parent = MainFrame

local BringCorner = Instance.new("UICorner")
BringCorner.CornerRadius = UDim.new(0, 6)
BringCorner.Parent = BringBtn

local bringing = false
BringBtn.MouseButton1Click:Connect(function()
    bringing = not bringing
    if bringing then
        BringBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    else
        BringBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 55)
    end
end)

RunService.RenderStepped:Connect(function()
    if bringing then
        local char = LocalPlayer.Character
        if char then
            local sword = char:FindFirstChild("KorbloxSwordAndShield")
            if sword then
                for _, v in pairs(sword:GetDescendants()) do
                    if v:IsA("BasePart") then
                        for _, p in pairs(Players:GetPlayers()) do
                            if p ~= LocalPlayer and p.Character then
                                local targetHrp = p.Character:FindFirstChild("HumanoidRootPart")
                                if targetHrp then
                                    targetHrp.CFrame = v.CFrame
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)
