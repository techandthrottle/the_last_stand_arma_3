// ================================================================
//  CONCERT_fnc_gameInit  (postInit, runs on server AND every client)
//  Map-independent Zombie Base-Defense ("Last Stand").
//  Any mission on any map just needs:
//    - an object named  base_center   (the base to defend)
//    - a marker named    respawn_west  (BLUFOR respawn)
//    - playable BLUFOR units
//  Tunables come from CBA Settings (ESC > Options > Addon Options >
//  "Zombie Defense"); fallback defaults apply if CBA is absent.
// ================================================================

// ---- Zombie roster (WebKnight, OPFOR/CSAT) ----
CONCERT_zombieSide = east;
CONCERT_zWalker  = ["Zombie_O_Walker_CSAT","Zombie_O_Shambler_CSAT","Zombie_O_Crawler_CSAT"];  // basic
CONCERT_zRunner  = ["Zombie_O_RunnerAngry_CSAT"];                                               // fast sprinters
CONCERT_zBloater = [                                                                            // specials (mid-tier)
    "Zombie_Special_OPFOR_Boomer",
    "Zombie_Special_OPFOR_Leaper_1",
    "Zombie_Special_OPFOR_Leaper_2",
    "Zombie_Special_OPFOR_Screamer",
    "Zombie_O_Shooter_CSAT"
];
CONCERT_zBoss    = [                                                                            // bosses (heavy)
    "WBK_SpecialZombie_Smasher_3",
    "WBK_SpecialZombie_Smasher_Hellbeast_3",
    "WBK_SpecialZombie_Smasher_Acid_3",
    "WBK_Goliaph_3",
    "WBK_SpecialZombie_Corrupted_3"
];
CONCERT_defRunnerPct  = 0.30;
CONCERT_defBloaterPct = 0.20;
CONCERT_defBossCount  = 1;
CONCERT_baseDrain       = 4;    // base HP drained per zombie per second while at the base
CONCERT_baseDamageRange = 12;   // metres a zombie must be within to damage the base
CONCERT_arsenalOffset   = [5,2,0];

// ---- CBA-setting fallbacks (used only if CBA didn't set them) ----
if (isNil "CONCERT_defWaves")        then { CONCERT_defWaves = 10; };
if (isNil "CONCERT_defBaseCount")    then { CONCERT_defBaseCount = 6; };
if (isNil "CONCERT_defGrowth")       then { CONCERT_defGrowth = 4; };
if (isNil "CONCERT_defPerPlayerPct") then { CONCERT_defPerPlayerPct = 25; };
if (isNil "CONCERT_defMaxPerWave")   then { CONCERT_defMaxPerWave = 120; };
if (isNil "CONCERT_defIntermission") then { CONCERT_defIntermission = 20; };
if (isNil "CONCERT_defPrepTime")     then { CONCERT_defPrepTime = 45; };
if (isNil "CONCERT_defSpawnMax")     then { CONCERT_defSpawnMax = 250; };
if (isNil "CONCERT_defRunnerEvery")  then { CONCERT_defRunnerEvery = 3; };
if (isNil "CONCERT_defBloaterEvery") then { CONCERT_defBloaterEvery = 3; };
if (isNil "CONCERT_defBossEvery")    then { CONCERT_defBossEvery = 5; };
if (isNil "CONCERT_defAutoStart")    then { CONCERT_defAutoStart = false; };
if (isNil "CONCERT_arsenalEnabled")  then { CONCERT_arsenalEnabled = true; };
if (isNil "CONCERT_baseHP")          then { CONCERT_baseHP = 1500; };

// ---- State ----
if (isNil "CONCERT_defRunning") then { CONCERT_defRunning = false; };
if (isNil "CONCERT_defGrp")     then { CONCERT_defGrp = grpNull; };

// The base to defend. Name an object "base_center" in Eden (falls back to "concert_screen_1").
CONCERT_fnc_stage = {
    private _b = missionNamespace getVariable ["base_center", objNull];
    if (isNull _b) then { _b = missionNamespace getVariable ["concert_screen_1", objNull]; };
    _b
};

diag_log format ["[CONCERT] gameInit RUNNING  isServer=%1 hasInterface=%2", isServer, hasInterface];

CONCERT_fnc_announce    = { params ["_msg"]; [_msg] remoteExec ["systemChat", 0]; [[_msg, "PLAIN DOWN"]] remoteExec ["titleText", 0]; };
CONCERT_fnc_hud         = { params ["_txt"]; [_txt] remoteExec ["hintSilent", 0]; };
CONCERT_fnc_livePlayers = { { alive _x } count (allUnits select { isPlayer _x }) };

