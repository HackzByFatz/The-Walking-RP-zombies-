local searchedNetIds = {}

local function pickLootItems()
    local lootResults = {}

    for i = 1, #Config.Loot.table do
        local loot = Config.Loot.table[i]
        local chance = math.random(1, 100)

        if chance <= loot.chance then
            local amount = math.random(loot.min, loot.max)
            lootResults[#lootResults + 1] = {
                item = loot.item,
                count = amount,
                label = loot.label
            }
        end
    end

    return lootResults
end

local function entityIsValidZombie(entity)
    if not entity or entity == 0 or not DoesEntityExist(entity) or not IsEntityAPed(entity) then
        return false
    end

    if Config.Search.requireDead and not IsEntityDead(entity) then
        return false
    end

    if Config.Target.allowedModels and #Config.Target.allowedModels > 0 then
        local model = GetEntityModel(entity)
        local allowed = false

        for i = 1, #Config.Target.allowedModels do
            if model == Config.Target.allowedModels[i] then
                allowed = true
                break
            end
        end

        if not allowed then
            return false
        end
    end

    return true
end

lib.callback.register('twta_zombies:server:searchZombie', function(source, netId)
    if not netId or searchedNetIds[netId] then
        return {
            success = false,
            message = Config.Notifications.alreadySearched
        }
    end

    local entity = NetworkGetEntityFromNetworkId(netId)
    if not entityIsValidZombie(entity) then
        return {
            success = false,
            message = Config.Notifications.invalidTarget
        }
    end

    local items = pickLootItems()

    for i = 1, #items do
        local loot = items[i]
        exports.ox_inventory:AddItem(source, loot.item, loot.count)
    end

    searchedNetIds[netId] = true

    return {
        success = true,
        items = items
    }
end)
