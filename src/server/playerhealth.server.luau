local Players = game:GetService("Players")

local PLAYER_HEALTH = 100

local function setPlayerHealth(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.MaxHealth = PLAYER_HEALTH
	humanoid.Health = PLAYER_HEALTH
end

local function setupPlayer(player: Player)
	player.CharacterAdded:Connect(setPlayerHealth)
	if player.Character then
		setPlayerHealth(player.Character)
	end
end

Players.PlayerAdded:Connect(setupPlayer)

for _, player in Players:GetPlayers() do
	setupPlayer(player)
end
