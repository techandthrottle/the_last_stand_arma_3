# Last Stand — Zombie Base-Defense (Arma 3)

A map-independent Arma 3 **co-op zombie base-defense** gamemode, packaged as the addon
`@LastStand`. A military squad **inserts by helicopter**, **convoys to an outpost** through roaming
zombie **horde ambushes**, then makes a **last stand** against escalating waves of WebKnight infected.
Features **staged cinematics + radio briefings**, a **fixed loadout** with an **ammo / grenade /
medical resupply** crate, **auto-rearmed AI defenders**, tiered zombie waves (walkers →
runners/specials → bosses), and a **destructible base objective**.

All gameplay logic lives in the **addon**, so any mission on any terrain works by placing a few
named objects — no per-map scripting. A reference mission ships on **CUP Zargabad**.

---

## Requirements

| Mod | Why |
|-----|-----|
| **Arma 3** 2.10+ | base engine, `BIS_fnc_playVideo` |
| **CBA_A3** | in-game settings menu (`requiredAddons` depends on `cba_main`) |
| **WebKnight's Zombies and Creatures** | the zombie unit classes |
| **CUP Terrains** (Core + Maps) | the reference mission's map (Zargabad) |
| ACE3 | *optional* — recommended for medical/gameplay; the mod itself doesn't require it |

---

## Repository layout

```
ArmaAIScreamConcert/
├── last_stand/                 ← addon SOURCE (packed into last_stand.pbo)
│   ├── $PBOPREFIX$                (= last_stand)
│   ├── config.cpp                CfgPatches, CBA preInit hook, CfgFunctions (gameInit), CfgSounds
│   ├── XEH_preInit.sqf           registers the CBA "Zombie Defense" settings
│   ├── functions/fn_gameInit.sqf ★ the whole gamemode (postInit, runs everywhere)
│   └── data/
│       ├── video/  intro.ogv     (arrival cinematic, keeps its own audio)
│       └── audio/  briefing.ogg  (legacy; unused by the current flow)
├── @LastStand/                 ← built mod players load (~7 MB)
│   ├── mod.cpp
│   └── addons/last_stand.pbo
└── dist/                       ← ready-to-ship bundle (mod + mission .pbo + HOW-TO-INSTALL.txt)
```

**Reference mission** (CUP Zargabad, MP): `…\Ragequit\mpmissions\The Outpost (Defense).cup_Zargabad_a3\`

| File | Role |
|------|------|
| `mission.sqm` | placed objects (base, heli, units, markers) |
| `init.sqf` | runs the four mission scripts below |
| `heliInsert.sqf` | SERVER: helicopter insertion (flies in, lands, unloads) |
| `routeAmbush.sqf` | SERVER: horde ambushes at `ambush_*` markers during travel |
| `baseRearm.sqf` | SERVER: auto-rearm AI defenders near the base |
| `missionFlow.sqf` | CLIENT: staged cinematics + radio briefings |
| `description.ext` | respawn config (`respawn_west`, BLUFOR) + briefing `CfgSounds` |
| `dropoff.ogv`, `travel.ogv` | mission cinematics (insertion, convoy) |
| `brief_dropoff.ogg`, `brief_travel.ogg` | radio voice briefings |

---

## Quick start — set up a mission on ANY map

1. Launch Arma with `@LastStand` + **CBA** + **WebKnight** (+ map mods, e.g. CUP Terrains).
2. In Eden, place and name:

   | Place | Name it | Purpose |
   |-------|---------|---------|
   | An object (flag, tent, HQ…) | **`base_center`** | the base to defend (zombies target it) |
   | A **marker** | **`respawn_west`** | BLUFOR respawn point (put it at the outpost) |
   | **Playable BLUFOR units** | — | the squad — **set their default loadout + medical gear here; it is fixed in-game** |
   | *(optional)* a supply box | **`resupply_crate`** | the exact resupply point (else one spawns near `base_center`) |

3. *(Travel scenario — optional)* also place:

   | Place | Name it | Purpose |
   |-------|---------|---------|
   | Helicopter + crew | **`heli1`** | insertion (put the players **inside** as cargo) |
   | Helipad (`Land_HelipadEmpty_F`) | **`lz_pad`** | landing zone (near the route start) |
   | Marker (optional) | **`heli_exit`** | where the heli flies off to |
   | Markers along the route | **`ambush_1`, `ambush_2`, …** | each spawns a horde when a player nears it |
   | Transport vehicles (M1025/M1152…) + props | — | the convoy + roadblocks/chokepoints |

   …and copy the mission-side files (`init.sqf`, `heliInsert.sqf`, `routeAmbush.sqf`,
   `baseRearm.sqf`, `missionFlow.sqf`, `description.ext`, and the `.ogv`/`.ogg` media) into the
   mission folder.

4. Tune everything in-game: **ESC → Options → Addon Options → "Zombie Defense"** (CBA).
5. Start the siege via the **"Secure the Outpost – Begin Defense"** action on `base_center`
   (or the admin scroll **START Base Defense**, or CBA **Auto-Start**).

The cinematics, briefings, scroll menu, and resupply are **gated** on `base_center` existing, so the
mod stays dormant on any mission without a base.

---

## In-game flow (travel scenario)

```
Mission start      → 🎬 dropoff.ogv (heli ride)  → 🎙️ brief_dropoff
   ↓ heli lands & unloads, convoy out
