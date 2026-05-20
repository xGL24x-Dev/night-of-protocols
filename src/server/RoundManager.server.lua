-- ============================================
-- RoundManager.server.lua
-- Script de SERVIDOR — Director de rondas
-- Flujo: Lobby → Cuenta regresiva → Rondas 1-4
--        (cada ronda: oleadas → si es la 4, boss)
--        → Victoria o Derrota por tiempo
-- Ubicación: src/server/RoundManager.server.lua
-- ============================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local GameConfig    = require(ReplicatedStorage.Shared.GameConfig)
local EnemySpawner  = require(script.Parent:WaitForChild("EnemySpawner"))

-- ════════════════════════════════════════════════
--  REMOTE EVENTS
--  Se agregan a la carpeta Remotes que ya crea
--  PlayerManager (esperamos a que exista)
-- ════════════════════════════════════════════════
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local function makeEvent(name)
    local e = remotes:FindFirstChild(name)
    if not e then
        e        = Instance.new("RemoteEvent")
        e.Name   = name
        e.Parent = remotes
    end
    return e
end

local evCountdown   = makeEvent("RoundCountdown")   -- (secondsLeft)
local evRoundStart  = makeEvent("RoundStart")        -- (roundNum, totalRounds)
local evWaveStart   = makeEvent("WaveStart")         -- (waveNum, totalWaves, enemyType)
local evWaveClear   = makeEvent("WaveClear")         -- ()
local evBossSpawn   = makeEvent("BossSpawn")         -- (bossName, bossHP)
local evRoundEnd    = makeEvent("RoundEnd")          -- (won: bool)
local evPhaseChange = makeEvent("PhaseChange")       -- (phase: string)

-- ════════════════════════════════════════════════
--  HELPERS
-- ════════════════════════════════════════════════
local function broadcast(event, ...)
    for _, plr in Players:GetPlayers() do
        event:FireClient(plr, ...)
    end
end

-- Espera en segundos sin bloquear el scheduler
local function waitSeconds(t)
    local start = tick()
    repeat RunService.Heartbeat:Wait() until tick() - start >= t
end

-- Lee el multiplicador de noche que pone DayNightCycle
local function getEnemyMultiplier()
    local val = ReplicatedStorage:FindFirstChild("EnemyMultiplier")
    return val and val.Value or 1.0
end

-- ════════════════════════════════════════════════
--  CUENTA REGRESIVA
-- ════════════════════════════════════════════════
local function runCountdown()
    broadcast(evPhaseChange, "countdown")
    for i = GameConfig.COUNTDOWN_TIME, 1, -1 do
        broadcast(evCountdown, i)
        waitSeconds(1)
    end
end

-- ════════════════════════════════════════════════
--  OLEADA
-- ════════════════════════════════════════════════
local function runWave(roundData, waveIndex)
    local multiplier   = getEnemyMultiplier()
    local hp           = math.floor(roundData.enemyHP * multiplier)
    local aliveEnemies = roundData.enemiesPerWave

    broadcast(evWaveStart, waveIndex, roundData.waves, roundData.enemyType)
    print(string.format("[RoundManager] Oleada %d/%d — %d x %s (HP: %d, mult: %.1f)",
        waveIndex, roundData.waves, roundData.enemiesPerWave,
        roundData.enemyType, hp, multiplier))

    EnemySpawner.spawnWave(roundData.enemyType, roundData.enemiesPerWave, hp, function()
        aliveEnemies = math.max(0, aliveEnemies - 1)
    end)

    -- Esperar hasta que todos mueran (timeout: ROUND_TIME)
    local timeout = tick() + GameConfig.ROUND_TIME
    repeat
        waitSeconds(0.5)
    until aliveEnemies <= 0 or tick() > timeout

    EnemySpawner.clearAll()
    broadcast(evWaveClear)
    print("[RoundManager] Oleada " .. waveIndex .. " limpia.")
    waitSeconds(3)
end

-- ════════════════════════════════════════════════
--  JEFE FINAL
-- ════════════════════════════════════════════════
local function runBoss(roundData)
    broadcast(evPhaseChange, "boss")

    local multiplier = getEnemyMultiplier()
    local bossHP     = math.floor(roundData.bossHP * multiplier)
    local bossAlive  = true

    EnemySpawner.spawnBoss(roundData.bossName, bossHP, function()
        bossAlive = false
    end)

    broadcast(evBossSpawn, roundData.bossName, bossHP)
    print(string.format("[RoundManager] Boss spawneado: %s (HP: %d)", roundData.bossName, bossHP))

    -- Timeout de 10 minutos para el boss
    local timeout = tick() + 600
    repeat
        waitSeconds(0.5)
    until not bossAlive or tick() > timeout

    return not bossAlive  -- true = jugadores ganaron
end

-- ════════════════════════════════════════════════
--  LOOP PRINCIPAL
-- ════════════════════════════════════════════════
local function startGame()
    local rounds      = GameConfig.ROUNDS
    local totalRounds = #rounds  -- 4

    print("[RoundManager] Iniciando juego — " .. totalRounds .. " rondas.")

    -- Cuenta regresiva
    runCountdown()

    for roundIndex, roundData in ipairs(rounds) do
        -- Anunciar ronda
        broadcast(evRoundStart, roundIndex, totalRounds)
        broadcast(evPhaseChange, "active")
        print("[RoundManager] ══ RONDA " .. roundIndex .. " / " .. totalRounds .. " ══")

        -- Oleadas de la ronda
        for waveIndex = 1, roundData.waves do
            runWave(roundData, waveIndex)

            -- Pausa entre oleadas (no después de la última)
            if waveIndex < roundData.waves then
                waitSeconds(roundData.waveDelay)
            end
        end

        -- ¿Es la ronda del boss?
        if roundData.isBossRound then
            local won = runBoss(roundData)
            broadcast(evRoundEnd, won)
            print("[RoundManager] Juego terminado — " .. (won and "VICTORIA" or "DERROTA"))
            return
        end

        -- Intermisión entre rondas normales
        if roundIndex < totalRounds then
            broadcast(evPhaseChange, "intermission")
            print("[RoundManager] Intermisión " .. GameConfig.INTERMISSION_TIME .. "s...")
            waitSeconds(GameConfig.INTERMISSION_TIME)
        end
    end
end

-- ════════════════════════════════════════════════
--  ARRANQUE
--  Espera al menos 1 jugador y que PlayerManager
--  haya creado los Remotes antes de iniciar
-- ════════════════════════════════════════════════
local gameStarted = false

-- Esperar al LobbyManager para iniciar
local lobbyDone = ReplicatedStorage:WaitForChild("LobbyDone")
lobbyDone.Event:Connect(function()
    if not gameStarted then
        gameStarted = true
        task.spawn(startGame)
    end
end)

print("[RoundManager] Esperando al lobby para iniciar.")