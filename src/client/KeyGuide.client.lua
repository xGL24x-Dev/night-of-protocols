-- ============================================
-- KeyGuide.client.lua
-- Guía de teclas — presiona L para mostrar/ocultar
-- Ubicación: src/client/KeyGuide.client.lua
-- ============================================

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

if playerGui:FindFirstChild("KeyGuideGui") then
	playerGui.KeyGuideGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name         = "KeyGuideGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 99
ScreenGui.Parent       = playerGui

-- ════════════════════════════════════════════
--  PANEL
-- ════════════════════════════════════════════
local Panel = Instance.new("Frame")
Panel.Size             = UDim2.new(0, 200, 0, 290)
Panel.Position         = UDim2.new(1, -10, 0.5, -145)
Panel.BackgroundColor3 = Color3.fromRGB(8, 8, 14)
Panel.BackgroundTransparency = 0.05
Panel.BorderSizePixel  = 0
Panel.Visible          = false
Panel.Parent           = ScreenGui

local pc = Instance.new("UICorner")
pc.CornerRadius = UDim.new(0, 12)
pc.Parent = Panel

local ps = Instance.new("UIStroke")
ps.Color       = Color3.fromRGB(100, 80, 200)
ps.Thickness   = 1.5
ps.Transparency = 0.3
ps.Parent = Panel

-- Header
local Header = Instance.new("Frame")
Header.Size             = UDim2.new(1, 0, 0, 40)
Header.BackgroundColor3 = Color3.fromRGB(14, 10, 28)
Header.BackgroundTransparency = 0
Header.BorderSizePixel  = 0
Header.Parent           = Panel

local hc = Instance.new("UICorner")
hc.CornerRadius = UDim.new(0, 12)
hc.Parent = Header

local hp = Instance.new("Frame")
hp.Size             = UDim2.new(1, 0, 0, 12)
hp.Position         = UDim2.new(0, 0, 1, -12)
hp.BackgroundColor3 = Color3.fromRGB(14, 10, 28)
hp.BackgroundTransparency = 0
hp.BorderSizePixel  = 0
hp.Parent = Header

local title = Instance.new("TextLabel")
title.Size           = UDim2.new(1, -12, 1, 0)
title.Position       = UDim2.new(0, 12, 0, 0)
title.BackgroundTransparency = 1
title.Text           = "⌨  CONTROLES"
title.TextColor3     = Color3.fromRGB(190, 175, 255)
title.Font           = Enum.Font.GothamBold
title.TextSize       = 13
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent         = Header

-- ════════════════════════════════════════════
--  FILAS
-- ════════════════════════════════════════════
local controls = {
	{ key="W A S D", action="Moverse",    icon="🚶", color=Color3.fromRGB(200,200,220) },
	{ key="Shift",   action="Correr",     icon="💨", color=Color3.fromRGB(200,200,220) },
	{ key="F",       action="Linterna",   icon="🔦", color=Color3.fromRGB(255,210,80)  },
	{ key="G",       action="Mochila",    icon="🎒", color=Color3.fromRGB(80,180,255)  },
	{ key="E",       action="Interactuar",icon="👆", color=Color3.fromRGB(80,255,160)  },
	{ key="R",       action="Generador",  icon="⚡", color=Color3.fromRGB(255,160,40)  },
	{ key="M",       action="Mapa",       icon="🗺", color=Color3.fromRGB(180,140,255) },
	{ key="L",       action="Controles",  icon="⌨",  color=Color3.fromRGB(150,130,220) },
}

local listFrame = Instance.new("Frame")
listFrame.Size             = UDim2.new(1, -12, 1, -48)
listFrame.Position         = UDim2.new(0, 6, 0, 44)
listFrame.BackgroundTransparency = 1
listFrame.Parent           = Panel

local layout = Instance.new("UIListLayout")
layout.FillDirection       = Enum.FillDirection.Vertical
layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
layout.Padding             = UDim.new(0, 3)
layout.Parent              = listFrame

