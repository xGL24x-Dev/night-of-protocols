-- ============================================
-- ReviveClient.client.lua
-- · Outline rojo en compañeros tumbados
-- · UI de revivir con barra de progreso
-- · Tecla E para revivir
-- Ubicación: src/client/ReviveClient.client.lua
-- ============================================

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes       = ReplicatedStorage:WaitForChild("Remotes")
local onDowned      = remotes:WaitForChild("PlayerDowned")
local onRevived     = remotes:WaitForChild("PlayerRevived")
local onProgress    = remotes:WaitForChild("ReviveProgress")
local requestRevive = remotes:WaitForChild("RequestRevive")
local cancelRevive  = remotes:WaitForChild("CancelRevive")

local REVIVE_RANGE = 8

-- ════════════════════════════════════════════════
--  OUTLINES ROJOS (SelectionBox por jugador)
-- ════════════════════════════════════════════════
local outlines = {}   -- { [userId] = SelectionBox }

local function addOutline(downedPlayer)
	if outlines[downedPlayer.UserId] then return end
	if downedPlayer == player then return end  -- no te marques a ti mismo

	local character = downedPlayer.Character
	if not character then return end

	local box = Instance.new("SelectionBox")
	box.Color3         = Color3.fromRGB(220, 20, 20)     -- rojo intenso
	box.LineThickness  = 0.06
	box.SurfaceTransparency = 0.85
	box.SurfaceColor3  = Color3.fromRGB(220, 20, 20)
	box.Adornee        = character
	box.Parent         = workspace

	outlines[downedPlayer.UserId] = box

	-- Pulso — el outline parpadea para llamar la atención
	task.spawn(function()
		while outlines[downedPlayer.UserId] do
			TweenService:Create(box, TweenInfo.new(0.5, Enum.EasingStyle.Sine),
				{ LineThickness = 0.12 }):Play()
			task.wait(0.5)
			if not outlines[downedPlayer.UserId] then break end
			TweenService:Create(box, TweenInfo.new(0.5, Enum.EasingStyle.Sine),
				{ LineThickness = 0.04 }):Play()
			task.wait(0.5)
		end
	end)
end

local function removeOutline(downedPlayer)
	local box = outlines[downedPlayer.UserId]
	if box then
		box:Destroy()
		outlines[downedPlayer.UserId] = nil
	end
end

-- ════════════════════════════════════════════════
--  GUI
-- ════════════════════════════════════════════════
if playerGui:FindFirstChild("ReviveGui") then
	playerGui.ReviveGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "ReviveGui"
ScreenGui.ResetOnSpawn   = false
ScreenGui.DisplayOrder   = 10
ScreenGui.Parent         = playerGui

-- ── Panel "Estás tumbado" ──────────────────────
local DownedPanel = Instance.new("Frame")
DownedPanel.Name             = "DownedPanel"
DownedPanel.Size             = UDim2.new(0, 340, 0, 110)
DownedPanel.Position         = UDim2.new(0.5, 0, 0.3, 0)
DownedPanel.AnchorPoint      = Vector2.new(0.5, 0)
DownedPanel.BackgroundColor3 = Color3.fromRGB(5, 0, 0)
DownedPanel.BackgroundTransparency = 0.05
DownedPanel.BorderSizePixel  = 0
DownedPanel.Visible          = false
DownedPanel.Parent           = ScreenGui

Instance.new("UICorner", DownedPanel).CornerRadius = UDim.new(0, 10)
local DS = Instance.new("UIStroke", DownedPanel)
DS.Color = Color3.fromRGB(200, 20, 20); DS.Thickness = 2

local DownedTitle = Instance.new("TextLabel", DownedPanel)
DownedTitle.Size             = UDim2.new(1, -16, 0, 32)
DownedTitle.Position         = UDim2.new(0, 8, 0, 8)
DownedTitle.BackgroundTransparency = 1
DownedTitle.Text             = "ESTÁS TUMBADO"
DownedTitle.TextColor3       = Color3.fromRGB(220, 30, 30)
DownedTitle.Font             = Enum.Font.GothamBold
DownedTitle.TextSize         = 20
DownedTitle.TextXAlignment   = Enum.TextXAlignment.Center

