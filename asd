local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Drones = workspace:WaitForChild("Drones")

local JammedDroneRemote = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Weapon"):WaitForChild("Jammer"):WaitForChild("JammedDrone")
local PlayerDroneRemote = ReplicatedStorage:WaitForChild("Events"):WaitForChild("PlayerDrone")

local espEnabled = false
local aimlockEnabled = false
local droneAimlockEnabled = false

local accelerationVal = 50
local maxSpeedVal = 100
local rotateRatioVal = 5

local MAX_ESP_DISTANCE = 500000
local COLOR_DANGER = Color3.fromRGB(255, 0, 0)
local COLOR_IN_RANGE = Color3.fromRGB(0, 255, 0)

local trackedDrones = {}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DroneControlGUI"
ScreenGui.ResetOnSpawn = false

local getHuiFunc = gethui or get_hidden_gui
if getHuiFunc then
	ScreenGui.Parent = getHuiFunc()
else
	local success = pcall(function()
		ScreenGui.Parent = CoreGui
	end)
	if not success then
		ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	end
end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 240, 0, 420)
MainFrame.Position = UDim2.new(0, 20, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(60, 60, 60)
UIStroke.Thickness = 2
UIStroke.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "Drone Controller"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

local function createButton(name, position, text)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.new(0.88, 0, 0, 32)
	button.Position = position
	button.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 13
	button.Font = Enum.Font.GothamSemibold
	button.Parent = MainFrame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button

	return button
end

local EspButton = createButton("EspButton", UDim2.new(0.06, 0, 0.10, 0), "ESP: OFF")
local AimlockButton = createButton("AimlockButton", UDim2.new(0.06, 0, 0.19, 0), "Jammer Lock: OFF")
local DroneAimlockButton = createButton("DroneAimlockButton", UDim2.new(0.06, 0, 0.28, 0), "Drone Aimlock: OFF")
local SpawnButton = createButton("SpawnButton", UDim2.new(0.06, 0, 0.37, 0), "Spawn Drone")
SpawnButton.BackgroundColor3 = Color3.fromRGB(40, 120, 180)

local function createSlider(titleText, posY, minVal, maxVal, defaultVal, callback)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(0.88, 0, 0, 45)
	container.Position = UDim2.new(0.06, 0, posY, 0)
	container.BackgroundTransparency = 1
	container.Parent = MainFrame

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 18)
	label.BackgroundTransparency = 1
	label.Text = titleText .. ": " .. tostring(defaultVal)
	label.TextColor3 = Color3.fromRGB(220, 220, 220)
	label.TextSize = 12
	label.Font = Enum.Font.GothamSemibold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container

	local sliderBg = Instance.new("Frame")
	sliderBg.Size = UDim2.new(1, 0, 0, 8)
	sliderBg.Position = UDim2.new(0, 0, 0, 24)
	sliderBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	sliderBg.BorderSizePixel = 0
	sliderBg.Parent = container

	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(1, 0)
	bgCorner.Parent = sliderBg

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
	fill.BorderSizePixel = 0
	fill.Parent = sliderBg

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fill

	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0, 16, 0, 16)
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Position = UDim2.new(fill.Size.X.Scale, 0, 0.5, 0)
	knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	knob.BorderSizePixel = 0
	knob.Parent = sliderBg

	local knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = UDim.new(1, 0)
	knobCorner.Parent = knob

	local sliding = false

	local function updateInput(input)
		local posX = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
		fill.Size = UDim2.new(posX, 0, 1, 0)
		knob.Position = UDim2.new(posX, 0, 0.5, 0)

		local val = math.floor(minVal + (maxVal - minVal) * posX)
		label.Text = titleText .. ": " .. tostring(val)
		callback(val)
	end

	sliderBg.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliding = true
			updateInput(input)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateInput(input)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliding = false
		end
	end)
end

local function isMyDrone(drone)
	if not drone or not drone:IsA("Model") then return false end
	for _, child in ipairs(drone:GetGetChildren() or {}) do
		if child.Name == "Player" then
			if child:IsA("ObjectValue") and child.Value == LocalPlayer then
				return true
			elseif child:IsA("StringValue") and (child.Value == LocalPlayer.Name or child.Value == tostring(LocalPlayer.UserId)) then
				return true
			end
		end
	end
	local playerVal = drone:FindFirstChild("Player", true) or drone:FindFirstChild("Operator", true)
	if playerVal then
		if playerVal:IsA("ObjectValue") and playerVal.Value == LocalPlayer then
			return true
		elseif (playerVal:IsA("StringValue") or playerVal:IsA("IntValue")) and (tostring(playerVal.Value) == LocalPlayer.Name or tostring(playerVal.Value) == tostring(LocalPlayer.UserId)) then
			return true
		end
	end
	return false
