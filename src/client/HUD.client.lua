-- ============================================
-- HUD.client.lua
-- Script de CLIENTE — HUD completo
-- Incluye:
--   · Barra de vida + visor del personaje (abajo izquierda)
--   · Barra de menú con acciones (abajo centro)
-- Ubicación: src/client/HUD.client.lua
-- ============================================

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

-- Limpiar HUDs anteriores
for _, name in ipairs({"HealthBarGui", "HUDGui"}) do
	if playerGui:FindFirstChild(name) then
		playerGui[name]:Destroy()
	end
end

-- ════════════════════════════════════════════════
--  SCREEN GUI PRINCIPAL
-- ════════════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "HUDGui"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent         = playerGui

-- ════════════════════════════════════════════════
--  HELPER: crear Frame con esquinas redondeadas
-- ════════════════════════════════════════════════
local function makeFrame(props)
	local f = Instance.new("Frame")
	f.Name             = props.name or "Frame"
	f.Size             = props.size or UDim2.new(0,100,0,40)
	f.Position         = props.pos  or UDim2.new(0,0,0,0)
	f.AnchorPoint      = props.anchor or Vector2.new(0,0)
	f.BackgroundColor3 = props.color or Color3.fromRGB(10,10,15)
	f.BackgroundTransparency = props.alpha or 0.15
	f.BorderSizePixel  = 0
	f.Parent           = props.parent or ScreenGui
	if props.radius then
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, props.radius)
		c.Parent = f
	end
	if props.stroke then
		local s = Instance.new("UIStroke")
		s.Color        = props.stroke
		s.Thickness    = props.strokeW or 1.5
		s.Transparency = props.strokeA or 0.4
		s.Parent = f
	end
	return f
end

local function makeLabel(props)
	local l = Instance.new("TextLabel")
	l.Name              = props.name or "Label"
	l.Size              = props.size or UDim2.new(1,0,1,0)
	l.Position          = props.pos  or UDim2.new(0,0,0,0)
	l.AnchorPoint       = props.anchor or Vector2.new(0,0)
	l.BackgroundTransparency = 1
	l.Text              = props.text or ""
	l.TextColor3        = props.color or Color3.fromRGB(220,220,220)
	l.Font              = props.font  or Enum.Font.GothamBold
	l.TextSize          = props.size2 or 13
	l.TextXAlignment    = props.alignX or Enum.TextXAlignment.Left
	l.TextYAlignment    = props.alignY or Enum.TextYAlignment.Center
	l.Parent            = props.parent or ScreenGui
	return l
end

-- ════════════════════════════════════════════════
--  SECCIÓN 1: BARRA DE VIDA + PERSONAJE (abajo izquierda)
-- ════════════════════════════════════════════════
local HpContainer = makeFrame({
	name   = "HpContainer",
	size   = UDim2.new(0, 290, 0, 84),
	pos    = UDim2.new(0, 16, 1, -16),
	anchor = Vector2.new(0, 1),
	color  = Color3.fromRGB(8, 8, 12),
	alpha  = 0.15,
	radius = 12,
	stroke = Color3.fromRGB(180, 30, 30),
	strokeW = 1.5,
	strokeA = 0.4,
	parent = ScreenGui,
})

-- ── Viewport del personaje ────────────────────
local Viewport = Instance.new("ViewportFrame")
Viewport.Name                   = "CharViewport"
Viewport.Size                   = UDim2.new(0, 68, 0, 68)
Viewport.Position               = UDim2.new(0, 8, 0.5, 0)
Viewport.AnchorPoint            = Vector2.new(0, 0.5)
Viewport.BackgroundColor3       = Color3.fromRGB(15, 15, 22)
Viewport.BackgroundTransparency = 0.3
Viewport.BorderSizePixel        = 0
Viewport.Parent                 = HpContainer

local vc = Instance.new("UICorner")
vc.CornerRadius = UDim.new(0, 8)
vc.Parent = Viewport

