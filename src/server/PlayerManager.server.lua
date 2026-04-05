-- ============================================
-- PlayerManager.server.lua
-- Script de SERVIDOR
-- Maneja: salud, daño, muerte y respawn
-- ============================================

local Players       = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Importar configuración compartida
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

-- ── EVENTOS (comunicación servidor <-> cliente) ──
-- Estos RemoteEvents permiten que el cliente reciba notificaciones
local remotes = Instance.new("Folder")
remotes.Name  = "Remotes"
remotes.Parent = ReplicatedStorage

local onPlayerDamaged = Instance.new("RemoteEvent")
onPlayerDamaged.Name  = "PlayerDamaged"
onPlayerDamaged.Parent = remotes

local onPlayerDied = Instance.new("RemoteEvent")
onPlayerDied.Name  = "PlayerDied"
onPlayerDied.Parent = remotes

-- ── FUNCIÓN: configurar jugador al entrar ────────
local function setupPlayer(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")

		-- Aplicar stats desde GameConfig
		humanoid.MaxHealth = GameConfig.PLAYER_HEALTH
		humanoid.Health    = GameConfig.PLAYER_HEALTH
		humanoid.WalkSpeed = GameConfig.PLAYER_WALKSPEED

		print("[SERVER] Jugador configurado:", player.Name)

		-- ── Detectar cuando recibe daño ─────────
		humanoid.HealthChanged:Connect(function(newHealth)
			local damage = humanoid.MaxHealth - newHealth
			if damage > 0 then
				-- Notificar al cliente que recibió daño
				onPlayerDamaged:FireClient(player, newHealth, GameConfig.PLAYER_HEALTH)
				print("[SERVER] Daño recibido por", player.Name, "- Salud:", newHealth)
			end
		end)

		-- ── Detectar muerte ─────────────────────
		humanoid.Died:Connect(function()
			print("[SERVER] " .. player.Name .. " ha muerto.")
			onPlayerDied:FireClient(player)

			-- Respawn después de 5 segundos
			task.wait(5)
			player:LoadCharacter()
		end)
	end)
end

-- ── INICIALIZAR jugadores que ya están y los nuevos ──
Players.PlayerAdded:Connect(setupPlayer)
for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end

print("[SERVER] PlayerManager cargado correctamente.")