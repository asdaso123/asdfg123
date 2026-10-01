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
local explodeToggleEnabled = false

local accelerationVal = 1
local maxSpeedVal = 100
local rotateRatioVal = 1

local MAX_ESP_DISTANCE = 500000
local COLOR_DANGER = Color3.fromRGB(235, 85, 85)
local COLOR_IN_RANGE = Color3.fromRGB(85, 235, 120)
local COLOR_PLAYER = Color3.fromRGB(85, 170, 255)

local trackedDrones = {}
local trackedPlayers = {}

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
ScreenGui.Name = "DronePanelGUI"
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
MainFrame.Size = UDim2.new(0, 300, 0, 330)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -165)
MainFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
MainFrame.BackgroundTransparency = 0.15
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(45, 45, 55)
UIStroke.Thickness = 1
UIStroke.Parent = MainFrame

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 36)
TopBar.BackgroundTransparency = 1
TopBar.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0.6, 0, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Drone Panel"
Title.TextColor3 = Color3.fromRGB(230, 230, 235)
Title.TextSize = 13
Title.Font = Enum.Font.Code
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local CreditLabel = Instance.new("TextLabel")
CreditLabel.Size = UDim2.new(1, -24, 0, 14)
CreditLabel.Position = UDim2.new(0, 12, 1, -16)
CreditLabel.BackgroundTransparency = 1
CreditLabel.Text = "Made By Anndrr1y"
CreditLabel.TextColor3 = Color3.fromRGB(110, 110, 125)
CreditLabel.TextSize = 10
CreditLabel.Font = Enum.Font.Code
CreditLabel.TextXAlignment = Enum.TextXAlignment.Left
CreditLabel.Parent = MainFrame

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 24, 0, 24)
CloseButton.AnchorPoint = Vector2.new(1, 0.5)
CloseButton.Position = UDim2.new(1, -10, 0.5, 0)
CloseButton.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
CloseButton.Text = "×"
CloseButton.TextColor3 = Color3.fromRGB(180, 180, 190)
CloseButton.TextSize = 14
CloseButton.Font = Enum.Font.Gotham
CloseButton.Parent = TopBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseButton

CloseButton.MouseButton1Click:Connect(function()
	_G.DroneControllerLoaded = false
	ScreenGui:Destroy()
end)

local NavContainer = Instance.new("Frame")
NavContainer.Size = UDim2.new(1, -24, 0, 32)
NavContainer.Position = UDim2.new(0, 12, 0, 38)
NavContainer.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
NavContainer.BorderSizePixel = 0
NavContainer.Parent = MainFrame

local NavCorner = Instance.new("UICorner")
NavCorner.CornerRadius = UDim.new(0, 6)
NavCorner.Parent = NavContainer

local NavLayout = Instance.new("UIListLayout")
NavLayout.FillDirection = Enum.FillDirection.Horizontal
NavLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
NavLayout.VerticalAlignment = Enum.VerticalAlignment.Center
NavLayout.SortOrder = Enum.SortOrder.LayoutOrder
NavLayout.Parent = NavContainer

local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, -24, 1, -94)
ContentContainer.Position = UDim2.new(0, 12, 0, 76)
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
	page.CanvasSize = UDim2.new(0, 0, 0, 240)
	page.ScrollBarThickness = 2
	page.Visible = false
	page.Parent = ContentContainer

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 6)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = page

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 2)
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
			btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
			btn.TextColor3 = Color3.fromRGB(240, 240, 245)
		else
			btn.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
			btn.TextColor3 = Color3.fromRGB(130, 130, 145)
		end
	end
end

local function createNavButton(name, text, order)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.48, 0, 0, 24)
	btn.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
	btn.Text = text
	btn.TextColor3 = Color3.fromRGB(130, 130, 145)
	btn.TextSize = 11
	btn.Font = Enum.Font.Code
	btn.LayoutOrder = order
	btn.Parent = NavContainer

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = btn

	btn.MouseButton1Click:Connect(function()
		switchPage(name)
	end)

	navButtons[name] = btn
	return btn
end

createNavButton("Combat", "Main", 1)
createNavButton("Settings", "Config", 2)
createPage("Combat")
createPage("Settings")

local function createButton(pageName, name, text, order)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.new(1, 0, 0, 32)
	button.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
	button.Text = text
	button.TextColor3 = Color3.fromRGB(200, 200, 210)
	button.TextSize = 11
	button.Font = Enum.Font.Code
	button.LayoutOrder = order
	button.Parent = pages[pageName]

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(45, 45, 55)
	stroke.Thickness = 1
	stroke.Parent = button

	return button
