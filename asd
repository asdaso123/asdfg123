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
local autoExplodeEnabled = false

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
MainFrame.Size = UDim2.new(0, 340, 0, 460)
MainFrame.Position = UDim2.new(0.5, -170, 0.5, -230)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
MainFrame.BackgroundTransparency = 0.15
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 14)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(60, 60, 75)
UIStroke.Thickness = 1.5
UIStroke.Parent = MainFrame

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 46)
TopBar.BackgroundTransparency = 1
TopBar.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0.6, 0, 1, 0)
Title.Position = UDim2.new(0, 16, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Drone Controller"
Title.TextColor3 = Color3.fromRGB(245, 245, 250)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local CreditLabel = Instance.new("TextLabel")
CreditLabel.Size = UDim2.new(1, -20, 0, 16)
CreditLabel.Position = UDim2.new(0, 16, 1, -22)
CreditLabel.BackgroundTransparency = 1
CreditLabel.Text = "Made by Anndrr1y"
CreditLabel.TextColor3 = Color3.fromRGB(120, 120, 140)
CreditLabel.TextSize = 11
CreditLabel.Font = Enum.Font.GothamMedium
CreditLabel.TextXAlignment = Enum.TextXAlignment.Left
CreditLabel.Parent = MainFrame

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 32, 0, 32)
CloseButton.AnchorPoint = Vector2.new(1, 0.5)
CloseButton.Position = UDim2.new(1, -12, 0.5, 0)
CloseButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
CloseButton.BackgroundTransparency = 0.2
CloseButton.Text = "✕"
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

local NavContainer = Instance.new("Frame")
NavContainer.Size = UDim2.new(1, -32, 0, 40)
NavContainer.Position = UDim2.new(0, 16, 0, 50)
NavContainer.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
NavContainer.BackgroundTransparency = 0.2
NavContainer.BorderSizePixel = 0
NavContainer.Parent = MainFrame

local NavCorner = Instance.new("UICorner")
NavCorner.CornerRadius = UDim.new(0, 8)
NavCorner.Parent = NavContainer

local NavLayout = Instance.new("UIListLayout")
NavLayout.FillDirection = Enum.FillDirection.Horizontal
NavLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
NavLayout.VerticalAlignment = Enum.VerticalAlignment.Center
NavLayout.SortOrder = Enum.SortOrder.LayoutOrder
NavLayout.Parent = NavContainer

local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, -32, 1, -132)
ContentContainer.Position = UDim2.new(0, 16, 0, 98)
ContentContainer.BackgroundTransparency = 1
ContentContainer.Parent = MainFrame

local pages = {}
local navButtons = {}

local function createPage(name)
	local page = Instance.new("ScrollingFrame")
	page.Name = name .. "Page"
	page.Size = UDim2.new(1, 0, 1, 0)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.CanvasSize = UDim2.new(0, 0, 0, 280)
	page.ScrollBarThickness = 4
	page.Visible = false
	page.Parent = ContentContainer

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 12)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = page

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 4)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.Parent = page

	pages[name] = page
	return page
end

local function switchPage(pageName)
	for name, page in pairs(pages) do
		page.Visible = (name == pageName)
	end
	for name, btn in pairs(navButtons) do
		if name == pageName then
			btn.BackgroundColor3 = Color3.fromRGB(0, 132, 255)
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		else
			btn.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
			btn.TextColor3 = Color3.fromRGB(160, 160, 180)
		end
	end
end

local function createNavButton(name, text, order)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.48, 0, 0, 32)
	btn.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
	btn.Text = text
	btn.TextColor3 = Color3.fromRGB(160, 160, 180)
	btn.TextSize = 13
	btn.Font = Enum.Font.GothamSemibold
	btn.LayoutOrder = order
	btn.Parent = NavContainer

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = btn

	btn.MouseButton1Click:Connect(function()
		switchPage(name)
	end)

	navButtons[name] = btn
	return btn
end

createNavButton("Combat", "Features", 1)
createNavButton("Settings", "Settings", 2)
createPage("Combat")
createPage("Settings")

