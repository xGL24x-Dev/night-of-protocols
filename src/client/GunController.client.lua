-- ============================================
-- GunController.client.lua
-- Maneja: disparo, HUD munición, retroceso
-- Ubicación: StarterPlayer/StarterCharacterScripts
-- ============================================

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local Debris           = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local character = script.Parent
local playerGui = player:WaitForChild("PlayerGui")
local camera    = workspace.CurrentCamera

-- ════════════════════════════════════════════════
--  CONFIGURACIÓN
-- ════════════════════════════════════════════════
local MAX_AMMO  = 17
local DAMAGE    = 35
local FIRE_RATE = 0.15
local RANGE     = 300

-- ════════════════════════════════════════════════
--  ESTADO
-- ════════════════════════════════════════════════
local equipped  = false
local ammo      = MAX_AMMO
local canShoot  = true
local recoil    = 0

-- ════════════════════════════════════════════════
--  HUD MUNICIÓN
-- ════════════════════════════════════════════════
-- Limpiar HUD anterior si existe
if playerGui:FindFirstChild("GlockHUD") then
	playerGui.GlockHUD:Destroy()
end

local gui = Instance.new("ScreenGui", playerGui)
gui.Name = "GlockHUD"; gui.ResetOnSpawn = false; gui.DisplayOrder = 10

local panel = Instance.new("Frame", gui)
panel.Size             = UDim2.new(0, 130, 0, 52)
panel.Position         = UDim2.new(1, -144, 1, -120)
panel.BackgroundColor3 = Color3.fromRGB(5, 0, 0)
panel.BackgroundTransparency = 0.08
panel.BorderSizePixel  = 0
panel.Visible          = false
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 6)
local pStroke = Instance.new("UIStroke", panel)
pStroke.Color = Color3.fromRGB(160, 140, 60); pStroke.Thickness = 1

local gunLbl = Instance.new("TextLabel", panel)
gunLbl.Size = UDim2.new(1,-8,0,16); gunLbl.Position = UDim2.new(0,4,0,4)
gunLbl.BackgroundTransparency = 1; gunLbl.Text = "GLOCK-17"
gunLbl.TextColor3 = Color3.fromRGB(180,160,80)
gunLbl.Font = Enum.Font.GothamBold; gunLbl.TextSize = 9
gunLbl.TextXAlignment = Enum.TextXAlignment.Left

local ammoLbl = Instance.new("TextLabel", panel)
ammoLbl.Size = UDim2.new(0.55,0,0,28); ammoLbl.Position = UDim2.new(0,4,0,20)
ammoLbl.BackgroundTransparency = 1; ammoLbl.Text = "17"
ammoLbl.TextColor3 = Color3.fromRGB(220,200,100)
ammoLbl.Font = Enum.Font.GothamBold; ammoLbl.TextSize = 24
ammoLbl.TextXAlignment = Enum.TextXAlignment.Left

local ammoMaxLbl = Instance.new("TextLabel", panel)
ammoMaxLbl.Size = UDim2.new(0.45,-4,0,28); ammoMaxLbl.Position = UDim2.new(0.55,0,0,24)
ammoMaxLbl.BackgroundTransparency = 1; ammoMaxLbl.Text = "/ 17"
ammoMaxLbl.TextColor3 = Color3.fromRGB(120,110,60)
ammoMaxLbl.Font = Enum.Font.Gotham; ammoMaxLbl.TextSize = 13
ammoMaxLbl.TextXAlignment = Enum.TextXAlignment.Left

local emptyLbl = Instance.new("TextLabel", panel)
emptyLbl.Size = UDim2.new(1,-8,0,28); emptyLbl.Position = UDim2.new(0,4,0,20)
emptyLbl.BackgroundTransparency = 1; emptyLbl.Text = "SIN BALAS"
emptyLbl.TextColor3 = Color3.fromRGB(220,60,60)
emptyLbl.Font = Enum.Font.GothamBold; emptyLbl.TextSize = 13
emptyLbl.TextXAlignment = Enum.TextXAlignment.Center
emptyLbl.Visible = false

local function updateHUD()
	if ammo <= 0 then
		ammoLbl.Visible    = false
		ammoMaxLbl.Visible = false
		emptyLbl.Visible   = true
		pStroke.Color      = Color3.fromRGB(220, 60, 60)
	else
		ammoLbl.Visible    = true
		ammoMaxLbl.Visible = true
		emptyLbl.Visible   = false
		ammoLbl.Text       = tostring(ammo)
		pStroke.Color      = ammo <= 5
			and Color3.fromRGB(220, 120, 40)
			or  Color3.fromRGB(160, 140, 60)
	end
