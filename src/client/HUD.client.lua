-- ============================================
-- HUD.client.lua
-- Barra de vida + comida + agua
-- Contadores de botiquines y balas
-- Abajo izquierda — estilo horror
-- Ubicación: src/client/HUD.client.lua
-- ============================================

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris            = game:GetService("Debris")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

if playerGui:FindFirstChild("HUDGui") then
	playerGui.HUDGui:Destroy()
end

-- ════════════════════════════════════════════════
--  STATS DEL JUGADOR
-- ════════════════════════════════════════════════
local stats = {
	hp      = 100,
	hpMax   = 100,
	food    = 100,
	water   = 100,
	medkits = 0,
	ammo    = 0,
}

local FOOD_DRAIN_RATE  = 0.5
local WATER_DRAIN_RATE = 0.8

-- ════════════════════════════════════════════════
--  SCREEN GUI
-- ════════════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "HUDGui"
ScreenGui.ResetOnSpawn   = false
ScreenGui.DisplayOrder   = 5
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent         = playerGui

-- ════════════════════════════════════════════════
--  PANEL PRINCIPAL (abajo izquierda)
-- ════════════════════════════════════════════════
local Panel = Instance.new("Frame")
Panel.Name             = "Panel"
Panel.Size             = UDim2.new(0, 260, 0, 90)
Panel.Position         = UDim2.new(0, 14, 1, -14)
Panel.AnchorPoint      = Vector2.new(0, 1)
Panel.BackgroundColor3 = Color3.fromRGB(5, 0, 0)
Panel.BackgroundTransparency = 0.08
Panel.BorderSizePixel  = 0
Panel.Parent           = ScreenGui

local PanelCorner = Instance.new("UICorner")
PanelCorner.CornerRadius = UDim.new(0, 6)
PanelCorner.Parent = Panel

local PanelStroke = Instance.new("UIStroke")
PanelStroke.Color       = Color3.fromRGB(160, 20, 20)
PanelStroke.Thickness   = 1
PanelStroke.Transparency = 0.5
PanelStroke.Parent = Panel

-- ── Fila superior: nombre + badge ────────────
local TopRow = Instance.new("Frame")
TopRow.Size             = UDim2.new(1, -16, 0, 20)
TopRow.Position         = UDim2.new(0, 8, 0, 8)
TopRow.BackgroundTransparency = 1
TopRow.Parent           = Panel

local NameLabel = Instance.new("TextLabel")
NameLabel.Size             = UDim2.new(0.6, 0, 1, 0)
NameLabel.BackgroundTransparency = 1
NameLabel.Text             = player.DisplayName
NameLabel.TextColor3       = Color3.fromRGB(220, 200, 200)
NameLabel.Font             = Enum.Font.GothamBold
NameLabel.TextSize         = 11
NameLabel.TextXAlignment   = Enum.TextXAlignment.Left
NameLabel.Parent           = TopRow

local StatusBadge = Instance.new("TextLabel")
StatusBadge.Name             = "StatusBadge"
StatusBadge.Size             = UDim2.new(0, 60, 0, 16)
StatusBadge.Position         = UDim2.new(1, -60, 0.5, 0)
StatusBadge.AnchorPoint      = Vector2.new(0, 0.5)
StatusBadge.BackgroundColor3 = Color3.fromRGB(30, 5, 5)
StatusBadge.BackgroundTransparency = 0.3
StatusBadge.BorderSizePixel  = 0
StatusBadge.Text             = "ESTABLE"
StatusBadge.TextColor3       = Color3.fromRGB(200, 60, 60)
StatusBadge.Font             = Enum.Font.GothamBold
StatusBadge.TextSize         = 8
StatusBadge.TextXAlignment   = Enum.TextXAlignment.Center
StatusBadge.Parent           = TopRow

local BadgeCorner = Instance.new("UICorner")
BadgeCorner.CornerRadius = UDim.new(0, 3)
BadgeCorner.Parent = StatusBadge

local BadgeStroke = Instance.new("UIStroke")
BadgeStroke.Color       = Color3.fromRGB(160, 20, 20)
BadgeStroke.Thickness   = 1
BadgeStroke.Transparency = 0.4
BadgeStroke.Parent = StatusBadge

-- ════════════════════════════════════════════════
--  FUNCIÓN: crear una barra de stat
-- ════════════════════════════════════════════════
local barFills = {}

