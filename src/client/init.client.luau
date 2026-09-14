local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local fireEvent = ReplicatedStorage:WaitForChild("GunFireEvent")
local rocketFireEvent = ReplicatedStorage:WaitForChild("RocketFireEvent")

local function connectTool(tool: Instance)
	if not tool:IsA("Tool") or tool:GetAttribute("Connected") then
		return
	end
	if tool.Name ~= "TrainingPistol" and tool.Name ~= "RocketLauncher" then
		return
	end

	tool:SetAttribute("Connected", true)
	tool.Activated:Connect(function()
		local camera = Workspace.CurrentCamera
		if camera then
			local event = if tool.Name == "RocketLauncher" then rocketFireEvent else fireEvent
			event:FireServer(camera.CFrame.LookVector)
		end
	end)
end

player.Backpack.ChildAdded:Connect(connectTool)
player.CharacterAdded:Connect(function(character)
	character.ChildAdded:Connect(connectTool)
end)

for _, item in player.Backpack:GetChildren() do
	connectTool(item)
end



