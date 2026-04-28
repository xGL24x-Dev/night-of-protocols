-- ============================================
-- HUD.client.lua
-- · Barra vida / comida / agua
-- · Contadores botiquines y balas
-- · Flash de daño y sonido de golpe
-- · Indicador de daño flotante
-- Ubicación: src/client/HUD.client.lua
-- ============================================

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris            = game:GetService("Debris")
local StarterGui        = game:GetService("StarterGui")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Quitar barra de vida nativa de Roblox
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)

if playerGui:FindFirstChild("HUDGui") then
	playerGui.HUDGui:Destroy()
end

-- ════════════════════════════════════════════════
--  STATS
-- ════════════════════════════════════════════════
local stats = {
	hp      = 100,
	hpMax   = 100,
	food    = 100,
	water   = 100,
	medkits = 0,
	ammo    = 0,
}

-- Drenado de comida y agua (por segundo real)
local FOOD_DRAIN  = 0.03   -- baja ~1.8 por minuto
local WATER_DRAIN = 0.05   -- baja ~3 por minuto

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
--  PANEL PRINCIPAL
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
Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 6)

local PanelStroke = Instance.new("UIStroke", Panel)
PanelStroke.Color       = Color3.fromRGB(160, 20, 20)
PanelStroke.Thickness   = 1
PanelStroke.Transparency = 0.5

-- Fila superior
local TopRow = Instance.new("Frame", Panel)
TopRow.Size             = UDim2.new(1, -16, 0, 20)
TopRow.Position         = UDim2.new(0, 8, 0, 8)
TopRow.BackgroundTransparency = 1

local NameLabel = Instance.new("TextLabel", TopRow)
NameLabel.Size             = UDim2.new(0.6, 0, 1, 0)
NameLabel.BackgroundTransparency = 1
NameLabel.Text             = player.DisplayName
NameLabel.TextColor3       = Color3.fromRGB(220, 200, 200)
NameLabel.Font             = Enum.Font.GothamBold
NameLabel.TextSize         = 11
NameLabel.TextXAlignment   = Enum.TextXAlignment.Left

local StatusBadge = Instance.new("TextLabel", TopRow)
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
Instance.new("UICorner", StatusBadge).CornerRadius = UDim.new(0, 3)
local BadgeStroke = Instance.new("UIStroke", StatusBadge)
BadgeStroke.Color = Color3.fromRGB(160, 20, 20); BadgeStroke.Thickness = 1; BadgeStroke.Transparency = 0.4

-- ════════════════════════════════════════════════
--  BARRAS DE STATS
-- ════════════════════════════════════════════════
local barFills = {}
local barNums  = {}

local function makeStatBar(name, iconText, iconColor, labelText, labelColor, yPos)
	local row = Instance.new("Frame", Panel)
	row.Size             = UDim2.new(1, -16, 0, 12)
	row.Position         = UDim2.new(0, 8, 0, yPos)
	row.BackgroundTransparency = 1

	local icon = Instance.new("TextLabel", row)
	icon.Size = UDim2.new(0, 12, 1, 0); icon.BackgroundTransparency = 1
	icon.Text = iconText; icon.TextColor3 = iconColor
	icon.Font = Enum.Font.GothamBold; icon.TextSize = 10
	icon.TextXAlignment = Enum.TextXAlignment.Center

	local lbl = Instance.new("TextLabel", row)
	lbl.Size = UDim2.new(0, 34, 1, 0); lbl.Position = UDim2.new(0, 14, 0, 0)
	lbl.BackgroundTransparency = 1; lbl.Text = labelText
	lbl.TextColor3 = labelColor; lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 8; lbl.TextXAlignment = Enum.TextXAlignment.Left

	local barBg = Instance.new("Frame", row)
	barBg.Size = UDim2.new(1, -76, 1, 0); barBg.Position = UDim2.new(0, 50, 0, 0)
	barBg.BackgroundColor3 = Color3.fromRGB(25, 8, 8); barBg.BorderSizePixel = 0
	Instance.new("UICorner", barBg).CornerRadius = UDim.new(0, 2)

	local fill = Instance.new("Frame", barBg)
	fill.Size = UDim2.new(1, 0, 1, 0); fill.BackgroundColor3 = Color3.fromRGB(140, 25, 25)
	fill.BorderSizePixel = 0
	Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 2)

	local shine = Instance.new("Frame", fill)
	shine.Size = UDim2.new(1, 0, 0.4, 0); shine.BackgroundColor3 = Color3.fromRGB(255,255,255)
	shine.BackgroundTransparency = 0.88; shine.BorderSizePixel = 0
	Instance.new("UICorner", shine).CornerRadius = UDim.new(0, 2)

	local num = Instance.new("TextLabel", row)
	num.Size = UDim2.new(0, 24, 1, 0); num.Position = UDim2.new(1, -24, 0, 0)
	num.BackgroundTransparency = 1; num.Text = "100"
	num.TextColor3 = labelColor; num.Font = Enum.Font.GothamBold
	num.TextSize = 8; num.TextXAlignment = Enum.TextXAlignment.Right

	barFills[name] = fill
	barNums[name]  = num
	return fill, num
