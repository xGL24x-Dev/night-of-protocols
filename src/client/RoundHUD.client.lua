-- ============================================
-- RoundHUD.client.lua
-- Script de CLIENTE — HUD de rondas
-- Muestra: ronda actual, oleada, tipo de enemigo,
--          cuenta regresiva y anuncio del boss
-- Sigue el estilo visual del HUD existente
-- Ubicación: src/client/RoundHUD.client.lua
-- ============================================

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Limpiar si existe de un respawn anterior
if playerGui:FindFirstChild("RoundHUDGui") then
    playerGui.RoundHUDGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name         = "RoundHUDGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 15
ScreenGui.Parent       = playerGui

-- ════════════════════════════════════════════════
--  PANEL SUPERIOR CENTRO (ronda + oleada)
-- ════════════════════════════════════════════════
local TopPanel = Instance.new("Frame")
TopPanel.Name             = "TopPanel"
TopPanel.Size             = UDim2.new(0, 280, 0, 58)
TopPanel.Position         = UDim2.new(0.5, 0, 0, 14)
TopPanel.AnchorPoint      = Vector2.new(0.5, 0)
TopPanel.BackgroundColor3 = Color3.fromRGB(8, 8, 14)
TopPanel.BackgroundTransparency = 0.15
TopPanel.BorderSizePixel  = 0
TopPanel.Visible          = false
TopPanel.Parent           = ScreenGui

local tpc = Instance.new("UICorner")
tpc.CornerRadius = UDim.new(0, 10)
tpc.Parent = TopPanel

local tps = Instance.new("UIStroke")
tps.Color       = Color3.fromRGB(180, 30, 30)
tps.Thickness   = 1.5
tps.Transparency = 0.4
tps.Parent = TopPanel

-- Línea superior: "RONDA 2 / 4"
local RoundLabel = Instance.new("TextLabel")
RoundLabel.Name             = "RoundLabel"
RoundLabel.Size             = UDim2.new(1, -16, 0, 26)
RoundLabel.Position         = UDim2.new(0, 8, 0, 4)
RoundLabel.BackgroundTransparency = 1
RoundLabel.Text             = "RONDA 1 / 4"
RoundLabel.TextColor3       = Color3.fromRGB(230, 230, 230)
RoundLabel.Font             = Enum.Font.GothamBold
RoundLabel.TextSize         = 15
RoundLabel.TextXAlignment   = Enum.TextXAlignment.Center
RoundLabel.Parent           = TopPanel

-- Línea inferior: "Oleada 1/3 — Vigilante"
local WaveLabel = Instance.new("TextLabel")
WaveLabel.Name             = "WaveLabel"
WaveLabel.Size             = UDim2.new(1, -16, 0, 20)
WaveLabel.Position         = UDim2.new(0, 8, 0, 32)
WaveLabel.BackgroundTransparency = 1
WaveLabel.Text             = ""
WaveLabel.TextColor3       = Color3.fromRGB(200, 170, 100)
WaveLabel.Font             = Enum.Font.Gotham
WaveLabel.TextSize         = 12
WaveLabel.TextXAlignment   = Enum.TextXAlignment.Center
WaveLabel.Parent           = TopPanel

-- ════════════════════════════════════════════════
--  NÚMERO GRANDE DE CUENTA REGRESIVA (centro)
-- ════════════════════════════════════════════════
local CountLabel = Instance.new("TextLabel")
CountLabel.Name             = "CountLabel"
CountLabel.Size             = UDim2.new(0, 160, 0, 120)
CountLabel.Position         = UDim2.new(0.5, -80, 0.38, 0)
CountLabel.BackgroundTransparency = 1
CountLabel.Text             = ""
CountLabel.TextColor3       = Color3.fromRGB(220, 50, 50)
CountLabel.Font             = Enum.Font.GothamBlack
CountLabel.TextSize         = 80
CountLabel.TextXAlignment   = Enum.TextXAlignment.Center
CountLabel.Parent           = ScreenGui