for _, ctrl in ipairs(controls) do
	local row = Instance.new("Frame")
	row.Size             = UDim2.new(1, 0, 0, 28)
	row.BackgroundColor3 = Color3.fromRGB(16, 13, 28)
	row.BackgroundTransparency = 0.3
	row.BorderSizePixel  = 0
	row.Parent           = listFrame

	local rc = Instance.new("UICorner")
	rc.CornerRadius = UDim.new(0, 6)
	rc.Parent = row

	local ico = Instance.new("TextLabel")
	ico.Size             = UDim2.new(0, 24, 1, 0)
	ico.Position         = UDim2.new(0, 4, 0, 0)
	ico.BackgroundTransparency = 1
	ico.Text             = ctrl.icon
	ico.Font             = Enum.Font.GothamBold
	ico.TextSize         = 13
	ico.TextXAlignment   = Enum.TextXAlignment.Center
	ico.Parent           = row

	local act = Instance.new("TextLabel")
	act.Size             = UDim2.new(1, -100, 1, 0)
	act.Position         = UDim2.new(0, 30, 0, 0)
	act.BackgroundTransparency = 1
	act.Text             = ctrl.action
	act.TextColor3       = Color3.fromRGB(200, 195, 220)
	act.Font             = Enum.Font.Gotham
	act.TextSize         = 11
	act.TextXAlignment   = Enum.TextXAlignment.Left
	act.Parent           = row

	local badge = Instance.new("TextLabel")
	badge.Size             = UDim2.new(0, 58, 0, 18)
	badge.Position         = UDim2.new(1, -62, 0.5, 0)
	badge.AnchorPoint      = Vector2.new(0, 0.5)
	badge.BackgroundColor3 = Color3.fromRGB(20, 16, 36)
	badge.BackgroundTransparency = 0
	badge.BorderSizePixel  = 0
	badge.Text             = ctrl.key
	badge.TextColor3       = ctrl.color
	badge.Font             = Enum.Font.GothamBold
	badge.TextSize         = 9
	badge.TextXAlignment   = Enum.TextXAlignment.Center
	badge.Parent           = row

	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 4)
	bc.Parent = badge

	local bs = Instance.new("UIStroke")
	bs.Color       = ctrl.color
	bs.Thickness   = 1
	bs.Transparency = 0.5
	bs.Parent = badge
end

-- ════════════════════════════════════════════
--  BOTÓN L (siempre visible en el borde derecho)
-- ════════════════════════════════════════════
local LBtn = Instance.new("Frame")
LBtn.Size             = UDim2.new(0, 32, 0, 32)
LBtn.Position         = UDim2.new(1, -38, 0.5, -16)
LBtn.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
LBtn.BackgroundTransparency = 0.1
LBtn.BorderSizePixel  = 0
LBtn.Parent           = ScreenGui

local lc = Instance.new("UICorner")
lc.CornerRadius = UDim.new(0, 7)
lc.Parent = LBtn

local ls = Instance.new("UIStroke")
ls.Color       = Color3.fromRGB(120, 100, 200)
ls.Thickness   = 1.2
ls.Transparency = 0.3
ls.Parent = LBtn

local lLbl = Instance.new("TextLabel")
lLbl.Size             = UDim2.new(1, 0, 1, 0)
lLbl.BackgroundTransparency = 1
lLbl.Text             = "L"
lLbl.TextColor3       = Color3.fromRGB(180, 160, 255)
lLbl.Font             = Enum.Font.GothamBold
lLbl.TextSize         = 15
lLbl.TextXAlignment   = Enum.TextXAlignment.Center
lLbl.Parent           = LBtn

-- ════════════════════════════════════════════
--  TOGGLE
-- ════════════════════════════════════════════
local isOpen = false

local function openPanel()
	isOpen = true
	Panel.Visible = true
	TweenService:Create(Panel, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.new(1, -280, 0.5, -145) }):Play()
	ls.Color        = Color3.fromRGB(80, 255, 160)
	lLbl.TextColor3 = Color3.fromRGB(80, 255, 160)
end

local function closePanel()
	isOpen = false
	ls.Color        = Color3.fromRGB(120, 100, 200)
	lLbl.TextColor3 = Color3.fromRGB(180, 160, 255)
	TweenService:Create(Panel, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Position = UDim2.new(1, -10, 0.5, -145) }):Play()
	task.wait(0.15)
	Panel.Visible = false
end

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.L then
		if isOpen then closePanel() else openPanel() end
	end
end)

print("[CLIENT] KeyGuide listo — presiona L para controles.")