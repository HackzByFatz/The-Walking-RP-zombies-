# The Walking RP Zombies (`tw_zombies`)

A lightweight zombie gameplay core for FiveM servers running on **Qbox** with **Ox** modules.

---

## Just the Zombies (Quickstart)

Use this if you only want zombie spawning/gameplay online quickly with minimal setup.

1. Place the resource at:
   - `resources/[core]/tw_zombies`
2. Make sure required dependencies are installed and ensured first (see [Dependencies](#dependencies)).
3. Add the `ensure` block below to your `server.cfg` in the same order.
4. Start/restart your server.
5. Tune values in `config.lua` (or your config file) using the [Config Reference](#config-reference).

```cfg
# === Base priority: framework first ===
ensure oxmysql
ensure ox_lib
ensure ox_target
ensure ox_inventory

ensure qbx_core

# === Gameplay/resources that tw_zombies relies on ===
# (add your own core gameplay resources here)

# === Zombies near the end of your core stack ===
ensure tw_zombies
```

---

## Installation

### Resource path

Install the folder in exactly this path:

```text
resources/[core]/tw_zombies
```

### Dependencies

This resource expects a Qbox + Ox environment.

#### Qbox

- `qbx_core`

#### Ox modules

- `oxmysql`
- `ox_lib`
- `ox_target`
- `ox_inventory`

> Keep dependencies ensured **before** `tw_zombies`.

### `server.cfg` ensure order (exact snippet)

Use this base-priority ordering as a starting point:

```cfg
# database + shared libs
ensure oxmysql
ensure ox_lib

# framework core
ensure qbx_core

# ox gameplay stack
ensure ox_target
ensure ox_inventory

# your server core resources
# ensure your_resource_1
# ensure your_resource_2

# zombies (after framework/dependencies)
ensure tw_zombies
```

---

## Config Reference

Below is a practical reference for common zombie tuning values. Names should match your resource config.

| Key | Type | Example Default | What it controls | Recommended range |
|---|---|---:|---|---|
| `MaxZombies` | integer | `40` | Maximum simultaneously active zombies. | `20-80` |
| `SpawnInterval` | integer (ms) | `5000` | Delay between spawn attempts. Lower = more pressure. | `3000-10000` |
| `SpawnRadius` | number | `120.0` | Radius around players where zombies may spawn. | `80.0-180.0` |
| `DespawnDistance` | number | `220.0` | Distance after which zombies are cleaned up. | `180.0-350.0` |
| `DamageMultiplier` | number | `1.0` | Global zombie damage scaling. | `0.75-2.0` |
| `HeadshotOnly` | boolean | `false` | If enabled, only headshots kill zombies. | `true/false` |
| `LootEnabled` | boolean | `true` | Enables zombie loot drops/rewards. | `true/false` |
| `AggroRange` | number | `45.0` | Detection range for chasing players. | `25.0-60.0` |
| `TickInterval` | integer (ms) | `500` | Main AI/update tick rate. Lower = smoother, heavier CPU usage. | `400-1000` |
| `Debug` | boolean | `false` | Enables verbose debug logging/visuals. | `true/false` |

> If your config includes additional keys, follow the same tuning logic: keep aggressive values only where player counts and hardware allow.

---

## Performance Tips

Zombie AI and ped management can become expensive quickly. Start conservative, then scale up.

- **Use entity caps intentionally**
  - Keep `MaxZombies` aligned with peak player counts.
  - Suggested baseline: `25-40` zombies for small/medium servers.
- **Increase spawn intervals before raising caps**
  - If server time or frame pacing worsens, raise `SpawnInterval` first.
- **Avoid very low tick intervals**
  - `TickInterval` below `300ms` can heavily increase script CPU usage.
  - Safe default for most servers: `500-750ms`.
- **Keep despawn distances practical**
  - Large `DespawnDistance` values keep entities alive too long and increase network load.
- **Test at realistic concurrency**
  - Validate with expected player counts, not empty-server tests only.
- **Enable debug only while tuning**
  - Turn `Debug` off in production.

### Recommended default profile

For most deployments:

- `MaxZombies = 35`
- `SpawnInterval = 6000`
- `SpawnRadius = 120.0`
- `DespawnDistance = 250.0`
- `TickInterval = 600`
- `HeadshotOnly = false`

This gives stable pressure without overloading low/mid-range hosts.
# The-Walking-RP-zombies-

Zombie interaction resource for FiveM using:
- `ox_target` for corpse interaction.
- `ox_inventory` for loot rewards.
- `ox_lib` for progress bars, callbacks, notifications, and optional zone warnings.

## Features
- Search/loot dead zombie peds via `ox_target`.
- Server-authoritative loot rolls through `ox_lib` callbacks.
- Loot distribution through `ox_inventory`.
- Optional high-risk area alerts using `ox_lib` zones or PolyZone.
- Centralized balancing in `config.lua` (loot + chances + labels + timing).

## Configuration
All balancing values live in `config.lua`:
- `Config.Target`: labels/icons/interact distance + allowed zombie models.
- `Config.Search`: progress duration, cooldown, dead-check, corpse cleanup.
- `Config.Notifications`: status and error text.
- `Config.Loot.table`: item names, min/max, chance.
- `Config.HighRiskZones`: zone list and optional PolyZone usage.

## Dependencies
- `ox_lib`
- `ox_target`
- `ox_inventory`
- `PolyZone` (optional, only when `Config.HighRiskZones.usePolyZone = true`)

## Usage
1. Add your zombie model hashes to `Config.Target.allowedModels` if you want to restrict targets.
2. Define your server loot economy in `Config.Loot.table`.
3. Add high-risk area entries in `Config.HighRiskZones.zones`.
4. Ensure dependencies are started before this resource.
