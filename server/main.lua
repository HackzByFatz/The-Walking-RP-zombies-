local ZOMBIE_GROUP_HASH = GetHashKey(Config.RelationshipGroups.zombie)

local zombies = {}
local modelCursor = 1
local spawnCursor = 1

local function nowMs()
    return GetGameTimer()
end

local function isNightHour(hour)
    return hour >= 20 or hour < 6
end

local function getDesiredMultiplier()
    local hour = tonumber(os.date("%H")) or 12
    if isNightHour(hour) then
        return Config.DayNightMultiplier.night or 1.0
    end

    return Config.DayNightMultiplier.day or 1.0
end

local function clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end
    if value > maxValue then
        return maxValue
    end
    return value
end

local function getPlayerPedAndCoords(src)
    local ped = GetPlayerPed(src)
    if ped == 0 or not DoesEntityExist(ped) then
        return nil, nil
    end

    return ped, GetEntityCoords(ped)
end

local function getOnlinePlayers()
    local players = {}

    for _, src in ipairs(GetPlayers()) do
        local ped, coords = getPlayerPedAndCoords(src)
        if ped and coords then
            players[#players + 1] = {
                src = src,
                ped = ped,
                coords = coords,
            }
        end
    end

    return players
end

local function distance(a, b)
    return #(a - b)
end

local function getZoneDensity(coords)
    local bestDensity = 1.0
    local foundZone = false

    for _, zone in ipairs(Config.SpawnZones or {}) do
        if distance(coords, zone.center) <= zone.radius then
            bestDensity = zone.density or 1.0
            foundZone = true
            break
        end
    end

    if not foundZone then
        return 0.55
    end

    return bestDensity
end

