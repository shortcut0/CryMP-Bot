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
BOT_CAMERA_RELEASE = 0x1
BOT_CAMERA_WALLJUMP = 0x2
BOT_CAMERASPEED_AUTO = 0x1

BOT_DEBUG_MODE = true
BOT_ENABLED = 1
BOT_USE_ANGLES = 1
BOT_VIEW_ANGLES = 180
BOT_HOSITLITY = 1
BOT_CAN_WALLJUMP = true
BOT_BLOCK_WEAPONS = 0
BOT_ADJUST_AIM = 0

BOT_PRESSED_KEYS = checkGlobal(BOT_PRESSED_KEYS, {})

BOT_RAYWORLD_MAXDIST = 1024
RH_GET_ENTITY = 0x1
RH_GET_POS = 0x2
RH_GET_ALL = 0x4

BOT_ITEM_PRIORITY = {
	FY71 = 10,
	SCAR = 9,
	SMG = 8,
	DSG1 = 7,
	GaussRifle = 7,
	Shotgun = 6,
	Hurricane = 5,
	SOCOM = 4
}

BOT_WALLJUMP_RESET = -1

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

KEY_SPRINT = "sprint"
KEY_JUMP = "jump"
KEY_ATTACK = "attack1"
KEY_MELEE = "special"
KEY_RELOAD = "reload"

KEY_CROUCH = "crouch"
KEY_PRONE = "prone"
KEY_STAND = { "crouch", "prone" }

------------------------------

FRAMELOG_PRINTALL = -1
FRAMELOG_PRINTTHRESHOLD = nil

------------------------------
Bot = {}
Bot.aCfg = {}
Bot.aGlobals = {}
Bot.PressedKeys = {}

------------------------------
Bot.LOG_VERBOSITY = 69
Bot.FRAME_CALLS = {}
Bot.REVIVE_TIMERS = {}
Bot.BOT_STUCK_TIME = 0.0
Bot.BOT_DEFAULT_STUCK_TIME = 2.5
Bot.BOT_INDOORS_TIME = 2.5
Bot.BOT_FORCED_CVARS = {

	BOT_SIMPLYFIED_MELEE = 1,

	BOT_FORCED_SPREAD = 0.001,
	BOT_FORCED_RECOIL = 0.001,
	BOT_FORCED_RECOIL_MULTIPLIER = 0.001,

	BOT_SPRINT_SHOOTING = 1.0,

	CL_BOB = 0.0,

	BOT_AI_WALKMULT = 1.0,
	BOT_WALKMULT = 1.0,
}

Bot.FORCED_SPRINT = nil
Bot.BOT_FORCED_NOSPRINT = nil

Bot.BOT_COMBAT_MOVEKEY = nil
Bot.BOT_COMBAT_TIMER_LASTMOVE = nil

Bot.FORCED_CAM_SPEED = nil
Bot.FORCED_CAM_LOOKAT = nil

Bot.FORCED_SUITMODE = nil
Bot.FORCED_SUIT_MODE = nil
Bot.FORCED_SUIT_TIMER = nil

Bot.BOT_FORCED_FIREMODES = {
	Shotgun = 2,
}

Bot.FORCED_PATH_DELAY = nil

Bot.LAST_DEBUG_EFFECT = nil
Bot.LAST_DEBUG_EFFECTS = {}

------------------------------
--- Init
Bot.Init = function(self)

	---------------------------------------
	BotLog("Bot.Init()")

	---------------------------------------
	local bOk, sErr = nil
	bOk = self:LoadLibraries()
	if (not bOk) then
		return false, SetError("Failed to Load Bot Libraries", "Unknown Cause"), BotError()
	end

	------------------------------------
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
Bot.SetCVars = function(self)

	local aCVars = self.BOT_FORCED_CVARS
	for sName, pValue in pairs(aCVars) do
		Game.ForceCVar(sName, tostring(pValue))
	end

	BotMainLog("Forced %d CVars to predefined values", table.count(aCVars))

end

