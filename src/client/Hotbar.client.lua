-- ============================================
-- Hotbar.client.lua
-- Script de CLIENTE — Hotbar + Sistema de Mochila
--
-- MECÁNICA:
--   · Hotbar de 6 slots abajo centro
--   · Items del mundo se recogen con E → van al hotbar
--   · La mochila ocupa 1 slot y tiene niveles (1→2→3)
--   · Con mochila equipada, G abre el inventario expandido
--   · Nivel 1 = 4 slots | Nivel 2 = 6 | Nivel 3 = 8
--   · Mejora la mochila combinando materiales
--
-- Ubicación: src/client/Hotbar.client.lua
-- ============================================

local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Limpiar GUIs anteriores
for _, n in ipairs({"HotbarGui", "InventoryGui"}) do
	if playerGui:FindFirstChild(n) then playerGui[n]:Destroy() end
end

-- ════════════════════════════════════════════════
--  DATOS DEL SISTEMA
-- ════════════════════════════════════════════════
local HOTBAR_SLOTS  = 6
local selectedSlot  = 1
local hotbarItems   = {}   -- [slot] = itemData o nil

-- Mochila
local backpackLevel    = 0   -- 0 = sin mochila, 1/2/3 = niveles
local inventoryItems   = {}  -- items dentro de la mochila
local inventoryOpen    = false
local nearbyItem   = nil
local PICKUP_RANGE = 8


local BACKPACK_SLOTS = { [0]=0, [1]=4, [2]=6, [3]=8 }
local BACKPACK_UPGRADES = {
	[1] = { name="Mochila Básica",     slots=4, icon="🎒", upgradeItems={"Tela", "Cuerda"} },
	[2] = { name="Mochila Reforzada",  slots=6, icon="🎒", upgradeItems={"Cuero", "Hebilla"} },
	[3] = { name="Mochila Táctica",    slots=8, icon="🎒", upgradeItems={"Metal", "Cerradura"} },
}

-- Definición de todos los items
local ITEM_DATA = {
	Backpack   = { icon="🎒", name="Mochila",          color=Color3.fromRGB(80,  140, 255), isBackpack=true  },
	Flashlight = { icon="🔦", name="Linterna",          color=Color3.fromRGB(255, 210, 80)                   },
	Battery    = { icon="🔋", name="Batería",            color=Color3.fromRGB(80,  200, 80)                   },
	Key        = { icon="🔑", name="Llave",              color=Color3.fromRGB(255, 200, 40)                   },
	MedKit     = { icon="❤️", name="Kit médico",        color=Color3.fromRGB(220, 60,  60)                   },
	Document   = { icon="📄", name="Archivo Sigma",     color=Color3.fromRGB(200, 180, 140)                  },
	KeyCard    = { icon="💳", name="Tarjeta acceso",    color=Color3.fromRGB(80,  160, 255)                  },
	Wrench     = { icon="🔧", name="Llave inglesa",     color=Color3.fromRGB(160, 160, 180)                  },
	Weapon     = { icon="🔨", name="Martillo",          color=Color3.fromRGB(200, 100, 60)                   },
	Fabric     = { icon="🧵", name="Tela",              color=Color3.fromRGB(200, 160, 220)                  },
	Rope       = { icon="〰️", name="Cuerda",            color=Color3.fromRGB(180, 150, 100)                  },
	Leather    = { icon="🟫", name="Cuero",             color=Color3.fromRGB(140, 90,  50)                   },
}

-- RemoteEvents
local remotes        = ReplicatedStorage:WaitForChild("Remotes")
local pickupItem     = remotes:WaitForChild("PickupItem")
local onItemPickedUp = remotes:WaitForChild("ItemPickedUp")

-- ════════════════════════════════════════════════
--  SCREEN GUI
-- ════════════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "HotbarGui"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent         = playerGui

