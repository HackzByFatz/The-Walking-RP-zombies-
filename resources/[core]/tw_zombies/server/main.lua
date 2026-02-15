lib.locale()

local zombiesEnabled = Config.DefaultEnabled
local playerKillCounts = {}

local function notify(source, message, messageType)
    TriggerClientEvent(TW_ZOMBIES.Net.Notify, source, message, messageType or 'inform')
end

local function broadcastState()
    GlobalState[TW_ZOMBIES.StateBagEnabledKey] = zombiesEnabled
    TriggerClientEvent(TW_ZOMBIES.Net.SyncState, -1, zombiesEnabled)
end

local function setZombiesEnabled(newState, actor)
    if zombiesEnabled == newState then
        return
    end

    zombiesEnabled = newState
    broadcastState()

    if actor and actor > 0 then
        notify(actor, newState and locale('zombies_enabled') or locale('zombies_disabled'), newState and 'success' or 'error')
    end
end

lib.callback.register(TW_ZOMBIES.Callback.GetState, function()
    return zombiesEnabled
end)

RegisterNetEvent(TW_ZOMBIES.Net.ZombieKilled, function()
    local source = source

    if not zombiesEnabled then
        return
    end

    playerKillCounts[source] = (playerKillCounts[source] or 0) + 1

    if playerKillCounts[source] % Config.KillsForRewardNotification == 0 then
        notify(source, locale('zombie_kill_milestone', playerKillCounts[source]), 'success')
    end
end)

RegisterCommand(Config.AdminCommand, function(source, args)
    local hasPermission = source == 0 or IsPlayerAceAllowed(source, Config.AdminAcePermission)
    if not hasPermission then
        notify(source, locale('no_permission'), 'error')
        return
    end

    local action = (args[1] or 'toggle'):lower()

    if action == 'on' then
        setZombiesEnabled(true, source)
    elseif action == 'off' then
        setZombiesEnabled(false, source)
    elseif action == 'toggle' then
        setZombiesEnabled(not zombiesEnabled, source)
    else
        notify(source, locale('usage', Config.AdminCommand), 'error')
    end
end, false)

AddEventHandler('playerDropped', function()
    local source = source
    playerKillCounts[source] = nil
end)

CreateThread(function()
    Wait(1000)
    broadcastState()
end)
