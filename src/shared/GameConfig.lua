-- ============================================
-- GameConfig.lua
-- Módulo compartido: configuración global
-- Accesible tanto desde servidor como cliente
-- ============================================

local GameConfig = {}

-- ── JUGADOR ───────────────────────────────
GameConfig.PLAYER_HEALTH     = 100      -- Salud máxima del jugador
GameConfig.PLAYER_WALKSPEED  = 16       -- Velocidad normal
GameConfig.PLAYER_SPRINTSPEED = 24      -- Velocidad al correr

-- ── ENEMIGOS ──────────────────────────────
GameConfig.VIGILANTE_SPEED        = 12  -- Velocidad del Vigilante
GameConfig.VIGILANTE_DETECT_RANGE = 30  -- Distancia en studs para detectar al jugador
GameConfig.VIGILANTE_DAMAGE       = 15  -- Daño por toque

-- ── MECÁNICA DE LOCURA ────────────────────
GameConfig.SANITY_MAX        = 100      -- Cordura máxima
GameConfig.SANITY_DRAIN_RATE = 0.5      -- Cuánta cordura pierde por segundo en oscuridad
GameConfig.SANITY_RECOVER    = 0.2      -- Recuperación por segundo en zona segura

-- ── OBJETIVOS ─────────────────────────────
GameConfig.TOTAL_GENERATORS  = 3        -- Generadores que hay que activar para escapar
GameConfig.HACK_TIME         = 5        -- Segundos para hackear un terminal

-- ── JUEGO ─────────────────────────────────
GameConfig.ROUND_TIME        = 600      -- Tiempo límite de la ronda (10 minutos)
GameConfig.LOBBY_WAIT_TIME   = 15       -- Segundos de espera en lobby antes de iniciar

-- ── RONDAS ────────────────────────────────
-- 4 rondas en total. La ronda 4 tiene boss.
-- enemyHP y enemyDamage se multiplican por
-- EnemyMultiplier (1.0 día / 1.5 noche).
GameConfig.ROUNDS = {
    {
        -- Ronda 1: introducción, enemigos lentos y débiles
        waves          = 3,
        enemiesPerWave = 4,
        enemyType      = "Vigilante",
        enemyHP        = 60,
        enemyDamage    = 10,
        waveDelay      = 8,    -- segundos entre oleadas
        isBossRound    = false,
    },
    {
        -- Ronda 2: más enemigos, algo más rápidos
        waves          = 3,
        enemiesPerWave = 6,
        enemyType      = "Vigilante",
        enemyHP        = 80,
        enemyDamage    = 15,
        waveDelay      = 7,
        isBossRound    = false,
    },
    {
        -- Ronda 3: oleadas grandes, enemigos resistentes
        waves          = 4,
        enemiesPerWave = 8,
        enemyType      = "Vigilante",
        enemyHP        = 100,
        enemyDamage    = 20,
        waveDelay      = 6,
        isBossRound    = false,
    },
    {
        -- Ronda 4: oleada previa + jefe final
        waves          = 2,
        enemiesPerWave = 6,
        enemyType      = "Vigilante",
        enemyHP        = 100,
        enemyDamage    = 20,
        waveDelay      = 5,
        isBossRound    = true,
        bossName       = "FinalBoss",
        bossHP         = 2000,
        bossDamage     = 35,
    },
}

GameConfig.INTERMISSION_TIME = 10   -- segundos entre rondas
GameConfig.COUNTDOWN_TIME    = 10   -- cuenta regresiva antes de ronda 1

return GameConfig