local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

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
	return true
end

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

local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")
local drone = getMyCurrentDrone()

if drone then
	local targetCFrame = rootPart.CFrame * CFrame.new(0, 0, -5)
	pcall(function()
		drone:PivotTo(targetCFrame)
	end)
end
