-- ============================================
-- MeleeClient.client.lua
-- Detecta clic izquierdo y envía golpe al servidor
-- Maneja efectos visuales del combate
-- Ubicación: src/client/MeleeClient.client.lua
-- ============================================

local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera    = workspace.CurrentCamera

local remotes      = ReplicatedStorage:WaitForChild("Remotes")
local onMeleeHit   = remotes:WaitForChild("MeleeHit")
local onMeleeEffect = remotes:WaitForChild("MeleeEffect")

-- ════════════════════════════════════════════════
--  ESTADO
-- ════════════════════════════════════════════════
local isDown         = false   -- si el jugador está tumbado
local hasWeapon      = false   -- si lleva arma equipada
local attackCooldown = false

-- Escuchar si el jugador fue tumbado
local remotes2 = ReplicatedStorage:WaitForChild("Remotes")
remotes2:WaitForChild("PlayerDowned").OnClientEvent:Connect(function(downedPlayer)
	if downedPlayer == player then
		isDown = true
	end
end)
remotes2:WaitForChild("PlayerRevived").OnClientEvent:Connect(function(revivedPlayer)
	if revivedPlayer == player then
		isDown = false
	end
end)

-- ════════════════════════════════════════════════
--  CLIC IZQUIERDO → GOLPE
-- ════════════════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
	if isDown then return end
	if attackCooldown then return end

	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	attackCooldown = true

	-- Determinar tipo de arma
	local weaponType = hasWeapon and "weapon" or "fist"
	local cooldown   = hasWeapon and 0.8 or 0.6

	-- Enviar al servidor
	onMeleeHit:FireServer(weaponType)

	-- Mostrar indicador de daño hecho (amarillo)
	local dmg = hasWeapon and 25 or 10
	local showDmg = ReplicatedStorage:FindFirstChild("ShowDamageIndicator")
	if showDmg then showDmg:Fire(dmg) end

	-- Animación de golpe (inclinar la cámara levemente)
	local originalCFrame = camera.CFrame
	TweenService:Create(camera,
		TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ CFrame = camera.CFrame * CFrame.Angles(math.rad(-3), 0, 0) }):Play()
	task.wait(0.08)
	TweenService:Create(camera,
		TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ CFrame = originalCFrame }):Play()

	-- Cooldown visual
	task.wait(cooldown)
	attackCooldown = false
end)

-- ════════════════════════════════════════════════
--  EFECTOS VISUALES AL GOLPEAR
-- ════════════════════════════════════════════════
onMeleeEffect.OnClientEvent:Connect(function(attacker, weaponType, attackCFrame)
	-- Sonido de golpe (solo si está cerca)
	local myChar = player.Character
	if not myChar then return end
	local myRoot = myChar:FindFirstChild("HumanoidRootPart")
	local attackerChar = attacker.Character
	if not attackerChar then return end
	local attackerRoot = attackerChar:FindFirstChild("HumanoidRootPart")
	if not myRoot or not attackerRoot then return end

	local dist = (myRoot.Position - attackerRoot.Position).Magnitude
	if dist > 20 then return end

	-- Sonido
	local soundId = weaponType == "weapon" and "rbxassetid://9120386446" or "rbxassetid://9120386446"
	local sound = Instance.new("Sound")
	sound.SoundId  = soundId
	sound.Volume   = math.clamp(1 - dist / 20, 0.1, 1)
	sound.Parent   = attackerRoot
	sound:Play()
	game:GetService("Debris"):AddItem(sound, 2)
end)

-- ════════════════════════════════════════════════
--  EQUIPAR / DESEQUIPAR ARMA
-- (llama esto desde el sistema de inventario)
-- ════════════════════════════════════════════════
local equipWeaponEvent = Instance.new("BindableEvent")
equipWeaponEvent.Name   = "EquipWeapon"
equipWeaponEvent.Parent = ReplicatedStorage
equipWeaponEvent.Event:Connect(function(equipped)
	hasWeapon = equipped
	print("[CLIENT] Arma", equipped and "equipada" or "guardada")
end)

print("[CLIENT] MeleeClient listo — clic izquierdo para golpear.")