local function makeStatBar(name, iconText, iconColor, labelText, labelColor, yPos)
	local row = Instance.new("Frame")
	row.Name             = name .. "Row"
	row.Size             = UDim2.new(1, -16, 0, 12)
	row.Position         = UDim2.new(0, 8, 0, yPos)
	row.BackgroundTransparency = 1
	row.Parent           = Panel

	local icon = Instance.new("TextLabel")
	icon.Size             = UDim2.new(0, 12, 1, 0)
	icon.BackgroundTransparency = 1
	icon.Text             = iconText
	icon.TextColor3       = iconColor
	icon.Font             = Enum.Font.GothamBold
	icon.TextSize         = 10
	icon.TextXAlignment   = Enum.TextXAlignment.Center
	icon.Parent           = row

	local lbl = Instance.new("TextLabel")
	lbl.Size             = UDim2.new(0, 34, 1, 0)
	lbl.Position         = UDim2.new(0, 14, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text             = labelText
	lbl.TextColor3       = labelColor
	lbl.Font             = Enum.Font.GothamBold
	lbl.TextSize         = 8
	lbl.TextXAlignment   = Enum.TextXAlignment.Left
	lbl.Parent           = row

	local barBg = Instance.new("Frame")
	barBg.Size             = UDim2.new(1, -76, 1, 0)
	barBg.Position         = UDim2.new(0, 50, 0, 0)
	barBg.BackgroundColor3 = Color3.fromRGB(25, 8, 8)
	barBg.BackgroundTransparency = 0
	barBg.BorderSizePixel  = 0
	barBg.Parent           = row

	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0, 2)
	bgCorner.Parent = barBg

	local fill = Instance.new("Frame")
	fill.Name             = name .. "Fill"
	fill.Size             = UDim2.new(1, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(140, 25, 25)
	fill.BackgroundTransparency = 0
	fill.BorderSizePixel  = 0
	fill.Parent           = barBg

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 2)
	fillCorner.Parent = fill

	local shine = Instance.new("Frame")
	shine.Size             = UDim2.new(1, 0, 0.4, 0)
	shine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	shine.BackgroundTransparency = 0.88
	shine.BorderSizePixel  = 0
	shine.Parent           = fill
	local sc = Instance.new("UICorner")
	sc.CornerRadius = UDim.new(0, 2)
	sc.Parent = shine

	local num = Instance.new("TextLabel")
	num.Name             = name .. "Num"
	num.Size             = UDim2.new(0, 24, 1, 0)
	num.Position         = UDim2.new(1, -24, 0, 0)
	num.BackgroundTransparency = 1
	num.Text             = "100"
	num.TextColor3       = labelColor
	num.Font             = Enum.Font.GothamBold
	num.TextSize         = 8
	num.TextXAlignment   = Enum.TextXAlignment.Right
	num.Parent           = row

	barFills[name] = fill
	return fill, num
end

local hpFill,    hpNum    = makeStatBar("hp",    "♥", Color3.fromRGB(220,60,60),  "VIDA",   Color3.fromRGB(200,60,60),  32)
local foodFill,  foodNum  = makeStatBar("food",  "◆", Color3.fromRGB(200,150,70), "COMIDA", Color3.fromRGB(190,140,60), 48)
local waterFill, waterNum = makeStatBar("water", "▲", Color3.fromRGB(60,140,200), "AGUA",   Color3.fromRGB(60,130,190), 64)

local function getBarColor(pct, barType)
	if barType == "hp" then
		if pct > 0.6 then return Color3.fromRGB(140,25,25)
		elseif pct > 0.3 then return Color3.fromRGB(130,80,10)
		else return Color3.fromRGB(110,110,10) end
	elseif barType == "food" then
		if pct > 0.5 then return Color3.fromRGB(120,80,15)
		elseif pct > 0.25 then return Color3.fromRGB(100,60,10)
		else return Color3.fromRGB(80,40,8) end
	elseif barType == "water" then
		if pct > 0.5 then return Color3.fromRGB(20,70,120)
		elseif pct > 0.25 then return Color3.fromRGB(15,55,90)
		else return Color3.fromRGB(10,35,65) end
	end
end

-- ════════════════════════════════════════════════
--  PANEL DE RECURSOS
-- ════════════════════════════════════════════════
local ResPanel = Instance.new("Frame")
ResPanel.Name             = "Resources"
ResPanel.Size             = UDim2.new(0, 260, 0, 36)
ResPanel.Position         = UDim2.new(0, 14, 1, -110)
ResPanel.AnchorPoint      = Vector2.new(0, 1)
ResPanel.BackgroundTransparency = 1
ResPanel.Parent           = ScreenGui