local function calculateDesiredCount(players)
    if #players == 0 then
        return 0
    end

    local aggregateDensity = 0.0
    for _, player in ipairs(players) do
        aggregateDensity = aggregateDensity + getZoneDensity(player.coords)
    end

    local averageDensity = aggregateDensity / #players
    local base = math.floor((#players * Config.ZombiesPerPlayer) * averageDensity)
    local withTime = math.floor(base * getDesiredMultiplier())

    return clamp(withTime, Config.MinZombies, Config.MaxZombies)
end

local function ensureRelationshipGroups()
    AddRelationshipGroup(Config.RelationshipGroups.zombie)

    SetRelationshipBetweenGroups(5, ZOMBIE_GROUP_HASH, GetHashKey(Config.RelationshipGroups.player))
    SetRelationshipBetweenGroups(5, GetHashKey(Config.RelationshipGroups.player), ZOMBIE_GROUP_HASH)
end

local function pickModelHash()
    if #Config.ZombieModels == 0 then
        return nil
    end

    local index = ((modelCursor - 1) % #Config.ZombieModels) + 1
    modelCursor = modelCursor + 1
    return Config.ZombieModels[index]
end

local function tryLoadModel(modelHash)
    if not IsModelInCdimage(modelHash) then
        return false
    end

    RequestModel(modelHash)
    local timeoutAt = nowMs() + 5000
    while not HasModelLoaded(modelHash) do
        if nowMs() > timeoutAt then
            return false
        end
        Wait(25)
    end

    return true
end

local function pickAnchorPlayer(players)
    if #players == 0 then
        return nil
    end

    local index = ((spawnCursor - 1) % #players) + 1
    spawnCursor = spawnCursor + 1
    return players[index]
end

local function findGroundZ(x, y, z)
    local found, groundZ = GetGroundZFor_3dCoord(x, y, z + 25.0, false)
    if found then
        return groundZ + 0.5
    end
    return z
end

local function randomSpawnOffset(radius)
    local angle = (spawnCursor * 57) % 360
    local rad = math.rad(angle)
    local spread = 20.0 + (spawnCursor % 8) * ((radius - 20.0) / 8.0)

    return math.cos(rad) * spread, math.sin(rad) * spread
end

local function spawnZombieNear(players)
    if #zombies >= Config.MaxZombies then
        return false
    end

    local anchor = pickAnchorPlayer(players)
    if not anchor then
        return false
    end

    local modelHash = pickModelHash()
    if not modelHash or not tryLoadModel(modelHash) then
        return false
    end

    local ox, oy = randomSpawnOffset(Config.SpawnRadius)
    local x = anchor.coords.x + ox
    local y = anchor.coords.y + oy
    local z = findGroundZ(x, y, anchor.coords.z)

    local ped = CreatePed(4, modelHash, x, y, z, 0.0, true, true)
    if ped == 0 then
        SetModelAsNoLongerNeeded(modelHash)
        return false
    end

    SetEntityAsMissionEntity(ped, true, true)
    SetPedRelationshipGroupHash(ped, ZOMBIE_GROUP_HASH)
    SetPedMaxHealth(ped, Config.ZombieHealth)
    SetEntityHealth(ped, Config.ZombieHealth)
    SetPedArmour(ped, Config.ZombieArmor)
    SetPedSeeingRange(ped, Config.AggroRange)
    SetPedHearingRange(ped, Config.AggroRange)
    SetPedAlertness(ped, 3)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 46, true)
    SetPedCombatAttributes(ped, 5, true)
    SetPedCombatRange(ped, 0)
    SetPedKeepTask(ped, true)

    local netId = NetworkGetNetworkIdFromEntity(ped)
    SetNetworkIdCanMigrate(netId, true)
    Entity(ped).state:set("isZombie", true, true)

    zombies[#zombies + 1] = {
        ped = ped,
        spawnedAt = nowMs(),
        lastTaskAt = 0,
        lastAttackAt = 0,
        deadAt = nil,
    }

    SetModelAsNoLongerNeeded(modelHash)
    return true
end

local function getNearestPlayer(players, coords)
    local nearest = nil
    local nearestDistance = math.huge

    for _, player in ipairs(players) do
        local d = distance(coords, player.coords)
        if d < nearestDistance then
            nearest = player
            nearestDistance = d
        end
    end

    return nearest, nearestDistance
end

local function damagePlayerPed(playerPed)
    local currentHealth = GetEntityHealth(playerPed)
    if currentHealth <= 0 then
        return
    end

    local newHealth = currentHealth - Config.AttackDamage
    if newHealth < 0 then
        newHealth = 0
    end

    SetEntityHealth(playerPed, newHealth)
end

local function cleanupZombieAt(index)
    local zombie = zombies[index]
    if not zombie then
        return
    end

    if zombie.ped and DoesEntityExist(zombie.ped) then
        DeleteEntity(zombie.ped)
    end

    zombies[index] = zombies[#zombies]
    zombies[#zombies] = nil
end

local function cleanupOverflow()
    while #zombies > Config.MaxZombies do
        cleanupZombieAt(#zombies)
    end
end

local function updateZombieAi(players)
    local tickNow = nowMs()

    for i = #zombies, 1, -1 do
        local zombie = zombies[i]

        if not zombie.ped or not DoesEntityExist(zombie.ped) then
            cleanupZombieAt(i)
        else
            local zombieCoords = GetEntityCoords(zombie.ped)
            local nearestPlayer, nearestDistance = getNearestPlayer(players, zombieCoords)

            if IsEntityDead(zombie.ped) then
                zombie.deadAt = zombie.deadAt or tickNow
                if tickNow - zombie.deadAt >= Config.DeadDespawnMs then
                    cleanupZombieAt(i)
                end
            elseif not nearestPlayer or nearestDistance > Config.DespawnDistance then
                cleanupZombieAt(i)
            else
                if nearestDistance <= Config.AggroRange and (tickNow - zombie.lastTaskAt) >= 850 then
                    TaskGoToEntity(zombie.ped, nearestPlayer.ped, -1, 0.0, 2.2, 0.0, 0)
                    zombie.lastTaskAt = tickNow
                end

                if nearestDistance <= Config.AttackRange and (tickNow - zombie.lastAttackAt) >= Config.AttackCooldownMs then
                    damagePlayerPed(nearestPlayer.ped)
                    zombie.lastAttackAt = tickNow
                end
            end
        end
    end

    cleanupOverflow()
end

CreateThread(function()
    ensureRelationshipGroups()

    while true do
        local players = getOnlinePlayers()
        local desiredCount = calculateDesiredCount(players)
        local canSpawn = desiredCount - #zombies

        if canSpawn > 0 and #players > 0 then
            for _ = 1, canSpawn do
                if #zombies >= Config.MaxZombies then
                    break
                end

                if not spawnZombieNear(players) then
                    break
                end
            end
        elseif canSpawn < 0 then
            for _ = 1, math.abs(canSpawn) do
                if #zombies == 0 then
                    break
                end
                cleanupZombieAt(#zombies)
            end
        end

        Wait(Config.SpawnTickMs)
    end
end)

CreateThread(function()
    while true do
        local players = getOnlinePlayers()
        updateZombieAi(players)
        Wait(Config.AiTickMs)
    end
end)
