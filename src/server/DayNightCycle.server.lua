-- ============================================
-- DayNightCycle.server.lua
-- Ciclo día/noche automático
-- · Día: tonos cálidos, enemigos normales
-- · Noche: oscuro y frío, enemigos más agresivos
-- · Sincronizado para todos los jugadores
-- Ubicación: src/server/DayNightCycle.server.lua
-- ============================================

local Lighting          = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

-- ════════════════════════════════════════════════
--  MODO DESARROLLADOR
--  true  → siempre de día, ciclo desactivado
--  false → ciclo normal día/noche
-- ════════════════════════════════════════════════
local DEV_MODE = false  -- ← cambia a false para el juego final

if DEV_MODE then
	print("[SERVER] ⚙ MODO DESARROLLADOR — ciclo día/noche desactivado")
end

-- ════════════════════════════════════════════════
--  CONFIGURACIÓN
-- ════════════════════════════════════════════════
local Config = {
	DAY_DURATION    = 360,   -- segundos de día  (6 min)
	NIGHT_DURATION  = 240,   -- segundos de noche (4 min)
	TRANSITION_TIME = 30,    -- segundos de transición amanecer/atardecer
	START_TIME      = 8,     -- empieza de mañana
}

-- ── Skybox — usa los objetos Sky que pusiste en Lighting ──
local function applySkybox(name)
	-- Desactivar todos los Sky primero
	for _, obj in ipairs(Lighting:GetChildren()) do
		if obj:IsA("Sky") then
			obj.Archivable = true
			obj.Parent = game.ServerStorage
		end
	end
	-- Activar el que corresponde
	local target = game.ServerStorage:FindFirstChild(name)
	if target then
		target.Parent = Lighting
		target.SunAngularSize  = 0
		target.MoonAngularSize = 0
	end
end

-- ── Presets visuales ─────────────────────────
local DAY_PRESET = {
	clockTime      = 14,                                    -- 2pm
	brightness     = 1,
	ambient        = Color3.fromRGB(120, 100, 80),
	outdoorAmbient = Color3.fromRGB(180, 160, 130),
	atmosphere = {
		Density = 0.25,
		Offset  = 0.2,
		Haze    = 0.5,
		Glare   = 0.3,
		Color   = Color3.fromRGB(255, 200, 140),
		Decay   = Color3.fromRGB(120, 80, 50),
	},
	colorCorrection = {
		Brightness = 0.02,
		Contrast   = 0.12,
		Saturation = 0.05,
		TintColor  = Color3.fromRGB(255, 235, 200),
	},
	bloom = {
		Intensity = 0.5,
		Size      = 24,
		Threshold = 0.9,
	},
}

local NIGHT_PRESET = {
	clockTime      = 0,                                     -- medianoche
	brightness     = 0,
	ambient        = Color3.fromRGB(15, 10, 25),
	outdoorAmbient = Color3.fromRGB(20, 15, 35),
	atmosphere = {
		Density = 0.5,
		Offset  = 0.1,
		Haze    = 1.5,
		Glare   = 0,
		Color   = Color3.fromRGB(30, 20, 60),
		Decay   = Color3.fromRGB(10, 5, 20),
	},
	colorCorrection = {
		Brightness = -0.08,
		Contrast   = 0.25,
		Saturation = -0.3,
		TintColor  = Color3.fromRGB(180, 190, 255),
	},
	bloom = {
		Intensity = 0.3,
		Size      = 18,
		Threshold = 0.95,
	},
}

-- ════════════════════════════════════════════════
--  SETUP INICIAL DE EFECTOS
-- ════════════════════════════════════════════════
-- Limpiar efectos anteriores
for _, v in ipairs(Lighting:GetChildren()) do
	if v:IsA("Atmosphere") or v:IsA("BloomEffect") or
		v:IsA("ColorCorrectionEffect") or v:IsA("SunRaysEffect") then
		v:Destroy()
	end
end

local atmosphere = Instance.new("Atmosphere")
atmosphere.Parent = Lighting

local bloom = Instance.new("BloomEffect")
bloom.Parent = Lighting

local colorCorrection = Instance.new("ColorCorrectionEffect")
colorCorrection.Parent = Lighting

-- ════════════════════════════════════════════════
--  REMOTE EVENTS
-- ════════════════════════════════════════════════
local remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Notificar a los clientes cuando cambia el ciclo
local onDayStart   = Instance.new("RemoteEvent")
onDayStart.Name    = "OnDayStart"
onDayStart.Parent  = remotes

local onNightStart = Instance.new("RemoteEvent")
onNightStart.Name  = "OnNightStart"
onNightStart.Parent = remotes

-- Variable global accesible desde otros scripts
local CycleModule = {}
CycleModule.isNight        = false
CycleModule.timeOfDay      = Config.START_TIME
CycleModule.enemyMultiplier = 1.0  -- 1.0 = normal, 1.5 = noche

-- Guardar en ReplicatedStorage para que otros scripts lo lean
local cycleValue = Instance.new("BoolValue")
cycleValue.Name   = "IsNight"
cycleValue.Value  = false
cycleValue.Parent = ReplicatedStorage

local multiplierValue = Instance.new("NumberValue")
multiplierValue.Name   = "EnemyMultiplier"
multiplierValue.Value  = 1.0
multiplierValue.Parent = ReplicatedStorage

-- ════════════════════════════════════════════════
--  FUNCIÓN DE INTERPOLACIÓN
-- ════════════════════════════════════════════════
local function lerpColor(a, b, t)
	return Color3.new(
		a.R + (b.R - a.R) * t,
		a.G + (b.G - a.G) * t,
		a.B + (b.B - a.B) * t
	)