-- ════════════════════════════════════════════════
--  HOTBAR (abajo centro)
-- ════════════════════════════════════════════════
local HotbarFrame = Instance.new("Frame")
HotbarFrame.Name             = "Hotbar"
HotbarFrame.Size             = UDim2.new(0, HOTBAR_SLOTS * 66 + 16, 0, 74)
HotbarFrame.Position         = UDim2.new(0.5, 0, 1, -12)
HotbarFrame.AnchorPoint      = Vector2.new(0.5, 1)
HotbarFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 14)
HotbarFrame.BackgroundTransparency = 0.1
HotbarFrame.BorderSizePixel  = 0
HotbarFrame.Parent           = ScreenGui

local HBCorner = Instance.new("UICorner")
HBCorner.CornerRadius = UDim.new(0, 12)
HBCorner.Parent = HotbarFrame

local HBStroke = Instance.new("UIStroke")
HBStroke.Color       = Color3.fromRGB(70, 60, 120)
HBStroke.Thickness   = 1.2
HBStroke.Transparency = 0.4
HBStroke.Parent = HotbarFrame

local HBLayout = Instance.new("UIListLayout")
HBLayout.FillDirection       = Enum.FillDirection.Horizontal
HBLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
HBLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
HBLayout.Padding             = UDim.new(0, 6)
HBLayout.Parent              = HotbarFrame

local HBPadding = Instance.new("UIPadding")
HBPadding.PaddingLeft  = UDim.new(0, 8)
HBPadding.PaddingRight = UDim.new(0, 8)
HBPadding.Parent = HotbarFrame

-- Crear slots
local slotFrames = {}

for i = 1, HOTBAR_SLOTS do
	local slot = Instance.new("Frame")
	slot.Name             = "Slot_"..i
	slot.Size             = UDim2.new(0, 60, 0, 60)
	slot.BackgroundColor3 = Color3.fromRGB(16, 14, 28)
	slot.BackgroundTransparency = 0.2
	slot.BorderSizePixel  = 0
	slot.Parent           = HotbarFrame

	local sc = Instance.new("UICorner")
	sc.CornerRadius = UDim.new(0, 8)
	sc.Parent = slot

	local ss = Instance.new("UIStroke")
	ss.Color       = Color3.fromRGB(55, 48, 95)
	ss.Thickness   = 1
	ss.Transparency = 0.5
	ss.Parent = slot

	-- Número del slot (tecla)
	local numLbl = Instance.new("TextLabel")
	numLbl.Size             = UDim2.new(0, 14, 0, 14)
	numLbl.Position         = UDim2.new(0, 3, 0, 2)
	numLbl.BackgroundTransparency = 1
	numLbl.Text             = tostring(i)
	numLbl.TextColor3       = Color3.fromRGB(80, 70, 120)
	numLbl.Font             = Enum.Font.GothamBold
	numLbl.TextSize         = 9
	numLbl.Parent           = slot

	-- Ícono del item
	local icon = Instance.new("TextLabel")
	icon.Name              = "Icon"
	icon.Size              = UDim2.new(1, 0, 0, 34)
	icon.Position          = UDim2.new(0, 0, 0, 10)
	icon.BackgroundTransparency = 1
	icon.Text              = ""
	icon.Font              = Enum.Font.GothamBold
	icon.TextSize          = 22
	icon.TextXAlignment    = Enum.TextXAlignment.Center
	icon.Parent            = slot

	-- Nombre corto
	local nameLbl = Instance.new("TextLabel")
	nameLbl.Name              = "ItemName"
	nameLbl.Size              = UDim2.new(1, -2, 0, 14)
	nameLbl.Position          = UDim2.new(0, 1, 1, -16)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text              = ""
	nameLbl.TextColor3        = Color3.fromRGB(180, 170, 210)
	nameLbl.Font              = Enum.Font.Gotham
	nameLbl.TextSize          = 8
	nameLbl.TextXAlignment    = Enum.TextXAlignment.Center
	nameLbl.TextWrapped       = true
	nameLbl.Parent            = slot

	slotFrames[i] = { frame=slot, stroke=ss, icon=icon, name=nameLbl, num=numLbl }
end