end

createButton("Combat", "EspButton", "ESP [OFF]", 1)
createButton("Combat", "AimlockButton", "Jammer Lock [OFF]", 2)
createButton("Combat", "SpawnButton", "Spawn Drone", 3)
createButton("Combat", "ExplodeButton", "Auto Explode [OFF]", 4)

local EspButton = pages["Combat"]:FindFirstChild("EspButton")
local AimlockButton = pages["Combat"]:FindFirstChild("AimlockButton")
local SpawnButton = pages["Combat"]:FindFirstChild("SpawnButton")
local ExplodeButton = pages["Combat"]:FindFirstChild("ExplodeButton")

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

local function disableDroneCollisions(drone)
	for _, part in ipairs(drone:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
		end
	end
end

local function enableDroneCollisions(drone)
	for _, part in ipairs(drone:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = true
		end
	end
end

local function createSlider(titleText, minVal, maxVal, defaultVal, isFloat, order, callback)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 42)
	container.BackgroundTransparency = 1
	container.LayoutOrder = order
	container.Parent = pages["Settings"]

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.6, 0, 0, 16)
	label.BackgroundTransparency = 1
	label.Text = titleText
	label.TextColor3 = Color3.fromRGB(180, 180, 190)
	label.TextSize = 11
	label.Font = Enum.Font.Code
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container

	local inputBox = Instance.new("TextBox")
	inputBox.Size = UDim2.new(0.35, 0, 0, 16)
	inputBox.Position = UDim2.new(0.65, 0, 0, 0)
	inputBox.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
	inputBox.Text = tostring(defaultVal)
	inputBox.TextColor3 = Color3.fromRGB(220, 220, 230)
	inputBox.TextSize = 11
	inputBox.Font = Enum.Font.Code
	inputBox.TextXAlignment = Enum.TextXAlignment.Right
	inputBox.Parent = container

	local boxCorner = Instance.new("UICorner")
	boxCorner.CornerRadius = UDim.new(0, 4)
	boxCorner.Parent = inputBox

	local sliderBg = Instance.new("Frame")
	sliderBg.Size = UDim2.new(1, 0, 0, 5)
	sliderBg.Position = UDim2.new(0, 0, 0, 22)
	sliderBg.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
	sliderBg.BorderSizePixel = 0
	sliderBg.Parent = container

	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(1, 0)
	bgCorner.Parent = sliderBg

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
	fill.BorderSizePixel = 0
	fill.Parent = sliderBg

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fill

	local sliding = false
	local currentVal = defaultVal

	local function setVisuals(val)
		local clampedVal = math.clamp(val, minVal, maxVal)
		currentVal = clampedVal
		local pct = (clampedVal - minVal) / (maxVal - minVal)
		fill.Size = UDim2.new(pct, 0, 1, 0)
		
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

