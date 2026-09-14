local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local DAMAGE = 100
local BLAST_RADIUS = 10
local FIRE_COOLDOWN = 1
local LAUNCHER_NAME = "RocketLauncher"
local FIRE_EVENT_NAME = "RocketFireEvent"

local fireEvent = ReplicatedStorage:FindFirstChild(FIRE_EVENT_NAME) :: RemoteEvent
if not fireEvent then
	fireEvent = Instance.new("RemoteEvent")
	fireEvent.Name = FIRE_EVENT_NAME
	fireEvent.Parent = ReplicatedStorage
end

local lastShot: {[Player]: number} = {}

local function makePart(parent: Instance, name: string, size: Vector3, color: Color3, cframe: CFrame): BasePart
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.CFrame = cframe
	part.Material = Enum.Material.Metal
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function weldPart(handle: BasePart, part: BasePart)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = part
	weld.Parent = handle
end

local function addLauncherModel(tool: Tool)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.6, 1.2, 0.6)
	handle.Color = Color3.fromRGB(30, 32, 35)
	handle.Material = Enum.Material.Metal
	handle.CanCollide = false
	handle.Parent = tool

	local tube = makePart(tool, "RocketTube", Vector3.new(0.85, 3.2, 0.85), Color3.fromRGB(70, 74, 78), CFrame.new(0, 1.7, 0))
	local rearTube = makePart(tool, "RearTube", Vector3.new(1, 0.35, 1), Color3.fromRGB(25, 27, 30), CFrame.new(0, 0.1, 0))
	local frontRing = makePart(tool, "FrontRing", Vector3.new(1, 0.28, 1), Color3.fromRGB(20, 22, 24), CFrame.new(0, 3.25, 0))
	local grip = makePart(tool, "Grip", Vector3.new(0.65, 1.2, 0.65), Color3.fromRGB(25, 25, 27), CFrame.new(0, -0.8, 0))
	local sight = makePart(tool, "Sight", Vector3.new(0.15, 0.35, 0.15), Color3.fromRGB(190, 190, 190), CFrame.new(0, 3.55, 0))

	for _, part in { tube, rearTube, frontRing, grip, sight } do
		part.CanCollide = false
		weldPart(handle, part)
	end

	local muzzleAttachment = Instance.new("Attachment")
	muzzleAttachment.Name = "MuzzleAttachment"
	muzzleAttachment.Position = Vector3.new(0, 0.2, 0)
	muzzleAttachment.Parent = frontRing

	local flash = Instance.new("ParticleEmitter")
	flash.Name = "RocketFlash"
	flash.Color = ColorSequence.new(Color3.fromRGB(255, 220, 80), Color3.fromRGB(255, 70, 15))
	flash.LightEmission = 1
	flash.Lifetime = NumberRange.new(0.08, 0.14)
	flash.Rate = 0
	flash.Speed = NumberRange.new(12, 18)
	flash.SpreadAngle = Vector2.new(20, 20)
	flash.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	flash.Parent = muzzleAttachment

	local sound = Instance.new("Sound")
	sound.Name = "RocketSound"
	sound.SoundId = "rbxassetid://138186576"
	sound.Volume = 0.8
	sound.RollOffMaxDistance = 150
	sound.Parent = frontRing

	tool.RequiresHandle = true
	tool.CanBeDropped = false
end

local function createLauncher(player: Player)
	local tool = Instance.new("Tool")
	tool.Name = LAUNCHER_NAME
	tool.ToolTip = "Launch rocket"
	addLauncherModel(tool)
	tool.Parent = player:WaitForChild("Backpack")
end

local function createPickup()
	local pickup = Instance.new("Part")
	pickup.Name = "RocketLauncherPickup"
	pickup.Size = Vector3.new(2, 0.4, 2)
	pickup.Transparency = 1
	pickup.CanCollide = false
	pickup.Anchored = true
	local spawnLocation = Workspace:FindFirstChildOfClass("SpawnLocation")
	pickup.Position = if spawnLocation then spawnLocation.Position + Vector3.new(-4, 1, 0) else Vector3.new(6, 3, 0)
	pickup.Parent = Workspace

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Pick Up"
	prompt.ObjectText = "Rocket Launcher"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.Parent = pickup

	local display = Instance.new("Model")
	display.Name = "RocketLauncherDisplay"
	display.Parent = pickup
	local handle = makePart(display, "Handle", Vector3.new(0.6, 1.2, 0.6), Color3.fromRGB(30, 32, 35), pickup.CFrame)
	handle.Anchored = true
	local tube = makePart(display, "RocketTube", Vector3.new(0.85, 3.2, 0.85), Color3.fromRGB(70, 74, 78), pickup.CFrame * CFrame.new(0, 1.7, 0))
	local grip = makePart(display, "Grip", Vector3.new(0.65, 1.2, 0.65), Color3.fromRGB(25, 25, 27), pickup.CFrame * CFrame.new(0, -0.8, 0))
	for _, part in { tube, grip } do
		part.CanCollide = false
		weldPart(handle, part)
	end
	display.PrimaryPart = handle
	display:PivotTo(pickup.CFrame * CFrame.Angles(0, 0, math.rad(90)))

	prompt.Triggered:Connect(function(player: Player)
		if player.Character and player.Character:FindFirstChildOfClass("Tool") then
			return
		end
		createLauncher(player)
		pickup:Destroy()
	end)
end

