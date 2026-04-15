-- ============================================
-- DamageSystem.server.lua
-- Maneja:
--   · Daño por caída (por pisos, % de vida)
--   · Daño por trampas/objetos en el mapa
--   · Sistema de revivir compañeros
-- Ubicación: src/server/DamageSystem.server.lua
-- ============================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

-- ════════════════════════════════════════════════
--  CONFIGURACIÓN
-- ════════════════════════════════════════════════

-- 1 piso ≈ 10 studs en Roblox
local FLOOR_HEIGHT = 10

-- Tabla de daño por pisos (% de vida máxima)
local FALL_TIERS = {
	{ minStuds =  20, damage = 0.05  },   -- 2 pisos  →  5%
	{ minStuds =  40, damage = 0.25  },   -- 4 pisos  → 25%
	{ minStuds =  80, damage = 0.50  },   -- 8 pisos  → 50%
	{ minStuds = 120, damage = 0.70  },   -- 12 pisos → 70%
	{ minStuds = 160, damage = 1.00  },   -- más alto → muerte
}

local Config = {
	FALL_MIN_VELOCITY  = 45,    -- velocidad mínima de impacto (evita daño al saltar)
	TRAP_COOLDOWN      = 1.5,   -- segundos entre golpes del mismo objeto
	REVIVE_TIME        = 5,     -- segundos para revivir a un compañero
	REVIVE_RANGE       = 8,     -- studs máximos para poder revivir
	DOWNED_TIME        = 30,    -- segundos antes de morir si nadie revive
}

-- ════════════════════════════════════════════════
--  REMOTE EVENTS
-- ════════════════════════════════════════════════
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local function getOrCreate(name, class)
	local existing = remotes:FindFirstChild(name)
	if existing then return existing end
	local e = Instance.new(class)
	e.Name   = name
	e.Parent = remotes
	return e
end

local onPlayerDamaged  = getOrCreate("PlayerDamaged",  "RemoteEvent")
local onPlayerDied     = getOrCreate("PlayerDied",     "RemoteEvent")
local onPlayerDowned   = getOrCreate("PlayerDowned",   "RemoteEvent")
local onPlayerRevived  = getOrCreate("PlayerRevived",  "RemoteEvent")
local onReviveProgress = getOrCreate("ReviveProgress", "RemoteEvent")
local requestRevive    = getOrCreate("RequestRevive",  "RemoteEvent")
local cancelRevive     = getOrCreate("CancelRevive",   "RemoteEvent")

-- ════════════════════════════════════════════════
--  ESTADO DE JUGADORES TUMBADOS
-- ════════════════════════════════════════════════
local downedPlayers    = {}
local reviveConnections = {}

-- ════════════════════════════════════════════════
--  FUNCIÓN: aplicar daño
-- ════════════════════════════════════════════════
local function applyDamage(player, amount, source)
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end
	if downedPlayers[player.UserId] then return end

	local newHealth = math.max(0, humanoid.Health - amount)
	humanoid.Health = newHealth

	onPlayerDamaged:FireClient(player, newHealth, humanoid.MaxHealth)

	print(string.format("[SERVER] %s recibió %d de daño por %s. Salud: %.0f/%.0f",
		player.Name, amount, source, newHealth, humanoid.MaxHealth))

	if newHealth <= 0 then
		onPlayerDied:FireClient(player)
	end
end

