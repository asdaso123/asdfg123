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

local speedMultiplier = 2
local maxSpdVal = 100
local rotRatioVal = 1

local COLOR_DANGER = Color3.fromRGB(240, 60, 60)

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
				if name == "MaxSpeed" then return maxSpdVal end
				if name == "Acceleration" then return speedMultiplier end
				if name == "RotateRatio" then return rotRatioVal end
			end
		end
	end
	return oldIndex(t, k)
end)
setreadonly(mt, true)

local Gui = Instance.new("ScreenGui")
Gui.Name = "UI_Core"
Gui.ResetOnSpawn = false

local getHuiFunc = gethui or get_hidden_gui
if getHuiFunc then
	Gui.Parent = getHuiFunc()
else
	pcall(function() Gui.Parent = CoreGui end)
	if not Gui.Parent then Gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
end

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 320, 0, 440)
Frame.Position = UDim2.new(0.5, -160, 0.5, -220)
Frame.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
Frame.BorderSizePixel = 0
Frame.Parent = Gui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 8)
Corner.Parent = Frame

local Bar = Instance.new("Frame")
Bar.Size = UDim2.new(1, 0, 0, 36)
Bar.BackgroundTransparency = 1
Bar.Parent = Frame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Panel"
Title.TextColor3 = Color3.fromRGB(220, 220, 225)
Title.TextSize = 13
Title.Font = Enum.Font.Code
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Bar

local Exit = Instance.new("TextButton")
Exit.Size = UDim2.new(0, 24, 0, 24)
Exit.AnchorPoint = Vector2.new(1, 0.5)
Exit.Position = UDim2.new(1, -8, 0.5, 0)
Exit.BackgroundTransparency = 1
Exit.Text = "×"
Exit.TextColor3 = Color3.fromRGB(150, 150, 160)
Exit.TextSize = 18
Exit.Font = Enum.Font.Code
Exit.Parent = Bar

Exit.MouseButton1Click:Connect(function()
	_G.DroneControllerLoaded = false
	Gui:Destroy()
end)

local List = Instance.new("UIListLayout")
List.SortOrder = Enum.SortOrder.LayoutOrder
List.Padding = UDim.new(0, 6)
List.Parent = Frame

Bar.LayoutOrder = 0

local Padding = Instance.new("UIPadding")
Padding.PaddingTop = UDim.new(0, 42)
Padding.PaddingLeft = UDim.new(0, 12)
Padding.PaddingRight = UDim.new(0, 12)
Padding.PaddingBottom = UDim.new(0, 12)
Padding.Parent = Frame

local function mkBtn(name, text, order)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(1, 0, 0, 32)
	btn.BackgroundColor3 = Color3.fromRGB(34, 34, 40)
	btn.BorderSizePixel = 0
	btn.Text = text
	btn.TextColor3 = Color3.fromRGB(180, 180, 190)
	btn.TextSize = 12
	btn.Font = Enum.Font.Code
	btn.LayoutOrder = order
	btn.Parent = Frame

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 4)
	c.Parent = btn

	return btn
end

mkBtn("EspBtn", "ESP: OFF", 1)
mkBtn("LockBtn", "Jammer Lock: OFF", 2)
mkBtn("DroneLockBtn", "Drone Aim: OFF", 3)
mkBtn("SpawnBtn", "Spawn Drone", 4)
mkBtn("TeleportBtn", "Teleport Drone", 5)
mkBtn("ExplodeBtn", "Explode Drones", 6)

local EspBtn = Frame:FindFirstChild("EspBtn")
local LockBtn = Frame:FindFirstChild("LockBtn")
local DroneLockBtn = Frame:FindFirstChild("DroneLockBtn")
local SpawnBtn = Frame:FindFirstChild("SpawnBtn")
local TeleportBtn = Frame:FindFirstChild("TeleportBtn")
local ExplodeBtn = Frame:FindFirstChild("ExplodeBtn")

local function getActiveDrones()
	local t = {}
	if workspace:FindFirstChild("Drones") then
		for _, v in ipairs(workspace.Drones:GetChildren()) do
			if v:IsA("Model") then table.insert(t, v) end
		end
	end
	for _, v in ipairs(workspace:GetChildren()) do
		if v:IsA("Model") and (string.find(v.Name, "Drone") or string.find(v.Name, "DronePlayer")) then
			local found = false
			for _, x in ipairs(t) do if x == v then found = true break end end
			if not found then table.insert(t, v) end
		end
	end
	return t
end