end

-- ════════════════════════════════════════════════
--  RETROCESO DE CÁMARA
-- ════════════════════════════════════════════════
RunService.RenderStepped:Connect(function(dt)
	if recoil > 0 then
		recoil = math.max(0, recoil - dt * 4)
		camera.CFrame = camera.CFrame * CFrame.Angles(
			math.rad(-recoil * 10),
			math.rad((math.random() - 0.5) * recoil * 2),
			0
		)
	end
end)

-- ════════════════════════════════════════════════
--  EFECTOS VISUALES DE BALA
-- ════════════════════════════════════════════════
local function bulletEffect(origin, hitPos)
	-- Línea de bala
	local dist = (hitPos - origin).Magnitude
	local part = Instance.new("Part")
	part.Size       = Vector3.new(0.04, 0.04, dist)
	part.CFrame     = CFrame.lookAt((origin+hitPos)/2, hitPos) * CFrame.new(0,0,-dist/2)
	part.Anchored   = true; part.CanCollide = false
	part.Material   = Enum.Material.Neon
	part.BrickColor = BrickColor.new("Bright yellow")
	part.CastShadow = false; part.Parent = workspace
	Debris:AddItem(part, 0.05)

	-- Marca de impacto
	local imp = Instance.new("Part")
	imp.Size       = Vector3.new(0.15, 0.15, 0.04)
	imp.CFrame     = CFrame.new(hitPos)
	imp.Anchored   = true; imp.CanCollide = false
	imp.BrickColor = BrickColor.new("Dark orange")
	imp.Parent     = workspace
	Debris:AddItem(imp, 3)

	-- Sonido de disparo
	local sound = Instance.new("Sound", character:FindFirstChild("HumanoidRootPart") or character)
	sound.SoundId = "rbxassetid://9045799572"
	sound.Volume  = 0.8
	sound:Play()
	Debris:AddItem(sound, 2)
end

-- ════════════════════════════════════════════════
--  DAÑO (via RemoteEvent al servidor)
-- ════════════════════════════════════════════════
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local onShoot = remotes:WaitForChild("GunShoot")

-- ════════════════════════════════════════════════
--  DETECTAR CUANDO SE RECOGE EL ARMA
-- ════════════════════════════════════════════════
local function onGlockPickedUp()
	equipped = true
	ammo     = MAX_AMMO
	panel.Visible = true
	updateHUD()
	print("[GUN] Glock equipada —", ammo, "balas")
end

-- Observar si aparece el BoolValue HasGlock en el personaje
character.ChildAdded:Connect(function(child)
	if child.Name == "HasGlock" then
		onGlockPickedUp()
	end
end)

-- Por si ya lo tenía al cargar
if character:FindFirstChild("HasGlock") then
	onGlockPickedUp()
end

-- ════════════════════════════════════════════════
--  CLIC IZQUIERDO → DISPARAR
-- ════════════════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if not equipped then return end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
	if not canShoot then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end
	local isDown = character:FindFirstChild("IsDowned")
	if isDown and isDown.Value then return end

	if ammo <= 0 then
		updateHUD()
		-- Sonido de click vacío
		local s = Instance.new("Sound", character:FindFirstChild("HumanoidRootPart") or character)
		s.SoundId = "rbxassetid://3145453220"
		s.Volume = 0.5; s:Play()
		Debris:AddItem(s, 1)
		return
	end

	canShoot = false
	ammo     = ammo - 1
	updateHUD()
	recoil   = math.clamp(recoil + 0.07, 0, 0.35)

	-- Raycast desde la cámara
	local ray = camera:ScreenPointToRay(
		camera.ViewportSize.X / 2,
		camera.ViewportSize.Y / 2
	)
	local spread = 0.015
	local dir = (ray.Direction + Vector3.new(
		(math.random()-0.5) * spread,
		(math.random()-0.5) * spread,
		0
	)).Unit

	-- Efectos visuales locales
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { character }
	params.FilterType = Enum.RaycastFilterType.Exclude
	local result = workspace:Raycast(ray.Origin, dir * RANGE, params)
	local hitPos = result and result.Position or (ray.Origin + dir * RANGE)
	bulletEffect(ray.Origin, hitPos)

	-- Enviar al servidor para aplicar daño
	onShoot:FireServer(ray.Origin, dir)

	task.wait(FIRE_RATE)
	canShoot = true
end)

print("[GUN] GunController listo.")