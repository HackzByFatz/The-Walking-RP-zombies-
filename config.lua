Config = {}

-- Hard cap for all active zombie entities.
Config.MaxZombies = 60

-- Optional floor so the world never feels empty when players are online.
Config.MinZombies = 12

-- Radius around selected player anchors used for spawn attempts.
Config.SpawnRadius = 85.0

-- Zombies farther than this from every player are despawned.
Config.DespawnDistance = 220.0

-- Base melee damage per successful attack.
Config.AttackDamage = 16

-- Detection radius used to acquire/maintain player targets.
Config.AggroRange = 45.0

-- Melee distance and attack pacing.
Config.AttackRange = 2.0
Config.AttackCooldownMs = 1700

-- Cleanup pacing for dead zombies.
Config.DeadDespawnMs = 12000

-- Global tick pacing.
Config.SpawnTickMs = 2500
Config.AiTickMs = 600

-- Spawn controller scaling.
Config.ZombiesPerPlayer = 8

-- Optional weighted zones: desired count scales with zone density for players inside.
Config.SpawnZones = {
    { name = "LosSantos", center = vector3(215.0, -925.0, 30.0), radius = 1650.0, density = 1.00 },
    { name = "BlaineCounty", center = vector3(1710.0, 4630.0, 41.0), radius = 1900.0, density = 0.70 },
}

-- Day/night multipliers applied to desired active zombie count.
Config.DayNightMultiplier = {
    day = 0.80,
    night = 1.35,
}

Config.ZombieModels = {
    `u_m_y_zombie_01`,
    `a_m_m_skater_01`,
    `a_m_y_methhead_01`,
    `a_m_y_vindouche_01`,
}

Config.MovementClipset = "move_m@drunk@verydrunk"
Config.ZombieHealth = 280
Config.ZombieArmor = 0

Config.RelationshipGroups = {
    zombie = "ZOMBIES",
    player = "PLAYER",
}
