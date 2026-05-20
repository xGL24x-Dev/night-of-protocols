-- ============================================
-- LobbyClient.client.lua
-- Script de CLIENTE — UI del Lobby
--
-- Muestra el panel del lobby:
--   · Si eres el host: botones 2/3/4 y botón Iniciar
--   · Si eres invitado: lista de jugadores y estado
--
-- Ubicación: src/client/LobbyClient.client.lua
-- ============================================

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes        = ReplicatedStorage:WaitForChild("Remotes")
local evLobbyState   = remotes:WaitForChild("LobbyState")
local evPlayerJoined = remotes:WaitForChild("LobbyPlayerJoin")
local evLobbyStart   = remotes:WaitForChild("LobbyStart")
local rfSetMax       = remotes:WaitForChild("SetMaxPlayers")
local rfStart        = remotes:WaitForChild("StartLobby")

-- ════════════════════════════════════════════════
--  GUI
-- ════════════════════════════════════════════════
if playerGui:FindFirstChild("LobbyGui") then
    playerGui.LobbyGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name         = "LobbyGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 30
ScreenGui.Parent       = playerGui

-- Panel principal
local Panel = Instance.new("Frame")
Panel.Name             = "LobbyPanel"
Panel.Size             = UDim2.new(0, 340, 0, 320)
Panel.Position         = UDim2.new(0.5, 0, 0.5, 0)
Panel.AnchorPoint      = Vector2.new(0.5, 0.5)
Panel.BackgroundColor3 = Color3.fromRGB(8, 8, 14)
Panel.BackgroundTransparency = 0.05
Panel.BorderSizePixel  = 0
Panel.Visible          = false
Panel.Parent           = ScreenGui

local pc = Instance.new("UICorner")
pc.CornerRadius = UDim.new(0, 16)
pc.Parent = Panel

local ps = Instance.new("UIStroke")
ps.Color       = Color3.fromRGB(80, 255, 160)
ps.Thickness   = 1.8
ps.Transparency = 0.3
ps.Parent = Panel

-- Header
local Header = Instance.new("Frame")
Header.Size             = UDim2.new(1, 0, 0, 52)
Header.BackgroundColor3 = Color3.fromRGB(10, 10, 22)
Header.BackgroundTransparency = 0
Header.BorderSizePixel  = 0
Header.Parent           = Panel

local hc = Instance.new("UICorner")
hc.CornerRadius = UDim.new(0, 16)
hc.Parent = Header

