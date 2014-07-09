/*
	DZAI_spawnMG
	
	Usage: [_spawnPos, _dir, _class, _weapongrade] spawn DZAI_spawnMG;
	
	Description: 
	
	Last updated: 
*/

private ["_spawnPos","_dir","_class","_weapongrade","_unitGroup","_pos","_attempts","_baseDist","_type","_unit","_static","_weapongrade"];
if (!isServer) exitWith {};

_spawnPos = _this select 0;
_dir = _this select 1;
_class = _this select 2;
_weapongrade = _this select 3;

if ((_dir > 360) || (_dir < 1)) then { _dir = 360; };

_pos = [];
_attempts = 0;
_baseDist = 25;

while {((count _pos) < 1) && {(_attempts < 3)}} do {
	_pos = _spawnPos findEmptyPosition [0.5,_baseDist,"Misc_cargo_cont_small_EP1"];
	if ((count _pos) > 1) then {
		_pos = _pos isFlatEmpty [0,0,0.75,5,0,false,ObjNull];
	}; 
	if ((count _pos) < 1) then {
		_baseDist = (_baseDist + 25);	_attempts = (_attempts + 1);
	};
};

if ((count _pos) < 1) then {
	_pos = [_spawnPos,random (125),random(360),false] call SHK_pos;
	_attempts = (_attempts + 1);
};

_pos set [2,0];

if (DZAI_debugLevel > 1) then {diag_log format ["DZAI Extended Debug: Found spawn position at %3 meters away at position %1 after %2 retries.",_pos,_attempts,(_pos distance _spawnPos)]};

_unitGroup = createGroup (call DZAI_getFreeSide);
_unitGroup setBehaviour "AWARE";
_unitGroup setCombatMode "RED";
//_unitGroup setSpeedMode "FULL";
_unitGroup allowFleeing 0;

_type = DZAI_BanditTypes call BIS_fnc_selectRandom2;								// Select skin of AI unit
_unit = _unitGroup createUnit [_type, _pos, [], 0, "FORM"];							// Spawn the AI unit
_unit setPosATL _pos;
[_unit] joinSilent _unitGroup;														// Add AI unit to group

_unit setVariable ["bodyName",(name _unit)];										// Set unit body name
_unit setVariable ["unithealth",[(10000 + (random 2000)),0,false]];					// Set unit health (blood, legs health, legs broken)
_unit setVariable ["unconscious",false];											// Set unit consciousness

if (DZAI_weaponNoise) then {
	_unit addEventHandler ["Fired", {_this call ai_fired;}];};						// Unit firing causes zombie aggro in the area, like player.
if (isNil "DDOPP_taser_handleHit") then {
	_unit addEventHandler ["HandleDamage",{_this call DZAI_AI_handledamage}];
} else {
	_unit addEventHandler ["HandleDamage",{_this call DDOPP_taser_handleHit;_this call DZAI_AI_handledamage}];
};

//[_unit, _weapongrade] call DZAI_setupLoadout;									// Assign unit loadout
[_unit, _weapongrade] call DZAI_setSkills;										// Set AI skill
[_unit, _weapongrade] spawn DZAI_autoRearm_unit;
if (DZAI_debugLevel > 1) then {diag_log format["DZAI Extended Debug: Spawned AI machine gunner type %1 with weapongrade %2 for group %3 (fnc_createGroup).",_type,_weapongrade,_unitGroup];};

_static = createVehicle [_class, _pos, [], 0, "CAN_COLLIDE"];
_static setDir round(_dir);
_static setPos _pos;

_static addEventHandler ["GetOut",{(_this select 0) setDamage 1;}];
_nul = _static call DZAI_protectObject;

_unit moveingunner _static;

_unitGroup selectLeader ((units _unitGroup) select 0);
_unitGroup setVariable ["GroupSize",1];
_unitGroup setVariable ["spawnPos",_spawnPos];
(DZAI_numAIUnits + 1) call DZAI_updateUnitCount;