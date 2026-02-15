Config = {}

Config.Target = {
    icon = 'fa-solid fa-skull',
    searchLabel = 'Search zombie',
    lootLabel = 'Loot zombie',
    searchDistance = 2.0,
    allowedModels = {
        -- Add zombie model hashes here if you want to limit interactions.
        -- `nil` or empty table allows all dead peds.
        -- `joaat("u_m_y_zombie_01")`
    }
}

Config.Search = {
    durationMs = 7500,
    cooldownSeconds = 2,
    cancelLabel = 'Searching zombie...',
    requireDead = true,
    removeAfterSearch = false,
    removeDelayMs = 1000
}

Config.Notifications = {
    searchStarted = 'Searching the corpse...',
    searchCancelled = 'You stopped searching.',
    searchFailed = 'You found nothing useful.',
    alreadySearched = 'This zombie has already been searched.',
    invalidTarget = 'You can only search dead zombies.',
    zoneEnter = 'You entered a high-risk infected area.',
    zoneExit = 'You left the high-risk infected area.'
}

Config.Loot = {
    currencyItem = nil, -- Example: 'money'
    table = {
        { item = 'water', min = 1, max = 2, chance = 65 },
        { item = 'bandage', min = 1, max = 1, chance = 45 },
        { item = 'bread', min = 1, max = 2, chance = 55 },
        { item = 'lockpick', min = 1, max = 1, chance = 15 },
        { item = 'radio', min = 1, max = 1, chance = 8 }
    }
}

Config.HighRiskZones = {
    enabled = true,
    usePolyZone = false,
    zones = {
        {
            name = 'Legion Infected Block',
            coords = vec3(206.27, -932.37, 30.69),
            size = vec3(120.0, 120.0, 50.0),
            rotation = 340.0,
            debug = false
        }
    }
}