-- ════════════════════════════════════════════════
--  BANNER DE BOSS (centro, aparece al spawnear)
-- ════════════════════════════════════════════════
local BossBanner = Instance.new("Frame")
BossBanner.Name             = "BossBanner"
BossBanner.Size             = UDim2.new(0, 360, 0, 70)
BossBanner.Position         = UDim2.new(0.5, 0, 0, -80)
BossBanner.AnchorPoint      = Vector2.new(0.5, 0)
BossBanner.BackgroundColor3 = Color3.fromRGB(10, 6, 18)
BossBanner.BackgroundTransparency = 0.1
BossBanner.BorderSizePixel  = 0
BossBanner.Parent           = ScreenGui

local bbc = Instance.new("UICorner")
bbc.CornerRadius = UDim.new(0, 12)
bbc.Parent = BossBanner

local bbs = Instance.new("UIStroke")
bbs.Color       = Color3.fromRGB(200, 30, 30)
bbs.Thickness   = 2
bbs.Transparency = 0.2
bbs.Parent = BossBanner

local BossTitle = Instance.new("TextLabel")
BossTitle.Size             = UDim2.new(1, -16, 0, 34)
BossTitle.Position         = UDim2.new(0, 8, 0, 6)
BossTitle.BackgroundTransparency = 1
BossTitle.Text             = "⚠  JEFE FINAL"
BossTitle.TextColor3       = Color3.fromRGB(255, 60, 60)
BossTitle.Font             = Enum.Font.GothamBlack
BossTitle.TextSize         = 20
BossTitle.TextXAlignment   = Enum.TextXAlignment.Center
BossTitle.Parent           = BossBanner

local BossSub = Instance.new("TextLabel")
BossSub.Size             = UDim2.new(1, -16, 0, 22)
BossSub.Position         = UDim2.new(0, 8, 0, 40)
BossSub.BackgroundTransparency = 1
BossSub.Text             = ""
BossSub.TextColor3       = Color3.fromRGB(200, 160, 160)
BossSub.Font             = Enum.Font.Gotham
BossSub.TextSize         = 13
BossSub.TextXAlignment   = Enum.TextXAlignment.Center
BossSub.Parent           = BossBanner

-- ════════════════════════════════════════════════
--  BANNER GENÉRICO (victoria / derrota / intermisión)
-- ════════════════════════════════════════════════
local GenBanner = Instance.new("Frame")
GenBanner.Name             = "GenBanner"
GenBanner.Size             = UDim2.new(0, 320, 0, 60)
GenBanner.Position         = UDim2.new(0.5, 0, 0, -70)
GenBanner.AnchorPoint      = Vector2.new(0.5, 0)
GenBanner.BackgroundColor3 = Color3.fromRGB(8, 8, 14)
GenBanner.BackgroundTransparency = 0.1
GenBanner.BorderSizePixel  = 0
GenBanner.Parent           = ScreenGui

local gbc = Instance.new("UICorner")
gbc.CornerRadius = UDim.new(0, 12)
gbc.Parent = GenBanner

local gbs = Instance.new("UIStroke")
gbs.Color       = Color3.fromRGB(80, 70, 140)
gbs.Thickness   = 1.5
gbs.Transparency = 0.3
gbs.Parent = GenBanner

local GenLabel = Instance.new("TextLabel")
GenLabel.Size             = UDim2.new(1, -16, 1, 0)
GenLabel.Position         = UDim2.new(0, 8, 0, 0)
GenLabel.BackgroundTransparency = 1
GenLabel.Text             = ""
GenLabel.TextColor3       = Color3.fromRGB(230, 230, 230)
GenLabel.Font             = Enum.Font.GothamBold
GenLabel.TextSize         = 16
GenLabel.TextXAlignment   = Enum.TextXAlignment.Center
GenLabel.Parent           = GenBanner

-- ════════════════════════════════════════════════
--  FUNCIONES DE ANIMACIÓN
-- ════════════════════════════════════════════════
local function slideIn(frame, targetY, duration)
    duration = duration or 0.35
    TweenService:Create(frame,
        TweenInfo.new(duration, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Position = UDim2.new(0.5, 0, 0, targetY) }):Play()
end

