-- ============================================
-- EnemySpawner.lua
-- ModuleScript de SERVIDOR
-- Clona y posiciona enemigos/jefe desde ServerStorage
-- Ubicación: src/server/EnemySpawner.lua
-- ============================================

local ServerStorage = game:GetService("ServerStorage")
local Workspace     = game:GetService("Workspace")

local EnemySpawner = {}

-- Carpeta donde viven los modelos en ServerStorage
local EnemyModels = ServerStorage:WaitForChild("EnemyModels")

-- Carpeta donde se depositan los enemigos vivos
local EnemyFolder = Workspace:FindFirstChild("Enemies")
if not EnemyFolder then
    EnemyFolder      = Instance.new("Folder")
    EnemyFolder.Name = "Enemies"
    EnemyFolder.Parent = Workspace
end

-- Puntos de spawn: partes en Workspace/SpawnPoints
local spawnPointsFolder = Workspace:WaitForChild("SpawnPoints")

local function getRandomSpawn()
    local points = spawnPointsFolder:GetChildren()
    if #points == 0 then
        return Vector3.new(0, 5, 0)
    end
    return points[math.random(1, #points)].Position + Vector3.new(0, 3, 0)
end

-- Clona un enemigo y conecta su muerte al callback
local function spawnEnemy(modelName, hp, onDeath)
    local template = EnemyModels:FindFirstChild(modelName)
    if not template then
        warn("[EnemySpawner] No existe el modelo: " .. modelName)
        return
    end

    local enemy = template:Clone()
    enemy.Parent = EnemyFolder

    -- Posicionar
    local hrp = enemy:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = CFrame.new(getRandomSpawn())
    end

    -- Aplicar HP (ya modificado por el multiplicador de noche)
    local humanoid = enemy:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.MaxHealth = hp
        humanoid.Health    = hp
        humanoid.Died:Connect(function()
            onDeath()
            task.delay(3, function()
                if enemy and enemy.Parent then
                    enemy:Destroy()
                end
            end)
        end)
    end
end

-- ── API PÚBLICA ───────────────────────────────

-- Spawnea una oleada completa.
-- onEachDeath se llama cada vez que muere un enemigo.
function EnemySpawner.spawnWave(enemyType, count, hp, onEachDeath)
    for i = 1, count do
        spawnEnemy(enemyType, hp, onEachDeath)
        task.wait(0.35)  -- pequeño delay entre spawns
    end
end

-- Spawnea el jefe final.
-- onDeath se llama cuando el jefe muere.
function EnemySpawner.spawnBoss(bossName, hp, onDeath)
    local template = EnemyModels:FindFirstChild(bossName)
    if not template then
        warn("[EnemySpawner] No existe el modelo de boss: " .. bossName)
        return
    end

    local boss = template:Clone()
    boss.Name   = "ActiveBoss"
    boss.Parent = EnemyFolder

    local humanoid = boss:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.MaxHealth = hp
        humanoid.Health    = hp
        humanoid.Died:Connect(function()
            onDeath()
            task.delay(5, function()
                if boss and boss.Parent then boss:Destroy() end
            end)
        end)
    end

    -- El jefe spawnea en BossSpawn (una Part en Workspace)
    local bossSpawn = Workspace:FindFirstChild("BossSpawn")
    local hrp = boss:FindFirstChild("HumanoidRootPart")
    if hrp and bossSpawn then
        hrp.CFrame = CFrame.new(bossSpawn.Position + Vector3.new(0, 5, 0))
    end
end

-- Destruye todos los enemigos vivos (se usa entre oleadas si hace falta)
function EnemySpawner.clearAll()
    for _, enemy in EnemyFolder:GetChildren() do
        enemy:Destroy()
    end
end

return EnemySpawner