CONCERT_fnc_defenseStop = {
    if (!isServer) exitWith { [] remoteExec ["CONCERT_fnc_defenseStop", 2]; };
    CONCERT_defRunning = false;
    if (!isNull CONCERT_defGrp) then { { deleteVehicle _x; } forEach (units CONCERT_defGrp); };
    [""] call CONCERT_fnc_hud;
};

// Validate tiers + build per-wave composition
CONCERT_fnc_validClasses = { _this select { isClass (configFile >> "CfgVehicles" >> _x) } };
CONCERT_fnc_revalidate = {
    CONCERT_zWalkerValid  = CONCERT_zWalker  call CONCERT_fnc_validClasses;
    CONCERT_zRunnerValid  = CONCERT_zRunner  call CONCERT_fnc_validClasses;
    CONCERT_zBloaterValid = CONCERT_zBloater call CONCERT_fnc_validClasses;
    CONCERT_zBossValid    = CONCERT_zBoss    call CONCERT_fnc_validClasses;
    CONCERT_zombieValid   = CONCERT_zWalkerValid + CONCERT_zRunnerValid + CONCERT_zBloaterValid + CONCERT_zBossValid;
    diag_log format ["[CONCERT] zombie tiers valid -> walkers=%1 runners=%2 specials=%3 bosses=%4", CONCERT_zWalkerValid, CONCERT_zRunnerValid, CONCERT_zBloaterValid, CONCERT_zBossValid];
};
CONCERT_fnc_waveClasses = {
    params ["_w", "_count"];
    private _walkPool = if (count CONCERT_zWalkerValid > 0) then { CONCERT_zWalkerValid } else { CONCERT_zombieValid };
    private _bossN = 0;
    if (CONCERT_defBossEvery > 0 && { (_w mod CONCERT_defBossEvery) == 0 } && { count CONCERT_zBossValid > 0 }) then { _bossN = CONCERT_defBossCount min _count; };
    private _rest = _count - _bossN;
    private _runN = 0; private _bloN = 0;
    if (CONCERT_defRunnerEvery > 0 && { (_w mod CONCERT_defRunnerEvery) == 0 } && { count CONCERT_zRunnerValid > 0 }) then { _runN = round (_rest * CONCERT_defRunnerPct); };
    if (CONCERT_defBloaterEvery > 0 && { (_w mod CONCERT_defBloaterEvery) == 0 } && { count CONCERT_zBloaterValid > 0 }) then { _bloN = round (_rest * CONCERT_defBloaterPct); };
    private _walkN = (_rest - _runN - _bloN) max 0;
    private _out = [];
    for "_i" from 1 to _walkN do { _out pushBack (selectRandom _walkPool); };
    for "_i" from 1 to _runN  do { _out pushBack (selectRandom CONCERT_zRunnerValid); };
    for "_i" from 1 to _bloN  do { _out pushBack (selectRandom CONCERT_zBloaterValid); };
    for "_i" from 1 to _bossN do { _out pushBack (selectRandom CONCERT_zBossValid); };
    _out call BIS_fnc_arrayShuffle
};

