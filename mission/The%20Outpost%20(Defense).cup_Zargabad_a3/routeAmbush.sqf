/*
    routeAmbush.sqf  --  SERVER: horde ambushes at marker locations YOU place.
    In Eden, drop markers named  ambush_1, ambush_2, ...  (anything starting with "ambush")
    along the travel route. When a player gets near one, a zombie HORDE spawns there to
    block the way. Each marker fires once. Stops when the siege begins.
    Uses CONCERT_fnc_ambush from @ConcertMod.  Called from init.sqf.
*/
if (!isServer) exitWith {};

// ---- tunables ----
private _hordeSize    = 14;    // zombies per ambush horde
private _triggerDist  = 180;   // spawn when a player gets this close to the marker (m)
private _spread       = 30;    // how spread out the horde spawns around the marker (m)
private _specialChance = 0.4;  // chance the horde includes specials
// ------------------

waitUntil { sleep 2; !isNil "CONCERT_fnc_ambush" };   // wait for the mod

private _markers = allMapMarkers select { (toLower _x) find "ambush" == 0 };
diag_log format ["[CONCERT] routeAmbush: %1 ambush markers -> %2", count _markers, _markers];
if (_markers isEqualTo []) exitWith { diag_log "[CONCERT] routeAmbush: no 'ambush_*' markers placed - nothing to do."; };

private _done = [];
while { !(missionNamespace getVariable ["CONCERT_defRunning", false]) && { count _done < count _markers } } do {
    sleep 3;
    private _players = allUnits select { isPlayer _x && alive _x };
    {
        private _m = _x;
        if !(_m in _done) then {
            private _mp = getMarkerPos _m;
            if (_players findIf { (_x distance2D _mp) < _triggerDist } > -1) then {
                [_mp, _hordeSize, _spread, (random 1 < _specialChance)] call CONCERT_fnc_ambush;
                _done pushBack _m;
                diag_log format ["[CONCERT] routeAmbush: HORDE (%1) spawned at marker %2.", _hordeSize, _m];
            };
        };
    } forEach _markers;
};
diag_log "[CONCERT] routeAmbush: done (siege started or all ambushes triggered).";
