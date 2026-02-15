local searchedEntities = {}
local inHighRiskZone = false

local function modelIsAllowed(entity)
    local allowedModels = Config.Target.allowedModels
    if not allowedModels or #allowedModels == 0 then
        return true
    end

    local model = GetEntityModel(entity)
    for i = 1, #allowedModels do
        if model == allowedModels[i] then
            return true
        end
    end

    return false
end

local function canSearchZombie(entity)
    if not DoesEntityExist(entity) or not IsEntityAPed(entity) then
        return false
    end

    if Config.Search.requireDead and not IsEntityDead(entity) then
        return false
    end

    if searchedEntities[entity] then
        return false
    end

    return modelIsAllowed(entity)
end

local function doZombieSearch(entity)
    if not canSearchZombie(entity) then
        lib.notify({ type = 'error', description = Config.Notifications.invalidTarget })
        return
    end

    lib.notify({ type = 'inform', description = Config.Notifications.searchStarted })

    local finished = lib.progressBar({
        duration = Config.Search.durationMs,
        label = Config.Search.cancelLabel,
        canCancel = true,
        useWhileDead = false,
        disable = {
            move = true,
            combat = true,
            car = true,
            mouse = false
        }
    })

    if not finished then
        lib.notify({ type = 'error', description = Config.Notifications.searchCancelled })
        return
    end

    local netId = NetworkGetNetworkIdFromEntity(entity)
    local response = lib.callback.await('twta_zombies:server:searchZombie', false, netId)

    if not response then
        lib.notify({ type = 'error', description = Config.Notifications.searchFailed })
        return
    end

    if not response.success then
        lib.notify({ type = 'error', description = response.message or Config.Notifications.searchFailed })
        return
    end

    searchedEntities[entity] = true

    if response.items and #response.items > 0 then
        local lootLines = {}
        for i = 1, #response.items do
            local entry = response.items[i]
            lootLines[#lootLines + 1] = ('%sx %s'):format(entry.count, entry.label or entry.item)
        end

        lib.notify({
            type = 'success',
            title = 'Zombie Loot',
            description = table.concat(lootLines, '\n')
        })
    else
        lib.notify({ type = 'inform', description = Config.Notifications.searchFailed })
    end

    if Config.Search.removeAfterSearch then
        SetTimeout(Config.Search.removeDelayMs, function()
            if DoesEntityExist(entity) then
                DeleteEntity(entity)
            end
        end)
    end

    Wait((Config.Search.cooldownSeconds or 0) * 1000)
end

exports.ox_target:addGlobalPed({
    {
        name = 'twta_zombie_search',
        icon = Config.Target.icon,
        label = Config.Target.searchLabel,
        distance = Config.Target.searchDistance,
        canInteract = function(entity)
            return canSearchZombie(entity)
        end,
        onSelect = function(data)
            doZombieSearch(data.entity)
        end
    },
    {
        name = 'twta_zombie_loot',
        icon = Config.Target.icon,
        label = Config.Target.lootLabel,
        distance = Config.Target.searchDistance,
        canInteract = function(entity)
            return canSearchZombie(entity)
        end,
        onSelect = function(data)
            doZombieSearch(data.entity)
        end
    }
})

CreateThread(function()
    if not Config.HighRiskZones.enabled then
        return
    end

    if Config.HighRiskZones.usePolyZone and GetResourceState('PolyZone') == 'started' then
        for i = 1, #Config.HighRiskZones.zones do
            local zone = Config.HighRiskZones.zones[i]
            local boxZone = BoxZone:Create(zone.coords, zone.size.x, zone.size.y, {
                name = ('twta_zombie_zone_%s'):format(i),
                heading = zone.rotation,
                minZ = zone.coords.z - (zone.size.z / 2),
                maxZ = zone.coords.z + (zone.size.z / 2),
                debugPoly = zone.debug
            })

            boxZone:onPlayerInOut(function(isPointInside)
                if isPointInside and not inHighRiskZone then
                    inHighRiskZone = true
                    lib.notify({ type = 'warning', description = Config.Notifications.zoneEnter })
                elseif not isPointInside and inHighRiskZone then
                    inHighRiskZone = false
                    lib.notify({ type = 'inform', description = Config.Notifications.zoneExit })
                end
            end)
        end

        return
    end

    for i = 1, #Config.HighRiskZones.zones do
        local zone = Config.HighRiskZones.zones[i]
        lib.zones.box({
            coords = zone.coords,
            size = zone.size,
            rotation = zone.rotation,
            debug = zone.debug,
            onEnter = function()
                inHighRiskZone = true
                lib.notify({ type = 'warning', description = Config.Notifications.zoneEnter })
            end,
            onExit = function()
                inHighRiskZone = false
                lib.notify({ type = 'inform', description = Config.Notifications.zoneExit })
            end
        })
    end
end)
