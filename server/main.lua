local RESOURCE_NAME = GetCurrentResourceName()

local dependencies = {
    qbx_core = false,
    ox_lib = false,
    ox_inventory = false,
}

local registeredPlayers = {}
local zombiesByBucket = {}
local dependencyWarningShown = false

local function log(level, message)
    print(("[%s] [%s] %s"):format(RESOURCE_NAME, level, message))
end

local function isResourceActive(resourceName)
    local state = GetResourceState(resourceName)
    return state == 'started' or state == 'starting'
end

local function refreshDependencies()
    for resourceName in pairs(dependencies) do
        dependencies[resourceName] = isResourceActive(resourceName)
    end
end

local function startupValidation()
    refreshDependencies()

    log('INFO', ('Qbox active: %s'):format(dependencies.qbx_core and 'yes' or 'no'))
    log('INFO', ('ox_lib active: %s'):format(dependencies.ox_lib and 'yes' or 'no'))
    log('INFO', ('ox_inventory active: %s'):format(dependencies.ox_inventory and 'yes' or 'no'))

    if not dependencies.qbx_core then
        log('WARN', 'qbx_core is not active. Zombie framework hooks will stay idle until it is started.')
    end
end

local function hasExport(resourceName, exportName)
    return pcall(function()
        return exports[resourceName][exportName]
    end)
end

local function getQboxPlayer(source)
    if not dependencies.qbx_core then
        return nil
    end

    if not hasExport('qbx_core', 'GetPlayer') then
        return nil
    end

    local ok, player = pcall(function()
        return exports.qbx_core:GetPlayer(source)
    end)

    if not ok then
        return nil
    end

    return player
end

local function canRunZombieLogic()
    refreshDependencies()

    if not dependencies.qbx_core then
        if not dependencyWarningShown then
            log('WARN', 'Zombie logic paused: qbx_core dependency unavailable.')
            dependencyWarningShown = true
        end
        return false
    end

    dependencyWarningShown = false
    return true
end

local function getBucketForPlayer(source)
    local bucket = GetPlayerRoutingBucket(source)
    if bucket == nil then
        return 0
    end

    return bucket
end

local function registerPlayer(source, origin)
    if not canRunZombieLogic() then
        return
    end

    local player = getQboxPlayer(source)
    if not player then
        return
    end

    local bucket = getBucketForPlayer(source)
    registeredPlayers[source] = {
        source = source,
        bucket = bucket,
        origin = origin,
    }

    zombiesByBucket[bucket] = zombiesByBucket[bucket] or { population = 0 }

    log('INFO', ('Registered player %s from %s in bucket %s'):format(source, origin, bucket))
end

local function cleanupPlayer(source, reason)
    local session = registeredPlayers[source]
    if not session then
        return
    end

    local bucket = session.bucket or 0
    registeredPlayers[source] = nil

    local bucketData = zombiesByBucket[bucket]
    if bucketData then
        bucketData.population = 0
        if next(bucketData) == nil or bucketData.population == 0 then
            zombiesByBucket[bucket] = nil
        end
    end

    log('INFO', ('Cleaned zombie/session state for player %s (%s)'):format(source, reason or 'unknown'))
end

local function spawnZombiesForPlayer(source)
    if not canRunZombieLogic() then
        return
    end

    local session = registeredPlayers[source]
    if not session then
        return
    end

    local bucket = getBucketForPlayer(source)
    if bucket ~= session.bucket then
        session.bucket = bucket
    end

    local bucketData = zombiesByBucket[bucket] or { population = 0 }
    zombiesByBucket[bucket] = bucketData

    bucketData.population = bucketData.population + 1

    TriggerClientEvent('twta-zombies:client:spawnBucketWave', source, {
        bucket = bucket,
        targetPopulation = bucketData.population,
    })
end

local function registerQboxEvents()
    -- Qbox event naming can vary between legacy and current bridges, so listen for both.
    RegisterNetEvent('qbx_core:server:playerLoaded', function(playerSource)
        registerPlayer(playerSource or source, 'qbx_core:server:playerLoaded')
    end)

    RegisterNetEvent('QBCore:Server:PlayerLoaded', function(playerSource)
        registerPlayer(playerSource or source, 'QBCore:Server:PlayerLoaded')
    end)

    RegisterNetEvent('qbx_core:server:playerUnloaded', function(playerSource)
        cleanupPlayer(playerSource or source, 'qbx_core:server:playerUnloaded')
    end)

    RegisterNetEvent('QBCore:Server:OnPlayerUnload', function(playerSource)
        cleanupPlayer(playerSource or source, 'QBCore:Server:OnPlayerUnload')
    end)
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= RESOURCE_NAME then
        return
    end

    startupValidation()
    registerQboxEvents()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= RESOURCE_NAME then
        return
    end

    for playerSource in pairs(registeredPlayers) do
        cleanupPlayer(playerSource, 'resource stop')
    end
end)

AddEventHandler('playerDropped', function(reason)
    cleanupPlayer(source, reason or 'disconnect')
end)

RegisterNetEvent('twta-zombies:server:requestSpawn', function()
    spawnZombiesForPlayer(source)
end)

CreateThread(function()
    while true do
        Wait(20000)

        if canRunZombieLogic() then
            for playerSource in pairs(registeredPlayers) do
                spawnZombiesForPlayer(playerSource)
            end
        end
    end
end)