local hpatch = Instance.new("Frame")
hpatch.Size             = UDim2.new(1, 0, 0, 16)
hpatch.Position         = UDim2.new(0, 0, 1, -16)
hpatch.BackgroundColor3 = Color3.fromRGB(10, 10, 22)
hpatch.BackgroundTransparency = 0
hpatch.BorderSizePixel  = 0
hpatch.Parent           = Header

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size             = UDim2.new(1, -16, 1, 0)
TitleLabel.Position         = UDim2.new(0, 14, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text             = "🟢  ZONA DE INICIO"
TitleLabel.TextColor3       = Color3.fromRGB(80, 255, 160)
TitleLabel.Font             = Enum.Font.GothamBlack
TitleLabel.TextSize         = 15
TitleLabel.TextXAlignment   = Enum.TextXAlignment.Left
TitleLabel.Parent           = Header

-- Subtítulo de estado
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name             = "Status"
StatusLabel.Size             = UDim2.new(1, -20, 0, 24)
StatusLabel.Position         = UDim2.new(0, 10, 0, 56)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text             = "Entra al círculo verde para unirte"
StatusLabel.TextColor3       = Color3.fromRGB(160, 160, 200)
StatusLabel.Font             = Enum.Font.Gotham
StatusLabel.TextSize         = 12
StatusLabel.TextXAlignment   = Enum.TextXAlignment.Center
StatusLabel.Parent           = Panel

-- Lista de jugadores
local PlayerList = Instance.new("Frame")
PlayerList.Name             = "PlayerList"
PlayerList.Size             = UDim2.new(1, -20, 0, 100)
PlayerList.Position         = UDim2.new(0, 10, 0, 86)
PlayerList.BackgroundColor3 = Color3.fromRGB(12, 10, 22)
PlayerList.BackgroundTransparency = 0.2
PlayerList.BorderSizePixel  = 0
PlayerList.Parent           = Panel

local plc = Instance.new("UICorner")
plc.CornerRadius = UDim.new(0, 10)
plc.Parent = PlayerList

local pll = Instance.new("UIListLayout")
pll.FillDirection = Enum.FillDirection.Vertical
pll.HorizontalAlignment = Enum.HorizontalAlignment.Center
pll.VerticalAlignment   = Enum.VerticalAlignment.Top
pll.Padding = UDim.new(0, 4)
pll.Parent = PlayerList

local plpad = Instance.new("UIPadding")
plpad.PaddingTop  = UDim.new(0, 6)
plpad.PaddingLeft = UDim.new(0, 8)
plpad.Parent = PlayerList

-- Separador
local Sep = Instance.new("Frame")
Sep.Size             = UDim2.new(1, -20, 0, 1)
Sep.Position         = UDim2.new(0, 10, 0, 194)
Sep.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
Sep.BackgroundTransparency = 0.3
Sep.BorderSizePixel  = 0
Sep.Parent           = Panel

-- Sección HOST: elegir tamaño
local HostSection = Instance.new("Frame")
HostSection.Name             = "HostSection"
HostSection.Size             = UDim2.new(1, -20, 0, 100)
HostSection.Position         = UDim2.new(0, 10, 0, 202)
HostSection.BackgroundTransparency = 1
HostSection.BorderSizePixel  = 0
HostSection.Visible          = false
HostSection.Parent           = Panel

local hostTitle = Instance.new("TextLabel")
hostTitle.Size             = UDim2.new(1, 0, 0, 20)
hostTitle.BackgroundTransparency = 1
hostTitle.Text             = "¿Cuántos jugadores?"
hostTitle.TextColor3       = Color3.fromRGB(200, 200, 230)
hostTitle.Font             = Enum.Font.GothamBold
hostTitle.TextSize         = 12
hostTitle.TextXAlignment   = Enum.TextXAlignment.Center
hostTitle.Parent           = HostSection

-- Botones 2 / 3 / 4
local SizeBtns = Instance.new("Frame")
SizeBtns.Size             = UDim2.new(1, 0, 0, 40)
SizeBtns.Position         = UDim2.new(0, 0, 0, 24)
SizeBtns.BackgroundTransparency = 1
SizeBtns.BorderSizePixel  = 0
SizeBtns.Parent           = HostSection

local sbl = Instance.new("UIListLayout")
sbl.FillDirection = Enum.FillDirection.Horizontal
sbl.HorizontalAlignment = Enum.HorizontalAlignment.Center
sbl.Padding = UDim.new(0, 8)
sbl.Parent = SizeBtns

local selectedSize = 0
local sizeBtnRefs  = {}

for _, n in ipairs({2, 3, 4}) do
    local btn = Instance.new("TextButton")
    btn.Name             = "Size_"..n
    btn.Size             = UDim2.new(0, 72, 0, 36)
    btn.BackgroundColor3 = Color3.fromRGB(20, 18, 38)
    btn.BackgroundTransparency = 0.2
    btn.BorderSizePixel  = 0
    btn.Text             = tostring(n) .. " 👤"
    btn.TextColor3       = Color3.fromRGB(160, 160, 200)
    btn.Font             = Enum.Font.GothamBold
    btn.TextSize         = 13
    btn.Parent           = SizeBtns

    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 8)
    bc.Parent = btn

    local bs = Instance.new("UIStroke")
    bs.Color       = Color3.fromRGB(60, 55, 100)
    bs.Thickness   = 1
    bs.Transparency = 0.4
    bs.Parent = btn

    sizeBtnRefs[n] = { btn=btn, stroke=bs }

    btn.MouseButton1Click:Connect(function()
        selectedSize = n
        -- Destacar botón seleccionado
        for _, ref in pairs(sizeBtnRefs) do
            ref.stroke.Color       = Color3.fromRGB(60, 55, 100)
            ref.stroke.Transparency = 0.4
            ref.btn.BackgroundColor3 = Color3.fromRGB(20, 18, 38)
            ref.btn.TextColor3       = Color3.fromRGB(160, 160, 200)
        end
        bs.Color       = Color3.fromRGB(80, 255, 160)
        bs.Transparency = 0.1
        btn.BackgroundColor3 = Color3.fromRGB(14, 30, 22)
        btn.TextColor3       = Color3.fromRGB(80, 255, 160)

        -- Enviar al servidor
        local ok, msg = rfSetMax:InvokeServer(n)
        if not ok then
            print("[LOBBY] Error: " .. tostring(msg))
        end
    end)
end

-- Botón Iniciar
local StartBtn = Instance.new("TextButton")
StartBtn.Name             = "StartBtn"
StartBtn.Size             = UDim2.new(1, 0, 0, 34)
StartBtn.Position         = UDim2.new(0, 0, 0, 68)
StartBtn.BackgroundColor3 = Color3.fromRGB(20, 80, 40)
StartBtn.BackgroundTransparency = 0.1
StartBtn.BorderSizePixel  = 0
StartBtn.Text             = "▶  INICIAR PARTIDA"
StartBtn.TextColor3       = Color3.fromRGB(80, 255, 140)
StartBtn.Font             = Enum.Font.GothamBold
StartBtn.TextSize         = 13
StartBtn.Parent           = HostSection

