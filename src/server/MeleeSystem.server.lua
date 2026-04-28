-- ============================================
-- MeleeSystem.server.lua
-- Sistema de combate cuerpo a cuerpo
-- · Puños y arma cuerpo a cuerpo
-- · Clic izquierdo para golpear
-- · Daña jugadores y enemigos
-- Ubicación: src/server/MeleeSystem.server.lua
-- ============================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris            = game:GetService("Debris")

-- ════════════════════════════════════════════════
--  CONFIGURACIÓN
-- ════════════════════════════════════════════════
local Config = {
	-- Puños
	FIST_DAMAGE     = 10,
	FIST_RANGE      = 5,
	FIST_COOLDOWN   = 0.6,

	-- Arma cuerpo a cuerpo
	WEAPON_DAMAGE   = 25,
	WEAPON_RANGE    = 6,
	WEAPON_COOLDOWN = 0.8,

	-- Knockback
	KNOCKBACK_FORCE = 30,
}

-- ════════════════════════════════════════════════
--  REMOTE EVENTS
-- ════════════════════════════════════════════════
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local function getOrCreate(name, class)
	local e = remotes:FindFirstChild(name)
	if e then return e end
	local n = Instance.new(class)
	n.Name = name; n.Parent = remotes
	return n
end

local onMeleeHit     = getOrCreate("MeleeHit",     "RemoteEvent")  -- cliente → servidor
local onMeleeEffect  = getOrCreate("MeleeEffect",  "RemoteEvent")  -- servidor → clientes (efectos visuales)
local onPlayerDamaged = remotes:WaitForChild("PlayerDamaged")
local onPlayerDied    = remotes:WaitForChild("PlayerDied")
local onPlayerDowned  = remotes:WaitForChild("PlayerDowned")

-- ════════════════════════════════════════════════
--  COOLDOWNS
-- ════════════════════════════════════════════════
local cooldowns     = {}   -- { [userId] = tick() }
local downedPlayers = {}   -- se sincroniza con DamageSystem via BindableEvent

-- BindableEvent para tumbar jugadores (lo escucha DamageSystem)
local requestDown = Instance.new("BindableEvent")
requestDown.Name   = "RequestDown"
requestDown.Parent = ReplicatedStorage

task.spawn(function()
	task.wait(2)
	print("[MELEE] MeleeSystem listo.")
end)

-- ════════════════════════════════════════════════
--  FUNCIÓN: aplicar daño
-- ════════════════════════════════════════════════
local function applyDamage(targetPlayer, amount, attackerRootPart, targetRootPart)
	if not targetPlayer then return end
	local character = targetPlayer.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	-- No dañar a jugadores tumbados
	local isDownedValue = character:FindFirstChild("IsDowned")
	if isDownedValue and isDownedValue.Value then return end

	-- Knockback
	if targetRootPart and attackerRootPart then
		local direction = (targetRootPart.Position - attackerRootPart.Position).Unit
		local bv = Instance.new("BodyVelocity")
		bv.Velocity = direction * Config.KNOCKBACK_FORCE + Vector3.new(0, 10, 0)
		bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
		bv.P        = 1e4
		bv.Parent   = targetRootPart
		Debris:AddItem(bv, 0.15)
	end

	local newHealth = math.max(1, humanoid.Health - amount)
	humanoid.Health = newHealth

	onPlayerDamaged:FireClient(targetPlayer, newHealth, humanoid.MaxHealth)

	print(string.format("[MELEE] %s golpeado — daño: %d | vida: %.0f",
		targetPlayer.Name, amount, newHealth))

	-- Si llega al mínimo → tumbar (nunca matar directo)
	if humanoid.Health <= 1 then
		local isDown = character:FindFirstChild("IsDowned")
		if not isDown or not isDown.Value then
			requestDown:Fire(targetPlayer)
		end
	end
end

local function applyDamageToEnemy(enemyModel, amount, attackerRootPart)
	local humanoid = enemyModel:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	humanoid.Health = math.max(0, humanoid.Health - amount)

	-- Knockback al enemigo
	local rootPart = enemyModel:FindFirstChild("HumanoidRootPart")
	if rootPart and attackerRootPart then
		local direction = (rootPart.Position - attackerRootPart.Position).Unit
		local bv = Instance.new("BodyVelocity")
		bv.Velocity = direction * Config.KNOCKBACK_FORCE
		bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
		bv.P        = 1e4
		bv.Parent   = rootPart
		Debris:AddItem(bv, 0.15)
	end

	print(string.format("[MELEE] Enemigo %s golpeado — daño: %d | vida: %.0f",
		enemyModel.Name, amount, humanoid.Health))
end

-- ════════════════════════════════════════════════
--  ESCUCHAR GOLPES DESDE EL CLIENTE
-- ════════════════════════════════════════════════
onMeleeHit.OnServerEvent:Connect(function(attacker, weaponType)
	-- weaponType: "fist" o "weapon"
	local userId = attacker.UserId

	-- Verificar cooldown
	local now      = tick()
	local cooldown = weaponType == "weapon" and Config.WEAPON_COOLDOWN or Config.FIST_COOLDOWN
	if (now - (cooldowns[userId] or 0)) < cooldown then return end
	cooldowns[userId] = now

	-- Verificar que el atacante no está tumbado
	local attackerChar = attacker.Character
	if not attackerChar then return end
	local isDownedVal = attackerChar:FindFirstChild("IsDowned")
	if isDownedVal and isDownedVal.Value then return end

	local attackerRoot = attackerChar:FindFirstChild("HumanoidRootPart")
	if not attackerRoot then return end

	local range  = weaponType == "weapon" and Config.WEAPON_RANGE  or Config.FIST_RANGE
	local damage = weaponType == "weapon" and Config.WEAPON_DAMAGE or Config.FIST_DAMAGE
	local attackerPos = attackerRoot.Position

	-- Efecto visual para todos los clientes cercanos
	onMeleeEffect:FireAllClients(attacker, weaponType, attackerRoot.CFrame)

	-- ── Buscar targets en rango ───────────────
	local hitSomething = false

	-- Jugadores
	for _, target in ipairs(Players:GetPlayers()) do
		if target == attacker then continue end
		local targetChar = target.Character
		if not targetChar then continue end
		local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
		if not targetRoot then continue end

		local dist = (attackerPos - targetRoot.Position).Magnitude
		if dist <= range then
			applyDamage(target, damage, attackerRoot, targetRoot)
			hitSomething = true
		end
	end

	-- Enemigos (modelos en workspace con tag "Enemy" o carpeta Enemies)
	local enemiesFolder = workspace:FindFirstChild("Enemies")
	if enemiesFolder then
		for _, enemy in ipairs(enemiesFolder:GetChildren()) do
			local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
			if not enemyRoot then continue end
			local dist = (attackerPos - enemyRoot.Position).Magnitude
			if dist <= range then
				applyDamageToEnemy(enemy, damage, attackerRoot)
				hitSomething = true
			end
		end
	end

	if hitSomething then
		print("[MELEE]", attacker.Name, "golpeó con", weaponType)
	end
end)

print("[SERVER] MeleeSystem cargado.")
print("[SERVER] Puños: " .. Config.FIST_DAMAGE .. " dmg | Arma: " .. Config.WEAPON_DAMAGE .. " dmg")