end

makeStatBar("hp",    "♥", Color3.fromRGB(220,60,60),  "VIDA",   Color3.fromRGB(200,60,60),  32)
makeStatBar("food",  "◆", Color3.fromRGB(200,150,70), "COMIDA", Color3.fromRGB(190,140,60), 48)
makeStatBar("water", "▲", Color3.fromRGB(60,140,200), "AGUA",   Color3.fromRGB(60,130,190), 64)

local function getBarColor(pct, t)
	if t == "hp" then
		return pct > 0.6 and Color3.fromRGB(140,25,25) or pct > 0.3 and Color3.fromRGB(130,80,10) or Color3.fromRGB(110,110,10)
	elseif t == "food" then
		return pct > 0.5 and Color3.fromRGB(120,80,15) or pct > 0.25 and Color3.fromRGB(100,60,10) or Color3.fromRGB(80,40,8)
	elseif t == "water" then
		return pct > 0.5 and Color3.fromRGB(20,70,120) or pct > 0.25 and Color3.fromRGB(15,55,90) or Color3.fromRGB(10,35,65)
	end
end

-- ════════════════════════════════════════════════
--  PANEL DE RECURSOS
-- ════════════════════════════════════════════════
local ResPanel = Instance.new("Frame", ScreenGui)
ResPanel.Size             = UDim2.new(0, 260, 0, 36)
ResPanel.Position         = UDim2.new(0, 14, 1, -110)
ResPanel.AnchorPoint      = Vector2.new(0, 1)
ResPanel.BackgroundTransparency = 1

local ResLayout = Instance.new("UIListLayout", ResPanel)
ResLayout.FillDirection = Enum.FillDirection.Horizontal
ResLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
ResLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
ResLayout.Padding = UDim.new(0, 6)

local medCountLabel, medStroke, ammoCountLabel, ammoStroke

local function makeResBox(name, iconText, iconColor, labelText, strokeColor)
	local box = Instance.new("Frame", ResPanel)
	box.Size = UDim2.new(0, 125, 1, 0)
	box.BackgroundColor3 = Color3.fromRGB(5, 0, 0); box.BackgroundTransparency = 0.08
	box.BorderSizePixel = 0
	Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
	local bs = Instance.new("UIStroke", box)
	bs.Color = strokeColor; bs.Thickness = 1; bs.Transparency = 0.5

	local icon = Instance.new("TextLabel", box)
	icon.Size = UDim2.new(0, 28, 1, 0); icon.Position = UDim2.new(0, 6, 0, 0)
	icon.BackgroundTransparency = 1; icon.Text = iconText
	icon.TextColor3 = iconColor; icon.Font = Enum.Font.GothamBold
	icon.TextSize = 16; icon.TextXAlignment = Enum.TextXAlignment.Center

	local lbl = Instance.new("TextLabel", box)
	lbl.Size = UDim2.new(0, 44, 0.5, 0); lbl.Position = UDim2.new(0, 34, 0, 2)
	lbl.BackgroundTransparency = 1; lbl.Text = labelText
	lbl.TextColor3 = Color3.fromRGB(130, 110, 110); lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 7; lbl.TextXAlignment = Enum.TextXAlignment.Left

	local count = Instance.new("TextLabel", box)
	count.Size = UDim2.new(0, 44, 0.5, 0); count.Position = UDim2.new(0, 34, 0.5, 0)
	count.BackgroundTransparency = 1; count.Text = "0"
	count.TextColor3 = iconColor; count.Font = Enum.Font.GothamBold
	count.TextSize = 13; count.TextXAlignment = Enum.TextXAlignment.Left

	return count, bs
end

medCountLabel, medStroke   = makeResBox("med",  "+", Color3.fromRGB(220,70,70),   "BOTIQUIN", Color3.fromRGB(180,40,40))
ammoCountLabel, ammoStroke = makeResBox("ammo", "•", Color3.fromRGB(220,200,100), "BALAS",    Color3.fromRGB(160,140,80))

