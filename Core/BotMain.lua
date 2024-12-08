--=====================================================
-- CopyRight (c) R 2022-2023
--
-- THE CORE FILE OF THE CRYMP-BOT
--
--=====================================================

------------------------------
if (Config.System == false) then
	SetError("System Disabled", "System Disabled in Config.Lua")
	BotError(false)
	return
end

------------------------------
if (not g_gameRules) then
	SetError("Bot Initialized to soon", "Bot.Init called before gameRules exist - should never happen");
	BotError(true)
	return
end

------------------------------
if (not g_localActor) then
	SetError("Bot Initialized to soon", "Bot.Init called before localActor exist - should never happen");
	BotError(true)

	return
end

------------------------------
if (not g_localActor.actor.SimulateInput) then
	SetError("Invalid Client", "Attempt to load bot on invalid Client");
	BotError(true)
	return
end

------------------------------
BotMainLog = function(iVerbosity, sFormat, ...)
	local sPrint = sFormat
	local aArgs = { ... }

	if (isNumber(iVerbosity)) then
		if (iVerbosity > Bot.LOG_VERBOSITY) then
			return
		end
	else
		sPrint = iVerbosity
		aArgs = table.insertFirst(aArgs, sFormat)
	end
	SystemLog(("[BotMain] " .. tostring(sPrint)), unpack(aArgs))
end

------------------------------
eRH_ENTITY = 0
eRH_POSITION = 1
eRH_ALL = 3

------------------------------
BOT_CPU_SAVER = false
ON_BOT_FPS = nil

BOT_MAX_FPS = 120.0
LAST_FRAME = nil

BOT_SMOOTHEN_MOVEMENT = true
BOT_CAMERA_RELEASE = 0x01
BOT_CAMERA_WALLJUMP = 0x02

BOT_CAMERASPEED_INSTANT = -1
BOT_CAMERASPEED_AUTO = -2
BOT_CAMERASPEED_COMBAT = -3

BOT_VIEW_ANGLES = 180
BOT_ENABLED = checkGlobal("BOT_ENABLED", 1, checkNumber)
BOT_USE_ANGLES = checkGlobal("BOT_USE_ANGLES", 1, checkNumber)
BOT_HOSITLITY = checkGlobal("BOT_HOSITLITY", 1, checkNumber)
BOT_MOVEMENT = checkGlobal("BOT_MOVEMENT",  1, checkNumber)
BOT_WEAPONHANDLING = checkGlobal("BOT_WEAPONHANDLING", 1, checkNumber)
BOT_CAN_WALLJUMP = checkGlobal("BOT_CAN_WALLJUMP", true)
BOT_BLOCK_WEAPONS = checkGlobal("BOT_BLOCK_WEAPONS", 0, checkNumber)
BOT_ADJUST_AIM = checkGlobal("BOT_ADJUST_AIM", 0, checkNumber)
BOT_PRESSED_KEYS = checkGlobal("BOT_PRESSED_KEYS", {}, checkArray)
ASTAR_DEBUG = checkGlobal("ASTAR_DEBUG", 0, checkNumber)
BOT_CPP_PATHGEN = checkGlobal("BOT_CPP_PATHGEN", 1, checkNumber)
BOT_USE_FIELDOFVIEW = checkGlobal("BOT_USE_FIELDOFVIEW", 1, checkNumber)
BOT_FIELDOFVIEW = checkGlobal("BOT_FIELDOFVIEW", 125, checkNumber)
BOT_TEST_ACTIVE = checkGlobal("BOT_TEST_ACTIVE", 0, checkNumber)
BOT_TEST_ENABLED = checkGlobal("BOT_TEST_ENABLED", 0, checkNumber)
BOT_PERFORMANCE_MODE = checkGlobal("BOT_PERFORMANCE_MODE", 0, checkNumber)

BOT_GO_IDLE = false

BOT_RAYWORLD_MAXDIST = 1024
RH_GET_ENTITY = 0x1
RH_GET_POS = 0x2
RH_GET_ALL = 0x4

------------------------------

SEATID_DRIVER = 1

------------------------------

WEAPON_GAUSS = "GaussRifle"
WEAPON_DSG = "DSG1"
WEAPON_SCAR = "SCAR"
WEAPON_SMG = "SMG"
WEAPON_FY71 = "FY71"
WEAPON_SHOTGUN = "Shotgun"
WEAPON_SOCOM = "SOCOM"
WEAPON_HURRICANE = "Hurricane"
WEAPON_ALIEN = "AlienMount"
WEAPON_RPG = "LAW"
WEAPON_FISTS = "Fists"
WEAPON_C4 = "C4"
WEAPON_DETONATOR = "Detonator"
WEAPON_CLAYMORE = "Claymore"

------------------------------

ITEM_KIT_RADAR = "RadarKit"
ITEM_KIT_LOCKPICK = "Lockpick"
ITEM_KIT_REPAIR = "Repairkit"

------------------------------

BOT_SPECIAL_ITEMS = {

	-- Test!!
	WEAPON_CLAYMORE,
	WEAPON_C4,
}
BOT_ITEM_PRIORITY = {
	FY71 = 10,
	SCAR = 9,
	SMG = 8,
	DSG1 = 7,
	GaussRifle = 7,
	Shotgun = 6,
	Hurricane = 5,
	SOCOM = 4,

	-- Test!!
	Claymore = 3,
	C4 = 3,
}

------------------------------

BOT_WALLJUMP_RESET = -1

------------------------------

ENTITY_AVMINE = "AVMine"
ENTITY_CLAYMORE = "Claymore"
ENTITY_FRAG = "Grenade" -- ??
ENTITY_FLYING_FRAG = "explosivegrenade" -- Projectiles

------------------------------

GAMERULES_POWERSTRUGGLE = "PowerStruggle"
GAMERULES_INSTANTACTION = "InstantAction"

------------------------------

BONE_HEAD = "Bip01 Head"
BONE_NECK = "Bip01 Neck"
BONE_PELVIS = "Bip01 Pelvis"

------------------------------

VEHICLE_CIV = "Civ_car1"
VEHICLE_USLTV = "US_ltv"
VEHICLE_NKLTV = "NK_ltv"
VEHICLE_LTV = ".*_ltv$"
VEHICLE_TANK = ".*_?tank$"
VEHICLE_APC = ".*_?apc$"
VEHICLE_TANKS = { VEHICLE_TANK, VEHICLE_APC }

------------------------------
NANOMODE_NULL = -1
NANOMODE_ARMOR = 3
NANOMODE_SPEED = 0
NANOMODE_STRENGTH = 1
NANOMODE_CLOAK = 2

------------------------------
MOVE_FORWARD = 1
MOVE_BACKWARD = 2
MOVE_LEFT = 3
MOVE_RIGHT = 4

VEHICLE_MOVE_FORWARD = 10
VEHICLE_MOVE_BACKWARD = 11
VEHICLE_MOVE_LEFT = 12
VEHICLE_MOVE_RIGHT = 13

KEY_FORWARD = "moveforward"
KEY_BACKWARD = "moveback"
KEY_LEFT = "moveleft"
KEY_RIGHT = "moveright"
KEY_V_FORWARD = "v_moveforward"
KEY_V_BACKWARD = "v_moveback"
KEY_V_LEFT = "v_turnleft"
KEY_V_RIGHT = "v_turnright"
KEY_V_ROTATEYAW = "v_rotateyaw"
KEY_V_ROTATEPITCH = "v_rotatepitch"

KEY_VEHICLE_BRAKE = "v_brake"
KEY_VEHICLE_BOOST = "v_boost"

KEY_SPRINT = "sprint"
KEY_JUMP = "jump"
KEY_ATTACK = "attack1"
KEY_MELEE = "special"
KEY_RELOAD = "reload"
KEY_INTERACT = "use"

KEY_CROUCH = "crouch"
KEY_PRONE = "prone"
KEY_STAND = { "crouch", "prone" }

PRESS_KEY = 0 -- press->release
HOLD_KEY = -1 -- infinite

------------------------------

FRAMELOG_PRINTALL = -1
FRAMELOG_PRINTTHRESHOLD = nil

------------------------------

eCVar_StancesNormal = 0 -- Normal stance switching
eCVar_StancesSimple = 1 -- Ignores some checks but still fails sometimes
eCVar_StancesSimpleEx = 2 -- Can't fail

eWallJumpType_Pos = 0
eWallJumpType_Vel = 1

eVehicleType_Other = ""
eVehicleType_Land = "land"
eVehicleType_Air = "air"

eExitVehicle_AIDecision = inc(1, 1)
eExitVehicle_FatalStuck = inc()
eExitVehicle_Flipped = inc()
eExitVehicle_NearTarget = inc()
eExitVehicle_DriverSeatBlocked = inc()
eExitVehicle_NarrowPath = inc()
eExitVehicle_RPGAttack = incEnd()

eDirection_Right = inc(1, "*2")
eDirection_Left = inc()
eDirection_Front = inc()
eDirection_Back = incEnd()

eMovInterrupt_None = inc(0, 1)
eMovInterrupt_Beef = inc()
eMovInterrupt_DoorPause = inc()
eMovInterrupt_DangerOutside = inc()
eMovInterrupt_FindUber = inc()
eMovInterrupt_EnterUber = inc()
eMovInterrupt_HopInMyVan = inc()
eMovInterrupt_Test = inc()
eMovInterrupt_CaptureInVehicle = inc()
eMovInterrupt_PlaceExplosive = inc()
eMovInterrupt_End = incEnd()

eStanceInterrupt_CampingPCM = inc(1, 1)
eStanceInterrupt_Camping = inc()
eStanceInterrupt_End = incEnd()

------------------------------
Bot = {
	id = nil,
	ent = nil,
	actor = nil,
	inventory = nil
}

Bot.aCfg = {}
Bot.aGlobals = {}
Bot.PressedKeys = {}

------------------------------

Bot.CJ_INFO = {}
Bot.CJ_KeyTimers = {}

------------------------------

Bot.FRAME = nil
Bot.FRAMES_PASSED = 0

------------------------------
Bot.LOG_VERBOSITY = 69
Bot.FRAME_CALLS = {}
Bot.REVIVE_TIMERS = {}
Bot.BOT_STUCK_TIME = 0.0
Bot.BOT_DEFAULT_STUCK_TIME = 2.5
Bot.BOT_INDOORS_TIME = 0.0
Bot.BOT_SUBTERRAIN_TIME = 0.0

Bot.WALLJUMPING = nil
Bot.WALLJUMP_SYSTEM = eWallJumpType_Pos
Bot.WALLJUMP_SYSTEM = eWallJumpType_Pos -- !!FIXME


-------------------------------
--- CVars that will be forced and unsynched
Bot.BOT_SYNCED_FORCED_CVARS = {

	-- Debug
	R_ATOC		  = 1.0, -- Broken Alpha to Coverage
	E_TERRAIN	  = 1.0, -- Show Terrain
	E_SKETCH_MODE = 1.0, -- More performance

	-- Only in release version
	SYS_FLASH = (BOT_DEBUG_MODE and  1.0 or 0.0), -- Disables Flash Files
	E_RENDER  = (BOT_DEBUG_MODE and  1.0 or 0.0), -- Disables Renderer
	--R_WIDTH   = (BOT_DEBUG_MODE and 1024 or 1),   -- Screen Width
	--R_HEIGHT  = (BOT_DEBUG_MODE and  800 or 1),   -- Screen Height

}

-------------------------------
--- CVars that will be forced
Bot.BOT_FORCED_CVARS = {

	-- Stuff
	BOT_SIMPLYFIED_MELEE 	= 1, -- Simplified Melee
	BOT_SIMPLYFIED_STANCES 	= eCVar_StancesSimpleEx, -- Simplified Stances

	-- Items
	BOT_FORCED_SPREAD 	= 0.001, -- Spread Multiplier
	BOT_FORCED_RECOIL 	= 0.001, -- Recoil Muliplier
	BOT_FORCED_PJS 		= 5.0,   -- Projectile Velocity
	BOT_SPRINT_SHOOTING = 1.0,   -- Shoot while sprinting
	BOT_FORCED_RECOIL_MULTIPLIER = 0.001,

	-- Character
	CL_BOB = 0.0,
	CL_LEANAMOUNT = 0.5, -- fixes lean glitches

	-- Movement
	BOT_AI_WALKMULT = 1.0, -- AI
	BOT_WALKMULT 	= 1.0,

	-- FPS
	BOT_SYSTEM_MAXFPS = 60.0
}

Bot.FORCED_SPRINT = nil
Bot.BOT_FORCED_NOSPRINT = nil

Bot.BOT_COMBAT_MOVEKEY = nil
Bot.BOT_COMBAT_TIMER_LASTMOVE = nil

Bot.FORCED_CAM_SPEED = nil
Bot.FORCED_CAM_LOOKAT = nil

Bot.FORCED_SUITMODE = nil -- ???
Bot.FORCED_SUIT_MODE = nil -- ??????
Bot.FORCED_SUIT_TIMER = nil

Bot.BOT_FORCED_FIREMODES = {
	Shotgun = 2,
}

Bot.FORCED_PATH_DELAY = nil

Bot.LAST_DEBUG_EFFECT = nil
Bot.LAST_DEBUG_EFFECTS = {}

Bot.CURRENT_MOVEMENT = nil

Bot.MOVEMENT_INTERRUPTED = eMovInterrupt_None
Bot.MOVEMENT_INTERRUPTED_TIMER = nil
Bot.MOVEMENT_INTERRUPTED_EXPIRY = nil

Bot.CAM_MOVEMENT_INTERRUPTED = eMovInterrupt_None
Bot.CAM_MOVEMENT_INTERRUPTED_TIMER = nil
Bot.CAM_MOVEMENT_INTERRUPTED_EXPIRY = nil

Bot.PLACED_EXPLOSIVES = {}
Bot.C4_LOCATIONS = {}

------------------------------
--- Init
Bot.Init = function(self)

	---------------------------------------
	BotLog("Bot.Init()")
	self:InitWithLocalActor()

	---------------------------------------
	local bOk, sErr = nil
	bOk = self:LoadLibraries()
	if (not bOk) then
		return false, SetError("Failed to Load Bot Libraries", "Unknown Cause"), BotError()
	end

	------------------------------------
	bOk, sErr = pcall(RWITools.Init, RWITools)
	if (not bOk) then
		return false, SetError("Failed to Initialize RWITools", sErr), BotError() end

	------------------------------------
	if (not BOT_KEEP_CORE) then
		bOk, sErr = pcall(Pathfinding.Init, Pathfinding)
		if (not bOk) then
			return false, SetError("Failed to Initialize Pathfinding System", sErr), BotError() end

		------------------------------------
		bOk, sErr = pcall(BotNavigation.Init, BotNavigation)
		if (not bOk) then
			return false, SetError("Failed to Initialize Navigation System", sErr), BotError() end

		------------------------------------
		bOk, sErr = pcall(BotAI.Init, BotAI)
		if (not bOk) then
			return false, SetError("Failed to Initialize AI System", sErr), BotError() end
	end

	------------------------------------
	self:PatchGameRules()
	self:PatchEntities()

	------------------------------------
	self:InitCVars()
	self:InitCommands()
	self:SetCVars()

	------------------------------------
	BOT_LUA_LOADED = true
	self:StopAll()

	------------------------------------
	BotLog("Bot Initialized")
	BotLog("Bot LUA Statistics: ")
	BotLog("    %s", table.countTypes(Bot))
end

------------------------------
--- Init
Bot.InitWithLocalActor = function(self)

	if (self.id and self.id == g_localActorId) then
		BotMainLog("[$7Warning$9] Already Initialized with Local Actor!")
	end

	self.id = g_localActorId
	self.ent = g_localActor
	self.actor = g_localActor.actor
	self.inventory = g_localActor.inventory
	BotMainLog("Initialized with Local Actor")

	--[[
	g_localActor.tsss = timernew(3)
	g_localActor.rec_a = {}
	g_localActor.OnAction = function(s, a, b, c)

		local ok = {
			"moveforward",
			"moveright","moveleft","moveback","jump","sprint"
		}

		if (not string.matchex(a, unpack(ok))) then
			return
		end

		local diff = 0
		if (g_localActor.rec_a[a]) then
			diff = g_localActor.rec_a[a].diff()
		end

		g_localActor.rec_a[a] = timernew()
		--BotMainLog("Pressing %-13s (A = %-10s), Between = %f", a, b, diff)
		BotMainLog("{ Timer = timernew(%f), Action = %s, Key = \"%s\"", g_localActor.tsss.diff(), (c == 0 and "self.ReleaseKey" or "self.PressKey"), a)
	end
	]]
end

------------------------------
--- Init
Bot.SetCVars = function(self)

	local aCVars = table.merge(self.BOT_SYNCED_FORCED_CVARS, self.BOT_FORCED_CVARS)
	for sName, pValue in pairs(aCVars) do
		Game.SetCVarSynch(sName, false)
		Game.ForceCVar(sName, tostring(pValue))
	end

	BotMainLog("Forced %d CVars to predefined values", table.count(aCVars))

end

------------------------------
--- Init
Bot.RestoreCVarSync = function(self)

	local aCVars = self.BOT_SYNCED_FORCED_CVARS
	for sName, pValue in pairs(aCVars) do
		Game.SetCVarSynch(sName, true)
	end

	BotMainLog("Restored Synch for %d CVars", table.count(aCVars))

end

------------------------------
--- Init
Bot.InitCVars = function(self, aList)

	------------------------------
	local sPrefix = "BOT_"
	local aCVars = checkVar(aList, {
		{ "toggle", 	"BOT_ENABLED", 		 BOT_ENABLED, 		"Toggles the Bot System Update", "Bot:OnShutdown", true },
		{ "hostility", 	"BOT_HOSITLITY", 	 BOT_HOSITLITY, 	"Toggles Bot Hostility", nil, true },
		{ "movement", 	"BOT_MOVEMENT", 	 BOT_MOVEMENT, 		"Toggles Bot Movment", nil, true },
		{ "blockitems", "BOT_BLOCK_WEAPONS", BOT_BLOCK_WEAPONS, "Toggles the Bots ability to fire weapons", nil, true },
		{ "adjustAim", 	"BOT_ADJUST_AIM", 	 BOT_ADJUST_AIM, 	"Toggles adjusting aim direction based on the targets velocity and speed", nil, true },
		{ "debug_astar", 	"ASTAR_DEBUG", 	 ASTAR_DEBUG, 		"Toggles AStar algorithm debugging", nil, true },
		{ "astar_cpp", 	"BOT_CPP_PATHGEN", 	 BOT_CPP_PATHGEN, 	"Toggles AStar algorithm debugging", nil, true },

		{ "test_toggle", 	"BOT_TEST_ACTIVE", 	 BOT_TEST_ACTIVE, 	"Toggles AStar algorithm debugging", nil, true },
		{ "test_enable", 	"BOT_TEST_ENABLED", 	 BOT_TEST_ENABLED, 	"Toggles AStar algorithm debugging", nil, true },

		{ "performance_mode", 	"BOT_PERFORMANCE_MODE", 	 BOT_PERFORMANCE_MODE, 	"Toggles AStar algorithm debugging", nil, true },

		{ "use_fov", 	"BOT_USE_FIELDOFVIEW", 	 BOT_USE_FIELDOFVIEW, 	"Toggles AStar algorithm debugging", nil, true },
		{ "fov", 	"BOT_FIELDOFVIEW", 	 BOT_FIELDOFVIEW, 	"Toggles AStar algorithm debugging", nil, true },

		{ "framelog_threshold", "FRAMELOG_PRINTTHRESHOLD", FRAMELOG_PRINTTHRESHOLD, "Toggles the threshold at which frame calls are logged (if iCalls > iThis)\nAlternatively you can use macros like 'topN' to print the topN calls (where N represents the number)", nil },
	})
	local iCVars = table.count(aCVars)

	------------------------------
	for i, aInfo in pairs (aCVars) do
		local sName 	= aInfo[1]
		local sGlobal  	= aInfo[2]
		local pDefault  = aInfo[3]
		local sDesc 	= aInfo[4]
		local fCallback = aInfo[5]
		local bNumber 	= aInfo[6]

		AddCVar((sPrefix .. sName), checkString(sDesc, "<No Description>"), pDefault, isNumber(pDefault) or bNumber, sGlobal, fCallback)
	end

	------------------------------
	BotMainLog(0, "Registered %d New Console Variables", iCVars)

	------------------------------
	return true
end

------------------------------
--- Init
Bot.InitCommands = function(self, aList)

	------------------------------
	local sPrefix = "BOT_"
	local aCommands = checkVar(aList, {
		{ "test", 					"test_description", 	"BotLog('Function-Called')" },
		{ "exec", 					"test_description", 	"loadstring(%%)" },
		{ "reload", 				"test_description", 	"Bot:Reload()" },
		{ "reloadonly", 			"test_description", 	"Bot:Reload(nil,1)" },
		{ "enable_frame_logging", 	"test_description", 	[[Bot:EnableFrameLogging()]] },
		{ "interrupt", 				"test_description", 	[[Bot:Interrupt()]] },
	})
	local iCVars = table.count(aCommands)

	------------------------------
	for i, aInfo in pairs (aCommands) do
		local sName 	= aInfo[1]
		local sFunc 	= aInfo[3]
		local sDesc 	= aInfo[2]

		AddCommand((sPrefix .. sName), checkString(sDesc, "<No Description>"), sFunc)
	end

	------------------------------
	BotMainLog(0, "Registered %d New Console Variables", iCVars)

	------------------------------
	return true
end

------------------------------
--- Init
Bot.PatchGameRules = function()

	----------------------------------
	if (not g_gameRules) then
		return false end

	----------------------------------
	function g_gameRules.Client:OnKill(playerId, shooterId, weaponClassName, damage, material, hit_type)
		local matName = self.game:GetHitMaterialName(material) or ""
		local type = self.game:GetHitType(hit_type) or ""

		local HS = string.find(matName, "head" )
		local ML = string.find(type,    "melee")

		Bot:OnKilled(playerId, shooterId, weaponClassName, damage, material, hit_type);
	end
	----------------------------------
	g_gameRules.Client.InGame.OnKill = g_gameRules.Client.OnKill; -- wtf, CryTek?
	g_gameRules.Client.PreGame.OnKill = g_gameRules.Client.OnKill; -- wtf, CryTek?
end

------------------------------
--- Init
Bot.PatchEntities = function(self)

	self:PatchDoors()
	ENTITY_DOOR_PATCHED = true
end

------------------------------
--- Init
Bot.PatchSpawns = function()
	if (not SpawnPoint) then
		return true end

	---------------------------------
	function SpawnPoint:Spawned(entity)
		BroadcastEvent(self, "Spawn");
		Bot.OnRevive(Bot, self, entity)
	end

	---------------------------------
	for i, hSpawn in pairs(GetEntities("SpawnPoint")) do
		hSpawn.Spawned = SpawnPoint.Spawned;
	end
end

------------------------------
--- Init
Bot.PatchDoors = function()

	----------------------------------
	if (not Door) then
		Script.ReloadScript("Scripts/Entities/Doors/Door.lua", 1, 1)
		if (not Door) then
			return
		end
	end

	----------------------------------
	-- Door.Properties.Rotation.fRange = 180
	Door.Patch = function(hDoor)
		hDoor.Properties.Rotation.bRelativeToUser = 1
		hDoor.Properties.Rotation.fRange = 180
		hDoor.Client.ClRotate = Door.Client.ClRotate
		hDoor.IsClosed = function(self)
			return (self.action == DOOR_CLOSE)
		end
		--BotDLL.SetPassthroughPhysics(hDoor)
	end

	----------------------------------
	function Door.Client:ClRotate(bOpen, bFwd)
		self.action = (bOpen and DOOR_OPEN or DOOR_CLOSE)
		self:Rotate(bOpen, true) -- always open doors forwards relative to the user
	end

	---------------------------------
	for i, hDoor in pairs(GetEntities("Door")) do
		Door.Patch(hDoor)
	end
end

------------------------------
--- Init
Bot.LoadLibraries = function(self)

	if (not self:LoadCVars()) then
		return false end

	if (not self:LoadMaths()) then
		return false end

	if (not self:LoadUtilities()) then
		return false end

	if (not self:LoadTools()) then
		return false end

	if (not BOT_KEEP_CORE) then
		if (not self:LoadPathfinding()) then
			return false end

		if (not self:LoadNavigation()) then
			return false end

		if (not self:LoadAISystem()) then
			return false end
	end

	self:LoadColors()

	BotLog("All Libraries loaded")

	return true
end

------------------------------
--- Init
Bot.LoadFile = function(self, sFile, sName, sPath)

	------------------------------
	local sLibPath = CRYMP_BOT_ROOT .. "\\Core\\" .. checkString(sPath, "")

	------------------------------
	BotLog("Loading %s Library", checkVar(sName, sFile))

	------------------------------
	local bOk, hLib = BotMain:LoadFile(sLibPath .. "\\" .. sFile)
	if (not bOk) then
		return false end

	------------------------------
	BotLog("Loaded %s Library", checkVar(sName, sFile))

	------------------------------
	return true
end

------------------------------
--- Init
Bot.LoadTools = function(self)
	return self:LoadFile("RWITools.lua", "RWITools", "Pathfinding\\")
end

------------------------------
--- Init
Bot.LoadColors = function(self)
	return self:LoadFile("Colors.lua", "Colors", "Utils\\")
end

------------------------------
--- Init
Bot.LoadUtilities = function(self)
	return self:LoadFile("Utilities.lua", "Utilities", "Utils\\")
