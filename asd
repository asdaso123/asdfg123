local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

if _G.DroneControllerLoaded then
	return
end
_G.DroneControllerLoaded = true

local JammedDroneRemote = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Weapon"):WaitForChild("Jammer"):WaitForChild("JammedDrone", 5)
local PlayerDroneRemote = ReplicatedStorage:WaitForChild("Events"):WaitForChild("PlayerDrone", 5)

local espEnabled = false
local aimlockEnabled = false
local droneAimlockEnabled = false

local accelerationVal = 50
local maxSpeedVal = 100
local rotateRatioVal = 1

local MAX_ESP_DISTANCE = 500000
local COLOR_DANGER = Color3.fromRGB(255, 0, 0)
local COLOR_IN_RANGE = Color3.fromRGB(0, 255, 0)

local trackedDrones = {}

local mt = getrawmetatable(game)
local oldIndex = mt.__index
setreadonly(mt, false)

mt.__index = newcclosure(function(t, k)
	if not checkcaller() and k == "Value" then
		local name = t.Name
		if name == "MaxSpeed" or name == "Acceleration" or name == "RotateRatio" then
			local parent = t.Parent
			if parent and parent.Name == "Fly" then
				if name == "MaxSpeed" then return maxSpeedVal end
				if name == "Acceleration" then return accelerationVal end
				if name == "RotateRatio" then return rotateRatioVal end
			end
		end
	end
	return oldIndex(t, k)
end)
setreadonly(mt, true)

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
MainFrame.Size = UDim2.new(0, 300, 0, 560)
MainFrame.Position = UDim2.new(0, 30, 0.15, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(50, 50, 58)
UIStroke.Thickness = 2
UIStroke.Parent = MainFrame

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 44)
TopBar.BackgroundTransparency = 1
TopBar.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0.7, 0, 1, 0)
Title.Position = UDim2.new(0, 14, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Drone Controller"
Title.TextColor3 = Color3.fromRGB(240, 240, 245)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 32, 0, 32)
CloseButton.AnchorPoint = Vector2.new(1, 0.5)
CloseButton.Position = UDim2.new(1, -10, 0.5, 0)
CloseButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextSize = 14
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Parent = TopBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 8)
CloseCorner.Parent = CloseButton

CloseButton.MouseButton1Click:Connect(function()
	_G.DroneControllerLoaded = false
	ScreenGui:Destroy()
end)

local ScrollingFrame = Instance.new("ScrollingFrame")
ScrollingFrame.Size = UDim2.new(1, 0, 1, -44)
ScrollingFrame.Position = UDim2.new(0, 0, 0, 44)
ScrollingFrame.BackgroundTransparency = 1
ScrollingFrame.BorderSizePixel = 0
ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 620)
ScrollingFrame.ScrollBarThickness = 6
ScrollingFrame.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 10)
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.Parent = ScrollingFrame

local UIPadding = Instance.new("UIPadding")
UIPadding.PaddingTop = UDim.new(0, 6)
UIPadding.PaddingBottom = UDim.new(0, 20)
UIPadding.Parent = ScrollingFrame

local function createSectionHeader(text, order)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.9, 0, 0, 24)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(140, 140, 160)
	label.TextSize = 12
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.LayoutOrder = order
	label.Parent = ScrollingFrame
	return label
end

local function createButton(name, text, color, order)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.new(0.9, 0, 0, 40)
	button.BackgroundColor3 = color
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 14
	button.Font = Enum.Font.GothamSemibold
	button.LayoutOrder = order
	button.Parent = ScrollingFrame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	return button
end

createSectionHeader("FEATURES & COMBAT", 1)
local EspButton = createButton("EspButton", "ESP: OFF", Color3.fromRGB(180, 40, 40), 2)
local AimlockButton = createButton("AimlockButton", "Jammer Lock: OFF", Color3.fromRGB(180, 40, 40), 3)
local DroneAimlockButton = createButton("DroneAimlockButton", "Drone Aimlock: OFF", Color3.fromRGB(180, 40, 40), 4)