local vs = Instance.new("UIStroke")
vs.Color = Color3.fromRGB(200, 40, 40)
vs.Thickness = 1
vs.Transparency = 0.5
vs.Parent = Viewport

local ViewportCam = Instance.new("Camera")
ViewportCam.Parent = Viewport
Viewport.CurrentCamera = ViewportCam

-- ── Panel derecho (nombre + barra) ───────────
local RightPanel = Instance.new("Frame")
RightPanel.Size             = UDim2.new(1, -90, 1, 0)
RightPanel.Position         = UDim2.new(0, 84, 0, 0)
RightPanel.BackgroundTransparency = 1
RightPanel.BorderSizePixel  = 0
RightPanel.Parent           = HpContainer

-- Nombre del jugador
local NameLabel = makeLabel({
	name   = "PlayerName",
	size   = UDim2.new(1, -8, 0, 20),
	pos    = UDim2.new(0, 4, 0, 10),
	text   = player.DisplayName,
	color  = Color3.fromRGB(230, 230, 230),
	font   = Enum.Font.GothamBold,
	size2  = 13,
	parent = RightPanel,
})

-- Fondo de la barra
local BarBg = makeFrame({
	name   = "BarBg",
	size   = UDim2.new(1, -8, 0, 14),
	pos    = UDim2.new(0, 4, 0, 36),
	color  = Color3.fromRGB(30, 10, 10),
	alpha  = 0,
	radius = 7,
	parent = RightPanel,
})

-- Relleno de la barra
local BarFill = makeFrame({
	name   = "BarFill",
	size   = UDim2.new(1, 0, 1, 0),
	color  = Color3.fromRGB(220, 40, 40),
	alpha  = 0,
	radius = 7,
	parent = BarBg,
})

-- Brillo superior
local BarShine = Instance.new("Frame")
BarShine.Size             = UDim2.new(1,0,0.45,0)
BarShine.BackgroundColor3 = Color3.fromRGB(255,255,255)
BarShine.BackgroundTransparency = 0.82
BarShine.BorderSizePixel  = 0
BarShine.Parent = BarFill
local bsc = Instance.new("UICorner")
bsc.CornerRadius = UDim.new(0,7)
bsc.Parent = BarShine

-- Texto HP
local HpText = makeLabel({
	name   = "HpText",
	size   = UDim2.new(1, -8, 0, 14),
	pos    = UDim2.new(0, 4, 0, 56),
	text   = "100 / 100",
	color  = Color3.fromRGB(170, 170, 170),
	font   = Enum.Font.Gotham,
	size2  = 11,
	parent = RightPanel,
})

local HeartIcon = makeLabel({
	name   = "Heart",
	size   = UDim2.new(0, 14, 0, 14),
	pos    = UDim2.new(1, -18, 0, 56),
	anchor = Vector2.new(0,0),
	text   = "♥",
	color  = Color3.fromRGB(220, 40, 40),
	font   = Enum.Font.GothamBold,
	size2  = 13,
	parent = RightPanel,
})

-- Borde pulsante de la barra (referencia al UIStroke del contenedor)
local HpStroke = HpContainer:FindFirstChildOfClass("UIStroke")

-- Barra de menú eliminada — reemplazada por KeyGuide (I)

-- ════════════════════════════════════════════════
--  SISTEMA DE LINTERNA
-- ════════════════════════════════════════════════

-- La linterna es un SpotLight que se crea en la cabeza
-- del personaje. Se activa/desactiva con F.
local flashlight     = nil   -- referencia al SpotLight activo
local flashlightOn   = false

local function createFlashlight(character)
	-- Buscar o crear la parte donde va la linterna (cabeza)
	local head = character:WaitForChild("Head")

	-- Eliminar linterna anterior si existe
	local old = head:FindFirstChild("Flashlight")
	if old then old:Destroy() end

	-- Crear el SpotLight
	local spot = Instance.new("SpotLight")
	spot.Name        = "Flashlight"
	spot.Brightness  = 5          -- intensidad
	spot.Range       = 60         -- alcance en studs
	spot.Angle       = 45         -- ángulo del cono de luz
	spot.Color       = Color3.fromRGB(255, 245, 220)  -- blanco cálido
	spot.Face        = Enum.NormalId.Front
	spot.Shadows     = true
	spot.Enabled     = false      -- empieza apagada
	spot.Parent      = head

	flashlight = spot