end

------------------------------
--- Init
Bot.LoadCVars = function(self)
	return self:LoadFile("CVars.lua", "CVars")
end

------------------------------
--- Init
Bot.LoadMaths = function(self)
	return self:LoadFile("Math.lua", "Maths")
end

------------------------------
--- Init
Bot.LoadPathfinding = function(self)
	return self:LoadFile("BotPathfinding.lua", "Pathfinding", "Pathfinding\\")
end

------------------------------
--- Init
Bot.LoadNavigation = function(self)
	return self:LoadFile("BotNavigation.lua", "Navigation", "Pathfinding\\")
end

------------------------------
--- Init
Bot.LoadAISystem = function(self)
	return self:LoadFile("BotAI.lua", "AI System", "AI\\")
end

------------------------------
--- Init
Bot.GetLevelName = function()

	------------------------------------------------------------
	local sLevel

	------------------------------------------------------------
	if (Game.GetCurrentLevel) then
		sLevel = Game:GetCurrentLevel()
	elseif (g_localActor.actor.GetCurrentLevel) then
		sLevel = g_localActor.actor:GetCurrentLevel()
	else
		sLevel = System.GetCVar("sv_Map")
	end

	------------------------------------------------------------
	return sLevel
end

------------------------------
--- Init
Bot.Reload = function(self, bClearData, bKeepCore)
	BotMainLog(0, "Reloading file ... ");

	if (clearData) then
		Bot = nil
	end

	if (bKeepCore) then
		SYSTEM_INTERRUPTED = false
		BOT_KEEP_CORE = true
	end
	BOT_RELOADING = true

	if (not BotMain) then
		return BotLog("Bot.Reload() BotMain is Null")
	end

	BotMain:LoadConfigFile()
	BotMain:LoadBotCore()

	BOT_KEEP_CORE = nil
end

------------------------------
--- Init
Bot.PreOnTimer = function(self, iFrametime)

	if (not g_gameRules) then
		return
	end

	self.OnTimer(self, (g_gameRules.class == GAMERULES_POWERSTRUGGLE), checkNumber(iFrametime, System.GetFrameTime()))
	--local s, e = pcall(self.OnTimer, self, g_gameRules.class == "PowerStruggle", (frameTime or System.GetFrameTime()));
	--if (not s and e) then
	--	SetError("Script Error in OnTimer()", tostring(e))
	--	BotError(Bot.aCfg.quitOnSoftError, true);
	--end
end

------------------------------
--- Init
Bot.PreOnHit = function(self, ...)

	self.OnHit(self, ...)
end

------------------------------
--- Init
Bot.PreOnExplosion = function(self, ...)

	self.OnExplosion(self, ...)
end

------------------------------
--- Init
Bot.OnTimer = function(self, ts)

	----------
	if (Pathfinding) then
		Pathfinding:OnTick() end

	----------
	if (BOT_ENABLED <= 0) then
		return end

	----------
	if (not g_localActor) then
		return end

	----------
	if (not self:EnterServerCooldown()) then
		return
	end

	----------
	BotAI.CallEvent("OnTimer", System.GetFrameTime())

end

------------------------------
--- Init
Bot.OnDisconnect = function(self, hPlayer, iChannel)

	if (not hPlayer.CONNECTED) then
		return
	end

	hPlayer.CONNECTED = nil -- non-player spam fix
	BotMainLog(0, "Player %s Disconnecting on Slot %d", checkString(hPlayer:GetName(), "Unknown"), iChannel);
end

------------------------------
--- Init
Bot.OnPlayerConnected = function(self, hPlayer, iChannel)

	if (hPlayer.CONNECTED) then
		return
	end

	hPlayer.CONNECTED = true -- non-player spam fix
	BotMainLog(0, "Player %s Connected on Slot %d", checkString(hPlayer:GetName(), "Unknown"), iChannel);
end

------------------------------
--- Init
Bot.PreUpdate = function(self, iFrametime)

	---------
	if (not g_gameRules) then
		return
	end

	self.DoUpdate(self, (g_gameRules.class == GAMERULES_POWERSTRUGGLE), checkNumber(iFrametime, System.GetFrameTime()))
	-- Errors handled in API
	--local bOk, sErr = pcall(self.DoUpdate, self, g_gameRules.class == "PowerStruggle", (iFT or System.GetFrameTime()));
	--if (not bOk) then
	--	SetError("Script Error in OnUpdate()", sErr)
	--	BotError()
	--end
end

------------------------------
--- Init
Bot.SpawnDebugEffect = function(self, vPos, sHandle, iScale)

	local bExpired = timerexpired(self.LAST_DEBUG_EFFECT, 1)
	if (sHandle) then
		bExpired = timerexpired(self.LAST_DEBUG_EFFECTS[sHandle], 1)
	end

	if (bExpired) then
		Particle.SpawnEffect("explosions.flare.night_time", vPos, g_Vectors.up, checkVar(iScale, 0.1))
		self.LAST_DEBUG_EFFECT = timerinit()
		if (sHandle) then
			self.LAST_DEBUG_EFFECTS[sHandle] = timerinit()
		end
	end
end

------------------------------
--- Init
Bot.Interrupt = function(self)

	if (SYSTEM_INTERRUPTED) then
		SYSTEM_INTERRUPTED = false
	else
		SYSTEM_INTERRUPTED = true
	end

	BotMainLog("System Interruption: %s", string.bool(SYSTEM_INTERRUPTED, BTOSTRING_ACTIVATED))
end

------------------------------
--- Init
Bot.EnableFrameLogging = function(self)

	local aBlacklist = {
		EnableFrameLogging = true,
		ResetFrameCalls = true,
		PrintFrameCall = true,
		LogFrameCall = true,
	}

	for i, v in pairs(self) do
		if (isFunc(v)) then
			if (aBlacklist[i] == nil) then
				local fOld = v
				local fNew = function(...)
					self:LogFrameCall(i)
					return fOld(...)
				end

				Bot[i] = fNew
			end
		end
	end

	BotLog("FrameLogging Enabled")
end

------------------------------
--- Init
Bot.ResetFrameCalls = function(self)
	for sFunc, v in pairs(self.FRAME_CALLS) do
		self.FRAME_CALLS[sFunc] = 0
	end
end

------------------------------
--- Init
Bot.LogFrameCall = function(self, sFunc)

	local iFrame = System.GetFrameID()
	if (self.CURRENT_FRAME ~= iFrame) then
		self.CURRENT_FRAME = iFrame
		self:PrintFrameCall(FRAMELOG_PRINTALL, FRAMELOG_PRINTTHRESHOLD)
		self:ResetFrameCalls()
	end

	self.FRAME_CALLS[sFunc] = (self.FRAME_CALLS[sFunc] or 0) + 1
end

------------------------------
--- Init
Bot.PrintFrameCall = function(self, sFunc, hThreshold)

	local bOk
	local aPrint = {}
	local iThreshold = string.matchex(hThreshold, "^(%d+)$")
	if (sFunc == FRAMELOG_PRINTALL) then
		for i, v in pairs(self.FRAME_CALLS) do
			bOk = true
			if (isNumber(iThreshold)) then
				bOk = (v >= iThreshold)
			end

			if (bOk) then
				table.insert(aPrint, { v, i })
			end
		end

		local iTop = string.matchex(hThreshold, "top(%d+)")
		if (iTop) then
			table.sort(aPrint, function(a, b) return (a[1] > b[1])  end)
			aPrint = table.ikeep(aPrint, tonumber(iTop))
		end

		BotLog("%s", string.rep("*", 29))
		for i, v in pairs(aPrint) do
			BotLog("Bot.%-20s [%2d]", v[2], v[1])
		end
		return
	end

	local iCalls = (self.FRAME_CALLS[sFunc] or 0)
	BotLog("[%s] %d", sFunc, iCalls)
end

------------------------------
--- Init
Bot.CanUpdate = function(self)
	return true
end

------------------------------
--- Init
Bot.OkToUpdate = function(self)
	local iBotFPS = 30

	if (BOT_CPU_SAVER) then
		iBotFPS = 24
	end

	local time = _time;
	if (ON_BOT_FPS and (time - ON_BOT_FPS) < (1 / iBotFPS)) then
		return false
	end

	ON_BOT_FPS = time
	return true
end

------------------------------
--- Init
Bot.LimitFPS = function(self)
	local iFPSMax = tonumber(BOT_MAX_FPS)
	if (iFPSMax and iFPSMax >= 1) then
		local iCurrTime = os.clock()
		while (LAST_FRAME and (1 / (iCurrTime - LAST_FRAME) > iFPSMax)) do
			iCurrTime = os.clock()
		end
		LAST_FRAME = iCurrTime
	end
end

------------------------------
--- Init
Bot.IsTargetVisible = function(self, hEntity)

	aRW_HitTable1 = {}
	aRW_HitTable2 = {}

	local bActor = (hEntity.actor ~= nil)
	local aTargetPositions = {
		hEntity:GetPos()
	}

	if (bActor) then
		aTargetPositions = {
			self:GetHeadPos(hEntity),
			self:GetBone_Pos(BONE_PELVIS, hEntity),
			hEntity:GetPos(),
		}
	end

	local iFlags = RWI_FLAGS_AMMOPIERCE1
	local iEnts = ent_all
	local iHits, iHits_B

	local vCamPos = self:GetViewCameraPos()
	local vDir
	local vDir_Scaled

	local iDistance = BOT_RAYWORLD_MAXDIST
	if (iDistance < 1) then
		iDistance = 1
	end

	local iMaxHits = 10
	local nIgnore1 = g_localActorId
	local nIgnore2 = nil

	local aHit, sClass, sSurfaceName

	local bSeethrough
	local bCollided = false
	local bContinue = true
	local bBreak = false
	for _, vPos in pairs(aTargetPositions) do

		if (not bContinue) then
			return bCollided
		end

		vDir = vector.getdir(vCamPos, vPos, 1)
		vDir_Scaled = vector.scaleInPlace(vDir, -iDistance)

		nIgnore1 = g_localActorId
		iHits = Physics.RayWorldIntersection(vCamPos, vDir_Scaled, iMaxHits, ent_all, nIgnore1, nIgnore2, aRW_HitTable1, iFlags)
		if (iHits > 0) then

			local iHit = 1
			aHit = aRW_HitTable1[iHit]
			sClass = aHit.static_name
			sSurfaceName = "none"

			if (aHit.surface) then
				sSurfaceName = System.GetSurfaceTypeNameById(aHit.surface)
			end

			bSeethrough = ((sClass and IsEntitySeethrough(sClass)) or IsMaterialSeethrough(sSurfaceName))
			if (bSeethrough) then
				while (bSeethrough) do
					nIgnore1 = aHit.renderNode
					iHits_B = Physics.RayWorldIntersection(vector.add(aHit.pos, vector.scale(vDir, -1)), vDir_Scaled, iMaxHits, ent_all, nIgnore1, nIgnore2, aRW_HitTable2, iFlags)
					if (iHits_B > 0) then
						local aHit_1 = aRW_HitTable2[1]
						if (aHit_1.entity and aHit_1.entity.id == hEntity.id) then
							bCollided = true
							bContinue = false
							break
						end
					end

					-- hits exhaused
					iHit = (iHit + 1)
					if (iHit > iHits) then
						break
					end

					-- next hit
					aHit = g_HitTable[iHit]
					sClass = aHit.static_class
					sSurfaceName = "none"
					if (aHit.surface) then
						sSurfaceName = System.GetSurfaceTypeNameById(aHit.surface)
					end
					bSeethrough = ((sClass and IsEntitySeethrough(sClass)) or IsMaterialSeethrough(sSurfaceName))
				end
			else

				-- check entity collision
				if (aHit.entity and aHit.entity.id == hEntity.id) then
					bContinue = false
					bCollided = true
					break
				end
				break
			end

		end
	end

	return bCollided
end

------------------------------
--- Init
Bot.PauseCircleJump = function(self)

	local aInfo = self.CJ_INFO
	if (aInfo and aInfo.Started) then
		for _, aTask in pairs(aInfo.Actions) do
			if (aTask.End) then
				break
			end -- do NOT execute End task!
			aTask.Action(self, aTask.Key)
		end
	end

	self.CJ_INFO = {}
	self.CJ_KeyTimers = {}
end

------------------------------
--- Init
Bot.ApplyCircleJump = function(self)

	local aInfo = self.CJ_INFO
	if (aInfo and aInfo.Started) then

		if (aInfo.Active) then

			for _, aTask in pairs(aInfo.Actions) do
				if (aTask.Timer.expired()) then
					aTask.Action(self, aTask.Key, true)
					if (aTask.End) then
						break
					end
				end
			end

		end
	else

		local iAdjust = -1.650000 -- start/stop delay
		local iSpeedScale = 1.0 + (math.frandom(0, 0.5)) -- faster keys
		self.CJ_INFO = {
			Started = true,
			Active = true,

			Actions = {
				{ Timer = timernew((1.759000 + iAdjust) * iSpeedScale), Action = self.PressKey, Key = "moveforward" },
				{ Timer = timernew((1.860000 + iAdjust) * iSpeedScale), Action = self.PressKey, Key = "sprint" },
				{ Timer = timernew((1.960000 + iAdjust) * iSpeedScale), Action = self.PressKey, Key = "moveleft" },
				{ Timer = timernew((2.094000 + iAdjust) * iSpeedScale), Action = self.PressKey, Key = "jump" },
				{ Timer = timernew((2.158000 + iAdjust) * iSpeedScale), Action = self.PressKey, Key = "moveright" },
				{ Timer = timernew((2.240000 + iAdjust) * iSpeedScale), Action = self.ReleaseKey, Key = "moveleft" },
				{ Timer = timernew((2.257000 + iAdjust) * iSpeedScale), Action = self.ReleaseKey, Key = "jump" },
				{ Timer = timernew((2.323000 + iAdjust) * iSpeedScale), Action = self.ReleaseKey, Key = "moveforward" },
				{ Timer = timernew((2.662000 + iAdjust) * iSpeedScale), Action = self.ReleaseKey, Key = "moveright" },
				{ Timer = timernew((2.714000 + iAdjust) * iSpeedScale), Action = self.ReleaseKey, Key = "sprint" },

				-- Mod
				{ Timer = timernew((2.600000 + iAdjust) * iSpeedScale), Action = self.PressKey, Key = "moveforward" },
				{ Timer = timernew((3.000000 + iAdjust) * iSpeedScale), Action = self.PressKey, Key = "moveforward" },

				-- End
				{ End = true, Timer = timernew((3.000000 + iAdjust) * iSpeedScale), Action = self.PauseCircleJump, Key = "" },
			}
		}
	end

end

------------------------------
--- Init
Bot.UpdateTest = function(self)

	if (BOT_TEST_ENABLED <= 0) then
		return true -- no test
	end

	if (BOT_TEST_ACTIVE <= 0) then
		return false -- test paused
	end

	local postest={
		x = 2579,
		y = 2450,
		z = 58.7
	}
	local posbot = self:GetPos()
	if (vector.distance(postest,posbot)>3) then
		self:ApplyCircleJump()
		self:SetCameraTarget(postest)
	else
		self:PauseCircleJump()
	end

	do return end

	local x = timernew()
	local a, b = Pathfinding:GetPathStart(self:GetPos())

	if (a) then
	--	Pathfinding:Effect(a, 0.1)
		CryAction.PersistantSphere(a, 0.5, COLOR_GREEN, "", 1)
	end
	BotMainLog("b = %d, %fs", b or -1, x.diff())

	do return false end

	local start = timernew()
	Pathfinding:GetPath(g_localActor:GetPos(), {x=1,y=1,z=1},function()  end)
	BotMainLog("%fs", start.diff())
	--[[

	-------

	local geom_colltype_ray = 32768
	local geom_colltype13 = 8192
	local rwi_colltype_bit = 16
	local rwi_colltype_any = 1024
	local rwi_force_pierceable_noncoll = 4096
	local rwi_ignore_solid_back_faces = 256

	local ent_all = 287

	local iEnts = ent_all
	local iFlags = BitOR(
			BitLeftShift(BitOR(geom_colltype_ray, geom_colltype13), rwi_colltype_bit),
			BitOR(rwi_colltype_any, BitOR(rwi_force_pierceable_noncoll, rwi_ignore_solid_back_faces))
	)

	local vPos = self:GetViewCameraPos()
	local vDir = self:GetViewCameraDir()


	local iHits = Physics.RayWorldIntersection(vPos, vector.scale(vDir, 1024), 1024, ent_all, g_localActorId, nil, g_HitTable, 2684359936)

	if (iHits > 0) then
		local aHit=g_HitTable[1]
		CryAction.PersistantSphere(aHit.pos,0.1,{0,0,1},"debug",0.1)
		BotMainLog(table.tostring(aHit))
	end

	BotMainLog("iHits=%d,flags=%d",iHits,iFlags)
--]]

	local hEnemy = GetEntities(ENTITY_PLAYER, nil, function(a)
		return string.match(a:GetName(), "test_player$")
	end)[1]
	if (hEnemy) then
		BotMainLog("testing in fov: %s", g_ts(self:InFov(hEnemy)))
	end

	return false
end

------------------------------
--- Init
Bot.InFov = function(self, hEntity)

	local iFov = (BOT_FIELDOFVIEW or 120)
	return vector.withinfov(self:GetPos(), hEntity:GetPos(), self:GetViewCameraDir(), iFov)

end

------------------------------
--- Init
Bot.UpdateWallJump = function(self)

	if (not self:IsWallJumping()) then
		--BotMainLog("bad")
		return false
	end

	if (self:HasGrab()) then
		self:StopWallJump()
		return
	end

	--local iSteps = 1--self.WALLJUMPING_STEPS
	--for i = 1, 1 do
	self:ProcessWallJump()
	--end
	--BotMainLog("????")

	return true
end

------------------------------
--- Init
Bot.ProcessWallJump = function(self)
	--BotMainLog("update ====")

	if (not self:IsWallJumping()) then
		return BotMainLog("bad bad")
	end

	if (not timerexpired(self.WALLJUMPING_START, 1.5)) then
		self:SetItem("Fists")
	end

	local iPath = self.WALLJUMPING_ID
	local iCurrent = checkVar(self.WALLJUMPING_CURRENT_NODE, 0)
	if (timerexpired(self.WALLJUMPING_LAST_MOVE, self.WALLJUMPING_UPDATERATE)) then

		local vBot = self:GetPos()
		local vStart = BotNavigation:GetWallJumpStart(iPath)[1]
		if (iCurrent <= 1 and vector.distance(vBot, vStart) > 1.25 and not self:IsStuck(1) and not self:GetStaticEntitiesInFront(self:GetViewCameraPos(),self:GetViewCameraDir(),1)) then
			self.FORCED_CAM_LOOKAT = vStart
			self:SetCameraTarget(BOT_CAMERA_WALLJUMP)
			self:StartMoving(MOVE_FORWARD, vStart)
			return
		end

		iCurrent = (iCurrent + (self.WALLJUMPING_STEPS))
		self.WALLJUMPING_CURRENT_NODE = iCurrent
		if (iCurrent >= self.WALLJUMPING_MAX_NODE) then
			BotMainLog("ended")
			self:ReleaseKey(KEY_FORWARD)
			return self:StopWallJump()
		end

		local aOrientation = BotNavigation:GetWallJumpPos(iPath, iCurrent)
		if (not isArray(aOrientation)) then
			self:ReleaseKey(KEY_FORWARD)
			BotMainLog("not an array")
			return self:StopWallJump()
		end

		local vPos = aOrientation[1]
		local vDir = aOrientation[2]
		local vVel = aOrientation[3]
		local iDistance = vector.distance(vPos, vBot)

		local iType = self.WALLJUMP_SYSTEM
		if (iType == eWallJumpType_Vel) then -- Velocity based (might look more real??)
			if (vector.isvector(vVel)) then
				Bot:SetVelocity(vVel)
				self:PressKey(KEY_FORWARD)
			end

		elseif (iType == eWallJumpType_Pos) then -- Position based (looks stuttery on high ping)
			if (vector.isvector(vPos)) then
				g_localActor:SetPos(vPos)
				g_localActor:AddImpulse(-1, g_localActor:GetCenterOfMassPos(), vector.getdir(vPos, vBot, true), 999, 1)
				self:PressKey(KEY_FORWARD)
			end

			if (vector.isvector(vDir) and not self:HasTarget()) then
				--self.FORCED_CAM_LOOKAT = vDir
				--self.FORCED_CAM_SPEED = 99
				g_localActor.actor:SetSmoothDirection(vDir, 10)
			end
		end
		self.WALLJUMPING_LAST_MOVE = timerinit()

		--BotMainLog("Index = %d", iCurrent)
	else
		BotMainLog("timer")
	end

end

------------------------------
--- Init
Bot.SetWallJump = function(self, iNode)

	if (iNode == BOT_WALLJUMP_RESET) then
		return self:StopWallJump()
	end

	if (self.WALLJUMPING or iNode == self.WALLJUMPING_ID) then
		return BotMainLog("not overwriting !")
	end

	local iMaxNodes = BotNavigation:GetWallJumpNodes(iNode)

	self.WALLJUMPING = true
	self.WALLJUMPING_ID = iNode
	self.WALLJUMPING_CURRENT_NODE = 0
	self.WALLJUMPING_MAX_NODE = iMaxNodes
	self.WALLJUMPING_STEPS = 3
	self.WALLJUMPING_START = timerinit()
	self.WALLJUMPING_UPDATERATE = 0.00 --(System.GetFrameTime() * 0.005 )
	self.WALLJUMPING_LAST_MOVE = nil

    local hFists = self:GetItem(WEAPON_FISTS)
    if (hFists) then
        hFists.weapon:RequestWeaponRaised(true) -- Send Walljump Request to server
    end

	BotMainLog("new jump set")
end

------------------------------
--- Init
Bot.StopWallJump = function(self)

	self.WALLJUMPING = false
	self.WALLJUMPING_ID = nil
	self.WALLJUMPING_START = nil
	self.WALLJUMPING_CURRENT_NODE = nil
	self.WALLJUMPING_UPDATERATE = nil
	self.WALLJUMPING_LAST_MOVE = nil
	self.WALLJUMPING_STEPS = nil
	self.WALLJUMPING_END = timerinit()

	BotMainLog("jump stopped!")

end

------------------------------
--- Init
Bot.IsWallJumping = function(self)
	return (self.WALLJUMPING)
end

------------------------------
--- Init
Bot.IsEndingWallJump = function(self, iCheck)

	if (not self:IsWallJumping()) then
		return true
	end

	local iCurrent = self.WALLJUMPING_CURRENT_NODE
	local iMax = self.WALLJUMPING_MAX_NODE
	local iFinished = ((iCurrent / iMax) * 100)

	return (iFinished > checkVar(iCheck, 80))
end

------------------------------
--- Init
Bot.EnterServerCooldown = function(self)
	local hEnterTimer = ON_ENTER_SERVER_TIMER
	if (not hEnterTimer or not hEnterTimer.expired()) then
		return false
	end

	return true
end

------------------------------
--- Init
Bot.DoUpdate = function(self, isPowerStruggle, deltaTime)

	if (not g_localActor) then
		return
	end

	--------------------------------
	Pathfinding:Update()
	BotNavigation:UpdatePaintPath()
	BotChatAI:UpdateTasks()

	--------------------------------
	if (not self:UpdateTest()) then
		return
	end

	--------------------------------
	if (Config.SystemBreak == true) then
		return end

	--------------------------------
	if (BOT_ENABLED ~= 1) then
		return end

	--BotMainLog("Revive now")

	--------------------------------
	self.FRAME_TIME = System.GetFrameTime()
	self:LimitFPS()

	------
	if (not self:OkToUpdate()) then
		return
	end

	------
	if (Config.System == false) then
		return end

	------
	if (not g_localActor) then
		return end

	------
	if (not self:CanUpdate()) then
		return false
	end

	------
	if (not self:EnterServerCooldown()) then
		return
	end

	------
	if (self:IsDead(g_localActor) or self:IsSpectating(g_localActor)) then
		return self:RevivePlayer()
	end

	------
	self:UpdateKeys()
	self:UpdateMovement()
end

------------------------------
--- Init
Bot.UpdateKeys = function(self)

	local iExpire
	for i, aKey in pairs(BOT_PRESSED_KEYS) do
		iExpire = aKey[3]
		if (iExpire ~= -1 and timerexpired(aKey[4], iExpire)) then
			self:ReleaseKey(aKey[1])
		end
	end

end

------------------------------
--- Init
Bot.ResetData = function(self, bSkipTarget)

	-- dont ?
	--BotNavigation:ResetAll()

	local hOld = self:GetTarget()
	if (hOld) then
		hOld.LAST_SEEN_POS = nil
		hOld.LAST_SEEN_TIMER = nil
	end

	if (not bSkipTarget) then
		self:ClearTarget()
	end
	self:StopShooting()
	self:StopMovement()
end

------------------------------
--- Init
Bot.IsAlive = function(self, hPlayer)
	return (hPlayer.actor:GetHealth() > 0 and not self:IsSpectating(hPlayer))
end

------------------------------
--- Init
Bot.IsDead = function(self, hPlayer)
	return (hPlayer.actor:GetHealth() <= 0)
end

------------------------------
--- Init
Bot.IsFlying = function(self, hPlayer)
	return (checkVar(hPlayer, g_localActor).actor:IsFlying())
end

------------------------------
--- Init
Bot.IsSpectating = function(self, hPlayer)
	return (hPlayer.actor:GetSpectatorMode() ~= 0)