-- ════════════════════════════════════════════════
--  SISTEMA DE TUMBADO
-- ════════════════════════════════════════════════
local function downPlayer(player)
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	if downedPlayers[player.UserId] then return end

	humanoid.Health    = 1
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0

	downedPlayers[player.UserId] = {
		player     = player,
		character  = character,
		timeLeft   = Config.DOWNED_TIME,
		isReviving = false,
	}

	onPlayerDowned:FireAllClients(player, Config.DOWNED_TIME)
	print("[SERVER]", player.Name, "está tumbado —", Config.DOWNED_TIME, "segundos para morir")

	task.spawn(function()
		while downedPlayers[player.UserId] do
			task.wait(1)
			local data = downedPlayers[player.UserId]
			if not data then break end

			data.timeLeft = data.timeLeft - 1
			onPlayerDowned:FireAllClients(player, data.timeLeft)

			if data.timeLeft <= 0 then
				downedPlayers[player.UserId] = nil
				if humanoid then humanoid.Health = 0 end
				onPlayerDied:FireClient(player)
				print("[SERVER]", player.Name, "murió — nadie lo revivió")
				break
			end
		end
	end)
end

-- ════════════════════════════════════════════════
--  SISTEMA DE REVIVIR
-- ════════════════════════════════════════════════
local function stopRevive(reviverPlayer)
	local id = reviverPlayer.UserId
	if reviveConnections[id] then
		reviveConnections[id]:Disconnect()
		reviveConnections[id] = nil
	end
end

local function startRevive(reviverPlayer, downedPlayer)
	local reviverId = reviverPlayer.UserId
	if reviveConnections[reviverId] then return end

	local data = downedPlayers[downedPlayer.UserId]
	if not data then return end

	data.isReviving = true
	local elapsed   = 0

	print("[SERVER]", reviverPlayer.Name, "reviviendo a", downedPlayer.Name)

	reviveConnections[reviverId] = RunService.Heartbeat:Connect(function(dt)
		elapsed = elapsed + dt
		local progress = math.clamp(elapsed / Config.REVIVE_TIME, 0, 1)

		onReviveProgress:FireClient(reviverPlayer, downedPlayer, progress)
		onReviveProgress:FireClient(downedPlayer, downedPlayer, progress)

		-- Cancelar si se alejó
		local revChar  = reviverPlayer.Character
		local downChar = downedPlayer.Character
		if not revChar or not downChar then
			stopRevive(reviverPlayer)
			if data then data.isReviving = false end
			return
		end

		local dist = (revChar:GetPivot().Position - downChar:GetPivot().Position).Magnitude
		if dist > Config.REVIVE_RANGE then
			stopRevive(reviverPlayer)
			if data then data.isReviving = false end
			onReviveProgress:FireClient(reviverPlayer, downedPlayer, -1)
			print("[SERVER] Revive cancelado — demasiado lejos")
			return
		end

		if progress >= 1 then
			-- Revivido exitosamente
			stopRevive(reviverPlayer)
			downedPlayers[downedPlayer.UserId] = nil

			local humanoid = downChar:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.Health    = humanoid.MaxHealth * 0.3
				humanoid.WalkSpeed = 16
				humanoid.JumpPower = 50
			end

			onPlayerRevived:FireAllClients(downedPlayer, reviverPlayer)
			print("[SERVER]", reviverPlayer.Name, "revivió a", downedPlayer.Name, "con 30% de vida")
		end
	end)
end

requestRevive.OnServerEvent:Connect(function(reviverPlayer, targetPlayer)
	if not targetPlayer then return end
	if not downedPlayers[targetPlayer.UserId] then return end

	local revChar  = reviverPlayer.Character
	local downChar = targetPlayer.Character
	if not revChar or not downChar then return end

	local dist = (revChar:GetPivot().Position - downChar:GetPivot().Position).Magnitude
	if dist <= Config.REVIVE_RANGE then
		startRevive(reviverPlayer, targetPlayer)
	end
end)

cancelRevive.OnServerEvent:Connect(function(player)
	stopRevive(player)
end)

-- ════════════════════════════════════════════════
--  DAÑO POR CAÍDA (por pisos, % de vida)
-- ════════════════════════════════════════════════
local function getFallDamagePercent(studs)
	local percent = 0
	for i = #FALL_TIERS, 1, -1 do
		if studs >= FALL_TIERS[i].minStuds then
			percent = FALL_TIERS[i].damage
			break
		end
	end
	return percent
