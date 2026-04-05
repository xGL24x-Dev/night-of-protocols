-- ============================================
-- InventoryManager.server.lua
-- Script de SERVIDOR
-- Valida y procesa la recogida de items
-- Ubicación: src/server/InventoryManager.server.lua
-- ============================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Esperar RemoteEvents (creados por PlayerManager)
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local pickupItem     = Instance.new("RemoteEvent")
pickupItem.Name      = "PickupItem"
pickupItem.Parent    = remotes

local onItemPickedUp = Instance.new("RemoteEvent")
onItemPickedUp.Name  = "ItemPickedUp"
onItemPickedUp.Parent = remotes

-- Carpeta donde viven los items recogibles en el mundo
local itemsFolder = workspace:FindFirstChild("PickupItems")
if not itemsFolder then
	itemsFolder      = Instance.new("Folder")
	itemsFolder.Name = "PickupItems"
	itemsFolder.Parent = workspace
end

-- ── Validar y procesar recogida ───────────────
local PICKUP_RANGE = 10  -- studs (un poco más que el cliente para tolerancia)

pickupItem.OnServerEvent:Connect(function(player, itemPart)
	-- Validaciones de seguridad
	if not itemPart or not itemPart.Parent then return end
	if itemPart.Parent ~= itemsFolder then return end

	local character = player.Character
	if not character then return end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	-- Verificar distancia en el servidor (anti-cheat básico)
	local dist = (itemPart.Position - root.Position).Magnitude
	if dist > PICKUP_RANGE then
		print("[SERVER] "..player.Name.." intentó recoger item desde muy lejos: "..dist.." studs")
		return
	end

	-- Leer datos del item
	local itemData = {
		itemType = itemPart:GetAttribute("ItemType") or "Generic",
		name     = itemPart:GetAttribute("ItemName") or "Item desconocido",
		id       = itemPart:GetAttribute("ItemID")   or tostring(math.random(100000, 999999)),
	}

	-- Eliminar el item del mundo
	itemPart:Destroy()

	-- Notificar al cliente que lo recogió
	onItemPickedUp:FireClient(player, itemData)

	print("[SERVER] "..player.Name.." recogió: "..itemData.name)
end)

print("[SERVER] InventoryManager cargado.")