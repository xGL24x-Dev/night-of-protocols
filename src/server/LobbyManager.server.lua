-- ============================================
-- LobbyManager.server.lua
-- Script de SERVIDOR — Sistema de Lobby
--
-- MECÁNICA:
--   · Hay un círculo (Part "LobbyCircle") en Workspace
--   · El primer jugador en entrar elige el tamaño de partida (2/3/4)
--   · Los demás pueden unirse al equipo
--   · Cuando se llena O el host presiona iniciar → arranca el juego
--   · Notifica a RoundManager via BindableEvent
--
-- Ubicación: src/server/LobbyManager.server.lua
-- ============================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

-- ════════════════════════════════════════════════
--  REMOTE EVENTS (en la carpeta Remotes que crea PlayerManager)
-- ════════════════════════════════════════════════
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local function makeEvent(name)
    local e = remotes:FindFirstChild(name)
    if not e then
        e = Instance.new("RemoteEvent")
        e.Name = name
        e.Parent = remotes
    end
    return e
end

local function makeFunction(name)
    local f = remotes:FindFirstChild(name)
    if not f then
        f = Instance.new("RemoteFunction")
        f.Name = name
        f.Parent = remotes
    end
    return f
end

local evLobbyState    = makeEvent("LobbyState")     -- → cliente: estado actual del lobby
local evPlayerJoined  = makeEvent("LobbyPlayerJoin") -- → cliente: alguien entró al círculo
local evLobbyStart    = makeEvent("LobbyStart")      -- → cliente: partida iniciando
local rfSetMaxPlayers = makeFunction("SetMaxPlayers") -- cliente → servidor: host elige tamaño
local rfStartLobby    = makeFunction("StartLobby")    -- cliente → servidor: host inicia

-- BindableEvent para avisarle al RoundManager
local lobbyDone = Instance.new("BindableEvent")
lobbyDone.Name   = "LobbyDone"
lobbyDone.Parent = ReplicatedStorage

-- ════════════════════════════════════════════════
--  ESTADO DEL LOBBY
-- ════════════════════════════════════════════════
local LobbyState = {
    phase      = "waiting",   -- waiting | choosing | ready | starting
    host       = nil,         -- Player (el primero en entrar)
    maxPlayers = 0,           -- elegido por el host (2/3/4)
    players    = {},          -- jugadores dentro del círculo
}

local VALID_SIZES = {2, 3, 4}

local function broadcastState()
    local playerNames = {}
    for _, p in ipairs(LobbyState.players) do
        table.insert(playerNames, p.Name)
    end
    local data = {
        phase      = LobbyState.phase,
        host       = LobbyState.host and LobbyState.host.Name or nil,
        maxPlayers = LobbyState.maxPlayers,
        players    = playerNames,
    }
    for _, p in Players:GetPlayers() do
        evLobbyState:FireClient(p, data)
    end
end

local function isInLobby(player)
    for _, p in ipairs(LobbyState.players) do
        if p == player then return true end
    end
    return false
end

local function removeFromLobby(player)
    for i, p in ipairs(LobbyState.players) do
        if p == player then
            table.remove(LobbyState.players, i)
            break
        end
    end
    -- Si era el host y quedan jugadores, reasignar host
    if LobbyState.host == player then
        if #LobbyState.players > 0 then
            LobbyState.host  = LobbyState.players[1]
            LobbyState.phase = "choosing"
            LobbyState.maxPlayers = 0
        else
            LobbyState.host  = nil
            LobbyState.phase = "waiting"
            LobbyState.maxPlayers = 0
        end
    end
    broadcastState()
end

-- ════════════════════════════════════════════════
--  DETECCIÓN DE ENTRADA AL CÍRCULO
--  Usando un Part llamado "LobbyCircle" en Workspace
-- ════════════════════════════════════════════════
local lobbyCircle = workspace:WaitForChild("LobbyCircle")
local CIRCLE_RADIUS = lobbyCircle.Size.X / 2  -- asume que es un cilindro/esfera

RunService.Heartbeat:Connect(function()
    if LobbyState.phase == "starting" then return end

    for _, player in Players:GetPlayers() do
        local character = player.Character
        if not character then continue end
        local root = character:FindFirstChild("HumanoidRootPart")
        if not root then continue end

        local dist = (root.Position - lobbyCircle.Position).Magnitude
        local inside = dist <= CIRCLE_RADIUS

        if inside and not isInLobby(player) then
            -- Entró al círculo
            table.insert(LobbyState.players, player)

            if #LobbyState.players == 1 then
                -- Es el primero → se convierte en host
                LobbyState.host  = player
                LobbyState.phase = "choosing"
                print("[LOBBY] Host: " .. player.Name .. " — eligiendo tamaño de partida")
            else
                print("[LOBBY] " .. player.Name .. " se unió al lobby (" .. #LobbyState.players .. "/" .. LobbyState.maxPlayers .. ")")
                evPlayerJoined:FireAllClients(player.Name)
            end

            broadcastState()

            -- Si ya se completó el cupo, pasar a ready
            if LobbyState.maxPlayers > 0 and #LobbyState.players >= LobbyState.maxPlayers then
                LobbyState.phase = "ready"
                broadcastState()
            end

        elseif not inside and isInLobby(player) then
            -- Salió del círculo
            removeFromLobby(player)
            print("[LOBBY] " .. player.Name .. " salió del círculo")
        end
    end
end)

-- ════════════════════════════════════════════════
--  REMOTE FUNCTIONS
-- ════════════════════════════════════════════════

-- El host elige el tamaño (2/3/4)
rfSetMaxPlayers.OnServerInvoke = function(player, size)
    if player ~= LobbyState.host then return false, "No eres el host" end
    if LobbyState.phase ~= "choosing" then return false, "Fase incorrecta" end

    local valid = false
    for _, v in ipairs(VALID_SIZES) do
        if v == size then valid = true break end
    end
    if not valid then return false, "Tamaño inválido" end

    LobbyState.maxPlayers = size
    LobbyState.phase      = "ready"
    broadcastState()
    print("[LOBBY] Tamaño de partida: " .. size .. " jugadores")
    return true
end