-- ════════════════════════════════════════════════
--  PANEL DE INVENTARIO (mochila abierta)
-- ════════════════════════════════════════════════
local InvPanel = Instance.new("Frame")
InvPanel.Name             = "InventoryPanel"
InvPanel.Size             = UDim2.new(0, 360, 0, 280)
InvPanel.Position         = UDim2.new(0.5, 0, 1, -100)
InvPanel.AnchorPoint      = Vector2.new(0.5, 1)
InvPanel.BackgroundColor3 = Color3.fromRGB(8, 8, 14)
InvPanel.BackgroundTransparency = 0.08
InvPanel.BorderSizePixel  = 0
InvPanel.Visible          = false
InvPanel.Parent           = ScreenGui

local InvCorner = Instance.new("UICorner")
InvCorner.CornerRadius = UDim.new(0, 14)
InvCorner.Parent = InvPanel

local InvStroke = Instance.new("UIStroke")
InvStroke.Color       = Color3.fromRGB(80, 140, 255)
InvStroke.Thickness   = 1.5
InvStroke.Transparency = 0.3
InvStroke.Parent = InvPanel

-- Header
local InvHeader = Instance.new("Frame")
InvHeader.Size             = UDim2.new(1, 0, 0, 46)
InvHeader.BackgroundColor3 = Color3.fromRGB(12, 10, 26)
InvHeader.BackgroundTransparency = 0
InvHeader.BorderSizePixel  = 0
InvHeader.Parent           = InvPanel

local IHCorner = Instance.new("UICorner")
IHCorner.CornerRadius = UDim.new(0, 14)
IHCorner.Parent = InvHeader

local IHPatch = Instance.new("Frame")
IHPatch.Size             = UDim2.new(1, 0, 0, 14)
IHPatch.Position         = UDim2.new(0, 0, 1, -14)
IHPatch.BackgroundColor3 = Color3.fromRGB(12, 10, 26)
IHPatch.BackgroundTransparency = 0
IHPatch.BorderSizePixel  = 0
IHPatch.Parent           = InvHeader

local InvTitle = Instance.new("TextLabel")
InvTitle.Size             = UDim2.new(1, -16, 1, 0)
InvTitle.Position         = UDim2.new(0, 14, 0, 0)
InvTitle.BackgroundTransparency = 1
InvTitle.Text             = "🎒  Mochila Básica  —  0 / 4"
InvTitle.TextColor3       = Color3.fromRGB(130, 180, 255)
InvTitle.Font             = Enum.Font.GothamBold
InvTitle.TextSize         = 13
InvTitle.TextXAlignment   = Enum.TextXAlignment.Left
InvTitle.Parent           = InvHeader

-- Botón mejorar
local UpgradeBtn = Instance.new("TextButton")
UpgradeBtn.Name             = "UpgradeBtn"
UpgradeBtn.Size             = UDim2.new(0, 90, 0, 26)
UpgradeBtn.Position         = UDim2.new(1, -98, 0.5, 0)
UpgradeBtn.AnchorPoint      = Vector2.new(0, 0.5)
UpgradeBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 180)
UpgradeBtn.BackgroundTransparency = 0.3
UpgradeBtn.Text             = "⬆ Mejorar"
UpgradeBtn.TextColor3       = Color3.fromRGB(150, 200, 255)
UpgradeBtn.Font             = Enum.Font.GothamBold
UpgradeBtn.TextSize         = 11
UpgradeBtn.BorderSizePixel  = 0
UpgradeBtn.Visible          = false
UpgradeBtn.Parent           = InvHeader

local UBCorner = Instance.new("UICorner")
UBCorner.CornerRadius = UDim.new(0, 6)
UBCorner.Parent = UpgradeBtn

-- Grid de inventario
local InvGrid = Instance.new("Frame")
InvGrid.Size             = UDim2.new(1, -20, 1, -58)
InvGrid.Position         = UDim2.new(0, 10, 0, 52)
InvGrid.BackgroundTransparency = 1
InvGrid.Parent           = InvPanel

local InvGridLayout = Instance.new("UIGridLayout")
InvGridLayout.CellSize    = UDim2.new(0, 76, 0, 76)
InvGridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
InvGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
InvGridLayout.VerticalAlignment   = Enum.VerticalAlignment.Top
InvGridLayout.Parent = InvGrid

local invSlotFrames = {}