local function isMyDrone(d)
	if not d or not d:IsA("Model") then return false end
	local p = d:FindFirstChild("Player") or d:FindFirstChild("Operator")
	if p then
		if p:IsA("ObjectValue") and p.Value == LocalPlayer then return true
		elseif (p:IsA("StringValue") or p:IsA("IntValue")) and (tostring(p.Value) == LocalPlayer.Name or tostring(p.Value) == tostring(LocalPlayer.UserId)) then return true end
	end
	if string.find(d.Name, LocalPlayer.Name) then return true end
	return false
end

local function applySettings(d)
	if not d or not d.Parent then return end
	local s = d:FindFirstChild("Settings")
	if s then
		local f = s:FindFirstChild("Fly")
		if f then
			local a = f:FindFirstChild("Acceleration")
			if a then a.Value = speedMultiplier end
			local m = f:FindFirstChild("MaxSpeed")
			if m then m.Value = maxSpdVal end
			local r = f:FindFirstChild("RotateRatio")
			if r then r.Value = rotRatioVal end
		end
	end
end

local function setCollisions(d, state)
	for _, p in ipairs(d:GetDescendants()) do
		if p:IsA("BasePart") then p.CanCollide = state end
	end
end

local function getMyDrone()
	for _, d in ipairs(getActiveDrones()) do
		if isMyDrone(d) then
			local l = d:FindFirstChild("LifeStatus")
			if not l or l.Value then return d end
		end
	end
	return nil
end

local function addEsp(d)
	if trackedDrones[d] then return end
	local h = Instance.new("Highlight")
	h.FillColor = COLOR_DANGER
	h.OutlineColor = COLOR_DANGER
	h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	h.Parent = d

	local l = Drawing.new("Line")
	l.Color = COLOR_DANGER
	l.Thickness = 1
	l.Visible = false

	local t = Drawing.new("Text")
	t.Color = COLOR_DANGER
	t.Size = 13
	t.Center = true
	t.Outline = true
	t.Visible = false

	trackedDrones[d] = {Highlight = h, Line = l, Text = t}
end

local function removeEsp(d)
	local data = trackedDrones[d]
	if data then
		if data.Highlight then data.Highlight:Destroy() end
		if data.Line then data.Line:Remove() end
		if data.Text then data.Text:Remove() end
		trackedDrones[d] = nil
	end
end

local function addPlayerEsp(p)
	if trackedPlayers[p] then return end
	local h = Instance.new("Highlight")
	h.FillColor = COLOR_DANGER
	h.OutlineColor = COLOR_DANGER
	h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	h.Parent = p.Character

	local l = Drawing.new("Line")
	l.Color = COLOR_DANGER
	l.Thickness = 1
	l.Visible = false

	local t = Drawing.new("Text")
	t.Color = COLOR_DANGER
	t.Size = 13
	t.Center = true
	t.Outline = true
	t.Visible = false

	trackedPlayers[p] = {Highlight = h, Line = l, Text = t}
end

local function removePlayerEsp(p)
	local data = trackedPlayers[p]
	if data then
		if data.Highlight then data.Highlight:Destroy() end
		if data.Line then data.Line:Remove() end
		if data.Text then data.Text:Remove() end
		trackedPlayers[p] = nil
	end
end

local function onAdd(c)
	if c:IsA("Model") and (string.find(c.Name, "Drone") or string.find(c.Name, "DronePlayer")) then
		addEsp(c)
		if isMyDrone(c) then
			setCollisions(c, false)
			applySettings(c)
		end
	end
end

for _, c in ipairs(getActiveDrones()) do onAdd(c) end
if workspace:FindFirstChild("Drones") then
	workspace.Drones.ChildAdded:Connect(onAdd)
	workspace.Drones.ChildRemoved:Connect(removeEsp)
end
workspace.ChildAdded:Connect(onAdd)
workspace.ChildRemoved:Connect(removeEsp)

for _, p in ipairs(Players:GetPlayers()) do
	if p ~= LocalPlayer then
		if p.Character then addPlayerEsp(p) end
		p.CharacterAdded:Connect(function()
			task.wait(1)
			addPlayerEsp(p)
		end)
	end
end

Players.PlayerAdded:Connect(function(p)
	if p ~= LocalPlayer then
		p.CharacterAdded:Connect(function()
			task.wait(1)
			addPlayerEsp(p)
		end)
	end
end)

Players.PlayerRemoving:Connect(function(p)
	removePlayerEsp(p)
end)