TopBar.InputBegan:Connect(function(input)
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

TopBar.InputChanged:Connect(function(input)
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

local function addESP(target, isPlayer)
	if trackedDrones[target] or trackedPlayers[target] then return end

	local highlight = Instance.new("Highlight")
	highlight.Name = "VisualHighlight"
	highlight.FillColor = isPlayer and COLOR_PLAYER or COLOR_DANGER
	highlight.OutlineColor = isPlayer and COLOR_PLAYER or COLOR_DANGER
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = target

	local line = Drawing.new("Line")
	line.Color = isPlayer and COLOR_PLAYER or COLOR_DANGER
	line.Thickness = 1
	line.Transparency = 1
	line.Visible = false

	local text = Drawing.new("Text")
	text.Color = isPlayer and COLOR_PLAYER or COLOR_DANGER
	text.Size = 12
	text.Center = true
	text.Outline = true
	text.OutlineColor = Color3.fromRGB(0, 0, 0)
	text.Visible = false

	local data = {
		Highlight = highlight,
		Line = line,
		Text = text,
		IsPlayer = isPlayer
	}

	if isPlayer then
		trackedPlayers[target] = data
	else
		trackedDrones[target] = data
	end
end

local function removeESP(target)
	local data = trackedDrones[target] or trackedPlayers[target]
	if data then
		if data.Highlight then data.Highlight:Destroy() end
		if data.Line then data.Line:Remove() end
		if data.Text then data.Text:Remove() end
		trackedDrones[target] = nil
		trackedPlayers[target] = nil
	end
end

local function hideAllESP()
	for _, data in pairs(trackedDrones) do
		if data.Highlight then data.Highlight.Enabled = false end
		if data.Line then data.Line.Visible = false end
		if data.Text then data.Text.Visible = false end
	end
	for _, data in pairs(trackedPlayers) do
		if data.Highlight then data.Highlight.Enabled = false end
		if data.Line then data.Line.Visible = false end
		if data.Text then data.Text.Visible = false end
	end
end

local function onDroneAdded(child)
	if child:IsA("Model") and (string.find(child.Name, "Drone") or string.find(child.Name, "DronePlayer")) then
		addESP(child, false)
		if isMyDrone(child) then
			disableDroneCollisions(child)
			applyDroneSettings(child)
		end
	end
end

local function onPlayerAdded(player)
	if player ~= LocalPlayer then
		player.CharacterAdded:Connect(function(char)
			task.wait(1)
			addESP(char, true)
		end)
		if player.Character then
			addESP(player.Character, true)
		end
	end
end

for _, child in ipairs(getActiveDrones()) do
	onDroneAdded(child)
end

for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(player)
	if player.Character then
		removeESP(player.Character)
	end
end)

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

	local function processTracking(collection, isPlayer)
		for target, data in pairs(collection) do
			if espEnabled and target and target.Parent and target:IsA("Model") then
				local targetPos
				if isPlayer then
					local hrp = target:FindFirstChild("HumanoidRootPart")
					if hrp then targetPos = hrp.Position else continue end
				else
					targetPos = target:GetPivot().Position
				end

				local distance = (targetPos - cameraPos).Magnitude
				if distance <= MAX_ESP_DISTANCE then
					local screenPos, onScreen = Camera:WorldToViewportPoint(targetPos)
					if onScreen then
						local currentColor = isPlayer and COLOR_PLAYER or ((distance <= 1000) and COLOR_IN_RANGE or COLOR_DANGER)

						data.Highlight.Enabled = true
						data.Highlight.FillColor = currentColor
						data.Highlight.OutlineColor = currentColor

						data.Line.Color = currentColor
						data.Line.From = screenBottom
						data.Line.To = Vector2.new(screenPos.X, screenPos.Y)
						data.Line.Visible = true

						data.Text.Color = currentColor
						data.Text.Position = Vector2.new(screenPos.X, screenPos.Y - 20)
						data.Text.Text = (isPlayer and "Player [" or "Drone [") .. tostring(math.floor(distance)) .. "m]"
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
	end

	processTracking(trackedDrones, false)
	processTracking(trackedPlayers, true)

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

	if explodeToggleEnabled then
		local character = LocalPlayer.Character
		if character then
			local rootPart = character:FindFirstChild("HumanoidRootPart")
			if rootPart then
				local targetCFrame = rootPart.CFrame
				for _, drone in ipairs(getActiveDrones()) do
					pcall(function()
						enableDroneCollisions(drone)
						drone:PivotTo(targetCFrame)
					end)
				end
			end
		end
	end
end)

EspButton.MouseButton1Click:Connect(function()
	espEnabled = not espEnabled
	if espEnabled then
		EspButton.Text = "ESP [ON]"
	else
		EspButton.Text = "ESP [OFF]"
		hideAllESP()
	end
end)

AimlockButton.MouseButton1Click:Connect(function()
	aimlockEnabled = not aimlockEnabled
	if aimlockEnabled then
		AimlockButton.Text = "Jammer Lock [ON]"
	else
		AimlockButton.Text = "Jammer Lock [OFF]"
	end
end)

SpawnButton.MouseButton1Click:Connect(function()
	if PlayerDroneRemote then
		PlayerDroneRemote:FireServer("Wood1")
		task.spawn(function()
			local startTime = tick()
			while tick() - startTime < 10 do
				local myDrone = nil
				for _, drone in ipairs(getActiveDrones()) do
					if isMyDrone(drone) then
						local lifeStatus = drone:FindFirstChild("LifeStatus")
						if not lifeStatus or lifeStatus.Value then
							myDrone = drone
							break
						end
					end
				end
				if myDrone then
					disableDroneCollisions(myDrone)
					applyDroneSettings(myDrone)
					break
				end
				task.wait(0.1)
			end
		end)
	end
end)

ExplodeButton.MouseButton1Click:Connect(function()
	explodeToggleEnabled = not explodeToggleEnabled
	if explodeToggleEnabled then
		ExplodeButton.Text = "Auto Explode [ON]"
	else
		ExplodeButton.Text = "Auto Explode [OFF]"
	end
end)