-- Crear slots del inventario (máximo 8)
for i = 1, 8 do
	local s = Instance.new("Frame")
	s.Name             = "InvSlot_"..i
	s.BackgroundColor3 = Color3.fromRGB(16, 13, 28)
	s.BackgroundTransparency = 0.3
	s.BorderSizePixel  = 0
	s.Visible          = false
	s.Parent           = InvGrid

	local sc = Instance.new("UICorner")
	sc.CornerRadius = UDim.new(0, 8)
	sc.Parent = s

	local ss = Instance.new("UIStroke")
	ss.Color       = Color3.fromRGB(50, 90, 160)
	ss.Thickness   = 1
	ss.Transparency = 0.5
	ss.Parent = s

	local ico = Instance.new("TextLabel")
	ico.Name              = "Icon"
	ico.Size              = UDim2.new(1, 0, 0, 40)
	ico.Position          = UDim2.new(0, 0, 0, 6)
	ico.BackgroundTransparency = 1
	ico.Text              = ""
	ico.Font              = Enum.Font.GothamBold
	ico.TextSize          = 24
	ico.TextXAlignment    = Enum.TextXAlignment.Center
	ico.Parent            = s

	local nl = Instance.new("TextLabel")
	nl.Name              = "ItemName"
	nl.Size              = UDim2.new(1, -4, 0, 18)
	nl.Position          = UDim2.new(0, 2, 1, -20)
	nl.BackgroundTransparency = 1
	nl.Text              = ""
	nl.TextColor3        = Color3.fromRGB(160, 180, 220)
	nl.Font              = Enum.Font.Gotham
	nl.TextSize          = 9
	nl.TextXAlignment    = Enum.TextXAlignment.Center
	nl.TextWrapped       = true
	nl.Parent            = s

	invSlotFrames[i] = { frame=s, stroke=ss, icon=ico, name=nl }
end

-- ── Tooltip de mejora ─────────────────────────
local UpgradeTooltip = Instance.new("Frame")
UpgradeTooltip.Name             = "UpgradeTooltip"
UpgradeTooltip.Size             = UDim2.new(0, 220, 0, 70)
UpgradeTooltip.Position         = UDim2.new(0.5, 0, 1, -105)
UpgradeTooltip.AnchorPoint      = Vector2.new(0.5, 1)
UpgradeTooltip.BackgroundColor3 = Color3.fromRGB(10, 12, 26)
UpgradeTooltip.BackgroundTransparency = 0.05
UpgradeTooltip.BorderSizePixel  = 0
UpgradeTooltip.Visible          = false
UpgradeTooltip.Parent           = ScreenGui

local UTCorner = Instance.new("UICorner")
UTCorner.CornerRadius = UDim.new(0, 10)
UTCorner.Parent = UpgradeTooltip

local UTStroke = Instance.new("UIStroke")
UTStroke.Color       = Color3.fromRGB(80, 140, 255)
UTStroke.Thickness   = 1
UTStroke.Transparency = 0.4
UTStroke.Parent = UpgradeTooltip

local UTText = Instance.new("TextLabel")
UTText.Size             = UDim2.new(1, -12, 1, 0)
UTText.Position         = UDim2.new(0, 6, 0, 0)
UTText.BackgroundTransparency = 1
UTText.Text             = ""
UTText.TextColor3       = Color3.fromRGB(160, 200, 255)
UTText.Font             = Enum.Font.Gotham
UTText.TextSize         = 11
UTText.TextXAlignment   = Enum.TextXAlignment.Left
UTText.TextYAlignment   = Enum.TextYAlignment.Center
UTText.TextWrapped      = true
UTText.Parent           = UpgradeTooltip

-- ── Pickup prompt ─────────────────────────────
local PickupPrompt = Instance.new("Frame")
PickupPrompt.Name             = "PickupPrompt"
PickupPrompt.Size             = UDim2.new(0, 210, 0, 34)
PickupPrompt.Position         = UDim2.new(0.5, 0, 1, -102)
PickupPrompt.AnchorPoint      = Vector2.new(0.5, 1)
PickupPrompt.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
PickupPrompt.BackgroundTransparency = 0.1
PickupPrompt.BorderSizePixel  = 0
PickupPrompt.Visible          = false
PickupPrompt.Parent           = ScreenGui

