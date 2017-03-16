_init = {
	//if (isServer) then {
		[_trap] call setup_trap;

		if (_trap getVariable ["armed", false]) then {
			[] call _arm;
		} else {
			[] call _disarm;
		};
	//};
};

_arm = {
	_exit = false;
	
	if (!isDedicated && !(_trap getVariable["fullRefund",true])) then {
		_exit = true;
		{
			if (_x in magazines player) exitWith {
				player removeMagazine _x;
				_exit = false;
				_trap setVariable ["fullRefund",true,true];
			};
		} count ["SmokeShell","SmokeShellRed","SmokeShellGreen"];
	};
	
	if (_exit) exitWith {
		//Trap was already triggered, require smoke to rearm
		format[localize "str_player_03",localize "str_dn_smoke"] call dayz_rollingMessages;
	};
	
	//if (isServer) then {
		_pos = getPosATL _trap;
		_pos1 = _trap modelToWorld (_trap selectionPosition "TripA");
		_pos2 = _trap modelToWorld (_trap selectionPosition "TripB");

		_trigger = createTrigger ["EmptyDetector", _pos];
		_trigger setpos _pos;
		_trigger setTriggerArea [1, ([_pos1, _pos2] call BIS_fnc_distance2D) / 2, [_pos1, _pos2] call BIS_fnc_dirTo, true];
		_trigger setTriggerActivation ["ANY", "PRESENT", false];
		_trigger setTriggerStatements [
			"this",
			"['trigger', thisTrigger, thisList] spawn tripsmoke;",
			""
		];

		[_trap, _trigger] call arm_trap;
	//} else {
		//_trap setVariable ["armed", true, true];
	//};
};

_disarm = {
	if (isServer) then {
		[_trap] call disarm_trap;
	} else {
		_trap setVariable ["armed", false, true];
	};
};

_remove = {
	if (isServer) then {
		[_trap] call remove_trap;
	} else {
		[_trap] call remove_trap;
		
		if (_trap getVariable ["fullRefund",true]) then {
			[0,0,0,["cfgMagazines","ItemTrapTripwireSmoke",_trap]] spawn object_pickup;
		} else {
			//Trap was already triggered, refund all parts except grenade
			["equip_string",1,1] call fn_dropItem;
			["PartWoodPile",1,1] call fn_dropItem;
			["equip_duct_tape",1,1] call fn_dropItem;
		};
	};
};

_trigger = {
	if (isServer) then {
		private "_entity";
		_entity = _this select 0;

		[nil,_trap,rSAY,["z_trap_trigger_0",60]] call RE;

		_position = _trap modelToWorld (_trap selectionPosition "TripA");
		_position set [2, 0];

		_flare = createVehicle ["SmokeShell", _position, [], 0, "CAN_COLLIDE"];

		[_trap] call trigger_trap;
		
		//TO-DO: save this variable to DB, currently allows one free rearm after server restart
		_trap setVariable ["fullRefund",false,true];
	};
};

private ["_event", "_trap", "_args"];
_event = _this select 0;
_trap = if (typeOf (_this select 1) == "EmptyDetector") then { dayz_traps_active select (dayz_traps_trigger find (_this select 1)) } else { _this select 1 };
_args = if (count _this > 2) then { _this select 2 } else { [objNull] };

switch (_event) do {
	case "init": {
		[] call _init;
	};
	case "remove": {
		[] call _remove;
	};
	case "arm": {
		[] call _arm;
	};
	case "disarm": {
		[] call _disarm;
	};
	case "trigger": {
		_args call _trigger;
	};
};
