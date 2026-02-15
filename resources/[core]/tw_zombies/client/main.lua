lib.locale()

local zombiesEnabled = Config.DefaultEnabled
local spawnedZombies = {}
local rewardedZombies = {}

local function debugPrint(message)
    if Config.Debug then
        print(('[tw_zombies] %s'):format(message))
    end
end

local function notify(data)
    lib.notify({
        title = locale('resource_label'),
        description = data.description,
        type = data.type or 'inform'
    })
end

local function clearZombie(zombie)
    if DoesEntityExist(zombie) then
        SetEntityAsMissionEntity(zombie, true, true)
        DeleteEntity(zombie)
    end
end

local function cleanupZombies(force)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    for index = #spawnedZombies, 1, -1 do
        local zombie = spawnedZombies[index]

        if not DoesEntityExist(zombie) then
            table.remove(spawnedZombies, index)
        else
            local zombieCoords = GetEntityCoords(zombie)
            local tooFar = #(playerCoords - zombieCoords) > (Config.SpawnRadius.max + 80.0)

            if force or tooFar then
                clearZombie(zombie)
                table.remove(spawnedZombies, index)
            end
        end
    end
end

local function setupZombieAttributes(zombie)
    SetEntityHealth(zombie, Config.ZombieHealth)
    SetPedArmour(zombie, 0)
    SetPedCanRagdoll(zombie, true)
    SetPedRelationshipGroupHash(zombie, `HATES_PLAYER`)
    SetPedAlertness(zombie, 3)
    SetPedHearingRange(zombie, 200.0)
    SetPedSeeingRange(zombie, 200.0)
    SetPedCombatAttributes(zombie, 46, true)
    SetPedCombatAttributes(zombie, 5, true)
    SetPedFleeAttributes(zombie, 0, false)
    SetPedAsEnemy(zombie, true)
    SetPedDropsWeaponsWhenDead(zombie, false)
    SetAiMeleeWeaponDamageModifier(Config.ZombieDamageModifier)
    SetPedMoveRateOverride(zombie, Config.ZombieMoveRate)
end

local function spawnZombie()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    local angle = math.rad(math.random(0, 359))
    local distance = math.random() * (Config.SpawnRadius.max - Config.SpawnRadius.min) + Config.SpawnRadius.min
    local spawnCoords = vec3(
        playerCoords.x + math.cos(angle) * distance,
        playerCoords.y + math.sin(angle) * distance,
        playerCoords.z
    )

    local model = Config.ZombieModels[math.random(1, #Config.ZombieModels)]
    lib.requestModel(model, 10000)

    local zombie = CreatePed(4, model, spawnCoords.x, spawnCoords.y, spawnCoords.z, math.random(0, 359) + 0.0, true, true)
    if zombie == 0 then
        return
    end

    setupZombieAttributes(zombie)
    TaskCombatPed(zombie, playerPed, 0, 16)

    SetModelAsNoLongerNeeded(model)
    spawnedZombies[#spawnedZombies + 1] = zombie

    debugPrint(('Spawned zombie %s (count: %s)'):format(zombie, #spawnedZombies))
end

RegisterNetEvent(TW_ZOMBIES.Net.SyncState, function(enabled)
    zombiesEnabled = enabled and true or false

    if zombiesEnabled then
        notify({ description = locale('zombies_enabled'), type = 'success' })
    else
        notify({ description = locale('zombies_disabled'), type = 'error' })
        cleanupZombies(true)
    end
end)

RegisterNetEvent(TW_ZOMBIES.Net.Notify, function(message, type)
    notify({ description = message, type = type })
end)

CreateThread(function()
    while true do
        if zombiesEnabled and #spawnedZombies < Config.MaxSpawnedPerPlayer then
            spawnZombie()
        end

        Wait(Config.SpawnInterval)
    end
end)

CreateThread(function()
    while true do
        if zombiesEnabled then
            local playerPed = PlayerPedId()

            for i = #spawnedZombies, 1, -1 do
                local zombie = spawnedZombies[i]

                if not DoesEntityExist(zombie) then
                    table.remove(spawnedZombies, i)
                elseif IsEntityDead(zombie) then
                    if not rewardedZombies[zombie] then
                        local killer = GetPedSourceOfDeath(zombie)
                        if killer == playerPed then
                            rewardedZombies[zombie] = true
                            TriggerServerEvent(TW_ZOMBIES.Net.ZombieKilled)
                        end
                    end

                    clearZombie(zombie)
                    table.remove(spawnedZombies, i)
                end
            end

            cleanupZombies(false)
        elseif #spawnedZombies > 0 then
            cleanupZombies(true)
        end

        Wait(Config.CleanupInterval)
    end
end)

CreateThread(function()
    local state = lib.callback.await(TW_ZOMBIES.Callback.GetState, false)
    if state ~= nil then
        zombiesEnabled = state
    end

    if zombiesEnabled then
        notify({ description = locale('zombies_enabled'), type = 'success' })
    end
end)