end

local function applyDroneSettings(drone)
	if not isMyDrone(drone) then return end
	local settingsFolder = drone:FindFirstChild("Settings")
	if settingsFolder then
		local flyFolder = settingsFolder:FindFirstChild("Fly")
		if flyFolder then
			for _, child in ipairs(flyFolder:GetChildren()) do
				if child.Name == "Acceleration" and child:IsA("ValueBase") then
					child.Value = accelerationVal
				elseif child.Name == "MaxSpeed" and child:IsA("ValueBase") then
					child.Value = maxSpeedVal
				elseif child.Name == "RotateRatio" and child:IsA("ValueBase") then
					child.Value = rotateRatioVal
				end
			end
		end
	end
end

local function applySettingsToAllMyDrones()
	for _, drone in ipairs(Drones:GetChildren()) do
		applyDroneSettings(drone)
	end
end

createSlider("Acceleration", 0.47, 1, 200, accelerationVal, function(val)
	accelerationVal = val
	applySettingsToAllMyDrones()
end)

createSlider("Max Speed", 0.62, 1, 500, maxSpeedVal, function(val)
	maxSpeedVal = val
	applySettingsToAllMyDrones()
end)

createSlider("Rotate Ratio", 0.77, 1, 50, rotateRatioVal, function(val)
	rotateRatioVal = val
	applySettingsToAllMyDrones()
end)

local dragging
local dragInput
local dragStart
local startPos

MainFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = MainFrame.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

MainFrame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
		MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

local function getMyCurrentDrone()
	for _, drone in ipairs(Drones:GetChildren()) do
		if isMyDrone(drone) then
			local lifeStatus = drone:FindFirstChild("LifeStatus")
			if not lifeStatus or lifeStatus.Value then
				return drone
			end
		end
	end
	return nil
end

local function getClosestEnemyPlayer(originPos)
	local closestPlayer = nil
	local shortestDistance = math.huge

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				local targetPos = player.Character.HumanoidRootPart.Position
				local distance = (targetPos - originPos).Magnitude
				if distance < shortestDistance then
					shortestDistance = distance
					closestPlayer = player
				end
			end
		end
	end

	return closestPlayer
end

local function addESP(drone)
	if trackedDrones[drone] then return end

	local highlight = Instance.new("Highlight")
	highlight.Name = "DroneHighlight"
	highlight.FillColor = COLOR_DANGER
	highlight.OutlineColor = COLOR_DANGER
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = drone

	local line = Drawing.new("Line")
	line.Color = COLOR_DANGER
	line.Thickness = 1.5
	line.Transparency = 1
	line.Visible = false

	local text = Drawing.new("Text")
	text.Color = COLOR_DANGER
	text.Size = 16
	text.Center = true
	text.Outline = true
	text.OutlineColor = Color3.fromRGB(0, 0, 0)
	text.Visible = false

	trackedDrones[drone] = {
		Highlight = highlight,
		Line = line,
		Text = text
	}

	applyDroneSettings(drone)
end

local function removeESP(drone)
	local data = trackedDrones[drone]
	if data then
		if data.Highlight then data.Highlight:Destroy() end
		if data.Line then data.Line:Remove() end
		if data.Text then data.Text:Remove() end
		trackedDrones[drone] = nil
	end
end

local function hideAllESP()
	for _, data in pairs(trackedDrones) do
		if data.Highlight then data.Highlight.Enabled = false end
		if data.Line then data.Line.Visible = false end
		if data.Text then data.Text.Visible = false end
	end
end

for _, child in ipairs(Drones:GetChildren()) do
	addESP(child)
end

Drones.ChildAdded:Connect(function(child)
	addESP(child)
	task.delay(0.2, function()
		applyDroneSettings(child)
	end)
end)

Drones.ChildRemoved:Connect(removeESP)

local function getJammer()
	local char = LocalPlayer.Character
	if char and char:FindFirstChild("Jammer") then
		return char.Jammer
	end
	return LocalPlayer.Backpack:FindFirstChild("Jammer")
end

