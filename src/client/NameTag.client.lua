-- ============================================
-- NameTag.client.lua
-- Script de CLIENTE — Nombre verde sobre la cabeza
--
-- Muestra el nombre de cada jugador en verde
-- con un BillboardGui sobre su Head.
-- Se actualiza automáticamente cuando alguien
-- entra o respawnea.
--
-- Ubicación: src/client/NameTag.client.lua
-- ============================================

local Players   = game:GetService("Players")
local RunService = game:GetService("RunService")

local function applyNameTag(targetPlayer, character)
    local head = character:WaitForChild("Head", 5)
    if not head then return end

    -- Eliminar tag anterior si existe
    local old = head:FindFirstChild("NameTag")
    if old then old:Destroy() end

    -- Ocultar el nombre de Roblox por defecto
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    end

    -- BillboardGui
    local billboard = Instance.new("BillboardGui")
    billboard.Name            = "NameTag"
    billboard.Size            = UDim2.new(0, 120, 0, 30)
    billboard.StudsOffset     = Vector3.new(0, 2.4, 0)
    billboard.AlwaysOnTop     = false
    billboard.MaxDistance     = 60
    billboard.ResetOnSpawn    = false
    billboard.Parent          = head

    -- Fondo semitransparente
    local bg = Instance.new("Frame")
    bg.Size             = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(5, 12, 8)
    bg.BackgroundTransparency = 0.4
    bg.BorderSizePixel  = 0
    bg.Parent           = billboard

    local bgc = Instance.new("UICorner")
    bgc.CornerRadius = UDim.new(0, 6)
    bgc.Parent = bg

    local bgs = Instance.new("UIStroke")
    bgs.Color       = Color3.fromRGB(60, 200, 100)
    bgs.Thickness   = 1
    bgs.Transparency = 0.4
    bgs.Parent = bg

    -- Texto del nombre
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size             = UDim2.new(1, -6, 1, 0)
    nameLabel.Position         = UDim2.new(0, 3, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text             = targetPlayer.DisplayName
    nameLabel.TextColor3       = Color3.fromRGB(80, 255, 130)
    nameLabel.Font             = Enum.Font.GothamBold
    nameLabel.TextSize         = 12
    nameLabel.TextXAlignment   = Enum.TextXAlignment.Center
    nameLabel.TextYAlignment   = Enum.TextYAlignment.Center
    nameLabel.Parent           = bg

    -- Si el nombre de display es diferente al username, mostrarlo abajo en gris
    if targetPlayer.DisplayName ~= targetPlayer.Name then
        billboard.Size = UDim2.new(0, 120, 0, 44)
        nameLabel.Size = UDim2.new(1, -6, 0, 22)

        local usernameLabel = Instance.new("TextLabel")
        usernameLabel.Size             = UDim2.new(1, -6, 0, 16)
        usernameLabel.Position         = UDim2.new(0, 3, 0, 24)
        usernameLabel.BackgroundTransparency = 1
        usernameLabel.Text             = "@" .. targetPlayer.Name
        usernameLabel.TextColor3       = Color3.fromRGB(100, 160, 120)
        usernameLabel.Font             = Enum.Font.Gotham
        usernameLabel.TextSize         = 9
        usernameLabel.TextXAlignment   = Enum.TextXAlignment.Center
        usernameLabel.Parent           = bg
    end

    -- Punto verde de estado (vivo)
    local dot = Instance.new("Frame")
    dot.Name             = "StatusDot"
    dot.Size             = UDim2.new(0, 7, 0, 7)
    dot.Position         = UDim2.new(0, 4, 0.5, 0)
    dot.AnchorPoint      = Vector2.new(0, 0.5)
    dot.BackgroundColor3 = Color3.fromRGB(80, 255, 130)
    dot.BackgroundTransparency = 0
    dot.BorderSizePixel  = 0
    dot.Parent           = bg

    local dc = Instance.new("UICorner")
    dc.CornerRadius = UDim.new(1, 0)
    dc.Parent = dot

    -- Cuando el jugador muere: el nombre se vuelve rojo
    if humanoid then
        humanoid.Died:Connect(function()
            nameLabel.TextColor3   = Color3.fromRGB(200, 60, 60)
            dot.BackgroundColor3   = Color3.fromRGB(200, 60, 60)
            bgs.Color              = Color3.fromRGB(180, 50, 50)
            bg.BackgroundColor3    = Color3.fromRGB(18, 5, 5)
        end)
    end
end

-- Aplicar a todos los jugadores existentes y futuros
local function onPlayerAdded(targetPlayer)
    -- Cuando tenga personaje
    local function onCharacter(character)
        applyNameTag(targetPlayer, character)
    end

    targetPlayer.CharacterAdded:Connect(onCharacter)
    if targetPlayer.Character then
        onCharacter(targetPlayer.Character)
    end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, p in Players:GetPlayers() do
    onPlayerAdded(p)
end

print("[CLIENT] NameTag cargado.")