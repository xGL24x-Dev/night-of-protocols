-- ============================================
-- InputController.client.lua
-- Script de CLIENTE
-- Maneja: correr, feedback visual de daño
-- Solo corre en el dispositivo del jugador
-- ============================================

local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local player     = Players.LocalPlayer
local character  = player.Character or player.CharacterAdded:Wait()
local humanoid   = character:WaitForChild("Humanoid")

-- ── ESPERAR que los RemoteEvents estén listos ────
local remotes       = ReplicatedStorage:WaitForChild("Remotes")
local onDamaged     = remotes:WaitForChild("PlayerDamaged")
local onDied        = remotes:WaitForChild("PlayerDied")

-- ── UI: crear pantalla de daño (flash rojo) ──────
local playerGui  = player:WaitForChild("PlayerGui")

local damageGui  = Instance.new("ScreenGui")
damageGui.Name   = "DamageEffect"
damageGui.ResetOnSpawn = false
damageGui.Parent = playerGui

local damageFrame        = Instance.new("Frame")
damageFrame.Size         = UDim2.new(1, 0, 1, 0)
damageFrame.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
damageFrame.BackgroundTransparency = 1   -- invisible por defecto
damageFrame.BorderSizePixel = 0
damageFrame.Parent = damageGui

-- ── FUNCIÓN: flash rojo al recibir daño ─────────
local function playDamageEffect()
	-- Aparece rápido y desaparece suavemente
	damageFrame.BackgroundTransparency = 0.3
	local tween = TweenService:Create(
		damageFrame,
		TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 1 }
	)
	tween:Play()
end

-- ── FUNCIÓN: pantalla de muerte ──────────────────
local function playDeathEffect()
	damageFrame.BackgroundTransparency = 0
	task.wait(3)
	local tween = TweenService:Create(
		damageFrame,
		TweenInfo.new(1, Enum.EasingStyle.Quad),
		{ BackgroundTransparency = 1 }
	)
	tween:Play()
end

-- ── SPRINT: Shift para correr ────────────────────
local isSprinting = false

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end  -- ignorar si está en chat u otro UI

	if input.KeyCode == Enum.KeyCode.LeftShift then
		isSprinting = true
		humanoid.WalkSpeed = GameConfig.PLAYER_SPRINTSPEED
		print("[CLIENT] Sprint activado")
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftShift then
		isSprinting = false
		humanoid.WalkSpeed = GameConfig.PLAYER_WALKSPEED
		print("[CLIENT] Sprint desactivado")
	end
end)

-- ── ESCUCHAR eventos del servidor ────────────────
onDamaged.OnClientEvent:Connect(function(currentHealth, maxHealth)
	playDamageEffect()
	print("[CLIENT] Salud actual:", currentHealth .. "/" .. maxHealth)
end)

onDied.OnClientEvent:Connect(function()
	playDeathEffect()
	print("[CLIENT] Jugador muerto - esperando respawn...")
end)

-- ── Reconectar al hacer respawn ───────────────────
player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoid  = newCharacter:WaitForChild("Humanoid")
	isSprinting = false
	print("[CLIENT] Personaje recargado.")
end)

print("[CLIENT] InputController cargado correctamente.")