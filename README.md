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
