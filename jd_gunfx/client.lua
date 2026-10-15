local nuiReady = false
local weaponMap = {}
local suppressorHashes = {}
local hearingProtected = false

local lastOwnShot = 0
local lastNearMiss = 0
local shakeToken = 0

local SKEL_HEAD = 31086

for name, data in pairs(Config.Weapons) do
    weaponMap[joaat(name)] = data
end
for _, name in ipairs(Config.Ringing.suppressors) do
    suppressorHashes[#suppressorHashes + 1] = joaat(name)
end

-- ─── NUI ───────────────────────────────────────────────────────
local function sendConfig()
    SendNUIMessage({
        action = 'config',
        ringing = {
            file = Config.Ringing.file,
            loop = Config.Ringing.loop,
            volume = Config.Ringing.volume,
            maxVolume = Config.Ringing.maxVolume,
            stack = Config.Ringing.stack,
            fadeOut = Config.Ringing.fadeOut
        },
        whiz = Config.NearMiss.sounds
    })
end

RegisterNUICallback('ready', function(_, cb)
    nuiReady = true
    sendConfig()
    cb('ok')
end)

-- ─── Camera ────────────────────────────────────────────────────
local function cameraShake(name, amplitude, duration)
    shakeToken = shakeToken + 1
    local token = shakeToken
    ShakeGameplayCam(name, amplitude)
    SetTimeout(duration, function()
        if token == shakeToken then
            StopGameplayCamShaking(false)
        end
    end)
end

local function flinch(degrees)
    if degrees <= 0.0 then return end
    local sign = math.random(0, 1) == 0 and -1.0 or 1.0
    local pitch = GetGameplayCamRelativePitch()
    local heading = GetGameplayCamRelativeHeading()
    SetGameplayCamRelativePitch(pitch + (math.random() * degrees * 0.8), 0.6)
    SetGameplayCamRelativeHeading(heading + sign * (math.random() * degrees), 0.6)
end

-- ─── Ringing ───────────────────────────────────────────────────
local function isSuppressed(ped, weapon)
    for i = 1, #suppressorHashes do
        if HasPedGotWeaponComponent(ped, weapon, suppressorHashes[i]) then
            return true
        end
    end
    return false
end

local function triggerRinging(ped, weapon, data)
    if hearingProtected or not nuiReady then return end

    local volume = data.volume
    if isSuppressed(ped, weapon) then
        volume = volume * Config.Ringing.suppressedMultiplier
    end
    if GetInteriorFromEntity(ped) ~= 0 then
        volume = volume * Config.Ringing.interiorMultiplier
    end
    if IsPedInAnyVehicle(ped, false) then
        volume = volume * Config.Ringing.vehicleMultiplier
    end

    SendNUIMessage({
        action = 'ring',
        volume = math.min(volume, 1.0),
        duration = data.duration
    })
end

-- ─── Near misses ───────────────────────────────────────────────
local function nearMissReaction(close)
    local cfg = Config.NearMiss
    SendNUIMessage({
        action = 'whiz',
        volume = close and cfg.volumeClose or cfg.volumeFar
    })

    if cfg.shake.enabled then
        cameraShake(cfg.shake.name, close and cfg.shake.close or cfg.shake.far, cfg.shake.duration)
        flinch(close and cfg.shake.flinchClose or cfg.shake.flinchFar)
    end
end

local function bulletsNearby(x, y, z, radius, shooting)
    if not IsBulletInArea(x, y, z, radius, false) then return false end
    if shooting and Config.NearMiss.ignoreOwnBullets and IsBulletInArea(x, y, z, radius, true) then
        return false
    end
    return true
end

-- ─── Main loops ────────────────────────────────────────────────
-- Slow loop (50 ms): caches the ped / dead state and watches for bullet hits.
-- Fast loop (every frame): only the three natives that must run per frame.
local ped = PlayerPedId()
local dead = false

CreateThread(function()
    local lastHealth = GetEntityHealth(ped)
    while true do
        ped = PlayerPedId()
        dead = IsEntityDead(ped)

        if Config.Hit.enabled then
            local health = GetEntityHealth(ped)
            if health > 0 and HasPedBeenDamagedByWeapon(ped, 0, 2) then
                if health < lastHealth then
                    local s = Config.Hit.shake
                    cameraShake(s.name, s.amplitude, s.duration)
                end
                -- clears only the weapon-damage flag, not the killer / damage entity data
                ClearPedLastWeaponDamage(ped)
            end
            lastHealth = health
        end

        Wait(50)
    end
end)

CreateThread(function()
    local near = Config.NearMiss
    local ringingOn = Config.Ringing.enabled
    local nearOn = near.enabled
    if not ringingOn and not nearOn then return end

    -- cheap coarse gate around the body; the precise head check only runs when this hits
    local gateRadius = near.outerRadius + 1.0

    while true do
        if IsPedShooting(ped) then
            lastOwnShot = GetGameTimer()
            if ringingOn then
                local weapon = GetSelectedPedWeapon(ped)
                local data = weaponMap[weapon]
                if data then triggerRinging(ped, weapon, data) end
            end
        end

        if nearOn and not dead then
            local c = GetEntityCoords(ped)
            if IsBulletInArea(c.x, c.y, c.z + 0.3, gateRadius, false) then
                local now = GetGameTimer()
                if now - lastNearMiss >= near.cooldown then
                    local head = GetPedBoneCoords(ped, SKEL_HEAD, 0.0, 0.0, 0.0)
                    local shooting = now - lastOwnShot < 250
                    if bulletsNearby(head.x, head.y, head.z, near.outerRadius, shooting) then
                        lastNearMiss = now
                        nearMissReaction(bulletsNearby(head.x, head.y, head.z, near.innerRadius, shooting))
                    end
                end
            end
        end

        Wait(0)
    end
end)

-- ─── Exports (hearing protection: earmuffs, headset, etc.) ─────
exports('setHearingProtection', function(state)
    hearingProtected = state == true
end)

exports('hasHearingProtection', function()
    return hearingProtected
end)

-- ─── Test command ──────────────────────────────────────────────
if Config.TestCommand then
    RegisterCommand(Config.TestCommand, function()
        SendNUIMessage({ action = 'ring', volume = 0.6, duration = 4000 })
        SetTimeout(1200, function() nearMissReaction(false) end)
        SetTimeout(2400, function() nearMissReaction(true) end)
    end, false)
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    StopGameplayCamShaking(true)
end)
