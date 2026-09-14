local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local DAMAGE = 10
local FIRE_COOLDOWN = 0.25
local GUN_NAME = "TrainingPistol"
local FIRE_EVENT_NAME = "GunFireEvent"
local SHOT_SOUND_ID = "rbxassetid://2920959"

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

local function addGunModel(tool: Tool)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.45, 1, 0.45)
	handle.Color = Color3.fromRGB(25, 25, 28)
	handle.Material = Enum.Material.Metal
	handle.CanCollide = false
	handle.Parent = tool

	local receiver = makePart(tool, "Receiver", Vector3.new(0.8, 1.7, 0.5), Color3.fromRGB(55, 58, 64), CFrame.new(0, 0.65, 0))
	local barrel = makePart(tool, "Barrel", Vector3.new(0.32, 1.3, 0.32), Color3.fromRGB(18, 18, 20), CFrame.new(0, 1.95, 0))
	local muzzle = makePart(tool, "Muzzle", Vector3.new(0.42, 0.25, 0.42), Color3.fromRGB(12, 12, 14), CFrame.new(0, 2.7, 0))
	local grip = makePart(tool, "Grip", Vector3.new(0.6, 1.3, 0.55), Color3.fromRGB(35, 35, 38), CFrame.new(0, -0.8, 0) * CFrame.Angles(math.rad(-10), 0, 0))
	local magazine = makePart(tool, "Magazine", Vector3.new(0.38, 0.8, 0.38), Color3.fromRGB(20, 20, 22), CFrame.new(0, -1.25, 0))
	local sight = makePart(tool, "FrontSight", Vector3.new(0.12, 0.25, 0.12), Color3.fromRGB(180, 180, 180), CFrame.new(0, 2.62, 0))

	for _, part in { receiver, barrel, muzzle, grip, magazine, sight } do
		part.CanCollide = false
		weldPart(handle, part)
	end

	local muzzleAttachment = Instance.new("Attachment")
	muzzleAttachment.Name = "MuzzleAttachment"
	muzzleAttachment.Position = Vector3.new(0, 0.15, 0)
	muzzleAttachment.Parent = muzzle

	local flash = Instance.new("ParticleEmitter")
	flash.Name = "MuzzleFlash"
	flash.Color = ColorSequence.new(Color3.fromRGB(255, 220, 90), Color3.fromRGB(255, 90, 20))
	flash.LightEmission = 1
	flash.Lifetime = NumberRange.new(0.04, 0.08)
	flash.Rate = 0
	flash.Speed = NumberRange.new(8, 12)
	flash.SpreadAngle = Vector2.new(25, 25)
	flash.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	flash.Parent = muzzleAttachment

	local light = Instance.new("PointLight")
	light.Name = "MuzzleLight"
	light.Brightness = 0
	light.Color = Color3.fromRGB(255, 190, 90)
	light.Range = 8
	light.Parent = muzzle

	local sound = Instance.new("Sound")
	sound.Name = "ShotSound"
	sound.SoundId = SHOT_SOUND_ID
	sound.Volume = 0.7
	sound.RollOffMaxDistance = 100
	sound.Parent = muzzle

	tool:SetAttribute("MuzzlePart", muzzle.Name)
	tool.RequiresHandle = true
	tool.CanBeDropped = false
end

local function createGun(player: Player): Tool
	local tool = Instance.new("Tool")
	tool.Name = GUN_NAME
	tool.ToolTip = "Press to fire"
	addGunModel(tool)
	tool.Parent = player:WaitForChild("Backpack")
	return tool
end

local function createPickup()
	local pickup = Instance.new("Part")
	pickup.Name = "GunPickup"
	pickup.Size = Vector3.new(2, 0.4, 2)
	pickup.Transparency = 1
	pickup.CanCollide = false
	pickup.Anchored = true
	local spawnLocation = Workspace:FindFirstChildOfClass("SpawnLocation")
	pickup.Position = if spawnLocation then spawnLocation.Position + Vector3.new(4, 1, 0) else Vector3.new(0, 3, 0)
	pickup.Parent = Workspace

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Pick Up"
	prompt.ObjectText = "Training Pistol"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.Parent = pickup

	local displayTool = Instance.new("Model")
	displayTool.Name = "PistolDisplay"
	displayTool.Parent = pickup

	local handle = makePart(displayTool, "Handle", Vector3.new(0.45, 1, 0.45), Color3.fromRGB(25, 25, 28), pickup.CFrame)
	handle.Anchored = true
	local barrel = makePart(displayTool, "Barrel", Vector3.new(0.32, 1.8, 0.32), Color3.fromRGB(18, 18, 20), pickup.CFrame * CFrame.new(0, 0.9, 0))
	local grip = makePart(displayTool, "Grip", Vector3.new(0.6, 1.3, 0.55), Color3.fromRGB(35, 35, 38), pickup.CFrame * CFrame.new(0, -0.85, 0))
	for _, part in { barrel, grip } do
		part.CanCollide = false
		weldPart(handle, part)
	end
	displayTool.PrimaryPart = handle
	displayTool:PivotTo(pickup.CFrame * CFrame.Angles(0, math.rad(90), 0))

	prompt.Triggered:Connect(function(player: Player)
		if player.Character and player.Character:FindFirstChildOfClass("Tool") then
			return
		end
		createGun(player)
		pickup:Destroy()
	end)
end

local function showImpact(position: Vector3, normal: Vector3)
	local impact = Instance.new("Part")
	impact.Name = "BulletImpact"
	impact.Shape = Enum.PartType.Ball
	impact.Size = Vector3.new(0.2, 0.2, 0.2)
	impact.Color = Color3.fromRGB(255, 190, 70)
	impact.Material = Enum.Material.Neon
	impact.Anchored = true
	impact.CanCollide = false
	impact.Position = position + normal * 0.05
	impact.Parent = Workspace
	Debris:AddItem(impact, 0.12)
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
	local tool = character and character:FindFirstChild(GUN_NAME)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local muzzle = tool and tool:FindFirstChild("Muzzle")
	if not tool or not humanoid or humanoid.Health <= 0 or not muzzle or not muzzle:IsA("BasePart") then
		return
	end

	lastShot[player] = now
	local origin = muzzle.Position
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { character }
	local result = Workspace:Raycast(origin, direction.Unit * 500, raycastParams)

	local flash = muzzle:FindFirstChild("MuzzleAttachment")
	local sound = muzzle:FindFirstChild("ShotSound")
	local light = muzzle:FindFirstChild("MuzzleLight")
	if flash and flash:IsA("Attachment") then
		local emitter = flash:FindFirstChild("MuzzleFlash")
		if emitter and emitter:IsA("ParticleEmitter") then
			emitter:Emit(12)
		end
	end
	if sound and sound:IsA("Sound") then
		sound:Play()
	end
	if light and light:IsA("PointLight") then
		light.Brightness = 5
		task.delay(0.06, function()
			if light.Parent then
				light.Brightness = 0
			end
		end)
	end

	if result then
		local hitHumanoid = result.Instance.Parent:FindFirstChildOfClass("Humanoid")
		if hitHumanoid then
			hitHumanoid:TakeDamage(DAMAGE)
		end
		showImpact(result.Position, result.Normal)
	end
end)

createPickup()