local sbc = Instance.new("UICorner")
sbc.CornerRadius = UDim.new(0, 8)
sbc.Parent = StartBtn

local sbs = Instance.new("UIStroke")
sbs.Color       = Color3.fromRGB(80, 255, 140)
sbs.Thickness   = 1.2
sbs.Transparency = 0.3
sbs.Parent = StartBtn

StartBtn.MouseButton1Click:Connect(function()
    if selectedSize == 0 then
        StatusLabel.Text = "⚠ Elige cuántos jugadores primero"
        return
    end
    local ok, msg = rfStart:InvokeServer()
    if not ok then
        StatusLabel.Text = "⚠ " .. tostring(msg)
    end
end)

-- Sección INVITADO: solo espera
local GuestSection = Instance.new("Frame")
GuestSection.Name             = "GuestSection"
GuestSection.Size             = UDim2.new(1, -20, 0, 100)
GuestSection.Position         = UDim2.new(0, 10, 0, 202)
GuestSection.BackgroundTransparency = 1
GuestSection.BorderSizePixel  = 0
GuestSection.Visible          = false
GuestSection.Parent           = Panel

local guestLabel = Instance.new("TextLabel")
guestLabel.Size             = UDim2.new(1, 0, 1, 0)
guestLabel.BackgroundTransparency = 1
guestLabel.Text             = "Esperando al host..."
guestLabel.TextColor3       = Color3.fromRGB(160, 160, 200)
guestLabel.Font             = Enum.Font.Gotham
guestLabel.TextSize         = 13
guestLabel.TextXAlignment   = Enum.TextXAlignment.Center
guestLabel.Parent           = GuestSection

-- ════════════════════════════════════════════════
--  ACTUALIZAR UI CON EL ESTADO DEL LOBBY
-- ════════════════════════════════════════════════
local function updatePlayerList(playerNames)
    for _, c in PlayerList:GetChildren() do
        if c:IsA("TextLabel") then c:Destroy() end
    end
    for i, name in ipairs(playerNames) do
        local lbl = Instance.new("TextLabel")
        lbl.Size             = UDim2.new(1, -10, 0, 20)
        lbl.BackgroundTransparency = 1
        lbl.Text             = "● " .. name
        lbl.TextColor3       = Color3.fromRGB(80, 255, 160)
        lbl.Font             = Enum.Font.GothamBold
        lbl.TextSize         = 12
        lbl.TextXAlignment   = Enum.TextXAlignment.Left
        lbl.Parent           = PlayerList
    end
end

evLobbyState.OnClientEvent:Connect(function(data)
    local amIInLobby = false
    for _, name in ipairs(data.players) do
        if name == player.Name then amIInLobby = true break end
    end

    -- Mostrar/ocultar panel
    if amIInLobby then
        Panel.Visible = true
    else
        Panel.Visible = false
        return
    end

    updatePlayerList(data.players)

    local amHost = (data.host == player.Name)

    -- Actualizar estado
    if data.phase == "choosing" then
        if amHost then
            StatusLabel.Text = "👑 Eres el lider — elige el tamaño de la partida"
        else
            StatusLabel.Text = "Esperando que " .. (data.host or "el lider") .. " elija..."
        end
    elseif data.phase == "ready" then
        local count = #data.players
        local max   = data.maxPlayers
        StatusLabel.Text = "Jugadores: " .. count .. " / " .. max
        if amHost then
            StatusLabel.Text = StatusLabel.Text .. "  — Puedes iniciar"
        end
    elseif data.phase == "starting" then
        StatusLabel.Text = "⚡ ¡Iniciando partida..."
    end

    -- Mostrar sección correcta
    HostSection.Visible  = amHost and (data.phase == "choosing" or data.phase == "ready")
    GuestSection.Visible = not amHost
    if not amHost then
        if data.phase == "choosing" then
            guestLabel.Text = "👑 " .. (data.host or "el lider") .. " está eligiendo..."
        elseif data.phase == "ready" then
            guestLabel.Text = "Esperando que el lider inicie..."
        end
    end
end)

-- Notificación de nuevo jugador unido
evPlayerJoined.OnClientEvent:Connect(function(name)
    -- Flash verde breve en el borde del panel
    TweenService:Create(ps, TweenInfo.new(0.2), { Transparency = 0 }):Play()
    task.wait(0.3)
    TweenService:Create(ps, TweenInfo.new(0.4), { Transparency = 0.3 }):Play()
end)

-- Partida iniciando
evLobbyStart.OnClientEvent:Connect(function(count)
    StatusLabel.Text = "⚡ Iniciando con " .. count .. " jugadores..."
    TweenService:Create(Panel,
        TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { BackgroundTransparency = 1 }):Play()
    task.wait(0.8)
    Panel.Visible = false
end)

print("[CLIENT] LobbyClient listo.")