createSectionHeader("ACTIONS", 5)
local SpawnButton = createButton("SpawnButton", "Spawn Drone", Color3.fromRGB(40, 120, 180), 6)
local ExplodeButton = createButton("ExplodeButton", "Explode Drones", Color3.fromRGB(180, 80, 0), 7)

createSectionHeader("DRONE SETTINGS", 8)

local function getActiveDrones()
	local drones = {}
	if workspace:FindFirstChild("Drones") then
		for _, v in ipairs(workspace.Drones:GetChildren()) do
			if v:IsA("Model") then
				table.insert(drones, v)
			end
		end
	end
	for _, v in ipairs(workspace:GetChildren()) do
		if v:IsA("Model") and (string.find(v.Name, "Drone") or string.find(v.Name, "DronePlayer")) then
			local found = false
			for _, existing in ipairs(drones) do
				if existing == v then 
					found = true 
					break 
				end
			end
			if not found then
				table.insert(drones, v)
			end
		end
	end
	return drones
end

local function isMyDrone(drone)
	if not drone or not drone:IsA("Model") then return false end
	local playerVal = drone:FindFirstChild("Player") or drone:FindFirstChild("Operator")
	if playerVal then
		if playerVal:IsA("ObjectValue") and playerVal.Value == LocalPlayer then
			return true
		elseif (playerVal:IsA("StringValue") or playerVal:IsA("IntValue")) and (tostring(playerVal.Value) == LocalPlayer.Name or tostring(playerVal.Value) == tostring(LocalPlayer.UserId)) then
			return true
		end
	end
	if string.find(drone.Name, LocalPlayer.Name) then
		return true
	end
	return false
end

local function applyDroneSettings(drone)
	if not drone or not drone.Parent then return end
	local settingsFolder = drone:FindFirstChild("Settings")
	if settingsFolder then
		local flyFolder = settingsFolder:FindFirstChild("Fly")
		if flyFolder then
			local accel = flyFolder:FindFirstChild("Acceleration")
			if accel then accel.Value = accelerationVal end
			local maxSpd = flyFolder:FindFirstChild("MaxSpeed")
			if maxSpd then maxSpd.Value = maxSpeedVal end
			local rotRatio = flyFolder:FindFirstChild("RotateRatio")
			if rotRatio then rotRatio.Value = rotateRatioVal end
		end
	end
end

local function applySettingsToAllMyDrones()
	for _, drone in ipairs(getActiveDrones()) do
		if isMyDrone(drone) then
			applyDroneSettings(drone)
		end
	end
end

local function createSlider(titleText, minVal, maxVal, defaultVal, isFloat, order, callback)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(0.9, 0, 0, 52)
	container.BackgroundTransparency = 1
	container.LayoutOrder = order
	container.Parent = ScrollingFrame

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.5, 0, 0, 20)
	label.BackgroundTransparency = 1
	label.Text = titleText
	label.TextColor3 = Color3.fromRGB(210, 210, 220)
	label.TextSize = 13
	label.Font = Enum.Font.GothamSemibold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container

	local inputBox = Instance.new("TextBox")
	inputBox.Size = UDim2.new(0.5, 0, 0, 20)
	inputBox.Position = UDim2.new(0.5, 0, 0, 0)
	inputBox.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
	inputBox.Text = tostring(defaultVal)
	inputBox.TextColor3 = Color3.fromRGB(0, 162, 255)
	inputBox.TextSize = 13
	inputBox.Font = Enum.Font.GothamBold
	inputBox.TextXAlignment = Enum.TextXAlignment.Right
	inputBox.Parent = container

	local boxCorner = Instance.new("UICorner")
	boxCorner.CornerRadius = UDim.new(0, 4)
	boxCorner.Parent = inputBox

	local sliderBg = Instance.new("Frame")
	sliderBg.Size = UDim2.new(1, 0, 0, 10)
	sliderBg.Position = UDim2.new(0, 0, 0, 30)
	sliderBg.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
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
	knob.Size = UDim2.new(0, 20, 0, 20)
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Position = UDim2.new(fill.Size.X.Scale, 0, 0.5, 0)
	knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	knob.BorderSizePixel = 0
	knob.Parent = sliderBg

	local knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = UDim.new(1, 0)
	knobCorner.Parent = knob

	local sliding = false
	local currentVal = defaultVal

	local function setVisuals(val)
		local clampedVal = math.clamp(val, minVal, maxVal)
		currentVal = clampedVal
		local pct = (clampedVal - minVal) / (maxVal - minVal)
		fill.Size = UDim2.new(pct, 0, 1, 0)
		knob.Position = UDim2.new(pct, 0, 0.5, 0)
		
		local formattedVal = isFloat and string.format("%.2f", clampedVal) or tostring(math.floor(clampedVal))
		inputBox.Text = formattedVal
		callback(isFloat and clampedVal or math.floor(clampedVal))
	end

	local function updateInput(input)
		local posX = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
		local val = minVal + (maxVal - minVal) * posX
		if not isFloat then val = math.floor(val) end
		setVisuals(val)
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

	inputBox.FocusLost:Connect(function()
		local num = tonumber(inputBox.Text)
		if num then
			setVisuals(num)
		else
			setVisuals(currentVal)
		end
	end)