~120 m from the LZ → 🎙️ brief_travel
   ↓ drive to the outpost (through ambushes)
Near the outpost   → 🎬 travel.ogv (convoy) → 🎬 intro.ogv (arrival)
   ↓ "Secure the Outpost"
Siege              → escalating waves rally the base at full aggression
Win / Lose         → survive all waves = VICTORY · all defenders dead OR base HP 0 = DEFEAT
```

Cinematics are fullscreen and **skippable (press any key)**; they carry their own audio, so the voice
briefings play in the gaps between them. AI defenders are auto-rearmed near the base; players resupply
at the crate during the breather between waves.

---

## Loadout & resupply

- **Fixed loadout:** whatever you give the playable units in Eden (including **medical gear**) is
  captured at mission start and **re-applied on every respawn**. There is no arsenal to change it.
- **Resupply crate** — a **"Resupply – Ammo & Grenades"** scroll action that restores **magazines,
  grenades, and medical items** to your starting loadout (weapons/uniform untouched). Toggle with CBA
  **"Resupply Crate at Base"**.
- **Crate placement** (priority): 1) an object you place named **`resupply_crate`** (exact control —
  recommended), else 2) a marker named **`resupply`**, else 3) it spawns near `base_center`, snapped
  flat to the ground.
- **AI defenders auto-rearm** near the base via `baseRearm.sqf` (static MGs refill to full; infantry
  mags top up). Put **medical items in the Eden loadout** or the crate has nothing medical to restore.

---

## Mission-side scripts & tunables

Plain mission `.sqf` — edit and re-host, **no repack**.

**`missionFlow.sqf`** — cinematic/briefing beats:
| Variable | Default | Meaning |
|---|---|---|
| travel-briefing distance | 120 | metres from the LZ before `brief_travel` plays |
| outpost cinematic distance | 90 | metres from `base_center` for the arrival cinematics |

**`routeAmbush.sqf`** — horde ambushes at `ambush_*` markers (each fires once; stops at siege start):
| Variable | Default | Meaning |
|---|---|---|
| `_hordeSize` | 14 | zombies per ambush |
| `_triggerDist` | 180 | spawn when a player gets this close to the marker (m) |
| `_spread` | 30 | spawn spread around the marker (m) |
| `_specialChance` | 0.4 | chance the horde includes specials |

**`heliInsert.sqf`** — insertion (needs `heli1`, `lz_pad`, optional `heli_exit`):
| Variable | Default | Meaning |
|---|---|---|
| `_introHold` | 14 | seconds the chopper holds before its approach |

**`baseRearm.sqf`** — AI auto-rearm:
| Variable | Default | Meaning |
|---|---|---|
| `_range` | 90 | rearm friendly AI within this of the base (m) |
| `_interval` | 15 | seconds between rearm passes |

> Ambush spawner: `[pos, count, radius, withSpecials] call CONCERT_fnc_ambush` — callable from any
> trigger's *On Activation* too.

---

## CBA settings ("Zombie Defense" category)

| Setting (CBA) → variable | Default | Meaning |
|---|---|---|
| Number of Waves · `CONCERT_defWaves` | 10 | waves to win |
| Wave 1 Zombie Count · `CONCERT_defBaseCount` | 6 | base size of wave 1 |
| Zombies Added Per Wave · `CONCERT_defGrowth` | 4 | linear growth per wave |
| Horde Scaling Per Extra Player (%) · `CONCERT_defPerPlayerPct` | 25 | +% horde per extra living defender |
| Max Zombies Per Wave · `CONCERT_defMaxPerWave` | 120 | perf cap |
| Seconds Between Waves · `CONCERT_defIntermission` | 20 | resupply window |
| Gear-Up Time Before Wave 1 · `CONCERT_defPrepTime` | 45 | prep seconds |
| Zombie Spawn Distance (m) · `CONCERT_defSpawnMax` | 250 | spawn ring (min = 60% of max) |
| Runner Wave Interval · `CONCERT_defRunnerEvery` | 3 | every Nth wave mixes runners (0 = never) |
| Special Wave Interval · `CONCERT_defBloaterEvery` | 3 | every Nth wave mixes specials |
| Boss Wave Interval · `CONCERT_defBossEvery` | 5 | every Nth wave adds a boss |
| Auto-Start Waves · `CONCERT_defAutoStart` | off | begin at start (keep **off** for the interact scenario) |
| Resupply Crate at Base · `CONCERT_arsenalEnabled` | on | ammo/grenade/medical resupply crate |
| Base HP · `CONCERT_baseHP` | 1500 | zombies at the base drain this; 0 = survive-only |

Wave size: `count = round((base + (wave-1)·growth) · (1 + (players-1)·perPlayer%))`, capped at the max.

---

## Zombie roster & wave composition (WebKnight, OPFOR/CSAT)

Set in `fn_gameInit.sqf` (editing these = a PBO repack). Invalid classes are auto-skipped and logged
(`[CONCERT] zombie tiers valid -> …`).

| Tier · variable | Classes |
|---|---|
| Basic · `CONCERT_zWalker` | `Zombie_O_Walker_CSAT`, `Zombie_O_Shambler_CSAT`, `Zombie_O_Crawler_CSAT` |
| Runner · `CONCERT_zRunner` | `Zombie_O_RunnerAngry_CSAT` |
| Specials · `CONCERT_zBloater` | Boomer, Leaper 1/2, Screamer, Shooter (`Zombie_Special_OPFOR_*`, `Zombie_O_Shooter_CSAT`) |
| Bosses · `CONCERT_zBoss` | Smasher, Smasher Hellspawn/Spewer, Goliath, Corrupted (`WBK_SpecialZombie_*`, `WBK_Goliaph_3`) |

When the siege starts, WebKnight's hunt-leash (`WBK_Zombies_*MoveDistanceLimit`) is raised to 4000 m so
zombies rally from anywhere; the squad spawns `COMBAT`/`RED`/full-speed and makes for the base.

---

## Key names, variables & functions

**Eden objects / markers**
- `base_center` — the base to defend (fallback name: `concert_screen_1`).
- `respawn_west` — BLUFOR respawn marker.
- `resupply_crate` *(optional)* — exact resupply crate spot.
- `heli1`, `lz_pad`, `heli_exit` — helicopter insertion.
- `ambush_1`, `ambush_2`, … — horde-ambush spawn points.

**Globals**
- `CONCERT_defRunning` — is a siege active (travel/ambush scripts stop when true).
- `CONCERT_zombieSide` — side zombies spawn on (`east`); forced hostile to `west`.

**Callable functions** (scroll action, triggers, debug console)
- `[] call CONCERT_fnc_defenseStart` / `CONCERT_fnc_defenseStop` / `CONCERT_fnc_defenseToggle`
- `[pos, count, radius, withSpecials] call CONCERT_fnc_ambush`
- `[] call CONCERT_fnc_playIntro` — the arrival cinematic
- `call CONCERT_fnc_resupply` — top up the local player's ammo/grenades/medical
- Scroll menu: **Secure the Outpost** (on `base_center`), **Resupply** (on the crate),
  admin **START/STOP Base Defense**.

> The internal script namespace is `CONCERT_*` for historical reasons (the mod began as a concert
> addon); it's invisible to players and kept stable so missions don't break.

---

## Cinematics & briefings

- **Arrival cinematic** `intro.ogv` — lives in the **addon** (`\last_stand\data\video\`), played by
  `CONCERT_fnc_playIntro`. Reliable path.
- **`dropoff.ogv` / `travel.ogv`** — live in the **mission folder**, played by `missionFlow.sqf` via
  `BIS_fnc_playVideo` (mission-relative). If one shows black/skips instantly, move it into the addon's
  `data\video\` and reference it by `\last_stand\…` path, then repack.
- **`brief_dropoff.ogg` / `brief_travel.ogg`** — mission `CfgSounds` (in `description.ext`).
- Encode video (keep audio): `ffmpeg -i in.mp4 -c:v libtheora -q:v 6 -c:a libvorbis -q:a 5 -r 30 out.ogv`
- Encode voice **loud** (TTS is quiet): `ffmpeg -i in.wav -vn -ac 2 -af "loudnorm=I=-11:TP=-1.0:LRA=11" -c:a libvorbis -q:a 5 out.ogg`

---

## Building / repacking

Addon Builder's binarize step fails here (CfgConvert needs the project drive), so PBOs are built with
a small Python packer that writes a valid uncompressed PBO (properties header → file headers → data →
`0x00` + SHA1 trailer):
- **Addon PBO** (`@LastStand\addons\last_stand.pbo`) — rebuild after any change to the addon
  `config.cpp`, `fn_gameInit.sqf`, `XEH_preInit.sqf`, or `data/`. Close **`arma3_x64`** first (the
  launcher alone doesn't lock it), then **fully restart Arma** (PBOs load only at startup).
- **Mission PBO** — pack the mission folder (same packer). Mission-side `.sqf` edits only need a
  re-host; repacking is just for distribution.

---

## Distributing it to others

Ship the **mod** (`@LastStand`) + the **mission** (`.pbo`). Players also load **CBA**, **WebKnight's
Zombies**, **CUP Terrains** (for Zargabad), optionally **ACE** — you can't bundle others' mods, so
list them as required. A ready `dist\` bundle (mod + mission `.pbo` + `HOW-TO-INSTALL.txt`, ~18 MB) is
in the repo — **zip it and send**.

1. **Steam Workshop** (public, auto-updates): Arma 3 Tools → **Arma 3 Publisher** → point at
   `@LastStand`, set title/tags, list required mods → upload. Players Subscribe.
2. **Manual** (private): zip `@LastStand` (local mod in the Launcher) + send the mission `.pbo` for
   their `MPMissions\`.
3. **Signing** (servers with `verifySignatures`): Arma 3 Tools → **DSCreateKey** then **DSSignFile**
   the private key against `last_stand.pbo`; put the `.bikey` in the server's `keys\`.

---

## Notes

- Playable units must be **BLUFOR (west)**. WebKnight zombies skip *same-side* targets, so the
  survivors must be a different side than the zombies; the mod also `setFriend`s the zombie + civilian
  sides hostile to west so the ranged "Shooter" zombie engages.
- Keep CBA **Auto-Start Waves OFF** for the travel scenario, so the siege only begins when players
  reach and **interact with** the outpost.
- The old concert feature and its media were removed; `briefing.ogg` in the addon is a harmless
  leftover and can be deleted on the next repack.