end

------------------------------
--- Init
Bot.GetViewCameraDir = function(self)
	return System.GetViewCameraDir()
end

------------------------------
--- Init
Bot.GetViewCameraPos = function(self)
	return System.GetViewCameraPos()
end

------------------------------
--- Init
Bot.SetSuit = function(self, iMode, iTime)
	if (not iMode) then
		return
	end

	self.FORCED_SUIT_TIMER = nil
	self.FORCED_SUIT_TIME = nil
	self.FORCED_SUIT_MODE = nil

	if (iTime) then
		self.FORCED_SUIT_TIMER = timerinit()
		self.FORCED_SUIT_TIME = iTime
		self.FORCED_SUIT_MODE = self:GetSuitMode()
	end

	g_localActor.actor:SetNanoSuitMode(iMode)
end

------------------------------
--- Init
Bot.GetSuitEnergy = function(self)
	return (g_localActor.actor:GetNanoSuitEnergy())
end

------------------------------
--- Init
Bot.GetSuitMode = function(self, iCheck)
	local iCurrent = g_localActor.actor:GetNanoSuitMode()
	if (iCheck) then
		return (iCurrent == iCheck)
	end

	return iCurrent
end

------------------------------
--- Init
Bot.OkToProne = function(self)

	if (self.FORCED_STANCE == STANCE_PRONE) then
		return true
	end

	if (self.STANCES_INTERRUPTED_EXCEPTION == STANCE_PRONE) then
		return true
	end

	if (self:HasTarget()) then
		return
	end

	if (self.CURRENT_MOVEMENT) then
		return
	end

	return true
end

------------------------------
--- Init
Bot.StartProne = function(self)
	BotMainLog("Proning !")

	if (self:GetStance(STANCE_PRONE)) then
		return
	end
	self:SetStance(STANCE_PRONE)
end

------------------------------
--- Init
Bot.StopProne = function(self)

	BotMainLog("stop it !")
	self:SetStance(STANCE_STAND)
end

------------------------------
--- Init
Bot.OkToSprint = function(self)

	local bSpeed, bCloak =
	self:GetSuitMode(NANOMODE_SPEED), self:GetSuitMode(NANOMODE_CLOAK)

	if (bCloak) then
		return false
	end

	local bIndoors = self:IsIndoors()
	local bNarrow = BotNavigation:IsPathNarrow()
	if (bIndoors) then
		-- TODO: add check if theres a roof (one thats low..)
		if (not self:IsUnderground() and RWI_GetPos(self:GetViewCameraPos(), { x = 0, y = 0, z = 2.5 })) then
			if (bNarrow) then
				return false
			end
		end
	end

	-- dont sprint going up stairs !??!
	if (self:PathIsElevating(3) and bNarrow) then
		return false, BotMainLog("No sprint on eleating PATH")
	end

	if (not bSpeed) then
		return true --(not bIndoors) -- ??? WHAT IF OBSTACE ??? COME BACK TO THIS
	--elseif (bIndoors) then
	--	return false
	end

	local iEnergy = self:GetSuitEnergy()
	--BotMainLog("energy=%f",iEnergy)

	if (iEnergy >= 25) then
		if (timerexpired(self.BOT_SPRINT_PAUSE, 5)) then
			if (self:StartedOrEndingPath(3)) then
				return false
			end
			if (bIndoors) then
				return false
			end
			return true
		end
	else
		self.BOT_SPRINT_PAUSE = timerinit()
	end

	return false
end

------------------------------
--- Init
Bot.RevivePlayer = function(self, hPlayer)

	local idPlayer = checkVar(checkArray(hPlayer, {}).id, g_localActorId)
	if (not timerexpired(self.REVIVE_TIMERS[idPlayer], 1)) then
		return
	end

	BotMainLog(0,"Reviving %s..",tostring(idPlayer))
	g_gameRules.server:RequestRevive(idPlayer)
	g_gameRules.game:ChangeSpectatorMode(idPlayer, 0, NULL_ENTITY)

	self.REVIVE_TIMERS[idPlayer] = timerinit()
end

------------------------------
--- Init
Bot.StartSprinting = function(self)
	self:PressKey(KEY_SPRINT)
	self.FORCED_SPRINT = false
end

------------------------------
--- Init
Bot.StopSprinting = function(self)
	self:ReleaseKey(KEY_SPRINT)
end

------------------------------
--- Init
Bot.OkToJump = function(self)
	local bIndoors = self:IsIndoors()
	if (bIndoors) then
		return false -- EXRIMENTAL!!
	end

	return true
end

------------------------------
--- Init
Bot.StartJump = function(self, iSuit)

	local hTimer = self.LAST_JUMP_TIMER
	if (hTimer and not timerexpired(self.LAST_JUMP_TIMER, 0.35)) then
		return
	end

	if (iSuit) then
		self:SetSuit(iSuit, 0.15)
	end

	self:PressKey(KEY_JUMP)
	g_localActor.actor:RequestJump()
	self.LAST_JUMP_TIMER = timerinit()

	BotMainLog("jumping")
end

------------------------------
--- Init
Bot.StopJump = function(self)
	self.LAST_JUMP_TIMER = nil
	self:ReleaseKey(KEY_JUMP)
end

------------------------------
--- Init
Bot.GetRayHitInfo = function(self, eIdReturnType, iDist)

	----------------
	local vPos = self:GetViewCameraPos()
	local vDir = self:GetViewCameraDir()

	----------------
	local iDistance = checkVar(iDist, 5)

	----------------
	local iHits = Physics.RayWorldIntersection(vPos, vector.scale(vDir, iDistance), iDistance, ent_all - ent_living, g_localActorId, nil, g_HitTable);
	local aHits = g_HitTable[1];
	if (iHits and iHits > 0 and aHits) then

		if (eIdReturnType == RH_GET_ENTITY) then
			return aHits.entity
		elseif (eIdReturnType == RH_GET_POS) then
			return aHits.pos
		elseif (eIdReturnType == RH_GET_ALL) then
			return aHits
		end
	end

	return
end

------------------------------
--- Init
Bot.GetObstacle = function(self, vSource, vDir, iDist)

	local iDistance = math.limit(checkNumber(iDist, 10), 1, BOT_RAYWORLD_MAXDIST)
	local vDirection = vector.scale(vDir, iDistance)
	local iHits = Physics.RayWorldIntersection(vSource, vDirection, iDistance, ent_all - ent_living, g_localActorId, nil, g_HitTable)
	if (iHits == 0) then
		return false, nil
	end

	local aHit = g_HitTable[1]
	return true, aHit.entity
end

------------------------------
--- Init
Bot.IsWater = function(self, vPos)
	local iWaterLevel = CryAction.GetWaterInfo(vPos)
	if (not iWaterLevel) then
		return false
	end

	return (iWaterLevel > vPos.z)
end

------------------------------
--- Init
Bot.IsWater_Right = function(self, iCheck)

	local iDist = checkVar(iCheck, 3)
	local vDir = vector.rotaten(self:GetDir(), 1)

	local vPos = self:GetPos()
	vPos.x = (vPos.x + (vDir.x * iDist))
	vPos.y = (vPos.y + (vDir.y * iDist))
	vPos.z = (vPos.z + (vDir.z * iDist)) - 1

	local bWater = self:IsWater(vPos)
	if (bWater) then
	--	Particle.SpawnEffect("explosions.flare.a", vPos, g_Vectors.up, 0.1)
	end

	return bWater
end

------------------------------
--- Init
Bot.IsWater_Left = function(self, iCheck)

	local iDist = checkVar(iCheck, 3)
	local vDir = vector.rotaten(self:GetDir(), 3)

	local vPos = self:GetPos()
	vPos.x = (vPos.x + (vDir.x * iDist))
	vPos.y = (vPos.y + (vDir.y * iDist))
	vPos.z = (vPos.z + (vDir.z * iDist)) - 1

	local bWater = self:IsWater(vPos)
	if (bWater) then
	--	Particle.SpawnEffect("explosions.flare.a", vPos, g_Vectors.up, 0.1)
	end

	return bWater
end

------------------------------
--- Init
Bot.GetObstacle_Right = function(self, iDist)
	local vSource = self:GetBone_Pos("Bip01 Pelvis")
	local vDir = vector.right(self:GetViewCameraDir())
	return (self:GetObstacle(vSource, vDir, iDist))
end

------------------------------
--- Init
Bot.GetObstacle_Left = function(self, iDist)

	local vSource = self:GetBone_Pos("Bip01 Pelvis")
	local vDir = vector.left(self:GetViewCameraDir())
	return (self:GetObstacle(vSource, vDir, iDist))
end

------------------------------
--- Init
Bot.GetJumpableObstacle = function(self)

	local vDir_Pelvis = self:GetDir() --self:GetBone_Dir("Bip01 Pelvis")
	local vPos_Pelvis = vector.modify(self:GetBone_Pos("Bip01 Pelvis"), "z", -0.1, true)
	local bObstacle_P, hObstacle_P = self:GetObstacle(vPos_Pelvis, vDir_Pelvis, 0.5)
	if (not bObstacle_P) then
		vPos_Pelvis = vector.modify(self:GetBone_Pos("Bip01 Pelvis"), "z", -0.2, true)
		bObstacle_P, hObstacle_P = self:GetObstacle(vPos_Pelvis, vDir_Pelvis, 0.5)
	end

	local vDir_Head = self:GetDir() --self:GetBone_Dir("Bip01 Head")
	local vPos_Head = self:GetBone_Pos(BONE_HEAD)
	local bObstacle_H, hObstacle_H = self:GetObstacle(vPos_Head, vDir_Head, 0.5)

	local bJumpable = (bObstacle_P and not bObstacle_H) and (not hObstacle_P or (hObstacle_P.actor == nil))
	return bJumpable
end

------------------------------
--- Init
Bot.GetCrouchableObstacle = function(self)

	local vDir_Pelvis = self:GetDir()
	local vPos_Pelvis = vector.modify(self:GetBone_Pos("Bip01 Pelvis"), "z", -0.1, true)
	local bObstacle_P, hObstacle_P = self:GetObstacle(vPos_Pelvis, vDir_Pelvis, 0.5)
	if (not bObstacle_P) then
		vPos_Pelvis = vector.modify(self:GetBone_Pos("Bip01 Pelvis"), "z", -0.2, true)
		bObstacle_P, hObstacle_P = self:GetObstacle(vPos_Pelvis, vDir_Pelvis, 0.5)
	end

	local vDir_Head = self:GetDir() --self:GetBone_Dir("Bip01 Head")
	local vPos_Head = self:GetBone_Pos(BONE_HEAD)
	local bObstacle_H, hObstacle_H = self:GetObstacle(vPos_Head, vDir_Head, 0.5)

	local bCrouchable = (not bObstacle_P and bObstacle_H) and (not hObstacle_P or (hObstacle_P.actor == nil))
	return bCrouchable
end

------------------------------
--- Init
Bot.UpdateIndoorsVar = function(self)
	local vCurr = self:GetPos()
	if (System.IsPointIndoors(vCurr)) then
		self.BOT_INDOORS_TIME = (self.BOT_INDOORS_TIME + self.FRAME_TIME)
	else
		self.BOT_INDOORS_TIME = 0.0
	end
end

------------------------------
--- Init
Bot.SwitchVehicleSeat = function(self, hVehicle, iSeatID)

	local iCurrentSeat = self:GetSeatId()
	if (iCurrentSeat == iSeatID) then
		return
	end

	if (not self.ATTEMPT_ENTER_SEAT_TIMER) then
		self.ATTEMPT_ENTER_SEAT_TIMER = timernew(3)
	end
	hVehicle.vehicle:OnUsed(g_localActorId, 1100 + iSeatID)
end

------------------------------
--- Init
Bot.EnterVehicle = function(self, hVehicle)

	local iBreakCase = eMovInterrupt_EnterUber
	if (not hVehicle) then
		return
	end

	--hVehicle.vehicle:EnterVehicle(g_localActorId, 1, true)
	hVehicle.vehicle:OnUsed(g_localActorId, 1100 + SEATID_DRIVER)
	self:PressKey(KEY_INTERACT)

	-- FREE CAMERA
	self:ContinueCamMovement(iBreakCase)

	local vLook = vector.modifyz(hVehicle:GetPos(), 1)
	self.FORCED_CAM_LOOKAT = vLook
	self:SetCameraTarget(vLook) -- Vehicle

	-- LOCK CAMERA
	self:InterruptCamera(iBreakCase, 1)
	self:InterruptMovement(iBreakCase, 1)

	-- Set timer
	self.ENTER_VEHICLE_TIMER = timerinit()
end

------------------------------
--- Init
Bot.LeaveVehicle = function(self, iRequest)

	local hVehicle = self:GetVehicle()
	local iSeat = self:GetSeatId()
	if (hVehicle) then
		hVehicle.STUCK_TRIED_BACKUP = nil
		hVehicle.STUCK_TRIED_BOOST = nil
		hVehicle.EXIT_TIMER = timerinit()
		hVehicle.vehicle:OnUsed(g_localActor.id, (1100 + iSeat))
		BotMainLog("We're on seat" ..iSeat)
	end

	-- reset timer
	self.ATTEMPT_ENTER_SEAT_TIMER = nil

	-- debug
	if (iRequest) then
		BotMainLog("Requestor Code was %d", checkNumber(iRequest, -1))
	end

	BotMainLog(tracebackEx())
	BotMainLog("Leaving vehicle NOW")
	self:StopMovement() -- clear all keys
	self:PressKey(KEY_INTERACT, 0.1)
end

------------------------------
--- Init
Bot.GetSeatId = function(self)

	local iSeat = 0
	local hVehicle = self:GetVehicle()
	if (not hVehicle) then
		return iSeat
	end

	for i, aSeat in pairs(hVehicle.Seats) do
		if (aSeat:GetPassengerId() == g_localActorId) then
			return (aSeat.seatId)
		end
	end

	return iSeat
end

------------------------------
--- Init
Bot.IsDriving = function(self)
	return (self.DRIVING_VEHICLE)
end

------------------------------
--- Init
Bot.IsDriver = function(self)
	return (self.DRIVING_VEHICLE_ISDRIVER)
end

------------------------------
--- Init
Bot.UpdateVehicleShooting = function(self)

	local hTarget = self:GetTarget()
	local hVehicle = self:GetVehicle()

	if (not hTarget) then
		return
	else
		local hCurrent = (hTarget.inventory:GetCurrentItem())
		if (hCurrent and hCurrent.class == WEAPON_RPG) then
			return self:LeaveVehicle(eExitVehicle_RPGAttack)
		end
	end

	if (not hVehicle) then
		return
	end

	-- !!FIXME: enable after finding proper method to update vehicle cam dir
	--do return false end

	local aWeapons = self:GetVehicleWeapons(hVehicle)
	if (not isArray(aWeapons)) then
		return
	end

	local vTarget = hTarget:GetPos()
	local iWeapons = table.count(aWeapons)
	local iOk = 0
	for i, hWeapon in pairs(aWeapons) do
		if (hWeapon and self:IsVehicleWeaponOk(hVehicle, hWeapon)) then
			iOk = iOk + 1

			-- does nothing
			--hWeapon:SetDirectionVector(vTargetDir)
			self:StartFire_Vehicle(hWeapon)
		end
	end

	if (iOk == 0) then
		self:StopFire_Vehicle()
		return false
	end

	-- !! trash, need to set dir directly somewhere
	self:SetVehicleViewDir(hTarget)
	return true
end

------------------------------
--- Init
Bot.SetVehicleViewDir = function(self, hTarget)

	----
	local vCamPos = self:GetViewCameraPos()
	local vCamDir = self:GetViewCameraDir()
	local vTargetPos = hTarget:GetPos()
	local vTargetDir = vector.getdir(vCamPos, vTargetPos, 1, -1)

	----
	local yawCameraDir, pitchCameraDir = vector.getyawpitch(vCamDir)
	local yawToTarget, pitchToTarget = vector.getyawpitch(vTargetDir)
	local yawAdjustment = yawCameraDir - yawToTarget
	local pitchAdjustment = pitchCameraDir - pitchToTarget

	----
	--BotMainLog("Cam Y: %f, Cam P: %f", yawCameraDir, pitchCameraDir)
	--BotMainLog("Tgt Y: %f, Tgt P: %f", yawToTarget, pitchToTarget)
	--BotMainLog("Adj Y: %f, Adj P: %f", yawAdjustment, pitchAdjustment)

	----
	local iSpeedScale = checkVar(BOT_VEHICLE_CAMERASPEED, 2.5)
	if (self.FORCED_VEHICLE_CAM_SPEED) then
		iSpeedScale = self.FORCED_VEHICLE_CAM_SPEED
	end
	yawAdjustment = (yawAdjustment * iSpeedScale)
	pitchAdjustment = (pitchAdjustment * iSpeedScale)

	----
	g_localActor.actor:SimulateInput(KEY_V_ROTATEYAW, 1, yawAdjustment)
	g_localActor.actor:SimulateInput(KEY_V_ROTATEPITCH, 1, pitchAdjustment)

	----
	self.FORCED_VEHICLE_CAM_SPEED = nil

end

------------------------------
--- Init
Bot.IsVehicleWeaponOk = function(self, hVehicle, hWeapon)

	if (not hVehicle or not hWeapon) then
		return
	end

	local sAmmo = hWeapon.weapon:GetAmmoType()
	if (not sAmmo) then
		return
	end

	--local iAmmo = hWeapon.weapon:GetAmmoCount(sAmmo)
	local iClip = hWeapon.weapon:GetClipSize(sAmmo)
	--local iVehicleAmmo = hVehicle.vehicle:GetAmmoCount(sAmmo)
	local iCapacity = hVehicle.inventory:GetAmmoCapacity(sAmmo)
	local iAmmo = hVehicle.inventory:GetAmmoCount(sAmmo)

	if (iCapacity <= 0) then
		BotMainLog("No clip size ?")
		return true
	end

	BotMainLog("check weapon %s %d", hWeapon.class, iAmmo)
	return (iAmmo > 0)
end
------------------------------
--- Init
Bot.StartFire_Vehicle = function(self, hWeapon)

	if (not hWeapon) then
		return
	end

	self.VEHICLE_FIRING = timerinit()
	self.VEHICLE_FIRING_WEAPONS = checkArray(self.VEHICLE_FIRING_WEAPONS, {})
	self.VEHICLE_FIRING_WEAPONS[hWeapon.id] = hWeapon
	hWeapon.weapon:RequestStartFire()

end

------------------------------
--- Init
Bot.StopFire_Vehicle = function(self)

	self.VEHICLE_FIRING = nil
	local aActive = self.VEHICLE_FIRING_WEAPONS
	if (not isArray(aActive)) then
		return
	end

	for idWeapon, hWeapon in pairs(aActive) do
		hWeapon.weapon:RequestStopFire()
	end

	--self.VEHICLE_FIRING_WEAPONS = {}
end


------------------------------
--- Init
Bot.UpdateVehicleStats = function(self, hVehicle)
	if (not hVehicle) then
		return
	end

	if (not hVehicle.INITIALIZED) then

		hVehicle.IsTank = function()
			return (string.matchex(hVehicle.class, unpack(VEHICLE_TANKS)))
		end
		hVehicle.IsSmall = function()
			return (string.matchex(hVehicle.class, VEHICLE_LTV, VEHICLE_CIV))
		end

	end

	hVehicle.INITIALIZED = true
end


------------------------------
--- Init
Bot.UpdateDriving = function(self)

	local hVehicle = self:GetVehicle()
	if (not hVehicle or not self:IsDriving()) then
		return
	else
		self:UpdateVehicleStats(hVehicle)
	end

	if (self:HasTarget()) then
		return
	end

	if (not timerexpired(hVehicle.EXIT_TIMER, 0.1)) then
		return
	end

	if (hVehicle.vehicle:IsFlipped()) then
		self:LeaveVehicle(eExitVehicle_Flipped)
		return
	end

	local hDriver = hVehicle:GetDriverId()
	if (hDriver == nil) then

		local hSeatSwitchTimer = self.ATTEMPT_ENTER_SEAT_TIMER
		if (not hSeatSwitchTimer) then
			self:SwitchVehicleSeat(hVehicle, SEATID_DRIVER)
		elseif (hSeatSwitchTimer.expired()) then -- server isnt allowing us to switch the seat!
			hVehicle.FAILED_SWITCH_DRIVERSEAT_TIMER = timernew(120)
			return self:LeaveVehicle(eExitVehicle_DriverSeatBlocked)
		end
	end

	local bStay
	local vPos = self:GetPos()
	local iSpeed = hVehicle:GetSpeed()
	local vVehicle = hVehicle:GetPos()
	local hTarget = self:GetTarget()
	local vGoal = BotNavigation:GetPathGoal()
	local bLeaveForTarget = (AIEvent("LeaveVehicleForTarget", hVehicle, vGoal) == AIEVENT_OK)
	if (not bLeaveForTarget and vGoal and AIEvent("IsCapturing")) then

		BotMainLog("STAY! CAPTURING, GOOD VEHICLE !!")
		self:InterruptMovement(eMovInterrupt_CaptureInVehicle)
		hVehicle.STUCK_TIME = 0
		return
	end

	if (vGoal and not hTarget) then

		-- > AIEVENT_OK, Ok, leave
		-- > AIEVENT_ABORT, Bad, Stay!

		local iDistance = vector.distance(vGoal, vVehicle)
		if (iDistance < 25 and bLeaveForTarget) then
			self:LeaveVehicle(eExitVehicle_NearTarget)
			return
		end
	end

	if (BotAI.CallEvent("ProcessInVehicle", hVehicle) == AIEVENT_ABORT) then
		self:InterruptMovement(eMovInterrupt_HopInMyVan, 1)
		BotMainLog("AI Decision to STOP and WAITs")
		return
	else
		self:ContinueMovement(eMovInterrupt_HopInMyVan)
	end

	if (BotNavigation:IsPathNarrow()) then
		BotMainLog("ITS NARROW AS FUDGE")
		return self:LeaveVehicle(eExitVehicle_NarrowPath)
	end

	self:UpdateVehicleStuck(hVehicle)

	local bStaticInFront = self:GetStaticEntitiesInFront(vector.modifyz(vVehicle, 1), hVehicle:GetDirectionVector(), 5, hVehicle.id)
	local bInterrupted = (not self:GetMovementInterruption(eMovInterrupt_None))

	-- bad
	if (not bInterrupted) then
		if ((bStaticInFront or hVehicle:IsStuck()) and not self:IsVehicleFiring()) then

			hVehicle.STUCK_TRIGGER_TIME = checkVar(hVehicle.STUCK_TRIGGER_TIME, math.random(2, 5))

			if (bStaticInFront or (hVehicle.STUCK_TRIED_BOOST and hVehicle.STUCK_TRIED_BOOST.expired())) then

				if (hVehicle.STUCK_TRIED_BACKUP and hVehicle.STUCK_TRIED_BACKUP.expired()) then
					hVehicle.FATAL_STUCK_TIMER = timerinit()
					self:LeaveVehicle(eExitVehicle_FatalStuck)
					return
				else

					self.VEHICLE_ACTION_GOBACK = true
					BotMainLog("going BACK in VEHICLE !!")
					hVehicle.STUCK_TRIED_BACKUP = checkVar(hVehicle.STUCK_TRIED_BACKUP, timernew((bStaticInFront and 1 or 4)))
				end
			else
				hVehicle.STUCK_TRIED_BOOST = checkVar(hVehicle.STUCK_TRIED_BOOST, timernew(getrandom(3, 5)))
				self:PressKey(KEY_VEHICLE_BOOST, 1)
			end
			return
		else
			hVehicle.STUCK_TRIED_BACKUP = nil
			hVehicle.STUCK_TRIGGER_TIME = nil
		end
	end

	if (not self:IsUnderground(vPos) and  bLeaveForTarget) then
		local iCountToIndoors = checkNumber(BotNavigation:GetNodeCountToIndoors(true), 999)
		bStay = AIEvent("OkInVehicle", hVehicle)
		if (bStay == 0xDEAD) then
			bStay = true
		end
		if (bStay ~= true or ((iCountToIndoors < 3))) then
			BotMainLog("bStay = %s OR %d < 3 AND %s", tostring(bStay~=true), iCountToIndoors, tostring(BotNavigation:IsCurrentNodeIndoors(true)))
			self:LeaveVehicle(eExitVehicle_AIDecision)
			return
		end
	end

	BotMainLog("%f speed", iSpeed)
	if (iSpeed > 8 and self.VEHICLE_ACTION_STEER and (self.VEHICLE_ACTION_SHARPTURN or iSpeed >= 8)) then
		self:PressKey(KEY_VEHICLE_BRAKE, 0.1)
		self.VEHICLE_ACTION_STEER = nil
		self.VEHICLE_ACTION_SHARPTURN = nil
		BotMainLog("short brake !!")
	end
end

------------------------------
--- Init
Bot.UpdateVehicleVar = function(self)

	local hVehicle = self:GetVehicle()
	if (hVehicle) then
		self.DRIVING_VEHICLE = true
		self.VEHICLE_TYPE = hVehicle.vehicle:GetMovementType()
		self.VEHICLE_DIRECTION = hVehicle:GetDirectionVector()
		self.DRIVING_VEHICLE_ISDRIVER = (hVehicle:GetDriverId() == g_localActorId)
	else
		self.DRIVING_VEHICLE = nil
		self.VEHICLE_TYPE = nil
		self.VEHICLE_DIRECTION = nil
		self.DRIVING_VEHICLE_ISDRIVER = nil
	end