RunService.RenderStepped:Connect(function()
	local camPos = Camera.CFrame.Position
	local vp = Camera.ViewportSize
	local bot = Vector2.new(vp.X / 2, vp.Y)

	for d, data in pairs(trackedDrones) do
		if espEnabled and d and d.Parent then
			local pos = d:GetPivot().Position
			local dist = (pos - camPos).Magnitude
			local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
			if onScreen and dist <= 500000 then
				data.Highlight.Enabled = true
				data.Line.From = bot
				data.Line.To = Vector2.new(screenPos.X, screenPos.Y)
				data.Line.Visible = true
				data.Text.Position = Vector2.new(screenPos.X, screenPos.Y - 20)
				data.Text.Text = math.floor(dist) .. "s"
				data.Text.Visible = true
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

	for p, data in pairs(trackedPlayers) do
		if espEnabled and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
			local hrp = p.Character.HumanoidRootPart
			local pos = hrp.Position
			local dist = (pos - camPos).Magnitude
			local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
			if onScreen and dist <= 500000 then
				data.Highlight.Enabled = true
				data.Line.From = bot
				data.Line.To = Vector2.new(screenPos.X, screenPos.Y)
				data.Line.Visible = true
				data.Text.Position = Vector2.new(screenPos.X, screenPos.Y - 20)
				data.Text.Text = p.Name .. " [" .. math.floor(dist) .. "s]"
				data.Text.Visible = true
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
		local char = LocalPlayer.Character
		local jammer = char and (char:FindFirstChild("Jammer") or LocalPlayer.Backpack:FindFirstChild("Jammer"))
		if jammer then
			local target = nil
			local minDist = math.huge
			for _, d in ipairs(getActiveDrones()) do
				if not isMyDrone(d) then
					local l = d:FindFirstChild("LifeStatus")
					if l and l.Value then
						local dist = (d:GetPivot().Position - camPos).Magnitude
						if dist < minDist then minDist = dist target = d end
					end
				end
			end
			if target then
				Camera.CFrame = CFrame.new(Camera.CFrame.Position, target:GetPivot().Position)
				local ev = jammer:FindFirstChild("Events")
				if ev and ev:FindFirstChild("FanEvent") then ev.FanEvent:FireServer(30) end
				if JammedDroneRemote then JammedDroneRemote:FireServer(target, Camera.CFrame) end
			end
		end
	end

	if droneAimlockEnabled then
		local myD = getMyDrone()
		if myD then
			local myPos = myD:GetPivot().Position
			local targetP = nil
			local minDist = math.huge
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
					local hum = p.Character:FindFirstChildOfClass("Humanoid")
					if hum and hum.Health > 0 then
						local dist = (p.Character.HumanoidRootPart.Position - myPos).Magnitude
						if dist < minDist then minDist = dist targetP = p end
					end
				end
			end
			if targetP then
				local targetPos = targetP.Character.HumanoidRootPart.Position
				Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPos)
				myD:PivotTo(CFrame.new(myPos, targetPos))
			end
		end
	end
end)

EspBtn.MouseButton1Click:Connect(function()
	espEnabled = not espEnabled
	EspBtn.Text = espEnabled and "ESP: ON" or "ESP: OFF"
end)

LockBtn.MouseButton1Click:Connect(function()
	aimlockEnabled = not aimlockEnabled
	LockBtn.Text = aimlockEnabled and "Jammer Lock: ON" or "Jammer Lock: OFF"
end)

DroneLockBtn.MouseButton1Click:Connect(function()
	droneAimlockEnabled = not droneAimlockEnabled
	DroneLockBtn.Text = droneAimlockEnabled and "Drone Aim: ON" or "Drone Aim: OFF"
end)

SpawnBtn.MouseButton1Click:Connect(function()
	if PlayerDroneRemote then
		PlayerDroneRemote:FireServer("Wood1")
		task.spawn(function()
			local start = tick()
			while tick() - start < 10 do
				local d = getMyDrone()
				if d then setCollisions(d, false) applySettings(d) break end
				task.wait(0.1)
			end
		end)
	end
end)

TeleportBtn.MouseButton1Click:Connect(function()
	local char = LocalPlayer.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		local rootPart = char.HumanoidRootPart
		for _, d in ipairs(getActiveDrones()) do
			if isMyDrone(d) then
				pcall(function()
					setCollisions(d, false)
					d:PivotTo(rootPart.CFrame + Vector3.new(0, 3, 0))
				end)
			end
		end
	end
end)

ExplodeBtn.MouseButton1Click:Connect(function()
	local char = LocalPlayer.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		local cf = char.HumanoidRootPart.CFrame
		for _, d in ipairs(getActiveDrones()) do
			pcall(function()
				setCollisions(d, true)
				d:PivotTo(cf)
			end)
		end
	end
end)

local dragging, dragInput, dragStart, startPos
Frame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = Frame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then dragging = false end
		end)
	end
end)

Frame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
		Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)
