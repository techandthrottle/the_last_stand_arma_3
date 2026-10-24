/*
    baseRearm.sqf  --  SERVER: keep friendly AI defenders at the base topped up with ammo.
    Handles static weapons / vehicles (full ammo) and infantry (mag top-up). Players are
    left alone (they use the Resupply crate). Called from init.sqf.
*/
if (!isServer) exitWith {};

// ---- tunables ----
private _range    = 90;    // rearm friendly AI within this of the base (m)
private _interval = 15;    // seconds between rearm passes
private _magTarget = 5;    // keep infantry topped to this many primary mags
// ------------------

waitUntil { sleep 2; !isNull (missionNamespace getVariable ["base_center", objNull]) };
private _base = missionNamespace getVariable ["base_center", objNull];
diag_log "[CONCERT] baseRearm: active.";

while { true } do {
    {
        private _u = _x;
        if (alive _u && !isPlayer _u && { side group _u == west } && { _u distance _base < _range }) then {
            private _v = vehicle _u;
            if (_v != _u) then {
                // static weapon / vehicle gunner -> refill to full
                _v setVehicleAmmo 1;
            } else {
                // infantry -> top up primary-weapon magazines
                private _w = primaryWeapon _u;
                if (_w != "") then {
                    private _mag = (primaryWeaponMagazine _u) param [0, ""];
                    if (_mag == "") then { _mag = (compatibleMagazines _w) param [0, ""]; };
                    if (_mag != "") then {
                        private _have = { _x == _mag } count (magazines _u);
                        if (_have < _magTarget) then {
                            for "_i" from (_have + 1) to _magTarget do { _u addMagazine _mag; };
                        };
                    };
                };
            };
        };
    } forEach allUnits;
    sleep _interval;
};
