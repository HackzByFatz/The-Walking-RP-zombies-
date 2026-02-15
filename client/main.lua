local configuredPeds = {}
local zombieGroupHash = GetHashKey(Config.RelationshipGroups.zombie)
local playerGroupHash = GetHashKey(Config.RelationshipGroups.player)

local function ensureRelationshipGroups()
    AddRelationshipGroup(Config.RelationshipGroups.zombie)
    SetRelationshipBetweenGroups(5, zombieGroupHash, playerGroupHash)
    SetRelationshipBetweenGroups(5, playerGroupHash, zombieGroupHash)
end

local function loadClipset(clipset)
    RequestAnimSet(clipset)
    local timeoutAt = GetGameTimer() + 5000

    while not HasAnimSetLoaded(clipset) do
        if GetGameTimer() > timeoutAt then
            return false
        end
        Wait(25)
    end

    return true
end

local function configureZombiePed(ped)
    if configuredPeds[ped] then
        return
    end

    SetPedRelationshipGroupHash(ped, zombieGroupHash)
    SetPedCanRagdollFromPlayerImpact(ped, false)
    SetPedSuffersCriticalHits(ped, false)
    SetPedCombatMovement(ped, 2)
    SetPedCombatRange(ped, 0)

    if loadClipset(Config.MovementClipset) then
        SetPedMovementClipset(ped, Config.MovementClipset, 1.0)
    end

    configuredPeds[ped] = true
end

CreateThread(function()
    ensureRelationshipGroups()

    while true do
        local pool = GetGamePool("CPed")
        local seen = {}

        for _, ped in ipairs(pool) do
            if DoesEntityExist(ped) and Entity(ped).state.isZombie then
                configureZombiePed(ped)
                seen[ped] = true
            end
        end

        for ped in pairs(configuredPeds) do
            if not seen[ped] or not DoesEntityExist(ped) then
                configuredPeds[ped] = nil
            end
        end

        Wait(1200)
    end
end)
