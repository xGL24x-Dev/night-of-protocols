-- ============================================
-- WeaponSystem.server.lua
-- Sistema básico de pistola para aprender:
--   · Recoger pistola desde el suelo (ya lo hace InventoryManager)
--   · Disparar con click izquierdo si está en el hotbar
--   · Daño validado en servidor con raycast
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local remotes = ReplicatedStorage:WaitForChild("Remotes")

local requestShoot = remotes:FindFirstChild("RequestShoot")
if not requestShoot then
	requestShoot = Instance.new("RemoteEvent")
	requestShoot.Name = "RequestShoot"
	requestShoot.Parent = remotes
end

local SHOOT_COOLDOWN = 0.2
local SHOOT_RANGE = 220
local SHOOT_DAMAGE = 25
local MAX_AIM_ANGLE_DOT = 0.25

local lastShotAt = {}

local function createTracer(startPos, endPos)
	local dist = (endPos - startPos).Magnitude
	if dist <= 0.05 then return end

	local tracer = Instance.new("Part")
	tracer.Anchored = true
	tracer.CanCollide = false
	tracer.CanQuery = false
	tracer.CanTouch = false
	tracer.Material = Enum.Material.Neon
	tracer.Color = Color3.fromRGB(255, 235, 120)
	tracer.Size = Vector3.new(0.08, 0.08, dist)
	tracer.CFrame = CFrame.lookAt(startPos, endPos) * CFrame.new(0, 0, -dist * 0.5)
	tracer.Parent = workspace

	Debris:AddItem(tracer, 0.06)
end

requestShoot.OnServerEvent:Connect(function(player, origin, direction)
	if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" then
		return
	end

	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root then
		return
	end

	local now = tick()
	local prev = lastShotAt[player.UserId] or 0
	if now - prev < SHOOT_COOLDOWN then
		return
	end
	lastShotAt[player.UserId] = now

	local unitDir = direction.Magnitude > 0 and direction.Unit or nil
	if not unitDir then return end

	-- Validación simple anti-cheat:
	-- no dejar disparar totalmente en dirección opuesta al personaje.
	if root.CFrame.LookVector:Dot(unitDir) < -MAX_AIM_ANGLE_DOT then
		return
	end

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { character }

	local rayResult = workspace:Raycast(origin, unitDir * SHOOT_RANGE, rayParams)
	local hitPos = rayResult and rayResult.Position or (origin + unitDir * SHOOT_RANGE)
	createTracer(origin, hitPos)

	if not rayResult then
		return
	end

	local model = rayResult.Instance:FindFirstAncestorOfClass("Model")
	if not model then return end

	local hitHumanoid = model:FindFirstChildOfClass("Humanoid")
	if not hitHumanoid or hitHumanoid.Health <= 0 then
		return
	end

	if model == character then
		return
	end

	hitHumanoid:TakeDamage(SHOOT_DAMAGE)
end)

Players.PlayerRemoving:Connect(function(player)
	lastShotAt[player.UserId] = nil
end)

print("[SERVER] WeaponSystem cargado (pistola básica).")
