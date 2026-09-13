local Workspace = game:GetService("Workspace")

local DUMMY_NAME = "WalkingDummy"
local DUMMY_HEALTH = 100
local WALK_RADIUS = 40

local function createPart(model: Model, name: string, size: Vector3, color: BrickColor): BasePart
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.BrickColor = color
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = model
	return part
end

local function connectParts(jointParent: BasePart, name: string, part0: BasePart, part1: BasePart, c0: CFrame, c1: CFrame)
	local joint = Instance.new("Motor6D")
	joint.Name = name
	joint.Part0 = part0
	joint.Part1 = part1
	joint.C0 = c0
	joint.C1 = c1
	joint.Parent = jointParent
end

local function createDummy(): Model
	local existingDummy = Workspace:FindFirstChild(DUMMY_NAME)
	if existingDummy then
		existingDummy:Destroy()
	end

	local dummy = Instance.new("Model")
	dummy.Name = DUMMY_NAME

	local rootPart = createPart(dummy, "HumanoidRootPart", Vector3.new(2, 2, 1), BrickColor.new("Medium stone grey"))
	rootPart.Transparency = 1
	rootPart.CanCollide = false

	local torso = createPart(dummy, "Torso", Vector3.new(2, 2, 1), BrickColor.new("Bright blue"))
	local head = createPart(dummy, "Head", Vector3.new(2, 1, 1), BrickColor.new("Bright yellow"))
	local leftArm = createPart(dummy, "Left Arm", Vector3.new(1, 2, 1), BrickColor.new("Bright yellow"))
	local rightArm = createPart(dummy, "Right Arm", Vector3.new(1, 2, 1), BrickColor.new("Bright yellow"))
	local leftLeg = createPart(dummy, "Left Leg", Vector3.new(1, 2, 1), BrickColor.new("Bright green"))
	local rightLeg = createPart(dummy, "Right Leg", Vector3.new(1, 2, 1), BrickColor.new("Bright green"))

	local humanoid = Instance.new("Humanoid")
	humanoid.Name = "Humanoid"
	humanoid.MaxHealth = DUMMY_HEALTH
	humanoid.Health = DUMMY_HEALTH
	humanoid.RigType = Enum.HumanoidRigType.R6
	humanoid.Parent = dummy

	connectParts(torso, "RootJoint", rootPart, torso, CFrame.new(0, 0, 0), CFrame.new(0, 0, 0))
	connectParts(torso, "Neck", torso, head, CFrame.new(0, 1, 0), CFrame.new(0, -0.5, 0))
	connectParts(torso, "Left Shoulder", torso, leftArm, CFrame.new(-1, 0.5, 0), CFrame.new(0.5, 0.5, 0))
	connectParts(torso, "Right Shoulder", torso, rightArm, CFrame.new(1, 0.5, 0), CFrame.new(-0.5, 0.5, 0))
	connectParts(torso, "Left Hip", torso, leftLeg, CFrame.new(-0.5, -1, 0), CFrame.new(0, 1, 0))
	connectParts(torso, "Right Hip", torso, rightLeg, CFrame.new(0.5, -1, 0), CFrame.new(0, 1, 0))

	dummy.PrimaryPart = rootPart
	dummy.Parent = Workspace

	local spawnLocation = Workspace:FindFirstChildOfClass("SpawnLocation")
	local spawnPosition = if spawnLocation then spawnLocation.Position + Vector3.new(0, 3, 0) else Vector3.new(0, 5, 0)
	dummy:PivotTo(CFrame.new(spawnPosition))

	return dummy
end

local function getGroundPosition(origin: Vector3): Vector3
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	local result = Workspace:Raycast(origin + Vector3.new(0, 50, 0), Vector3.new(0, -200, 0), raycastParams)
	return if result then result.Position + Vector3.new(0, 3, 0) else origin
end

local dummy = createDummy()
local humanoid = dummy:FindFirstChildOfClass("Humanoid")
local rootPart = dummy.PrimaryPart

if humanoid and rootPart then
	while dummy.Parent do
		local offset = Vector3.new(math.random(-WALK_RADIUS, WALK_RADIUS), 0, math.random(-WALK_RADIUS, WALK_RADIUS))
		local destination = getGroundPosition(rootPart.Position + offset)
		humanoid:MoveTo(destination)
		humanoid.MoveToFinished:Wait()
		task.wait(math.random(1, 3))
	end
end