local ResLayout = Instance.new("UIListLayout")
ResLayout.FillDirection       = Enum.FillDirection.Horizontal
ResLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
ResLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
ResLayout.Padding             = UDim.new(0, 6)
ResLayout.Parent              = ResPanel

local function makeResBox(name, iconText, iconColor, labelText, strokeColor)
	local box = Instance.new("Frame")
	box.Name             = name .. "Box"
	box.Size             = UDim2.new(0, 125, 1, 0)
	box.BackgroundColor3 = Color3.fromRGB(5, 0, 0)
	box.BackgroundTransparency = 0.08
	box.BorderSizePixel  = 0
	box.Parent           = ResPanel

	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 6)
	bc.Parent = box

	local bs = Instance.new("UIStroke")
	bs.Color = strokeColor
	bs.Thickness = 1
	bs.Transparency = 0.5
	bs.Parent = box

	local icon = Instance.new("TextLabel")
	icon.Size             = UDim2.new(0, 28, 1, 0)
	icon.Position         = UDim2.new(0, 6, 0, 0)
	icon.BackgroundTransparency = 1
	icon.Text             = iconText
	icon.TextColor3       = iconColor
	icon.Font             = Enum.Font.GothamBold
	icon.TextSize         = 16
	icon.TextXAlignment   = Enum.TextXAlignment.Center
	icon.Parent           = box

	local lbl = Instance.new("TextLabel")
	lbl.Size             = UDim2.new(0, 44, 0.5, 0)
	lbl.Position         = UDim2.new(0, 34, 0, 2)
	lbl.BackgroundTransparency = 1
	lbl.Text             = labelText
	lbl.TextColor3       = Color3.fromRGB(130, 110, 110)
	lbl.Font             = Enum.Font.Gotham
	lbl.TextSize         = 7
	lbl.TextXAlignment   = Enum.TextXAlignment.Left
	lbl.Parent           = box

	local count = Instance.new("TextLabel")
	count.Name           = name .. "Count"
	count.Size           = UDim2.new(0, 44, 0.5, 0)
	count.Position       = UDim2.new(0, 34, 0.5, 0)
	count.BackgroundTransparency = 1
	count.Text           = "0"
	count.TextColor3     = iconColor
	count.Font           = Enum.Font.GothamBold
	count.TextSize       = 13
	count.TextXAlignment = Enum.TextXAlignment.Left
	count.Parent         = box

	return count, bs
end

local medCount,  medStroke  = makeResBox("med",  "+", Color3.fromRGB(220,70,70),   "BOTIQUIN", Color3.fromRGB(180,40,40))
local ammoCount, ammoStroke = makeResBox("ammo", "•", Color3.fromRGB(220,200,100), "BALAS",    Color3.fromRGB(160,140,80))

-- ════════════════════════════════════════════════
--  ACTUALIZAR UI
-- ════════════════════════════════════════════════
local function updateHUD()
	local hpPct    = math.clamp(stats.hp    / stats.hpMax, 0, 1)
	local foodPct  = math.clamp(stats.food  / 100,         0, 1)
	local waterPct = math.clamp(stats.water / 100,         0, 1)

	TweenService:Create(hpFill,    TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = UDim2.new(hpPct,    0, 1, 0), BackgroundColor3 = getBarColor(hpPct,    "hp")    }):Play()
	TweenService:Create(foodFill,  TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = UDim2.new(foodPct,  0, 1, 0), BackgroundColor3 = getBarColor(foodPct,  "food")  }):Play()
	TweenService:Create(waterFill, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = UDim2.new(waterPct, 0, 1, 0), BackgroundColor3 = getBarColor(waterPct, "water") }):Play()

	hpNum.Text    = math.floor(stats.hp)
	foodNum.Text  = math.floor(stats.food)
	waterNum.Text = math.floor(stats.water)

	medCount.Text  = tostring(stats.medkits)
	ammoCount.Text = tostring(stats.ammo)

	medStroke.Color        = stats.medkits == 0 and Color3.fromRGB(220,60,60)  or Color3.fromRGB(180,40,40)
	medStroke.Transparency = stats.medkits == 0 and 0.1 or 0.5
	ammoStroke.Color        = stats.ammo == 0 and Color3.fromRGB(220,180,40)   or Color3.fromRGB(160,140,80)
	ammoStroke.Transparency = stats.ammo == 0 and 0.1 or 0.5

	local minStat = math.min(hpPct, foodPct, waterPct)
	if minStat > 0.6 then
		StatusBadge.Text       = "ESTABLE"
		StatusBadge.TextColor3 = Color3.fromRGB(200,60,60)
		BadgeStroke.Color      = Color3.fromRGB(160,20,20)
		PanelStroke.Color      = Color3.fromRGB(160,20,20)
	elseif minStat > 0.3 then
		StatusBadge.Text       = "PELIGRO"
		StatusBadge.TextColor3 = Color3.fromRGB(220,160,40)
		BadgeStroke.Color      = Color3.fromRGB(180,120,0)
		PanelStroke.Color      = Color3.fromRGB(180,120,0)
	else
		StatusBadge.Text       = "CRITICO"
		StatusBadge.TextColor3 = Color3.fromRGB(220,220,40)
		BadgeStroke.Color      = Color3.fromRGB(200,200,0)
		PanelStroke.Color      = Color3.fromRGB(200,200,0)
	end
