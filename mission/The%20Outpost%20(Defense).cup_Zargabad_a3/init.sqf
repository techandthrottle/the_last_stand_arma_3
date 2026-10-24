// Mission init — gameplay logic lives in @LastStand (fn_gameInit).
// This file is for mission-specific intro/support scripting only.

// Helicopter insertion (server-side; the script exits on clients).
[] execVM "heliInsert.sqf";

// Roaming horde ambushes at ambush_* markers during the travel phase (server-side).
[] execVM "routeAmbush.sqf";

// Auto-rearm friendly AI defenders at the base (static MGs & infantry) (server-side).
[] execVM "baseRearm.sqf";

// Narrative beats: drop-off briefing -> travel briefing -> arrival cinematic (per client).
[] execVM "missionFlow.sqf";
