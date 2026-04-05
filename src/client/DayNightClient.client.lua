-- ============================================
-- DayNightClient.client.lua
-- Muestra notificaciones de día/noche al jugador
-- Ubicación: src/client/DayNightClient.client.lua
-- ============================================

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes      = ReplicatedStorage:WaitForChild("Remotes")
local onDayStart   = remotes:WaitForChild("OnDayStart")
local onNightStart = remotes:WaitForChild("OnNightStart")

-- ════════════════════════════════════════════════
--  GUI DE NOTIFICACIÓN
-- ════════════════════════════════════════════════
if playerGui:FindFirstChild("DayNightGui") then
	playerGui.DayNightGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name         = "DayNightGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 20
ScreenGui.Parent       = playerGui

-- Banner de notificación (aparece al cambiar)
local Banner = Instance.new("Frame")
Banner.Name             = "Banner"
Banner.Size             = UDim2.new(0, 300, 0, 60)
Banner.Position         = UDim2.new(0.5, 0, 0, -70)
Banner.AnchorPoint      = Vector2.new(0.5, 0)
Banner.BackgroundColor3 = Color3.fromRGB(10, 8, 20)
Banner.BackgroundTransparency = 0.1
Banner.BorderSizePixel  = 0
Banner.Parent           = ScreenGui

local BannerCorner = Instance.new("UICorner")
BannerCorner.CornerRadius = UDim.new(0, 12)
BannerCorner.Parent = Banner

local BannerStroke = Instance.new("UIStroke")
BannerStroke.Color       = Color3.fromRGB(255, 200, 80)
BannerStroke.Thickness   = 1.5
BannerStroke.Transparency = 0.3
BannerStroke.Parent = Banner

local BannerIcon = Instance.new("TextLabel")
BannerIcon.Size             = UDim2.new(0, 50, 1, 0)
BannerIcon.Position         = UDim2.new(0, 0, 0, 0)
BannerIcon.BackgroundTransparency = 1
BannerIcon.Text             = "☀️"
BannerIcon.Font             = Enum.Font.GothamBold
BannerIcon.TextSize         = 26
BannerIcon.TextXAlignment   = Enum.TextXAlignment.Center
BannerIcon.Parent           = Banner

local BannerTitle = Instance.new("TextLabel")
BannerTitle.Size           = UDim2.new(1, -60, 0, 28)
BannerTitle.Position       = UDim2.new(0, 52, 0, 6)
BannerTitle.BackgroundTransparency = 1
BannerTitle.Text           = "AMANECER"
BannerTitle.TextColor3     = Color3.fromRGB(255, 220, 120)
BannerTitle.Font           = Enum.Font.GothamBold
BannerTitle.TextSize       = 16
BannerTitle.TextXAlignment = Enum.TextXAlignment.Left
BannerTitle.Parent         = Banner

local BannerSub = Instance.new("TextLabel")
BannerSub.Size             = UDim2.new(1, -60, 0, 20)
BannerSub.Position         = UDim2.new(0, 52, 0, 32)
BannerSub.BackgroundTransparency = 1
BannerSub.Text             = "Los enemigos vuelven a la normalidad"
BannerSub.TextColor3       = Color3.fromRGB(180, 160, 120)
BannerSub.Font             = Enum.Font.Gotham
BannerSub.TextSize         = 11
BannerSub.TextXAlignment   = Enum.TextXAlignment.Left
BannerSub.Parent           = Banner

-- Indicador de fase (esquina superior derecha, siempre visible)
local PhaseIndicator = Instance.new("Frame")
PhaseIndicator.Size             = UDim2.new(0, 90, 0, 30)
PhaseIndicator.Position         = UDim2.new(1, -104, 0, 14)
PhaseIndicator.BackgroundColor3 = Color3.fromRGB(10, 8, 20)
PhaseIndicator.BackgroundTransparency = 0.2
PhaseIndicator.BorderSizePixel  = 0
PhaseIndicator.Parent           = ScreenGui

local PICorner = Instance.new("UICorner")
PICorner.CornerRadius = UDim.new(0, 8)
PICorner.Parent = PhaseIndicator

local PIStroke = Instance.new("UIStroke")
PIStroke.Color       = Color3.fromRGB(255, 200, 80)
PIStroke.Thickness   = 1
PIStroke.Transparency = 0.4
PIStroke.Parent = PhaseIndicator

local PILabel = Instance.new("TextLabel")
PILabel.Size             = UDim2.new(1, 0, 1, 0)
PILabel.BackgroundTransparency = 1
PILabel.Text             = "☀️  DÍA"
PILabel.TextColor3       = Color3.fromRGB(255, 220, 120)
PILabel.Font             = Enum.Font.GothamBold
PILabel.TextSize         = 12
PILabel.TextXAlignment   = Enum.TextXAlignment.Center
PILabel.Parent           = PhaseIndicator

-- ════════════════════════════════════════════════
--  FUNCIÓN: mostrar banner
-- ════════════════════════════════════════════════
local function showBanner(icon, title, subtitle, strokeColor, titleColor)
	BannerIcon.Text       = icon
	BannerTitle.Text      = title
	BannerTitle.TextColor3 = titleColor
	BannerSub.Text        = subtitle
	BannerStroke.Color    = strokeColor

	-- Entrar desde arriba
	Banner.Position = UDim2.new(0.5, 0, 0, -70)
	TweenService:Create(Banner,
		TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, 0, 0, 16) }):Play()

	-- Esperar y salir
	task.wait(3.5)
	TweenService:Create(Banner,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Position = UDim2.new(0.5, 0, 0, -70) }):Play()
end

-- ════════════════════════════════════════════════
--  ESCUCHAR EVENTOS DEL SERVIDOR
-- ════════════════════════════════════════════════
onNightStart.OnClientEvent:Connect(function()
	-- Actualizar indicador
	PILabel.Text      = "🌙  NOCHE"
	PILabel.TextColor3 = Color3.fromRGB(160, 140, 255)
	PIStroke.Color    = Color3.fromRGB(120, 100, 220)

	-- Mostrar banner de advertencia
	task.spawn(showBanner,
		"🌙",
		"PROTOCOLO SIGMA ACTIVO",
		"⚠ Los enemigos son más peligrosos esta noche",
		Color3.fromRGB(120, 80, 220),
		Color3.fromRGB(200, 180, 255)
	)
end)

onDayStart.OnClientEvent:Connect(function()
	-- Actualizar indicador
	PILabel.Text      = "☀️  DÍA"
	PILabel.TextColor3 = Color3.fromRGB(255, 220, 120)
	PIStroke.Color    = Color3.fromRGB(255, 200, 80)

	-- Mostrar banner
	task.spawn(showBanner,
		"☀️",
		"AMANECER",
		"Los sistemas vuelven a la normalidad",
		Color3.fromRGB(255, 180, 60),
		Color3.fromRGB(255, 220, 120)
	)
end)

print("[CLIENT] DayNightClient listo.")