------------------------------
--- Init
Bot.InitCVars = function(self, aList)

	------------------------------
	local sPrefix = "BOT_"
	local aCVars = checkVar(aList, {
		{ "toggle", 	"BOT_ENABLED", 		 BOT_ENABLED, 		"Toggles the Bot System Update", "Bot:OnShutdown" },
		{ "hostility", 	"BOT_HOSITLITY", 	 BOT_HOSITLITY, 	"Toggles Bot Hostility", nil },
		{ "blockitems", "BOT_BLOCK_WEAPONS", BOT_BLOCK_WEAPONS, "Toggles the Bots ability to fire weapons", nil },
		{ "adjustAim", 	"BOT_ADJUST_AIM", 	 BOT_ADJUST_AIM, 	"Toggles adjusting aim direction based on the targets velocity and speed", nil },

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
		{ "test", 					"test_description", 	"BotLog('Function Called')" },
		{ "reload", 				"test_description", 	"Bot:Reload()" },
		{ "enable_frame_logging", 	"test_description", 	[[Bot:EnableFrameLogging()]] },
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
		hDoor.Properties.Rotation.fRange = Door.Properties.Rotation.fRange
		hDoor.Client.ClRotate = Door.Client.ClRotate
	end

	----------------------------------
	function Door.Client:ClRotate(bOpen, bFwd)
		self.action = (bOpen and DOOR_OPEN or DOOR_CLOSE)
		self:Rotate(bOpen, true) -- always open doors forwards relative to the user
	end

	----------------------------------
	for i, hDoor in pairs(System.GetEntitiesByClass("Door")) do
		hDoor.Client.ClRotate = Door.Client.ClRotate
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

	if (not self:LoadPathfinding()) then
		return false end

	if (not self:LoadNavigation()) then
		return false end

	if (not self:LoadAISystem()) then
		return false end

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
Bot.LoadUtilities = function(self)
	return self:LoadFile("Utilities.lua", "Utilities")
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
Bot.Reload = function(self, bClearData)
	BotMainLog(0, "Reloading file ... ");

	if (clearData) then
		Bot = nil
	end

	BOT_RELOADING = true

	if (not BotMain) then
		return BotLog("Bot.Reload() BotMain is Null")
	end

	BotMain:LoadConfigFile()
	BotMain:LoadBotCore()
end

------------------------------
--- Init
Bot.PreOnTimer = function(self, ts)

	if (not g_gameRules) then
		return
	end

	local s, e = pcall(self.OnTimer, self, g_gameRules.class == "PowerStruggle", (frameTime or System.GetFrameTime()));
	if (not s and e) then
		SetError("Script Error in OnTimer()", tostring(e))
		BotError(Bot.aCfg.quitOnSoftError, true);
	end
end

------------------------------
--- Init
Bot.PreOnHit = function(self, ...)
	local s, e = pcall(self.OnHit, self, ...);
	if (not s and e) then
		SetError("Script Error in OnHit()", e)
		BotError(Bot.aCfg.quitOnSoftError, true);
	end
end

------------------------------
--- Init
Bot.PreOnExplosion = function(self, ...)
	local s, e = pcall(self.OnExplosion, self, ...);
	if (not s and e) then
		SetError("Script Error in OnExplosion()", e)
		BotError(Bot.aCfg.quitOnSoftError, true);
	end
end

------------------------------
--- Init
Bot.OnTimer = function(self, ts)

	--------------------------------
	if (Pathfinding) then
		Pathfinding:OnTick() end

	--------------------------------
	if (BOT_ENABLED ~= 1) then
		return end

	--------------------------------
	if (not g_localActor) then
		return end

	--------------------------------
	BotAI.CallEvent("OnTimer", System.GetFrameTime())

end

------------------------------
--- Init
Bot.OnDisconnect = function(self, hPlayer, iChannel)
	BotMainLog(0, "Player %s Disconnecting on Slot %d", checkString(hPlayer:GetName(), "Unknown"), iChannel);
end

------------------------------
--- Init
Bot.OnPlayerConnected = function(self, hPlayer, iChannel)
	BotMainLog(0, "Player %s Connected on Slot %d", checkString(hPlayer:GetName(), "Unknown"), iChannel);
end

------------------------------
--- Init
Bot.PreUpdate = function(self, iFT)

	---------
	if (not g_gameRules) then
		return
	end

	local bOk, sErr = pcall(self.DoUpdate, self, g_gameRules.class == "PowerStruggle", (iFT or System.GetFrameTime()));
	if (not bOk) then
		SetError("Script Error in OnUpdate()", sErr)
		BotError()
	end
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
	local iBotFPS = 999

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
Bot.UpdateTest = function(self)
do return true end
	--local vPos = { x = 58, y = 50, z = 20 }
	--self:SpawnDebugEffect(vPos)
	--self:IsPosition_Behind(vPos)

	local hEnemy = GetEntity("test_player")
	local vEnemy = hEnemy:GetPos()
	local idEnemy = hEnemy.id

	--local bCanJump, iNode = BotNavigation:ShouldWallJump(vEnemy, idEnemy, g_localActorId)
	--if (bCanJump) then
	--	BotMainLog("should jump %s, on path %d", string.bool(bCanJump), iNode)
	--	self:SpawnDebugEffect(BotNavigation:GetWallJumpStart(iNode)[1],"1")
	--	self:SpawnDebugEffect(BotNavigation:GetWallJumpEnd(iNode)[1], "2")

	--	self:SetWallJump(iNode)
	--end

	self:UpdateWallJump()

	return false
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
		if (iCurrent <= 1 and vector.distance(vBot, vStart) > 1.25 and not self:IsStuck(1)) then
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
			local iDistance = vector.distance(vPos, vBot)

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
	self.WALLJUMPING_UPDATERATE = (System.GetFrameTime() * 0.005 )
	self.WALLJUMPING_LAST_MOVE = nil

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
Bot.DoUpdate = function(self, isPowerStruggle, deltaTime)

	--------------------------------
	Pathfinding:Update()

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

	--------------------------------
	self.FRAME_TIME = System.GetFrameTime()

	--------------------------------
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
	BotNavigation:ResetAll()

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
	self:SetStance(STANCE_PRONE)
end

------------------------------
--- Init
Bot.StopProne = function(self)
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

	if (not bSpeed) then
		return true
	end

	local iEnergy = self:GetSuitEnergy()
	--BotMainLog("energy=%f",iEnergy)

	if (iEnergy >= 25) then
		if (timerexpired(self.BOT_SPRINT_PAUSE, 5)) then
			if (self:StartedOrEndingPath(3)) then
				return false
			end
			if (self:IsIndoors()) then
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
	local vDir = vector.rotaten(self:GetViewCameraDir(), 1)
	return (self:GetObstacle(vSource, vDir, iDist))
end

------------------------------
--- Init
Bot.GetObstacle_Left = function(self, iDist)
	local vSource = self:GetBone_Pos("Bip01 Pelvis")
	local vDir = vector.rotaten(self:GetViewCameraDir(), 3)
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
	local vPos_Head = self:GetBone_Pos("Bip01 Head")
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
	local vPos_Head = self:GetBone_Pos("Bip01 Head")
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
Bot.UpdateStuckVar = function(self)

	local iSpeed = self:GetSpeed()
	local vCurr = self:GetPos()
	local vLast = self.BOT_LAST_POSITON

	if (vLast) then
		local iDistance = vector.distance(vCurr, vLast)
		if (iDistance < 0.15 or iSpeed <= 0.1) then
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
Bot.IsSwimming = function(self)
	return (self:GetStance(STANCE_SWIM))
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
		return
	elseif (not hEntity) then
		return
	end

	local hTarget = self.LAST_SEEN_TARGET
	if (hTarget) then
		hTarget.LAST_SEEN_POS = nil
	end

	self:SetTarget(NULL_ENTITY)
	self.CURRENT_TARGETID = hEntity.id
	self.CURRENT_TARGET = hEntity
	self.LAST_SEEN_TARGET = nil
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

	local bSameTeam = (self:GetTeam(g_localActorId) == self:GetTeam(hTarget.id))
	return (bSameTeam)
end

------------------------------
--- Init
Bot.IsTarget_Reachable = function(self, hTarget)

	local vTarget = self:GetPos_Head(hTarget)
	local iDistance = self:GetDistance(vTarget)

	local bVisible = (self:IsVisible_Entity(hTarget) and iDistance < 8)
	return (bVisible)
end
------------------------------
--- Init
Bot.IsTargetOk = function(self, hTarget, bSkipVisibility)

	---------------------------
	if (not hTarget) then
		return false end

	---------------------------
	local sTarget = hTarget:GetName()

	---------------------------
	local bSameTeam = g_gameRules.game:GetTeam(g_localActorId) == g_gameRules.game:GetTeam(hTarget.id)

	---------------------------
	if (g_gameRules.class ~= "InstantAction" and bSameTeam) then
		return false end

	---------------------------
	if (not timerexpired(self.FLASHBANG_BLIND_TIMER, 2.5)) then
		return false end

	---------------------------
	if (not self:IsAlive(hTarget)) then
		--BotMainLog("alive BAD for %s",hTarget:GetName())
		return false end

	return true
end

------------------------------
--- Init
Bot.ValidateTarget = function(self, hTarget, bIgnoreAng, bSkipVisibility)

	---------------------------
	if (BOT_HOSITLITY <= 0) then
		return false end

	---------------------------
	if (not self:IsTargetOk(hTarget, bSkipVisibility)) then
		return false
	end

	---------------------------
	local iDistance = self:GetDistance(hTarget)
	if (iDistance < 6 and self:IsEnt_Behind(hTarget)) then
		return true end

	---------------------------
	if (iDistance > 60 and not bIgnoreAng and BOT_USE_ANGLES and self:GetDistance(hTarget) > 5) then
		if (not self:WithinAngles(hTarget, BOT_VIEW_ANGLES)) then
			--BotMainLog("ang BAD")
			return false
		end
	end

	---------------------------
	--BotMainLog("target ok: %s", hTarget:GetName())
	return true
end

------------------------------
--- Init
Bot.CheckForTargets = function(self, iRadius, bSkipVisibility)

	local aPlayers = GetPlayers()
	if (table.empty(aPlayers)) then
		return
	end

	local bIgnoreAng = (self:HasTarget())

	local iMaxDistance = 85
	local vPos = self:GetPos()
	local aBest = { nil, checkVar(iRadius, -1) }
	local vPlayer, iDistance

	for i, hPlayer in pairs(aPlayers) do
		if (hPlayer.id ~= g_localActorId) then
			vPlayer = hPlayer:GetPos()
			iDistance = vector.distance(vPlayer, vPos)
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
Bot.SetStance = function(self, iStance, iTime)

	local aKeys = {
		[STANCE_CROUCH] = KEY_CROUCH,
		[STANCE_STAND] = KEY_STAND,
		[STANCE_PRONE] = KEY_PRONE
	}

	if (iStance == STANCE_STAND and self:GetStance(iStance)) then
		return
	end

	local bCurrentStance = self:GetStance(iStance)
	local iKey = aKeys[iStance]
	if (iStance == STANCE_STAND or not bCurrentStance) then
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

	local vEntity = self:GetBone_Pos("Bip01 Head", hEntity)
	local vPos = self:GetBone_Pos("Bip01 Head")

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
		return false
	end
	return (System.IsPointVisible(vPoint))
end

------------------------------
--- Init
Bot.IsVisible_Entity = function(self, hEntity)

	local vEntity = checkVar(self:GetBone_Pos("Bip01 Head", hEntity), hEntity:GetPos())
	local vPos = self:GetBone_Pos("Bip01 Head")

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
Bot.CanSee_Position = function(self, vTarget)
	if (not vector.isvector(vTarget)) then
		return
	end
	return Physics.RayTraceCheck(self:GetPos_Head(), vTarget, g_localActorId, checkVar(idEntity, checkVar(self:GetTargetId(), g_localActorId)))
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
Bot.UpdateSuitMode = function(self)

	local hTimer = self.FORCED_SUIT_TIMER
	if (hTimer and timerexpired(hTimer, self.FORCED_SUIT_TIME)) then
		self:SetSuit(self.FORCED_SUIT_MODE)
	else

		local iFinalSuit = NANOMODE_NULL
		local bIndoors = self:IsIndoors()

		if (not self:HasTarget()) then
			if (not timerexpired(self.BOT_SPRINT_PAUSE, 5)) then
				iFinalSuit = NANOMODE_ARMOR
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
	end

	---------------
	return iCount < iLimit
end

------------------------------
--- Init
Bot.SetItem = function(self, sClass)
	local hCurrentItem = self:GetItem()
	if (not hCurrentItem or hCurrentItem.class ~= sClass) then
		g_localActor.actor:SelectItemByName(sClass)
	end
end

------------------------------
--- Init
Bot.HasItem = function(self, sClass)
	return (g_localActor.inventory:GetItemByClass(sClass))
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

	if (not hWeapon.weapon) then
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
		local idWeapon = self:HasItem(sClass)
		if (not idWeapon) then
			return
		end
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
		return false
	end

	if (not GetEntity(hItem.id)) then
		return false
	end

	if (not self:IsVisible_Entity(hItem)) then
		if (timerexpired(self.CURRENT_GRAB_INVISIBLETIMER, 5)) then
			return false
		end
	else
		self.CURRENT_GRAB_INVISIBLETIMER = timerinit()
	end

	if (self:IsCarried(hItem)) then
		return false
	end

	if (not self:AmmoOk(hItem) or not self:CheckAmmoRestrictions(hItem)) then
		return false
	end

	local sItem = hItem.class
	if (not bIgnoreStock and not self:CanGrab_Category(sItem)) then
		local bHasItem = self:HasItem(sItem)
		if (not bHasItem or self:AmmoStockFull(sItem)) then
			return false
		end
	end

	local iDistance = self:GetDistance(hItem)
	if (iDistance > 20) then
		return false
	end

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
		BotNavigation:SetSleepTimer(0.15)
		self:StopMovement()
		BotMainLog("%f",iDistance)
		if (iDistance > 2 or not self:IsPointVisible(hItem)) then
			self:SetCameraTarget(vItem, 99)
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

	local hCurrent = self.CURRENT_PICKUP
	if (hCurrent) then
		return self:GrabItem()
	end

	local iRadius = 15
	local aPriorityList = BOT_ITEM_PRIORITY

	local aItems = GetEntities(GET_ALL, "weapon")
	if (table.empty(aItems)) then
		return
	end

	local bWallJumping = self:IsWallJumping()
	local vPos = self:GetPos()
	local iDistance

	local hItem, sItem
	local bCanGrab, hGrab
	local bStockFull
	local bGrabable, bGrabableEx, bCanGrabCategory
	local bHasItem
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

					hEmpty = self:HasEmptyItems(1)
					if (not bCanGrabCategory and bGrabableEx and not bHasItem) then
						if (hEmpty) then
							self:Drop(hEmpty)
							BotMainLog("AMMO EMPTY, DROPA DN SELET THIS NOW!!")
							bCanGrabCategory = true
						end
					end
					bCanGrab = ((bCanGrabCategory or not bStockFull) and self:AmmoOk(hItem))
					if (not bWallJumping and bCanGrab and bGrabable) then
						hGrab = hItem
						BotMainLog("%s - We can GRAB it!", sItem)
					end
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

	local hCurrentItem = self:GetItem()
	local aInventory = self:GetInventory()
	if (not isArray(aInventory)) then
		return false
	end

	local bSelected = false
	local iDistance = self:GetDistance(hTarget)
	local bAmmoOk = self:AmmoOk(hCurrentItem)
	BotMainLog("ammo ok= %s",string.bool(bAmmoOk))

	local bDSG = (self:HasItem(WEAPON_DSG) and self:AmmoOk(WEAPON_DSG))
	local bGauss = (self:HasItem(WEAPON_GAUSS) and self:AmmoOk(WEAPON_GAUSS))
	local bShotgun = (self:HasItem(WEAPON_SHOTGUN) and self:AmmoOk(WEAPON_SHOTGUN))

	local bSeekBetter = true
	local hCurrent = (self.CURRENT_ITEM)
	if (hCurrent) then
		bSeekBetter = (not self:AmmoOk(hCurrent) or hCurrent.class ~= "Fists" or not self:IsItem(hCurrent))
	end

	if (false and iDistance < 8 and bShotgun) then
		self:SetItem(WEAPON_SHOTGUN)
		BotMainLog("using shotgun!! %f",iDistance)
	elseif (iDistance > 75 and (bDSG or bGauss)) then
		self:SetItem((bGauss and WEAPON_GAUSS or WEAPON_DSG))
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
		end

		if (not bSelected and not bAmmoOk and not bForce) then
			BotMainLog("AMMO : BAD!")
			self:SetItem("Fists")
			self:FindItem()
		end
	end

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
			return
		end
	end

	BotMainLog("check inventory")

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
		self:SetItem("Fists")
		self:FindItem()
	else
		self:ReleaseKey(KEY_RELOAD)
	end

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

	self:StopMovement()
	self:SetTarget(NULL_ENTITY)
	self:StopShooting()
	self:ResetData(1)

	BotMainLog("tar clear")
end

------------------------------
--- Init
Bot.UpdateTargets = function(self)

	if (self:IsWallJumping() and not self:IsEndingWallJump()) then
		return BotMainLog("Walljumping")
	end

	local hNewTarget = self:CheckForTargets()
	local hTarget = self.CURRENT_TARGET
	if (hTarget) then

		if (not GetEntity(hTarget.id)) then
			return false, self:ClearTarget()
		end

		if (self:IsSpectating(hTarget)) then
			return false, self:ClearTarget()
		end

		local vPos = self:GetPos()
		local vTarget = hTarget:GetPos()
		local vTargetHead = self:GetBone_Pos("Bip01 Head", hTarget)

		local iSpeed = self:GetSpeed()
		local iTargetSpeed = self:GetSpeed(hTarget)
		local vTargetVel = self:GetVelocity(hTarget)

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
		local bFists = (hItem and hItem.class == "Fists")
		local bAmmoOk = self:AmmoOk(hItem)

		BotMainLog("t = %s, alive = %s, visible = %s, new target = %s",
		hTarget:GetName(),
				string.bool(bAlive),
				string.bool(bVisible),
				tostring((hNewTarget))
		)

		if (bAlive) then

			if (bVisible) then

				self.RUNNING_TO_TARGET = nil
				if (bFists) then
					BotMainLog("dist = %f",iDistance)
					if (iDistance > 2.25) then

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
					self.FORCED_CAM_SPEED = 99.99

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

				if (hNewTarget) then
					BotMainLog("dead. ne target !!")
					self:SetTarget(hNewTarget)
					return true
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
				return
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
Bot.ProcessLastSeenMovement = function(self)

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
		vTarget = self:GetBone_Pos("Bip01 Head", hTarget)
		hTarget.LAST_SEEN_POS = vTarget
	end
	local vPos = self:GetPos()
	local iDistance = vector.distance(vTarget, vPos)

	self:ProcessCombatMovement(0.1)
	self.FORCED_CAM_LOOKAT = vTarget
	self.LAST_SEEN_TARGET = hTarget

	if (not hTimer) then
		hTarget.LAST_SEEN_TIMER = timerinit()
	end

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
Bot.ProcessCombatMovement = function(self, iTimerExpire)

	local hTimer = self.BOT_COMBAT_TIMER_LASTMOVE
	if (not timerexpired(hTimer, checkVar(iTimerExpire, 0.25)) and not self:IsStuck(1)) then
		return
	end

	-- fixme: New approach
	local sKey = ((math.random(1, 2) == 1) and MOVE_LEFT or MOVE_RIGHT)
	--local sKey = ((self.BOT_COMBAT_MOVEKEY == MOVE_RIGHT) and MOVE_LEFT or MOVE_RIGHT)
	if (sKey == MOVE_LEFT and self:GetObstacle_Left()) then
		sKey = MOVE_RIGHT
		BotMainLog("Obstacle to left, going right!!")
	elseif (self:GetObstacle_Right()) then
		BotMainLog("Obstacle to right, going left!!")
		sKey = MOVE_LEFT
	end

	if (sKey == MOVE_LEFT) then
		if (self:IsWater_Left(1.5)) then
			sKey = MOVE_RIGHT
		end
	elseif (self:IsWater_Right(1.5)) then
		sKey = MOVE_LEFT
	end

	self:StartMoving(sKey)
	self.BOT_COMBAT_MOVEKEY = sKey
	self.BOT_COMBAT_TIMER_LASTMOVE = timerinit()
	self.BOT_FORCED_NOSPRINT = true

	BotMainLog("$4MOVE !! %s", sKey)
end

------------------------------
--- Init
Bot.AmmoOk = function(self, hCheck, iCheck)

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

	local iAmmo = hWeapon.weapon:GetAmmoCount()
	local iClip = hWeapon.weapon:GetClipSize()

	if (iAmmo == nil) then
		return false
	end

	if (iCheck) then
		local iPercent = ((iClip / iAmmo) * 100)
		math.fix(iPercent)
		BotMainLog("ammo score %% = %f>=%f=%s",iPercent,iCheck,string.bool((iPercent ~= INF and iPercent >= iCheck)))
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

	local iInventory = self:GetInventoryAmmo(hWeapon.class)
	return (checkVar(iCheck, 1) >= iInventory)
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
Bot.UpdateStance = function(self)

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

	--if (bSet) then
	--	self:PressKey(self.STANCE_MODE)
	--end
end

------------------------------
--- Init
Bot.CheckWallJump = function(self)
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
Bot.UpdateMovement = function(self)

	if (not self:CheckRecorders()) then
		if (not self:IsWallJumping() and timerexpired(self.WALLJUMPING_END, 1)) then
			return self:GoIdle()
		end
	elseif (self:IsIdle()) then
		self:StopIdle()
	end

	self:UpdateStance()
	self:UpdateJump()
	self:UpdateSuitMode()
	self:UpdateIndoorsVar()

	local bUpdateNavi = true
	if (self:UpdateTargets()) then
		bUpdateNavi = false
		if (self:IsWallJumping()) then
			self:StopWallJump()
		end
	end

	self:UpdateInventory()
	self:UpdateCurrentItem()

	if (self:HasGrab()) then
		bUpdateNavi = false
	end

	if (bUpdateNavi and self:UpdateWallJump()) then
		bUpdateNavi = false
	end

	--BotMainLog("!we have a grab..%s",string.bool(bUpdateNavi))
	if (bUpdateNavi) then
		BotNavigation:Update()
		self:CheckWallJump()
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
			self:StartJump()
			--self:StopJump()
		end

		local bObstacle_Crouch = (false and self:GetCrouchableObstacle())
		if (bObstacle_Crouch and bStuck) then
			self:SetStance(STANCE_CROUCH, 2.5)
			self.UNSTUCK_CROUCHING = true
		elseif (self.UNSTUCK_CROUCHING) then
			self:SetStance(STANCE_STAND)
			self.UNSTUCK_CROUCHING = nil
		end

		local bSwimming = self:IsSwimming()
		if (bSwimming) then
			self:StartJump()
		end

		local hDoor = self:GetRayHitInfo(RH_GET_ENTITY)
		if (hDoor and hDoor.class == "Door") then
			if (timerexpired(hDoor.USE_TIMER, 1)) then
				hDoor.USE_TIMER = timerinit()
				hDoor:OnUsed(g_localActor)

				self.LAST_USED_DOOR = hDoor
				self.LAST_USED_DOOR_STATE = hDoor.action
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
			self:SetCameraTarget(self.FORCED_CAM_LOOKAT)
		else
			self:SetCameraTarget(vLookAt)
		end
	else
		if (self.FORCED_CAM_LOOKAT) then
			self:SetCameraTarget(self.FORCED_CAM_LOOKAT)
		end
		self.BOT_STUCK_TIME = 0.0
		BotMainLog("no move")
	end

	self.FORCED_CAM_LOOKAT = nil
	self.BOT_FORCED_NOSPRINT = nil
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
Bot.SetCameraTarget = function(self, vTarget, iCamSpeed)

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
	if (iSpeed == BOT_CAMERASPEED_AUTO) then
		iSpeed = self:GetOptimalCameraSpeed()
	end

	------
	if (self.FORCED_CAM_SPEED) then
		iSpeed = self.FORCED_CAM_SPEED
	end

	------
	vDir = vector.getdir(vTarget, vHead, true)
	g_localActor.actor:SetSmoothDirection(vDir, iSpeed)
	--BotMainLog("cam speed = %f",iSpeed)

	------
	if (BOT_DEBUG_MODE) then
		--BotMainLog("%s", vector.tostring(vDir))
		CryAction.PersistantArrow(self:GetPos_Head(), 0.1, vDir, vDir, "arrow", 10)
	end

	------
	self.FORCED_CAM_SPEED = nil
end

------------------------------
--- Init
Bot.StartMoving = function(self, iMode, vTarget)

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

	local aMove = aKeyMap[iMode]
	if (not aMove) then
		return BotLogError("Invalid move type to Bot.StartMoving")
	end

	self:StopMovement()

	local sKey, vGoal = aMove[1], checkVar(vTarget, aMove[2])
	self:PressKey(sKey, -1)

	self.CURRENT_MOVEMENT = {
		sKey = sKey,
		vGoal = vGoal,
		iTime = _time
	};
end

------------------------------
--- Init
Bot.PressKey = function(self, sKey, iTime)

	if (not sKey) then
		return
	end

	if (isArray(sKey)) then
		for i, pKey in pairs(sKey) do
			self:ReleaseKey(pKey)
		end
		return
	end

	g_localActor.actor:SimulateInput(sKey, 1, 1)
	BOT_PRESSED_KEYS[sKey] = {
		sKey,
		sKey,
		checkVar(iTime, -1),
		timerinit()
	}

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
	self:SetCameraTarget(BOT_CAMERA_RELEASE)
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
	local sBoneName = "Bip01 head"
	local iThreshold = 2

	------------------
	local vPos = self:GetViewCameraPos()
	local vTargetPos1 = hTarget:GetBonePos("Bip01 head")
	local vTargetPos2 = hTarget:GetBonePos("Bip01 pelvis")

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
Bot.GetPos = function(self)
	return (g_localActor:GetPos())
end

------------------------------
--- Init
Bot.GetPos_Head = function(self)
	return (g_localActor.actor:GetHeadPos())
end

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
end

------------------------------
--- Init
Bot.OnRadio = function(self, sender, type, message)
end

------------------------------
--- Init
Bot.SendRadioMessage = function(self, iMessage)
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
Bot.OnChatMessage = function(self, sender, type, message)
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
Bot.OnKilled = function(self, idPlayer, idShooter, sWeapon, iDamage, sMat, iType)

	local hPlayer = GetEntity(idPlayer)
	if (idPlayer == g_localActorId) then
		BotMainLog(0, "Bot Died, resetting all data")
		self:ResetData()
	end

end

------------------------------
--- Init
Bot.OnShoot = function(self, hPlayer, hWeapon, vPos, vDir, bIsBot)
end

------------------------------
--- Init
Bot.OnRevive = function(self, hEntity)
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
