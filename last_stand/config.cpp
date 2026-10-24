class CfgPatches {
    class last_stand {
        name = "Last Stand";
        author = "Ragequit";
        units[] = {};
        weapons[] = {};
        requiredVersion = 2.10;
        requiredAddons[] = {"A3_Functions_F", "cba_main"};  // cba_main: CBA Settings for the gamemode
    };
};

// CBA preInit hook: registers the "Zombie Defense" settings before the game logic runs.
class Extended_PreInit_EventHandlers {
    class last_stand_preInit {
        init = "call compile preprocessFileLineNumbers '\last_stand\XEH_preInit.sqf'";
    };
};

class CfgFunctions {
    class CONCERT {
        tag = "CONCERT";
        class core {
            file = "\last_stand\functions";
            class gameInit { postInit = 1; }; // the whole gamemode, runs on every machine at start
        };
    };
};

class CfgSounds {
    sounds[] = {};
    // 2D voice briefing played once per client at mission start.
    class concert_briefing {
        name = "concert_briefing";
        sound[] = {"\last_stand\data\audio\briefing.ogg", 3.16, 1};
        titles[] = {};
    };
};