local PPCorner = Instance.new("UICorner")
PPCorner.CornerRadius = UDim.new(0, 8)
PPCorner.Parent = PickupPrompt

local PPStroke = Instance.new("UIStroke")
PPStroke.Color       = Color3.fromRGB(80, 255, 160)
PPStroke.Thickness   = 1
PPStroke.Transparency = 0.3
PPStroke.Parent = PickupPrompt

local PickupText = Instance.new("TextLabel")
PickupText.Size             = UDim2.new(1, 0, 1, 0)
PickupText.BackgroundTransparency = 1
PickupText.Text             = "[E]  Recoger"
PickupText.TextColor3       = Color3.fromRGB(80, 255, 160)
PickupText.Font             = Enum.Font.GothamBold
PickupText.TextSize         = 13
PickupText.TextXAlignment   = Enum.TextXAlignment.Center
PickupText.Parent           = PickupPrompt

-- ════════════════════════════════════════════════
--  FUNCIONES DE UI
-- ════════════════════════════════════════════════
local function refreshHotbar()
	for i = 1, HOTBAR_SLOTS do
		local sf   = slotFrames[i]
		local item = hotbarItems[i]
		local data = item and (ITEM_DATA[item.itemType] or {})

		sf.icon.Text  = data and data.icon or ""
		sf.name.Text  = data and data.name or ""

		-- Slot seleccionado
		if i == selectedSlot then
			sf.stroke.Color       = Color3.fromRGB(255, 255, 255)
			sf.stroke.Transparency = 0.1
			sf.stroke.Thickness   = 2
			sf.frame.BackgroundColor3 = Color3.fromRGB(22, 20, 40)
		elseif item then
			sf.stroke.Color       = data.color or Color3.fromRGB(80, 70, 130)
			sf.stroke.Transparency = 0.3
			sf.stroke.Thickness   = 1
			sf.frame.BackgroundColor3 = Color3.fromRGB(18, 16, 32)
		else
			sf.stroke.Color       = Color3.fromRGB(55, 48, 95)
			sf.stroke.Transparency = 0.5
			sf.stroke.Thickness   = 1
			sf.frame.BackgroundColor3 = Color3.fromRGB(16, 14, 28)
		end
	end
end

local function refreshInventory()
	local slots    = BACKPACK_SLOTS[backpackLevel]
	local nextData = BACKPACK_UPGRADES[backpackLevel + 1]
	local bpData   = BACKPACK_UPGRADES[backpackLevel]
	local bpName   = bpData and bpData.name or "Mochila"

	InvTitle.Text = "🎒  "..bpName.."  —  "..#inventoryItems.." / "..slots

	-- Mostrar/ocultar botón mejorar
	UpgradeBtn.Visible = (backpackLevel < 3)

	-- Tooltip de mejora
	if nextData then
		UTText.Text = "⬆ Mejorar a nivel "..(backpackLevel+1).."\n"..
			"Necesitas: "..table.concat(nextData.upgradeItems, " + ").."\n"..
			"Slots: "..slots.." → "..nextData.slots
	end

	-- Actualizar slots del inventario
	for i = 1, 8 do
		local sf   = invSlotFrames[i]
		local item = inventoryItems[i]
		sf.frame.Visible = (i <= slots)

		if item then
			local d = ITEM_DATA[item.itemType] or {}
			sf.icon.Text  = d.icon or "❓"
			sf.name.Text  = item.name or ""
			sf.stroke.Color       = d.color or Color3.fromRGB(80, 140, 255)
			sf.stroke.Transparency = 0.2
			sf.frame.BackgroundColor3 = Color3.fromRGB(18, 16, 32)
		else
			sf.icon.Text  = ""
			sf.name.Text  = ""
			sf.stroke.Color       = Color3.fromRGB(50, 90, 160)
			sf.stroke.Transparency = 0.5
			sf.frame.BackgroundColor3 = Color3.fromRGB(16, 13, 28)
		end
	end