end

-- ════════════════════════════════════════════════
--  DRENADO DE COMIDA Y AGUA
-- ════════════════════════════════════════════════
local drainTimer = 0

RunService.Heartbeat:Connect(function(dt)
	drainTimer = drainTimer + dt
	if drainTimer >= 1 then
		drainTimer = 0
		stats.food  = math.max(0, stats.food  - FOOD_DRAIN_RATE  / 60)
		stats.water = math.max(0, stats.water - WATER_DRAIN_RATE / 60)

		if stats.food <= 0 or stats.water <= 0 then
			local character = player.Character
			if character then
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.Health > 0 then
					humanoid.Health = math.max(0, humanoid.Health - 0.5)
				end
			end
		end
		updateHUD()
	end
end)

-- ════════════════════════════════════════════════
--  EVENTOS DEL SERVIDOR
-- ════════════════════════════════════════════════
local remotes   = ReplicatedStorage:WaitForChild("Remotes")
local onDamaged = remotes:WaitForChild("PlayerDamaged")

onDamaged.OnClientEvent:Connect(function(currentHp, maxHp)
	stats.hp    = currentHp
	stats.hpMax = maxHp
	updateHUD()

	-- Flash rojo pantalla completa (una sola vez, desaparece solo)
	local flash = Instance.new("Frame")
	flash.Size             = UDim2.new(1, 0, 1, 0)
	flash.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
	flash.BackgroundTransparency = 0.5
	flash.BorderSizePixel  = 0
	flash.ZIndex           = 99
	flash.Parent           = ScreenGui
	TweenService:Create(flash,
		TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 1 }):Play()
	Debris:AddItem(flash, 0.5)

	-- Sonido de golpe
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://9120386446"
	sound.Volume  = 0.8
	sound.Parent  = playerGui
	sound:Play()
	Debris:AddItem(sound, 2)
end)

-- ════════════════════════════════════════════════
--  FUNCIONES PÚBLICAS
-- ════════════════════════════════════════════════
local function addMedkit(amount)
	stats.medkits = stats.medkits + (amount or 1)
	updateHUD()
end

local function addAmmo(amount)
	stats.ammo = stats.ammo + (amount or 10)
	updateHUD()
end

local function useMedkit()
	if stats.medkits <= 0 then return end
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	stats.medkits = stats.medkits - 1
	humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + 50)
	stats.hp    = humanoid.Health
	stats.food  = math.min(100, stats.food  + 10)
	stats.water = math.min(100, stats.water + 5)
	updateHUD()
	print("[CLIENT] Botiquín usado. Quedan:", stats.medkits)
end

-- Tecla H → usar botiquín
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.H then
		useMedkit()
	end
end)

-- ── Conectar al personaje ─────────────────────
local function onCharacter(character)
	local humanoid = character:WaitForChild("Humanoid")
	stats.hp    = humanoid.Health
	stats.hpMax = humanoid.MaxHealth
	humanoid.HealthChanged:Connect(function(hp)
		stats.hp = hp
		updateHUD()
	end)
	updateHUD()
end

player.CharacterAdded:Connect(onCharacter)
if player.Character then onCharacter(player.Character) end

-- Exponer para otros scripts
local addMedkitEvent = Instance.new("BindableEvent")
addMedkitEvent.Name   = "AddMedkit"
addMedkitEvent.Parent = ReplicatedStorage
addMedkitEvent.Event:Connect(function(amt) addMedkit(amt) end)

local addAmmoEvent = Instance.new("BindableEvent")
addAmmoEvent.Name   = "AddAmmo"
addAmmoEvent.Parent = ReplicatedStorage
addAmmoEvent.Event:Connect(function(amt) addAmmo(amt) end)

updateHUD()
print("[CLIENT] HUD cargado — H para usar botiquín.")