end

createSlider("Acceleration", 0, 1000, accelerationVal, false, 9, function(val)
	accelerationVal = val
	applySettingsToAllMyDrones()
end)

createSlider("Max Speed", 0, 1000, maxSpeedVal, false, 10, function(val)
	maxSpeedVal = val
	applySettingsToAllMyDrones()
end)

createSlider("Rotate Ratio", 0.1, 2, rotateRatioVal, true, 11, function(val)
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
	for _, drone in ipairs(getActiveDrones()) do
		if isMyDrone(drone) then
			local lifeStatus = drone:FindFirstChild("LifeStatus")
			if not lifeStatus or lifeStatus.Value then
				return drone
			end
		end
	end
	return nil
end

local function waitForMyDrone(maxWait)
	local startTime = tick()
	maxWait = maxWait or 10
	while tick() - startTime < maxWait do
		local drone = getMyCurrentDrone()
		if drone then
			return drone
		end
		task.wait(0.1)
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

local function onDroneAdded(child)
	if child:IsA("Model") and (string.find(child.Name, "Drone") or string.find(child.Name, "DronePlayer")) then
		addESP(child)
		if isMyDrone(child) then
			applyDroneSettings(child)
		end
	end
end

for _, child in ipairs(getActiveDrones()) do
	onDroneAdded(child)
end

if workspace:FindFirstChild("Drones") then
	workspace.Drones.ChildAdded:Connect(onDroneAdded)
	workspace.Drones.ChildRemoved:Connect(removeESP)
end

workspace.ChildAdded:Connect(onDroneAdded)
workspace.ChildRemoved:Connect(removeESP)

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
	local originPos = (character and character:FindFirstChild("HumanoidRootPart")) and character.HumanoidRootPart.Position or Camera.CFrame.Position

	for _, drone in ipairs(getActiveDrones()) do
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
		task.spawn(function()
			local myDrone = waitForMyDrone(10)
			if myDrone then
				applyDroneSettings(myDrone)
			end
		end)
	else
		DroneAimlockButton.Text = "Drone Aimlock: OFF"
		DroneAimlockButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
	end
end)

SpawnButton.MouseButton1Click:Connect(function()
	if PlayerDroneRemote then
		PlayerDroneRemote:FireServer("Wood1")
		task.spawn(function()
			local myDrone = waitForMyDrone(10)
			if myDrone then
				applyDroneSettings(myDrone)
			end
		end)
	end
end)

ExplodeButton.MouseButton1Click:Connect(function()
	local character = LocalPlayer.Character
	if character then
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if rootPart then
			local targetCFrame = rootPart.CFrame
			for _, drone in ipairs(getActiveDrones()) do
				pcall(function()
					drone:PivotTo(targetCFrame)
				end)
			end
		end
	end
end)
