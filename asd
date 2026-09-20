local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = gethui and gethui() or game:GetService("CoreGui")

local screenGui = Instance.new("ScreenGui")
screenGui.ResetOnSpawn = false
screenGui.Parent = CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 100)
frame.Position = UDim2.new(0.5, -100, 0.5, -50)
frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

local textBox = Instance.new("TextBox")
textBox.Size = UDim2.new(0.8, 0, 0.35, 0)
textBox.Position = UDim2.new(0.1, 0, 0.15, 0)
textBox.PlaceholderText = "Username..."
textBox.Text = ""
textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
textBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
textBox.Parent = frame

local button = Instance.new("TextButton")
button.Size = UDim2.new(0.8, 0, 0.35, 0)
button.Position = UDim2.new(0.1, 0, 0.55, 0)
button.Text = "Toggle"
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
button.Parent = frame

local active = false

button.MouseButton1Click:Connect(function()
	active = not active
	if active then
		button.BackgroundColor3 = Color3.fromRGB(40, 150, 40)
	else
		button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	end
end)

local function getTarget()
	local search = textBox.Text:lower()
	if search == "" then return nil end
	for _, player in Players:GetPlayers() do
		if player.Name:lower():sub(1, #search) == search or player.DisplayName:lower():sub(1, #search) == search then
			return player
		end
	end
	return nil
end

RunService.RenderStepped:Connect(function()
	if not active then return end
	
	local target = getTarget()
	if target and target.Character then
		local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
		if targetHRP then
			targetHRP.CFrame = targetHRP.CFrame * CFrame.new(0, -5, 0)
		end
	end
	
	local camera = workspace.CurrentCamera
	if camera then
		camera.CFrame = CFrame.lookAt(camera.CFrame.Position, camera.CFrame.Position + Vector3.new(0, 1, 0))
	end
end)