local DownedSub = Instance.new("TextLabel", DownedPanel)
DownedSub.Size             = UDim2.new(1, -16, 0, 18)
DownedSub.Position         = UDim2.new(0, 8, 0, 42)
DownedSub.BackgroundTransparency = 1
DownedSub.Text             = "Un compañero puede revivirte"
DownedSub.TextColor3       = Color3.fromRGB(180, 130, 130)
DownedSub.Font             = Enum.Font.Gotham
DownedSub.TextSize         = 12
DownedSub.TextXAlignment   = Enum.TextXAlignment.Center

local DownedTimerLabel = Instance.new("TextLabel", DownedPanel)
DownedTimerLabel.Size             = UDim2.new(1, -16, 0, 16)
DownedTimerLabel.Position         = UDim2.new(0, 8, 0, 64)
DownedTimerLabel.BackgroundTransparency = 1
DownedTimerLabel.Text             = "REAPARECE EN:"
DownedTimerLabel.TextColor3       = Color3.fromRGB(160, 100, 100)
DownedTimerLabel.Font             = Enum.Font.GothamBold
DownedTimerLabel.TextSize         = 10
DownedTimerLabel.TextXAlignment   = Enum.TextXAlignment.Center

local DownedTimer = Instance.new("TextLabel", DownedPanel)
DownedTimer.Name             = "DownedTimer"
DownedTimer.Size             = UDim2.new(1, -16, 0, 30)
DownedTimer.Position         = UDim2.new(0, 8, 0, 76)
DownedTimer.BackgroundTransparency = 1
DownedTimer.Text             = "30"
DownedTimer.TextColor3       = Color3.fromRGB(220, 50, 50)
DownedTimer.Font             = Enum.Font.GothamBold
DownedTimer.TextSize         = 24
DownedTimer.TextXAlignment   = Enum.TextXAlignment.Center

-- Viñeta roja en bordes (solo cuando estás tumbado)
local Vignette = Instance.new("Frame", ScreenGui)
Vignette.Name             = "Vignette"
Vignette.Size             = UDim2.new(1, 0, 1, 0)
Vignette.BackgroundTransparency = 1
Vignette.BorderSizePixel  = 0
Vignette.Visible          = false
Vignette.ZIndex           = 1

-- 4 bordes de la viñeta
local vigSides = {
	{ UDim2.new(0,0,0,0),   UDim2.new(1,0,0,60) },   -- top
	{ UDim2.new(0,0,1,-60), UDim2.new(1,0,0,60) },   -- bottom
	{ UDim2.new(0,0,0,0),   UDim2.new(0,60,1,0) },   -- left
	{ UDim2.new(1,-60,0,0), UDim2.new(0,60,1,0) },   -- right
}
for _, v in ipairs(vigSides) do
	local f = Instance.new("Frame", Vignette)
	f.Position         = v[1]
	f.Size             = v[2]
	f.BackgroundColor3 = Color3.fromRGB(160, 0, 0)
	f.BackgroundTransparency = 0.4
	f.BorderSizePixel  = 0
	f.ZIndex           = 1
end

-- ── Panel de progreso de revive ───────────────
local RevivePanel = Instance.new("Frame", ScreenGui)
RevivePanel.Name             = "RevivePanel"
RevivePanel.Size             = UDim2.new(0, 280, 0, 60)
RevivePanel.Position         = UDim2.new(0.5, 0, 0.55, 0)
RevivePanel.AnchorPoint      = Vector2.new(0.5, 0)
RevivePanel.BackgroundColor3 = Color3.fromRGB(5, 10, 5)
RevivePanel.BackgroundTransparency = 0.05
RevivePanel.BorderSizePixel  = 0
RevivePanel.Visible          = false

Instance.new("UICorner", RevivePanel).CornerRadius = UDim.new(0, 8)
local RS2 = Instance.new("UIStroke", RevivePanel)
RS2.Color = Color3.fromRGB(60, 180, 80); RS2.Thickness = 1.5