end

local function toggleFlashlight()
	if not flashlight then return end
	flashlightOn = not flashlightOn
	flashlight.Enabled = flashlightOn

	-- Animación suave de brillo al encender/apagar
	if flashlightOn then
		flashlight.Brightness = 0
		-- Subir brillo gradualmente
		local t = 0
		local connection
		connection = game:GetService("RunService").Heartbeat:Connect(function(dt)
			t = t + dt * 4   -- velocidad de fade-in
			flashlight.Brightness = math.min(t * 5, 5)
			if t >= 1 then connection:Disconnect() end
		end)
	else
		-- Bajar brillo gradualmente
		local t = 1
		local connection
		connection = game:GetService("RunService").Heartbeat:Connect(function(dt)
			t = t - dt * 4
			flashlight.Brightness = math.max(t * 5, 0)
			if t <= 0 then connection:Disconnect() end
		end)
	end
end

-- ── Solo tecla F para la linterna ────────────
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.F then
		toggleFlashlight()
	end
end)

-- ════════════════════════════════════════════════
--  LÓGICA DE SALUD
-- ════════════════════════════════════════════════
local function getBarColor(pct)
	if pct > 0.6 then
		return Color3.fromRGB(220, 40, 40)
	elseif pct > 0.3 then
		return Color3.fromRGB(220, 140, 20)
	else
		return Color3.fromRGB(220, 220, 20)
	end
end

local function updateHp(current, max)
	local pct = math.clamp(current / max, 0, 1)

	TweenService:Create(BarFill, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = UDim2.new(pct, 0, 1, 0) }):Play()

	TweenService:Create(BarFill, TweenInfo.new(0.3),
		{ BackgroundColor3 = getBarColor(pct) }):Play()

	HpText.Text = math.floor(current) .. " / " .. max

	if pct <= 0.3 and HpStroke then
		TweenService:Create(HpStroke, TweenInfo.new(0.4, Enum.EasingStyle.Sine,
			Enum.EasingDirection.InOut, -1, true),
			{ Transparency = 0.0 }):Play()
	elseif HpStroke then
		HpStroke.Transparency = 0.4
	end
end

-- ── Viewport: clonar personaje ────────────────
local function setupViewport(character)
	for _, c in ipairs(Viewport:GetChildren()) do
		if c:IsA("Model") then c:Destroy() end
	end
	local clone = character:Clone()
	clone.Parent = Viewport
	for _, s in ipairs(clone:GetDescendants()) do
		if s:IsA("Script") or s:IsA("LocalScript") then s.Enabled = false end
	end
	local head = clone:FindFirstChild("Head")
	if head then
		ViewportCam.CFrame = CFrame.new(
			head.Position + Vector3.new(0, 0.5, 3.8),
			head.Position + Vector3.new(0, 0.2, 0)
		)
	end
end

-- ── Conectar al personaje ─────────────────────
local function onCharacter(character)
	local humanoid = character:WaitForChild("Humanoid")
	local maxHp    = GameConfig.PLAYER_HEALTH

	task.wait(0.5)
	setupViewport(character)
	createFlashlight(character)   -- ← crear linterna en el nuevo personaje

	-- Si la linterna estaba encendida antes del respawn, reencenderla
	if flashlightOn then
		flashlightOn = false       -- resetear estado para que toggleFlashlight funcione
		toggleFlashlight()
	end

	humanoid.HealthChanged:Connect(function(hp)
		updateHp(hp, maxHp)
	end)

	updateHp(humanoid.Health, maxHp)
end

player.CharacterAdded:Connect(onCharacter)
if player.Character then onCharacter(player.Character) end

print("[CLIENT] HUD completo cargado.")