local function createExplosion(position: Vector3, ownerCharacter: Model)
	local effect = Instance.new("Part")
	effect.Name = "RocketExplosion"
	effect.Shape = Enum.PartType.Ball
	effect.Size = Vector3.new(1, 1, 1)
	effect.Color = Color3.fromRGB(255, 120, 20)
	effect.Material = Enum.Material.Neon
	effect.Anchored = true
	effect.CanCollide = false
	effect.Position = position
	effect.Parent = Workspace

	local light = Instance.new("PointLight")
	light.Brightness = 12
	light.Range = 18
	light.Color = Color3.fromRGB(255, 140, 40)
	light.Parent = effect

	local particles = Instance.new("ParticleEmitter")
	particles.Color = ColorSequence.new(Color3.fromRGB(255, 220, 80), Color3.fromRGB(190, 30, 10))
	particles.Lifetime = NumberRange.new(0.2, 0.5)
	particles.Speed = NumberRange.new(15, 28)
	particles.SpreadAngle = Vector2.new(180, 180)
	particles.Rate = 0
	particles.Texture = "rbxasset://textures/particles/fire_main.dds"
	particles.Parent = effect
	particles:Emit(40)
	Debris:AddItem(effect, 0.5)

	local explosionSound = Instance.new("Sound")
	explosionSound.SoundId = "rbxassetid://138186576"
	explosionSound.Volume = 1
	explosionSound.RollOffMaxDistance = 160
	explosionSound.Parent = effect
	explosionSound:Play()

	local damagedHumanoids: {[Humanoid]: boolean} = {}
	for _, part in Workspace:GetPartBoundsInRadius(position, BLAST_RADIUS) do
		local model = part:FindFirstAncestorOfClass("Model")
		local humanoid = model and model:FindFirstChildOfClass("Humanoid")
		if humanoid and model ~= ownerCharacter and not damagedHumanoids[humanoid] then
			damagedHumanoids[humanoid] = true
			humanoid:TakeDamage(DAMAGE)
		end
	end
end

local function launchRocket(player: Player, direction: Vector3)
	local character = player.Character
	local tool = character and character:FindFirstChild(LAUNCHER_NAME)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local tube = tool and tool:FindFirstChild("FrontRing")
	if not tool or not humanoid or humanoid.Health <= 0 or not tube or not tube:IsA("BasePart") then
		return
	end

	local rocket = Instance.new("Part")
	rocket.Name = "Rocket"
	rocket.Shape = Enum.PartType.Cylinder
	rocket.Size = Vector3.new(0.35, 1.6, 0.35)
	rocket.Color = Color3.fromRGB(185, 45, 25)
	rocket.Material = Enum.Material.Metal
	rocket.CanCollide = false
	rocket.Anchored = true
	rocket.CFrame = CFrame.lookAt(tube.Position + direction.Unit * 1.5, tube.Position + direction.Unit * 2.5) * CFrame.Angles(math.rad(90), 0, 0)
	rocket.Parent = Workspace

	local trail = Instance.new("Trail")
	local front = Instance.new("Attachment")
	front.Position = Vector3.new(0, 0.8, 0)
	front.Parent = rocket
	local back = Instance.new("Attachment")
	back.Position = Vector3.new(0, -0.8, 0)
	back.Parent = rocket
	trail.Attachment0 = front
	trail.Attachment1 = back
	trail.Lifetime = 0.2
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 170, 40), Color3.fromRGB(100, 100, 100))
	trail.Parent = rocket

	local lastPosition = rocket.Position
	local elapsed = 0
	local connection: RBXScriptConnection
	connection = RunService.Heartbeat:Connect(function(deltaTime)
		if not rocket.Parent then
			connection:Disconnect()
			return
		end
		elapsed += deltaTime
		local nextPosition = lastPosition + direction.Unit * 180 * deltaTime
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { character, rocket }
		local result = Workspace:Raycast(lastPosition, nextPosition - lastPosition, params)
		if result or elapsed > 5 then
			connection:Disconnect()
			local impactPosition = if result then result.Position else nextPosition
			rocket:Destroy()
			createExplosion(impactPosition, character)
			return
		end
		rocket.CFrame = CFrame.lookAt(nextPosition, nextPosition + direction.Unit) * CFrame.Angles(math.rad(90), 0, 0)
		lastPosition = nextPosition
	end)
end

fireEvent.OnServerEvent:Connect(function(player: Player, direction: Vector3)
	local now = os.clock()
	if lastShot[player] and now - lastShot[player] < FIRE_COOLDOWN then
		return
	end
	if direction.Magnitude < 0.9 or direction.Magnitude > 1.1 then
		return
	end
	local character = player.Character
	local tool = character and character:FindFirstChild(LAUNCHER_NAME)
	if not tool then
		return
	end
	lastShot[player] = now
	local tube = tool:FindFirstChild("FrontRing")
	if tube and tube:IsA("BasePart") then
		local flash = tube:FindFirstChild("MuzzleAttachment")
		local sound = tube:FindFirstChild("RocketSound")
		if flash and flash:IsA("Attachment") then
			local emitter = flash:FindFirstChild("RocketFlash")
			if emitter and emitter:IsA("ParticleEmitter") then
				emitter:Emit(20)
			end
		end
		if sound and sound:IsA("Sound") then
			sound:Play()
		end
	end
	launchRocket(player, direction.Unit)
end)

Players.PlayerRemoving:Connect(function(player)
	lastShot[player] = nil
end)

createPickup()