local ReviveLabel = Instance.new("TextLabel", RevivePanel)
ReviveLabel.Size             = UDim2.new(1, -16, 0, 22)
ReviveLabel.Position         = UDim2.new(0, 8, 0, 6)
ReviveLabel.BackgroundTransparency = 1
ReviveLabel.Text             = "Reviviendo..."
ReviveLabel.TextColor3       = Color3.fromRGB(80, 220, 100)
ReviveLabel.Font             = Enum.Font.GothamBold
ReviveLabel.TextSize         = 13
ReviveLabel.TextXAlignment   = Enum.TextXAlignment.Center

local ReviveBarBg = Instance.new("Frame", RevivePanel)
ReviveBarBg.Size             = UDim2.new(1, -20, 0, 14)
ReviveBarBg.Position         = UDim2.new(0, 10, 0, 36)
ReviveBarBg.BackgroundColor3 = Color3.fromRGB(15, 35, 15)
ReviveBarBg.BorderSizePixel  = 0
Instance.new("UICorner", ReviveBarBg).CornerRadius = UDim.new(0, 4)

local ReviveFill = Instance.new("Frame", ReviveBarBg)
ReviveFill.Size             = UDim2.new(0, 0, 1, 0)
ReviveFill.BackgroundColor3 = Color3.fromRGB(60, 200, 80)
ReviveFill.BorderSizePixel  = 0
Instance.new("UICorner", ReviveFill).CornerRadius = UDim.new(0, 4)

-- ── Prompt flotante sobre el compañero ────────
local RevivePrompt = Instance.new("BillboardGui", workspace)
RevivePrompt.Name        = "RevivePrompt"
RevivePrompt.Size        = UDim2.new(0, 160, 0, 44)
RevivePrompt.StudsOffset = Vector3.new(0, 3.5, 0)
RevivePrompt.AlwaysOnTop = true
RevivePrompt.Enabled     = false

local PromptBg = Instance.new("Frame", RevivePrompt)
PromptBg.Size             = UDim2.new(1, 0, 1, 0)
PromptBg.BackgroundColor3 = Color3.fromRGB(5, 0, 0)
PromptBg.BackgroundTransparency = 0.15
PromptBg.BorderSizePixel  = 0
Instance.new("UICorner", PromptBg).CornerRadius = UDim.new(0, 6)
local PS = Instance.new("UIStroke", PromptBg)
PS.Color = Color3.fromRGB(220, 30, 30); PS.Thickness = 1.5

local PromptKey = Instance.new("TextLabel", PromptBg)
PromptKey.Size             = UDim2.new(0, 28, 0.8, 0)
PromptKey.Position         = UDim2.new(0, 6, 0.1, 0)
PromptKey.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
PromptKey.BackgroundTransparency = 0.2
PromptKey.BorderSizePixel  = 0
PromptKey.Text             = "E"
PromptKey.TextColor3       = Color3.fromRGB(255, 255, 255)
PromptKey.Font             = Enum.Font.GothamBold
PromptKey.TextSize         = 14
PromptKey.TextXAlignment   = Enum.TextXAlignment.Center
Instance.new("UICorner", PromptKey).CornerRadius = UDim.new(0, 4)

local PromptText = Instance.new("TextLabel", PromptBg)
PromptText.Size             = UDim2.new(1, -44, 1, 0)
PromptText.Position         = UDim2.new(0, 38, 0, 0)
PromptText.BackgroundTransparency = 1
PromptText.Text             = "Revivir"
PromptText.TextColor3       = Color3.fromRGB(220, 180, 180)
PromptText.Font             = Enum.Font.GothamBold
PromptText.TextSize         = 13
PromptText.TextXAlignment   = Enum.TextXAlignment.Left

-- ════════════════════════════════════════════════
--  ESTADO LOCAL
-- ════════════════════════════════════════════════
local isDown       = false
local isReviving   = false
local nearbyDowned = nil
local downedSet    = {}

