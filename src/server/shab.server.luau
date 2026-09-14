local Workspace = game:GetService("Workspace")

local SHABSTER_NAME = "Shabster"
local SHABSTER_HEALTH = 1
local RESPAWN_DELAY = 3
local WALK_RADIUS = 25

local function getSpawnPosition(): Vector3
	local spawnLocation = Workspace:FindFirstChildOfClass("SpawnLocation")
	if spawnLocation then
		return spawnLocation.Position + Vector3.new(8, 0, 0)
	end
	return Vector3.new(8, 4, 0)
end

local function createSnowball(model: Model, name: string, size: Vector3, position: Vector3): BasePart
	local snowball = Instance.new("Part")
	snowball.Name = name
	snowball.Shape = Enum.PartType.Ball
	snowball.Size = size
	snowball.Position = position
	snowball.Color = Color3.fromRGB(245, 250, 255)
	snowball.Material = Enum.Material.Snow
	snowball.TopSurface = Enum.SurfaceType.Smooth
	snowball.BottomSurface = Enum.SurfaceType.Smooth
	snowball.Parent = model
	return snowball
end

local function createPart(model: Model, name: string, size: Vector3, color: Color3, position: Vector3): BasePart
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = model
	return part
end

local function weldParts(part0: BasePart, part1: BasePart)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = part0
	weld.Part1 = part1
	weld.Parent = part0
end

local function createShabster(): Model
	local oldShabster = Workspace:FindFirstChild(SHABSTER_NAME)
	if oldShabster then
		oldShabster:Destroy()
	end

	local shabster = Instance.new("Model")
	shabster.Name = SHABSTER_NAME

	local spawnPosition = getSpawnPosition()

	local rootPart = createPart(shabster, "HumanoidRootPart", Vector3.new(2, 2, 1), Color3.new(1, 1, 1), spawnPosition + Vector3.new(0, 2.5, 0))
	rootPart.Transparency = 1
	rootPart.CanCollide = false

	local bottom = createSnowball(shabster, "BottomSnowball", Vector3.new(4, 3, 4), spawnPosition + Vector3.new(0, 1.5, 0))
	local middle = createSnowball(shabster, "MiddleSnowball", Vector3.new(3, 2.5, 3), spawnPosition + Vector3.new(0, 3.8, 0))
	local head = createSnowball(shabster, "Head", Vector3.new(2.25, 2.25, 2.25), spawnPosition + Vector3.new(0, 5.7, 0))

	local leftArm = createPart(shabster, "LeftStickArm", Vector3.new(0.25, 3, 0.25), Color3.fromRGB(92, 55, 30), spawnPosition + Vector3.new(-2.1, 4, 0))
	leftArm.CFrame *= CFrame.Angles(0, 0, math.rad(65))
	local rightArm = createPart(shabster, "RightStickArm", Vector3.new(0.25, 3, 0.25), Color3.fromRGB(92, 55, 30), spawnPosition + Vector3.new(2.1, 4, 0))
	rightArm.CFrame *= CFrame.Angles(0, 0, math.rad(-65))

	local hatBrim = createPart(shabster, "HatBrim", Vector3.new(2.8, 0.25, 2.8), Color3.fromRGB(15, 15, 18), spawnPosition + Vector3.new(0, 7, 0))
	hatBrim.Shape = Enum.PartType.Cylinder
	local hatTop = createPart(shabster, "HatTop", Vector3.new(1.8, 1.3, 1.8), Color3.fromRGB(8, 8, 10), spawnPosition + Vector3.new(0, 7.65, 0))
	hatTop.Shape = Enum.PartType.Cylinder

	local eyeColor = Color3.fromRGB(12, 12, 12)
	local leftEye = createPart(shabster, "LeftEye", Vector3.new(0.22, 0.22, 0.22), eyeColor, spawnPosition + Vector3.new(-0.4, 6, -1.05))
	local rightEye = createPart(shabster, "RightEye", Vector3.new(0.22, 0.22, 0.22), eyeColor, spawnPosition + Vector3.new(0.4, 6, -1.05))
	local nose = createPart(shabster, "CarrotNose", Vector3.new(0.3, 0.3, 0.9), Color3.fromRGB(255, 120, 20), spawnPosition + Vector3.new(0, 5.7, -1.2))
	nose.Shape = Enum.PartType.Cylinder
	nose.CFrame *= CFrame.Angles(math.rad(90), 0, 0)

	for _, part in { bottom, middle, head, leftArm, rightArm, hatBrim, hatTop, leftEye, rightEye, nose } do
		part.CanCollide = false
		weldParts(rootPart, part)
	end

	local humanoid = Instance.new("Humanoid")
	humanoid.Name = "Humanoid"
	humanoid.MaxHealth = SHABSTER_HEALTH
	humanoid.Health = SHABSTER_HEALTH
	humanoid.DisplayName = SHABSTER_NAME
	humanoid.Parent = shabster

	local healthBar = Instance.new("BillboardGui")
	healthBar.Name = "HealthBar"
	healthBar.Adornee = head
	healthBar.AlwaysOnTop = true
	healthBar.Size = UDim2.fromOffset(120, 28)
	healthBar.StudsOffset = Vector3.new(0, 1.6, 0)
	healthBar.Parent = shabster

	local healthText = Instance.new("TextLabel")
	healthText.BackgroundTransparency = 1
	healthText.Size = UDim2.fromScale(1, 1)
	healthText.Font = Enum.Font.GothamBold
	healthText.TextColor3 = Color3.new(1, 1, 1)
	healthText.TextScaled = true
	healthText.TextStrokeTransparency = 0.4
	healthText.Text = "1 / 1"
	healthText.Parent = healthBar

	shabster.PrimaryPart = rootPart
	shabster.Parent = Workspace

	local function getGroundPosition(origin: Vector3): Vector3
		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		raycastParams.FilterDescendantsInstances = { shabster }
		local result = Workspace:Raycast(origin + Vector3.new(0, 25, 0), Vector3.new(0, -60, 0), raycastParams)
		if result then
			return result.Position + Vector3.new(0, 3, 0)
		end
		return origin
	end

	local function walkLoop()
		while shabster.Parent do
			if humanoid.Health <= 0 then
				break
			end
			local homePosition = getSpawnPosition()
			local offset = Vector3.new(math.random(-WALK_RADIUS, WALK_RADIUS), 0, math.random(-WALK_RADIUS, WALK_RADIUS))
			local destination = getGroundPosition(homePosition + offset)
			humanoid:MoveTo(destination)
			humanoid.MoveToFinished:Wait()
			task.wait(math.random(0.5, 1.5))
		end
	end

	task.spawn(walkLoop)

	humanoid.Died:Connect(function()
		task.delay(RESPAWN_DELAY, function()
			if not Workspace:FindFirstChild(SHABSTER_NAME) then
				createShabster()
			end
		end)
	end)

	return shabster
end

createShabster()