end

local function openInventory()
	if backpackLevel == 0 then
		PickupText.Text  = "¡Necesitas una mochila!"
		PickupPrompt.Visible = true
		task.wait(2)
		PickupPrompt.Visible = false
		return
	end
	inventoryOpen = true
	refreshInventory()
	InvPanel.Size    = UDim2.new(0, 340, 0, 260)
	InvPanel.Visible = true
	TweenService:Create(InvPanel,
		TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Size = UDim2.new(0, 360, 0, 280) }):Play()
end

local function closeInventory()
	inventoryOpen    = false
	UpgradeTooltip.Visible = false
	TweenService:Create(InvPanel,
		TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Size = UDim2.new(0, 340, 0, 260) }):Play()
	task.wait(0.15)
	InvPanel.Visible = false
end

-- ════════════════════════════════════════════════
--  LÓGICA DE MEJORA
-- ════════════════════════════════════════════════
local function tryUpgrade()
	if backpackLevel >= 3 then return end
	local nextData = BACKPACK_UPGRADES[backpackLevel + 1]
	if not nextData then return end

	-- Verificar si tiene los materiales en el inventario
	local needed = {}
	for _, mat in ipairs(nextData.upgradeItems) do
		needed[mat] = true
	end

	local found = {}
	local foundIdx = {}
	for i, item in ipairs(inventoryItems) do
		if needed[item.name] and not found[item.name] then
			found[item.name]    = true
			foundIdx[item.name] = i
		end
	end

	local canUpgrade = true
	for mat, _ in pairs(needed) do
		if not found[mat] then canUpgrade = false break end
	end

	if canUpgrade then
		-- Consumir materiales
		local toRemove = {}
		for _, idx in pairs(foundIdx) do
			table.insert(toRemove, idx)
		end
		table.sort(toRemove, function(a,b) return a > b end)
		for _, idx in ipairs(toRemove) do
			table.remove(inventoryItems, idx)
		end

		-- Subir nivel
		backpackLevel = backpackLevel + 1

		-- Actualizar item de mochila en hotbar
		for i = 1, HOTBAR_SLOTS do
			if hotbarItems[i] and hotbarItems[i].itemType == "Backpack" then
				hotbarItems[i].name  = BACKPACK_UPGRADES[backpackLevel].name
				hotbarItems[i].level = backpackLevel
				break
			end
		end

		refreshHotbar()
		refreshInventory()
		UpgradeTooltip.Visible = false

		-- Feedback visual
		InvStroke.Color = Color3.fromRGB(80, 255, 160)
		task.wait(0.8)
		InvStroke.Color = Color3.fromRGB(80, 140, 255)
	else
		-- Mostrar qué falta
		local missing = {}
		for mat, _ in pairs(needed) do
			if not found[mat] then table.insert(missing, mat) end
		end
		UTText.Text = "❌ Faltan materiales:\n"..table.concat(missing, ", ")
		UpgradeTooltip.Visible = true
		task.wait(2.5)
		if inventoryOpen then
			refreshInventory()
			UpgradeTooltip.Visible = false
		end
	end
end

UpgradeBtn.MouseButton1Click:Connect(function()
	UpgradeTooltip.Visible = not UpgradeTooltip.Visible
	if UpgradeTooltip.Visible then
		refreshInventory()
		task.wait(0.1)
		tryUpgrade()
	end
end)