end

local function setupFallDamage(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		local rootPart = character:WaitForChild("HumanoidRootPart")

		humanoid.EvaluateStateMachine = true

		local wasFalling    = false
		local fallStartY    = 0
		local lastVelocityY = 0

		local conn
		conn = RunService.Heartbeat:Connect(function()
			if not character.Parent then
				conn:Disconnect()
				return
			end

			local velY     = rootPart.AssemblyLinearVelocity.Y
			local onGround = humanoid.FloorMaterial ~= Enum.Material.Air

			if velY < -10 and not wasFalling then
				wasFalling = true
				fallStartY = rootPart.Position.Y
			end

			if wasFalling and onGround and lastVelocityY < -Config.FALL_MIN_VELOCITY then
				wasFalling = false
				local fallen  = fallStartY - rootPart.Position.Y
				local floors  = math.floor(fallen / FLOOR_HEIGHT)
				local percent = getFallDamagePercent(fallen)

				print(string.format("[FALL] %s | %.1f studs (~%d pisos) | daño: %d%%",
					player.Name, fallen, floors, percent * 100))

				if percent > 0 then
					local damage = math.floor(humanoid.MaxHealth * percent)
					local result = humanoid.Health - damage

					if percent >= 1 or result <= 0 then
						downPlayer(player)
					else
						applyDamage(player, damage, "caída ("..floors.." pisos)")
					end
				end
			end

			if onGround then wasFalling = false end
			lastVelocityY = velY
		end)

		humanoid.Died:Connect(function()
			conn:Disconnect()
			downedPlayers[player.UserId] = nil
		end)
	end)
end

-- ════════════════════════════════════════════════
--  TRAMPAS Y OBJETOS DAÑINOS
-- ════════════════════════════════════════════════
-- CÓMO USAR EN EL MAPA:
-- Selecciona cualquier Part → Properties → Attributes → + Add Attribute
-- Nombre: "Damage" | Tipo: Number | Valor: ej. 20
-- Opcional: "DamageSource" (String) para nombre personalizado

local trapCooldowns = {}

local function registerTrap(part)
	local damage = part:GetAttribute("Damage")
	if not damage then return end
	local source = part:GetAttribute("DamageSource") or part.Name

	part.Touched:Connect(function(hit)
		local character = hit.Parent
		local player    = Players:GetPlayerFromCharacter(character)
		if not player then return end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then return end

		local key     = tostring(player.UserId) .. "_" .. tostring(part:GetDebugId())
		local lastHit = trapCooldowns[key] or 0
		if tick() - lastHit < Config.TRAP_COOLDOWN then return end
		trapCooldowns[key] = tick()

		applyDamage(player, damage, source)
	end)

	print("[SERVER] Trampa registrada:", part.Name, "| Daño:", damage)
end

local function scanForTraps(parent)
	for _, obj in ipairs(parent:GetDescendants()) do
		if obj:IsA("BasePart") and obj:GetAttribute("Damage") then
			registerTrap(obj)
		end
	end
end

workspace.DescendantAdded:Connect(function(obj)
	if obj:IsA("BasePart") and obj:GetAttribute("Damage") then
		registerTrap(obj)
	end
end)

-- ════════════════════════════════════════════════
--  INICIALIZAR
-- ════════════════════════════════════════════════
Players.PlayerAdded:Connect(function(player)
	setupFallDamage(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	setupFallDamage(player)
end

Players.PlayerRemoving:Connect(function(player)
	downedPlayers[player.UserId] = nil
	stopRevive(player)
end)

task.wait(2)
scanForTraps(workspace)

print("[SERVER] DamageSystem cargado.")
print("[SERVER] Daño por pisos: 2p=5% | 4p=25% | 8p=50% | 12p=70% | +alto=muerte")
print("[SERVER] Revivir: mantén E cerca del compañero tumbado ("..Config.REVIVE_TIME.."s)")