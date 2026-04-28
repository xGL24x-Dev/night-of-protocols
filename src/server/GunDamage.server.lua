-- ============================================
-- GunDamage.server.lua
-- Solo maneja el daño de los disparos
-- Ubicación: src/server/GunDamage.server.lua
-- ============================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris            = game:GetService("Debris")

local DAMAGE      = 35
local RANGE       = 300
local FIRE_RATE   = 0.15

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local onShoot = remotes:WaitForChild("GunShoot")
local onPlayerDamaged = remotes:WaitForChild("PlayerDamaged")

local requestDown = ReplicatedStorage:FindFirstChild("RequestDown") or
	(function()
		local e = Instance.new("BindableEvent")
		e.Name = "RequestDown"; e.Parent = ReplicatedStorage
		return e
	end)()

local cooldowns = {}

onShoot.OnServerEvent:Connect(function(player, origin, direction)
	-- Verificar que tiene el arma
	local char = player.Character
	if not char then return end
	if not char:FindFirstChild("HasGlock") then return end

	-- Cooldown anti-spam
	local now = tick()
	if (now - (cooldowns[player.UserId] or 0)) < FIRE_RATE then return end
	cooldowns[player.UserId] = now

	-- Anti-cheat básico
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	if (root.Position - origin).Magnitude > 20 then return end

	-- Raycast en el servidor
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { char }
	params.FilterType = Enum.RaycastFilterType.Exclude

	local result = workspace:Raycast(origin, direction.Unit * RANGE, params)
	if not result then return end

	local hit = result.Instance
	local model = hit:FindFirstAncestorOfClass("Model")
	if not model then return end

	-- Daño a jugador
	local targetPlayer = Players:GetPlayerFromCharacter(model)
	if targetPlayer and targetPlayer ~= player then
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then return end
		local isDown = model:FindFirstChild("IsDowned")
		if isDown and isDown.Value then return end

		local newHp = math.max(1, humanoid.Health - DAMAGE)
		humanoid.Health = newHp
		onPlayerDamaged:FireClient(targetPlayer, newHp, humanoid.MaxHealth)

		print(string.format("[GUN] %s disparó a %s — daño: %d | vida: %.0f",
			player.Name, targetPlayer.Name, DAMAGE, newHp))

		if newHp <= 1 then
			requestDown:Fire(targetPlayer)
		end
		return
	end

	-- Daño a enemigo
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		humanoid.Health = math.max(0, humanoid.Health - DAMAGE)
		print(string.format("[GUN] Enemigo %s — daño: %d | vida: %.0f",
			model.Name, DAMAGE, humanoid.Health))
	end
end)

-- Limpiar cooldown al salir
Players.PlayerRemoving:Connect(function(player)
	cooldowns[player.UserId] = nil
end)

print("[SERVER] GunDamage cargado — daño:", DAMAGE)