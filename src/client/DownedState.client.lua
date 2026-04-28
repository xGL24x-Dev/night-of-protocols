-- ============================================
-- DownedState.client.lua
-- Maneja el estado tumbado del jugador:
-- · Bloquea movimiento al caer/morir
-- · Quita el parpadeo rojo al revivir
-- · Recuperación gradual de vida al revivir
-- · Animación de tirado en el piso
-- Ubicación: src/client/DownedState.client.lua
-- ============================================

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local StarterGui        = game:GetService("StarterGui")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes      = ReplicatedStorage:WaitForChild("Remotes")
local onDowned     = remotes:WaitForChild("PlayerDowned")
local onRevived    = remotes:WaitForChild("PlayerRevived")
local onDied       = remotes:WaitForChild("PlayerDied")

-- ════════════════════════════════════════════════
--  ESTADO
-- ════════════════════════════════════════════════
local isDown       = false
local recoveryConn = nil

-- ════════════════════════════════════════════════
--  HELPERS
-- ════════════════════════════════════════════════
local function getHumanoid()
	local char = player.Character
	if not char then return nil end
	return char:FindFirstChildOfClass("Humanoid")
end

local function getRootPart()
	local char = player.Character
	if not char then return nil end
	return char:FindFirstChild("HumanoidRootPart")
end

-- Quitar TODOS los flashes rojos de la pantalla
local function clearFlashes()
	local gui = playerGui:FindFirstChild("HUDGui")
	if gui then
		for _, obj in ipairs(gui:GetDescendants()) do
			if obj:IsA("Frame") and obj.ZIndex == 99 then
				obj:Destroy()
			end
		end
	end
	-- También limpiar cualquier frame rojo de pantalla completa
	for _, gui2 in ipairs(playerGui:GetChildren()) do
		for _, obj in ipairs(gui2:GetDescendants()) do
			if obj:IsA("Frame") and obj.ZIndex >= 90 and
				obj.BackgroundColor3 == Color3.fromRGB(180,0,0) then
				obj:Destroy()
			end
		end
	end
end

-- ════════════════════════════════════════════════
--  AL QUEDAR TUMBADO
-- ════════════════════════════════════════════════
local function onDownedState()
	isDown = true
	local humanoid = getHumanoid()
	local rootPart = getRootPart()
	if not humanoid or not rootPart then return end

	-- Bloquear movimiento completamente
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.AutoRotate = false

	-- Deshabilitar controles del jugador
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	local controls = require(player.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("ControlModule"))
	pcall(function() controls:Disable() end)

	-- Marcar en el character para que otros scripts lo lean
	local isDownedFlag = Instance.new("BoolValue")
	isDownedFlag.Name   = "IsDowned"
	isDownedFlag.Value  = true
	isDownedFlag.Parent = player.Character

	-- Animar al jugador como si estuviera tirado
	-- Inclinar el HumanoidRootPart 90 grados (boca abajo)
	local originalCFrame = rootPart.CFrame
	local downedCFrame   = CFrame.new(originalCFrame.Position) *
		CFrame.Angles(math.rad(90), originalCFrame:ToEulerAnglesYXZ())

	TweenService:Create(rootPart,
		TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ CFrame = downedCFrame }):Play()

	-- Fijar el personaje en el suelo con un BodyPosition
	local bp = Instance.new("BodyPosition")
	bp.Name        = "DownedLock"
	bp.Position    = rootPart.Position
	bp.MaxForce    = Vector3.new(1e5, 1e5, 1e5)
	bp.P           = 1e4
	bp.D           = 1e3
	bp.Parent      = rootPart

	print("[CLIENT] Jugador tumbado — movimiento bloqueado")
end