-- ════════════════════════════════════════════════
--  INDICADOR DE DAÑO FLOTANTE
-- ════════════════════════════════════════════════
local function showDamageIndicator(amount, onSelf)
	local label = Instance.new("TextLabel", ScreenGui)
	label.Size             = UDim2.new(0, 80, 0, 30)
	label.BackgroundTransparency = 1
	label.BorderSizePixel  = 0
	label.ZIndex           = 20
	label.Font             = Enum.Font.GothamBold

	if onSelf then
		-- Daño recibido — rojo, aparece en el centro
		label.Text       = "-" .. tostring(math.floor(amount))
		label.TextColor3 = Color3.fromRGB(220, 50, 50)
		label.TextSize   = 20
		label.Position   = UDim2.new(0.5, -40, 0.45, 0)
	else
		-- Daño hecho — amarillo, aparece arriba centro
		label.Text       = "-" .. tostring(math.floor(amount))
		label.TextColor3 = Color3.fromRGB(220, 200, 50)
		label.TextSize   = 16
		label.Position   = UDim2.new(0.5, -40, 0.38, 0)
	end

	-- Flotar hacia arriba y desvanecerse
	TweenService:Create(label,
		TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = label.Position + UDim2.new(0, 0, -0.08, 0),
		  TextTransparency = 1 }):Play()
	Debris:AddItem(label, 0.9)
end

-- ════════════════════════════════════════════════
--  ACTUALIZAR HUD
-- ════════════════════════════════════════════════
local function updateHUD()
	local hpPct    = math.clamp(stats.hp    / stats.hpMax, 0, 1)
	local foodPct  = math.clamp(stats.food  / 100, 0, 1)
	local waterPct = math.clamp(stats.water / 100, 0, 1)

	TweenService:Create(barFills["hp"],    TweenInfo.new(0.25),
		{ Size = UDim2.new(hpPct,    0, 1, 0), BackgroundColor3 = getBarColor(hpPct,    "hp")    }):Play()
	TweenService:Create(barFills["food"],  TweenInfo.new(0.25),
		{ Size = UDim2.new(foodPct,  0, 1, 0), BackgroundColor3 = getBarColor(foodPct,  "food")  }):Play()
	TweenService:Create(barFills["water"], TweenInfo.new(0.25),
		{ Size = UDim2.new(waterPct, 0, 1, 0), BackgroundColor3 = getBarColor(waterPct, "water") }):Play()

	barNums["hp"].Text    = math.floor(stats.hp)
	barNums["food"].Text  = math.floor(stats.food)
	barNums["water"].Text = math.floor(stats.water)

	medCountLabel.Text  = tostring(stats.medkits)
	ammoCountLabel.Text = tostring(stats.ammo)

	medStroke.Color        = stats.medkits == 0 and Color3.fromRGB(220,60,60)  or Color3.fromRGB(180,40,40)
	medStroke.Transparency = stats.medkits == 0 and 0.1 or 0.5
	ammoStroke.Color        = stats.ammo == 0 and Color3.fromRGB(220,180,40)   or Color3.fromRGB(160,140,80)
	ammoStroke.Transparency = stats.ammo == 0 and 0.1 or 0.5

	local minStat = math.min(hpPct, foodPct, waterPct)
	if minStat > 0.6 then
		StatusBadge.Text = "ESTABLE"; StatusBadge.TextColor3 = Color3.fromRGB(200,60,60)
		BadgeStroke.Color = Color3.fromRGB(160,20,20); PanelStroke.Color = Color3.fromRGB(160,20,20)
	elseif minStat > 0.3 then
		StatusBadge.Text = "PELIGRO"; StatusBadge.TextColor3 = Color3.fromRGB(220,160,40)
		BadgeStroke.Color = Color3.fromRGB(180,120,0); PanelStroke.Color = Color3.fromRGB(180,120,0)
	else
		StatusBadge.Text = "CRITICO"; StatusBadge.TextColor3 = Color3.fromRGB(220,220,40)
		BadgeStroke.Color = Color3.fromRGB(200,200,0); PanelStroke.Color = Color3.fromRGB(200,200,0)
	end
end

-- ════════════════════════════════════════════════
--  DRENADO DE COMIDA Y AGUA (solo visual, no daña)
-- El daño por hambre/sed lo maneja el servidor
-- ════════════════════════════════════════════════
local drainTimer = 0
RunService.Heartbeat:Connect(function(dt)
	drainTimer = drainTimer + dt
	if drainTimer >= 1 then
		drainTimer = 0
		stats.food  = math.max(0, stats.food  - FOOD_DRAIN)
		stats.water = math.max(0, stats.water - WATER_DRAIN)
		updateHUD()
	end
end)