end

------------------------------
--- Init
Bot.IsVehicleFiring = function(self)
	return (not timerexpired(self.VEHICLE_FIRING))
end

------------------------------
--- Init
Bot.UpdateVehicleStuck = function(self, hVehicle)

	local hVehicle = checkVar(hVehicle, self:GetVehicle())
	if (not hVehicle) then
		return
	end

	local iSpeed = hVehicle:GetSpeed()
	if (iSpeed < 1) then
		hVehicle.STUCK_TIME = (hVehicle.STUCK_TIME or 0) + System.GetFrameTime()
	else
		hVehicle.STUCK_TIME = 0
	end

	--if (not hVehicle.IsStuck) then
		hVehicle.IsStuck = function(self, iTime)
			local bStuck = (checkNumber(hVehicle.STUCK_TIME, 0) >= checkVar(iTime, checkNumber(hVehicle.STUCK_TRIGGER_TIME, 5)))
			return (bStuck)
		end
	--end
end

------------------------------
--- Init
Bot.GetStaticEntitiesInFront = function(self, vPos, vDir, iDist, idIgnore)

	local iDistance = math.limit(checkNumber(iDist, 1), 1, BOT_RAYWORLD_MAXDIST)
	local iHits = Physics.RayWorldIntersection(vPos, vector.scale(vDir, iDistance), iDistance, ent_all - ent_living - ent_rigid, g_localActorId, nil, g_HitTable)
	if (iHits == 0) then
		return false
	end

	for i = 1, iHits do
		local aHit = g_HitTable[i]
		if (aHit) then
			local hHit = aHit.entity
			if (aHit.foliage or (hHit and (hHit.id == idIgnore or hHit.id == g_localActorId))) then
				iHits = (iHits - 1)
			end
		end
	end
	return (iHits > 0)
end

------------------------------
--- Init
Bot.GetEntityInFront = function(self, vPos, vDir, iDist, idEntity)

	local iDistance = math.limit(checkNumber(iDist, 1), 1, BOT_RAYWORLD_MAXDIST)
	local iHits = Physics.RayWorldIntersection(vPos, vector.scale(vDir, iDistance), iDistance, ent_all, g_localActorId, nil, g_HitTable)
	if (iHits == 0) then
		return false--, BotMainLog("no collision")
	end

	local aHit = g_HitTable[1]
	if (aHit) then
		local hHit = aHit.entity
		if (hHit) then
			--BotMainLog("collided: %s (%s==%s,%s)", tostring(hHit:GetName()),tostring(hHit.id),tostring(idEntity), tostring(idEntity==hHit.id))
			return (hHit.id == idEntity)
		end
	end
	return false
end

------------------------------
--- Init
Bot.UpdateTerrainVar = function(self)

	local vPos = g_localActor:GetPos()
	local iTerrain = System.GetTerrainElevation(vPos)
	local iUnder = ((vPos.z + 0.25) - checkNumber(iTerrain, -999999))
	if (iUnder < 0) then
		self.BOT_SUBTERRAIN_TIME = (self.BOT_SUBTERRAIN_TIME + self.FRAME_TIME)
		--BotLog("sub terrain %f",iUnder)
	else
		self.BOT_SUBTERRAIN_TIME = 0.0
		--BotLog("not")
	end

end

------------------------------
--- Init
Bot.UpdateStuckVar = function(self)

	local iSpeed = self:GetSpeed()
	local vCurr = self:GetPos()
	local vLast = self.BOT_LAST_POSITON

	if (vLast) then
		local iDistance = vector.distance(vCurr, vLast)
		if (self:GetMovementInterruption(eMovInterrupt_None) and (iDistance < 0.15 or iSpeed <= 0.1)) then
			self.BOT_STUCK_TIME = self.BOT_STUCK_TIME + System.GetFrameTime()
			--BotMainLog("stuck time: %f",self.BOT_STUCK_TIME)
		else
			self.BOT_STUCK_TIME = 0.0
		end
	end

	self.BOT_LAST_POSITON = vCurr
end

------------------------------
--- Init
Bot.IsStuck = function(self, iTime)
	return (self.BOT_STUCK_TIME >= checkNumber(iTime, self.BOT_DEFAULT_STUCK_TIME))
end

------------------------------
--- Init
Bot.IsUnderwater = function(self, vCheck, iThreshold)

	local vPos = checkVar(vCheck, self:GetPos())
	local iWater = CryAction.GetWaterInfo(vPos)
	if (not iWater) then
		return false
	end

	local iUnderwater = (iWater - vPos.z)
	if (iUnderwater < 0) then
		return false--, BotMainLog("Not underwate!!!!")
	end

	--BotMainLog("> %f",vPos.z - iWater)
	return (iUnderwater > checkVar(iThreshold, 1))
end

------------------------------
--- Init
Bot.IsSwimming = function(self)
	return (self:GetStance(STANCE_SWIM))
end

------------------------------
--- Init
Bot.IsDiving = function(self)
	return (self:IsSwimming() and self:IsUnderwater())
end

------------------------------
--- Init
Bot.HasTarget = function(self)
	return (self:GetTarget() ~= nil)
end

------------------------------
--- Init
Bot.GetTarget = function(self)
	return (self.CURRENT_TARGET)
end

------------------------------
--- Init
Bot.GetTarget_Near = function(self, iCheck)
	local aTargets = self:CheckForTargets(checkVar(iCheck, 15), true)
	return (table.count(aTargets) > 0)
end

------------------------------
--- Init
Bot.GetTargetId = function(self)
	return (self.CURRENT_TARGETID)
end

------------------------------
--- Init
Bot.SetTarget = function(self, hEntity)

	if (hEntity == NULL_ENTITY) then
		self.CURRENT_TARGETID = nil
		self.CURRENT_TARGET = nil
		self.C4_GOTO_TARGET = nil
		self.C4_GOTO_TARGET_DISTANCE = nil

		AIEvent("OnTargetLost")
		return
	elseif (not hEntity) then
		return
	end

	local hTarget = self.LAST_SEEN_TARGET
	if (hTarget) then
		hTarget.LAST_SEEN_POS = nil
	end

	-- !!Fixme: experimental
	BotMainLog("New target acquired, reset grab")
	self:ResetGrab()
	------

	--self:SetTarget(NULL_ENTITY)
	self.CURRENT_TARGETID = hEntity.id
	self.CURRENT_TARGET = hEntity
	self.LAST_SEEN_TARGET = nil

	-----
	self.C4_GOTO_TARGET = nil
	self.C4_GOTO_TARGET_DISTANCE = nil

	-----
	hEntity.LAST_SEEN_POS = nil
	hEntity.LAST_SEEN_TIMER = nil

	AIEvent("OnTargetAcquired", hEntity)
end

------------------------------
--- Init
Bot.GetTeam = function(self, idTarget)
	return g_gameRules.game:GetTeam(checkVar(idTarget, g_localActorId))
end

------------------------------
--- Init
Bot.IsTarget_SameTeam = function(self, hTarget)

	---------------------------
	if (g_gameRules.class == "InstantAction") then
		return false
	end

	local hCheck = GetEntity(hTarget)
	if (not hCheck) then
		return false, BotMainLog("bad team identifier %s", tostring(hTarget))
	end

	local iMyTeam = self:GetTeam(g_localActorId)
	local iEntTeam = self:GetTeam(hCheck.id)

	local bSameTeam = (iMyTeam == iEntTeam)
	return (bSameTeam)
end

------------------------------
--- Init
Bot.IsTarget_Reachable = function(self, hTarget)

	local vTarget = self:GetPos_Head(hTarget)
	local hVehicle = self:GetVehicle(hTarget)
	local iDistance = self:GetDistance(vTarget)

	local bVisible = (self:IsVisible_Entity(hTarget) and iDistance < 8)
	if (not bVisible and hVehicle) then
		bVisible = (self:IsVisible_Entity(hVehicle))
	end
	return (bVisible)
end
------------------------------
--- Init
Bot.IsTargetOk = function(self, hTarget, bSkipVisibility)

	-----
	if (not hTarget) then
		return false end

	---------------------------
	local sTarget = hTarget:GetName()
	local bSameTeam = self:IsTarget_SameTeam(hTarget)

	-----
	if (g_gameRules.class ~= GAMERULES_INSTANTACTION and bSameTeam) then
		return false end

	-----
	if (not timerexpired(self.FLASHBANG_BLIND_TIMER, 2.5)) then
		return false end

	-----
	if (not self:IsAlive(hTarget)) then
		return false end

	-----
	local hVehicle = self:GetVehicle(hTarget)
	if (hVehicle) then
		if (hVehicle.vehicle:GetMovementType() == eVehicleType_Air) then
			return false
		end
	end

	-----
	return true
end

------------------------------
--- Init
Bot.IsLoud = function(self, hTarget)

	if (hTarget.actor:GetLinkedVehicleId()) then
		return true
	end

	return false
end

------------------------------
--- Init
Bot.ValidateTarget = function(self, hTarget, bIgnoreAng, bSkipVisibility)

	-----
	local vPos = self:GetPos()
	local vTarget = self:GetPos(hTarget)
	local iDistance = vector.distance(vPos, vTarget)
	local bBotHostile = self:IsHostile()

	if (not bBotHostile) then
		return false end

	-----
	local bOk = self:IsTargetOk(hTarget, bSkipVisibility)
	if (not bOk) then
		return false
	end

	-----
	if (iDistance < 6 and self:IsEnt_Behind(hTarget)) then
		return true
	end

	-----

	-----
	if (not self:IsLoud(hTarget) and BOT_USE_FIELDOFVIEW > 0 and iDistance > 20 and (timerexpired(hTarget.LAST_FIRE_TIMER, 10) and not self:IsEntityTagged(hTarget.id))) then
		if (not self:InFov(hTarget)) then
			BotMainLog("fov BAD")
			--throw_error()
			return false
		end
	end

	-----
	if (not AIEventGet("ValidateTarget", AIGET_OK, hTarget)) then
		return
	end

	-----
	return true
end

------------------------------
--- Init
Bot.GetTargetMaxDistance = function(self, hPlayer)

	local vPos = self:GetPos()
	local vPlayer = hPlayer:GetPos()
	local vPlayerLookAt = (hPlayer:GetBoneDir(BONE_HEAD))
	local iDistance = (vector.distance(vPos, vPlayer))
	if (iDistance < 80) then
		return 80
	end

	local vDirToPlayer = vector.getdir(vPlayer, vPos, 1, -1)
	local iDotProduct = vector.dot(vDirToPlayer, vPlayerLookAt)

	local bInView = (iDotProduct > 0.25)
	print("Dot Product:", iDotProduct)

	-- Interpret the dot product value
	if iDotProduct > 0.9 then
		--BotMainLog("Target is looking almost directly at the player.")
	elseif iDotProduct > 0 then
		--BotMainLog("Target is looking somewhat towards the player.")
	elseif iDotProduct > -0.9 then
		--BotMainLog("Target is looking somewhat away from the player.")
	else
		--BotMainLog("Target is looking almost directly away from the player.")
	end

	local hItem = (hPlayer.inventory:GetCurrentItem())
	local bHasSniper = (self:HasSniper())
	if (hItem) then
		local bCamper = string.matchex(hItem.class, WEAPON_GAUSS, WEAPON_DSG)
		if (bCamper) then
			if (bInView) then
				if (not timerexpired(hPlayer.LAST_FIRE_TIMER, 30)) then
					return (bHasSniper and 600 or 200)
				end
				return (bHasSniper and 350 or 150)
			end
		end
	end

	if (not timerexpired(hPlayer.LAST_FIRE_TIMER, 30)) then
		return (bHasSniper and 200 or 175)
	end

	if (bInView) then
		return (bHasSniper and 210 or 175)
	end
	return (bHasSniper and 150 or 125)
end

------------------------------
--- Init
Bot.HasSniper = function(self)
	return (self:HasItem(WEAPON_DSG) or self:HasItem(WEAPON_GAUSS))
end

------------------------------
--- Init
Bot.GotCamped = function(self)

	local aInfo = self.CAMP_INFO
	if (not aInfo) then
		return false
	end

	return (not aInfo.Timer.expired())
end

------------------------------
--- Init
Bot.CheckForTargets = function(self, iRadius, bSkipVisibility)

	local aPlayers = GetPlayers()
	if (table.empty(aPlayers)) then
		return
	end

	local bIgnoreAng = (self:HasTarget())

	local iMaxDistance = 0--self:GetTargetMaxDistance() -- !!FIXME,
	local vPos = self:GetPos()
	local aBest = { nil, checkVar(iRadius, -1) }
	local vPlayer, iDistance

	for i, hPlayer in pairs(aPlayers) do
		if (hPlayer.id ~= g_localActorId) then
			vPlayer = hPlayer:GetPos()
			iDistance = vector.distance(vPlayer, vPos)
			iMaxDistance = self:GetTargetMaxDistance(hPlayer)
			if (iDistance < iMaxDistance) then
				--BotMainLog("dist ok")
				if (iDistance < aBest[2] or aBest[2] == -1) then
					if (bSkipVisibility or self:IsVisible_Entity(hPlayer)) then
						--BotMainLog("visible ok")
						if (self:ValidateTarget(hPlayer, bIgnoreAng, bSkipVisibility)) then
							aBest = { hPlayer, iDistance }
						end
					end
				end
			end
		end
	end

	return unpack(aBest)
end

------------------------------
--- Init
Bot.GetStance = function(self, iCheck, hPlayer)
	local iStance = checkVar(hPlayer, g_localActor).actorStats.stance
	if (iCheck) then
		return (iStance == iCheck)
	end

	return iStance
end

------------------------------
--- Init
Bot.GetStanceKey = function(self, hPlayer)
	local iStance = checkVar(hPlayer, g_localActor).actorStats.stance
	local aKeys = {
		[STANCE_CROUCH] = KEY_CROUCH,
		[STANCE_PRONE] = KEY_PRONE,
	}

	return aKeys[iStance]
end

------------------------------
--- Init
Bot.SetStance = function(self, iStance, iTime)

	if (not self:GetStanceInterruption(eMovInterrupt_None, iStance)) then
		return BotMainLog("interrupted *********************************")
	end

	local aKeys = {
		[STANCE_CROUCH] = KEY_CROUCH,
		[STANCE_STAND] = KEY_STAND,
		[STANCE_PRONE] = KEY_PRONE
	}

	if (iStance == STANCE_STAND and self:GetStance(iStance)) then
		return BotMainLog("Already standing !!")
	end

	local iCurrentStance = self:GetStance()
	local bCurrentStance = self:GetStance(iStance)
	local iKey = aKeys[iStance]
	if (iStance == STANCE_STAND) then
		if (iCurrentStance == STANCE_PRONE) then
			self:PressKey(KEY_PRONE)
		elseif (iCurrentStance == STANCE_CROUCH) then
			self:PressKey(KEY_CROUCH)
		else
			BotMainLog("Failed to switch stance from %d", g_TN(iCurrentStance))
		end
	elseif (not bCurrentStance) then
		self:PressKey(iKey)
	end

	self.STANCE_TIMER = timerinit()
	self.STANCE_TIME = checkVar(iTime, -1)
	self.STANCE_MODE = (isString(iKey) and iKey or nil)

	--BotMainLog("Stance = %s", tostring(iKey))
end

------------------------------
--- Init
Bot.IsVisible = function(self, hEntity)

	if (self:IsTargetVisible(hEntity)) then
		return true
	end

	local vEntity = self:GetBone_Pos(BONE_HEAD, hEntity)
	local vPos = self:GetBone_Pos(BONE_HEAD)

	if (not (vEntity or vPos)) then
		return
	end

	return (Physics.RayTraceCheck(vEntity, vPos, NULL_ENTITY, NULL_ENTITY))
end

------------------------------
--- Init
Bot.IsPointVisible = function(self, hEntity)

	local vPoint = hEntity
	if (isArray(hEntity) and hEntity.GetPos) then
		vPoint = hEntity:GetPos()
	elseif (isEntityId(hEntity)) then
		vPoint = GetEntity(hEntity):GetPos()
	end

	if (not vector.isvector(vPoint)) then
		return false, BotMainLog("Poinint is not visile")
	end
	return (System.IsPointVisible(vPoint))
end

------------------------------
--- Init
Bot.IsVisible_Entity = function(self, hEntity)

	local vEntity = checkVar(self:GetBone_Pos(BONE_HEAD, hEntity), vector.modifyz(hEntity:GetPos(), 1))
	local vPos = self:GetBone_Pos(BONE_HEAD)

	if (not (vEntity or vPos)) then
		return false
	end

	return (
			self:CanSee_Position(vEntity) or
			Physics.RayTraceCheck(vEntity, vPos, g_localActorId, hEntity.id) or
			self:CanSee_RayHit(hEntity)
	)
end

------------------------------
--- Init
Bot.IsVisible_Points = function(self, vPoint1, vPoint2, idIgnore1, idIgnore2)

	if (not (vPoint1 or vPoint2)) then
		return false
	end

	return (
		Physics.RayTraceCheck(vPoint1, vPoint1, checkVar(idIgnore1, g_localActorId), checkVar(idIgnore1, g_localActorId)) or
		self:IsVisible_RayHit(vPoint1, vPoint2, idIgnore1)
	)
end

------------------------------
--- Init
Bot.CanSee_RayHit = function(self, hTarget)

	------------------
	local vTarget = hTarget:GetPos()
	local vPos = self:GetPos_Head()
	local vDir = vector.getdir(vPos, vTarget, true)

	local iHits = Physics.RayWorldIntersection(vPos, vector.scale(vDir, BOT_RAYWORLD_MAXDIST), BOT_RAYWORLD_MAXDIST, ent_all, g_localActorId, nil, g_HitTable)
	local aHits = g_HitTable[1]

	------------------
	if (iHits and iHits > 0 and aHits) then
		if (not aHits.entity) then
			return false end

		------------------
		if (aHits.entity.id ~= hTarget.id) then
			return false end

		------------------
		return true
	end

	------------------
	return false
end

------------------------------
--- Init
Bot.IsVisible_RayHit = function(self, vSource, vTarget, idIgnore)

	------------------
	local vDir = vector.getdir(vSource, vTarget, true)

	local iHits = Physics.RayWorldIntersection(vSource, vector.scale(vDir, BOT_RAYWORLD_MAXDIST), BOT_RAYWORLD_MAXDIST, ent_all, checkVar(idIgnore, g_localActorId), nil, g_HitTable)
	local aHits = g_HitTable[1]

	------------------
	if (iHits and iHits > 0 and aHits) then

		------------------
		if (vector.distance(aHit.pos, vTarget) < 1) then
			return true
		end

		------------------
		return false
	end

	------------------
	return true
end

------------------------------
--- Init
Bot.CanSee_Position = function(self, vTarget, idEntity)
	if (not vector.isvector(vTarget)) then
		return
	end
	return Physics.RayTraceCheck(self:GetPos_Head(), vTarget, g_localActorId, checkVar(idEntity, checkVar(self:GetTargetId(), g_localActorId)))
end

------------------------------
--- Init
Bot.CanSee_Entity = function(self, hEntity)
	if (not isArray(hEntity)) then
		return
	end
	return Physics.RayTraceCheck(self:GetPos_Head(), vector.modifyz(hEntity:GetPos(), 0.25), g_localActorId, hEntity.id)
end

------------------------------
--- Init
Bot.ProbableEnemyNear = function(self, iCheck, bReturnEntity)

	local aPlayers = GetPlayers()
	if (table.empty(aPlayers)) then
		if (bReturnEntity) then
			return
		end
		return false
	end

	local vPos = self:GetPos()
	local iThreshold = checkVar(iCheck, 45)

	local iDistance
	local hLastChecked
	for i, hPlayer in pairs(aPlayers) do
		if (not self:IsTarget_SameTeam(hPlayer)) then
			if (self:IsAlive(hPlayer) and hPlayer.id ~= g_localActorId) then
				iDistance = vector.distance(hPlayer:GetPos(), vPos)
				if (iDistance < iThreshold) then-- or self:IsVisible(hPlayer)) then
					hLastChecked = hPlayer
				end
			end
		end
	end

	if (bReturnEntity) then
		return hLastChecked
	end

	return (hLastChecked ~= nil)
end

------------------------------
--- Init
Bot.CloseToPathGoal = function(self, iCheck)

	local vPos = self:GetPos()
	local vTarget = self.PATHFINDING_FINALPATH_POS
	if (not vTarget) then
		return false
	end

	local iDistance = vector.distance(vPos, vTarget)
	return (iDistance < checkVar(iCheck, 7.5))
end

------------------------------
--- Init
Bot.IsIndoors = function(self, iCheck)
	if (vector.isvector(iCheck)) then
		return (System.IsPointIndoors(iCheck))
	end
	return (self.BOT_INDOORS_TIME > checkVar(iCheck, 0))
end

------------------------------
--- Init
Bot.IsUnderground = function(self, iCheck, iThreshold)
	if (vector.isvector(iCheck)) then

		local vPos = iCheck
		local iTerrain = System.GetTerrainElevation(vPos)
		if (not iTerrain) then
			return true--, BotMainLog("NO TERRAIN FOUND !!")
		end

		local iUnder = (vPos.z - checkNumber(iTerrain, 0))
		if (iUnder > checkNumber(iThreshold, 0)) then
			return false--, BotMainLog("not under")
		end

		--BotMainLog("->%s %f < %f", tostring((iUnder < checkNumber(iThreshold, 0))), iUnder, iThreshold or 0)
		return (iUnder < checkNumber(iThreshold, 0))
	end

	return (self.BOT_SUBTERRAIN_TIME > checkVar(iCheck, 0))
end

------------------------------
--- Init
Bot.StartedOrEndingPath = function(self, iCheck)

	local iMaxNodes = self.CURRENT_PATH_NODES
	local iCurrentNode = self.CURRENT_PATH_NODE

	if (not (iMaxNodes or iCurrentNode)) then
		return
	end

	local bAtStart = (iCurrentNode <= checkVar(iCheck, 3))
	local bAtEnd = ((iMaxNodes - iCurrentNode <= checkVar(iCheck, 3)))

	return (bAtStart or bAtEnd)
end

------------------------------
--- Init
Bot.PathIsElevating = function(self, iCheck)

	local iCountToElevation = BotNavigation:IsPathElevating(false)
	if (iCheck > iCountToElevation) then
		return true
	end
	return false
end

------------------------------
--- Init
Bot.UpdateSuitMode = function(self)

	local hTimer = self.FORCED_SUIT_TIMER
	if (hTimer and timerexpired(hTimer, self.FORCED_SUIT_TIME)) then
		self:SetSuit(self.FORCED_SUIT_MODE)
	else

		local iFinalSuit = NANOMODE_NULL
		local bIndoors = self:IsIndoors()

		--BotMainLog("suit hehe")
		if (not self:HasTarget()) then
			local iAISuit = {}
			if (not timerexpired(self.BOT_SPRINT_PAUSE, 5)) then
				iFinalSuit = NANOMODE_ARMOR
				--BotMainLog("armor, timer not expired??")
			elseif (AIEventGet_Ovr("GetSuitMode", iAISuit)) then
				iFinalSuit = iAISuit.Value
				--BotMainLog("SUIT BY AI: %d", iFinalSuit or -1)
			elseif (self:GetSuitEnergy() >= 50 and self:OkToSprint() and not bIndoors) then
				iFinalSuit = NANOMODE_SPEED
			elseif (bIndoors) then
				iFinalSuit = NANOMODE_ARMOR
			end

			-- Always armor mode in risky situations ?
			if (self:ProbableEnemyNear()) then
				iFinalSuit = NANOMODE_ARMOR
			end
		else
			-- Always armor in combat ?
			iFinalSuit = NANOMODE_ARMOR

			if (self.FORCED_SUITMODE) then
				iFinalSuit = self.FORCED_SUITMODE
			end
		end

		if (iFinalSuit ~= NANOMODE_NULL) then
		--	BotMainLog("FINAL SUIT %s",tostring(iFinalSuit))
			self:SetSuit(iFinalSuit)
		end

	end

	self.FORCED_SUITMODE = nil
end

------------------------------
--- Init
Bot.UpdateJump = function(self)

	local hTimer = self.LAST_JUMP_TIMER
	if (hTimer and timerexpired(hTimer, 0.5)) then
		self:StopJump()
	end

end

------------------------------
--- Init
Bot.ClearGotoVehicle = function(self)
	self.GOTO_VEHICLE = nil
	self.GOTO_VEHICLE_TIMER = nil

	self.ATTEMPT_ENTER_VEHICLE_TIMER = nil
	self.ATTEMPT_ENTER_DRIVERSEAT_TIMER = nil
end