CONCERT_fnc_defenseStart = {
    if (!isServer) exitWith { [] remoteExec ["CONCERT_fnc_defenseStart", 2]; };
    if (CONCERT_defRunning) exitWith {};
    call CONCERT_fnc_revalidate;
    if (count CONCERT_zombieValid == 0) exitWith { ["Defense: no valid zombie class set."] call CONCERT_fnc_announce; };
    if (isNull (call CONCERT_fnc_stage)) exitWith { ["Defense: no base (base_center) found."] call CONCERT_fnc_announce; };
    CONCERT_defRunning = true;

    // Full aggression: lift WebKnight's hunt leash so zombies rally from any range.
    WBK_Zombies_MoveDistanceLimit                 = 4000;
    WBK_Zombies_SpecialInfected_MoveDistanceLimit = 4000;
    WBK_Zombies_Smasher_MoveDistanceLimit         = 4000;
    WBK_Zombies_Goliath_MoveDistanceLimit         = 4000;
    [] spawn {
        private _base = call CONCERT_fnc_stage;
        private _dmax = CONCERT_defSpawnMax;
        private _dmin = (_dmax * 0.6) max 60;
        if (CONCERT_defPrepTime > 0) then {
            [format ["DEFENSE STARTING - gear up at the arsenal! First wave in %1s.", CONCERT_defPrepTime]] call CONCERT_fnc_announce;
            sleep CONCERT_defPrepTime;
        };
        CONCERT_baseCurHP    = CONCERT_baseHP;
        CONCERT_baseDestroyed = false;
        for "_w" from 1 to CONCERT_defWaves do {
            if (!CONCERT_defRunning) exitWith {};
            private _pc    = (call CONCERT_fnc_livePlayers) max 1;
            private _count = round ((CONCERT_defBaseCount + ((_w - 1) * CONCERT_defGrowth)) * (1 + ((_pc - 1) * (CONCERT_defPerPlayerPct / 100))));
            _count = _count min CONCERT_defMaxPerWave;
            private _isBoss = (CONCERT_defBossEvery > 0 && { (_w mod CONCERT_defBossEvery) == 0 } && { count CONCERT_zBossValid > 0 });
            private _msg = format ["WAVE %1 / %2  -  %3 incoming!  (%4 defenders)", _w, CONCERT_defWaves, _count, _pc];
            if (_isBoss) then { _msg = _msg + "   >>> BOSS WAVE <<<"; };
            [_msg] call CONCERT_fnc_announce;

            private _classes = [_w, _count] call CONCERT_fnc_waveClasses;
            CONCERT_defGrp = createGroup CONCERT_zombieSide;
            {
                if (!CONCERT_defRunning) exitWith {};
                private _ang = random 360;
                private _d   = _dmin + random (_dmax - _dmin);
                private _b   = getPosATL _base;
                private _sp  = [(_b select 0) + sin _ang * _d, (_b select 1) + cos _ang * _d, 0];
                CONCERT_defGrp createUnit [_x, _sp, [], 10, "NONE"];
                if (_forEachIndex mod 4 == 3) then { sleep 0.4; };
            } forEach _classes;
            CONCERT_defGrp setBehaviour "COMBAT";
            CONCERT_defGrp setCombatMode "RED";
            CONCERT_defGrp setSpeedMode "FULL";
            { if (alive _x) then { _x doMove (getPosATL _base); _x setSpeedMode "FULL"; }; } forEach (units CONCERT_defGrp);
            diag_log format ["[CONCERT] Defense wave %1 spawned %2 (boss=%3)", _w, count _classes, _isBoss];

            while { CONCERT_defRunning && ({ alive _x } count (units CONCERT_defGrp) > 0) } do {
                { if (alive _x) then { _x doMove (getPosATL _base); }; } forEach (units CONCERT_defGrp);
                private _left = { alive _x } count (units CONCERT_defGrp);

                private _baseStr = "";
                if (CONCERT_baseHP > 0) then {
                    private _atBase = { alive _x && { _x distance _base < CONCERT_baseDamageRange } } count (units CONCERT_defGrp);
                    if (_atBase > 0) then {
                        CONCERT_baseCurHP = (CONCERT_baseCurHP - (_atBase * CONCERT_baseDrain * 2)) max 0;
                    };
                    _baseStr = format ["    Base HP: %1", round CONCERT_baseCurHP];
                    if (CONCERT_baseCurHP <= 0) then { CONCERT_baseDestroyed = true; CONCERT_defRunning = false; };
                };

                [format ["Wave %1/%2    Zombies left: %3%4", _w, CONCERT_defWaves, _left, _baseStr]] call CONCERT_fnc_hud;
                if ((call CONCERT_fnc_livePlayers) == 0) then {
                    sleep 8;
                    if ((call CONCERT_fnc_livePlayers) == 0) then { CONCERT_defRunning = false; };
                };
                sleep 2;
            };
            if (!CONCERT_defRunning) exitWith {};
            if (_w < CONCERT_defWaves) then {
                [format ["Wave %1 cleared!  RESUPPLY at the crate - next wave in %2s...", _w, CONCERT_defIntermission]] call CONCERT_fnc_announce;
                sleep CONCERT_defIntermission;
            };
        };
        [""] call CONCERT_fnc_hud;
        if (CONCERT_baseDestroyed) then {
            ["DEFEAT - the base has been overrun and destroyed."] call CONCERT_fnc_announce;
        } else {
            if ((call CONCERT_fnc_livePlayers) == 0) then {
                ["DEFEAT - all defenders are down."] call CONCERT_fnc_announce;
            } else {
                if (CONCERT_defRunning) then { [format ["VICTORY!  You held the outpost through all %1 waves!", CONCERT_defWaves]] call CONCERT_fnc_announce; };
            };
        };
        CONCERT_defRunning = false;
    };
};
CONCERT_fnc_defenseToggle = { if (CONCERT_defRunning) then { [] call CONCERT_fnc_defenseStop; } else { [] call CONCERT_fnc_defenseStart; }; };

