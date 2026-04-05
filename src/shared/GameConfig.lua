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

return GameConfig