------------------------------
--- Init
Bot.ValidateVehicle = function(hVehicle)

	if (AIEvent("ValidateVehicle", hVehicle) ~= AIEVENT_OK) then
		return false
	end

	if (not isArray(hVehicle)) then
		return false
	end

	if (not GetEntity(hVehicle.id)) then
		return false
	end

	local hTimer = hVehicle.FAILED_SWITCH_DRIVERSEAT_TIMER
	if (hTimer and not hTimer.expired()) then
		return false, BotMainLog("vehicle fataly stuck!!")
	end

	if (not timerexpired(hVehicle.FATAL_STUCK_TIMER, 30)) then
		return false, BotMainLog("vehicle fataly stuck!!")
	end

	local iRadius = 15
	local iMineRadius = 10 -- AV Mine
	local aAllowed = {
		VEHICLE_CIV,
		VEHICLE_LTV, -- all ltvs
		VEHICLE_TANK, -- all tanks
		VEHICLE_APC, -- all npcs
	}

	-----------
	local vPos = g_localActor:GetPos()
	local vVehicle = hVehicle:GetPos()
	local vVehicle_Modified = vector.modify(vVehicle, 1.25)
	local iDistance = vector.distance(vPos, vVehicle)
	if (iDistance > iRadius) then
		return false--, BotMainLog("out of range!")
	end

	-----------
	if (hVehicle.vehicle:IsDestroyed()) then
		return false, BotMainLog("broken")
	end

	if (hVehicle.vehicle:GetRepairableDamage() > 30) then
		return false, BotMainLog("too much damaged!")
	end

	if (hVehicle.vehicle:IsFlipped()) then
		return false
	end

	-----------
	if (not string.matchex(hVehicle.class, unpack(aAllowed))) then
		return false, BotMainLog("bad class")
	end

	-----------
	if (Bot:VehicleFull(hVehicle)) then
		return false, BotMainLog("space bad")
	end

	if (not Bot:DriverSeatFree(hVehicle)) then
		return false, BotMainLog("driver seat bad")
	end

	-----------
	local aNearbyMines = GetEntities({ ENTITY_AVMINE, ENTITY_CLAYMORE }, nil, function(a)

		if (not a or not isArray(a) or not a.GetPos) then
			return false
		end
		return (not Bot:IsTarget_SameTeam(a) and vector.distance(vVehicle, a:GetPos()) < iMineRadius)
	end)

	if (table.count(aNearbyMines) > 0) then
		return false, BotMainLog("AVMINES bad")
	end

	-----------
	if (not Bot:IsPointVisible(vVehicle_Modified)) then
	--	return false, BotMainLog("visibility bad 2")
	end

	-----------
	if (not Bot:CanSee_Position(vVehicle_Modified) and not Bot:CanSee_Entity(hVehicle)) then
		return false, BotMainLog("visibility bad")
	end

	-----------
	local iZDiff = math.positive(vVehicle.z - vPos.z)
	if (iZDiff > 1 and not Pathfinding:IsPointOnTerrain(vPos) and not Pathfinding:IsPointOnTerrain(vVehicle)) then
		return BotMainLog("elevation bad")
	end

	if (not timerexpired(BotNavigation.LEAVE_INDOORS_TIMER, 0.25)) then
		return BotMainLog("just lft indoors")
	end

	if (not timerexpired(Bot.LAST_USED_DOOR, 0.25)) then
		return BotMainLog("just lft indoors")
	end

	if (not timerexpired(hVehicle.EXIT_TIMER, 10)) then
		return BotMainLog("just lft indoors")
	end

	-----------
	BotMainLog("Goto vehicle %s", hVehicle:GetName())
	return true
end

------------------------------
--- Init
Bot.HostilesNearby = function(self)
	return table.count(GetEntities(ENTITY_PLAYER, nil, function(a)
		return (a.id ~= self.id and not self:IsTarget_SameTeam(a) and Bot:IsAlive(a) and vector.distance(a:GetPos(),Bot:GetPos())<80)
	end)) > 0
end

------------------------------
--- Init
Bot.FindVehicle = function(self)

	if (self:IsDriving()) then
		return
	end

	if (self:HostilesNearby()) then
		return-- BotMainLog("baddies nearby")
	end

	local vPos = g_localActor:GetPos()
	local vCamPos = self:GetViewCameraPos()
	local vCamDir = self:GetViewCameraDir()

	local hCurrent = self.GOTO_VEHICLE
	if (hCurrent) then

		BotAI.PAUSE_UPDATE = true

		BotMainLog("GOTO VEHICLE !!!")
		if (not self.ValidateVehicle(hCurrent)) then
			self:ClearGotoVehicle()
		else
			local vCurrent = hCurrent:GetPos()
			local iCurrent = vector.distance(vCurrent, vPos)
			local bCurrentInFront = self:GetEntityInFront(vector.modifyz(vCamPos, -0.5), vCamDir, 2, hCurrent.id)

			BotMainLog("Current uber: %f",iCurrent)
			BotMainLog("Current in font: %s",g_TS(bCurrentInFront))
			if (iCurrent < 3 or bCurrentInFront) then
				self:StopMovement()
				self:InterruptMovement(eMovInterrupt_FindUber, 1)

				local hTryTimer = self.ATTEMPT_ENTER_VEHICLE_TIMER
				if (hTryTimer and hTryTimer.expired()) then
					return self:ClearGotoVehicle()
				elseif (hTryTimer == nil) then
					self.ATTEMPT_ENTER_VEHICLE_TIMER = timernew(3) -- server isnt allowing us to enter this vehicle!
				end

				if (timerexpired(self.ENTER_VEHICLE_TIMER, 1)) then
					self:EnterVehicle(hCurrent)
				--	self:ClearGotoVehicle()
				end
				BotMainLog("Entereing !!")
			else
				BotNavigation:SetSleepTimer(0.1)
				self:StartMoving(MOVE_FORWARD, vCurrent)
				self.FORCED_CAM_LOOKAT = vector.modifyz(vCurrent, 1.5)
			end
			return
		end
	end
	if (BotNavigation:IsTargetPlayer()) then
		return
	end

	local vGoal = BotNavigation:GetPathGoal()
	local iExitThreshold = 60
	if (BotNavigation:IsPathGoalIndoors()) then
		iExitThreshold = 95
	end
	if (vGoal and vector.distance(vPos, vGoal) < iExitThreshold) then
		return
	end

	local aVehicles = GetEntities(GET_ALL, "vehicle", self.ValidateVehicle)
	if (table.count(aVehicles) == 0) then
		return
	end

	local aBest = { -1 }
	for i, hTemp in pairs(aVehicles) do
		local iDistance = vector.distance(hTemp:GetPos(), vPos)
		if (aBest[1] == -1 or iDistance < aBest[1]) then
			aBest = {
				iDistance,
				hTemp
			}
		end
	end

	local hVehicle = aBest[2]
	if (not hVehicle) then
		return
	end

	self.GOTO_VEHICLE = hVehicle
	self.GOTO_VEHICLE_TIMER = timerinit()
end

------------------------------
--- Init
Bot.VehicleFull = function(self, hCheck)
	if (not hCheck) then
		return true
	end

	local aSeats = hCheck.Seats
	local iSeats = table.count(aSeats)
	local iFilled = 0
	for i, aSeat in pairs(aSeats) do
		if (aSeat.passengerId) then
			iFilled = iFilled + 1
		end
	end

	return (iFilled >= iSeats)
end

------------------------------
--- Init
Bot.DriverSeatFree = function(self, hCheck)
	if (not hCheck) then
		return
	end

	if (hCheck:HasDriver()) then
		return true
	end

	-- delete
	local bFree = true
	for i, aSeat in pairs(hCheck.Seats) do
		if (aSeat.isDriver) then
			bFree = (bFree or (not aSeat.passengerId))
		end
	end

	return bFree
end


------------------------------
--- Init
Bot.GetVehicle = function(self, hCheck)

	local idVehicle = checkVar(hCheck, g_localActor).actor:GetLinkedVehicleId()
	if (not idVehicle) then
		return
	end

	return GetEntity(idVehicle)
end

------------------------------
--- Init
Bot.GetVehicleType = function(self, hCheck)

	local sType
	local hTarget = checkVar(hCheck, g_localActor)
	if (isArray(hTarget)) then
		if (hTarget.vehicle) then
			sType = hTarget.class
		elseif (hTarget.actor) then
			local hVehicle = self:GetVehicle(hTarget)
			if (hVehicle) then
				sType = hVehicle.class
			end
		end
	end

	return sType
end

------------------------------
--- Init
Bot.IsVehicleTank = function(self, hCheck)

	local hVehicle = checkVar(hCheck, self:GetVehicle())
	if (not hVehicle) then
		return
	end

	return (string.matchex(hVehicle.class, unpack(VEHICLE_TANKS)))
end

------------------------------
--- Init
Bot.GetVehicleWeapons = function(self, hCheck)

	local hVehicle = checkVar(hCheck, self:GetVehicle())
	if (not hVehicle) then
		return
	end

	local aSeats = hVehicle.Seats
	local iSeat = self:GetVehicleSeat(hVehicle)
	if (not iSeat) then
		return
	end

	local aSeat = aSeats[iSeat]
	if (not aSeat) then
		return
	end

	if (not aSeat.passengerId == g_localActorId) then
		return
	end

	local iWeapons = aSeat.seat:GetWeaponCount()
	if (iWeapons < 1) then
		return
	end

	local aWeapons = {}
	for i = 1, iWeapons do
		local idWeapon = aSeat.seat:GetWeaponId(i)
		if (idWeapon) then
			BotMainLog("weapon[%d] found", i)
			local hWeapon = GetEntity(idWeapon)
			if (hWeapon) then
				table.insert(aWeapons, hWeapon)
			end
		end
	end

	return aWeapons
end

------------------------------
--- Init
Bot.GetVehicleSeat = function(self, hCheck, idCheck)

	local hVehicle = checkVar(hCheck, self:GetVehicle())
	if (not hVehicle) then
		return
	end

	local iSeat
	for i, aSeat in pairs(hVehicle.Seats) do
		if (aSeat:GetPassengerId() == checkVar(idCheck, g_localActorId)) then
			iSeat = aSeat.seatId
			break
			--BotMainLog("seat %d %s==%s", aSeat.seatId,tostring(aSeat.passengerId), tostring(checkVar(idCheck, g_localActorId)))
		end
	end
	return iSeat
end

------------------------------
--- Init
Bot.SpaceInInventory = function(self, sClass)

	---------------
	local sCategory = g_localActor.actor:GetItemCategory(sClass)
	if (not sCategory) then
		return true end

	---------------
	local iLimit = 1

	---------------
	local iCount = g_localActor.actor:GetItemCountOfCategory(sCategory)
	if (sCategory == "medium" or sCategory == "heavy") then
		iCount = (g_localActor.actor:GetItemCountOfCategory("heavy") + g_localActor.actor:GetItemCountOfCategory("medium"))
		iLimit = 2
	elseif (sCategory == "explosive") then
		iLimit = 2
	end

	---------------
	BotMainLog("space:%s %d<%d",sCategory,iCount,iLimit)
	return iCount < iLimit
end

------------------------------
--- Init
Bot.SetItem = function(self, sClass)
	local hCurrentItem = self:GetItem()
	if (not hCurrentItem or hCurrentItem.class ~= sClass) then
		g_localActor.actor:SelectItemByName(sClass)
		if (self.LAST_ITEM_CLASS ~= sClass) then
			if (sClass == WEAPON_RPG) then
				self.MELEE_RPG_TIMER = timerinit()
			else
				self.MELEE_RPG_TIMER = nil
			end
		end


		self.LAST_ITEM_CLASS = sClass
		BotMainLog("Set item %s", sClass)
	end
end

------------------------------
--- Init
Bot.IsSpecialItem = function(self, sClass)
	return string.matchex(sClass, unpack(BOT_SPECIAL_ITEMS))
end

------------------------------
--- Init
Bot.HasItem = function(self, sClass, bGetHandle)
	local bHas = (g_localActor.inventory:GetItemByClass(sClass))
	if (bHas) then

		if (self:IsSpecialItem(sClass)) then
			if (self:InventoryEmpty(sClass)) then
				return
			elseif (bGetHandle) then
				return bHas
			end
			return true
		end

		if (bGetHandle) then
			return bHas
		end
		return true
	end

	local aInventory = self:GetInventory()
	if (not aInventory) then
		return
	end

	local bOk
	local hWeapon, hLast
	for i, idWeapon in pairs(aInventory) do
		hWeapon = GetEntity(idWeapon)
		if (hWeapon and hWeapon.class == sClass) then
			hLast = hWeapon
			bOk = true
		end
	end

	if (bGetHandle) then
		return hLast
	end
	return bOk
end

------------------------------
--- Init
Bot.GetInventoryAmmo = function(self, sAmmoType)

	---------------
	local sAmmoType = sAmmoType
	if (isArray(sAmmoType)) then
		sAmmoType = sAmmoType.weapon:GetAmmoType()
	elseif (isEntityId(sAmmoType)) then
		sAmmoType = GetEntity(sAmmoType).weapon:GetAmmoType()
	end

	---------------
	if (not sAmmoType) then
		return 0 end

	---------------
	local iAmmo = g_localActor.actor:GetInventoryAmmo(sAmmoType)
	return (iAmmo or 0)
end

------------------------------
--- Init
Bot.GetAmmoScore = function(self, sClass)

	local hWeapon = self:GetItem()
	if (sClass) then
		local idWeapon = self:HasItem(sClass)
		if (not idWeapon) then
			return
		end
		hWeapon = GetEntity(idWeapon)
	end

	if (not hWeapon.weapon) then
		return 0
	end

	local iAmmo = hWeapon.weapon:GetAmmo()
	local iClip = hWeapon.weapon:GetClipSize()

	if (not iAmmo) then
		return 0
	end

	return (iClip / iAmmo)
end

------------------------------
--- Init
Bot.AmmoStockFull = function(self, sClass, iCheck)

	local hWeapon = self:GetItem()
	if (sClass) then
		local idWeapon = self:HasItem(sClass)
		if (not idWeapon) then
			return
		end
		hWeapon = GetEntity(idWeapon)
	end

	if (not (hWeapon and hWeapon.weapon)) then
		return 0
	end

	local sAmmo = hWeapon.weapon:GetAmmoType()
	if (string.empty(sAmmo)) then
		return false
	end

	local iCapacity = g_localActor.inventory:GetAmmoCapacity(sAmmo)
	local iAmmo = g_localActor.inventory:GetAmmoCount(sAmmo)

	if (not isNumber(iCapacity) or not isNumber(iAmmo)) then
		return false
	end

	return (iAmmo < checkVar(iCheck, iCapacity))
end

------------------------------
--- Init
Bot.AmmoStockEmpty = function(self, sClass)
	return (self:AmmoStockFull(sClass, 1))
end

------------------------------
--- Init
Bot.IsItem = function(self, hCheck)
	local hWeapon = checkVar(self:GetItem(), hCheck)
	if (not hWeapon) then
		return false
	end

	if (not hWeapon.weapon) then
		return false
	end

	return true
end

------------------------------
--- Init
Bot.GetItem = function(self, sClass)

	if (sClass) then
		--BotMainLog("GetItem(%s)", sClass)
		local idWeapon = self:HasItem(sClass, true)
		if (not idWeapon) then
		--	BotMainLog("not found(%s)", sClass)
			return
		end
		--BotMainLog("id(%s)", tostring(idWeapon))
		return GetEntity(idWeapon)
	end
	return (g_localActor.inventory:GetCurrentItem())
end

------------------------------
--- Init
Bot.IsItem_Current = function(self, sClass)
	local hCurrent = self:GetItem()
	if (not hCurrent) then
		return false
	end

	return (hCurrent.class == sClass)
end

------------------------------
--- Init
Bot.GetAmmo = function(self, sClass)
	return (g_localActor.inventory:GetAmmoCount(sClass))
end

------------------------------
--- Init
Bot.GetInventory = function(self)
	return (g_localActor.inventory:GetInventoryTable())
end

------------------------------
--- Init
Bot.ShouldReload = function(self, hCheck)
	local hWeapon = checkVar(hCheck, self:GetItem())
	if (not hWeapon) then
		return false
	end

	if (not hWeapon.weapon) then
		return false
	end

	local aIgnore = {
		AlienMount = 1,
	}

	if (aIgnore[hWeapon.class]) then
		return false
	end

	local iAmmo = hWeapon.weapon:GetAmmoCount()
	local iClip = hWeapon.weapon:GetClipSize()

	if (isNull(iAmmo) or isNull(iClip)) then
		return false
	end

	return (iAmmo < iClip)
end

------------------------------
--- Init
Bot.CanReload = function(self, hCheck)
	local hWeapon = checkVar(hCheck, self:GetItem())
	if (not hWeapon) then
		return false
	end

	if (not hWeapon.weapon) then
		return false
	end

	local iAmmo = self:GetAmmo(hWeapon.weapon:GetAmmoType())

	if (isNull(iAmmo)) then
		return false
	end

	return (iAmmo >= 1)
end

------------------------------
--- Init
Bot.IsCarried = function(self, hCheck)
	return (hCheck.weapon:GetShooter())
end

------------------------------
--- Init
Bot.CheckAmmoRestrictions = function(self, hCheck, idCheck)
	local hWeapon = checkVar(hCheck, self:GetItem())
	if (not hWeapon) then
		return false
	end
	return hWeapon.weapon:CheckAmmoRestrictions(checkVar(idCheck, g_localActorId))
end

------------------------------
--- Init
Bot.ResetGrab = function(self)
	self.CURRENT_PICKUP = nil
	self.CURRENT_GRAB_INVISIBLETIMER = nil

	BotMainLog("Grab Reset")
end

------------------------------
--- Init
Bot.GetGrab = function(self, hItem)
	return (self.CURRENT_PICKUP)
end

------------------------------
--- Init
Bot.SetGrab = function(self, hItem)
	self.CURRENT_PICKUP = hItem
end

------------------------------
--- Init
Bot.HasGrab = function(self)
	if (self:HasTarget()) then
		return false
	end
	return (self.CURRENT_PICKUP ~= nil)
end

------------------------------
--- Init
Bot.CanGrab_Category = function(self, sClass)
	return (self:SpaceInInventory(sClass))
end

------------------------------
--- Init
Bot.CanGrab = function(self, hItem, bIgnoreStock)

	if (not hItem) then
		return false, BotMainLog("no item")
	end

	if (not GetEntity(hItem.id)) then
		return false, BotMainLog("no item2")
	end

	if (not self:IsVisible_Entity(hItem)) then
		if (timerexpired(self.CURRENT_GRAB_INVISIBLETIMER, 5)) then
			return false, BotMainLog("invisible")
		end
	else
		self.CURRENT_GRAB_INVISIBLETIMER = timerinit()
	end

	if (self:IsCarried(hItem)) then
		return false, BotMainLog("carried")
	end

	local sItem = hItem.class
	local bAmmoOk = (self:AmmoOk(hItem, nil, true))
	if ((string.matchex(sItem,
			WEAPON_CLAYMORE, -- doesnt have any clip
			WEAPON_C4 -- doesnt have any clip
	))) then
		BotMainLog("its special")
		bAmmoOk = (not self:InventoryFull(hItem))
	end

	if ((not bAmmoOk) or not self:CheckAmmoRestrictions(hItem)) then
		return false, BotMainLog("ammo or restriction bad")
	end

	if (not bIgnoreStock and not self:CanGrab_Category(sItem)) then
		local bHasItem = self:HasItem(sItem)
		if (not bHasItem or self:AmmoStockFull(sItem)) then
			return false, BotMainLog("stock full or not has item")
		end
	end

	local iDistance = self:GetDistance(hItem)
	if (iDistance > 20) then
		return false, BotMainLog("disance")
	end

	BotMainLog("All GOod")
	return true
end

------------------------------
--- Init
Bot.IsWeapon = function(self, hItem)

	if (not hItem) then
		return false
	end

	if (not hItem.weapon) then
		return false
	end

	local sItem = hItem.class
	local aNonWeapons = {
		"OffHand", "Fists"
	}
	if (string.matchex(sItem, unpack(aNonWeapons))) then
		return false
	end

	local iAmmo = hItem.weapon:GetAmmoCount()
	local iClip = hItem.weapon:GetAmmoCount()
	if (not isNumber(iAmmo)) then
		return false
	end

	--BotMainLog("%f%s",iAmmo,hItem.class)

	return true
end

------------------------------
--- Init
--- Fix dum jumping
Bot.GrabItem = function(self, hCheck)

	BotMainLog("grabbing item !!")
	local hItem = self:GetGrab()
	if (not self:CanGrab(hItem) or self:IsWallJumping()) then
		BotMainLog("not possible ..")
		return self:ResetGrab()
	end

	local sItem = hItem.class
	local vItem = hItem:GetPos()

	self:SpawnDebugEffect(vItem)
	if (self:HasTarget()) then
		self:ResetGrab()
		return -- OK ??
	end

	local iDistance = self:GetDistance(vItem)
	if (iDistance >= 2.6) then

		local iCurrent = BotNavigation.CURRENT_PATH_NODE
		local iNodes = table.count(checkArray(BotNavigation.CURRENT_PATH_ARRAY))
		if (iCurrent and iNodes and (iNodes - iCurrent > 2)) then

			local idTarget = BotNavigation:GetTargetId()
			if (not idTarget or idTarget ~= hItem.id) then
				BotNavigation:GetNewPath(hItem) end

			BotNavigation:Update()
			BotNavigation.CURRENT_PATH_NODELAY = true
			BotNavigation.CURRENT_PATH_IGNOREPLAYERS = true
			BotMainLog("update GOTO !")
		else
			self:StartMoving(MOVE_FORWARD, vItem)

			BotMainLog("PATH CANT REACH")
		end
	else
		BotNavigation:SetSleepTimer(0.1)
		self:StopMovement()
		BotMainLog("%f",iDistance)
		if (iDistance > 2 or not self:IsPointVisible(hItem)) then
			self:SetCameraTarget(vItem, 99) -- find item
		end
		g_localActor.actor:SvRequestPickUpItem(hItem.id)
		--BotMainLog("stop move")
	end

	self.PICK_ITEM_TIMER = timerinit()
	BotMainLog("ok to GRAB %s", hItem.class)

end

------------------------------
--- Init
Bot.Drop = function(self, hItem)
	g_localActor.actor:DropItem(hItem.id)
end

------------------------------
--- Init
Bot.HasEmptyItems = function(self, bReturnClass)

	--local aItems = GetEntities(GET_ALL, "weapon") -- ???
	local aItems = self:GetInventory()
	if (table.empty(aItems)) then
		return
	end

	local hItem
	for i, idItem in pairs(aItems) do
		hItem = GetEntity(idItem)
		if (hItem and hItem.weapon and self:IsWeapon(hItem)) then
			if (self:AmmoStockEmpty(hItem.class) and not self:AmmoOk(hItem)) then
				return (bReturnClass and hItem or true)
			end
		end
	end

	return false
end

------------------------------
--- Init
Bot.FindItem = function(self, bCheckOnly)
	--BotMainLog("find new item !!")

	if (self:IsFlying()) then
		return
	end

	if (self:HasTarget()) then
		return
	end

	local hCurrent = self.CURRENT_PICKUP
	if (hCurrent) then
		BotMainLog("has already!!")
		return self:GrabItem()
	end

	local iRadius = 15
	local aPriorityList = BOT_ITEM_PRIORITY

	local aItems = GetEntities(GET_ALL, "weapon")
	if (table.empty(aItems)) then
		return
	end

	local bWallJumping = self:IsWallJumping()
	if (bWallJumping) then
		return
	end

	local vPos = self:GetPos()
	local iDistance

	local hItem, sItem
	local bCanGrab, hGrab
	local bStockFull
	local bGrabable, bGrabableEx, bCanGrabCategory, bIgnoreAmmo, bHas
	local bHasItem, bAmmoOk
	local hEmpty

	for i, idItem in pairs(aItems) do
		hItem = GetEntity(idItem)
		if (hItem and hItem.weapon and not self:IsCarried(hItem)) then
			sItem = hItem.class
			if (aPriorityList[sItem]) then
				iDistance = vector.distance(hItem:GetPos(), vPos)
				if (iDistance < iRadius and self:IsVisible_Entity(hItem)) then
					bStockFull = self:AmmoStockFull(sItem)
					bCanGrabCategory = self:CanGrab_Category(sItem)
					bGrabable = self:CanGrab(hItem)
					bGrabableEx = self:CanGrab(hItem, true)
					bHasItem = self:HasItem(hItem.class)

					BotMainLog("Stock   : %s", g_ts(bStockFull)) -- 0
					BotMainLog("Category: %s", g_ts(bCanGrabCategory)) -- true
					BotMainLog("Grab1   : %s", g_ts(bGrabable))
					BotMainLog("Grab2   : %s", g_ts(bGrabableEx))
					BotMainLog("Has Item: %s", g_ts(bHasItem))

					hEmpty = self:HasEmptyItems(1)
					if (not bCanGrabCategory and bGrabableEx and not bHasItem) then
						if (hEmpty) then
							self:Drop(hEmpty)
							BotMainLog("AMMO EMPTY, DROPA DN SELET THIS NOW!!")
							bCanGrabCategory = true
						end
					end

					bAmmoOk = self:AmmoOk(hItem, nil, true)
					BotMainLog("AMmo OK: %s",g_ts(bAmmoOk))
					bIgnoreAmmo = self:IsSpecialItem(sItem)
					if (bIgnoreAmmo) then
						bAmmoOk = (not self:InventoryFull(hItem))
					end

					bCanGrab = ((bCanGrabCategory or not bStockFull) and bAmmoOk)
					if (bCanGrab and bGrabable) then
						hGrab = hItem
						BotMainLog("%s - We can GRAB it!", sItem)
					end

					BotMainLog("item: %s", sItem)
				end
			end
		end
	end

	if (hGrab) then
		--self:StopMovement()
		self:SetGrab(hGrab)
	end

end