end

local function lerpNumber(a, b, t)
	return a + (b - a) * t
end

-- Aplicar un preset con interpolación suave
local function applyPreset(preset, alpha)
	-- alpha: 0 = completamente día, 1 = completamente noche
	local d, n = DAY_PRESET, NIGHT_PRESET

	-- Clock time (interpolación de hora)
	local targetHour
	if alpha < 0.5 then
		-- Atardecer: de día (14h) a noche (24h)
		local t = alpha * 2
		targetHour = lerpNumber(d.clockTime, 24, t)
	else
		-- Amanecer: de noche (0h) a día (14h)
		local t = (alpha - 0.5) * 2
		targetHour = lerpNumber(0, d.clockTime, 1 - t)
	end

	Lighting.ClockTime       = targetHour
	Lighting.Brightness      = lerpNumber(d.brightness, n.brightness, alpha)
	Lighting.Ambient         = lerpColor(d.ambient, n.ambient, alpha)
	Lighting.OutdoorAmbient  = lerpColor(d.outdoorAmbient, n.outdoorAmbient, alpha)

	-- Atmosphere
	atmosphere.Density = lerpNumber(d.atmosphere.Density, n.atmosphere.Density, alpha)
	atmosphere.Offset  = lerpNumber(d.atmosphere.Offset,  n.atmosphere.Offset,  alpha)
	atmosphere.Haze    = lerpNumber(d.atmosphere.Haze,    n.atmosphere.Haze,    alpha)
	atmosphere.Glare   = lerpNumber(d.atmosphere.Glare,   n.atmosphere.Glare,   alpha)
	atmosphere.Color   = lerpColor(d.atmosphere.Color,    n.atmosphere.Color,   alpha)
	atmosphere.Decay   = lerpColor(d.atmosphere.Decay,    n.atmosphere.Decay,   alpha)

	-- Color Correction
	colorCorrection.Brightness = lerpNumber(d.colorCorrection.Brightness, n.colorCorrection.Brightness, alpha)
	colorCorrection.Contrast   = lerpNumber(d.colorCorrection.Contrast,   n.colorCorrection.Contrast,   alpha)
	colorCorrection.Saturation = lerpNumber(d.colorCorrection.Saturation, n.colorCorrection.Saturation, alpha)
	colorCorrection.TintColor  = lerpColor(d.colorCorrection.TintColor,   n.colorCorrection.TintColor,  alpha)

	-- Bloom
	bloom.Intensity  = lerpNumber(d.bloom.Intensity, n.bloom.Intensity, alpha)
	bloom.Size       = lerpNumber(d.bloom.Size,      n.bloom.Size,      alpha)
	bloom.Threshold  = lerpNumber(d.bloom.Threshold, n.bloom.Threshold, alpha)
end

-- ════════════════════════════════════════════════
--  CICLO PRINCIPAL
-- ════════════════════════════════════════════════
local phase     = "day"     -- "day", "sunset", "night", "sunrise"
local phaseTime = 0         -- tiempo transcurrido en la fase actual

-- Aplicar estado inicial
applyPreset(DAY_PRESET, 0)
applySkybox("Sky")   -- "Sky" = cielo del día

-- Si es modo desarrollador, no correr el ciclo
if DEV_MODE then
	print("[SERVER] ☀️ Día permanente activado.")
	return
end

print("[SERVER] DayNightCycle iniciado.")
print("[SERVER] Duración día: " .. Config.DAY_DURATION .. "s | Noche: " .. Config.NIGHT_DURATION .. "s")

RunService.Heartbeat:Connect(function(dt)
	phaseTime = phaseTime + dt

	if phase == "day" then
		applyPreset(DAY_PRESET, 0)
		applySkybox("Sky")

		if phaseTime >= Config.DAY_DURATION then
			phase     = "sunset"
			phaseTime = 0
			print("[SERVER] 🌅 Atardecer iniciando...")
		end

	elseif phase == "sunset" then
		local alpha = math.clamp(phaseTime / Config.TRANSITION_TIME, 0, 1)
		applyPreset(DAY_PRESET, alpha)

		if alpha >= 0.5 then
			applySkybox("Night Sky")
		else
			applySkybox("Sky")
		end

		if phaseTime >= Config.TRANSITION_TIME then
			phase     = "night"
			phaseTime = 0

			CycleModule.isNight         = true
			CycleModule.enemyMultiplier = 1.5
			cycleValue.Value            = true
			multiplierValue.Value       = 1.5

			onNightStart:FireAllClients()
			print("[SERVER] 🌙 Noche — enemigos más agresivos (x1.5)")
		end

	elseif phase == "night" then
		applyPreset(NIGHT_PRESET, 1)
		applySkybox("Night Sky")

		if phaseTime >= Config.NIGHT_DURATION then
			phase     = "sunrise"
			phaseTime = 0
			print("[SERVER] 🌄 Amanecer iniciando...")
		end

	elseif phase == "sunrise" then
		local alpha = math.clamp(1 - (phaseTime / Config.TRANSITION_TIME), 0, 1)
		applyPreset(DAY_PRESET, alpha)

		if alpha <= 0.5 then
			applySkybox("Sky")
		else
			applySkybox("Night Sky")
		end

		if phaseTime >= Config.TRANSITION_TIME then
			phase     = "day"
			phaseTime = 0

			CycleModule.isNight         = false
			CycleModule.enemyMultiplier = 1.0
			cycleValue.Value            = false
			multiplierValue.Value       = 1.0

			onDayStart:FireAllClients()
			print("[SERVER] ☀️ Día — enemigos normales")
		end
	end
end)