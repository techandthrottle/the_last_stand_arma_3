/*
    missionFlow.sqf  --  per-client cinematic + briefing beats.
      Mission start      : dropoff.ogv (heli ride)   -> brief_dropoff (audio)
      ~120m from the LZ  : brief_travel (audio)
      Near the outpost   : travel.ogv (convoy) -> intro.ogv (arrival cinematic)
    Mission videos: dropoff.ogv / travel.ogv (this folder).  Arrival intro.ogv lives in @LastStand.
*/
if (!hasInterface) exitWith {};
waitUntil { !isNull player };

// Fullscreen, skippable video player (press any key to skip).
LS_playVid = {
    params ["_vid"];
    missionNamespace setVariable ["CONCERT_skipIntro", false];
    private _disp = findDisplay 46;
    private _eh = -1;
    if (!isNull _disp) then { _eh = _disp displayAddEventHandler ["KeyDown", { missionNamespace setVariable ["CONCERT_skipIntro", true]; false }]; };
    systemChat "Press any key to skip.";
    private _h = [_vid, [safeZoneX, safeZoneY, safeZoneW, safeZoneH], [1,1,1,1], "CONCERT_skipIntro", [0,0,0,0], false] spawn BIS_fnc_playVideo;
    waitUntil { scriptDone _h };
    if (_eh >= 0 && { !isNull _disp }) then { _disp displayRemoveEventHandler ["KeyDown", _eh]; };
};

// ---- Mission start: INSERTION cinematic, then drop-off briefing ----
sleep 2;
["dropoff.ogv"] call LS_playVid;
sleep 0.3;
playSound "brief_dropoff";

// record the drop-off point once on foot
waitUntil { sleep 1; (vehicle player == player) && alive player };
private _lz = getPosATL player;

// ---- Travel: ~120 m from the drop-off -> travel briefing ----
waitUntil { sleep 2; !alive player || (player distance2D _lz > 120) };
if (alive player) then { playSound "brief_travel"; };

// ---- Near the outpost: travel cinematic -> arrival cinematic ----
private _base = call CONCERT_fnc_stage;
if (!isNull _base) then {
    waitUntil { sleep 2; !alive player || (player distance2D _base < 90) };
    if (alive player) then {
        ["travel.ogv"] call LS_playVid;   // travel/convoy cinematic
        [] call CONCERT_fnc_playIntro;    // then the arrival cinematic (intro.ogv)
    };
};