------------------------------
--- Init
Bot.UpdateItem = function(self, bForce)

	local hTarget = self:GetTarget()
	if (not hTarget and not bForce) then
		return false
	end

	local vCamPos = self:GetViewCameraPos()
	local vCamDir = self:GetViewCameraDir()

	local iDistance = 0
	if (hTarget) then
		iDistance = self:GetDistance(hTarget)
	end

	local vTarget, aVehicles, hClosestVehicle
	local vPos = self:GetPos()
	local bNearVehicle = false
	if (hTarget and iDistance > 15) then
		vTarget = hTarget:GetPos()
		aVehicles = GetEntities(GET_ALL, "vehicle", function(hEnt)
			return (not hEnt.vehicle:IsDestroyed() and vector.distance(vTarget, hEnt:GetPos()) < 8.5 and not self:IsTarget_SameTeam(hEnt))
		end)
		bNearVehicle = (table.count(aVehicles) > 0)
		if (bNearVehicle) then
			table.sort(aVehicles, function(a, b) return (vector.distance(a:GetPos(), vTarget) < vector.distance(b:GetPos(), vTarget))  end)
			hClosestVehicle = aVehicles[1]
			if (self:GetDistance(hClosestVehicle) < 12) then
				hClosestVehicle = nil
			end
		end
	end

	local hVehicle = self:GetVehicle(hTarget)
	local iVehicle = self:GetVehicleType(hVehicle)
	if (self.COMBAT_RELOAD_TIMER and not self.COMBAT_RELOAD_TIMER.expired()) then
		return true
	end

	local hCurrentItem = self:GetItem()
	local aInventory = self:GetInventory()
	if (not isArray(aInventory)) then
		return false
	end

	if (hCurrentItem) then
		if (hCurrentItem.class == WEAPON_RPG) then
			if (not timerexpired(self.MELEE_RPG_TIMER, 2.5)) then
				self:MeleeWeapon()
				self.MELEE_RPG_TIMER = nil
			end
		end
	end

	local bIndoors = self:IsIndoors()
	local bSelected = false
	local bAmmoOk = self:AmmoOk(hCurrentItem)
	local iSpeed = 0
	if (hTarget) then
		iSpeed = hTarget:GetSpeed()
	end
	local iRPGSpeed = -1

	BotMainLog("ammo ok= %s",string.bool(bAmmoOk))
	BotMainLog("rpg ok= %s",string.bool(self:HasItem(WEAPON_RPG)))
	BotMainLog("rpg AMMO ok= %s",string.bool(self:AmmoOk(WEAPON_RPG)))

	local bRPG = (self:HasItem(WEAPON_RPG) and self:AmmoOk(WEAPON_RPG))
	local bC4 = (self:HasItem(WEAPON_C4))
	local bDetonator = (self:HasItem(WEAPON_DETONATOR))

	self.C4_GOTO_TARGET = nil

	if (not bIndoors and bRPG and (hVehicle or bNearVehicle)) then
		BotMainLog("vehicle and RPG %f>%f",iSpeed,iRPGSpeed)
		if (iSpeed > iRPGSpeed or iVehicle ~= VEHICLE_CIV) then
			self:SetItem(WEAPON_RPG)
			if (hClosestVehicle) then
				self.FORCED_CAM_LOOKAT = vector.modifyz(hClosestVehicle:GetPos(), 1.5)
			elseif (hVehicle) then
				self.FORCED_CAM_LOOKAT = vector.modifyz(hVehicle:GetPos(), 1.5)
			end
			BotMainLog("rpg ok")
			return true
		end
	elseif ((bC4 or bDetonator) and iDistance < 30 and hVehicle) then
		self.NO_FIRE_TIME = timernew(1)
		self.C4_GOTO_TARGET = true
		self.C4_GOTO_TARGET_DISTANCE = 5

		BotMainLog("C4 update")

		if (iDistance < 5 or self:GetEntityInFront(vCamPos, vCamDir, 6, hVehicle.id)) then
			local hC4 = self:GetItem(WEAPON_C4)
			local hDetonator = self:GetItem(WEAPON_C4)
			if (hC4 and not self.C4_PLACED and self:AmmoOk(WEAPON_C4)) then
				self:SetItem(WEAPON_C4)
				hC4.weapon:RequestStartFire()
				self:StartShooting()
				self.C4_PLACED = true
			elseif (hDetonator) then
				BotMainLog("DETONATOR")
				self:SetItem(WEAPON_DETONATOR)
				hDetonator.weapon:RequestStartFire()
				self:StartShooting()
				self.C4_PLACED = nil
			end
		end
		return true
	end

	self.C4_PLACED = nil

	local bDSG = (self:HasItem(WEAPON_DSG) and self:AmmoOk(WEAPON_DSG))
	local bGauss = (self:HasItem(WEAPON_GAUSS) and self:AmmoOk(WEAPON_GAUSS))
	local bShotgun = (self:HasItem(WEAPON_SHOTGUN) and self:AmmoOk(WEAPON_SHOTGUN))
	local bFY71 = (self:HasItem(WEAPON_FY71) and self:AmmoOk(WEAPON_FY71))
	local bSCAR = (self:HasItem(WEAPON_SCAR) and self:AmmoOk(WEAPON_SCAR))

	local bSeekBetter = true
	local hCurrent = (self.CURRENT_ITEM)
	if (hCurrent) then
		bSeekBetter = (not self:AmmoOk(hCurrent) or hCurrent.class ~= "Fists" or not self:IsItem(hCurrent))
	end

	if (false and iDistance < 8 and bShotgun) then
		self:SetItem(WEAPON_SHOTGUN)
		bSelected = true
	elseif (iDistance > 75 and (bDSG or bGauss)) then
		self:SetItem((bGauss and WEAPON_GAUSS or WEAPON_DSG))
		bSelected = true
	elseif (iDistance > 15 and (bFY71 or bSCAR)) then
		self:SetItem((bFY71 and WEAPON_FY71 or WEAPON_SCAR))
		bSelected = true
	elseif (bSeekBetter) then

		local hWeapon
		local hSelected, hPanicSelect
		local aUsable = {
			FY71 = 1,
			SCAR = 1,
			SMG = 1,
			--Hurricane = 1,
			--Shotgun = 1,
		}

		for i, idWeapon in pairs(aInventory) do
			hWeapon = GetEntity(idWeapon)
			if (aUsable[hWeapon.class] and self:IsItem(hWeapon)) then
				if (self:AmmoOk(hWeapon, 10)) then
					BotMainLog("ammo okiiii")
					if (hSelected) then
						if (hSelected.class == WEAPON_SHOTGUN) then
							hSelected = hWeapon
						end
					else
						hSelected = hWeapon
					end
				elseif (self:InventoryAmmoOk(hWeapon.class)) then
					BotMainLog("inv ok")
					hPanicSelect = hWeapon
				end
			end
		end

		if (hSelected) then
			self:SetItem(hSelected.class)
			self.CURRENT_ITEM = hSelected
			bSelected = true
			BotMainLog("selected%s",hSelected.class)
		elseif (hPanicSelect and not bAmmoOk) then
			if (iDistance > 10) then
				self.COMBAT_RELOAD_TIMER = timernew(5)
				self:ReloadWeapon(hPanicSelect)
				bSelected = true
				BotMainLog("inventory ammo ok, reload!")
			else
				self:SetItem("Fists")
				return
			end
		elseif (not bSeekBetter) then
			bSelected = true
		end
	end

	if (not bSelected) then
		if (bGauss) then
			self:SetItem(WEAPON_GAUSS)
			bSelected = true
		elseif (bDSG) then
			self:SetItem(WEAPON_DSG)
			bSelected = true
		elseif (bShotgun and iDistance < 50) then
			self:SetItem(WEAPON_SHOTGUN)
			bSelected = true
		elseif (bFY71) then
			self:SetItem(WEAPON_FY71)
			bSelected = true
		elseif (bSCAR) then
			self:SetItem(WEAPON_SCAR)
			bSelected = true

		end

		if (not bSelected and not bAmmoOk and not bForce) then
			BotMainLog("AMMO : BAD!")
			if (iDistance > 10 and hCurrent and self:InventoryAmmoOk(hCurrent)) then
				self.COMBAT_RELOAD_TIMER = timernew(5)
				self:ReloadWeapon(hCurrent)
				bSelected = true
				BotMainLog("inventory ammo ok, reload!")
			else
				self:SetItem("Fists")
				--self:FindItem()
			end
		end
	end

	-- FIXME: !!! TEST !!!
	self:FindItem()

	return bSelected
	--self:UpdateCurrentItem()
end

------------------------------
--- Init
Bot.SetFireMode = function(self, hItem, iMode)

	-- fixed: and to or replacement
	if (not timerexpired(hItem.REQUEST_FIREMODE_TIMER, 3) or iMode == hItem.REQUEST_FIREMODE) then
		return
	end

	hItem.REQUEST_FIREMODE_TIMER = timerinit()
	hItem.REQUEST_FIREMODE = iMode

	hItem.weapon:RequestChangeFireMode(iMode)
end

------------------------------
--- Init
Bot.GetFireMode = function(self, hItem)
	return (hItem.weapon:GetCurrentFireMode())
end

------------------------------
--- Init
Bot.GetFireMode_Forced = function(self, hItem)
	local aForced = self.BOT_FORCED_FIREMODES
	if (not isArray(aForced)) then
		return
	end

	local iMode = aForced[hItem.class]
	return iMode
end

------------------------------
--- Init
Bot.UpdateCurrentItem = function(self)

	local hCurrent = self:GetItem()
	if (not hCurrent) then
		return
	end

	local iFireMode = self:GetFireMode(hCurrent)
	local iForcedFireMode = self:GetFireMode_Forced(hCurrent)

	--BotMainLog("iFireMode=%f",iFireMode)

	if (iForcedFireMode) then
		if (iFireMode ~= iForcedFireMode) then
			self:SetFireMode(hCurrent, iForcedFireMode)
		end
	else
	end
	--RequestChangeFireMode
end

------------------------------
--- Init
Bot.UpdateInventory = function(self)

	local hCurrentItem = self:GetItem()
	local aInventory = self:GetInventory()
	if (not isArray(aInventory)) then
		return
	end

	--BotMainLog("near:%s",string.bool(self:GetTarget_Near(15)))
	local bNear = self:GetTarget_Near(15)
	local bTarget = self:HasTarget()
	if ((bTarget or bNear)) then
		local bUpdated = self:UpdateItem(bNear)
		if (bUpdated) then
			return BotMainLog("target or nearby updated")
		end
	end

	--BotMainLog("check inventory")

	local bSelectFists = true
	local aPriorityList = BOT_ITEM_PRIORITY

	local aReload = {}
	local hWeapon
	for i, idWeapon in pairs(aInventory) do
		hWeapon = GetEntity(idWeapon)
		if (self:ShouldReload(hWeapon) and self:CanReload(hWeapon)) then
			table.insert(aReload, hWeapon)
		end
	end

	table.sort(aReload, function(a, b)
		local iScore_A = checkNumber(aPriorityList[a.class], 1)
		local iScore_B = checkNumber(aPriorityList[b.class], 1)
		return (iScore_A > iScore_B)
	end)

	if (table.count(aReload) > 0) then
		bSelectFists = false
		local hReload = aReload[1]
		self:ReloadWeapon(hReload)
		self:SetItem(hReload.class)
	end

	if (bSelectFists) then

		if (self:IsDriving()) then
			return
		end

		if (timerexpired(self.EXPLOSIVE_PLANT_TIMER, 1) and timerexpired(self.C4_DETONATION_TIMER, 1)) then
			local sIdleItem = AIEventGetStr("GetIdleWeapon", "Fists")
			self:SetItem(sIdleItem)

			AIEvent("OnIdleWeapon", sIdleItem)
			self:FindItem()
		end

		-- debug
		--BotMainLog("IDLE ??????????????????????????????????ß")

		-- idle view
		local vIdleView = AIEventGetVec("GetIdleViewPoint")
		if (vIdleView ~= nil) then
			self.FORCED_CAM_LOOKAT = vIdleView
			self.FORCED_CAM_SPEED = BOT_CAMERASPEED_AUTO

			self:SetCameraTarget(vIdleView)
		end

		-- check timer
		if (timerexpired(self.PICK_ITEM_TIMER, 5)) then
			local hC4 = GetEntity(self:HasItem(WEAPON_C4, true)) -- get handle
			if (hC4) then
				AIEvent("Inventory_FoundC4", hC4)
				if (AIEventGet("Inventory_CanPlaceExplosive", AIEVENT_OK, hC4)) then
					BotMainLog("PLACE C4!!!")
					self:PlaceExplosive(hC4) -- not not working properly
				end
			end

			local hClaymore = GetEntity(self:HasItem(WEAPON_CLAYMORE, true)) -- get handle
			if (hClaymore) then
				AIEvent("Inventory_FoundClaymore", hClaymore)
				if (AIEventGet("Inventory_CanPlaceExplosive", AIEVENT_OK, hClaymore)) then
					BotMainLog("PLACE CLAYMORE!!!")
					self:PlaceExplosive(hClaymore)
				end
			end
		end
	else
		self:ReleaseKey(KEY_RELOAD)
	end

end

------------------------------
--- Init
Bot.GetPlacedExplosives = function(self, sType)

	local aPlaced = {}
	for _, aExplosive in pairs(self.PLACED_EXPLOSIVES) do
		if (sType == aExplosive.Type and GetEntity(aExplosive.ExplosiveID)) then
			table.insert(aPlaced, aExplosive.Explosive)
		end
	end

	return aPlaced
end

------------------------------
--- Init
Bot.PlaceExplosive = function(self, hExplosive)

	-- pause
	self:InterruptCamera(eMovInterrupt_PlaceExplosive)
	self:InterruptMovement(eMovInterrupt_PlaceExplosive)

	-- simulate stance
	self:SetStance(STANCE_CROUCH, 0.1)

	-- check
	if (not timerexpired(self.EXPLOSIVE_PLANT_TIMER, 0.5)) then
		return
	end

	local sType = (hExplosive.class)

	-- C4 is simple
	if (sType == WEAPON_C4) then

		self:SetItem(WEAPON_C4)
		table.insert(self.C4_LOCATIONS, {
			ExplosiveID = hExplosive.id,
			Position = self:GetPos()
		})

	elseif (sType == WEAPON_CLAYMORE) then

		self:SetItem(WEAPON_CLAYMORE)
		self:SetCameraTarget(vector.modifyz(self:GetViewCameraDir(), 0.3, 1))
	else
		error("invalid explosive type")
	end

	------------------
	-- "plant"/"throw"
	-- !!UPDATE OR NULLIFY WITH EVERY THROW/PLANT REQUEST !!!
	hExplosive.weapon:SetPlantPredicate(RWI_GetPos(self:GetViewCameraPos(), vector.modifyz(self:GetViewCameraDir(), -0.8), 999))
	self:PressKey(KEY_ATTACK, PRESS_KEY)
	hExplosive.weapon:RequestStartFire()
	hExplosive.weapon:RequestStopFire()

	------------------
	-- set timer
	self.EXPLOSIVE_PLANT_TIMER = timerinit()

	-- insert new item, this is bad. no projectile id for comparision
	table.insert(self.PLACED_EXPLOSIVES, {
		Explosive = hExplosive,
		ExplosiveID = hExplosive.id,
		Type = sType
	})

	-- fially, inform AI
	AIEvent("OnExplosivePlaced")
end

------------------------------
--- Init
Bot.ReloadWeapon = function(self, hWeapon)

	self.WEAPON_RELOAD_TIMER = timerinit()
	if (not self:GetItem(hWeapon.class)) then
		self:SetItem(hWeapon.class)
	else
		self:PressKey(KEY_RELOAD)
	end

end

------------------------------
--- Init
Bot.ClearTarget = function(self)

	local hTarget = self:GetTarget()
	if (hTarget) then
		hTarget.LAST_SEEN_TIMER = nil
		hTarget.LAST_SEEN_POS = nil
	end

	self.LAST_SEEN_CLEAR = nil
	--self.LAST_SEEN_TARGET = nil -- in SetTarget()

	self:StopMovement()
	self:SetTarget(NULL_ENTITY)
	self:StopShooting()
	self:ResetData(1)

	BotMainLog("tar clear")
end

------------------------------
--- Init
Bot.IsHostile = function(self)
	return (BOT_HOSITLITY > 0)
end

------------------------------
--- Init
Bot.UpdateTargets = function(self)

	if (not self:IsHostile()) then
		return
	end

	if (self:IsWallJumping() and not self:IsEndingWallJump()) then
		return false, BotMainLog("Walljumping")
	end

	local hNewTarget = self:CheckForTargets()
	local hTarget = self.CURRENT_TARGET
	if (hTarget) then

		if (self:IsSwimming()) then
			return false
		end

		if (not GetEntity(hTarget.id)) then
			return false, self:ClearTarget()
		end

		if (self:IsSpectating(hTarget)) then
			return false, self:ClearTarget()
		end

		local bDriving = self:IsDriving()

		local iSpeed = self:GetSpeed()
		local iTargetSpeed = self:GetSpeed(hTarget)
		local vTargetVel = self:GetVelocity(hTarget)

		local vPos = self:GetPos()
		local vTarget = hTarget:GetPos()
		local vTargetHead = self:GetBone_Pos(BONE_HEAD, hTarget)
		if (iTargetSpeed > 6) then
			vTargetHead.z = vTargetHead.z - 0.3
			if (iTargetSpeed > 10) then
				vTargetHead.z = vTargetHead.z - 0.5
			end
		end

		if (BOT_ADJUST_AIM > 0) then
			vTargetHead = vector.add(vTargetHead,
					vector.scale(vTargetVel, (math.maxex(iTargetSpeed, 6) / 125))
			)
			BotMainLog("speed=%f",iTargetSpeed)
		end


		local vTargetLookAt = vTargetHead
		local iDistance = vector.distance(vTarget, vPos)

		if (iDistance > 15 and (self:IsItem_Current("DSG1") or self:IsItem_Current("GaussRifle"))) then
			if (iTargetSpeed > 1) then
				vTargetLookAt.z = (vTargetLookAt.z - 0.15)
			end
		end

		local bAlive = self:IsAlive(hTarget)
		local bVisible = self:IsVisible(hTarget)
		local hItem = self:GetItem()
		local bFists = (hItem and hItem.class == WEAPON_FISTS)
		local bAmmoOk = self:AmmoOk(hItem)

		BotMainLog("t = %s, alive = %s, visible = %s, new target = %s",
		hTarget:GetName(),
				string.bool(bAlive),
				string.bool(bVisible),
				tostring((hNewTarget))
		)

		if (hTarget and bAlive) then
			if (bVisible) then
				if (bDriving) then
					if (not self:UpdateVehicleShooting()) then
						self:LeaveVehicle()
						self:StopFire_Vehicle() -- place this everywhere the vehicle shoots!
					else
						return true
					end
				end

				self.RUNNING_TO_TARGET = nil
				if (bFists or (self.C4_GOTO_TARGET)) then
					BotMainLog("dist = %f",iDistance)
					if (iDistance > checkNumber(self.C4_GOTO_TARGET_DISTANCE, 2.25)) then

						if (not self:IsTarget_Reachable(hTarget)) then
							local idTarget = BotNavigation:GetTargetId()
							if (not idTarget or idTarget ~= hTarget.id) then
								BotNavigation:GetNewPath(hTarget) end

							BotNavigation:Update()
							BotNavigation.CURRENT_PATH_NODELAY = true
							BotNavigation.CURRENT_PATH_IGNOREPLAYERS = true

							self.FORCED_SPRINT = true
							self.FORCED_SUITMODE = NANOMODE_SPEED
							self.RUNNING_TO_TARGET = true
							--
						else
							self.FORCED_CAM_SPEED = 99
							self:StartMoving(MOVE_FORWARD, vTarget)
						end
					else

						BotNavigation:ResetPath()
						self:StartMoving(MOVE_FORWARD, vTarget)
						self.FORCED_CAM_LOOKAT = vTargetHead

						if (self:GetStance(STANCE_PRONE, hTarget)) then
							self:SetStance(STANCE_CROUCH, 1)
						end

						self:MeleeFists()
					end
				else

					self:ProcessCombatMovement()
					self.FORCED_CAM_LOOKAT = vTargetLookAt
					self.FORCED_CAM_SPEED = BOT_CAMERASPEED_COMBAT

					if (bAmmoOk) then

						if (iDistance < 1.5) then
							self:MeleeWeapon()
							self:StopShooting()
						else
							self:StartShooting()

						end
						BotMainLog("FIre ???")
					end
				end
			else

				if (hNewTarget and (self.LAST_SEEN_STARTTIMER and self.LAST_SEEN_STARTTIMER.expired(5))) then
					if (hNewTarget == hTarget) then

						local idTarget = BotNavigation:GetTargetId()
						if (not idTarget or idTarget ~= hTarget.id) then
							BotNavigation:GetNewPath(hTarget) end

						BotNavigation:Update()
						BotNavigation.CURRENT_PATH_NODELAY = true
						BotNavigation.CURRENT_PATH_IGNOREPLAYERS = true

						BotMainLog("GOING TO THEM !!")
						return true
					end

					BotMainLog("dead. ne target !!")
					self:SetTarget(hNewTarget)
					return true
				else

				end

				if (self:IsDriving()) then
					self:LeaveVehicle()
				end

				if (bFists) then
					if (self.RUNNING_TO_TARGET) then
						BotMainLog("goig to ????")
						local idTarget = BotNavigation:GetTargetId()
						if (not idTarget or idTarget ~= hTarget.id) then
							BotNavigation:GetNewPath(hTarget) end

						BotNavigation:Update()
						BotNavigation.CURRENT_PATH_NODELAY = true
						BotNavigation.CURRENT_PATH_IGNOREPLAYERS = true

						self.FORCED_SPRINT = true
						self.FORCED_SUITMODE = NANOMODE_SPEED
					else
						self:ClearTarget()
						return
					end
				else
					self:ProcessLastSeenMovement()
				end

				self:StopShooting()
			end
		elseif (hNewTarget) then
			BotMainLog("dead. ne target !!")
			self:SetTarget(hNewTarget)
			self:StopShooting()
			return true
		else

			if (bFists and iDistance < 5) then
				self:SetTarget(NULL_ENTITY)
				self:StopShooting()
				--return
			end

			if (not self:ProcessGotoDeathPos()) then
				self:ClearTarget()
			end
		end

		--BotMainLog("current target:: %s", hTarget:GetName())
		return true
	elseif (hNewTarget) then

		self.CURRENT_TARGET = hNewTarget
		self.CURRENT_TARGETID = hNewTarget.id

		return true, self:UpdateTargets()
	end

	return false -- No target
end

------------------------------
--- Init
Bot.SetLastSeen = function(self, bActivate)
	self.LAST_SEEN_MOVING = (bActivate)
end

------------------------------
--- Init
Bot.SetLastSeenTarget = function(self, hTarget)
	self.LAST_SEEN_TARGET = (hTarget)
end

------------------------------
--- Init
Bot.GetLastSeen = function(self, bActivate)
	return (self.LAST_SEEN_MOVING)
end

------------------------------
--- Init
Bot.GetLastSeenEntity = function(self, sMember)

	local hTarget = self.LAST_SEEN_TARGET
	if (not hTarget) then
		return nil
	end

	if (sMember) then
		return hTarget[sMember]
	end

	return hTarget
end

------------------------------
--- Init
Bot.ProcessLastSeenMovement = function(self)

	if (not self.LAST_SEEN_STARTTIMER) then
		self.LAST_SEEN_STARTTIMER = timernew()
	end

	self:SetLastSeen(false)
	self:SetLastSeenTarget()

	local hNewTarget = self:CheckForTargets()
	local hTarget = self.CURRENT_TARGET
	if (not hTarget) then
		return
	end

	self.LAST_SEEN_CLEAR = checkVar(self.LAST_SEEN_CLEAR, math.random(3, 7))

	local hTimer = hTarget.LAST_SEEN_TIMER
	if (hTimer and timerexpired(hTimer, self.LAST_SEEN_CLEAR)) then
		self:ClearTarget()
		return
	end

	if (self:IsSwimming()) then
		self:ClearTarget()
		return
	end

	local vTarget = hTarget.LAST_SEEN_POS
	if (not vTarget) then
		vTarget = self:GetBone_Pos(BONE_HEAD, hTarget)
		hTarget.LAST_SEEN_POS = vTarget
	end
	local vPos = self:GetPos()
	local iDistance = vector.distance(vTarget, vPos)

	self:ProcessCombatMovement(0.1, true)
	self.FORCED_CAM_LOOKAT = vTarget
	self.LAST_SEEN_TARGET = hTarget

	if (not hTimer) then
		hTarget.LAST_SEEN_TIMER = timerinit()
	end

	self:SetLastSeen(true)
	self:SetLastSeenTarget(hTarget)
	BotMainLog("LAST SEEN !!")
end

------------------------------
--- Init
Bot.ProcessGotoDeathPos = function(self)

	local hNewTarget = self:CheckForTargets()
	local hTarget = self.CURRENT_TARGET
	if (not hTarget or hNewTarget) then
		return false
	end

	local iDistance = self:GetDistance(hTarget)
	if (iDistance > 5) then
		return false
	end

	-- todo: make this
	return false--, self:ClearTarget()

	--[[
	BotMainLog("goig to ????")
	local idTarget = BotNavigation:GetTargetId()
	if (not idTarget or idTarget ~= hTarget.id) then
		BotNavigation:GetNewPath(hTarget) end

	BotNavigation:Update()
	BotNavigation.CURRENT_PATH_NODELAY = true
	BotNavigation.CURRENT_PATH_IGNOREPLAYERS = true
	--]]