local function getClosestDrone()
	local closestDrone = nil
	local shortestDistance = math.huge

	local character = LocalPlayer.Character
	local originPos = (character and character:FindFirstChild("HumanoidRootPart")) 
		and character.HumanoidRootPart.Position or Camera.CFrame.Position

	for _, drone in ipairs(Drones:GetChildren()) do
		if not isMyDrone(drone) then
			local lifeStatus = drone:FindFirstChild("LifeStatus")
			if lifeStatus and lifeStatus.Value then
				local dronePos = drone:GetPivot().Position
				local distance = (dronePos - originPos).Magnitude

				if distance < shortestDistance then
					shortestDistance = distance
					closestDrone = drone
				end
			end
		end
	end

	return closestDrone
end

RunService.RenderStepped:Connect(function()
	local viewportSize = Camera.ViewportSize
	local screenBottom = Vector2.new(viewportSize.X / 2, viewportSize.Y)
	local cameraPos = Camera.CFrame.Position

	for drone, data in pairs(trackedDrones) do
		if espEnabled and drone and drone.Parent and drone:IsA("Model") then
			local dronePos = drone:GetPivot().Position
			local distance = (dronePos - cameraPos).Magnitude

			if distance <= MAX_ESP_DISTANCE then
				local screenPos, onScreen = Camera:WorldToViewportPoint(dronePos)

				if onScreen then
					local currentColor = (distance <= 1000) and COLOR_IN_RANGE or COLOR_DANGER

					data.Highlight.Enabled = true
					data.Highlight.FillColor = currentColor
					data.Highlight.OutlineColor = currentColor

					data.Line.Color = currentColor
					data.Line.From = screenBottom
					data.Line.To = Vector2.new(screenPos.X, screenPos.Y)
					data.Line.Visible = true

					data.Text.Color = currentColor
					data.Text.Position = Vector2.new(screenPos.X, screenPos.Y - 25)
					data.Text.Text = tostring(math.floor(distance)) .. " Studs"
					data.Text.Visible = true
				else
					data.Highlight.Enabled = false
					data.Line.Visible = false
					data.Text.Visible = false
				end
			else
				data.Highlight.Enabled = false
				data.Line.Visible = false
				data.Text.Visible = false
			end
		else
			if data.Highlight then data.Highlight.Enabled = false end
			data.Line.Visible = false
			data.Text.Visible = false
		end
	end

	if aimlockEnabled then
		local jammer = getJammer()
		if jammer and jammer.Parent == LocalPlayer.Character then
			local targetDrone = getClosestDrone()
			if targetDrone then
				local dronePos = targetDrone:GetPivot().Position

				Camera.CFrame = CFrame.new(Camera.CFrame.Position, dronePos)

				local events = jammer:FindFirstChild("Events")
				local fanEvent = events and events:FindFirstChild("FanEvent")
				if fanEvent then
					fanEvent:FireServer(30)
				end

				if JammedDroneRemote then
					JammedDroneRemote:FireServer(targetDrone, Camera.CFrame)
				end
			end
		end
	end

	if droneAimlockEnabled then
		local myDrone = getMyCurrentDrone()
		if myDrone then
			local dronePos = myDrone:GetPivot().Position
			local targetPlayer = getClosestEnemyPlayer(dronePos)
			if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
				local targetPos = targetPlayer.Character.HumanoidRootPart.Position
				Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPos)
			end
		end
	end
end)

EspButton.MouseButton1Click:Connect(function()
	espEnabled = not espEnabled
	if espEnabled then
		EspButton.Text = "ESP: ON"
		EspButton.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
	else
		EspButton.Text = "ESP: OFF"
		EspButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
		hideAllESP()
	end
end)

AimlockButton.MouseButton1Click:Connect(function()
	aimlockEnabled = not aimlockEnabled
	if aimlockEnabled then
		AimlockButton.Text = "Jammer Lock: ON"
		AimlockButton.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
	else
		AimlockButton.Text = "Jammer Lock: OFF"
		AimlockButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
	end
end)

DroneAimlockButton.MouseButton1Click:Connect(function()
	droneAimlockEnabled = not droneAimlockEnabled
	if droneAimlockEnabled then
		DroneAimlockButton.Text = "Drone Aimlock: ON"
		DroneAimlockButton.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
	else
		DroneAimlockButton.Text = "Drone Aimlock: OFF"
		DroneAimlockButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
	end
end)

SpawnButton.MouseButton1Click:Connect(function()
	if PlayerDroneRemote then
		PlayerDroneRemote:FireServer("Wood1")
	end
end)
