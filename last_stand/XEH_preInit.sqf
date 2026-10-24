// ================================================================
//  CBA Settings for the Zombie Base-Defense gamemode.
//  Map-independent: configure in-game at
//    ESC -> Options -> Addon Options -> "Zombie Defense".
//  Each setting creates the matching CONCERT_* global the logic reads.
//  isGlobal = true  -> the server's value is forced to all clients.
// ================================================================
#define CAT "Zombie Defense"

["CONCERT_defWaves",        "SLIDER",   ["Number of Waves", "Survive this many waves to win."], CAT, [1, 50, 10, 0],    true] call CBA_Settings_fnc_init;
["CONCERT_defBaseCount",    "SLIDER",   ["Wave 1 Zombie Count", "Horde size of the first wave."], CAT, [1, 60, 6, 0],   true] call CBA_Settings_fnc_init;
["CONCERT_defGrowth",       "SLIDER",   ["Zombies Added Per Wave", ""], CAT, [0, 40, 4, 0],     true] call CBA_Settings_fnc_init;
["CONCERT_defPerPlayerPct", "SLIDER",   ["Horde Scaling Per Extra Player (%)", "More players = bigger horde."], CAT, [0, 200, 25, 0], true] call CBA_Settings_fnc_init;
["CONCERT_defMaxPerWave",   "SLIDER",   ["Max Zombies Per Wave (perf cap)", ""], CAT, [10, 300, 120, 0], true] call CBA_Settings_fnc_init;
["CONCERT_defIntermission", "SLIDER",   ["Seconds Between Waves (resupply window)", ""], CAT, [0, 120, 20, 0], true] call CBA_Settings_fnc_init;
["CONCERT_defPrepTime",     "SLIDER",   ["Gear-Up Time Before Wave 1 (s)", ""], CAT, [0, 300, 45, 0], true] call CBA_Settings_fnc_init;
["CONCERT_defSpawnMax",     "SLIDER",   ["Zombie Spawn Distance (m)", ""], CAT, [80, 500, 250, 0], true] call CBA_Settings_fnc_init;
["CONCERT_defRunnerEvery",  "SLIDER",   ["Runner Wave Interval (0 = never)", "Every Nth wave mixes in runners."], CAT, [0, 10, 3, 0], true] call CBA_Settings_fnc_init;
["CONCERT_defBloaterEvery", "SLIDER",   ["Special Wave Interval (0 = never)", "Every Nth wave mixes in specials."], CAT, [0, 10, 3, 0], true] call CBA_Settings_fnc_init;
["CONCERT_defBossEvery",    "SLIDER",   ["Boss Wave Interval (0 = never)", "Every Nth wave adds a boss."], CAT, [0, 20, 5, 0], true] call CBA_Settings_fnc_init;
["CONCERT_defAutoStart",    "CHECKBOX", ["Auto-Start Waves at Mission Start", ""], CAT, [false], true] call CBA_Settings_fnc_init;
["CONCERT_arsenalEnabled",  "CHECKBOX", ["Resupply Crate at Base", "Ammo & grenade resupply crate next to the base (loadouts are fixed)."], CAT, [true], true] call CBA_Settings_fnc_init;
["CONCERT_baseHP",          "SLIDER",   ["Base HP (0 = survive-only)", "Zombies that reach the base drain this; at 0 the base is destroyed and you lose. Set 0 to disable base damage."], CAT, [0, 10000, 1500, 0], true] call CBA_Settings_fnc_init;