end

------------------------------
--- Init
Bot.ProcessCombatMovement = function(self, iTimerExpire, bNoSniping)

	local hItem = self:GetItem()
	local hTarget = self:GetTarget()
	local vTarget = hTarget:GetPos()
	local vPos = self:GetPos()
	local iDistance = vector.distance(vTarget, vPos)

	if (hItem and (hItem.class == WEAPON_DSG or hItem.class == WEAPON_GAUSS)) then
		--bNoSniping = true
	end

	BotMainLog("%f",iDistance)

	-- stances
	self:ContinueStances(eStanceInterrupt_CampingPCM)

	if (not bNoSniping) then
		if (iDistance > 65) then-- and (hTarget:GetSpeed() < 10 or hTarget.actorStats.stance ~= STANCE_STAND)) then

			local iExpire = 6 -- force stop after this time (3s no camp)
			local iCampTime = 3 -- camp for this time (3s camp)
			if (iDistance > 200) then
				iExpire = 8
				iCampTime = 1
			end

			if (not self.PRONE_CAMP_TIMER or not self.PRONE_CAMP_TIMER.expired(iCampTime)) then

				BotMainLog("$6SNIPE")

				-- stance
				self:StartProne()
				self:InterruptStances(eStanceInterrupt_CampingPCM, STANCE_PRONE)

				-- timer
				self.PRONE_CAMP_TIMER = (self.PRONE_CAMP_TIMER or timernew())

				return
			elseif (self.PRONE_CAMP_TIMER.expired(iExpire)) then

				self.PRONE_CAMP_TIMER = nil
			end

			BotMainLog("$6camping BAD")
		end
	end
	if (self:GetStance(STANCE_PRONE)) then
		self:SetStance(STANCE_STAND)
	end

	local hTimer = self.BOT_COMBAT_TIMER_LASTMOVE
	if (not timerexpired(hTimer, checkVar(iTimerExpire, 0.25)) and not self:IsStuck(1)) then
		return
	end

	-- fixme: New approach
	local sKey = ((math.random(1, 2) == 1) and MOVE_LEFT or MOVE_RIGHT)
	--local sKey = ((self.BOT_COMBAT_MOVEKEY == MOVE_RIGHT) and MOVE_LEFT or MOVE_RIGHT)
	-- broken, ALL BROKEN
	--if (sKey == MOVE_LEFT and self:GetObstacle_Left()) then
	--	sKey = MOVE_RIGHT
	--	BotMainLog("Obstacle to left, going right!!")
	--elseif (self:GetObstacle_Right()) then
	--	BotMainLog("Obstacle to right, going left!!")
	--	sKey = MOVE_LEFT
	--end

	if (sKey == MOVE_LEFT) then
		if (self:IsWater_Left(1.5)) then
			sKey = MOVE_RIGHT
		end
	elseif (self:IsWater_Right(1.5)) then
		sKey = MOVE_LEFT
	end

	if (sKey == MOVE_LEFT) then
		if (self:TargetNotVisibleFrom(eDirection_Left, self:GetHeadPos(hTarget), 0.8)) then
			BotMainLog("NOT going to left!")
			sKey = MOVE_RIGHT
		end
	elseif (self:TargetNotVisibleFrom(eDirection_Right, self:GetHeadPos(hTarget), 0.8)) then
		BotMainLog("NOT going to RIGHT!")
		sKey = MOVE_LEFT
	end

	-- !DEBUG:
	--SYSTEM_INTERRUPTED = true

	self:StartMoving(sKey, nil, 0.25)
	self.BOT_COMBAT_MOVEKEY = sKey
	self.BOT_COMBAT_TIMER_LASTMOVE = timerinit()
	self.BOT_FORCED_NOSPRINT = true

	BotMainLog("$4MOVE !! %s", sKey)
end

------------------------------
--- Init
Bot.TargetNotVisibleFrom = function(self, iDirection, vTarget, iDistance)

	local vCamPos = self:GetViewCameraPos()
	local vCamDir = self:GetViewCameraDir()
	local vCamDir_Right = vector.right(vCamDir)
	local vCamDir_Left = vector.left(vCamDir)

	local iScale = (1 + iDistance)

	local vCamPos_Right = vector.add(vCamPos, vector.scale(vCamDir_Right, iScale))
	local vCamPos_Left = vector.add(vCamPos, vector.scale(vCamDir_Left, iScale))

	local bVisible
	if (iDirection == eDirection_Left) then

		bVisible = (
				Pathfinding.CanSeeNode_Simple(vCamPos_Left, vTarget)
				or Pathfinding.CanSeeNode_Simple(vCamPos_Left, vector.modifyz(vTarget_Left, -0.5))
		)
		Pathfinding:Effect(vCamPos_Left, 0.1)
	elseif (iDirection == eDirection_Right) then

		bVisible = (
				Pathfinding.CanSeeNode_Simple(vCamPos_Right, vTarget)
						or Pathfinding.CanSeeNode_Simple(vCamPos_Right, vector.modifyz(vTarget_Left, -0.5))
		)
		Pathfinding:Effect(vCamPos_Right, 0.1)
	else
		error("bad direction")
	end

	--SYSTEM_INTERRUPTED = true
	return (not bVisible)
end

------------------------------
--- Init
Bot.AmmoOk = function(self, hCheck, iCheck, bIsPickup)

	local hItem = checkVar(hCheck, self:GetItem())
	if (not hItem) then
		return false
	end

	local hWeapon
	if (isString(hItem)) then
		--BotMainLog("Its a string !")
		hWeapon = self:GetItem(hItem)
	else
		--BotMainLog("Its a weapon handle ?? !")
		hWeapon = hItem
	end

	if (not (hWeapon and hWeapon.weapon)) then
		BotMainLog("Weapon %s not found (%s)", tostring(hWeapon), tostring(hItem))
		return false
	end

	local iAmmo
	local iClip
	local sAmmo = hWeapon.weapon:GetAmmoType()
	if (not sAmmo) then
		return
	end

	if (self:IsSpecialItem(hWeapon.class) and bIsPickup) then
		BotMainLog("Hello!")

		iClip = g_localActor.inventory:GetAmmoCapacity(sAmmo)
		iAmmo = g_localActor.inventory:GetAmmoCount(sAmmo)

		return (iAmmo > 0)
	else
		iAmmo = hWeapon.weapon:GetAmmoCount()
		iClip = hWeapon.weapon:GetClipSize()
	end

	if (iAmmo == nil or iAmmo < 1) then

		if (hCheck == WEAPON_RPG) then
			--BotMainLog("iammo=%f, iclip=%f, itest=%f", iAmmo, iClip, self:GetInventoryAmmo(hCheck))
		end

		BotMainLog("ammo nil or ammo < 1")
		return false
	end

	if (iCheck) then
		local iPercent = ((iClip / iAmmo) * 100)
		math.fix(iPercent)
		--BotMainLog("ammo score %% = %f>=%f=%s",iPercent,iCheck,string.bool((iPercent ~= INF and iPercent >= iCheck)))
		return (iPercent ~= INF and iPercent >= iCheck)
	end

	if (iAmmo >= 1) then
		return true
	end
end

------------------------------
--- Init
Bot.InventoryAmmoOk = function(self, hCheck, iCheck)

	local hItem = checkVar(hCheck, self:GetItem())
	if (not hItem) then
		return false
	end

	local hWeapon
	if (isString(hItem)) then
		hWeapon = self:GetItem(hItem)
	else
		hWeapon = hItem
	end

	if (not (hWeapon and hWeapon.weapon)) then
		return false
	end

	local iInventory = self:GetInventoryAmmo(hWeapon)
	return (checkVar(iCheck, 1) >= iInventory)
end

------------------------------
--- Init
Bot.InventoryEmpty = function(self, hItem)

	local hWeapon = hItem
	if (isString(hItem)) then
		hWeapon = g_localActor.inventory:GetItemByClass(hItem)
	end
	hWeapon = GetEntity(hItem)

	if (not (hWeapon and hWeapon.weapon)) then
		return false
	end

	local sAmmoType = hWeapon.weapon:GetAmmoType()
	if (not sAmmoType) then
		return false
	end

	local iCapacity = g_localActor.inventory:GetAmmoCapacity(sAmmoType)
	local iAmmo = g_localActor.inventory:GetAmmoCount(sAmmoType)

	return (iAmmo == 0)
end

------------------------------
--- Init
Bot.InventoryFull = function(self, hItem)

	local hWeapon
	if (isString(hItem)) then
		hWeapon = self:GetItem(hItem)
	else
		hWeapon = hItem
	end

	if (not (hWeapon and hWeapon.weapon)) then
		return false
	end

	local sAmmoType = hWeapon.weapon:GetAmmoType()
	if (not sAmmoType) then
		return false
	end

	local iCapacity = g_localActor.inventory:GetAmmoCapacity(sAmmoType)
	local iAmmo = g_localActor.inventory:GetAmmoCount(sAmmoType)

	return (iAmmo >= iCapacity)
end

------------------------------
--- Init
Bot.StartShooting = function(self)
	--self:ReleaseKey(KEY_ATTACK)

	if (BOT_BLOCK_WEAPONS > 0) then
		return
	end

	local hWeapon = self:GetItem()
	if (hWeapon) then
		hWeapon.weapon:RequestStartFire()
	end
	self:PressKey(KEY_ATTACK)
end

------------------------------
--- Init
Bot.StopShooting = function(self)
	local hWeapon = self:GetItem()
	if (hWeapon) then
		hWeapon.weapon:RequestStopFire()
	end
	self:ReleaseKey(KEY_ATTACK)
	BotMainLog("stop shoot !!")
end

------------------------------
--- Init
Bot.MeleeFists = function(self)
	local hCurrentItem = self:GetItem()
	if (not hCurrentItem or not hCurrentItem.class == "Fists") then
		return
	end

	if (self:GetSuitEnergy() >= 125) then
		self:SetSuit(NANOMODE_STRENGTH, 0.25)
	else
		self:SetSuit(NANOMODE_ARMOR)
	end

	if (timerexpired(self.MELEE_TIMER, 0.15)) then
		self:PressKey(KEY_ATTACK)
		self.MELEE_TIMER = timerinit()
	end
	--hCurrentItem.weapon:StartFire()
	--hCurrentItem.weapon:StopFire()
end

------------------------------
--- Init
Bot.MeleeWeapon = function(self)
	local hCurrentItem = self:GetItem()
	if (not hCurrentItem) then
		return
	end

	if (self:GetSuitEnergy() >= 125) then
		self:SetSuit(NANOMODE_STRENGTH, 0.25)
	else
		self:SetSuit(NANOMODE_ARMOR)
	end


	if (timerexpired(self.MELEE_TIMER, 0.15)) then
		self:PressKey(KEY_MELEE)
		self.MELEE_TIMER = timerinit()
	end
	--hCurrentItem.weapon:StartFire()
	--hCurrentItem.weapon:StopFire()
end

------------------------------
--- Init
Bot.UpdateProne = function(self)

	local bProning = self:GetStance(STANCE_PRONE)
	if (bProning and not self:OkToProne()) then
		BotMainLog("Stopping prone.. not ok!")
		self:StopProne()
	end
end


------------------------------
--- Init
Bot.UpdateStance = function(self)

	self:UpdateProne()

	local hTimer = self.STANCE_TIMER
	local iTime = self.STANCE_TIME
	--local bSet = true

	if (hTimer and iTime ~= -1) then
		if (timerexpired(hTimer, iTime)) then
			self:SetStance(STANCE_STAND)
			self.STANCE_TIMER = nil
			self.STANCE_TIME = nil
			--self.STANCE_MODE = nil
			--bSet = false
		end
	end

end

------------------------------
--- Init
Bot.CheckWallJump = function(self)

	if (not timerexpired(self.WALLJUMPING_END, 7)) then
		return
	end

--	BotMainLog("nav u")
	local 	bCanJump, iDataIndex,
			vSkipTo, iSkipTo = BotNavigation:ShouldWallJumpOnPath()

	if (bCanJump and not self:HasTarget()) then
		BotMainLog("should jump %s, on path %d skip to node %d from node %d", string.bool(bCanJump), iDataIndex, iSkipTo, BotNavigation.CURRENT_PATH_NODE)
		self:SpawnDebugEffect(BotNavigation:GetWallJumpStart(iDataIndex)[1],"13")
		self:SpawnDebugEffect(BotNavigation:GetWallJumpEnd(iDataIndex)[1], "23")

		self:SetWallJump(iDataIndex)
		BotNavigation:SetCurrentPathNode(iSkipTo, vSkipTo)
		--SYSTEM_INTERRUPTED = true
	end
end

------------------------------
--- Init
Bot.CheckRecorders = function(self)

	local aPlayers = GetPlayers()
	local iPlaying = 0
	local iSpectating = 0

	local bAlive, bDead, bSpectating
	for i, hPlayer in pairs(aPlayers) do
		if (hPlayer.id ~= g_localActorId) then

			bAlive = self:IsAlive(hPlayer)
			bDead = self:IsDead(hPlayer)
			bSpectating = self:IsSpectating(hPlayer)

			if (bAlive) then
				hPlayer.DEAD_TIMER = timerinit()
				hPlayer.SPECTATING_TIMER = nil
			end

			if (bSpectating and not hPlayer.SPECTATING_TIMER) then
				hPlayer.SPECTATING_TIMER = timerinit()
			end

			if ((bSpectating and timerexpired(hPlayer.SPECTATING_TIMER, 30)) or timerexpired(hPlayer.DEAD_TIMER, 60)) then
				iSpectating = iSpectating + 1
			else
				iPlaying = iPlaying + 1
			end
		end
	end

	if (iPlaying == 0 and g_gameRules.class ~= "PowerStruggle") then
	--	BotMainLog("NO ONE PLAYING!")
		return false
	else
		self.FORCED_PATH_DELAY = 0
	end

	return true
end

------------------------------
--- Init
Bot.GoIdle = function(self)

	self:StopMovement()
	self:SetStance(STANCE_PRONE)
	self:SetItem("Fists")

	self.IN_IDLE = true
end

------------------------------
--- Init
Bot.StopIdle = function(self)
	self:SetStance(STANCE_STAND)
	self.IN_IDLE = false
end

------------------------------
--- Init
Bot.IsIdle = function(self)
	return (self.IN_IDLE)
end

------------------------------
--- Init
Bot.ResetCommonEx = function(self)

	----------------
	--- RESET COMMON EX
	--- EVERY OTHER FRAME!
	self.FRAMES_PASSED = 0

	-- stances
	--self.FORCED_STANCE = nil
	--self.FORCED_PRONE = nil
end

------------------------------
--- Init
Bot.ResetCommon = function(self)


	----------------
	--- RESET COMMON
	--- EVERY FRAME!
	--self.GOTO_TARGET = nil
	--self.GOTO_TARGET_DISTANCE = nil

	-- stances
	self.FORCED_STANCE = nil

	-- find vehicle
	self:ContinueMovement(eMovInterrupt_EnterUber)
	self:ContinueCamMovement(eMovInterrupt_EnterUber)

	-- (PS) capture from inside a vehicle
	self:ContinueMovement(eMovInterrupt_CaptureInVehicle)

	-- explosives
	self:ContinueMovement(eMovInterrupt_PlaceExplosive)
	self:ContinueCamMovement(eMovInterrupt_PlaceExplosive)

	self.FORCED_CAM_LOOKAT = nil
	self.BOT_FORCED_NOSPRINT = nil
	----------------

	BotAI.PAUSE_UPDATE = false

	----------------
end

------------------------------
--- Init
Bot.UpdateMovement = function(self)

	if (BOT_MOVEMENT <= 0) then
		return self:StopMovement()
	end

	if (BOT_GO_IDLE) then
		if (not self:CheckRecorders()) then
			if (not self:IsWallJumping() and timerexpired(self.WALLJUMPING_END, 1)) then
				if (AIEventGet("CanGoIdle", { 0xDEAD, AIEVENT_OK })) then
					return self:GoIdle()
				end
			end
		elseif (self:IsIdle()) then
			self:StopIdle()
		end
	end

	self:UpdateStance()
	self:UpdateJump()
	self:UpdateSuitMode()
	self:UpdateIndoorsVar()
	self:UpdateTerrainVar()
	self:UpdateVehicleVar()
	self:UpdateDriving()
	self:UpdateExplosives()

	local bUpdateNavi = true
	local bFindVehicle = false
	if (self:UpdateTargets()) then
		bUpdateNavi = false
		if (self:IsWallJumping()) then
			self:StopWallJump()
		end
	elseif (not self:HasTarget()) then
		bFindVehicle = true
	end

	self:UpdateInventory()
	self:UpdateCurrentItem()

	if (self:HasGrab()) then
		bUpdateNavi = false
		bFindVehicle = false
		BotMainLog("grab, dont update navi or vehicles")
	end

	if (bUpdateNavi and self:UpdateWallJump()) then
		bUpdateNavi = false
		bFindVehicle = false
	end

	local hTimerEnter_Vehicle = self.ATTEMPT_ENTER_SEAT_TIMER
	local hTimerSwitch_Seat = self.ATTEMPT_ENTER_SEAT_TIMER

	if (hTimerEnter_Vehicle and not hTimerEnter_Vehicle.expired()) then
		bUpdateNavi = false
	end
	if (hTimerSwitch_Seat and not hTimerSwitch_Seat.expired()) then
		bUpdateNavi = false
	end

	--BotMainLog("!we have a grab..%s",string.bool(bUpdateNavi))
	self:ContinueMovement(eMovInterrupt_FindUber)
	if (bUpdateNavi) then
		BotNavigation:Update()

		if (not self:IsDriving()) then
			self:CheckWallJump()
		end

		if (bFindVehicle and not self:HasTarget()) then
			self:FindVehicle()
		end
	end

	local aMove = self.CURRENT_MOVEMENT
	if (aMove) then

		self:UpdateStuckVar()

		local hTarget = self:GetTarget()

		local vLookAt = vector.copy(aMove.vGoal)
		if (BOT_SMOOTHEN_MOVEMENT) then
			vLookAt.z = vLookAt.z + self:GetHeadHeight()
		end

		local bSprint = ((self.FORCED_SPRINT or (
			--not self:StartedOrEndingPath(3) and -- in OkToSprint because this is depending on our current suit mode
			self:OkToSprint() and
			not self:CloseToPathGoal() and
			timerexpired(self.LAST_JUMP_TIMER, 1))) and
			not self.BOT_FORCED_NOSPRINT
		)

		if (bSprint) then
			self:StartSprinting()
		else
			self:StopSprinting()
		end

		local bStuck = self:IsStuck(0.15)
		local bObstacle, iPreferredSuit = self:GetJumpableObstacle()
		if (bObstacle and bStuck) then
			if (self:OkToJump() and timerexpired(self.MELEE_TIMER, 2.5)) then
				if (table.count(BotNavigation.CURRENT_PATH_ARRAY) > 0) then
					self:StartJump()
					BotMainLog("stuck jump ->")
					--self:StopJump()
				end
			end
		end

		local bSwimming = self:IsSwimming()
		if (bSwimming) then
			if (not BotNavigation:IsCurrentNodeUnderwater()) then
				self:StartJump()
				--BotMainLog("Swimming and node is on solid ground!")
			else
				--BotMainLog("assuming swim..")
			end
		end

		local bObstacle_Crouch = (false and self:GetCrouchableObstacle())
		if (bObstacle_Crouch and bStuck) then
			self:SetStance(STANCE_CROUCH, 2.5)
			self.UNSTUCK_CROUCHING = true
		elseif (self.UNSTUCK_CROUCHING) then
			self:SetStance(STANCE_STAND)
			self.UNSTUCK_CROUCHING = nil
		end

		--local bSwimming = self:IsSwimming()
		--local bNodeUnderwater = BotNavigation:IsCurrentNodeUnderwater()
		--if (bSwimming and not bNodeUnderwater) then
		--	BotMainLog("bNodeUnderwater = %s",tostring(bNodeUnderwater))
		--	self:StartJump()
		--end

		local hDoor = self:GetRayHitInfo(RH_GET_ENTITY)
		if (hDoor and hDoor.class == "Door") then
			if (timerexpired(hDoor.USE_TIMER, 1)) then
				hDoor.USE_TIMER = timerinit()
				hDoor:OnUsed(g_localActor)

				self.LAST_USED_DOOR = hDoor
				self.LAST_USED_DOOR_STATE = hDoor.action

				if (hDoor:IsClosed()) then
					self:InterruptMovement(eMovInterrupt_DoorPause, 0.5)
				end
			end
		elseif (hDoor and timerexpired(hDoor.USE_TIMER, 1)) then
			local hLastDoor = self.LAST_USED_DOOR
			local iLastState = self.LAST_USED_DOOR_STATE
			if (hLastDoor and (iLastState ~= hLastDoor.action)) then
				hLastDoor:OnUsed(g_localActor)

				self.LAST_USED_DOOR = nil
				self.LAST_USED_DOOR_STATE = nil
			end
		end

		self:SpawnDebugEffect(vLookAt)

		if (self.FORCED_CAM_LOOKAT) then
			self:SetCameraTarget(self.FORCED_CAM_LOOKAT) -- movement forced
		else
			if (BOT_SMOOTHEN_MOVEMENT) then
				self.LIMIT_VIEWDIR_Z = true
			end
			self:SetCameraTarget(vLookAt) -- movement normal
		end

		local aInfo = self.CJ_INFO
		local iCountToIndoors = BotNavigation:GetNodeCountToIndoors(1)
		local iDistance = BotNavigation:GetNodeDistance()
		if (iDistance and (not self:IsIndoors() or self:IsUnderground()) and (iCountToIndoors == nil or iCountToIndoors > 2)) then
			if (iDistance > 3) then
				self:ApplyCircleJump()
			elseif (iDistance < 2) then
				self:PauseCircleJump()
			end
			BotMainLog("ok!!")
		end
	else
		if (self.FORCED_CAM_LOOKAT) then
			self:SetCameraTarget(self.FORCED_CAM_LOOKAT) -- no movement forced
		end
		self.BOT_STUCK_TIME = 0.0
		--BotMainLog("no movement data available!")
	end

	self:ResetCommon()

	local iFrame = System.GetFrameID()
	if (self.FRAME ~= iFrame) then
		self.FRAMES_PASSED = (self.FRAMES_PASSED + 1)
	end

	if (self.FRAMES_PASSED >= 2) then
		--BotMainLog("2 passed..")
		self:ResetCommonEx()
	end

	--BotMainLog("frame..")
	self.FRAME = iFrame
end

------------------------------
--- Init
Bot.DetonateC4 = function(self)

	BotMainLog("detonate c4")

	if (not timerexpired(self.C4_DETONATION_TIMER)) then
		return
	end

	local hDetonator = self:GetItem(WEAPON_DETONATOR)
	if (hDetonator) then
		self:SetItem(WEAPON_DETONATOR)
		self:PressKey(KEY_ATTACK, PRESS_KEY)
		self.C4_DETONATION_TIMER = timerinit()
	end


end

------------------------------
--- Init
Bot.UpdateExplosives = function(self)

	local aExplosives = self.C4_LOCATIONS
	if (table.empty(aExplosives)) then
		return
	end

	if (self:HasTarget()) then
		return
	end

	local aNew = {}
	for _, aExplosive in pairs(aExplosives) do
		if (GetEntity(aExplosive.ExplosiveID)) then
			local aNearby = GetEntities(ENTITY_PLAYER, nil, function(a) return (a.id ~= self.id and not self:IsTarget_SameTeam(a) and self:IsAlive(a) and vector.distance(a:GetPos(), aExplosive.Position) < 10)  end)
			if (not table.empty(aNearby)) then
				self:DetonateC4()
			else
				table.insert(aNew, aExplosive)
			end
		end
	end

	self.C4_LOCATIONS = aNew
end

------------------------------
--- Init
Bot.GetOptimalCameraSpeed = function(self)

	local iSpeed = self:GetSpeed()
	local iThreshold = 10
	local iMaxSpeed = 10

	local iCamSpeed = math.limit(((iSpeed / iMaxSpeed) * 10), 1.5, 10)
	return iCamSpeed
end

------------------------------
--- Init
Bot.GetCombatCameraSpeed = function(self)

	local hTarget = self:GetTarget()
	if (not hTarget) then
		return self:GetOptimalCameraSpeed()
	end

	-----
	-- Global?
	local iMinSpeed_Visible = 99 -- !!FIXME
	local iMinSpeed_Hidden = 5

	-----
	local vPos = self:GetPos()
	local vTarget = hTarget:GetPos()
	local iDistance = vector.distance(vPos, vTarget)

	local iTargetSpeed = hTarget:GetSpeed()

	-----
	local iSpeed_Visible = math.minex(iTargetSpeed, iMinSpeed_Visible)
	local iSpeed_Hidden = math.minex(iTargetSpeed, iMinSpeed_Hidden)
	local bVisible = System.IsPointVisible(vTarget)

	-----
	local iSpeed = iSpeed_Visible
	if (not bVisible) then
		iSpeed = iSpeed_Hidden
	end

	-----
	BotMainLog("iSpeed = %f, bVisible = %s", iSpeed, g_ts(bVisible))

	-----
	if (iDistance < 15) then
		iSpeed = 100
	end
	return iSpeed
end