-- ════════════════════════════════════════════════
--  SELECCIÓN DE SLOT (teclas 1–6)
-- ════════════════════════════════════════════════
local slotKeys = {
	[Enum.KeyCode.One]   = 1,
	[Enum.KeyCode.Two]   = 2,
	[Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four]  = 4,
	[Enum.KeyCode.Five]  = 5,
	[Enum.KeyCode.Six]   = 6,
}

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end

	-- Seleccionar slot con teclas 1–6
	local slot = slotKeys[input.KeyCode]
	if slot then
		selectedSlot = slot
		refreshHotbar()
		return
	end

	-- G → abrir/cerrar inventario
	if input.KeyCode == Enum.KeyCode.G then
		if inventoryOpen then closeInventory() else openInventory() end
		return
	end

	-- F → linterna (solo si la tiene en el slot seleccionado)
	-- (la linterna ya la maneja HUD.client.lua)

	-- E → recoger item cercano
	if input.KeyCode == Enum.KeyCode.E and nearbyItem then
		-- ¿Hay slot libre en el hotbar?
		local freeSlot = nil
		for i = 1, HOTBAR_SLOTS do
			if not hotbarItems[i] then freeSlot = i break end
		end
		if freeSlot then
			pickupItem:FireServer(nearbyItem)
		else
			PickupText.Text  = "¡Hotbar lleno! Usa la mochila"
			PickupPrompt.Visible = true
			task.wait(2)
			if not nearbyItem then PickupPrompt.Visible = false end
		end
	end

	-- Scroll del mouse → cambiar slot
	if input.UserInputType == Enum.UserInputType.MouseWheel then
		selectedSlot = selectedSlot + (input.Position.Z > 0 and -1 or 1)
		if selectedSlot < 1 then selectedSlot = HOTBAR_SLOTS end
		if selectedSlot > HOTBAR_SLOTS then selectedSlot = 1 end
		refreshHotbar()
	end
end)

-- ════════════════════════════════════════════════
--  DETECCIÓN DE ITEMS CERCANOS
-- ════════════════════════════════════════════════

RunService.Heartbeat:Connect(function()
	local character = player.Character
	if not character then return end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local itemsFolder = workspace:FindFirstChild("PickupItems")
	if not itemsFolder then
		PickupPrompt.Visible = false
		nearbyItem = nil
		return
	end

	local closest, closestDist = nil, PICKUP_RANGE
	for _, item in ipairs(itemsFolder:GetChildren()) do
		if item:IsA("BasePart") then
			local dist = (item.Position - root.Position).Magnitude
			if dist < closestDist then
				closestDist = dist
				closest     = item
			end
		end
	end

	nearbyItem = closest
	if closest and not inventoryOpen then
		PickupText.Text      = "[E]  Recoger " .. (closest:GetAttribute("ItemName") or "Item")
		PickupPrompt.Visible = true
	else
		PickupPrompt.Visible = false
	end
end)

-- ════════════════════════════════════════════════
--  RECIBIR ITEM DEL SERVIDOR
-- ════════════════════════════════════════════════
onItemPickedUp.OnClientEvent:Connect(function(itemData)
	-- ¿Es una mochila?
	if itemData.itemType == "Backpack" and backpackLevel == 0 then
		backpackLevel = 1
		-- Poner en primer slot libre
		for i = 1, HOTBAR_SLOTS do
			if not hotbarItems[i] then
				hotbarItems[i] = itemData
				break
			end
		end
		refreshHotbar()
		PickupText.Text  = "✓ ¡Mochila equipada! Presiona G para abrirla"
		PickupPrompt.Visible = true
		task.wait(3)
		PickupPrompt.Visible = (nearbyItem ~= nil)
		return
	end

	-- Item normal → ¿va al hotbar o al inventario?
	local addedToHotbar = false
	for i = 1, HOTBAR_SLOTS do
		if not hotbarItems[i] then
			hotbarItems[i]  = itemData
			addedToHotbar   = true
			break
		end
	end

	if not addedToHotbar and backpackLevel > 0 then
		-- Va al inventario de la mochila
		local maxSlots = BACKPACK_SLOTS[backpackLevel]
		if #inventoryItems < maxSlots then
			table.insert(inventoryItems, itemData)
			PickupText.Text = "✓ "..itemData.name.." → Mochila"
		else
			PickupText.Text = "¡Sin espacio!"
		end
	elseif not addedToHotbar then
		PickupText.Text = "¡Hotbar lleno! Necesitas una mochila"
	else
		PickupText.Text = "✓ "..itemData.name.." recogido"
	end

	refreshHotbar()
	if inventoryOpen then refreshInventory() end

	PickupPrompt.Visible = true
	task.wait(2)
	if not nearbyItem then PickupPrompt.Visible = false end
end)

-- Init
refreshHotbar()
print("[CLIENT] Hotbar + Mochila cargados.")