// Spawn an ambush pack (use from a trigger's On Activation or routeAmbush.sqf):
//   [getPosATL thisTrigger, 8] call CONCERT_fnc_ambush;
//   [getPosATL thisTrigger, 6, 25, true] call CONCERT_fnc_ambush;  // include specials
CONCERT_fnc_ambush = {
    if (!isServer) exitWith { _this remoteExec ["CONCERT_fnc_ambush", 2]; };
    params ["_pos", ["_n", 6], ["_radius", 20], ["_withSpecials", false]];
    private _pool = CONCERT_zWalkerValid + CONCERT_zRunnerValid;
    if (_withSpecials) then { _pool = _pool + CONCERT_zBloaterValid; };
    if (_pool isEqualTo []) then { _pool = CONCERT_zombieValid; };
    if (_pool isEqualTo []) exitWith { grpNull };
    private _g = createGroup CONCERT_zombieSide;
    for "_i" from 1 to _n do {
        _g createUnit [selectRandom _pool, _pos getPos [random _radius, random 360], [], 0, "NONE"];
    };
    _g
};

// Resupply crate at the base — refills ammo + grenades to each player's fixed loadout.
CONCERT_fnc_setupArsenal = {
    if (!isServer) exitWith {};
    if (!CONCERT_arsenalEnabled) exitWith {};
    waitUntil { !isNull (call CONCERT_fnc_stage) };
    private _base = call CONCERT_fnc_stage;
    // Placement priority: 1) object named "resupply_crate"  2) marker "resupply"  3) base offset.
    private _box = missionNamespace getVariable ["resupply_crate", objNull];
    if (isNull _box) then {
        private _pos = if (markerType "resupply" != "") then { getMarkerPos "resupply" } else { _base modelToWorld CONCERT_arsenalOffset };
        _box = "Box_NATO_Support_F" createVehicle [0,0,0];
        _box setPosATL [_pos select 0, _pos select 1, 0];
        _box setVectorUp [0,0,1];
        _box setDir (getDir _base);
    };
    clearItemCargoGlobal _box; clearWeaponCargoGlobal _box; clearMagazineCargoGlobal _box; clearBackpackCargoGlobal _box;
    _box setVariable ["CONCERT_resupply", true, true];
    CONCERT_arsenalBox = _box;
    [_box] remoteExec ["CONCERT_fnc_addResupplyAction", 0, true];
    diag_log format ["[CONCERT] Resupply crate ready at %1.", getPosATL _box];
};
CONCERT_fnc_addResupplyAction = {
    params ["_box"];
    if (!hasInterface) exitWith {};
    _box addAction [
        "<t color='#66ff66'>Resupply  -  Ammo & Grenades</t>",
        { call CONCERT_fnc_resupply; },
        nil, 1.5, true, false, "", "alive player", 5
    ];
};
// Detect medical items by classname keyword (ACE + vanilla).
CONCERT_medKeywords = ["bandage","dressing","tourniquet","morphine","epinephrine","adenosine","atropine","splint","bloodiv","saline","plasma","quikclot","packing","elastic","aidkit","medikit","firstaidkit","surgicalkit","painkiller"];
CONCERT_fnc_isMed = { private _c = toLower _this; (CONCERT_medKeywords findIf { _c find _x > -1 } > -1) };

CONCERT_fnc_resupply = {
    if (!hasInterface) exitWith {};
    private _u = player;
    private _mags = uiNamespace getVariable ["CONCERT_defMags", []];
    if (_mags isEqualTo []) exitWith { systemChat "Resupply unavailable (no default loadout stored)."; };

    // --- ammo + grenades: restore magazines to the default set ---
    { _u removeMagazines _x } forEach (magazines _u);
    { _u addMagazine _x } forEach _mags;
    reload _u;

    // --- medical: top each medical item back up to the default count ---
    private _medDef = (uiNamespace getVariable ["CONCERT_defItems", []]) select { _x call CONCERT_fnc_isMed };
    if (count _medDef > 0) then {
        private _cur = items _u;
        {
            private _it = _x;
            private _need = ({ _x == _it } count _medDef) - ({ _x == _it } count _cur);
            if (_need > 0) then { for "_i" from 1 to _need do { _u addItem _it; }; };
        } forEach (_medDef arrayIntersect _medDef);
    };

    systemChat "Resupplied: ammo, grenades & medical restored.";
};