local function slideOut(frame, duration)
    duration = duration or 0.2
    TweenService:Create(frame,
        TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { Position = UDim2.new(0.5, 0, 0, -100) }):Play()
end

local function showGenBanner(text, color, seconds)
    GenLabel.Text      = text
    GenLabel.TextColor3 = color
    gbs.Color          = color
    GenBanner.Position = UDim2.new(0.5, 0, 0, -70)
    slideIn(GenBanner, 90)
    task.delay(seconds or 3.5, function()
        slideOut(GenBanner)
    end)
end

-- ════════════════════════════════════════════════
--  EVENTOS
-- ════════════════════════════════════════════════
local remotes     = ReplicatedStorage:WaitForChild("Remotes")
local evCountdown = remotes:WaitForChild("RoundCountdown")
local evRound     = remotes:WaitForChild("RoundStart")
local evWave      = remotes:WaitForChild("WaveStart")
local evClear     = remotes:WaitForChild("WaveClear")
local evBoss      = remotes:WaitForChild("BossSpawn")
local evEnd       = remotes:WaitForChild("RoundEnd")
local evPhase     = remotes:WaitForChild("PhaseChange")

-- Cuenta regresiva
evCountdown.OnClientEvent:Connect(function(secs)
    CountLabel.Text    = tostring(secs)
    CountLabel.TextSize = 40
    TweenService:Create(CountLabel,
        TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { TextSize = 80 }):Play()
    task.delay(0.7, function()
        if CountLabel.Text == tostring(secs) then
            CountLabel.Text = ""
        end
    end)
end)

-- Inicio de ronda
evRound.OnClientEvent:Connect(function(current, total)
    TopPanel.Visible  = true
    RoundLabel.Text   = "RONDA  " .. current .. "  /  " .. total
    WaveLabel.Text    = ""
    showGenBanner("— RONDA " .. current .. " —",
        Color3.fromRGB(220, 180, 80), 3)
end)

-- Inicio de oleada
evWave.OnClientEvent:Connect(function(wave, totalWaves, enemyType)
    WaveLabel.Text = "Oleada " .. wave .. " / " .. totalWaves .. "  ·  " .. enemyType
end)

-- Oleada limpia
evClear.OnClientEvent:Connect(function()
    WaveLabel.Text = "✓  Oleada eliminada"
end)

-- Boss spawneado
evBoss.OnClientEvent:Connect(function(bossName, _hp)
    BossSub.Text       = bossName
    BossBanner.Position = UDim2.new(0.5, 0, 0, -80)
    slideIn(BossBanner, 110)

    -- Pulsar el borde del banner
    task.spawn(function()
        for _ = 1, 4 do
            TweenService:Create(bbs,
                TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                { Transparency = 0 }):Play()
            task.wait(0.3)
            TweenService:Create(bbs,
                TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                { Transparency = 0.6 }):Play()
            task.wait(0.3)
        end
    end)

    -- Ocultar el banner de ronda normal mientras está el boss
    WaveLabel.Text = "¡Elimina al jefe!"
end)

-- Fin del juego
evEnd.OnClientEvent:Connect(function(won)
    -- Ocultar boss banner si está visible
    slideOut(BossBanner, 0.2)

    if won then
        showGenBanner("🏆  ¡VICTORIA!", Color3.fromRGB(80, 220, 120), 8)
        RoundLabel.Text = "¡VICTORIA!"
        WaveLabel.Text  = ""
    else
        showGenBanner("💀  DERROTA", Color3.fromRGB(200, 50, 50), 8)
        RoundLabel.Text = "DERROTA"
        WaveLabel.Text  = ""
    end
end)

-- Cambio de fase
evPhase.OnClientEvent:Connect(function(phase)
    if phase == "intermission" then
        showGenBanner("Prepárate para la siguiente ronda...",
            Color3.fromRGB(140, 130, 200), 4)
        WaveLabel.Text = "Intermisión..."
    elseif phase == "countdown" then
        TopPanel.Visible = false
    elseif phase == "boss" then
        tps.Color = Color3.fromRGB(200, 30, 30)  -- borde rojo intenso en el panel
    end
end)

print("[CLIENT] RoundHUD cargado.")