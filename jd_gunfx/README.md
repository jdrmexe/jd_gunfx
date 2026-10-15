# jd_gunfx

Gunfire realism for FiveM: **ringing ears** when you fire loud weapons, and **bullet whizz + screen shake** when you are shot at.

Standalone. No framework needed. Client-side only.

---

## Contents

- [Features](#features)
- [Install](#install)
- [Adding your own sounds](#adding-your-own-sounds)
- [Choosing which weapons cause ringing](#choosing-which-weapons-cause-ringing)
- [Being shot at](#being-shot-at)
- [Configuration](#configuration)
- [Commands and exports](#commands-and-exports)
- [Troubleshooting](#troubleshooting)

---

## Features

- Ringing sound when you fire configured weapons, using your own `.mp3`
- Each weapon has its own ring volume and length
- Repeated shots stack the ringing, then it fades out
- Louder indoors and in vehicles, much quieter with a suppressor
- Bullets passing your head play a whizz sound (random pitch and left/right position)
- Camera shake and a tiny flinch when bullets pass close, a bigger jolt when you are hit
- Hearing protection export for earmuffs or headsets

---

## Install

1. Put the `jd_gunfx` folder in your `resources` folder.
2. Add `ensure jd_gunfx` to your `server.cfg`.
3. Replace the placeholder ringing sound with yours (below).

---

## Adding your own sounds

The included sounds are **generated placeholders**, not real recordings. They are there so everything works straight away. Replace them whenever you like.

### Ringing

Put your file at:

```
html/sounds/ringing.mp3
```

Or use another name and set it in `config.lua`:

```lua
Config.Ringing.file = 'my_ringing.mp3'
```

| Your file | Setting |
|---|---|
| Short steady tone that can repeat | `Config.Ringing.loop = true` |
| Longer clip that fades out by itself | `Config.Ringing.loop = false` |

### Bullet whizz

Drop `.ogg` or `.mp3` files into `html/sounds/` and list them:

```lua
Config.NearMiss.sounds = { 'whiz_1.ogg', 'whiz_2.ogg', 'my_whiz.ogg' }
```

One is picked at random each time.

If you use sounds from the internet, check their licence first. Freesound (CC0 filter) and the free Sonniss GDC audio bundles are good places to look.

---

## Choosing which weapons cause ringing

Only weapons listed in `Config.Weapons` cause ringing. Remove a line to turn it off for that weapon.

```lua
Config.Weapons = {
    WEAPON_PISTOL        = { volume = 0.30, duration = 2500 },
    WEAPON_CARBINERIFLE  = { volume = 0.52, duration = 3800 },
    WEAPON_HEAVYSNIPER   = { volume = 0.85, duration = 5800 },
}
```

| Field | Meaning |
|---|---|
| `volume` | How loud the ringing starts, from 0.0 to 1.0 |
| `duration` | How long it lasts, in milliseconds |

Addon weapons work too: add their spawn name the same way.

### Modifiers

| Situation | Setting | Default |
|---|---|---|
| Inside an interior | `Config.Ringing.interiorMultiplier` | `1.4` |
| Inside a vehicle | `Config.Ringing.vehicleMultiplier` | `1.15` |
| Suppressor fitted | `Config.Ringing.suppressedMultiplier` | `0.2` |

---

## Being shot at

When a bullet passes near your head:

- a whizz sound plays,
- the camera shakes and flinches slightly,
- a bullet that is very close does all of this harder.

Getting actually hit gives a stronger jolt.

Your own bullets are ignored, so you still get whizzes while returning fire.

---

## Configuration

Everything is in `config.lua`.

### Ringing

| Setting | Default | Description |
|---|---|---|
| `Ringing.enabled` | `true` | Turn ringing on or off |
| `Ringing.volume` | `0.8` | Master volume |
| `Ringing.maxVolume` | `1.0` | Highest the ringing can stack to |
| `Ringing.stack` | `0.3` | How much each extra shot adds |
| `Ringing.fadeOut` | `2500` | Fade-out time in ms |

### Near misses

| Setting | Default | Description |
|---|---|---|
| `NearMiss.enabled` | `true` | Turn near-miss effects on or off |
| `NearMiss.outerRadius` | `2.6` | Metres around your head that count as "passing by" |
| `NearMiss.innerRadius` | `1.0` | Metres that count as "very close" |
| `NearMiss.cooldown` | `120` | Minimum ms between reactions |
| `NearMiss.volumeFar / volumeClose` | `0.55 / 0.95` | Whizz volume |
| `NearMiss.shake.far / close` | `0.05 / 0.11` | Shake strength |
| `NearMiss.shake.duration` | `260` | Shake length in ms |
| `NearMiss.shake.flinchFar / flinchClose` | `0.25 / 0.7` | Camera flinch in degrees (0 turns it off) |

### Getting hit

| Setting | Default | Description |
|---|---|---|
| `Hit.enabled` | `true` | Turn the hit jolt on or off |
| `Hit.shake.amplitude` | `0.28` | Jolt strength |
| `Hit.shake.duration` | `450` | Jolt length in ms |

---

## Commands and exports

| Command | What it does |
|---|---|
| `/testgunfx` | Plays the ringing, a far whizz and a close whizz once |

Change or remove it with `Config.TestCommand`.

### Hearing protection

For earmuffs, headsets or similar items. While protected, ringing is switched off.

```lua
exports['jd_gunfx']:setHearingProtection(true)   -- on
exports['jd_gunfx']:setHearingProtection(false)  -- off
local protected = exports['jd_gunfx']:hasHearingProtection()
```

---

## Troubleshooting

| Problem | Try this |
|---|---|
| No sound at all | Check the file name in `config.lua` matches the file in `html/sounds/` |
| Ringing too quiet or too loud | Change `Ringing.volume` or the weapon's `volume` |
| Ringing cuts off or glitches | Set `Ringing.loop = false` if your mp3 is a longer clip |
| No whizz while you are shooting | Set `NearMiss.ignoreOwnBullets = false` |
| Whizz triggers too easily or not enough | Change `NearMiss.outerRadius` |
| Shake is too strong | Lower `NearMiss.shake.far` and `close` |

---

Made by JD Development & Designs.