-- ════════════════════════════════════════════════
--  DETECTAR COMPAÑERO MÁS CERCANO
-- ════════════════════════════════════════════════
RunService.Heartbeat:Connect(function()
	if isDown then return end

	local character = player.Character
	if not character then return end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local closest     = nil
	local closestDist = REVIVE_RANGE + 1

	for downedPlayer in pairs(downedSet) do
		local downChar = downedPlayer.Character
		if downChar then
			local downRoot = downChar:FindFirstChild("HumanoidRootPart")
			if downRoot then
				local dist = (rootPart.Position - downRoot.Position).Magnitude
				if dist < closestDist then
					closestDist = dist
					closest     = downedPlayer
				end
			end
		end
	end

	-- Actualizar prompt flotante
	if closest ~= nearbyDowned then
		nearbyDowned = closest
		if closest then
			local downChar = closest.Character
			if downChar and downChar:FindFirstChild("HumanoidRootPart") then
				RevivePrompt.Adornee = downChar.HumanoidRootPart
				RevivePrompt.Enabled = true
				PromptText.Text = "Revivir a\n" .. closest.DisplayName
			end
		else
			RevivePrompt.Enabled = false
			if isReviving then
				isReviving = false
				cancelRevive:FireServer()
				RevivePanel.Visible = false
			end
		end
	end
end)

-- ════════════════════════════════════════════════
--  TECLA E
-- ════════════════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode ~= Enum.KeyCode.E then return end
	if isDown or isReviving or not nearbyDowned then return end

	isReviving = true
	ReviveLabel.Text    = "Reviviendo a " .. nearbyDowned.DisplayName .. "..."
	RevivePanel.Visible = true
	ReviveFill.Size     = UDim2.new(0, 0, 1, 0)
	requestRevive:FireServer(nearbyDowned)
end)

UserInputService.InputEnded:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode ~= Enum.KeyCode.E then return end
	if not isReviving then return end

	isReviving = false
	cancelRevive:FireServer()
	RevivePanel.Visible = false
	ReviveFill.Size     = UDim2.new(0, 0, 1, 0)
end)

-- ════════════════════════════════════════════════
--  EVENTOS DEL SERVIDOR
-- ════════════════════════════════════════════════
onDowned.OnClientEvent:Connect(function(downedPlayer, timeLeft)
	downedSet[downedPlayer] = true

	if downedPlayer == player then
		-- Yo fui tumbado
		isDown = true
		DownedPanel.Visible = true
		Vignette.Visible    = true
		DownedTimer.Text    = tostring(timeLeft or 30)
		RevivePrompt.Enabled = false
	else
		-- Compañero tumbado — mostrar outline rojo
		addOutline(downedPlayer)
		if timeLeft then
			DownedTimer.Text = tostring(timeLeft)
		end
	end
end)

onRevived.OnClientEvent:Connect(function(downedPlayer, reviverPlayer)
	downedSet[downedPlayer] = nil
	removeOutline(downedPlayer)

	if downedPlayer == player then
		isDown = false
		DownedPanel.Visible = false
		Vignette.Visible    = false
		RevivePanel.Visible = false
	end

	if reviverPlayer == player then
		isReviving = false
		RevivePanel.Visible = false
	end

	if downedPlayer == nearbyDowned then
		nearbyDowned        = nil
		RevivePrompt.Enabled = false
	end
end)

onProgress.OnClientEvent:Connect(function(downedPlayer, progress)
	if progress < 0 then
		isReviving = false
		RevivePanel.Visible = false
		ReviveFill.Size     = UDim2.new(0, 0, 1, 0)
		return
	end

	RevivePanel.Visible = true
	TweenService:Create(ReviveFill,
		TweenInfo.new(0.1, Enum.EasingStyle.Linear),
		{ Size = UDim2.new(math.clamp(progress, 0, 1), 0, 1, 0) }):Play()
end)

-- Limpiar outlines si alguien sale del juego
Players.PlayerRemoving:Connect(function(p)
	if outlines[p.UserId] then
		outlines[p.UserId]:Destroy()
		outlines[p.UserId] = nil
	end
	downedSet[p] = nil
end)

print("[CLIENT] ReviveClient cargado — E para revivir compañeros.")