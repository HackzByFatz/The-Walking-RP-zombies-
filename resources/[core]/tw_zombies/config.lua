Config = {}

Config.Debug = false
Config.DefaultEnabled = true

Config.SpawnInterval = 7000 -- ms between spawn checks
Config.CleanupInterval = 2500 -- ms between cleanup checks
Config.MaxSpawnedPerPlayer = 8
Config.SpawnRadius = {
    min = 30.0,
    max = 65.0
}

Config.ZombieModels = {
    `u_m_y_zombie_01`,
    `a_m_m_tramp_01`,
    `a_m_m_hillbilly_01`,
    `a_m_m_skidrow_01`
}

Config.ZombieHealth = 220
Config.ZombieDamageModifier = 0.4
Config.ZombieMoveRate = 1.0

Config.AdminCommand = 'zombies'
Config.AdminAcePermission = 'command.zombies'

Config.KillsForRewardNotification = 10
