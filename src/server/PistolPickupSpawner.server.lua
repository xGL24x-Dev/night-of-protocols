-- ============================================
-- PistolPickupSpawner.server.lua
-- Crea un pickup simple de pistola en el mapa.
-- ============================================

local Workspace = game:GetService("Workspace")

local itemsFolder = Workspace:FindFirstChild("PickupItems")
if not itemsFolder then
	itemsFolder = Instance.new("Folder")
	itemsFolder.Name = "PickupItems"
	itemsFolder.Parent = Workspace
end

if itemsFolder:FindFirstChild("PistolPickup") then
	return
end

local spawnPosition = Vector3.new(0, 4, 0)
local spawnLocation = Workspace:FindFirstChildOfClass("SpawnLocation")
if spawnLocation then
	spawnPosition = spawnLocation.Position + Vector3.new(4, 2, 0)
end

local pickup = Instance.new("Part")
pickup.Name = "PistolPickup"
pickup.Size = Vector3.new(1.6, 0.6, 2.2)
pickup.Material = Enum.Material.Metal
pickup.Color = Color3.fromRGB(55, 55, 60)
pickup.Anchored = true
pickup.CanCollide = false
pickup.Position = spawnPosition
pickup.Parent = itemsFolder

pickup:SetAttribute("ItemType", "Pistol")
pickup:SetAttribute("ItemName", "Pistola básica")
pickup:SetAttribute("ItemID", "pistol_basic_01")

print("[SERVER] Pickup de pistola creado en:", pickup.Position)