-- ════════════════════════════════════════════════
--  AL SER REVIVIDO
-- ════════════════════════════════════════════════
local function onRevivedState(reviverPlayer)
	isDown = false

	local humanoid = getHumanoid()
	local rootPart = getRootPart()
	if not humanoid then return end

	-- Quitar flag de tumbado
	local flag = player.Character and player.Character:FindFirstChild("IsDowned")
	if flag then flag:Destroy() end

	-- Quitar el BodyPosition que lo fijaba al suelo
	if rootPart then
		local bp = rootPart:FindFirstChild("DownedLock")
		if bp then bp:Destroy() end

		-- Animar levantarse
		TweenService:Create(rootPart,
			TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ CFrame = CFrame.new(rootPart.Position) *
				CFrame.Angles(0, rootPart.CFrame:ToEulerAnglesYXZ()) }):Play()
	end

	-- Restaurar movimiento
	humanoid.WalkSpeed  = 16
	humanoid.JumpPower  = 50
	humanoid.AutoRotate = true

	-- Reactivar controles
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
	local controls = require(player.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("ControlModule"))
	pcall(function() controls:Enable() end)

	-- ── Quitar parpadeo rojo INMEDIATAMENTE ──
	clearFlashes()

	-- También limpiar la viñeta del ReviveGui
	local reviveGui = playerGui:FindFirstChild("ReviveGui")
	if reviveGui then
		local vignette = reviveGui:FindFirstChild("Vignette")
		if vignette then
			TweenService:Create(vignette,
				TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ BackgroundTransparency = 1 }):Play()
			task.wait(0.5)
			vignette.Visible = false
		end
		local downedPanel = reviveGui:FindFirstChild("DownedPanel")
		if downedPanel then downedPanel.Visible = false end
	end

	-- ── Recuperación gradual de vida ──────────
	-- Fase 1: 15% → 30% rápido  (5 segundos)
	-- Fase 2: 30% → 50% lento   (30 segundos)
	-- Fase 3: 50% → 50% muy lento (se detiene, obliga botiquín)
	if recoveryConn then recoveryConn:Disconnect() end

	-- Fijar vida inicial al 15%
	local humanoid2 = getHumanoid()
	if humanoid2 then
		humanoid2.Health = humanoid2.MaxHealth * 0.15
	end

	recoveryConn = RunService.Heartbeat:Connect(function(dt)
		local char = player.Character
		if not char then recoveryConn:Disconnect(); return end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum then recoveryConn:Disconnect(); return end
		if isDown then recoveryConn:Disconnect(); return end

		local maxHp   = hum.MaxHealth
		local hp      = hum.Health
		local phase1  = maxHp * 0.30   -- 30%
		local phase2  = maxHp * 0.50   -- 50%

		if hp < phase1 then
			-- FASE 1: rápido — 15% → 30% en 5 segundos
			local rate = (maxHp * 0.15) / 5
			hum.Health = math.min(phase1, hp + rate * dt)

		elseif hp < phase2 then
			-- FASE 2: lento — 30% → 50% en 30 segundos
			local rate = (maxHp * 0.20) / 30
			hum.Health = math.min(phase2, hp + rate * dt)

		else
			-- FASE 3: muy lento — 50% en adelante (casi nada, obliga botiquín)
			-- Sube apenas 0.1% por segundo — prácticamente no sube
			local rate = maxHp * 0.001
			local cap  = maxHp * 0.55   -- tope absoluto en 55% sin botiquín
			if hp >= cap then
				recoveryConn:Disconnect()
				print("[CLIENT] Recuperación detenida — usa botiquín para más vida")
			else
				hum.Health = math.min(cap, hp + rate * dt)
			end
		end
	end)

	print("[CLIENT] Revivido por", reviverPlayer and reviverPlayer.DisplayName or "compañero",
		"— recuperando vida gradualmente")
end

-- ════════════════════════════════════════════════
--  EVENTOS
-- ════════════════════════════════════════════════
onDowned.OnClientEvent:Connect(function(downedPlayer, timeLeft)
	if downedPlayer == player then
		onDownedState()
	end
end)

onRevived.OnClientEvent:Connect(function(downedPlayer, reviverPlayer)
	if downedPlayer == player then
		-- Solo activar recuperación si realmente estaba tumbado
		if isDown then
			onRevivedState(reviverPlayer)
		end
		-- Si no estaba tumbado (spawn normal) solo resetear estado
		isDown = false
	end
end)

onDied.OnClientEvent:Connect(function()
	-- Al morir definitivamente también bloqueamos movimiento
	isDown = true
	local humanoid = getHumanoid()
	if humanoid then
		humanoid.WalkSpeed  = 0
		humanoid.JumpPower  = 0
		humanoid.AutoRotate = false
	end
	-- Detener recuperación si estaba activa
	if recoveryConn then
		recoveryConn:Disconnect()
		recoveryConn = nil
	end
end)

-- Resetear al respawnear — quitar TODO lo del estado tumbado
player.CharacterAdded:Connect(function(character)
	isDown = false

	-- Detener recuperación
	if recoveryConn then
		recoveryConn:Disconnect()
		recoveryConn = nil
	end

	local humanoid = character:WaitForChild("Humanoid")
	local rootPart = character:WaitForChild("HumanoidRootPart")

	-- Esperar a que Roblox termine de cargar
	task.wait(0.2)

	-- Forzar 100% de vida siempre al respawnear
	humanoid.Health    = humanoid.MaxHealth
	humanoid.WalkSpeed = 16
	humanoid.JumpPower = 50
	humanoid.AutoRotate = true

	-- Quitar flag IsDowned si quedó
	local oldFlag = character:FindFirstChild("IsDowned")
	if oldFlag then oldFlag:Destroy() end

	-- Quitar BodyPosition si quedó
	local bp = rootPart:FindFirstChild("DownedLock")
	if bp then bp:Destroy() end

	-- Quitar flashes rojos
	clearFlashes()

	-- Restaurar controles
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
	local controls = require(player.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("ControlModule"))
	pcall(function() controls:Enable() end)

	-- Ocultar todos los paneles
	local reviveGui = playerGui:FindFirstChild("ReviveGui")
	if reviveGui then
		local dp = reviveGui:FindFirstChild("DownedPanel")
		if dp then dp.Visible = false end
		local vig = reviveGui:FindFirstChild("Vignette")
		if vig then vig.Visible = false end
		local rp = reviveGui:FindFirstChild("RevivePanel")
		if rp then rp.Visible = false end
	end

	-- Restaurar cámara
	local camera = workspace.CurrentCamera
	if camera then camera.CameraType = Enum.CameraType.Custom end

	print("[CLIENT] Respawn — vida al 100%")
end)

print("[CLIENT] DownedState listo.")