// ----------------------------------------------------------------
//  FIXED LOADOUT: capture the Eden default once, re-apply it on respawn.
// ----------------------------------------------------------------
if (hasInterface) then {
    [] spawn {
        waitUntil { !isNull player && { alive player } };
        if (isNull (call CONCERT_fnc_stage)) exitWith {};
        sleep 1;   // let the editor loadout finish applying
        if (isNil { uiNamespace getVariable "CONCERT_defLoadout" }) then {
            uiNamespace setVariable ["CONCERT_defLoadout", getUnitLoadout player];
            uiNamespace setVariable ["CONCERT_defMags", magazines player];
            uiNamespace setVariable ["CONCERT_defItems", items player];   // for medical top-up
        };
        player addEventHandler ["Respawn", {
            params ["_unit"];
            private _ld = uiNamespace getVariable ["CONCERT_defLoadout", []];
            if !(_ld isEqualTo []) then { _unit setUnitLoadout _ld; };
        }];
    };
};

// ----------------------------------------------------------------
//  PLAYER ACTIONS (admin scroll menu) — defense control only.
// ----------------------------------------------------------------
if (hasInterface) then {
    [] spawn {
        waitUntil { !isNull player && { player == player } };
        if (isNull (call CONCERT_fnc_stage)) exitWith {};
        private _admin = "(call BIS_fnc_admin > 0) || !isMultiplayer";
        player addAction ["<t color='#ff3b3b'>START Base Defense</t>", { [] call CONCERT_fnc_defenseStart; }, nil, 7, false, true, "", "(" + _admin + ") && !CONCERT_defRunning", 6];
        player addAction ["<t color='#ffaa00'>STOP Base Defense</t>",  { [] call CONCERT_fnc_defenseStop;  }, nil, 7, false, true, "", "(" + _admin + ") && CONCERT_defRunning", 6];
    };
};

// ----------------------------------------------------------------
//  BASE INTERACTION: reach the outpost, interact, and the siege begins.
//  (Keep CBA "Auto-Start Waves" OFF so the defense only triggers here.)
// ----------------------------------------------------------------
if (hasInterface) then {
    [] spawn {
        waitUntil { !isNull player };
        private _base = call CONCERT_fnc_stage;
        if (isNull _base) exitWith {};
        _base addAction [
            "<t color='#66ff66'>Secure the Outpost  -  Begin Defense</t>",
            { [] call CONCERT_fnc_defenseStart; },
            nil, 10, true, true, "",
            "!CONCERT_defRunning",
            5
        ];
    };
};

// ----------------------------------------------------------------
//  CINEMATIC: fullscreen, skippable. NOT auto-played — the mission calls
//  it when players reach the outpost:  [] call CONCERT_fnc_playIntro;
// ----------------------------------------------------------------
CONCERT_fnc_playIntro = {
    if (!hasInterface) exitWith {};
    if (missionNamespace getVariable ["CONCERT_introPlayed", false]) exitWith {};
    missionNamespace setVariable ["CONCERT_introPlayed", true];
    missionNamespace setVariable ["CONCERT_skipIntro", false];
    private _disp = findDisplay 46;
    private _ehId = -1;
    if (!isNull _disp) then { _ehId = _disp displayAddEventHandler ["KeyDown", { missionNamespace setVariable ["CONCERT_skipIntro", true]; false }]; };
    systemChat "Press any key to skip.";
    private _h = ["\last_stand\data\video\intro.ogv", [safeZoneX, safeZoneY, safeZoneW, safeZoneH], [1,1,1,1], "CONCERT_skipIntro", [0,0,0,0], false] spawn BIS_fnc_playVideo;
    waitUntil { scriptDone _h };
    if (_ehId >= 0 && { !isNull _disp }) then { _disp displayRemoveEventHandler ["KeyDown", _ehId]; };
};

// ----------------------------------------------------------------
//  SERVER-SIDE setup
// ----------------------------------------------------------------
if (isServer) then {
    call CONCERT_fnc_revalidate;

    // Survivors are MILITARY (WEST). Make the zombie (and civilian) sides hostile to west.
    if (!isNull (call CONCERT_fnc_stage)) then {
        CONCERT_zombieSide setFriend [west, 0]; west setFriend [CONCERT_zombieSide, 0];
        civilian setFriend [west, 0];           west setFriend [civilian, 0];
    };

    [] spawn CONCERT_fnc_setupArsenal;

    if (CONCERT_defAutoStart) then { [] spawn { waitUntil { !isNull (call CONCERT_fnc_stage) }; [] call CONCERT_fnc_defenseStart; }; };
};