------------------------------
--- Init
Bot.SetCameraTarget = function(self, vTarget, iCamSpeed)

	------
	if (not self:GetCamMovementInterruption(eMovInterrupt_None)) then
		return
	end

	------
	local vHead = self:GetViewCameraPos()
	local vDir

	------
	if (vTarget == BOT_CAMERA_RELEASE) then
		g_localActor.actor:CancelSmoothDirection()
		return
	end

	------
	if (self:IsWallJumping()) then
		if (vTarget == BOT_CAMERA_WALLJUMP) then
			vDir = vector.getdir(self.FORCED_CAM_LOOKAT, vHead, true)
			g_localActor.actor:SetSmoothDirection(vDir, 10)
		end
		return
	end

	------
	local iSpeed = checkNumber(iCamSpeed, BOT_CAMERASPEED_AUTO)

	------
	if (self.FORCED_CAM_SPEED) then
		iSpeed = self.FORCED_CAM_SPEED
	end

	if (iSpeed == BOT_CAMERASPEED_AUTO) then
		iSpeed = self:GetOptimalCameraSpeed()
	end
	if (iSpeed == BOT_CAMERASPEED_COMBAT) then
		iSpeed = self:GetCombatCameraSpeed()
		BotMainLog("$4Camera speed is combat!!!")
	end

	------
	vDir = vector.getdir(vTarget, vHead, true)
	if (self.LIMIT_VIEWDIR_Z) then
		BotMainLog("vLookAt.z=%f",vDir.z)
		if (vDir.z < -0.3) then
			vDir.z = -0.3
		end
		if (vDir.z > 0.7) then
			vDir.z = 0.7
		end
	end
	if (iSpeed == BOT_CAMERASPEED_INSTANT) then
		g_localActor.actor:SetAngles(vector.getang(vTarget, vHead))
		BotMainLog("instant")
		iSpeed = 999
	end

	g_localActor.actor:SetSmoothDirection(vDir, iSpeed)
	--BotMainLog("camspeed=%f",iSpeed)

	--BotMainLog("cam speed = %f",iSpeed)

	------
	if (BOT_DEBUG_MODE) then
		--BotMainLog("%s", vector.tostring(vDir))
		CryAction.PersistantArrow(self:GetPos_Head(), 0.1, vDir, vDir, "arrow", 10)
	end

	------
	self.FORCED_CAM_SPEED = nil
	self.LIMIT_VIEWDIR_Z = nil
end

------------------------------
--- Init
Bot.StartMoving = function(self, iMode, vTarget, iKeyTime)

	local aKeyMap = {
		[MOVE_FORWARD] 	= { KEY_FORWARD, 	self:GetPos_Front(1) },
		[MOVE_BACKWARD] = { KEY_BACKWARD, 	self:GetPos_Back(1) },
		[MOVE_LEFT] 	= { KEY_LEFT, 		self:GetPos_Front(1, vector.rotaten(self:GetPos(), 1)) },
		[MOVE_RIGHT] 	= { KEY_RIGHT, 		self:GetPos_Front(1, vector.rotaten(self:GetPos(), 3)) },

		[VEHICLE_MOVE_FORWARD] 	= { KEY_V_FORWARD,	self:GetPos_Front(1) },
		[VEHICLE_MOVE_BACKWARD] = { KEY_V_BACKWARD, self:GetPos_Back(1) },
		[VEHICLE_MOVE_LEFT] 	= { KEY_V_LEFT, 	self:GetPos_Front(1, vector.rotaten(self:GetPos(), 1)) },
		[VEHICLE_MOVE_RIGHT] 	= { KEY_V_RIGHT, 	self:GetPos_Front(1, vector.rotaten(self:GetPos(), 3)) },
	}

	local sExtraKey
	local bReleaseKey
	if (self.DRIVING_VEHICLE) then
		if (self.VEHICLE_TYPE == eVehicleType_Land) then

			if (iMode == MOVE_FORWARD) then
				iMode = VEHICLE_MOVE_FORWARD

				local iDirection, iDot = self:GetDirection(vTarget, self.VEHICLE_DIRECTION, 0.03)
				BotMainLog("->" ..iDirection)

				local bActionBack = self.VEHICLE_ACTION_GOBACK
				local bBehind = (bActionBack or (BitAND(iDirection, eDirection_Back) ~= 0))

				local hVehicle = self:GetVehicle()
				local vVehicle = hVehicle:GetPos()
				local bStaticBehind = self:GetStaticEntitiesInFront(vector.modifyz(vVehicle, 1), vector.reverse(hVehicle:GetDirectionVector()), 7, hVehicle.id)
				if (bStaticBehind) then
					bBehind = false
				end


				if (bBehind) then
					self.VEHICLE_BACKUP_TIMER = timerinit()
				end
				if (bBehind or not timerexpired(self.VEHICLE_BACKUP_TIMER, 1)) then
					iMode = VEHICLE_MOVE_BACKWARD
				end

				--if (iDirection == eDirection_Left) then
				if (BitAND(iDirection, eDirection_Left) ~= 0) then

					if (not bActionBack and iMode == VEHICLE_MOVE_BACKWARD) then
						sExtraKey = KEY_V_RIGHT
					else
						sExtraKey = KEY_V_LEFT
					end

					self.VEHICLE_ACTION_STEER = timerinit()

					if (iDot > 0.2) then
						bReleaseKey = true
						self.VEHICLE_ACTION_SHARPTURN = true
						self.VEHICLE_ACTION_TURNLEFT = nil
						BotMainLog("slow down cowboy")
					end

					local hActionRightTimer = self.VEHICLE_ACTION_TURNLEFT
					if (hActionRightTimer and not bBehind) then

						if (hActionRightTimer.expired(0.8))  then
							self.VEHICLE_ACTION_TURNLEFT = timernew()
						elseif (hActionRightTimer.expired(0.3)) then
							sExtraKey = nil
						end
					else
						self.VEHICLE_ACTION_TURNLEFT = timernew()
					end

					if (sExtraKey) then
						BotMainLog("too the leeeft")
					end

				--elseif (iDirection == eDirection_Right) then
				elseif (BitAND(iDirection, eDirection_Right) ~= 0) then

					if (not bActionBack and iMode == VEHICLE_MOVE_BACKWARD) then
						sExtraKey = KEY_V_LEFT
					else
						sExtraKey = KEY_V_RIGHT
					end

					self.VEHICLE_ACTION_STEER = timerinit()

					if (iDot < -0.2) then
						bReleaseKey = true
						self.VEHICLE_ACTION_SHARPTURN = true
						self.VEHICLE_ACTION_TURNRIGHT = nil
						BotMainLog("slow down cowboy")
					end

					local hActionRightTimer = self.VEHICLE_ACTION_TURNRIGHT
					if (hActionRightTimer and not bBehind) then

						if (hActionRightTimer.expired(0.5))  then
							self.VEHICLE_ACTION_TURNRIGHT = timernew()
						elseif (hActionRightTimer.expired(0.3)) then
							sExtraKey = nil
						end
					else
						self.VEHICLE_ACTION_TURNRIGHT = timernew()
					end
					BotMainLog("too the RIGHT %s",sExtraKey)

				elseif (BitAND(iDirection, eDirection_Front) ~= 0) then
					sExtraKey = KEY_VEHICLE_BOOST
					BotMainLog("death center")

				end
			end

			self.VEHICLE_ACTION_GOBACK = nil
			BotMainLog("Drviving car ")
		end
	end

	local aMove = aKeyMap[iMode]
	if (not aMove) then
		return BotLogError("Invalid move type to Bot.StartMoving")
	end

	self:StopMovement()
	if (self.MOVEMENT_INTERRUPTED > eMovInterrupt_None) then
		if (self.MOVEMENT_INTERRUPTED_TIMER and self.MOVEMENT_INTERRUPTED_TIMER.expired()) then

			self:ContinueMovement()
			BotLog("Movement interruption timer has expired")
		else
			return BotLog("Movement interrupted (code %d)", self.MOVEMENT_INTERRUPTED)
		end
	end

	local sKey, vGoal = aMove[1], checkVar(vTarget, aMove[2])
	self:PressKey(sKey, checkVar(iKeyTime, -1))
	if (sExtraKey) then
		self:PressKey(sExtraKey, 0.05)
	end
	self.CURRENT_MOVEMENT = {
		sKey = sKey,
		vGoal = vGoal,
		iTime = _time
	};
end

------------------------------
--- Init
Bot.ContinueMovement = function(self, iCase)

	if (iCase and iCase ~= self.MOVEMENT_INTERRUPTED) then
		return
	end

	self.MOVEMENT_INTERRUPTED = eMovInterrupt_None
	self.MOVEMENT_INTERRUPTED_TIMER = nil
	self.MOVEMENT_INTERRUPTED_EXPIRY = nil
end

------------------------------
--- Init
Bot.GetMovementInterruption = function(self, iCase)

	if (iCase) then
		return (self.MOVEMENT_INTERRUPTED == iCase)
	end

	return self.MOVEMENT_INTERRUPTED
end

------------------------------
--- Init
Bot.InterruptMovement = function(self, iCase, iExpiry)

	if (self.MOVEMENT_INTERRUPTED == iCase) then
		if (not iExpiry or iExpiry == self.MOVEMENT_INTERRUPTED_EXPIRY) then
			return
		end
	end

	self.MOVEMENT_INTERRUPTED = iCase

	if (iExpiry) then
		self.MOVEMENT_INTERRUPTED_TIMER = callAnd(timernew, {}, { { 'setexpiry', iExpiry } })
		self.MOVEMENT_INTERRUPTED_EXPIRY = iExpiry
	end
end

------------------------------
--- Init
Bot.ContinueCamMovement = function(self, iCase)

	if (iCase and iCase ~= self.CAM_MOVEMENT_INTERRUPTED) then
		return
	end

	self.CAM_MOVEMENT_INTERRUPTED = eMovInterrupt_None
	self.CAM_MOVEMENT_INTERRUPTED_TIMER = nil
	self.CAM_MOVEMENT_INTERRUPTED_EXPIRY = nil
end

------------------------------
--- Init
Bot.GetCamMovementInterruption = function(self, iCase)

	if (iCase) then
		return (self.CAM_MOVEMENT_INTERRUPTED == iCase)
	end

	return self.CAM_MOVEMENT_INTERRUPTED
end

------------------------------
--- Init
Bot.InterruptCamera = function(self, iCase, iExpiry)

	if (self.CAM_MOVEMENT_INTERRUPTED == iCase) then
		if (not iExpiry or iExpiry == self.CAM_MOVEMENT_INTERRUPTED_EXPIRY) then
			return
		end
	end

	self.CAM_MOVEMENT_INTERRUPTED = iCase

	if (iExpiry) then
		self.CAM_MOVEMENT_INTERRUPTED_TIMER = timernew(iExpiry)
		self.CAM_MOVEMENT_INTERRUPTED_EXPIRY = iExpiry
	end
end

------------------------------
--- Init
Bot.ContinueStances = function(self, iCase)

	if (iCase and iCase ~= self.STANCES_INTERRUPTED) then
		return
	end

	self.STANCES_INTERRUPTED = eMovInterrupt_None
	self.STANCES_INTERRUPTED_TIMER = nil
	self.STANCES_INTERRUPTED_EXPIRY = nil
	self.STANCES_INTERRUPTED_EXCEPTION = nil
end

------------------------------
--- Init
Bot.InterruptStances = function(self, iCase, hException, iExpiry)

	if (self.STANCES_INTERRUPTED == iCase) then
		if (not iExpiry or iExpiry == self.STANCES_INTERRUPTED_EXPIRY) then
			return
		end
	end

	self.STANCES_INTERRUPTED = iCase
	self.STANCES_INTERRUPTED_EXCEPTION = hException

	if (iExpiry) then
		self.STANCES_INTERRUPTED_TIMER = timernew(iExpiry)
		self.STANCES_INTERRUPTED_EXPIRY = iExpiry
	end
end

------------------------------
--- Init
Bot.GetStanceInterruption = function(self, iCase, iException)

	if (iCase) then
		local bCase = (self.STANCES_INTERRUPTED == iCase)
		local bException = false
		if (self.STANCES_INTERRUPTED_EXCEPTION ~= nil and self.STANCES_INTERRUPTED_EXCEPTION == iException) then
			bException = (not self:GetStance(iException))
		end
		if (bException) then
			return true
		end
		return bCase
	end

	return self.STANCES_INTERRUPTED
end

------------------------------
--- Init
Bot.PressKey = function(self, sKey, iTime, bIsCJ)

	if (not sKey) then
		return
	end

	if (isArray(sKey)) then
		for i, pKey in pairs(sKey) do
			self:ReleaseKey(pKey)
		end
		return
	end

	if (not bIsCJ) then
		local hActionTimer = self.CJ_KeyTimers[sKey]
		if (hActionTimer and not hActionTimer.expired()) then
			return BotMainLog("blocked key input %s", sKey)
		end
	end

	g_localActor.actor:SimulateInput(sKey, 1, 1)
	BOT_PRESSED_KEYS[sKey] = {
		sKey,
		sKey,
		checkVar(iTime, -1),
		timerinit()
	}

	if (iTime == PRESS_KEY) then
		BOT_PRESSED_KEYS[sKey] = nil
		g_localActor.actor:SimulateInput(sKey, 0, 0)
	end

	if (bIsCJ) then
		self.CJ_KeyTimers[sKey] = timernew(3)
 	end

	--BotMainLog(0,"Pressing key %s",sKey)
end

------------------------------
--- Init
Bot.ReleaseKey = function(self, iKey)

	if (iKey == KEY_ALL) then
		for i, aKey in pairs(BOT_PRESSED_KEYS) do
			self:ReleaseKey(aKey[1])
		end
		return
	end

	if (not iKey) then
		return
	end

	local aKey = BOT_PRESSED_KEYS[iKey]
	if (not isArray(aKey)) then
		return
	end

	local sKey = aKey[2]
	if (sKey == KEY_ATTACK) then
		g_localActor.actor:SimulateInput(aKey[2], 2, 1)
	else
		g_localActor.actor:SimulateInput(aKey[2], 2, 0)
	end
	BOT_PRESSED_KEYS[iKey] = nil
end

------------------------------
--- Init
Bot.OnShutdown = function(self)
	self:StopAll()
end

------------------------------
--- Init
Bot.StopAll = function(self)
	self:ReleaseKey(KEY_ALL)
	self:SetCameraTarget(BOT_CAMERA_RELEASE) -- release
end

------------------------------
--- Init
Bot.StopMovement = function(self, iMode, vTarget)

	self.CURRENT_MOVEMENT = nil
	for i, sKey in pairs({
		"moveforward",
		"moveback",
		"moveright",
		"moveleft",
		"v_moveforward",
		"v_moveback",
		"v_turnleft",
		"v_turnright"
	}) do
		g_localActor.actor:SimulateInput(sKey, 2, 0)
		self:ReleaseKey(sKey)
	end

--	BotMainLog("stop move !!")
end

------------------------------
--- Init
Bot.GetHeadHeight = function(self, hActor)

	local vPos = checkVar(hActor, g_localActor):GetPos()
	local vHead = checkVar(hActor, g_localActor).actor:GetHeadPos()

	return (vHead.z - vPos.z - 0.35)
end

------------------------------
--- Init
Bot.GetVelocity = function(self, hCheck)
	return (checkVar(hCheck, g_localActor):GetVelocity())
end

------------------------------
--- Init
Bot.GetSpeed = function(self, hCheck)
	return (checkVar(hCheck, g_localActor):GetSpeed())
end

------------------------------
--- Init
Bot.WithinAngles = function(self, hTarget, iFov)

	------------------
	local sBoneName = BONE_HEAD
	local iThreshold = 2

	------------------
	local vPos = self:GetViewCameraPos()
	local vTargetPos1 = hTarget:GetBonePos(BONE_HEAD)
	local vTargetPos2 = hTarget:GetBonePos(BONE_PELVIS)

	------------------
	vTargetPos1 = {
		x = (vTargetPos1.x + vTargetPos2.x) / 2,
		y = (vTargetPos1.y + vTargetPos2.y) / 2,
		z = (vTargetPos1.z + vTargetPos2.z) / 2
	};

	------------------
	local iDX, iDY, iDZ = vTargetPos1.x - vPos.x, vTargetPos1.y - vPos.y, vTargetPos1.z - vPos.z
	local iDist = math.sqrt(iDX * iDX + iDY * iDY + iDZ * iDZ)
	local dir = { x = iDX / iDist, y = iDY / iDist, z = iDZ / iDist }

	------------------
	local aHitData = {}
	local iHits = Physics.RayWorldIntersection(vPos, vector.scale(dir, 8192), 8192, ent_terrain + ent_static + ent_rigid + ent_sleeping_rigid + ent_living, g_localActorId, nil, aHitData)
	local iEntsBefore = 0

	------------------
	local maxDeg = checkVar(iFov, BOT_VIEW_ANGLES)

	------------------
	if (iHits > 0) then
		for i, v in pairs(aHitData) do
			if (v.entity) then
				if (v.entity.class == "Player" and v.entity.id == hTarget.id) then
					if (iEntsBefore < iThreshold and BotMath:Angle(dir, self:GetViewCameraDir()) < maxDeg) then
						return true
					else
						return false
					end
				end
			end
			iEntsBefore = iEntsBefore + 1
		end
	end
	return false
end

------------------------------
--- Init
Bot.GetDistance = function(self, pTarget)
	local vPos = self:GetPos()
	local vTarget
	if (vector.isvector(pTarget)) then
		vTarget = pTarget
	elseif (isArray(pTarget) and pTarget.GetPos) then
		vTarget = pTarget:GetPos()
	elseif (isUserdata(pTarget)) then
		local hEnt = GetEntity(pTarget)
		if (hEnt) then
			vTarget = hEnt:GetPos()
		end
	end

	return (vector.distance(vPos, vTarget))
end

------------------------------
--- Init
Bot.IsEnt_Behind = function(self, vPos)
	return (not self:WithinAngles(vPos, 160))
end

------------------------------
--- Init
Bot.IsPosition_Behind = function(self, vPos)
	local vProjection = System.ProjectToScreen(vPos)
	BotMainLog("%s",vector.tostring(vProjection))
end

------------------------------
--- Init
Bot.GetDirection = function(self, vTarget, vCam, iThreshold)

	local vPos = self:GetPos()
	local vCam = checkVar(vCam, self:GetViewCameraDir())

	local vDir = vector.getdir(vTarget, vPos, 1,1)
	local iDot_Dir = vector.dot(vCam, vDir)

	local iFlags = 0
	if (iDot_Dir < 0) then
		BotMainLog("behind")
		iFlags = eDirection_Back
	else
		BotMainLog("front")
	end

	local vCross = vector.cross(vCam, vDir)

	local iDot = vector.dot(vCross, vectors.up)
	iThreshold = checkNumber(iThreshold, 0.1)

	local iDot2 = math.abs(iDot)
	if (iDot2 > iThreshold) then
		if (iDot < 0) then
			return BitOR(iFlags, eDirection_Right), iDot2
		elseif (iDot > 0) then
			return BitOR(iFlags, eDirection_Left), iDot2
		end
	else
		return eDirection_Front, iDot2
	end
end

------------------------------
--- Init
Bot.GetBone_Dir = function(self, sBone, hEntity)
	return (checkVar(hEntity, g_localActor):GetBoneDir(sBone))
end

------------------------------
--- Init
Bot.GetBone_Pos = function(self, sBone, hEntity)
	return (checkVar(hEntity, g_localActor):GetBonePos(sBone))
end

------------------------------
--- Init
Bot.GetDir = function(self)
	return (g_localActor:GetDirectionVector())
end

------------------------------
--- Init
Bot.GetPos = function(self, hCheck)
	if (not g_localActor) then
		return
	end
	return ((hCheck or g_localActor):GetPos())
end

------------------------------
--- Init
Bot.GetPos_Head = function(self, hCheck)
	if (hCheck) then
		return (hCheck.actor:GetHeadPos())
	end
	return (g_localActor.actor:GetHeadPos())
end

------------------------------
--- Init
Bot.GetHeadPos = Bot.GetPos_Head

------------------------------
--- Init
Bot.GetPos_Front = function(self, iDistance, vStart)

	local vDir = self:GetViewCameraDir()
	local vHere = checkVar(vStart, self:GetPos())
	vHere.x = (vHere.x + (vDir.x * iDistance))
	vHere.y = (vHere.y + (vDir.y * iDistance))
	vHere.z = (vHere.z + (vDir.z * iDistance))

	return vHere
end

------------------------------
--- Init
Bot.GetPos_Back = function(self, iDistance, vStart)

	local vDir = self:GetViewCameraDir()
	local vHere = checkVar(vStart, self:GetPos())
	vHere.x = (vHere.x - (vDir.x * iDistance))
	vHere.y = (vHere.y - (vDir.y * iDistance))
	vHere.z = (vHere.z - (vDir.z * iDistance))

	return vHere
end

------------------------------
--- Init
Bot.OnEnteredServer = function(self)
	ON_ENTER_SERVER_TIMER = timernew(15)
end

------------------------------
--- Init
Bot.OnRadio = function(self, sender, type, message)
end

------------------------------
--- Init
Bot.SendRadioMessage = function(self, iMessage)
	if (isNullAny(g_localActor, iMessage)) then
		return
	end

	g_gameRules.game:SendRadioMessage(g_localActorId, iMessage)
end

------------------------------
--- Init
Bot.OnWallJump = function(self, hPlayer)
	if (hPlayer == g_localActor) then
		Pathfinding:OnWallJump(g_localActor)
	end
end

------------------------------
--- Init
Bot.OnChatMessage = function(self, idSource, sMsg, iType)
	local hUser = GetEntity(idSource)
	BotChatAI.OnChatMessage(hUser, sMsg, iType)
end

------------------------------
--- Init
Bot.OnFlashbangBlind = function(self)
end

------------------------------
--- Init
Bot.OnPlayerJump = function(self, hPlayer, bIsBot, iChannel)
end

------------------------------
--- Init
Bot.OnHit = function(self, aHit)
end

------------------------------
--- Init
Bot.OnExplosion = function(self, aHit)
end

------------------------------
--- Init
Bot.OnTaggedEntity = function(self, idEntity, hEntity)
	if (not self.TAGGED_ENTITIES) then
		self.TAGGED_ENTITIES = {} end

	---------------------
	BotMainLog("Tagged")
	self.TAGGED_ENTITIES[idEntity] = timerinit()
end

------------------------------
--- Init
Bot.IsEntityTagged = function(self, idEntity)
	if (not self.TAGGED_ENTITIES) then
		self.TAGGED_ENTITIES = {} end

	---------------------
	return (not timerexpired(self.TAGGED_ENTITIES[idEntity], 20))
end

------------------------------
--- Init
Bot.OnKilled = function(self, nPlayer, nShooter, sWeapon, iDamage, sMat, iType)

	local hPlayer = GetEntity(nPlayer)
	local hShooter = GetEntity(nShooter)

	if (hPlayer == g_localActor) then
		self:ResetData()
		BotMainLog(0, "Bot Died, resetting all data")
	end

	if (not hShooter) then
		return
	end

	local vPos = self:GetPos()
	local vShooter = hShooter:GetPos()
	local vTarget = hPlayer:GetPos()

	local iDist_ShooterBot = vector.distance(vPos, vShooter)
	local iZDiff_ShooterBot = math.positive(vPos.z - vShooter.z)

	if (nPlayer == self.id) then
		if (string.matchex(sWeapon, WEAPON_GAUSS, WEAPON_DSG)) then
			if (iDist_ShooterBot > 100 and iZDiff_ShooterBot > 45) then -- camper
				self.CAMPER_INFO = {
					Camper = hShooter,
					Pos = vShooter,
					Timer = timernew(120)
				}
			end
		end
	end


	hPlayer.VAN_INVITATION_COUNTER = 0

end

------------------------------
--- Init
Bot.OnShoot = function(self, hPlayer, hWeapon, vHitPos)

	if (hPlayer.id == g_localActorId) then
		return
	end

	local vPos = self:GetPos()
	local vPlayer = hPlayer:GetPos()

	local iHitDistance = vector.distance(vHitPos, vPos)
	if (iHitDistance < 5) then
		self:OnShotAt(hPlayer, hWeapon)
	end

	hPlayer.LAST_FIRE_TIMER = timerinit()
end

------------------------------
--- Init
Bot.OnShotAt = function(self, hPlayer, hWeapon, vHit)

	if (self:HasTarget()) then
		return
	end

	if (self:IsTarget_SameTeam(hPlayer)) then
		-- !! TODO: funny reaction ?! shooting back?! hahahahahah ...
		return
	end

	local vPos = self:GetPos()
	local vPlayer = hPlayer:GetPos()
	local iDistance = vector.distance(vPlayer, vPos)
	local aVehicleWeapons = self:GetVehicleWeapons()

	local bOk = false
	if (iDistance < 300) then
		bOk = true
		if (self:IsDriving() and not aVehicleWeapons) then
			self:LeaveVehicle()
		end
	end

	if (not bOk) then
		return false, BotMainLog("Ignoring the DUDEEE")
	end

	BotMainLog("Setting target !!")
	self:SetTarget(hPlayer)
end

------------------------------
--- Init
Bot.OnRevive = function(self, hEntity)
	hEntity.VAN_INVITATION_COUNTER = 0
end

---------------------------------------------------------------------------------------------
function _StartupBot()

	BotLog("Initializing Bot")

	local bOk, sErr = pcall(Bot.Init, Bot)
	if (not bOk) then
		SetError("Failed to initialize the Bot", sErr)
		BotError(not _reload and Config.QuitOnHardError)
		return
	end

	BotLog("BotMain Initialized")
end

-------------------------------
_StartupBot()
