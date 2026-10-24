/*
    heliInsert.sqf  --  run on the SERVER:  [] execVM "heliInsert.sqf";

    Needs in Eden:
        heli1     -> helicopter with AI crew, passengers already loaded (players as cargo)
        lz_pad    -> helipad at the landing zone (Land_HelipadEmpty_F is invisible)
        heli_exit -> (optional) marker where the helicopter flies after unloading
*/
if (!isServer) exitWith {};

private _heli = heli1;
private _pad  = lz_pad;
private _crewGroup = group driver _heli;

// Pilots ignore danger and don't get distracted on the way in
_crewGroup setBehaviourStrong "CARELESS";
_crewGroup setCombatMode "BLUE";

// ---- Phase 0: hold while the opening cinematic plays ----
private _introHold = 14;   // seconds; intro.ogv is ~10s + a short lead-in. Tune to taste.
sleep _introHold;

// ---- Phase 1: fly to the LZ at height ----
_heli flyInHeight 80;
_heli move (getPosATL _pad);
waitUntil { sleep 1; _heli distance2D _pad < 400 || !alive _heli };
if (!alive _heli) exitWith {};

// ---- Phase 2: slow approach ----
_heli limitSpeed 40;
_heli flyInHeight 20;
waitUntil { sleep 1; _heli distance2D _pad < 120 || !alive _heli };
if (!alive _heli) exitWith {};

// ---- Phase 3: land for DROP-OFF (GET OUT keeps the engine on and holds) ----
_heli land "GET OUT";
waitUntil { sleep 0.5; isTouchingGround _heli || (getPosATL _heli select 2) < 1 || !alive _heli };
if (!alive _heli) exitWith {};

// Pin it to the ground so it physically cannot lift while troops disembark.
private _pilot = driver _heli;
_pilot disableAI "MOVE";
_heli setVelocity [0,0,0];
sleep 1.5;

// ---- Phase 4: unload everyone who isn't crew (AI and players), one by one ----
private _passengers = (crew _heli) select { group _x != _crewGroup };
{
    unassignVehicle _x;
    [_x] remoteExec ["moveOut", _x];   // runs where the unit is local, so it works for players too
    sleep 0.6;
} forEach _passengers;

waitUntil { sleep 0.5; ((crew _heli) select { group _x != _crewGroup }) isEqualTo [] };
sleep 4;                               // let the squad move clear of the rotors

// ---- Phase 5: release the pilot and take off ----
_pilot enableAI "MOVE";
_heli land "NONE";
_heli limitSpeed 300;
_heli flyInHeight 100;

private _exit = if (getMarkerColor "heli_exit" != "") then {
    getMarkerPos "heli_exit"
} else {
    _heli getPos [3000, getDir _heli]  // no marker: fly 3 km straight ahead
};
_heli move _exit;

// Clean up once it's far away
waitUntil { sleep 5; _heli distance2D _exit < 300 || !alive _heli };
{ deleteVehicle _x; } forEach (crew _heli);
deleteVehicle _heli;