local function createButton(pageName, name, text, color, order)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.new(1, 0, 0, 42)
	button.BackgroundColor3 = color
	button.BackgroundTransparency = 0.15
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 14
	button.Font = Enum.Font.GothamSemibold
	button.LayoutOrder = order
	button.Parent = pages[pageName]

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	return button
end

createButton("Combat", "EspButton", "ESP: OFF", Color3.fromRGB(180, 40, 40), 1)
createButton("Combat", "AimlockButton", "Jammer Lock: OFF", Color3.fromRGB(180, 40, 40), 2)
createButton("Combat", "DroneAimlockButton", "Drone Aimlock: OFF", Color3.fromRGB(180, 40, 40), 3)
createButton("Combat", "AutoExplodeButton", "Auto Explode Drones: OFF", Color3.fromRGB(180, 40, 40), 4)
createButton("Combat", "SpawnButton", "Spawn Drone", Color3.fromRGB(40, 120, 180), 5)

local EspButton = pages["Combat"]:FindFirstChild("EspButton")
local AimlockButton = pages["Combat"]:FindFirstChild("AimlockButton")
local DroneAimlockButton = pages["Combat"]:FindFirstChild("DroneAimlockButton")
local AutoExplodeButton = pages["Combat"]:FindFirstChild("AutoExplodeButton")
local SpawnButton = pages["Combat"]:FindFirstChild("SpawnButton")

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

local function setDroneCollisions(drone, state)
	for _, part in ipairs(drone:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = state
		end
	end
end

local function createSlider(titleText, minVal, maxVal, defaultVal, isFloat, order, callback)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 52)
	container.BackgroundTransparency = 1
	container.LayoutOrder = order
	container.Parent = pages["Settings"]

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.6, 0, 0, 20)
	label.BackgroundTransparency = 1
	label.Text = titleText
	label.TextColor3 = Color3.fromRGB(210, 210, 225)
	label.TextSize = 13
	label.Font = Enum.Font.GothamSemibold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container

	local inputBox = Instance.new("TextBox")
	inputBox.Size = UDim2.new(0.4, 0, 0, 20)
	inputBox.Position = UDim2.new(0.6, 0, 0, 0)
	inputBox.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
	inputBox.BackgroundTransparency = 0.2
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
	sliderBg.Size = UDim2.new(1, 0, 0, 8)
	sliderBg.Position = UDim2.new(0, 0, 0, 28)
	sliderBg.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
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
	knob.Size = UDim2.new(0, 18, 0, 18)
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

createSlider("Acceleration", 0, 1000, accelerationVal, false, 1, function(val)
	accelerationVal = val
	applySettingsToAllMyDrones()
end)

createSlider("Max Speed", 0, 1000, maxSpeedVal, false, 2, function(val)
	maxSpeedVal = val
	applySettingsToAllMyDrones()
end)

createSlider("Rotate Ratio", 0.1, 2, rotateRatioVal, true, 3, function(val)
	rotateRatioVal = val
	applySettingsToAllMyDrones()
end)

switchPage("Combat")

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
			setDroneCollisions(child, not autoExplodeEnabled)
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
				setDroneCollisions(myDrone, not autoExplodeEnabled)
				applyDroneSettings(myDrone)
			end
		end)
	else
		DroneAimlockButton.Text = "Drone Aimlock: OFF"
		DroneAimlockButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
	end
end)

AutoExplodeButton.MouseButton1Click:Connect(function()
	autoExplodeEnabled = not autoExplodeEnabled
	if autoExplodeEnabled then
		AutoExplodeButton.Text = "Auto Explode Drones: ON"
		AutoExplodeButton.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
	else
		AutoExplodeButton.Text = "Auto Explode Drones: OFF"
		AutoExplodeButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
	end
	for _, drone in ipairs(getActiveDrones()) do
		if isMyDrone(drone) then
			setDroneCollisions(drone, not autoExplodeEnabled)
		end
	end
end)

SpawnButton.MouseButton1Click:Connect(function()
	if PlayerDroneRemote then
		PlayerDroneRemote:FireServer("Wood1")
		task.spawn(function()
			local myDrone = waitForMyDrone(10)
			if myDrone then
				setDroneCollisions(myDrone, not autoExplodeEnabled)
				applyDroneSettings(myDrone)
			end
		end)
	end
end)