-- ════════════════════════════════════════════════
--  EVENTOS DEL SERVIDOR
-- ════════════════════════════════════════════════
local remotes   = ReplicatedStorage:WaitForChild("Remotes")
local onDamaged = remotes:WaitForChild("PlayerDamaged")

local lastHp = 100

onDamaged.OnClientEvent:Connect(function(currentHp, maxHp)
	local dmgAmount = lastHp - currentHp
	lastHp  = currentHp
	stats.hp    = currentHp
	stats.hpMax = maxHp
	updateHUD()

	-- Indicador de daño recibido
	if dmgAmount > 0 then
		showDamageIndicator(dmgAmount, true)
	end

	-- Sonido de golpe
	local sound = Instance.new("Sound", playerGui)
	sound.SoundId = "rbxassetid://9120386446"
	sound.Volume  = 0.8
	sound:Play()
	Debris:AddItem(sound, 2)

	-- Flash rojo solo bajo 20% de vida
	local hpPct = maxHp > 0 and (currentHp / maxHp) or 0
	if hpPct < 0.2 then
		local flash = Instance.new("Frame", ScreenGui)
		flash.Size = UDim2.new(1,0,1,0)
		flash.BackgroundColor3 = Color3.fromRGB(180,0,0)
		flash.BackgroundTransparency = 0.5
		flash.BorderSizePixel = 0; flash.ZIndex = 99
		TweenService:Create(flash, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 1 }):Play()
		Debris:AddItem(flash, 0.5)
	end
end)

-- Daño hecho a otro jugador (para mostrar el indicador amarillo)
local onMeleeEffect = remotes:WaitForChild("MeleeEffect")
onMeleeEffect.OnClientEvent:Connect(function(attacker, weaponType, _)
	if attacker ~= player then return end
	-- El indicador lo muestra el MeleeClient
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

	-- No usar botiquín si está tumbado
	local isDown = character:FindFirstChild("IsDowned")
	if isDown and isDown.Value then return end

	stats.medkits = stats.medkits - 1
	humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + 50)
	stats.hp    = humanoid.Health
	stats.food  = math.min(100, stats.food  + 10)
	stats.water = math.min(100, stats.water + 5)
	updateHUD()
	print("[CLIENT] Botiquín usado. Quedan:", stats.medkits)
end

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.H then useMedkit() end
end)

-- ════════════════════════════════════════════════
--  SINCRONIZAR CON EL PERSONAJE
-- ════════════════════════════════════════════════
local function onCharacter(character)
	local humanoid = character:WaitForChild("Humanoid")

	-- Esperar a que Roblox termine de inicializar el personaje
	task.wait(0.2)

	-- Siempre iniciar con 100% de todo
	stats.hp    = humanoid.MaxHealth
	stats.hpMax = humanoid.MaxHealth
	stats.food  = 100
	stats.water = 100
	lastHp      = humanoid.MaxHealth

	-- Forzar vida al máximo al entrar/respawnear
	humanoid.Health = humanoid.MaxHealth

	-- Escuchar cambios de vida DESPUÉS de inicializar
	humanoid.HealthChanged:Connect(function(hp)
		stats.hp = math.max(0, hp)
		lastHp   = stats.hp
		updateHUD()
	end)

	updateHUD()
	print("[CLIENT] Personaje listo — vida:", stats.hp, "/ comida: 100 / agua: 100")
end

player.CharacterAdded:Connect(onCharacter)
if player.Character then onCharacter(player.Character) end

-- Exponer eventos para otros scripts
local addMedkitEvent = Instance.new("BindableEvent", ReplicatedStorage)
addMedkitEvent.Name = "AddMedkit"
addMedkitEvent.Event:Connect(function(amt) addMedkit(amt) end)

local addAmmoEvent = Instance.new("BindableEvent", ReplicatedStorage)
addAmmoEvent.Name = "AddAmmo"
addAmmoEvent.Event:Connect(function(amt) addAmmo(amt) end)

-- Exponer función para mostrar daño hecho (lo llama MeleeClient)
local showDmgEvent = Instance.new("BindableEvent", ReplicatedStorage)
showDmgEvent.Name = "ShowDamageIndicator"
showDmgEvent.Event:Connect(function(amount) showDamageIndicator(amount, false) end)

updateHUD()
print("[CLIENT] HUD cargado — H para usar botiquín.")