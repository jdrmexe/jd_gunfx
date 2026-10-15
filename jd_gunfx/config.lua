Config = {}

-- ─────────────────────────────────────────────────────────────
--  FIRING -> EAR RINGING
-- ─────────────────────────────────────────────────────────────
Config.Ringing = {
    enabled = true,

    -- Your .mp3 goes here: html/sounds/<file>
    file = 'ringing.mp3',

    -- true  = file loops for as long as the ringing lasts (use a seamless tone)
    -- false = file plays once per trigger (use if your mp3 already fades out by itself)
    loop = true,

    volume = 0.8,          -- master volume of the ringing (0.0 - 1.0)
    maxVolume = 1.0,       -- ceiling when many shots stack
    stack = 0.3,           -- each extra shot adds (weapon volume x stack) while still ringing
    fadeOut = 2500,        -- ms to fade away once the duration is over

    interiorMultiplier = 1.4,   -- louder indoors (reverberant)
    vehicleMultiplier = 1.15,   -- louder inside a vehicle
    suppressedMultiplier = 0.2, -- weapon fitted with a suppressor

    -- Suppressor components (a weapon with any of these equipped uses suppressedMultiplier)
    suppressors = {
        'COMPONENT_AT_PI_SUPP', 'COMPONENT_AT_PI_SUPP_02',
        'COMPONENT_AT_AR_SUPP', 'COMPONENT_AT_AR_SUPP_02',
        'COMPONENT_AT_SR_SUPP', 'COMPONENT_AT_SR_SUPP_03',
        'COMPONENT_AT_MUZZLE_01' -- remove if you do not want this one counted
    }
}

-- Weapons that cause ringing.  volume = how loud the ring starts (0-1), duration = how long it lasts (ms).
-- Anything NOT listed here never causes ringing. Addon weapons: just add their spawn name.
Config.Weapons = {
    WEAPON_RPG      = { volume = 0.90, duration = 2500 },      
    WEAPON_MG          = { volume = 0.30, duration = 2500 },
    WEAPON_COMBATMG        = { volume = 0.60, duration = 4500 },
}

-- ─────────────────────────────────────────────────────────────
--  BEING SHOT AT -> WHIZZ + SHAKE
-- ─────────────────────────────────────────────────────────────
Config.NearMiss = {
    enabled = true,

    outerRadius = 2.6,   -- metres around your head: bullet = "passing by"
    innerRadius = 1.0,   -- metres around your head: bullet = "very close" (louder + harder shake)
    cooldown = 120,      -- ms between two near-miss reactions
    ignoreOwnBullets = true,

    -- Whizz files live in html/sounds/. One is picked at random (pitch + pan randomised).
    sounds = { 'whiz_1.ogg', 'whiz_2.ogg', 'whiz_3.ogg', 'whiz_4.ogg' },
    volumeFar = 0.55,
    volumeClose = 0.95,

    -- Camera reaction
    shake = {
        enabled = true,
        name = 'SMALL_EXPLOSION_SHAKE',
        far = 0.05,       -- amplitude for a bullet passing by
        close = 0.11,     -- amplitude for a very close one
        duration = 260,   -- ms
        -- tiny involuntary camera flinch (degrees, random direction). 0 disables.
        flinchFar = 0.25,
        flinchClose = 0.7
    }
}

-- Actually getting hit by a bullet
Config.Hit = {
    enabled = true,
    shake = { name = 'JOLT_SHAKE', amplitude = 0.28, duration = 450 }
}

Config.TestCommand = 'testgunfx'   -- plays ringing + whizz + shake once (nil to disable)
