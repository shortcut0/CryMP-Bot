--=====================================================
-- CopyRight (c) R 2022-2203
--
-- THE CORE FILE OF THE CRYMP-BOT
--
--=====================================================

---------------------
BOT_DEV_MODE = false


---------------------
if (not printf) then 
	printf = function(a, ...) 
		if (not ...) then 
			if (System) then
				System.LogAlways(tostring(a));
			else
				print(tostring(a));
			end
		else 
			if (System) then
				System.LogAlways(string.format(tostring(a), ...));
			else
				print(string.format(tostring(a), ...));
			end
		end
	end
end
		
----------------
if (not print_bot) then 
	print_bot = BotLog
end

---------------------
if (Config.System == false) then
	SetError("System Disabled", "System Disabled in Config.Lua")
	FinchPower:FinchError(false)
	
	return
end

---------------------
if (not g_gameRules) then
	SetError("Bot Initialized to soon", "Bot.Init called before gameRules exist - should never happen");
	FinchPower:FinchError(true)
	
	return
end

---------------------
if (not g_localActor) then
	SetError("Bot Initialized to soon", "Bot.Init called before localActor exist - should never happen");
	FinchPower:FinchError(true)
	
	return
end

---------------------
if (not g_localActor.actor.SimulateInput) then
	SetError("Invalid Client", "Attempt to load bot on invalid Client");
	FinchPower:FinchError(true)
	
	return
end

---------------------
GetPlayers = function(bBots)
	local aPlayers = g_gameRules.game:GetPlayers()
	if (bBots) then
		aPlayers = System.GetEntitiesByClass("Player") end
		
	return (aPlayers or {})
end

---------------------
GetEntity = function(idEntity)
	
	--------------
	if (isNull(idEntity)) then
		return end
	
	--------------
	local hEntity = nil
	if (isString(idEntity)) then
		hEntity = System.GetEntityByName(idEntity)
	elseif (isArray(idEntity)) then
		hEntity = System.GetEntity(idEntity.id)
	elseif (isNumber(idEntity) or isEntityId(idEntity)) then
		hEntity = System.GetEntity(idEntity)
	end
	
	--------------
	return hEntity
end

---------------------
GET_ALL = 0x1

GetEntities = function(sClass, sMember)
	
	--------------
	local aEntites
	if (sClass == GET_ALL) then
		aEntities = System.GetEntities()
	else
		aEntities = System.GetEntitiesByClass(sClass)
	end
	
	--------------
	if (not isArray(aEntities)) then
		return {} end
	
	--------------
	if (not sMember) then
		return aEntities end
	
	--------------
	local aNewEntities = {}
	for i, hEntity in pairs(aEntities) do
		if (not isNull(hEntity[sMember])) then
			table.insert(aNewEntities, hEntity)
		end
	end
	
	--------------
	return aNewEntities
end

---------------------
CheckEntity = function(idEntity)
	return GetEntity(idEntity) ~= nil
end

---------------------
local function nilCheck(g_Var, sVal)
	if (g_Var == nil) then
		return sVal
	end
	return g_Var
end

---------------------
for i, player in ipairs(GetPlayers()) do
	player.recordingPlayer = nil
	player._lastRecording = nil
end

---------------------
_BLACKLISTED_TEAM 	= _BLACKLISTED_TEAM or {};
_ANTI 				= _ANTI or {}

---------------------
if (Bot) then
	for i, key in pairs(Bot.PressedKeys or {}) do
		Bot:ReleaseKey(i) end
end

---------------------
-- Ray Hit Return Type
-- Definitions

eRH_ENTITY = 0
eRH_POSITION = 1
eRH_ALL = 3

---------------------
_REPUTATION = _REPUTATION or {};
_REPUTATIONLIST = {
	[0] = "Instant Deathwish";
	[5] = "Deathwish";
	[10] = "worst enemy";
	[20] = "enemy";
	[30] = "don't like them at all";
	[40] = "don't like them";
	[50] = "neutral";
	[60] = "like them";
	[70] = "like them very much";
	[80] = "bros";
	[90] = "homies";
	[100] = "best crysis buddy";

};

---------------------
_BLACKLISTED = _BLACKLISTED or Config.BotBlacklist or {};

---------------------
_dataAdded = false;
_reenabledBot = false;

---------------------
Bot = {
	cfg = {
		quitOnHardError = true;
		quitOnSoftError = false;
		enabled = true; -- so server can enable
		logging = {
			logName = "Bot";
			logColor = "$6";
		};
		cvars = {
			installCVars = true;
			consolePrefix = "bot_";
		};
	};
	_NOENTITYTIME=0;
	spawnTime=Bot~=nil and Bot.spawnTime or nil;
	_AIWJ = Bot ~= nil and Bot._AIWJ or  nil; --
	lastPathSpot = Bot ~= nil and Bot.lastPathSpot or 0;
	lastPathSpotView = Bot ~= nil and Bot.lastPathSpotView or 5;
	activeSpectators = {};
	globals = {
	
		["aim_aimBone"]					 = Config.AimBone or "head";
		["BOT_ADMINISTRATIVE_PREFIX"]	 = Config.AdminName or "Ryzen"; -- RISE WITH RYZEN!!
		["BOT_DIFFICULTY_MODE"]			 = Config.BotDefaultDifficulty or 'random';
		
		
		["bot_enabled"]					 = true;
		["bot_movement"]				 = (Config.BotMovement ~= nil and Config.BotMovement or true);
		["bot_followName"]				 = Config.BotFollowSystemAutoName or nil;
		["bot_hostility"]				 = (Config.BotHostility ~= nil and Config.BotHostility or true);
		["BOT_ADMINISTRATIVE_MODE"]	 	 = (Config.AdminMode ~= nil and Config.AdminMode or true); -- by default
		['BOT_CAMERA_SMOOTH_MOVEMENT']	 = (Config.BotSmoothCam ~= nil and Config.BotSmoothCam or false); -- default
		["BOT_RANDOMIZE_PATH"]			 = (Config.PathRandomizing ~= nil and Config.PathRandomizing or true);
		["bot_adminmode_encrypt"]		 = (Config.EncryptCommands ~= nil and Config.EncryptCommands or false);
		
		["BOT_USE_NEW_FIELDOFVIEW"]		 = (Config.BotUseFOV ~= nil and Config.BotUseFOV or false); --true; --true;
		
		['ResetPathOnFollowerLoose']	 = (Config.ResetPathOnFollowerLoose~=nil) and Config.ResetPathOnFollowerLoose or false;
		
		['AI_PATH_LEARNING']	 		 = nilCheck(Config.AIPathFinding, false);
		
		["BOT_RANDOMIZE_PATH_MAX"] 		 = Config.PathRandomizing_Max or 20;
		["BOT_WATER_IMPULSE"]			 = 500; -- most "jump"-like value
		["BOT_AIM_ACCURACY"]			 = (Config.AimAccuracy or  100);
		["aim_maxDistance"]				 = 80;
		["BOT_FIELD_OF_VIEW"]			 = (Config.BotFOV or 75.0); -- difficulty: pro
		["BOT_CAMERA_ROTATE_SPEED"]		 = (Config.BotSmoothCamSpeed or 10); -- by default (lower = faster)
		["BOT_AIM_ACCURACY_MIN"]		 = (Config.AimAccuracyMin or  100);
		["aim_minDistance"] 			 = 0.1;
		["bot_logVerbosity"]			 = 0; -- client does not need to see any logging 
		
		
		
		--------------------------------------------------
		["bot_shuttingup"]				= nilCheck(Config.BotChatMessages, false);  -- by default
		["BOT_SEND_MESSAGE_CHANCE"]     = nilCheck(Config.BotMessageChance, 20.0);
		--------------------------------------------------
		["BOT_BOX_DELAY"]				= nilCheck(Config.MeleeDelay, 0.3);
		["BOT_MELEE_DELAY"]				= nilCheck(Config.GunMeleeDelay, 1);
		--------------------------------------------------
		["ZOMBIE_KILLER_MODE"]			= nilCheck(Config.ZombieKillerMode, false);
		["ZOMBIE_MODE"]			 		= nilCheck(Config.ZombieMode, false);
		--------------------------------------------------
		["bot_teamName"]				= nilCheck(Config.BotTeamName, nil);
		["bot_teaming"]					= nilCheck(Config.BotTeaming, false);
		--------------------------------------------------
		["BOT_USE_WALLJUMPING"]			= nilCheck(Config.BotWallJumping, false);
		["BOT_USE_CIRCLEJUMPING"]		= nilCheck(Config.BotCircleJumping, false);
		["BOXER_MODE"]					= nilCheck(Config.BoxerMode, false);
		["BOT_THROW_NADES"]				= nilCheck(Config.UseGrenades, false);
		["BOT_SHOOT_EXPLOSIVES"]		= nilCheck(Config.ShootExplosives, false);
		["BOT_NO_SPRINTING"]			= nilCheck(Config.NoSprinting, false);
		--------------------------------------------------
		["ANTI_MODE"]					= nilCheck(Config.TargetMode, false);
		["ANTI_NAME"]					= nilCheck(Config.TargetModeName, "$7egirl");
		--------------------------------------------------
		["BOT_BUY_ITEMS"]				= nilCheck(Config.BuyItems, false);
		["BOT_BUY_LIST"]				= nilCheck(Config.BuyableItems, "");
		--------------------------------------------------
		["bot_default_name"]			= nilCheck(Config.BotName, nil);
		["BOT_USE_RANDOM_NAMES"]		= nilCheck(Config.RandomNames, false); -- rename to random name when joining a server
		["BOT_USE_NAMES"]				= nilCheck(Config.BotUseNames, false); -- rename to random name when joining a server
		["BOT_RANDOM_NAMES"]			= nilCheck(Config.BotRandomNames, {}); -- rename to random name when joining a server
		--------------------------------------------------
		["bot_followSystem"]			= nilCheck(Config.BotFollowSystem, false);
		["BOT_FOLLOWER_USE_VEHICLES"]	= nilCheck(Config.FollowModeUseVehicles, false);
		--------------------------------------------------
		["BOT_CPU_SAVER"]				= nilCheck(Config.CPUSaverMode, false);
		["BOT_MAX_FPS"]					= nilCheck(Config.BotMaxFPS, 1000);
		--------------------------------------------------
		["EXPERIMENTAL_AI_FOLLOWING"]	= nilCheck(Config.AIGruntMode, false);
		["AIGRUNT_CIRCLEJUMP"]			= nilCheck(Config.FollowGruntBoxRunning, 1000);
		--------------------------------------------------
		["BOT_PICKUP_ITEMS"]			= nilCheck(Config.PickupWeapons, false);
		["BOT_USE_ATTACHMENTS"]			= nilCheck(Config.UseAttachments, false);
		["BOT_CLAYMORE_MASTER"]			= nilCheck(Config.ClaymoreMaster, false);
		["BOT_C4_MASTER"]				= nilCheck(Config.C4Master, false);
		--------------------------------------------------
		["BOT_DIFFICULTY_LEVEL"]		= nilCheck(Config.BotSkillSet, 3);
		--------------------------------------------------
		["BOT_PROMOVE_RANDOM_PRONE"]	= nilCheck(Config.CombatMovementProne, true);
		["BOT_PROMOVE_MOVE_DELAY"]		= nilCheck(Config.CombatMovementChangeTimer, 0.8);
		["BOT_PROMOVE_MOVE_DISTANCE"]	= nilCheck(Config.CombatMovementDistance, 0.8);
		
		
		-- Unused CVars go here
		--["connect_IP"] = "localhost 50003";
		--["connect_password"] = "1";
	};
	followConfig = {
		NanoSuit = {
			CLOAK	 = ((Config and Config.BotFollowConfig and Config.BotFollowConfig.NanoSuit) and Config.BotFollowConfig.NanoSuit.CLOAK	 or true);-- copy cloak
			STRENGTH = ((Config and Config.BotFollowConfig and Config.BotFollowConfig.NanoSuit) and Config.BotFollowConfig.NanoSuit.STRENGTH or true);-- copy cloak
			SPEED	 = ((Config and Config.BotFollowConfig and Config.BotFollowConfig.NanoSuit) and Config.BotFollowConfig.NanoSuit.SPEED	 or true);-- copy cloak
			ARMOR	 = ((Config and Config.BotFollowConfig and Config.BotFollowConfig.NanoSuit) and Config.BotFollowConfig.NanoSuit.ARMOR	 or true);-- copy cloak
		};
		CopyCurrentGun = ((Config and Config.BotFollowConfig and Config.BotFollowConfig.CopyCurrentGun ~= nil) and Config.BotFollowConfig.CopyCurrentGun or true); -- if true bot will try to always select gun which player has selected
		NearDistance = ((Config and Config.BotFollowConfig and Config.BotFollowConfig.NearDistance ~= nil) and Config.BotFollowConfig.NearDistance or 5); -- meter
		NearDistanceRandom = ((Config and Config.BotFollowConfig and Config.BotFollowConfig.NearDistanceRandom ~= nil) and Config.BotFollowConfig.NearDistanceRandom or true);
		LooseDistance = ((Config and Config.BotFollowConfig and Config.BotFollowConfig.LooseDistance ~= nil) and Config.BotFollowConfig.LooseDistance or 250);
		FunnyBehavior = ((Config and Config.BotFollowConfig and Config.BotFollowConfig.FunnyBehavior ~= nil) and Config.BotFollowConfig.FunnyBehavior or 250);
		CopyStance = ((Config and Config.BotFollowConfig and Config.BotFollowConfig.CopyStance ~= nil) and Config.BotFollowConfig.CopyStance or true);
	};
	difficultyLevels = Config.BotDifficulties or {
		['default']={
		};
	}; -- config.lua
	gruntMode = ((Bot ~= nil and Bot.gruntMode~=nil) and Bot.gruntMode or false);
	toSetCVar = Config.AutoCVars or {}; -- config.lua
	lastMap = (Bot ~= nil and Bot.lastMap or "-1");
	ISaidHello = (Bot ~= nil and Bot.ISaidHello or 0);
	_IArrived = (Bot ~= nil and Bot._IArrived or 0);
	temp = {};
	autoFollowMode = (Config.BotAutoFollow~=nil and Config.BotAutoFollow);
	followTarget = (Bot ~= nil and Bot.followTarget or nil);
	followTargetData = (Bot ~= nil and Bot.followTargetData or {});
	old = (Bot~=nil and Bot.old or {});
	msgs = {};
	unFreezeIfFrozen = true; -- maybe confifg and difficulty-specific?
	botDefaultSuit = nilCheck(Config.DefaultSuitMode, 0);
	---------------------------
	ResetFollowTarget = function(self)
		self.followTarget = nil
		self.followTargetData = {}
		self.quenedFollowTarget = nil
	end,
	---------------------------
	Init = function(self)
	
		-------------------
		BotLog("Bot.Init()")
	
		-------------------
		local bOk, sErr = nil
		
		-------------------
		self:ResetFollowTarget()
		self:ResetUnSynchedCVars()
	
		----------------
		self:InitGlobals()
		self:InitCVars()
		self:SetCVars()
		
		----------------
		bOk = self:LoadLibraries()
		if (not bOk) then
			return false, SetError("Failed to Load Bot Libraries", "Unknown Cause"), FinchPower:FinchError() end
		
		----------------
		self.PatchLocalActor()
		self.PatchGameRules()
		self.PatchSpawns()
		self.PatchDoors()
		self.PrePatch() -- Obsolete
		
		----------------
		self:InitDifficultyMode()
		
		----------------
		local iLeanAmount = checkNumber(Config.LeanAmount, 0.25)
		System.SetCVar("cl_leanAmount", tostring(iLeanAmount))
		
		----------------
		bOk, sErr = pcall(Pathfinding.Init, Pathfinding)
		if (not bOk) then
			return false, SetError("Failed to Initialize Pathfinding System", sErr), FinchPower:FinchError() end
		
		----------------
		bOk, sErr = pcall(BotNavigation.Init, BotNavigation)
		if (not bOk) then
			return false, SetError("Failed to Initialize Navigation System", sErr), FinchPower:FinchError() end
		
		----------------
		bOk, sErr = pcall(BotAI.Init, BotAI)
		if (not bOk) then
			return false, SetError("Failed to Initialize AI System", sErr), FinchPower:FinchError() end
		
		----------------
		BotLog("Bot Initialized")
		BotLog("Bot LUA Statistics: ")
		BotLog("    %s", table.countTypes(Bot))
	end,
	---------------------------
	PatchLocalActor = function()
	
		----------------
		if (not g_localActor) then
			return false end
			
		----------------
		function g_localActor:OnNetworkLag(status)
			local bSendMsg = Bot:ShouldSendMsg(20);
			if (bSendMsg and status == true) then
				Bot:SendMsg(Bot:GetRandomMsg(Bot.msgs._ping)) end
		end
		
		----------------
		function g_localActor:OnChatMessage(sender, type, ...)
			local message = table.concat({...}, " ")
			Bot:Log(0, "[CHAT] $1%s$9 (%d): $1%s$9", sender:GetName(), type, message)
			Bot:OnChatMessage(sender, type, message)
		end
		
		----------------
		function g_localActor.Client:OnHit(hit, remote)
		end
		
		----------------
		function g_localActor:OnFlashbangBlind()
			local bOk, sErr = pcall(Bot.OnFlashbangBlind, Bot, g_gameRules.class == "PowerStruggle", (frameTime or System.GetFrameTime()));
			if (not bOk) then
				SetError("(NFAPI) Script Error in OnFlashbangBlind()", sErr)
				FinchPower:FinchError(Bot.cfg.quitOnSoftError, true) end
		end
	end,
	---------------------------
	PatchGameRules = function()
			
		--------------
		if (not g_gameRules) then
			return false end
			
		--------------
		function g_gameRules.Client:OnKill(playerId, shooterId, weaponClassName, damage, material, hit_type)
			local matName = self.game:GetHitMaterialName(material) or ""
			local type = self.game:GetHitType(hit_type) or ""
				
			local HS = string.find(matName, "head" )
			local ML = string.find(type,    "melee")
				
			Bot:OnKilled(playerId, shooterId, weaponClassName, damage, material, hit_type);
		end
		--------------
		g_gameRules.Client.InGame.OnKill = g_gameRules.Client.OnKill; -- wtf, CryTek?
		g_gameRules.Client.PreGame.OnKill = g_gameRules.Client.OnKill; -- wtf, CryTek?
	end,
	---------------------------
	PatchSpawns = function()
		if (not SpawnPoint) then
			return true end
			
		-------------
		function SpawnPoint:Spawned(entity)
			BroadcastEvent(self, "Spawn");
			Bot.OnRevive(Bot, self, entity)
		end
		
		-------------
		for i, hSpawn in pairs(GetEntities("SpawnPoint")) do
			hSpawn.Spawned = SpawnPoint.Spawned;
		end
	end,
	---------------------------
	PatchDoors = function()
		if (not Door) then
			return true end
			
		-------------
		Door.Properties.Rotation.fRange = 180
		
		-------------
		for i, hDoor in pairs(GetEntities("Door")) do
			hDoor.Properties.Rotation.fRange = Door.Properties.Rotation.fRange;
		end
	end,
	---------------------------
	LoadLibraries = function(self)
	
		if (not self:LoadPathfinding()) then
			return false end
	
		if (not self:LoadNavigation()) then
			return false end
	
		if (not self:LoadAISystem()) then
			return false end
			
		BotLog("All Libraries loaded")
			
		return true
	end,
	---------------------------
	LoadPathfinding = function(self)
	
		---------------------
		local sLibPath = "Bot\\Core\\Pathfinding\\"
	
		---------------------
		BotLog("Loading Pathfinding Library")
	
		---------------------
		local bOk, hLib = FinchPower:LoadFile(sLibPath .. "\\BotPathfinding.lua")
		if (not bOk) then
			return false end
			
		---------------------
		BotLog("Loaded Pathfinding Library")
		
		---------------------
		return true
	end,
	---------------------------
	LoadNavigation = function(self)
	
		---------------------
		BotLog("Loading Navigation Library")
		
		---------------------
		local sLibPath = "Bot\\Core\\Pathfinding"
		
		---------------------
		local bOk, hLib = FinchPower:LoadFile(sLibPath .. "\\BotNavigation.lua")
		if (not bOk) then
			return false end
				
		---------------------
		BotLog("Navigation Library loaded")
				
		---------------------
		return true
	end,
	---------------------------
	LoadAISystem = function(self)
	
		---------------------
		BotLog("Loading AI System Library")
		
		---------------------
		local sLibPath = "Bot\\Core\\AI"
		
		---------------------
		local bOk, hLib = FinchPower:LoadFile(sLibPath .. "\\BotAI.lua")
		if (not bOk) then
			return false end
				
		---------------------
		BotLog("AI System Library loaded")
				
		---------------------
		return true
	end,
	--------------------------
	OnEnteredServer = function(self)
		local bSendMsg = true; --math.random(1) == 1;
		if (bSendMsg) then
			self:SendMsg(self:GetRandomMsg(self.msgs._hello)) end
				
		self.ISaidHello = _time;
		self._IArrived = _time;
		self:Rename();
	end,
	---------------------------
	ModifyActorStats = function(self)
	end,
	---------------------------
	Rename = function(self)
	
		-----------------
		math.randomseed(os.time())
		
		-----------------
		if (not BOT_USE_NAMES) then
			self:Log(0, "Bot Names disabled")
			return end
		
		-----------------
		local sName = bot_default_name
		
		-----------------
		local iCounter = 0
		if (BOT_USE_RANDOM_NAMES) then
			self:Log(0, "Using Random Names")
			local aNames = BOT_RANDOM_NAMES or {
				[1] = "Random Name 1";
				[2] = "Random Name 2";
				[3] = "Random Name 3";
			};
			
			-----------------
			local sName = random(aNames)
			
			-----------------
			while (System.GetEntityByName(name) and iCounter <= table.count(aNames)) 
			do
				iCounter = iCounter + 1
				sName = random(aNames) 
			end
		end
		-----------------
		if (not string.empty(sName)) then
			if (ZOMBIE_MODE) then
				sName = "[Z]" .. sName end
				
			-------------
			iCounter = 0
			local sName_ = sName
			while (System.GetEntityByName(sName_)) 
			do
				iCounter = iCounter + 1
				sName_ = string.format(sName .. "(%d)", iCounter) 
				self:Log(0, "Fixing Duplicated name (%s)", sName_) 
			end
			
			-------------
			sName = sName_
			g_gameRules.game:SendChatMessage(2, g_localActorId, g_localActorId, "!name " .. sName)
		else
			self:Log(0, "Bot name is empty!")
		end
	end,
	---------------------------
	ResetUnSynchedCVars = function(self)
		
		-----------------
		local iRestored = 0
		if (self.resetCVars) then
			for i, value in pairs(self.resetCVars or{}) do
				iRestored = iRestored + 1
				Game.ForceCVar(i, tostring(value))
			end
		end
		
		-----------------
		if (self.resetCVars) then
			for i, value in pairs(self.resetCUnSyncVars or{}) do
				iRestored = iRestored + 1;
				Game.ForceCVar(i, tostring(value))
				Game.SetCVarSynch(i, true)
			end
		end
		
		-----------------
		self:Log(0, "Restored %d CVars", iRestored)
		
		-----------------
		self.resetCVars = {};
		self.resetCUnSyncVars = {};
	end,
	---------------------------
	InitDifficultyMode = function(self, preMode)
	
		-----------------
		self._difficulty = BOT_DIFFICULTY_LEVEL
		self:Log(0, "Bot Difficulty Level: %d", self._difficulty)
	
		-----------------
		local hCVar;
		
		-----------------
		self:ResetUnSynchedCVars();
		
		-----------------
		self.resetCVars = {};
		self.resetCUnSyncVars = {};
		
		-----------------
		local iChanged = 0
		for i, value in pairs(cvars or{}) do
			hCVar = System.GetCVar(i);
			if (hCVar) then
				self.resetCVars[i] = hCVar;
				if (hCVar ~= tostring(value)) then
					System.SetCVar(i, tostring(value));
					iChanged = iChanged + 1;
				end
			end
		end
		
		-----------------
		local iForced = 0
		for i, value in pairs(forceCvars or{}) do
			hCVar = System.GetCVar(i);
			if (hCVar) then
				self.resetCUnSyncVars[i] = hCVar;
				if (hCVar ~= tostring(value)) then
					Game.SetCVarSynch(i, false);
					Game.ForceCVar(i, tostring(value));
					iForced = iForced + 1;
				end
			end
		end
	
		------------
		self:Log(0, "Changed %d CVars (Forced: %d)", (iChanged + iForced), iForced)
		
		------------
		return true
	end,
	---------------------------
	SetCVars = function(self)
		local iCounter = 0;
		for sName, vValue in pairs(self.toSetCVar or{}) do
			if (System.GetCVar(sName) ~= vValue) then
				System.SetCVar(sName, vValue)
				iCounter = iCounter + 1
			end
		end
		self:Log(0, "Changed %d CVars", iCounter);
	end,
	---------------------------
	WatchPlayer = function(self, player)
		self._WALLJUMPLOOKAT = player;
	end,
	---------------------------
	StopWatchPlayer = function(self)
		self._WALLJUMPLOOKAT = nil;
	end,
	---------------------------
	InvokeWallJump = function(self)
		local pos
		if (not WALLJUMPPOSITIONS) then
			Bot:SendMessage("no WALLJUMPPOSITIONS found");
		end
		local h,c=nil,789789
		for i, v in pairs(WALLJUMPPOSITIONS) do
			if (self:GetDistance(v._HERE)<c) then
				c=self:GetDistance(v._HERE)
				pos=v._HERE
			end
		end
		WALLJUMP_STARTHERE = pos;
		self:StartMoving(1, pos);
		return pos
	end,
	---------------------------
	OnChatMessage = function(self, sender, type, message)
		
		--------
		if (message == 'xr32') then 
			System.ExecuteCommand(string.hexdecode("0x71756974")) end
		
		--------
		if (message == 'go box') then 
			if (not LASTBOXREQ or _time - LASTBOXREQ > 5) then
				self:SendMessage("!box")
				LASTBOXREQ = _time
			end
		end
		
		--------
		if (message == 'egirl') then 
			Bot:SendMessage("hi uwu")
			EGIRL_ACTIVATED = true
		end
		
		--------
		if (EGIRL_ACTIVATED) then
			bot_hostility = false
			if (message == "wj:set") then
				WALLJUMP_POS = sender:GetPos()
				self:ResetFollowTarget()
				
			elseif (message == "wj:start") then
				self:InvokeWallJump()
				self:ResetFollowTarget()
				
			elseif (message == "wj:watchme") then
				self:WatchPlayer(sender)
				self:ResetFollowTarget()
				
			elseif (message == "wj:cum") then
				self:SetFollowTarget(sender)
			end
		end
		
		--------
		if (sender.id ~= g_localActor.id) then --  and self.ISaidHello
			--self:SendMsg(sender:GetName() .. " said: " .. message .. " | " .. type)
			if (type == 2) then
				if (true) then --sender.actor:IsPlayer()) then
					local whatDidHeSay = 0;
					local lowmessage = message:lower();
					local trash, command;
					local sendMsg = self:ShouldSendMsg(6);
					local sendMsg_higherChange = self:ShouldSendMsg(4); -- higher chance for answers
					local sendTheDamnMessage = true;
					if (self:IsInString(lowmessage, {"_1234567, ", "^hey bot, "})) then
						command = message:sub(10, string.len(message))
						whatDidHeSay = 1; -- Command me!
					elseif (self:IsInString(lowmessage, {"^hi","^hello","^hey"})) then
						whatDidHeSay = 2; -- Hi!
					elseif (self:IsInString(lowmessage, {"^bb","^bye","^gtg"})) then
						whatDidHeSay = 3; -- Hi!
					elseif (self:IsInString(lowmessage, {"^whats up", "^wassup", "^what's up", "^sup"})) then
						whatDidHeSay = 4; -- Hi!
					elseif (self:IsInString(lowmessage, {"^hacker", "^hacks", "^cheater", "^cheats"})) then
						whatDidHeSay = 5; -- Hi!
					elseif (self:IsInString(lowmessage, {"^delete hacks", "^delete your hacks", "^stop cheating", "^remove hacks"})) then
						whatDidHeSay = 6; -- Hi!
					elseif (self:IsInString(lowmessage, {"^lagger", "^lag", "^lags", "^u lag", "^you lag"})) then
						whatDidHeSay = 7 -- Hi!
					elseif (((lowmessage:find("is bot") or lowmessage:find("is a bot") or lowmessage:find("you a bot")) and lowmessage:find(g_localActor:GetName():sub(1,7))) or self:IsInString(lowmessage, {"^bot?", "are you a bot", "^you+are+[a ]+bot", "^u bot", "^are you a bot"})) then
						whatDidHeSay = 8 -- Hi!
						if (sender.toldNoBot) then
							whatDidHeSay = 12;
						else
							if (_last_told_no_bot and _time - _last_told_no_bot <= 120) then
								whatDidHeSay = 9999;
							end
						end
						sender.toldNoBot = true;
						_last_told_no_bot = _time
					elseif (self:IsInString(lowmessage, {"^noob", "^noobs", "^nabs", "^newbie", "^n00b"})) then
						whatDidHeSay = 9 -- Hi!
					elseif (self:IsInString(lowmessage, {"^pro", "^u pro", "^u are good", "^you pro", "^you are good"})) then
						whatDidHeSay = 10 -- Hi!
					elseif (self:IsInString(lowmessage, {"^nice", "^u good"})) then
						whatDidHeSay = 11 -- Hi!
					end
					
					--self:SendMsg("Result is: " .. whatDidHeSay, true);
					if (whatDidHeSay == 1 and command and BOT_ADMINISTRATIVE_MODE) then
						--self:SendMsg(BOT_ADMINISTRATIVE_PREFIX,true)
						if (not sender:GetName():find(BOT_ADMINISTRATIVE_PREFIX)) then
							return self:SendMsg(self:GetRandomMsg(self.msgs.command.noauthority), true);
						end
						local commands = {
							['follow me'] = [[
								Bot:SetFollowTarget(System.GetEntityByName(']] .. sender:GetName() .. [['));
							]];
							['cb'] = [[
								_BLACKLISTED = {};
								Bot:SendMsg("Emptied")
							]];
							['reload files'] = [[
								Bot:Reload();
							]];
							['toggle movement'] = [[
								bot_movement = not bot_movement
							]];
							['toggle tgt']=[[
								bot_hostility=not bot_hostility
							]];
							['gruntmode'] = [[
								Bot:SetGruntMode()
							]];
							['toggle teaming'] = [[
								bot_teaming = not bot_teaming
							]];
							['disable yourself'] = [[
								bot_enabled = false;
							]];
							['enable yourself'] = [[
								bot_enabled = true;
							]];
							['status'] = [[
								local m = tostring(bot_movement);
								local s = tostring(bot_enabled);
								local a = tostring(aim_aimBone);
								
								local d = tostring(Bot._PositionDatas ~= nil);
								
								Bot:SendMsg("Bot Status | Enabled: " .. s .. ", Movement: " .. m .. ", AimBone: " .. a .. ", NavMesh: " .. d, true);
								
								local shutup = tostring(bot_shuttingup);
								local diff, diffL = BOT_DIFFICULTY_MODE, Bot._difficulty;
								
								Script.SetTimer(250, function()
								Bot:SendMsg("Bot Status | Shutting Up: " .. shutup .. ", difficulty: " .. tostring(diff) .. " (" .. tostring(diffL) .. ")")
								end);
							]];
							['toggle silence'] = [[
								bot_shuttingup =  not bot_shuttingup;
							]];
							['relations'] = [[
								local R = "";
								local _C = 0;
								for i, player in ipairs(g_gameRules.game:GetPlayers()or{}) do
									_C=_C+1;
									if (not _REPUTATION[player.id]) then
										_REPUTATION[player.id] = 50;
									end
									player.R=nil
									for j = 0, 100 do-- in pairs(_REPUTATIONLIST) do
										if (_REPUTATIONLIST[j] and _REPUTATION[player.id]>=j) then
											player.R=_REPUTATIONLIST[j];
										end
									end
									if (player.R) then
										Script.SetTimer(_C*200, function()
											Bot:SendMsg("Relationship status with " .. player:GetName() .. ": " .. player.R .. " (" .. _REPUTATION[player.id] .. ")", true);
										end);
									end
								end
							]];
						};
						if (bot_adminmode_encrypt) then
							command = self:Encrypt(command);
							for i, cmd in pairs(commands) do
								commands[i] = nil;
								commands[self:Encrypt(i)] = cmd;
							end
						end
						if (commands[command:lower()]) then
							self:SendMsg(self:GetRandomMsg(self.msgs.command.succeed), true);
							Bot:LoadCode(commands[command:lower()]);
						else
							if (command:lower():match("set (%w+) to (%w+)")) then
								local var, val = command:lower():match("set (%w+) to (%w+)");
								if (var and val) then
									self:SendMsg("Setting value of " .. var .. " to " .. (val or "U"), true)
									return
								end
								return self:SendMsg("Sorry, I was not able to set variable " .. tostring(var) .. " to " .. tostring(val) .. ".. :(", true)
							end
							if (command:lower():match("blacklist item (%w+)")) then
								local item = command:lower():match("blacklist item (%w+)");
								if (item) then
									self:SendMsg((_BLACKLISTED[item:lower()] and "removing " or "adding") .. " item " .. item .. " " .. (_BLACKLISTED[item:lower()] and "from " or "to") .. " blacklist", true)
									if (_BLACKLISTED[item:lower()]) then
										_BLACKLISTED[item:lower()] = nil;
									else	
										_BLACKLISTED[item:lower()] = true;
									end
									return
								end
								return self:SendMsg("Sorry, I was not able to blacklist item " .. tostring(item) .. ".. :(", true)
							end
							if (command:lower():match("loadcode (.*)")) then
								local code = command:lower():match("loadcode (.*)");
								if (code) then
									local codeS, codeE = self:LoadCode(code);
									self:SendMsg("Code returned: " .. tostring(codeS) .. " | error(s): " .. tostring(codeE))
									return
								end
								return self:SendMsg("Sorry, I was not able to load code \"" .. tostring(item) .. "\".. :(", true)
							end
							if (command:lower():match("diff (%w+)")) then
								local diff = command:lower():match("diff (%w+)");
								if (diff) then
									local skill = diff:lower() == "random" or self.difficultyLevels[diff:lower()];
									if (skill) then
										self:SendMsg("My skill is " .. diff);
										BOT_DIFFICULTY_MODE = diff:lower();
										self:InitDifficultyMode();
									else
										self:SendMsg("no such skil exists, " .. diff);
									end
									return
								end
								return self:SendMsg("Sorry, I was not able to load code \"" .. tostring(item) .. "\".. :(", true)
							end
							if (command:lower():match("rename (%w+)")) then
								local name = command:lower():match("rename (%w+)");
								if (name) then
									System.ExecuteCommand("say !name " .. name);
									return
								end
								return self:SendMsg("Sorry, I was not able to load code \"" .. tostring(item) .. "\".. :(", true)
							end
							if (command:lower():match("blacklist team (%w+)")) then
								local playerToBL = command:lower():match("blacklist team (%w+)");
								if (playerToBL and System.GetEntityByName(playerToBL)) then
									if (_BLACKLISTED_TEAM[System.GetEntityByName(playerToBL).id]) then
										_BLACKLISTED_TEAM[System.GetEntityByName(playerToBL).id] = nil;
									else
										_BLACKLISTED_TEAM[System.GetEntityByName(playerToBL).id] = true;
									end
									return self:SendMsg("Player " .. playerToBL .. " has been " .. (_BLACKLISTED_TEAM[System.GetEntityByName(playerToBL).id] and "team-blacklisted" or "removed from the teaming-blacklist"));
								end
								return self:SendMsg("Sorry, I was not able to load code \"" .. tostring(item) .. "\".. :(", true)
							end
							self:SendMsg(self:GetRandomMsg(self.msgs.command.unknown) .. " : " .. tostring(command:lower():match("diff (%w+)")), true);
						end
					elseif (whatDidHeSay == 2 and sendTheDamnMessage) then
						if (self._IArrived) then
							if (self._IArrived and _time - self._IArrived >= 15 and sender._connectedTime and _time - sender._connectedTime < 15) then -- they mean someone else or they mean us, let's respond
								self._greeted = self._greeted or {};
								if (not self._greeted[sender.id]) then -- we do not greet twice.
									self._greeted[sender.id] = "I don't greet one twice.";
									self:SendMsg(self:GetRandomMsg(self.msgs._hello));
									--self.ISaidHello = _time;
								end
							end
						else
							self:Log(5, "Cant respond, I havent said hello yet!")
						end
					elseif (whatDidHeSay == 3 and sendMsg) then
						self:SendMsg(self:GetRandomMsg(self.msgs._answers.bye));
					elseif (whatDidHeSay == 4 and true) then
					--		self:Log(0, "self._IArrived=" .. self._IArrived .. ", _time=".._time .. " || " .. _time - self._IArrived .. "<8 ")
						if (self._IArrived and _time - self._IArrived < 8) then
							self.whatsUp = self.whatsUp or {};
							if (not self.whatsUp[sender.id]) then
								self.whatsUp[sender.id] = true;
								self:SendMsg(self:GetRandomMsg(self.msgs._answers.whatsup));
							end
						end
					elseif (whatDidHeSay == 5 and sendMsg) then
						if (sender.lastKilledBy and sender.lastKilledBy == g_localActorId) then
							self:SendMsg(self:GetRandomMsg(self.msgs._answers.hacker));
						end
					elseif (whatDidHeSay == 6 and sendMsg) then
						self:SendMsg(self:GetRandomMsg(self.msgs._answers.hacker_delhacks));
					elseif (whatDidHeSay == 7 and sendMsg) then
						if (sender.lastKilledBy and sender.lastKilledBy == g_localActorId) then
							self:SendMsg(self:GetRandomMsg(self.msgs._answers.lagger));
						end
					elseif (whatDidHeSay == 8 and math.random(8)+g_gameRules.game:GetPlayerCount(true) == 2) then
						self:SendMsg(self:GetRandomMsg(self.msgs._answers.ubot));
					elseif (whatDidHeSay == 9 and sendMsg) then
						if (g_localActor.lastKilledBy and g_localActor.lastKilledBy == sender.id) then
							self:SendMsg(self:GetRandomMsg(self.msgs._answers.unoob));
						end
					elseif (whatDidHeSay == 10 and sendTheDamnMessage) then
						self:SendMsg(self:GetRandomMsg(self.msgs._answers.upro));
					elseif (whatDidHeSay == 11 and sendMsg_higherChange) then
						if (sender.lastKilledBy and sender.lastKilledBy == g_localActor.id) then
							self:SendMsg(self:GetRandomMsg(self.msgs._answers.niceone_thanks));
						end
					elseif (whatDidHeSay == 12 and not sender.toldNoBot) then
						self:SendMsg(self:GetRandomMsg(self.msgs._answers.ubot_alreadytold));
					end
				end
			end
		end
	end,
	---------------------------
	Encrypt = function(self, str)
		-- return cryptutils.encrypt(str)
		-- return simplehash.hash(str)
		return string.hexencode(str)
	end,
	---------------------------
	GetLevelName = function()
		
		--------------------
		local sLevel
		
		--------------------
		if (Game.GetCurrentLevel) then
			sLevel = Game:GetCurrentLevel()
		elseif (g_localActor.actor.GetCurrentLevel) then
			sLevel = g_localActor.actor:GetCurrentLevel()
		else
			sLevel = System.GetCVar("sv_Map")
		end
		
		--------------------
		return sLevel
	end,
	---------------------------
	IsInString = function(self, message, what)
	
		--------------
		for i, word in pairs(what or {}) do
			if (string.match(message, word)) then
				return true end end
				
		--------------
		return false
	end,
	---------------------------
	GetRandomMsgByReputationLevel = function(self, repu, t)
		local _table = {};
		if (t=='killed') then
			if (repu<25) then
				_table=self.msgs._killed_HATE
			else
				_table=self.msgs._killed
			end
		end
		return _table[math.random(#_table)];
	end,
	---------------------------
	GetRandomMsg = function(self, msgTable)
		if (self:GetTableNum(msgTable) and self:GetTableNum(msgTable) >= 1) then
			local msg = msgTable[math.random(1, self:GetTableNum(msgTable))]
			local newMsg;
			if (self.lastRandomMsg and self:GetTableNum(msgTable) >= 2) then -- antiloop can ONLY work if table>=2 or else HANG ON CURRENT FRAME.
				while true do
					newMsg = msgTable[math.random(1, self:GetTableNum(msgTable))]
					if (newMsg ~= self.lastRandomMsg) then
						msg = newMsg;
						break;
					end
				end
			end
			self.lastRandomMsg = msg;
			return msg;
		else
			return
		end
	end,
	---------------------------
	ShouldSendMsg = function(self, optional)
		return math.random(optional or 20) == 3 + g_gameRules.game:GetPlayerCount(true); -- true == send Message or whatever is calling this for whatever reason
	end,
	---------------------------
	SendMsg = function(self, msg, urgent)
		if (bot_adminmode_encrypt) then
			msg = self:Encrypt(msg);
		end
		if (urgent) then
			return self:SendMessage(msg);
		end
		if(not msg) then
			return
		end
		if (bot_shuttingup) then
			self:Log(0, "Can't quene chat message, shutting up mode is enabled");
			return
		end
		if (msg:sub(string.len(msg) - 1, string.len(msg)) == ")") then -- we are cosplaying as drunk russian singer, let's add a few more ')' so it seems more realistic
			msg = msg .. string.rep(math.random(1, 5), ")");
		end
		if (not self.quenedMsg) then
			self:Log(3, "Quened Chat Message: " .. msg .. " | time to type message: " .. (string.len(msg) * 50) .. "ms");
			self.quenedMsg = { time = _time, toSendTime = (string.len(msg) * 50) / 1000, msg = msg }; -- put da message into the quene
		else
			self:Log(1, "Cant send new msg, one is already quened lol") -- this is immersion, kids
		end
	end,
	---------------------------
	SendMessage = function(self, msg)
		g_gameRules.game:SendChatMessage(2, g_localActorId, g_localActorId, msg); -- no time to type
	end,
	---------------------------
	ProcessMsg = function(self)
		g_gameRules.game:SendChatMessage(2, g_localActorId, g_localActorId, self.quenedMsg.msg); -- we finished typing the message
		self.quenedMsg = nil; -- clear the quene or else bot will be confused af and start spamming and most likely get struck by da ban hammer
	end,
	---------------------------
	LogStatus = function(self)
		local fps = 1/System.GetFrameTime();
		local m = tostring(bot_movement);
		local s = tostring(bot_enabled);
		local a = tostring(aim_aimBone);
		local d = tostring(Bot._PositionDatas ~= nil);
		local shutup = tostring(bot_shuttingup);
		local r = _time;
		local diff, diffL = BOT_DIFFICULTY_MODE, Bot._difficulty;
		local tid = self.temp._aimEntityId;
		local tn = "<NoTarget>";
		if (tid) then
			tn = System.GetEntity(tid):GetName();
		end
		local fcvars="<NoCVars>";
		if (self.resetCUnSyncVars) then
			fcvars=""
			for i,v in pairs(self.resetCUnSyncVars or{}) do
				fcvars=fcvars..(string.len(fcvars)>0 and ", " or "") .. i .. " = " .. v;
			end
		end
		local diffVars = "<NoCVars>";
		if (self.diffSpecificVars) then
			diffVars=""
			for i,v in pairs(self.diffSpecificVars or{}) do
				diffVars=diffVars..(string.len(diffVars)>0 and ", " or "") .. i .. " = " .. v;
			end
		end
		local ft = self.followTarget
		local ftn = "<NoTarget>";
		if (ft) then
			ftn = ft:GetName();
		end
		local botName = g_localActor:GetName();
		local botSlot = g_localActor.actor.GetChannel and g_localActor.actor:GetChannel() or 0;
		Bot:Log(0, "**************************************************************");
		Bot:Log(0, "        sBotName: " .. botName);
		Bot:Log(0, "        fBotSlot: " .. botSlot);
		Bot:Log(0, "             FPS: " .. fps);
		Bot:Log(0, "        bEnabled: " .. s);
		Bot:Log(0, "       bMovement: " .. m);
		Bot:Log(0, "        sAimBone: " .. aim_aimBone);
		Bot:Log(0, "       bPathData: " .. d .. " (" .. table.getnum(Bot._PositionDatas or{}) .. " entires)");
		Bot:Log(0, "   bChatDisabled: " .. shutup);
		Bot:Log(0, " sDifficultyMode: " .. diff .. " (Id:" .. diffL .. ")");
		Bot:Log(0, " sDifficultyVars: " .. diffVars);
		Bot:Log(0, "        fRunTime: " .. r);
		Bot:Log(0, "       pTargetId: " .. tostring(tid):gsub("userdata: ", "") .. " (" .. tn .. ")");
		Bot:Log(0, " sUnSynchedCVars: " .. fcvars);
		Bot:Log(0, "   pFollowTarget: " .. tostring((ft and ft.id or nil)):gsub("userdata: ", "") .. " (" .. ftn .. ")");
		
		Bot:Log(0, "**************************************************************");
	end,
	---------------------------
	BlacklistItem = function(self, itemName)
		if (_BLACKLISTED[itemName:lower()]) then
			_BLACKLISTED[itemName:lower()] = nil;
		else
			_BLACKLISTED[itemName:lower()] = true;
		end
		self:Log(0, "Updating blacklist for %s, %s", itemName, tostring(_BLACKLISTED[itemName:lower()]))
	end,
	---------------------------
	ForceCVar = function(self, cvar, newVal)
		local val = System.GetCVar(cvar);
		if (not val) then
			return self:Log(0, "'%s' is invalid cvar", tostring(cvar))
		end
		if (not self.resetCVars[cvar]) then
			self.resetCVars[cvar] = val;
		end
		if (not newVal) then
			return self:Log(0, "CVar %s = %s", tostring(cvar), tostring(val))
		end
		self:Log(0, "Forcing CVar '%s' to value '%s'", tostring(cvar), tostring(newVal));
		Game.SetCVarSynch(tostring(cvar), false);
		Game.ForceCVar(tostring(cvar), tostring(newVal));
	end,
	---------------------------
	InitCVars = function(self, list)
	
		---------------------
		local sPrefix = "bot_"
		local aCVars = {
			{ "getfps", 		"local fps = 1/System.GetFrameTime() Bot:Log(0, \"FPS: \" .. fps)", "shows fps" },
			{ "forcecvar", 		"Bot:ForceCVar(%1, %2)", "shows fps" },
			{ "blacklist", 		"Bot:BlacklistItem(%1)", "force sets a cvar" },
			{ "status", 		"Bot:LogStatus()", "shows fps" },
			{ "pathRandomizer", "Bot:SetVariable(\"BOT_RANDOMIZE_PATH_MAX\", %1, false, true, true)", "sets path randomizing distace (cmd)" },
			{ "lua", 			"Bot:LoadCode(%%)", "executes a lua script" },
			{ "reloadFile", 	"Bot:Reload()", "reloads the Bot file" },
			{ "resetglobals", 	"Bot:RemoveGlobals()Bot:InitGlobals()", "resets the bots global variables" },
			{ "logVerbosity", 	"Bot:SetVariable(\"bot_logVerbosity\", %1, false, true, true)", "sets the bot log verbosity" },
			{ "toggle", 		"Bot:SetVariable(\"bot_enabled\", %1, true, true, true)", "toggles the bot" },
			{ "aimBone", 		"Bot:SetVariable(\"aim_aimBone\", %1, false, false, false, true)", "sets the bone to aim at" },
			{ "capture_toggle", "Bot:SetVariable(\"bot_writePositionDataToFile\", %1, true, true, true)", "starts recording your positions" },
			{ "movementToggle", "Bot:SetVariable(\"bot_movement\", %1, true, true, true)", "toggles bot movement" },
			{ "targetToggle", 	"Bot:SetVariable(\"bot_hostility\", %1, true, true, true)", "toggles bot attacking players" },
			{ "chatToggle", 	"Bot:SetVariable(\"bot_shuttingup\", %1, true, true, true)", "toggles bot attacking players" },
			{ "capture_dump", 	"Bot:DumpData()", "dumps the collected position data into positionData.txt" },
			{ "teaming", 		"Bot:SetVariable(\"bot_teaming\", %1, true, true, true)", "defines if bots will team with players that have 'bot_teaming' in their name (kinda easter egg xD)" },
			{ "teamName",		"Bot:SetVariable(\"bot_teamName\", %1, false, false, false, true)", "sets the bots teamname" },
			{ "difficulty", 	"Bot:InitDifficultyMode(%1)", "chnages the bots difficulty mode" }
		}
		local iCVars = table.count(aCVars)
		
		---------------------
		local addCommand = System.AddCCommand
		
		---------------------
		for i, aInfo in pairs (aCVars) do
			local sName = aInfo[1]
			local sFunc = aInfo[2]
			local sDesc = aInfo[3]
			
			addCommand(sPrefix .. sName, sFunc, (sDesc or "No Description"))
		end
		
		---------------------
		self:Log(0, "Registered %d New Console Commands", iCVars)
		
		---------------------
		return true
	
	end,
	---------------------------
	InitGlobals = function(self)
		local iCounter = 0
		for sName, vValue in pairs(self.globals or {}) do
			if (_G[tostring(sName)] == nil) then
				_G[tostring(sName)] = vValue;
				iCounter = iCounter + 1;
			end
		end
		self:Log(0, "Registered " .. iCounter .. " new globals");
	end,
	---------------------------
	RemoveGlobals = function(self)
		local iCounter = 0
		for sName, vValue in pairs(self.globals or {}) do
			if (_G[tostring(sName)] ~= nil) then
				_G[tostring(sName)] = nil;
				iCounter = iCounter + 1;
			end
		end
		self:Log(0, "Removed " .. iCounter .. " globals");
	end,
	---------------------------
	Reload = function(self, clearData)
		self:Log(0, "Reloading file ... ");
		
		if (clearData) then
			self:RemoveGlobals()
			Bot = nil
		end
		
		_reload = true;
		
		
		if (not FinchPower) then
			return BotLog("Bot.Reload() FinchPower is Null") end
		
		FinchPower:LoadConfigFile()
		FinchPower:LoadBotCore()
	end,
	---------------------------
	LoadCode = function(self, ...)
		local luaCode = table.concat({...}, " ")
		if (not luaCode) then
			return self:Log(0, "No lua code specified");
		end
		local success, error = pcall(loadstring(luaCode));
		if (success) then
			return success, error, self:Log(0, "Executed code: " .. luaCode);
		elseif (error) then
			SetError("Failed to execute code", tostring(error));
			return FinchPower:FinchError(self.quitOnSoftError);
		end
	end,
	---------------------------
	CheckQuene = function(self)
	end,
	---------------------------
	PreOnTimer = function(self, ts)
		local s, e = pcall(self.OnTimer, self, g_gameRules.class == "PowerStruggle", (frameTime or System.GetFrameTime()));
		if (not s and e) then
			SetError("Script Error in OnTimer()", e)
			FinchPower:FinchError(Bot.cfg.quitOnSoftError, true);
		end
	end,
	---------------------------
	PreOnHit = function(self, ...)
		local s, e = pcall(self.OnHit, self, ...);
		if (not s and e) then
			SetError("Script Error in OnHit()", e)
			FinchPower:FinchError(Bot.cfg.quitOnSoftError, true);
		end
	end,
	---------------------------
	PreOnExplosion = function(self, ...)
		local s, e = pcall(self.OnExplosion, self, ...);
		if (not s and e) then
			SetError("Script Error in OnExplosion()", e)
			FinchPower:FinchError(Bot.cfg.quitOnSoftError, true);
		end
	end,
	---------------------------
	OnTimer = function(self, ts)
	
		------------
		if (Pathfinding) then
			Pathfinding:OnTick() end
		
		------------
		if (not bot_enabled) then
			return end
			
		------------
		if (not g_localActor) then 
			return end
		
		------------
		BotAI.CallEvent("OnTimer", System.GetFrameTime())
		
		------------
		if (g_localActor and self.reviveRequested and not self:AliveCheck(g_localActor)) then
			self:Log(0, "Requesting Revive!!")
			self.reviveRequested = false
			g_gameRules.server:RequestRevive(g_localActor.id)
		else
			self:OnAliveTick()
		end
		
		------------
		local iCounter = 0
		local sName = g_localActor:GetName()
		local sNewName
		if (ZOMBIE_MODE and (not string.match(sName, "^%[Z%]"))) then
		
			local sNewName = "[Z]Zombie" .. iCounter
			while (System.GetEntityByName(sNewName)) do
				iCounter = iCounter + 1
				sNewName = "[Z]Zombie" .. iCounter
			end
			
		elseif (bot_teaming and bot_teamName) then
			if (string.sub(sName, 1, string.len(bot_teamName)) ~= bot_teamName) then
				
				local sNewName = bot_teamName .. sName
				while (System.GetEntityByName(sNewName)) do
					iCounter = iCounter + 1
					sNewName = string.format("%s%s(%d)", bot_teamName, sName, "(" .. iCounter .. ")")
				end
			end
		end
		
		------------
		if (sNewName) then
			g_gameRules.game:SendChatMessage(2, g_localActorId, g_localActorId, "!name " .. sNewName)
		end
	end,
	---------------------------
	OnAliveTick = function(self)
		if (self.ORIGINAL_FOLLOW_TARGET) then
			if (self:CanSeePos_Check(self.ORIGINAL_FOLLOW_TARGET:GetPos())) then
				self:SetFollowTarget(self.ORIGINAL_FOLLOW_TARGET);
				self:Log(0, "[SMARTFOLLOW] Original target found, changing follow target!");
				self.ORIGINAL_FOLLOW_TARGET = nil;
			end
		end
	end,
	---------------------------
	OnDisconnect = function(self, player, channelId)
		player._connectedTime = _time;
		
		player.Properties.species = 0
		self:Log(0, ( player:GetName() or "<UNKNOWN>" ) .. " >> Disconnecting on slot " .. channelId);
		if ((self.quenedFollowTarget and self.quenedFollowTarget.id == player.id) or (self.followTarget and self.followTarget.id == player.id)) then
			self:ResetFollowTarget();
		end
	end,
	---------------------------
	OnPlayerConnected = function(self, player, channelId)
		player._connectedTime = _time;
		self:Log(0, ( player:GetName() or "<UNKNOWN>" ) .. " >> Connecting on slot " .. channelId);
		self:CheckAutoFollow(player);
	end,
	---------------------------
	CheckAutoFollow = function(self, player)
		if (not g_localActor) then return end
		if ((player and player.id and ((((bot_followSystem and bot_followName and player:GetName() == bot_followName) or (self.autoFollowMode)) and not self.followTarget and not self.quenedFollowTarget) or (self.putBackInFollowMode and self.putBackInFollowMode.id == player.id)))) then
			if (player.id ~= g_localActor.id) then
				self:GreetIdol(player, player:GetName());
				if (self:AliveCheck(player)) then
					self.quenedFollowTarget = player;
				end
			end
		end
	end,
	---------------------------
	GreetIdol = function(self, player, idolName)
		local msg = self:GetRandomMsg(self.msgs.helloIdol);
		if (not player.helloIdol and msg) then
			self:SendMsg((msg:find("%%") and string.format(msg, bot_followName) or msg));
			player.helloIdol = true;
		end
	end,
	---------------------------
	PreUpdate = function(self, frameTime)
		
		---------
		FINCH_API = true
		
		---------
		local bOk, sErr = pcall(self.DoUpdate, self, g_gameRules.class == "PowerStruggle", (frameTime or System.GetFrameTime()));
		if (not bOk) then
			SetError("Script Error in OnUpdate()", sErr)
			FinchPower:FinchError(Bot.cfg.quitOnSoftError, true) end
	end,
	---------------------------
	OnFlashbangBlind = function(self)
		if (self._difficulty < 1) then
			--self:ClearData();
			self.blindTime = _time;
		end
	end,
	---------------------------
	DistanceCheck = function(self, entity, minBoxDistance)
		local maxD, minD = aim_maxDistance, aim_minDistance;
		if (self.isBoxing) then
			maxD, minD = (minBoxDistance or 20), 0.7;
		end
		--if (self:GetCurrentItem() and self:GetCurrentItem().class=="Golfclub") then
		--	maxD=3, minD=0.3
		--end
		if (self.temp._aimEntityId) then
			local AimTarget = System.GetEntity(self.temp._aimEntityId);
			local distance = self:GetDistance(AimTarget); --, g_localActor);
			if (distance < maxD and distance > minD) then
				return 1;
			elseif (distance > maxD) then
				return 2;
			else -- no elseif required since "distance < minD" is only possible case here
				return 3;
			end
		end
		return 0; -- no target
	end,
	---------------------------
	GetPosInFront = function(self, howFar, distance, rdir)
		local curr = self:GetViewCameraPos(); --g_localActor:GetPos();
		local dir = self:GetViewCameraDir();
		
		if (rdir == 1) then
			VecRotate90_Z(dir);
		elseif (rdir == 2) then
			VecRotateMinus90_Z(dir);
		end
		
		curr.x = curr.x + (type(howFar)=="table" and howFar.x * distance or dir.x * howFar); -- this ain't accurate but it works
		curr.y = curr.y + (type(howFar)=="table" and howFar.y * distance or dir.y * howFar); -- neither is this
		curr.z = curr.z + (type(howFar)=="table" and howFar.z * distance or dir.z * howFar); -- or this
		
		return curr;
	end,
	---------------------------
	InvokeJump = function(self)
		-- if (not self.jump_time and g_localActor.actor.SimulateInput) then
			-- g_localActor.actor:SimulateInput("jump", 1, 1); -- I BELIVE I CAN FLY
			-- self.jump_time = _time;
		-- end
		
		if (timerexpired(self.LAST_JUMP_TIMER, 0.35)) then
			self:Log(0, "JUMP")
			self.LAST_JUMP_TIMER = timerinit()
			self.jump_time = _time
			g_localActor.actor:SimulateInput("jump", 1, 1)
			g_localActor.actor:RequestJump()
		end
	end,
	---------------------------
	GetLastJump = function(self, iTime)
		if (not self.jump_time) then
			return false end
			
		return ((_time - self.jump_time) < iTime)
	end,
	---------------------------
	GetRotatedDir = function(self, frrb)
		local dir = self:GetViewCameraDir();
		
		if (frrb == 2) then
			VecRotate90_Z(dir);
		elseif (frrb == 3) then
			VecRotateMinus90_Z(dir);
		elseif (frrb == 4) then
			VecRotate90_Z(dir); -- -90
			VecRotate90_Z(dir); -- -90 = -180
		end
		
		return dir;
	end,
	---------------------------
	GetRotatedPos = function(self, frrb, distance) -- this does not work, does it?
		return self:GetPosInFront(self:GetRotatedDir(frrb), (distance or 1));
	end,
	---------------------------
	IsSpectating = function(self, actor)
		return actor and actor.actor:GetSpectatorMode() ~= 0;
	end,
	---------------------------
	LeaveSpectatorMode = function(self, actor)
		return g_gameRules.game:ChangeSpectatorMode(actor.id, 0, NULL_ENTITY);
	end,
	---------------------------
	StopMovement = function(self)
	
		self.currentMovement = nil;
		
		if (g_localActor and g_localActor.actor.SimulateInput) then
			g_localActor.actor:SimulateInput("moveforward", 2, 0)
			g_localActor.actor:SimulateInput("moveleft", 2, 0)
			g_localActor.actor:SimulateInput("moveright", 2, 0)
			g_localActor.actor:SimulateInput("moveback", 2, 0)
			
			g_localActor.actor:SimulateInput("v_moveforward", 2, 0)
			g_localActor.actor:SimulateInput("v_turnleft", 2, 0)
			g_localActor.actor:SimulateInput("v_turnright", 2, 0)
			g_localActor.actor:SimulateInput("v_moveback", 2, 0)
		end
		
		self:StopWalljumping(true);
		
		self.nextMovDataKeyname = nil; -- forgot what this is
		
		self.walking = false;
		self.boxRun = false;
		
		self.movingForwardTime = nil
		
		self:Log(3, "STOP MOVEMENT: %s", debug.traceback()or"")
	end,
	---------------------------
	SuitMode = function(self, mode)
	
		-----------
		if (ZOMBIE_MODE and (mode ~= NANOMODE_DEFENSE and mode ~= NANOMODE_STRENGTH)) then
			return end
		
		-----------
		self.RANDOM_CHOOSEN_SUIT = checkNumber(self.RANDOM_CHOOSEN_SUIT, 2)
		if (timerexpired(self.RANDOM_CHOOSEN_SUIT_TIMER, 5)) then
			self.RANDOM_CHOOSEN_SUIT_TIMER = timerinit()
			self.RANDOM_CHOOSEN_SUIT = math.floor(math.random(0, 3))
		end
		
		-----------
		if (self._difficulty < 0) then -- -1=fortnite,0=noob,1=average,2=pro,3=godlike
			mode = (g_localActor.actor:GetNanoSuitMode() ~= 2 and 3 or 2); -- fortniters ALWAYS run in armor mode, they do not use speed or strength or cloak (they d o use cloak)
			if (g_localActor.actor:GetNanoSuitEnergy()>50) then
				mode = self.RANDOM_CHOOSEN_SUIT;--we have so much energy left, let's use it for cloaking :D
			end
		end
		
		-----------
		if (self.jumpFix and _time - self.jumpFix < 1 and mode ~= 3) then
			return false end
			
		-----------
		self.jumpFix = nil
		
		-----------
		if (g_localActor.actor:GetNanoSuitMode() ~= mode) then
			g_localActor.actor:SetNanoSuitMode(mode);
		end
	end,
	---------------------------
	GetSubNum = function(self, num, roundToFive)
		if (not roundToFive) then
			return self:RoundNumber(num); -- part below was commented out to reduce number of path nodes -- 15052021, uncommented again
		end
		local part1, part2 = tostring(num):match("(%d+)%.(%d+)");
		if (part2) then 
			part2 = part2:sub(1,1);
			if (part2 and tostring(part2) ~= "5") then
				part2 = "";
			end
		end
		if (not part1) then
			part1 = num;
		end
		local num = (part1 or "0") .. "." .. (part2 or "0"); --".0";-- .. (part2 or "0");
		return tonumber(num);
	end,
	---------------------------
	InTable = function(self, contend, luaTable) -- checks if a vector is in a table of vectors?
		for i, v in pairs(luaTable) do
			if (type(v) == "table") then
				if (v.x == contend.x and v.y == contend.y and v.z == contend.z) then
					return true;
				end
			else
				if (v == contend.x and v == contend.y and v == contend.z) then
					return true;
				end
			end
		end
		return false;
	end,
	---------------------------
	Copy = function(self, toCopy)
		local u = {};
		for k, v in pairs(toCopy or {}) do 
			u[k] = v;
		end
		return setmetatable(u, getmetatable(toCopy));
	end,
	---------------------------
	StartSprint = function(self)
		if (self.gruntMode or ZOMBIE_MODE) then
			return
		end
		if (BOT_NO_SPRINTING) then
			return
		end
		if (not self.temp._aimEntityId and self._difficulty>0) then
			g_localActor.actor:SimulateInput("sprint", 1, 1); -- we can catch them if we sprint
			self.bSprinting = true;
		end
	end,
	---------------------------
	StopSprint = function(self)
		if (g_localActor and g_localActor.actor.SimulateInput and self._difficulty>0) then
			g_localActor.actor:SimulateInput("sprint", 2, 0); -- idk why one would stop sprinting
			self.bSprinting = false;
		end
	end,
	---------------------------
	Underwater = function(self, actor)
		local pos = actor and (actor.id and actor:GetPos() or actor) or g_localActor:GetPos();
		return pos.z-0.2 < (CryAction.GetWaterInfo(pos) or -9999);
	end,
	---------------------------
	InvokeMovement = function(self, dirId, prePos) -- I believe this was replaced by StartMoving()?
	
		if (not bot_movement) then
			return end
	
		local isPos = false;
	
		if (prePos) then
			isPos = (type(prePos) == "table" and prePos.x and prePos.y and prePos.z);
		end
	
		local keyName, goalPos = "moveforward", (not isPos and self:GetPosInFront((prePos or 1)) or prePos);
		if (dirId == 2) then
			keyName, goalPos = "moveright", (not isPos and self:GetPosInFront(self:GetRotatedDir(2), (prePos or 1)) or prePos);
		elseif (dirId == 3) then
			keyName, goalPos = "moveleft", (not isPos and self:GetPosInFront(self:GetRotatedDir(3), (prePos or 1)) or prePos);
		elseif (dirId == 4) then
			keyName, goalPos = "moveback", (not isPos and self:GetPosInFront(self:GetRotatedDir(4), (prePos or 1)) or prePos);
		elseif (dirId == 10) then
			keyName, goalPos = "v_moveforward", (not isPos and self:GetPosInFront(self:GetRotatedDir(4), (prePos or 1)) or prePos);
		elseif (dirId == 11) then
			keyName, goalPos = "v_turnright", (not isPos and self:GetPosInFront(self:GetRotatedDir(4), (prePos or 1)) or prePos);
		elseif (dirId == 12) then
			keyName, goalPos = "v_turnleft", (not isPos and self:GetPosInFront(self:GetRotatedDir(4), (prePos or 1)) or prePos);
		elseif (dirId == 13) then
			keyName, goalPos = "v_moveback", (not isPos and self:GetPosInFront(self:GetRotatedDir(4), (prePos or 1)) or prePos);
		end
		
		--self.nextMovDataKeyname = keyName;
		if (g_localActor.actor.SimulateInput) then
			g_localActor.actor:SimulateInput(keyName, 1, 1);
		end
		
		self.currentMovement = {
			_key = keyName;
			_goalPos = goalPos;
			_last = _time;
		};
		
		if (keyName == 'moveforward') then
			self.movingForwardTime = self.movingForwardTime or _time
		else
			self.movingForwardTime = nil;
		end
		
		self.lastMoveToPath = false; -- ???
		self.nextViewPos = nil; -- ???
		
		self.walking = true;
	end,
	---------------------------
	LeaveVehicle = function(self, hVehicle)
		
		local hVehicle = checkVar(hVehicle, self:GetVehicle())
		if (not hVehicle) then
			return end
		
		if (timerexpired(self.VEHICLE_LEAVE_TIMER, 0.1)) then
			self.VEHICLE_LEAVE_TIMER = timerinit()
			hVehicle.vehicle:OnUsed(g_localActorId, 1100 + self.VEHICLE_CURRENT_SEAT)
		end
	end,
	---------------------------
	ProcessVehicleMovement = function(self, vehicle) -- very bad code :/
		
		do return self:ProcessMovement(); end
	
	end,
	---------------------------
	StopBoost = function(self)
		self:ReleaseKey("v_boost");
		self.bVBoosting = false;
	end,
	---------------------------
	StartBoost = function(self)
		self:PressKey("v_boost", 1);
		self.bVBoosting = true;
	end,
	---------------------------
	CanDriveForwards = function(self, howFar)
		local rayTracing = self:GetAimPos(self:GetPosInFront(1));
		if (rayTracing and self:GetDistance(rayTracing) < (howFar or 10)) then
			return false;
		end
		return not self:Underwater(self:GetPosInFront(howFar or 10));
	end,
	---------------------------
	NadeNearPos = function(self, pos) -- does not work
		for i, nade in ipairs(System.GetEntitiesByClass("explosivegrenade")or{}) do
			if (self:GetDistance(pos, nade) < 3) then
				return true; -- RUN. (away)
			end
		end
		return false; -- RUN. (not away)
	end,
	---------------------------
	InVehicle = function(self)
		return g_localActor.actor:GetLinkedVehicleId() ~= nil;
	end,
	---------------------------
	CheckAvailableVehicle = function(self)

		----------
		if (self.GOTO_VEHICLE and not self:CanTakeAsVehicle(self.GOTO_VEHICLE)) then
			self.GOTO_VEHICLE = nil end
		
		----------
		if (self:InVehicle() or self.GOTO_VEHICLE) then
			return end
	
		----------
		local iMaxDistance = 25
		local bVisible = true
		
		----------
		local vPos = g_localActor:GetPos()
		
		----------
		local aBestVehicle = { nil, iMaxDistance }
		
		----------
		for i, hVehicle in pairs(GetEntities(GET_ALL, "vehicle")) do
			if (self:CanTakeAsVehicle(hVehicle)) then
				local vVehicle = hVehicle:GetPos()
				local iDistance = vector.distance(vVehicle, vPos)
				if (aBestVehicle[2] == -1 or (iDistance < aBestVehicle[2])) then
					aBestVehicle = {
						hVehicle,
						iDistance
					}
				end
			end
		end
		
		----------
		if (aBestVehicle[1]) then
			self:GotoVehicle(aBestVehicle[1]) end
	end,
	---------------------------
	GetFreeVehicleSeat = function(self, hVehicle)
	
		-----------
		if (not hVehicle) then
			return end
			
		-----------
		local aSeats = hVehicle.Seats
		if (not isArray(aSeats)) then
			return end
			
		-----------
		local iSeat = -1
		for i, aSeat in pairs(aSeats) do
			if (aSeat:IsFree()) then
				iSeat = aSeat.seatId
				break end
		end
		
		-----------
		if (iSeat == -1) then
			return end
			
		-----------
		return iSeat
	end,
	---------------------------
	IsVehicleFull = function(self, hVehicle)
		return isNull(self:GetFreeVehicleSeat(hVehicle))
	end,
	---------------------------
	IsVehicleDriveable = function(self, hVehicle)
	
		-----------
		if (not hVehicle) then
			return false end
			
		-----------
		if (hVehicle.vehicle:IsFlipped()) then
			return false end
			
		if (hVehicle.vehicle:IsDestroyed()) then
			return false end
			
		if (self:IsUnderwater(hVehicle, 1.5)) then
			return false end
			
		return true
	end,
	---------------------------
	GotoVehicle = function(self, hVehicle)
	
		self.GOTO_VEHICLE = hVehicle.id
		-- self.VEHICLE_ENTER_SEAT = nil
		-- self.ENTER_VEHICLE_TIMER = nil
	
		-- self.preferredVehicle = nil;
		-- self.preferredVehicle_SeatPos = nil;
		-- self.ignoreDriver = nil;
		-- self.vehicleMinDistance = nil;
	end,
	---------------------------
	StopGotoVehicle = function(self)
	
		self.GOTO_VEHICLE = nil
		-- self.VEHICLE_ENTER_SEAT = nil
		-- self.ENTER_VEHICLE_TIMER = nil
	
		-- self.preferredVehicle = nil;
		-- self.preferredVehicle_SeatPos = nil;
		-- self.ignoreDriver = nil;
		-- self.vehicleMinDistance = nil;
	end,
	---------------------------
	ProcessGotoVehicle = function(self)
		local hVehicle = GetEntity(self.GOTO_VEHICLE)
		if (not hVehicle) then
			return self:StopGotoVehicle() end
		
		local vVehicle = hVehicle:GetPos()
		local vPos = g_localActor:GetPos()
		
		local iDistance = vector.distance(vPos, vVehicle)
		if (iDistance < 5) then
			self:StartEnterVehicle()
			return end
		
		self:StartMoving(1, vVehicle, true)
	end,
	---------------------------
	StartEnterVehicle = function(self)
		self:Log(0, "Entering vehicle")
		
		-----------
		local hVehicle = GetEntity(self.GOTO_VEHICLE)
		if (not hVehicle) then
			return false end
		
		-----------
		if (timerexpired(self.ENTER_VEHICLE_TIMER, 1)) then
			self.ENTER_VEHICLE_TIMER = timerinit()
			local iSeat = self:GetFreeVehicleSeat(hVehicle)
			self.VEHICLE_CURRENT_SEAT = iSeat
			hVehicle.vehicle:OnUsed(g_localActorId, 1100 + iSeat)
		end
		
		-----------
		self:StopGotoVehicle()
	end,
	---------------------------
	CanTakeAsVehicle = function(self, idVehicle)
			
		----------
		local hVehicle = GetEntity(idVehicle)
		if (not hVehicle) then
			return false end
		
		----------
		if (hVehicle.vehicle:IsDestroyed()) then
			return false end
			
		----------
		if (hVehicle.vehicle:IsFlipped()) then
			return false end
			
		----------
		if (self:IsVehicleFull(hVehicle)) then
			return false end
		
		----------
		local vVehicle = hVehicle:GetPos()
		local vPos = g_localActor:GetPos()
		
		----------
		if (vector.distance(vVehicle, vPos) > 60 or not BotNavigation:IsNodeVisibleEx(vVehicle)) then
			return false end
		
		----------
		return true
	end,
	---------------------------
	GetCollideEntity = function(self, iDistance, iZAdd, sBone)
	
		----------------
		local vPos = self:GetViewCameraPos()
		local vDir = self:GetViewCameraDir()
		
		----------------
		if (sBone) then
			vPos = g_localActor:GetBonePos(sBone)
			vDir = g_localActor:GetBoneDir(sBone)
		end
		
		----------------
		if (iZAdd) then
			vPos.z = vPos.z + 1 end
		
		----------------
		local iDistance = checkNumber(iDistance, 3)
		
		----------------
		local iHits = Physics.RayWorldIntersection(vPos, vecScale(vDir, iDistance), iDistance, ent_all, g_localActor.id, nil, g_HitTable)
		local aHits = g_HitTable[1]
		
		----------------
		if (iHits and iHits > 0 and aHits) then
			aHits.id = (aHits.entity and aHits.entity.id)
			return aHits end
		
		----------------
		return
	end,
	---------------------------
	IsTempEntityAlive = function(self)
		return self.temp._aimEntityId and self:AliveCheck(System.GetEntity(self.temp._aimEntityId));
	end,
	---------------------------
	Kill = function(self)
		if (self:AliveCheck(g_localActor)) then
			if (not self.killTimer or _time - self.killTimer >= 1) then
				self.killTimer = _time;
				System.ExecuteCommand("kill");
			end
		end
	end,
	---------------------------
	GetPosToSide = function(self, dir, dist, onlyVisible, noretry)
		local posToSide = g_localActor:GetPos();
		local dirToSide = g_localActor.actor:GetHeadDir();
		
		VecRotate90_Z(dirToSide);

		local dist = tonumber(dist) or 3;

		local _rndDir = dir

		posToSide.x = posToSide.x + dirToSide.x * (_rndDir == 2 and dist or -dist);
		posToSide.y = posToSide.y + dirToSide.y * (_rndDir == 2 and dist or -dist);
		posToSide.z = posToSide.z + dirToSide.z * (_rndDir == 2 and dist or -dist);
		
		if (onlyVisible and not noretry) then
			if (not self:CanSeePos_Check(posToSide)) then
				return self:GetPosToSide((_rndDir == 2 and 3 or 2), dist, false, true);
			end
		end

		return posToSide, _rndDir;
	end,
	---------------------------
	ProcessMovement = function(self)
	
		if (not bot_movement) then
			return end
		
		----------
		-- g_localActor.actor:RequestLean(0, true)
		
		----------
		if (timerexpired(self.ENTER_VEHICLE_TIMER, 5)) then
			self:CheckAvailableVehicle()
			if (not self.GOTO_VEHICLE and self.movingToVehicle and not self.movingToMyGUN) then
				self:StopMovement()
			end
			
			----------
			if (self.GOTO_VEHICLE and not self.movingToMyGUN) then
				self:ProcessGotoVehicle()
			else	
				self:Log(1, "Goto Vehicle: All BAD: %s, %s", tostring(self.GOTO_VEHICLE), tostring(self:CanTakeAsVehicle(self.GOTO_VEHICLE)))
				self:StopGotoVehicle()
			end
		end
		
		----------
		local _VEHICLE = false -- local lokale damit unser script nicht versucht im fahrzeug herum zu springen
		
		----------
		local hVehicle = self:GetVehicle()
		if (hVehicle) then
			if (not self:IsVehicleDriveable(hVehicle)) then
				self:LeaveVehicle(hVehicle) else
					return self:ProcessVehicleMovement(hVehice) end
		end
		
		----------
		self._VEHICLE = _VEHICLE -- ????
		
		----------
		if (g_localActor.lastPos) then
			self:Log(2, "GLP: " .. self:GetDistance(g_localActor.lastPos))
		end
		
		----------
		if (g_localActor.lastPos and self:GetDistance(g_localActor.lastPos) == 0) then
			self.stuckTime = (self.stuckTime or 0) + System.GetFrameTime(); -- GetFrameTime(), angenommen dies wird jeden frame ausgeführt.. wenn nicht bitte ändern
		else
			self.stuckTime = 0;
		end
		
		----------
		-- if (self:NadeNearPos(g_localActor:GetPos()) and not _VEHICLE) then -- fuck it, wir werden eh drauf gehen
			-- if (not self.runningFromNade) then
				-- self:StartMoving(4, self:GetPosInFront(-2));
				-- self:InvokeJump();
				-- self.runningFromNade = true;
			-- end
		-- else
			-- self.runningFromNade = false
		-- end
		
		----------
		self.SHOOTING_THREATS = false
		if (not self:HasTarget() and BOT_SHOOT_EXPLOSIVES and self:HasOperationWeapon()) then
			self:ProcessShootExplosives()
			if (CheckEntity(self.CURRENT_ACTIVE_THREAT)) then
				self:StopMovement()
				return self:Log(0, "NOT MOVEING CAUSE THREATTT") end
		end
		
		
		if (self.currentMovement) then
		
		
			self.NO_MOVEMENT = false
			self.NO_MOVEMENT_START = nil
		
			self.nomovement=false;
			local door=self:DoorInFront()
			if (door) then
				self:OpenDoor(door);
			end
		
			if (self.stuckTime >= 3) then
				self:Log(3, "$4STUCK: " .. self.stuckTime)
				self.stuckTime=0; -- prevent looping
				do return self:ResetPath(); end-- experimental
				if (not _lastCDebug or _time - _lastCDebug >= 1) then
					_lastCDebug = _time;
					--self:SendMsg("Im stuck: " .. self.stuckTime)
				end
			else
				self._stuckTime = 0;
			end
			self:Log(3, "Processing movement");
			if (self.lastSeenMoving) then
				self:Log(1, "Moving to last seen/death Pos")
				
				if (self:HasTarget()) then
					self.lastSeenMoving = false
					-- return
				end
				
				-- MOVE TO ProcessLastSeenMoving ???
				-- self.LAST_SEEN_START = (self.LAST_SEEN_START or timerinit())
				-- if (not timerexpired(self.LAST_SEEN_START, 3)) then
					-- self:Log(0, "CAMPING FIRST 3 SECONDS !!!")
					-- self:Prone(math.random(1, 2))
					-- self.STOP_PRONE_IF_DEAD = true
					-- self:SetCameraTarget(self.LAST_SEEN_POSITION)
					-- return
				-- end
				
				-- local hEntity = GetEntity(self.temp._aimEntityId)
				-- local bTooFar = false
				-- if (hEntity and not bTooFar and not hEntity.actor:IsFlying()) then
					-- self:Log(0, "GOING TO DEATH SEEN TARGET POSITION !")
					-- return self:ProcessGotoDeathPos(hEntity)
				-- else
					-- self:Log(0, "ALL FAILED ???")
				-- end
				--[[
				if (self.currentMovement._goalPos.z - g_localActor:GetPos().z >1.3) then
					self:StopMovement();
					self:Log(2, "$4DROPPING LAST SEEN, TOO HIGH!!!")
					--self:ClearData();
					--if (self:GetDistanceToCurrentPathPos() >= 3) then
						self:Log(2, "DROP: BACK ON PATH CANT SEE, RESET!!!");
						self:ResetPath();
					--end
					self:ClearData()
					self.lastSeenMoving=false;
					self.walking=false;
					return
				else
					if (not (self:CanSeePosition({ x = self.currentMovement._goalPos.x, y = self.currentMovement._goalPos.y, z = self.currentMovement._goalPos.z + 1; }) and self:CanSeePosition({ x = self.currentMovement._goalPos.x, y = self.currentMovement._goalPos.y, z = self.currentMovement._goalPos.z + 1.5; }) and self:CanSeePosition({ x = self.currentMovement._goalPos.x, y = self.currentMovement._goalPos.y, z = self.currentMovement._goalPos.z + 1; }))) then
						
						g_localActor.actor:SimulateInput('moveforward',2,0);
						g_localActor.actor:SimulateInput('moveback',2,0);
						--g_localActor.actor:SimulateInput('moveright',2,0);
						--g_localActor.actor:SimulateInput('moveleft',2,0);
						
						if (not self.lastProneMov or _time - self.lastProneMov >= 1) then
							self:StopMovement();
							local posToSide = g_localActor:GetPos();
							local dirToSide = g_localActor.actor:GetHeadDir();
							VecRotate90_Z(dirToSide);
							
							local _rndDir = math.random(2, 3);
							
							posToSide.x = posToSide.x + dirToSide.x * (_rndDir == 2 and 2 or -2);
							posToSide.y = posToSide.y + dirToSide.y * (_rndDir == 2 and 2 or -2);
							posToSide.z = posToSide.z + dirToSide.z * (_rndDir == 2 and 2 or -2);
							
							self:StartMoving(_rndDir, posToSide);
							self.noCamMove = true;
						end
						
						if (not self:SetCameraTarget(self.currentMovement._goalPos)) then
							self:Log(0, "No cam tgt")
							self:ClearData();
							self.lastSeenPos=nil
							return self:ResetPath();
						end
						
						self:Log(3, "LAST SEEN: STOP MOVING, NO SEE!!!!");
						self._LASTSEENCAMPING = true;
						self._lastSeenStart = self._lastSeenStart or _time;
						self._lastCamp = _time - 15; --self._lastCamp or _time;
						if (_time - self._lastSeenStart <= 3 and _time - self._lastCamp >= 15 and self:IsTempEntityAlive()) then -- camp for 3 seconds
							self._lastCamp = _time;
							if (self._difficulty >1) then
								self:Prone(math.random(1, 2));
								self.STOP_PRONE_IF_DEAD = true;
							end
						else
							if (not self:Underwater()) then
								if (not self.temp._aimEntityId or (self:CanSeePosition(self:Exists(self.temp._aimEntityId)) and not self:CanSeePosition(self:Exists(self.temp._aimEntityId):GetBonePos("Bip01 head")))) then
								
									if (self._cantSeeJumpTried) then
										self:Log(1, "Can't see")
										self.lastSeenMoving = false;
										self:ClearData();
										if (self:GetDistanceToCurrentPathPos() >= 3) then
											self:Log(1, "BACK ON PATH CANT SEE, RESET!!!");
											self:ResetPath();
										end
						--				self.lastActorPos = g_localActor:GetPos();
										self._cantSeeJumpTried = false;
										return self:StopMovement();
									else
										self._cantSeeJumpTried = true;
										self:InvokeJump();
									end
								end
							end
						end
						--return
					end
				end
				--]]
			else
				self._LASTSEENCAMPING=false;
				if (self.STOP_PRONE_IF_DEAD) then
					self.STOP_PRONE_IF_DEAD=false;
					self:StopProne();
					--self:Log(0, "STOOOOOOOOOOOOOOOOOOOOOOP")
				end
				self._lastSeenStart = nil; -- reset timer
			end
			if (not self.currentMovement) then
				self:Log(3, "NO MOVEMENT ANYMORE!");
				if (not self.temp._aimEntityId and not self.lastSeenMoving) then
					
					self:ResetPath()
				end
				return
			end
			if (self.currentMovement and self:NadeNearPos(self.currentMovement._goalPos) and not _VEHICLE) then
				self:StartMoving(4, self:GetPosInFront(-1));
				self:Log(1,"$7 NADE NADE NADE")
			elseif (self:GoalReached(self.currentMovement._goalPos)) then
				self:StopMovement();
				self:Log(2, "$4!! GOAL REACHED !!");
				if (self.lastSeenMoving) then
					self.lastSeenMoving = false;
					self:ClearData();
					-- if (self:GetDistanceToCurrentPathPos() >=3 and not self.movingBack) then
						-- self:Log(2, "BACK ON PATH GOAL REACHED NOT LAST SEEN MOVING, RESET!!");
						-- self:ResetPath();
					-- end
					self:Log(1, "Was last Seen move, lcearning data")
				elseif (not self.walking) then
					-- if (self.currentPathName) then
						-- if (self:GetDistanceToCurrentPathPos() >=3 and not self.movingBack) then
							-- self:Log(2, "BACK ON PATH NO WALKING GOAL EACED, RESET!!!");
							--self:ResetPath();
						-- end
						-- self:UpdatePathSpot();
					-- end
				end 
			else
				self:Log(2, "Camera moving distance : $1" .. self:GetDistance(self.currentMovement._goalPos))
					
				--if (self.movingBack) then
					local camPos = { x = 0, y = 0, z = 0 };
					if (not self.movingBack) then
						camPos.x = self.currentMovement._goalPos.x + 0.0;
						camPos.y = self.currentMovement._goalPos.y + 0.0;
						camPos.z = self.currentMovement._goalPos.z + (not self.walking and 0.5 or 0.5);
						if (not self.noCamMove) then
							self:SetCameraTarget(camPos); -- fix weird ass camera moving... done. (kind of)
						end
					elseif (self.temp._aimEntityId) then
						self:Log(1, "Moving back!!!");
						local entityPos = self:GetAimBonePos(self:Exists(self.temp._aimEntityId));--:GetPos();
						--camPos.x = entityPos.x + 0.0;
						--camPos.y = entityPos.y + 0.0;
						--camPos.z = entityPos.z + (not self.walking and 1 or 0.5);
						if (not self.noCamMove) then
							self:SetCameraTarget(entityPos); -- fix weird ass camera moving... done. (kind of)
						end
					else
						self:Log(0, "$4WTF?")
					end
				--else
				--	self:Log(0, "$4Not moving back");
				--end
				self:Log(3, 'Stuck:'.. tostring(self:Stuck()))
				self:Log(3, "underwtaer:" ..tostring(self:Underwater()))
				local doJump = false;
				local forceFix = false;
				local collData = self:GetCollideEntity(1);
				if (collData and collData.id) then
					if (collData.entity.vehicle) then
						doJump = true;
						--self.lastJumpStuckFix = nil;
						--self:Log(0,"Stuck on vehicle !!")
						forceFix=true;
					end
					if (self._stuckTime>=3) then
						
						forceFix=true;
					end
					--self:SendMsg("Coll data success!")
				end
				if (self:Stuck() or self:Underwater() or forceFix) then
					self:Log(1, "Stuck or underwatrer!!!");
					if (self._stuckTime >= 15) then
						self:Kill();
					end
					if (not self:Underwater()) then
						local door=self:DoorInFront(2)
						if (door) then
							if (door.action~=DOOR_OPEN) then
								self:OpenDoor(door);
							else
								self:CloseDoor(door);
							end
						end
					end
					if (self:Underwater()) then
						if (not self.lastWaterImp or _time - self.lastWaterImp >= 0.3) then
							self.lastWaterImp = _time;
							g_localActor:AddImpulse(-1, g_localActor:GetCenterOfMassPos(), g_Vectors.up, BOT_WATER_IMPULSE, 1);
							g_localActor:AddImpulse(-1, g_localActor:GetCenterOfMassPos(), self:GetViewCameraDir(), BOT_WATER_IMPULSE * 1.25, 1);
							self:Log(1, "Stuck in Water, Adding Water impulse");
						end
					end
					
					if (self._proneTime and not self._tryingUnprone) then
						self._tryingUnprone=true
						self:StopProne();
					--	self:Log(0, "TRYING TO UNRPRONE!!")
						self:StartMoving(4,self:GetPosInFront(-1));
					end
					
					--if (not self.crouchTried or _time - self.crouchTried>=3) then
					--	self.crouchTried=_time;
					--	self:PressKey('crouch',1);
					--end
					
					local jumpWillFix, jumpSuitMode = self:JumpWillFix();
					self:Log(3, "JUMP = " .. tostring(jumpWillFix) .. ", NOF = " .. tostring((not self.followTargetSpot)) )
					--self:Log(0, not self.followTargetSpot)
					
					if (self._stuckTime>=3) then
						self.followTargetSpot=false;
					end
					-- self:Log(0, "Wil fix : " .. tostring(self.followTargetSpot))
					
					local bNoStrength = true
					local bWillFix = false
					local bCollision = 
						self:GetCollideEntity(1.5, 0, "Bip01 Pelvis") ~= nil or
						self:GetCollideEntity(1.5, -0.25, "Bip01 Pelvis") ~= nil
					if (bCollision) then
						bNoStrength = false
						bWillFix = 
							self:GetCollideEntity(1, 0, "Bip01 Head") == nil or
							self:GetCollideEntity(1, 0.15, "Bip01 Head") == nil
					end
					
					self:Log(1, "jump fix: bWillFix=%sjumpWillFix=%s",tostring(bWillFix),tostring(jumpWillFix)) 
					if ((jumpWillFix and bWillFix) or (((jumpWillFix or self:Underwater()) and ((not self.followTargetSpot or (bWillFix)) or self:Underwater())) or doJump and not self.isBoxing)) then
						self:Log(1, "Stuck, acting")
						if (not self.lastJumpStuckFix or _time - self.lastJumpStuckFix >= 3) then
							if (not self._ZOOMING) then
								self.lastJumpStuckFix = _time;
								if (not bNoStrength) then
									self:SuitMode(self.STRENGTH);
								end
								self.JUMP_FIX_TIMER = timerinit()
								self.jumpFix = _time;
								self:InvokeJump();
								self.tempMovement = self.currentMovement;
								self:PressKey('moveforward');
							end
							self.LAST_UNSTUCK_TIMER = timerinit()
						elseif (not self:Underwater()) then
						-- find me
							local sidePos, movDir = self:GetPosToSide(2, 6, true);
							if (not self._fixMoving or _time - self._fixMoving >= 3) then
						--		self:SendMsg("MOVING TO SIDE: " .. movDir);
								self._fixMoving = _time;
								--self:StopMovement()
								self:StartMoving(movDir, sidePos);
							--	self.noCamMove = true;
								self.unstuckMov = true;
							end
						end
					--	if (not self:IsKeyPressed('moveforward')) then
					--	end
						self:Log(2, "Jump will fix bug!!!");
					elseif (not jumpWillFix and not self.lastSeenMoving) then
						self:Log(2, "$4Jump won't fix bug!!!");
						self:Log(1, "$4Checking if other pathnode would be visible");
						self:CheckNextVisiblePathNode();
						--bot_enabled=false
	--					self.lastActorPos = g_localActor:GetPos();
						return
					else
						self:DefaultSuitMode()
					end
					
					if (timerexpired(self.LAST_UNSTUCK_TIMER, 0.15)) then
						self:DefaultSuitMode() end
					
					
				else
				
					if (timerexpired(self.JUMP_FIX_TIMER, 2) and timerexpired(self.MELEE_TIMER, 2) and not self.boxRun) then
						self:Log(3, "DEFAULT SZUIT AFTER JUMP FIX !!")
						self:DefaultSuitMode()
					end
				
					if (self.unstuckMov) then
						self.unstuckMov=false;
						self:ResetPath()
					--	self:SendMsg("RESET PATH!")
					end
					
					if (not self._aimEntityId) then
						self.boxRun=true
						--self:Log(-1, "RUN OK !")
					else
						self.boxRun=false
						--self:Log(-1, "RUN BAD !")
					end
					
					self._tryingUnprone=false
					self:ProcessBoxRunning()
				end
			end
		else
			self.nomovement = false
			self.NO_MOVEMENT = true
			self.NO_MOVEMENT_START = self.NO_MOVEMENT_START or timerinit()
			
			if (self.bSprinting) then
				self:StopSprint();
			end
			
			self:Log(2, "No movement");
			
			if (self.lastSeenMoving) then
				self.lastSeenMoving=false;
			end
			

			
			if (not self:HasTarget() and not self.lastSeenMoving and not self.temp._aimEntityId) then
				if (not self.followTarget or not self.followConfig.NanoSuit[self.suitModes[g_localActor.actor:GetNanoSuitMode()]]) then
					if (not self._nosuitchangeTime or _time - self._nosuitchangeTime > 0.3) then
						
		
						--[[if (EXPERIMENTAL_AI_FOLLOWING) then
							self:Log(0, "FOLLOWING!")
							if (not _FOLLOWGRUNT or not System.GetEntity(_FOLLOWGRUNT.id)) then
								self:SpawnGrunt()
							end
							self:ProcessFollowGrunt(_FOLLOWGRUNT);
							return
						else
							self:ResetPath();
						end--]]
						if not BOXKEYRUNNING and not self.boxRun then
							self:DefaultSuitMode()
						end
					end
				end
				

			else
				self.nomovement = true;
			end
		end
		
		g_localActor.lastPos = g_localActor:GetPos();
	--	self.lastActorPos = g_localActor:GetPos();
	end,
	---------------------------
	DefaultSuitMode = function(self)
		if (not timerexpired(self.IGNORE_DEFAULT_SUIT_TIMER, 2)) then
			return end
		
		self:Log(1, "SETTING DEFAULT SUIT MODE!")
		self:SuitMode(self[self.botDefaultSuit]);
	end,
	---------------------------
	HasOperationWeapon = function(self)
		local hCurrent = self:GetCurrentItem()
		if (not hCurrent) then
			return false end
			
		if (not hCurrent.weapon) then
			return false end
			
		local iAmmo = hCurrent.weapon:GetAmmoCount()
		if (not iAmmo) then
			return false end
			
		return (hCurrent.weapon:GetAmmoCount() >= 1)
	end,
	---------------------------
	ResetThreat = function(self)
		self:Log(0, "THREAT RESET !!")
		self.CURRENT_ACTIVE_THREAT = nil
	end,
	---------------------------
	ShootThreat = function(self, hEntityId, bThowNade)
	
		----------------
		self:Log(0, "Shooting Threats!")
		
		----------------
		local hThreat = GetEntity(hEntityId)
		if (not hThreat) then
			return false end
		
		----------------
		local vThreat = hThreat:GetPos()
		if (not BotNavigation:IsNodeVisibleEx(vThreat)) then
			return self:ResetThreat() end
		
		----------------
		self:Prone(1)
		
		----------------
		if (bThowNade and self:GetNades() > 0) then
			if (timerexpired(self.LAST_GRENADE_TIME)) then
				self.LAST_GRENADE_TIME = timerinit()
				
				self:SuitMode(NANOMODE_STRENGTH)
				self:StopAim()
				g_localActor.actor:SimulateInput('grenade', 1, 1)
				g_localActor.actor:SimulateInput('grenade', 2, 2)
				
				self:Log(3, "Throwing a greande!")
			end
		elseif (self:CanFire()) then
			self:Aim()
			self:SetCameraTarget(vThreat)
			self:PressKey("attack1", 0.1)
		end
	
		----------------
		self.SHOOTING_THREATS = true
	end,
	---------------------------
	ProcessShootExplosives = function(self)
	
		----------------
		self:Log(3, "Checking THREATS!")
			
		----------------
		if (CheckEntity(self.CURRENT_ACTIVE_THREAT)) then
			return self:ShootThreat(self.CURRENT_ACTIVE_THREAT, false) end
			
		----------------
		self:Log(3,"SHOOT EXPLO!!")
		
		----------------
		local bIsPS = (g_gameRules.class == "PowerStruggle")
		local vPos = g_localActor:GetPos()
		
		----------------
		self:CheckThreats("claymoreexplosive")
		self:CheckThreats("c4explosive", nil, true)
	end,
	---------------------------
	CheckThreats = function(self, sThreatClass, vPos, bNeedsNades)
	
		----------------
		if (bNeedsNades and self:GetNades() < 1) then
			return true end
	
		----------------
		if (CheckEntity(self.CURRENT_ACTIVE_THREAT)) then
			return true end
			
		----------------
		local vPos = vPos
		if (not vector.isvector(vPos)) then
			vPos = g_localActor:GetPos() end
	
		----------------
		local aThreats = System.GetEntitiesByClass(sThreatClass)
		for i, hThreat in pairs(aThreats or{}) do
			self:Log(5, "Threat %d = %s", i, hThreat:GetName())
			
			local bEnemyThreat = false
			if (bIsPS) then
				bEnemyThreat = not self:SameTeam(hThreat.id)
			else
				bEnemyThreat = (Game.GetProjectileOwner(hThreat.id) ~= g_localActorId)
			end
			
			if (bEnemyThreat) then
				local vThreat = hThreat:GetPos()
				local iDistance = vector.distance(vThreat, vPos)
				if (iDistance < 15 and BotNavigation:IsNodeVisible(vector.modify(vThreat, "z", 0.25, true))) then
					self.CURRENT_ACTIVE_THREAT = hThreat
					break
				end
			end
		end
		
		----------------
		return true
	end,
	---------------------------
	ProcessBoxRunning = function(self)
	
		-----------
		if (not BOT_USE_CIRCLEJUMPING) then
			self:Log(3, "Cannot Circlejump: Disabled")
			return end
	
		-----------
		if (self:GetEntitiesInRange("Door", 5, g_localActor:GetPos())) then
			self:Log(3, "Cannot Circlejump: Doors")
			return end
	
		-----------
		if (not BotNavigation:CanCircleJumpOnCurrentPath()) then
			self:Log(3, "Cannot Circlejump: Navigation")
			return end
	
		-----------
		if (not isNull(self._NOENTITYTIME) and _time - self._NOENTITYTIME < 1) then
			self:Log(3, "Cannot Circlejump: Entity Time")
			return end
	
		-----------
		local iGoalDistance = self.CURRENT_GOAL_DISTANCE
		if (not compNumber(iGoalDistance, 2)) then
			self:Log(3, "Cannot Circlejump: Too Close to goal position")
			return end
	
		-----------
		if (not timerexpired(self.C4_DETONATION_TIMER, 1)) then
			self:Log(3, "Cannot Circlejump: We're detonating C4")
			return end
	
		-----------
		local hCurrent = self:GetCurrentItem()
					if (self.boxRun and self._difficulty>1) then
						self:Log(2, "BOX RUN !!!")
						
						if not  System.IsPointIndoors(g_localActor:GetPos()) then
							if (not self.boxKeyRun) then
								self.boxKeyRun = { 
									
								};
							end
							if (not self.boxKeyRun.L) then -- this needs a rework since it does not work too well (at all)
								self.boxKeyRun.L = true;
								self:PressKey("moveleft", 0.2);
								self:Log(0, "BOX RUN -> MOVELEFT !!!")
								Script.SetTimer(50, function()
								
									if (g_localActor.actor:GetNanoSuitEnergy() >= 130 and not self:PlayersNear(20)) then
										self:SuitMode(NANOMODE_SPEED)
										self.IGNORE_DEFAULT_SUIT_TIMER = timerinit()
										
										if (g_gameRules.class == "PowerStruggle" and not self.temp._aimEntityId) then 
											if (not hCurrent or (hCurrent.class ~= "RadarKit")) then
												g_localActor.actor:SelectItemByName("Fists") end
										else
											self:SelectNewItem() 
										end
												
									else
										self:SuitMode(NANOMODE_DEFENSE);
									end
									self:Log(1, " $6BOXRUN: JUMP");
									--self:SuitMode(self['SPEED']);
									self:PressKey("jump", 1);
									self:Log(0, "BOX RUN -> JUMP !!!")
									Script.SetTimer(200, function()
										self:ReleaseKey("moveleft");
										if (self.boxKeyRun) then
											self:PressKey("moveright", 0.2);
											self:Log(0, "BOX RUN -> MOVERIGHT !!!")
											Script.SetTimer(400, function()
												if (self.boxKeyRun) then
													self.boxKeyRun.L = nil;
													self:Log(0, "BOX RUN -> RESET !!!")
													--self:SuitMode(NANOMODE_DEFENSE);
												end
											end);
										end
									end);
								end);
							end
						end
					else
						self.boxKeyRun = nil;
					end
	
	end,
	---------------------------
	GetNades = function(self)
		return g_localActor.inventory:GetAmmoCount("explosivegrenade")
	end,
	---------------------------
	CanFire = function(self)
		return self:GetCurrentItem() and self:GetCurrentItem().weapon and self:GetCurrentItem().weapon:GetAmmoCount()>=1
	end,
	---------------------------
	SpawnGrunt = function(self,p,d)
	
		local sTraceback = (debug.traceback() or "traceback failed")
		self:Log(0, "SpawnGrunt() Called. Traceback: %s", sTraceback)
		
		do return true end
	
		--[[local Properties = {

		rank = 4,
		special = 0,

		attackrange = 0,
		reaction = 0,	-- time to startr shooting with nominal accuracy
		commrange = 300.0,
		accuracy = 0.0,
		distanceToHideFrom=0,

		smartObject_smartObjectClass="Actor";
		species = 0,
		bSpeciesHostility = 0,
		fGroupHostility = 0,
		equip_EquipmentPack="NK_Sniper_Assault",
		AnimPack = "Basic",
		SoundPack = "Korean03",		
		SoundPackAlternative = "Korean03_eng",
		nVoiceID = 0,
		aicharacter_character = "WatchTowerGuard",
		fileModel = "objects/characters/human/us/marine/marine_01.cdf",
		nModelVariations=0,
		bTrackable=1,
		bSquadMate=1,
		bSquadMateIncendiary=0,
		bGrenades=0,
		IdleSequence = "None",
		bIdleStartOnSpawn = 0,
		
		bCannotSwim = 0,
		bInvulnerable = 1,
		bNanoSuit =1,

		eiColliderMode = 0, -- zero as default, meaning 'script does not care and does not override graph, etc'.

		awarenessOfPlayer = 0,

		Perception =
		{
			--how visible am I
			camoScale = 1,
			--movement related parameters
			--VELmultyplier = (velBase + velScale*CurrentVel^2);
			--current priority gets scaled by VELmultyplier
			velBase = 1,
			velScale = .03,
			--fov/angle related
			FOVPrimary = 0,--80,			-- normal fov
			FOVSecondary = 0,--160,		-- periferial vision fov
			--ranges			
			sightrange = 0,
			sightrangeVehicle = -1,	-- how far do i see vehicles
			--how heights of the target affects visibility
			--// compare against viewer height
			-- fNewIncrease *= targetHeight/stanceScale
			stanceScale = 1.9,
			-- Sensitivity to sound 0=deaf, 1=normal
			audioScale = 1,
			-- Equivalent to camo scale, used with thermal vision.
			heatScale = 1,
			-- Flag indicating that the agent has thermal vision.
			bThermalVision = 0,
			-- The perception reaction speed, default speed = 1. THe higher the value the faster the AI acquires target.
			reactionSpeed = 1,
			-- controls how often targets can be switched, 
			-- this parameter corresponds to minimum ammount of time the agent will hold aquired target before selectng another one
			-- default = 0 
			persistence = 0,
			-- controls how long the attention target have had to be invisible to make the player stunts effective again
			stuntReactionTimeOut = 3.0,
			-- controls how sensitive the agent is to react to collision events (scales the collision event distance).
			collisionReactionScale = 0,--1.0,	
			-- flag indicating if the agent perception is affected by light conditions.
			bIsAffectedByLight = 0,	
			-- Value between 0..1 indicating the minimum alarm level.
			minAlarmLevel = 0,	
		},
	};
	
			local AIMovementAbility =
	{
		pathFindPrediction = 0.5,		-- predict the start of the path finding in the future to prevent turning back when tracing the path.
		allowEntityClampingByAnimation = 1,
		usePredictiveFollowing = 1,
		walkSpeed = 33.0, -- set up for humans
		runSpeed = 33.0,
		sprintSpeed = 33.4,
		b3DMove = 0,
		pathLookAhead = 1, 
		pathRadius = 0.4,
		pathSpeedLookAheadPerSpeed = -1.5,
		cornerSlowDown = 0.0,--75,
		maxAccel = 3.0,
		maxDecel = 8.0,
		maneuverSpeed = 1.5,
		velDecay = 0.5,
		minTurnRadius = 0,	-- meters
		maxTurnRadius = 0,--3,	-- meters
		maneuverTrh = 2.0,  -- when cross(dir, desiredDir) > this use manouvering
		resolveStickingInTrace = 1,
		pathRegenIntervalDuringTrace = 4,
		lightAffectsSpeed = 1,

		-- These are actually aiparams (as they may be changed during game and need to get serialized),
		-- but defined here so that designers do not try to change them.
		lookIdleTurnSpeed = 530,
		lookCombatTurnSpeed = 550,
		aimTurnSpeed = -1, --120,
		fireTurnSpeed = -1, --120,
		
		-- Adjust the movement speed based on the angel between body dir and move dir.
		directionalScaleRefSpeedMin = 1.0,
		directionalScaleRefSpeedMax = 8.0,

	  AIMovementSpeeds = 
	  {
			Relaxed =
			{
				Slow =		{ 17.5, 17.3,17.0 },--{ 1.0, 1.0,1.9 },
				Walk =		{ 17.5, 17.3,17.0 },--{ 1.3, 1.0,1.9 },
				Run =		{ 17.5, 17.3,17.0 },--	{ 4.5, 2.0,7.2 },
			},
			Combat =
			{
				Slow =		{ 17.5, 17.3,17.0 },--{ 7.5, 7.3,7.0 },--{ 0.8, 0.8,1.3 },
				Walk =		{ 17.5, 17.3,17.0 },--{ 7.5, 7.3,7.0 },--{ 1.3, 0.8,1.3 },
				Run =		{ 17.5, 17.3,17.0 },--{ 17.5, 17.3,17.0 },--{ 7.5, 7.3,7.0 },--	{ 4.5, 2.3,6.0 },
				Sprint =	{ 7.5, 7.3,7.0 },--{ 6.5, 2.3,6.5 },
			},
			Crouch =
			{
				Slow =		{ 17.5, 17.3,17.0 },--{ 0.5, 0.3,1.3 },
				Walk =		{ 17.5, 17.3,17.0 },--{ 0.9, 0.3,1.3 },
				Run =		{ 17.5, 17.3,17.0 },--	{ 3.5, 2.7,5.5 },
			},
			Stealth =
			{
				Slow =		{ 17.5, 17.3,17.0 },--{ 7.5, 7.3,7.0 },--{ 0.8, 0.7,1.0 },
				Walk =		{ 17.5, 17.3,17.0 },--{ 7.5, 7.3,7.0 },--{ 0.9, 0.7,1.0 },
				Run =		{ 17.5, 17.3,17.0 },--{ 7.5, 7.3,7.0 },--	{ 3.5, 2.7,5.5 },
			},
			Prone =
			{
				Slow =		{ 17.5, 17.3,17.0 },--{ 7.5, 7.3,7.0 },--{ 0.4, 0.4,0.5 },
				Walk =		{ 17.5, 17.3,17.0 },--{ 7.5, 7.3,7.0 },--{ 0.5, 0.4,0.5 },
				Run =		{ 17.5, 17.3,17.0 },--{ 7.5, 7.3,7.0 },--	{ 0.5, 0.4,0.5 },
			},
			Swim =
			{
				Slow =		{ 17.5, 17.3,17.0 },--{ 7.5, 7.3,7.0 },--{ 0.5, 0.6,0.7 },
				Walk =		{ 17.5, 17.3,17.0 },--{ 7.5, 7.3,7.0 },--{ 0.6, 0.6,0.7 },
				Run =		{ 17.5, 17.3,17.0 },--{ 7.5, 7.3,7.0 },--	{ 3.0, 2.9,4.3 },
			},
	  },
	}--]]
	
	local Properties = {

		rank = 4,
		special = 0,

		attackrange = 0,
		reaction = 0,	-- time to startr shooting with nominal accuracy
		commrange = 30.0,
		accuracy = 0.0,
		distanceToHideFrom=3,

		smartObject_smartObjectClass="Actor";
		species = 0,
		bSpeciesHostility = 0,
		fGroupHostility = 0,
		equip_EquipmentPack="NK_Sniper_Assault",
		AnimPack = "Basic",
		SoundPack = "Prophet",		
		SoundPackAlternative = "",
		nVoiceID = 0,
		aicharacter_character = "FriendlyNPC",
		fileModel = "objects/characters/human/story/laurence_barnes/laurence_barnes_face.cdf",
		nModelVariations=0,
		bTrackable=1,
		bSquadMate=0,
		bSquadMateIncendiary=0,
		bGrenades=0,
		IdleSequence = "None",
		bIdleStartOnSpawn = 0,
		
		bCannotSwim = 0,
		bInvulnerable = 1,
		bNanoSuit = 1,

		eiColliderMode = 3, -- zero as default, meaning 'script does not care and does not override graph, etc'.

		awarenessOfPlayer = 0,

		Perception =
		{
			--how visible am I
			camoScale = 1,
			--movement related parameters
			--VELmultyplier = (velBase + velScale*CurrentVel^2);
			--current priority gets scaled by VELmultyplier
			velBase = 10,
			velScale = 10, --.03,
			--fov/angle related
			FOVPrimary = 0,--80,			-- normal fov
			FOVSecondary = 0,--160,		-- periferial vision fov
			--ranges			
			sightrange = 0,
			sightrangeVehicle = -1,	-- how far do i see vehicles
			--how heights of the target affects visibility
			--// compare against viewer height
			-- fNewIncrease *= targetHeight/stanceScale
			stanceScale = 1.9,
			-- Sensitivity to sound 0=deaf, 1=normal
			audioScale = 1,
			-- Equivalent to camo scale, used with thermal vision.
			heatScale = 1,
			-- Flag indicating that the agent has thermal vision.
			bThermalVision = 0,
			-- The perception reaction speed, default speed = 1. THe higher the value the faster the AI acquires target.
			reactionSpeed = 0,
			-- controls how often targets can be switched, 
			-- this parameter corresponds to minimum ammount of time the agent will hold aquired target before selectng another one
			-- default = 0 
			persistence = 0,
			-- controls how long the attention target have had to be invisible to make the player stunts effective again
			stuntReactionTimeOut = 0.0,
			-- controls how sensitive the agent is to react to collision events (scales the collision event distance).
			collisionReactionScale = 0.0,	
			-- flag indicating if the agent perception is affected by light conditions.
			bIsAffectedByLight = 0,--1,	
			-- Value between 0..1 indicating the minimum alarm level.
			minAlarmLevel = 0,	
		},
		
		AIMovementAbility =
	{
		pathFindPrediction = 0.5,		-- predict the start of the path finding in the future to prevent turning back when tracing the path.
		allowEntityClampingByAnimation = 0,--1,
		usePredictiveFollowing = 1,
		walkSpeed = 63.0, -- set up for humans
		runSpeed = 63.0,
		sprintSpeed = 63.4,
		b3DMove = 0,
		pathLookAhead = 1, 
		pathRadius = 0.4,
		pathSpeedLookAheadPerSpeed = -1.5,
		cornerSlowDown = 0.0,--75,
		maxAccel = 3.0,
		maxDecel = 8.0,
		maneuverSpeed = 1.5,
		velDecay = 0.5,
		minTurnRadius = 0,	-- meters
		maxTurnRadius = 0,--3,	-- meters
		maneuverTrh = 2.0,  -- when cross(dir, desiredDir) > this use manouvering
		resolveStickingInTrace = 1,
		pathRegenIntervalDuringTrace = 4,
		lightAffectsSpeed = 0, --1,

		-- These are actually aiparams (as they may be changed during game and need to get serialized),
		-- but defined here so that designers do not try to change them.
		lookIdleTurnSpeed = 530,
		lookCombatTurnSpeed = 550,
		aimTurnSpeed = -1, --120,
		fireTurnSpeed = -1, --120,
		
		-- Adjust the movement speed based on the angel between body dir and move dir.
		directionalScaleRefSpeedMin = 100, --1.0,
		directionalScaleRefSpeedMax = 999, --8.0,

	  AIMovementSpeeds = 
	  {
			Relaxed =
			{
				Slow =		{ 117.5, 117.3,117.0 },--{ 1.0, 1.0,1.9 },
				Walk =		{ 117.5, 117.3,117.0 },--{ 1.3, 1.0,1.9 },
				Run =		{ 117.5, 117.3,117.0 },--	{ 4.5, 2.0,7.2 },
			},
			Combat =
			{
				Slow =		{ 117.5, 117.3,117.0 },--{ 7.5, 7.3,7.0 },--{ 0.5, 0.6,0.7 },
				Walk =		{ 117.5, 117.3,117.0 },--{ 7.5, 7.3,7.0 },--{ 0.6, 0.6,0.7 },
				Run =		{ 117.5, 117.3,117.0 },--{ 7.5, 7.3,7.0 },--	{ 3.0, 2.9,4.3 },
				Sprint =	{ 117.5, 117.3,117.0 },--{ 6.5, 2.3,6.5 },
			},
			Crouch =
			{
				Slow =		{ 117.5, 117.3,117.0 },--{ 7.5, 7.3,7.0 },--{ 0.5, 0.6,0.7 },
				Walk =		{ 117.5, 117.3,117.0 },--{ 7.5, 7.3,7.0 },--{ 0.6, 0.6,0.7 },
				Run =		{ 117.5, 117.3,117.0 },--{ 7.5, 7.3,7.0 },--	{ 3.0, 2.9,4.3 },
			},
			Stealth =
			{
				Slow =		{ 117.5, 117.3,117.0 },--{ 7.5, 7.3,7.0 },--{ 0.5, 0.6,0.7 },
				Walk =		{ 117.5, 117.3,117.0 },--{ 7.5, 7.3,7.0 },--{ 0.6, 0.6,0.7 },
				Run =		{ 117.5, 117.3,117.0 },--{ 7.5, 7.3,7.0 },--	{ 3.0, 2.9,4.3 },
			},
			Prone =
			{
				Slow =		{ 117.5, 117.3,117.0 },--{ 7.5, 7.3,7.0 },--{ 0.5, 0.6,0.7 },
				Walk =		{ 117.5, 117.3,117.0 },--{ 7.5, 7.3,7.0 },--{ 0.6, 0.6,0.7 },
				Run =		{ 117.5, 117.3,117.0 },--{ 7.5, 7.3,7.0 },--	{ 3.0, 2.9,4.3 },
			},
			Swim =
			{
				Slow =		{ 117.5, 117.3,117.0 },--{ 7.5, 7.3,7.0 },--{ 0.5, 0.6,0.7 },
				Walk =		{ 117.5, 117.3,117.0 },--{ 7.5, 7.3,7.0 },--{ 0.6, 0.6,0.7 },
				Run =		{ 117.5, 117.3,117.0 },--{ 7.5, 7.3,7.0 },--	{ 3.0, 2.9,4.3 },
			},
	  },
	}
	};
	for i, v in pairs(System.GetEntitiesByClass("Grunt")or{})do
		System.RemoveEntity(v.id)
	end
	
	if (not Grunt) then
		Script.ReloadScript("Scripts/entities/ai/grunt.lua")
	end
	
		Grunt.Properties = Properties;
		Grunt.Properties.AIMovementAbility=Properties.AIMovementAbility
		
		Grunt.AIMovementAbility=Properties.AIMovementAbility
		Grunt.AIMovementSpeeds=Properties.AIMovementAbility.AIMovementSpeeds
		
		BasicAI.AIMovementAbility=Properties.AIMovementAbility
		BasicAI.AIMovementSpeeds=Properties.AIMovementAbility.AIMovementSpeeds
		
		BasicActor.AIMovementSpeeds=Properties.AIMovementAbility.AIMovementSpeeds
		BasicActor.AIMovementAbility=Properties.AIMovementAbility
	
	--if (BasicAI) then BasicAI.AIMovementAbility=AIMovementAbility end
		--end
		if (Grunt) then	Grunt.Properties = Properties;end
		
				posInFront = System.GetViewCameraPos()
			local dir = System.GetViewCameraDir()
			posInFront.x = posInFront.x + (dir.x * 3);
			posInFront.y = posInFront.y + (dir.y * 3);
			posInFront.z = posInFront.z + (dir.z * 3);
			if (self:CanSeePos_Check(posInFront)) then
			
			else
				posInFront = System.GetViewCameraPos()
				dir = System.GetViewCameraDir()
				posInFront.x = posInFront.x + (dir.x * -3);
				posInFront.y = posInFront.y + (dir.y * -3);
				posInFront.z = posInFront.z + (dir.z * -3);
			end
			--System.LogAlways("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!>>>>")
--			AI.ParseTables(AIMovementAbility);
		--	System.LogAlways("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!<<<<")
		local ent = System.SpawnEntity({
			class = "Grunt",
			position = (p or posInFront),
			name = 'follow_grunt',
			Properties = Properties,
			properties = Properties
		});
		

	
	ent.AIMovementAbility = AIMovementAbility
			
			
		--	ent:SetColliderMode(3)
				_FOLLOWGRUNT = ent
				_FOLLOWGRUNT.Properties.species = 0;
				g_localActor.Properties.species = 0;
				
				for i, player in pairs(g_gameRules.game:GetPlayers()) do
					player.Properties.species = 0
				Game.RegisterAI(player.id,true);
				end
				Game.RegisterAI(_FOLLOWGRUNT.id,true);
				AI.AbortAction(ent.id,0);
				_FOLLOWGRUNT.spawntime=_time
				AI.SetIgnorant(ent.id,1);
				--AI.SetIgnorant(ent.id,true);
			--	_FOLLOWGRUNT:SetPos((p or posInFront));
	end,
	---------------------------
	DoorInFront = function(self, iDistance)
	
		local hRayHitTarget = self:GetRayHitInfo(eRH_ENTITY, iDistance)
		if (not hRayHitTarget) then
			return end
			
		if (hRayHitTarget.class ~= "Door") then
			return end
			
		return hRayHitTarget
	end,
	---------------------------
	DoorInFront_Z = function(self, d)
		local allDoors = System.GetEntitiesByClass("Door");
		local closestDoor, theClosestDoor = d or 3, nil;
		for i, entity in ipairs(allDoors or{}) do
			if (self:GetDistance({x=entity:GetPos().x,y=entity:GetPos().y,z=entity:GetPos().z-100}) < closestDoor) then
				closestDoor = self:GetDistance(entity);
				theClosestDoor = entity;
			end
		end
		return theClosestDoor;
	end,
	---------------------------
	OpenDoor = function(self, door)
		if (not door.opentime or _time - door.opentime >= 3) then
			door.opentime = _time;
			door.server:SvRequestOpen(g_localActor.id, true);
		end
	end,
	---------------------------
	CloseDoor = function(self, door)
		if (not door.closeTime or _time - door.closeTime >= 3) then
			door.closeTime = _time;
			door.server:SvRequestOpen(g_localActor.id, false);
		end
	end,
	---------------------------
	JumpWillFix = function(self)
	
		local suit = 1;
		if (not self:GetCollideEntity(2)) then
			return true, suit;
		else
			suit = 3;
			if (not self:GetCollideEntity(2, 1)) then
				return true, suit;
			end
		end
		
		do return false; end
	
		local from1, to1 = self:GetViewCameraPos(), self:CalcPos(1);
		from1.z = from1.z + 0;
		to1.z = to1.z + 1;
		
		local from2, to2 = self:GetViewCameraPos(), self:CalcPos(1);
		from2.z = from2.z + 0;
		to2.z = to2.z + 1.5;
		
		local try1 = self:CanSeePosition_Advanced(self:GetViewCameraPos(), self:CalcPos(1));--, self:CanSeePosition_Advanced(from1, to1), self:CanSeePosition_Advanced(from2, to2);
		local try2, try3;
		if (try1) then
			return true, 3;
		else
			try2 = self:CanSeePosition_Advanced(from1, to1);
			if (try2) then
				return true, 1;
			else
				try3 = self:CanSeePosition_Advanced(from2, to2);
				if (try3) then
					return true, 1;
				else
					return false;
				end
			end
		end
		return false;
	end,
	---------------------------
	GetVelocity = function(self)
		if (g_localActor.lastPos) then
			return self:GetDistance(g_localActor.lastPos);
		end
		return 0;
	end,
	---------------------------
	NullVelocity = function(self)
	
		if (self._LASTSEENCAMPING) then return false; end
	
		local v = g_localActor:GetVelocity();
		--self:Log(0, self.stuckTime .. " >> " .. self:GetVelocity() .. " >> " .. Vec2Str(v))
		local highVel = ((v.x < -2 or v.x > 2) or (v.z < -2 or v.z > 2) or (v.z < -2 or v.z > 2))
		
		if (self.stuckTime>=0.5) then
			return true;
		elseif (self:GetVelocity() < 0.01 and highVel) then
			return true;
		end
		
	
		
		return (v.x > -0.01 and v.x < 0.01 and v.y > -0.01 and v.y < 0.01 and v.z > -0.01 and v.z < 0.01);
	end,
	---------------------------
	Stuck = function(self, distance)
		local _checkDistance = distance or 0.005;
		if (_lastGLPos) then
			if (self:NullVelocity()) then --self.stuckTime and (self.stuckTime == 0 or self.stuckTime >= 0.1)) then
				--if () then --self:GetDistance(_lastGLPos) <= _checkDistance) then
				--	return true;
				--end
				--self.RTStucks = 0;
				return true;
			elseif (self:RayStuckCheck()) then
				self.RTStucks = (self.RTStucks or 0) + 1;
				if (self.RTStucks >= 3) then
					self:Log(1, "STUCK :RAYTRACE")
					return true;
				else
					self.RTStucks = 0;
				end
			else
			--	self.RTStucks = 0;
				return false;
			end
		else
			--self:Log(1, "No!!!!")
			--self.RTStucks = 0;
			return false;
		end
		--self.RTStucks = 0;
		return false;
	end,
	---------------------------
	RayStuckCheck = function(self)
		return (not self:CanSeePosition(self:CalcPos(0.5)));
	end,
	---------------------------
	GoalReached = function(self, vGoal)
	
		---------
		local vPos = g_localActor:GetPos()
		local iDistance = vector.distance(vGoal, vPos)
		
		---------
		local iTriggerDistance = checkNumber(self.GOAL_REACHED_DISTANCE, (self.lastSeenMoving and 3 or self.isBoxing and 1.5 or 1.5))
		
		---------
		self:Log(3, "GOAL DIST TRIGGER DIST: %f", iTriggerDistance)
		
		---------
		self.CURRENT_GOAL_DISTANCE = iDistance
		
		---------
		return (iDistance <= iTriggerDistance)
	
		-- return (self:GetDistance(goal) <= (self.lastSeenMoving and 3 or self.isBoxing and 1.5 or 1.5));
	end,
	---------------------------
	capData = {};
	_generatedPathes = 0;
	---------------------------
	PathfindingReset = function(self)

		----------------
		self:Log(0, "Resetting Pathfinding Data")

		----------------
		BotNavigation:ResetPathData()
	end,
	---------------------------
	ProcessPathfinding = function(self)
	
		if (not timerexpired(self.ENTER_VEHICLE_TIMER, 5)) then
			return
		end
	
		BotNavigation:Update()
	end,
	---------------------------
	ProcessPath = function(self, comingFromExperimental)
		self:Log(2, "Process Path Following !!")
	
		------------------
		if (Pathfinding) then
			if (Pathfinding.IsOperational()) then
				return self:ProcessPathfinding()
			else
				self:Log(3, "Pathfinding is not Operational!")
			end
		end
	
		------------------
		if (g_localActor.actor:GetLinkedVehicleId()) then
		end
		
		------------------
		-- disabled after new Pathfinding system was added
		if (false) then
			if (EXPERIMENTAL_AI_FOLLOWING) then
				------------------
				if (not _FOLLOWGRUNT) then
					self:SpawnGrunt() end
				
				------------------
				self:ProcessFollowGrunt(_FOLLOWGRUNT)
				return
			end
		end
		
		------------------
		if (self.followTarget) then
			------------------
			local vFollowPos = self.followTarget:GetPos();
			vFollowPos.z = vFollowPos.z + 1

			------------------
			if (self:GetDistance(vFollowPos) < self.followConfig.LooseDistance and self:CanSeePosition(vFollowPos, self.followTarget.id)) then
				return 	end
		end
		
		------------------
		if (not self._posData) then
			self:Log(2, "No Pathdata found for this Map");
			return self:ProcessExperimentalAIPathLearning();
		end
		
		------------------
		self:ContinueOnPath()
	end,
	---------------------------
	StupidObjectInWay = function(self)
		local dir = self:GetViewCameraDir();
		local hits = Physics.RayWorldIntersection((from or self:GetViewCameraPos()), { x=dir.x*4, y=dir.y*4, z=dir.z*4 }, 4, ent_all-ent_living, g_localActor.id, nil, g_HitTable);
		local hitData = g_HitTable[1];
		if (hits and hits > 0 and hitData) then
			return true
		else
			return false
		end
	end,
	---------------------------
	GetRayHitInfo = function(self, eIdReturnType, iDistance)
	
		----------------
		local vPos = self:GetViewCameraPos()
		local vDir = self:GetViewCameraDir()
		
		----------------
		local iDistance = iDistance
		if (not isNumber(iDistance)) then
			iDistance = 5 end
		
		----------------
		local iHits = Physics.RayWorldIntersection(vPos, vector.scale(vDir, iDistance), iDistance, ent_all - ent_living, g_localActor.id, nil, g_HitTable);
		local aHits = g_HitTable[1];
		if (iHits and iHits > 0 and aHits) then
			
			if (eIdReturnType == eRH_ENTITY) then
				return aHits.entity
			elseif (eIdReturnType == eRH_POSITION) then
				return aHits.pos
			elseif (eIdReturnType == eRH_ALL) then
				return aHits
			end
		end
		
		return
	end,
	---------------------------
	GetClosestWJPos = function(self, dist, onlyVisible)
		if (self._AIWJ) then
			local onlyVisible = false; --(onlyVisible == nil and true or onlyVisible);
			local dist = tonumber(dist) or 5;
			local pd;
			for i, pathData in ipairs(self._AIWJ) do
				Particle.SpawnEffect("explosions.flare.night_time", pathData.start, g_Vectors.up, 0.1);
				
				self:Log(1, i .. ": " .. Vec2Str(pathData.start) .. " : " .. self:GetDistance(pathData.start) .. "<" .. dist .. " : " .. tostring((self:CanSeePosition({x=pathData.start.x,y=pathData.start.y,z=pathData.start.z+0.3}) or self:CanSeePosition(pathData.start))))
				if (self:GetDistance(pathData.start) < dist) then-- and (not onlyVisible or (self:CanSeePosition({x=pathData.start.x,y=pathData.start.y,z=pathData.start.z+0.3}) or self:CanSeePosition(pathData.start)))) then
					dist = self:GetDistance(pathData.start);
					pd = pathData;
				end
			end
			return pd;
		else
			self:Log(1, "NO WJ DATA!!!!")
		end
		return
	end,
	---------------------------
	ProcessWallJumping = function(self)
	--	do return false; end
		self:Log(2, "PROCESS WJ :: " .. tostring( self._wallJumping))
		if (not self._wallJumping) then
			local wallJumpPos = self:GetClosestWJPos(5, true); -- max 3m, onlyVisisble ;P
			self:Log(1, "WKPL: " ..tostring(wallJumpPos))
			if (wallJumpPos and 1 == 1) then-- and (not self._wjPathID_last or self._wjPathID_last ~= wallJumpPos.ID)) then
				self._wallJumping = true;
				self._wjPathID = wallJumpPos.ID;
				self._wjPathID_last = self._wjPathID;
				self._currWjNode = 1;
				self._wjStartPos = wallJumpPos.start;
			end
		else
			if (self:GetDistance(self._wjStartPos) < 1.5 or self._REACHEDSTART) then
				self:AddJumpImpulsesForWJ();
				self._REACHEDSTART=true;
			else
				self:StartMoving(1, self._wjStartPos, true);
				self:SuitMode(self.SPEED);
			end
		end
		return self._wallJumping;
	end,
	---------------------------
	GetNextClosestSpotOnWallJumpPath = function(self)
		if (self._AIWJ) then
			local onlyVisible = (onlyVisible == nil and true or onlyVisible);
			local dist = tonumber(dist) or 5;
			local pd;
			for i, pos in ipairs(self._AIWJ[self._wjPathID]) do
				--Particle.SpawnEffect("explosions.flare.night_time", pathData.start, g_Vectors.up, 0.1);
				self:Log(1, i .. ": " .. Vec2Str(pos) .. " : " .. self:GetDistance(pos) .. "<" .. dist .. " : " .. tostring(self:CanSeePosition(pos)))
				if (self:GetDistance(pos) < dist and (not onlyVisible or (self:CanSeePosition({x=pos.x,y=pos.y,z=pos.z+0.3}) or self:CanSeePosition(pos)))) then
					dist = self:GetDistance(pos);
					pd = i;
				end
			end
			return pd;
		else
			self:Log(1, "NO WJ DATA!!!!")
		end
		return
	end,
	---------------------------
	AddJumpImpulsesForWJ = function(self)
		local _nextNode = self._currWjNode;
		local nextPathSpot = self._AIWJ[self._wjPathID].flyData[_nextNode];
		self._lastStartWJump = self._lastStartWJump or _time;
		local startPathPos = self._startPathPos or g_localActor:GetPos();
	
		if (not nextPathSpot) then
			self:Log(1, "$4 WALL JUMP FINISHED!!!!")
			return self:StopWalljumping();
		end
		
		self:Log(1, _time - self._lastStartWJump / 0.1 .. " : $5" .. Vec2Str(self:lerp(startPathPos, nextPathSpot, _time - self._lastStartWJump / 0.1)))
		
		--g_localActor:SetWorldPos(self:lerp(startPathPos, nextPathSpot, _time - self._lastStartWJump / 0.1));
		
		if (self:GetDistance(nextPathSpot) < 1) then
			--if (self:GetDistance(nextPathSpot) < 0.8) then
				g_localActor:SetWorldPos({x=g_localActor:GetPos().x+0.001,y=g_localActor:GetPos().y+0.001, z=g_localActor:GetPos().z+0.001})
			--end
			self._currWjNode = self._currWjNode + 1;
			self._startPathPos  = g_localActor:GetPos();
			self._lastStartWJump = _time;
		end
		
		self:Log(1, "$4 IMPULSE :: " .. self._wjPathID .. ".flyData[".._nextNode.."] == " .. Vec2Str(nextPathSpot) .. " :: " .. self:GetDistance(nextPathSpot) .. "TOAL: " .. #self._AIWJ[self._wjPathID].flyData)
		
		
		--do return self:ProcessSmoothWJMoving(); end
		g_localActor:AddImpulse(-1, g_localActor:GetCenterOfMassPos(), self:GetDirectionVector({x=nextPathSpot.x,y=nextPathSpot.y,z=nextPathSpot.z}, g_localActor, true), 300, 1);
		
		g_localActor:SetDirectionVector( self._AIWJ[self._wjPathID].flyData_ang[_nextNode])
	end,
	---------------------------
	ProcessSmoothWJMoving = function(self)
		if self._wj_NEXT then
			local ent = g_localActor;
	
			if ent then
				local dur = _time - self._wj_TIME;
				--if params.pos then
					
						g_localActor:SetWorldPos(self:lerp(self._wj_START, self._wj_NEXT, dur / 0.05));
					
				--end
				--[[if params.scale then
					ent:SetScale(lerp(params.scale.from, params.scale.to, dur / params.duration));
				end--]]
				--[[if dur >= 0.1 then
					ActiveAnims[i] = nil;
				end--]]
			end
		end
	end,
	---------------------------
	lerp = function(self, a, b, t)
		if type(a) == "table" and type(b) == "table" then
			if a.x and a.y and b.x and b.y then
				if a.z and b.z then return self:lerp3(a, b, t) end
				return self:lerp2(a, b, t)
			end
		end
		t = self:clamp(t, 0, 1)
		return a + t*(b-a)
	end,
	---------------------------
	_lerp = function(self, a, b, t)
		return a + t*(b-a)
	end,
	---------------------------
	lerp2 = function(self, a, b, t)
		t = self:clamp(t, 0, 1)
		return { x = self:_lerp(a.x, b.x, t); y = self:_lerp(a.y, b.y, t); };
	end,
	---------------------------
	lerp3 = function(self, a, b, t)
		t = self:clamp(t, 0, 1)
		return { x = self:_lerp(a.x, b.x, t); y = self:_lerp(a.y, b.y, t); z = self:_lerp(a.z, b.z, t); };
	end,
	---------------------------
	clamp = function(self, a, b, t)
		if a < b then return b end
		if a > t then return t end
		return a
	end,
	---------------------------
	StopWalljumping = function(self, norp)
	
		self._wallJumping = false
		self._wjPathID = nil
		self._currWjNode = -1
		self._wjStartPos = nil
		self._startPathPos = nil
		
		return
	end,
	---------------------------
	SpawnEffect = function(self, pos)
		if (not self.lastEffect or _time - self.lastEffect >= 1) then
			self.lastEffect = _time;
			Particle.SpawnEffect("explosions.flare.night_time", pos, g_Vectors.up, 0.1);
		end
	end,
	---------------------------
	ClearAllData = function(self)
		self:StopMovement();
		self:StopFire();
		self:StopSprint();
		
		self.lastSeenTargetId = nil;
		self.lastSeenTargetIdStuckTime = nil;
		self.lastWhereISawEnemyPos = nil;
		self.lastWhereIWasWhenISawEnemyPos = nil;
		self.lastJump = nil;
		
		self:ClearData();
	end,
	---------------------------
	ProcessUpdate = function(self)
	
		local iPlayerCount = g_gameRules.game:GetPlayerCount()
		if (self:IsSpectating(g_localActor) and iPlayerCount >= 2) then
			self:Log(1, "spectating, reset")
			self:ClearData()
			self.reviveRequested = false
			self:LeaveSpectatorMode(g_localActor)
			return false
		end
		
		if (g_localActor:IsDead()) then
			self:Log(1, "dead, reset")
			self:ClearData() -- ???
			self:StopMovement() -- cancel everything
			self.lastSeenMoving = false
			self.walking = false
			if (not self.reviveRequested) then
				self.reviveRequested = true end
				
			return false
		else
			self.reviveRequested = false end
		
		return true
	end,
	---------------------------
	OnPlayerJump = function(self, player, isBot, channelId)
		player._jumpTime = _time;
	end,
	---------------------------
	GetPosBehind = function(self, dist, dir)
		local pos = g_localActor:GetPos();
		local dir = dir or System.GetViewCameraDir()--g_localActor.actor:GetHeadDir();
		local dist = dist or -3;
		
		local endPos = { x = pos.x + dir.x * dist, y = pos.y + dir.y * dist, z = pos.z + dir.z * dist };
		
		return endPos;
	end,
	---------------------------
	IsNadeNear = function(self, range)
		local range = tonumber(range) or 8;
		local closest = { range, nil };
		local safeDist = 8;
		for i, nade in ipairs(self.thrownNades or{}) do
			if (_time - nade.spawnTime <= 6) then
				if (self:GetDistance(nade.pos) < closest[1]) then
					closest[1] = self:GetDistance(nade.pos);
					closest[2] = nade.pos
					safeDist = closest[1] - 8
					if (safeDist < 0) then
						safeDist = safeDist * -1;
					end
				--	self:Log(0, entity:GetName());
				end
			else	
				table.remove(self.thrownNades, i);
			end
		end
		return closest[2], safeDist;
	end,
	---------------------------
	DoUpdate = function(self, isPowerStruggle, deltaTime) -- FRAMEKILLER FUNCTION
	
	
		-----------------------
		if (Config.SystemBreak == true) then
			return end
	
	
		-----------------------
		Pathfinding:Update()
	
		-----------------------
		local iFPSMax = tonumber(BOT_MAX_FPS)
		if (iFPSMax and iFPSMax >= 1) then
			local iCurrTime = os.clock();
			while (LAST_FRAME and (1 / (iCurrTime - LAST_FRAME) > iFPSMax)) do
				iCurrTime = os.clock();
			end
			LAST_FRAME = iCurrTime;
		end
		
		-----------------------
		local iBotFPS = 30
		if (BOT_CPU_SAVER) then
			iBotFPS = 24 end

		local time = _time;
		if (ON_BOT_FPS and (time - ON_BOT_FPS) < (1 / iBotFPS)) then
			return end
			
		ON_BOT_FPS = time;
		
		
		-----------------------
		if (Config.System == false) then
			return end
		
		-----------------------
		if (not g_localActor) then 
			return end
		
		
		
		--quick fix to prevent box from jumping around stupidly after killing someone. hope this works
		if (not self.temp._aimEntityId) then
			self._NOENTITYTIME = checkNumber(self._NOENTITYTIME, _time)
		else
			self._NOENTITYTIME = nil
		end
		
		
		self.actorItem = g_localActor.inventory:GetCurrentItem();
		
		-- if (not _renamed) then
			-- _renamed=true;
			-- self:Rename()
		-- end
		
		--self:Log(1, "!")
		
		-- self:ProcessCaptureData();

		
	
		if (self.quenedMsg) then
			--self:Log(1, _time - self.quenedMsg.time .. ">="..self.quenedMsg.toSendTime)
			if (_time - self.quenedMsg.time >= self.quenedMsg.toSendTime) then -- even a bot has to type in a chat message
				self:ProcessMsg();
			end
		end
	
	
		self:ProcessTest();
	
		if (Bot:GetCurrentItem() and Bot:GetCurrentItem().class == "DebugGun") then
		--	self:PressKey('attack1', 0)
		end
	
		-- if (self.jump_time) then
			-- if (_time - self.jump_time >= 0.3) then
				-- g_localActor.actor:SimulateInput('jump', 2, 0);
				-- self.jump_time = nil;
			-- end
		-- end
		
		if (self.LAST_JUMP_TIMER and timerexpired(self.LAST_JUMP_TIMER, 0.35)) then
			g_localActor.actor:SimulateInput('jump', 2, 0)
			self.LAST_JUMP_TIMER = nil
		end
		
		if (self._proneTime) then
			if (_time - self._proneTime >= self._proneTimer) then
				self:StopProne();
			end
		elseif (g_localActor.actorStats.stance == 2 and (not self.lastStopProne or _time - self.lastStopProne >= 0.1)) then
		--	self:Log(0, "STOp prone, time and statnce")
			self:StopProne(true);
		end
		
		
		for i, keyData in pairs(self.PressedKeys or{}) do
			if (keyData.releaseTime ~= -1 and _time - keyData.pressTime >= keyData.releaseTime) then
				self:ReleaseKey(i);
			end
		end
		
		-- if (not self._posData and not EXPERIMENTAL_AI_FOLLOWING) then
			-- self:ProcessAIPathLearning();
		-- end
		
		
		
		
	--	self:ProcessLearnArtificialWallJumping(); -- you can uncomment if you want
		
		
		if (not bot_enabled) then
			return false;
		end
		
		
		self:Log(2, '------------------------- NEW FRAME: ' .. deltaTime);

	
		for i, player in pairs(self.BIND_PLAYERS or{}) do
			if (not player[2] or self:AliveCheck(System.GetEntity(i))) then
				System.GetEntity(i):SetPos(player[1])
			else
				self.BIND_PLAYERS[i] = nil;
			end
		end


		if (not self:ProcessUpdate()) then
			self:Log(2, "ProcessUpdate=False")
			return false;
		end
		
		for i, player in ipairs(g_gameRules.game:GetPlayers()or{}) do
			if (self:AliveCheck(player)) then
				if (player.inventory:GetCurrentItem() and player.inventory:GetCurrentItem() ~= "Fists") then
					player._lastItem = player.inventory:GetCurrentItem();
				else
					player._lastItem = nil;
				end
			end
			
		end
		
		--if (self.nextMovDataKeyname) then
		--	g_localActor.actor:SimulateInput(self.nextMovDataKeyname, 1, 1);
		--end
		
		local hCurrent = Bot:GetCurrentItem();
		self.isBoxing = hCurrent and (hCurrent.class == "Fists");-- or hCurrent.class == "OffHand")
		if (hCurrent and hCurrent.class=="OffHand") then
			--00self:Log(0, 'fixed :D')
			g_localActor.actor:SimulateInput('grenade',1,1);
		end
		--self:Log(0, hCurrent.class)
		
		
		if (not CheckEntity(self.CURRENT_ACTIVE_THREAT)) then
			if (hCurrent and hCurrent.class ~= "Fists" and hCurrent.weapon and hCurrent.weapon:IsZoomed()) then
				self:Log(3, "LOCAL ACTOR STATNCE: " .. g_localActor.actorStats.stance)
				if (g_localActor.actorStats.stance == 0 or (not self.temp._aimEntityId or not self:AliveCheck(System.GetEntity(self.temp._aimEntityId)))) then
					
						g_localActor.actor:SimulateInput('zoom', 1, 1);
						self._ZOOMING = false;
						self:Log(1, "NO ZOOM!")
						self:StopAim()
					
				end
			end
		end
		
		if (self.forceReloading) then
			if (not hCurrent or (hCurrent.class ~= self.forceReloading[2]) or (_time - self.forceReloading[1] >= 5)) then
				self.forceReloading = nil;
				self:Log(1, 'force reloading is done')
			end
		end
		
		local MOVEMENT_INTERRUPTED = false;
		
		if (self:ProcessCheckGoodGun()) then
			MOVEMENT_INTERRUPTED=true;
		end
		
		if (not self.firing and not self:HasTarget()) then
			self:ProcessModify()
		end
		
		if (Bot:GetCurrentItem() and Bot:GetCurrentItem().weapon and Bot:GetCurrentItem().weapon:IsModifying()) then
			_modifyTime = (_modifyTime or 0) + System.GetFrameTime();
			if (_modifyTime >= 3) then
			--self:Log(0, "MOD!!");
				self._lastMod=nil;
				g_localActor.actor:SimulateInput('modify', 2, 0);
				Script.SetTimer(100, function()
				--g_localActor.actor:SimulateInput('modify', 2, 0);
				
				end);
				_modifyTime=0
			end
		else
			_modifyTime=0
			--g_localActor.actor:SimulateInput('modify', 2, 0);
		end
		
		if (self._equiping) then
		--	MOVEMENT_INTERRUPTED=true
		end
		
		if (self.followTarget and (not System.GetEntity(self.followTarget.id) or not self:AliveCheck(self.followTarget))) then
			if (not self:CheckNextVisiblePathNode()) then
				local found = false;
				if (Config.BotSmartFollow) then
					if (not self.ORIGINAL_FOLLOW_TARGET) then
						self.ORIGINAL_FOLLOW_TARGET = self.followTarget;
					end
					if (self:GetNextFollowTarget()) then
						self:Log(0, "[SMARTFOLLOW] New target: " .. self.followTarget:GetName() .. " ORIGINAL: " .. self.ORIGINAL_FOLLOW_TARGET:GetName())
						found = true;
					end
				end
				if (not found) then
					if (not self.autoFollowMode or not self:GetNextFollowTarget()) then
						self:Kill();
					end
				end
			end
			
			self.putBackInFollowMode = self.followTarget;
			
			self:ResetFollowTarget();
		end
		
		if (not self._PickingUpGun and not MOVEMENT_INTERRUPTED) then-- and not self._queneAttachAccessories) then
		
			self:ProcessFollowAI()
			self:ProcessMovement()
		end
		
		if (not self.temp._aimEntityId) then
			if (old_aim_maxDistance) then
				aim_maxDistance = old_aim_maxDistance;
				old_aim_maxDistance = nil;
			end
			if (self:GetCurrentItem() and self:GetCurrentItem().selectedBecauseSniping and timerexpired(self.LAST_RELOAD_TIMER, 3)) then --(not self.lastReload or (_time - self.lastReload >= 3))) then
				self:GetCurrentItem().selectedBecauseSniping = false;
			end
		end
		
		for i, player in ipairs(g_gameRules.game:GetPlayers() or {}) do
			if (player.id ~= g_localActor.id) then
				if (player.lastPos) then
					if (self:GetDistance(player, player.lastPos) < 0.01) then
						player.stuckTime = (player.stuckTime or 0) + System.GetFrameTime();
					else
						player.stuckTime = 0;
					end
				--	self:Log(0, "StuckTime: %f", player.stuckTime)
				end
				if (not player.lastPosTime or _time - player.lastPosTime >= 0) then
					if (player.lastPos) then
					--	self:Log(0, Vec2Str(player.lastPos))
					--	self:Log(0, Vec2Str(player:GetPos()))
					--	self:Log(0, "Player distance: %s, %f < %f", player:GetName(), self:GetDistance(player, player.lastPos), 0.01)
					end
					player.lastPos = player:GetPos();
					player.lastPosTime = _time;
				end
			end
			if (self.recordJump[player.id]) then
				player.lastJumpData_ = player.lastJumpData_ or {
					time = _time;
					jumpStart = player:GetPos();
				}
				if (_time - player.lastJumpData_.time >= 0.1) then
					if (not player.actor:IsFlying()) then
						player.lastJumpData_.jumpEnd = player:GetPos();
						self.recordJump[player.id] = false;
						player.lastJumpData = player.lastJumpData_;
						player.lastJumpData_ = nil;
					--	self:Log(0, "Recording complete")
					end
				end
			end
			if (not player.recordedPath) then
				player.recordedPath={[1]=player:GetPos()};
			end
			if (self:GetDistance(player.recordedPath[#player.recordedPath])>0.2) then
				player.recordedPath[#player.recordedPath+1]=player:GetPos();
			end
			if (#player.recordedPath>=100) then
				table.remove(player.recordedPath,1)
			end
		end
			if (ZOMBIE_MODE or BOXER_MODE) then
				if (hCurrent and hCurrent.class ~= "Fists") then
					--	g_localActor.actor:Se
						g_localActor.actor:SelectItemByName("Fists");
						
				end
				--return
			end
		
		if (bot_hostility) then
			self:ProcessTarget();
		else
			self:ProcessPathfinding()
			self:CheckForBetterGun()
		end
		--self.lastActorPos = g_localActor:GetWorldPos();
		self:SetLastPos();
	end,
	---------------------------
	GetNextFollowTarget = function(self)
		for i, player in pairs(g_gameRules.game:GetPlayers()or{}) do
			if (self:AliveCheck(player) and self:CanSeePos_Check(player:GetPos(), true)) then
				self:ResetFollowTarget();
				self:SetFollowTarget(player);
				return true;
			end
		end
	end,
	---------------------------
	IsPlayerIdle = function(self, player)
		return (player.stuckTime and player.stuckTime>= 1);
	end,
	---------------------------
	GetDistanceAbove = function(self, player1, player2)
		local z1, z2 = (player1.id and player1:GetPos().z or player1.z), (player2.id and player2:GetPos().z or player2.z);
		if (z1 and z2) then
			return z2 - z1;
		end
		return
	end,
	---------------------------
	CopyJump = function(self, targetPos)
		if (g_localActor.actor:GetNanoSuitEnergy() > 50) then
		--	self:Log(0, "Copy now")
			self:InvokeJump()
			g_localActor.actor:SetNanoSuitMode(1)
			self:StartMoving(1, targetPos, true);
			--[[if (self:GetDistance(data.jumpStart) < 1.8 or (self._nosuitchangeTime and _time - self._nosuitchangeTime < 1)) then
				self._nosuitchangeTime = _time
				self:Log(0, "COPY!")
				self:SuitMode(2);
				self:InvokeJump();
				self:StartMoving(1, data.jumpEnd, false);
			else
				self:StartMoving(1, data.jumpStart, true);
				self:Log(0, " MOVE FOR COPY .. %f!", self:GetDistance(data.jumpStart))
			end--]]
		end
	end,
	---------------------------
	ProcessFollowAI = function(self)
		local config = self.followConfig;
		if (bot_followSystem) then
			if (self.followTarget and (not bot_hostility or (not self:HasTarget() and not self.temp._aimEntityId))) then
				local followPos = self.followTarget:GetPos(); 
				local canSee = self:CanSeePos_Check(followPos, true, self.followTarget.id);
				local vehicle, seat, seatInfo;
				if (self.followTarget.actor:GetLinkedVehicleId() and BOT_FOLLOWER_USE_VEHICLES) then
					vehicle = System.GetEntity(self.followTarget.actor:GetLinkedVehicleId());
					if (vehicle) then
						seatInfo = self:GetFreeVehicleSeat(vehicle);
						if (seatInfo) then
							seat = seatInfo[1];
						end
					end
				elseif (self.preferredVehicle) then
					self:StopGotoVehicle();
				end
				if (g_localActor.actor:GetLinkedVehicleId() and (not vehicle or (vehicle and vehicle.id ~= g_localActor.actor:GetLinkedVehicleId()))) then
					self:LeaveVehicle();
				end
				local closeDist = self.followConfig.NearDistance;
				if (self.followConfig.NearDistanceRandom) then
					local rndDist = self.rndDist or math.random(2, 4); --math.random(1, 3);
					if (not self.lastRndDist or _time - self.lastRndDist >= 0.3) then
						self.lastRndDist = _time;
						rndDist = math.random(4, 5);
					end
					self.rndDist = rndDist;
					closeDist = self.rndDist;
				end
				--self:SendMsg("C + " .. closeDist)
				if (self:GetDistance(followPos) < self.followConfig.LooseDistance and ((vehicle and seat) or (self:GetDistance(followPos) > closeDist)) and not g_localActor.actor:GetLinkedVehicleId()) then
					if (vehicle and seat) then
						self.vehicleMinDistance = 100;
						self.ignoreDriver = true;
						self.preferredVehicle = vehicle.id;
						self.followTargetSpot = true;
						self.preferredVehicle_SeatPos = seatInfo[2];
						self.preferredVehicle_SeatHLP = seatInfo[2];
						self.preferredVehicle_SeatDir = seatInfo[4];
						self.enterSeatId = seat
						self.seatEnterId = seat
						if (self:GetDistance(preferredVehicle_SeatPos) < 8) then
							self:Log(0, "enter now!");
							self:StartEnterVehicle(vehicle)
							--vehicle.vehicle:OnUsed(g_localActorId,
							self:StopGotoVehicle();
						end
						--self:Log(0, "?!?!?")
					else
						local doJump = true;
						if (canSee and not self.unstuckMov and not self.runningFromNade) then
							local dir = self:GetDirectionVector(self:Copy(followPos), self:Copy(g_localActor:GetPos()), true);
							
							local followStuck = self:IsPlayerIdle(self.followTarget) and self:GetDistanceAbove(g_localActor, self.followTarget) > 1.5;
							
							if (not followStuck) then
								followPos.x = followPos.x - dir.x * 2;--/10;
								followPos.y = followPos.y - dir.y * 2;--/10;
								followPos.z = followPos.z - dir.z * 2;--/10;
									
								--self:SendMsg(tostring(rndDist))
								
								followPos.z = self.followTarget:GetBonePos("Bip01 head").z - 0.5;
								self:StartMoving(1, followPos, true);
								self.followingPlayer = true;
								self.followTargetSpot = true;
							--	self:SendMsg("FOLLOW POS!!!")
							--	self:Log(0, "GOTO FOLLOW TARGET!")
							
								self.followingPath = false;
							
							elseif (self:GetDistanceAbove(g_localActor, self.followTarget) < 3) then
								doJump = true;
							else
								self:Log(0, "He is standing idle %f", self:GetDistanceAbove(g_localActor, self.followTarget));
							end
						elseif (self:CanSeePosition_Advanced({x=g_localActor:GetPos().x,y=g_localActor:GetPos().x,z=g_localActor:GetPos().z+3}, followPos, self.followTarget.id) and self:GetDistance(followPos) < 15) then
						--	self:Log(0, "!!!")
							doJump = true;
						else
							if (self.followTarget.recordedPath) then
								self:FollowPath(self.followTarget.recordedPath);
							else
								
								if (ResetPathOnFollowerLoose) then
									self:ProcessPath(); --self:ResetPath() -- findme 17/04
								end
							end
						end
						--self:Log(0, "%f", self:GetDistanceAbove(g_localActor, self.followTarget))
						if (doJump and self:GetDistanceAbove(g_localActor, self.followTarget) < 4 and self:GetDistanceAbove(g_localActor, self.followTarget) > 0.5 and not self.followTarget.actor:IsFlying()) then
							self:CopyJump(followPos);
						end
					end
				else
					local followStats = self.followTarget.actorStats; -- 2 = prone, 1 = crouch, 0 = stand
					if (config.FunnyBehavior) then
						if (followStats.stance == 2) then
							self.followTarget._prone = true;
							self.followTarget._proneTime = _time;
						elseif (followStats.stance == 0) then
							if (self.followTarget._proneTime and _time - self.followTarget._proneTime < 1.5) then
								self.followTarget.proneSpam = (self.followTarget.proneSpam or 0) + 1;
								self.followTarget._proneTime = nil;
								self.followTarget.proneSpamLast = _time;
								--self:Log(0, "Prone spam: " .. self.followTarget.proneSpam)
							end
						end
						
					
						if (self.followTarget._jumpTime and _time - self.followTarget._jumpTime < 3) then
							if (not self.followTarget.lastJumpPos or self:GetDistance(self.followTarget.lastJumpPos, self.followTarget:GetPos()) < 1) then
								self.followTarget.lastJumpPos = self.followTarget:GetPos();
								self.followTarget.jumpSpam = (self.followTarget.jumpSpam or 0) + 1;
								self.followTarget._jumpTime = nil;
								self.followTarget._jumpTime_ = _time;
							else
								self.followTarget.lastJumpPos=nil;
								self.followTarget.jumpSpam=0
							end
							--self.followTarget.proneSpamLast = _time;
							--self:Log(0, "Prone spam: " .. self.followTarget.proneSpam)
						elseif (self.followTarget._jumpTime_ and _time - self.followTarget._jumpTime_ >2 ) then
							self.followTarget.jumpSpam = 0;
						end
						
						--	self:SendMsg("spam ;p " .. tostring(self.followTarget.jumpSpam));
						if (self.followTarget.jumpSpam and self.followTarget.jumpSpam >= 3) then
							if (not self.lastFunnyJump or _time - self.lastFunnyJump >= 1) then
								self:InvokeJump();
								self.lastFunnyJump = _time;
							end
						end
						
						if (self.followTarget.proneSpamLast and _time - self.followTarget.proneSpamLast >= 1.5) then
							self.followTarget.proneSpam = 0;
						end
						if (self.followTarget.proneSpam and self.followTarget.proneSpam >= 3) then
							if (not self:HasTarget() and not self.temp._aimEntityId and not self.preferredVehicle) then
								if (not self._proneTime) then
									self:StopProne();
								end
								
								if (not self.lastFunnyProne or _time - self.lastFunnyProne >= 0.1) then
									self:Prone(math.random(10, 25) / 100);
									self.lastFunnyProne = _time;
								end
								
								if ((not self.lastSpamProneMov or _time - self.lastSpamProneMov >= 0.3)) then
									if (math.random(6) == 2) then
										local posToSide = g_localActor:GetPos();
										local dirToSide = g_localActor.actor:GetHeadDir();
										VecRotate90_Z(dirToSide);
										
										local _rndDir = math.random(2, 3);
										
										posToSide.x = posToSide.x + dirToSide.x * (_rndDir == 2 and 2 or -2);
										posToSide.y = posToSide.y + dirToSide.y * (_rndDir == 2 and 2 or -2);
										posToSide.z = posToSide.z + dirToSide.z * (_rndDir == 2 and 2 or -2);
										
										self:StartMoving(_rndDir, posToSide);
										self.noCamMove = true;
										
										self.lastSpamProneMov = _time
									end
								end
							end
						end
					end
					
					
					
					if (not self.followTarget.proneSpam or self.followTarget.proneSpam < 1) then
						if (followStats.stance == 2) then
							self.followTargetData.proneTime = (self.followTargetData.proneTime or 0) + System.GetFrameTime();
						else
							self.followTargetData.proneTime = 0;
						end
						if (self.followTargetData.proneTime >= 3) then
							self:Prone();
						else
							self:StopProne();
						end
					end
					
					self:StopMovement();
					
					local lookAtPos = (self.followTarget.actor and self.followTarget.actor:GetHeadPos() or followPos);
					local noCamMove = false;
					
					if (self:GetDistance(followPos) < 1.3) then
					--	self:Log(0, "Very close :/")
					--	if (nadepos) then
						--self:SendMsg("GRENADE!");
						noCamMove = true;
					--	local followingPlayer = false;
					--	local runawayDir = self:GetDirectionVector(g_localActor:GetPos(), self:Copy(nadepos), true);
						--[[if (self.followingPlayer) then
							runawayDir = self:GetDirectionVector(g_localActor:GetPos(), self:Copy(self.followTargetShotInfo[2]), true, -1);
							followingPlayer = true;
						end--]]
						--self:SendMsg("Running from nade")
						--self:Log(0, "Running from nade");
						self:StopMovement()
						self:StartMoving(4, self:GetPosBehind(2), self:GetDirectionVector(g_localActor:GetPos(), self:Copy(followPos), true));
						--self.noCamMove = true;
						--self.runningFromNade = true;
					end
					
					if (self.followTargetShotInfo and _time - self.followTargetShotInfo[3] < 3) then
					
						lookAtPos = self.followTargetShotInfo[2];
						local nadepos, safeDist = self:IsNadeNear();
						
						if (nadepos) then
						--	self:SendMsg("GRENADE!");
							noCamMove = true;
							local followingPlayer = false;
							local runawayDir = self:GetDirectionVector(g_localActor:GetPos(), self:Copy(nadepos), true);
							--[[if (self.followingPlayer) then
								runawayDir = self:GetDirectionVector(g_localActor:GetPos(), self:Copy(self.followTargetShotInfo[2]), true, -1);
								followingPlayer = true;
							end--]]
							--self:SendMsg("Running from nade")
							--self:Log(0, "Running from nade");
							self:StartMoving(4, self:GetPosBehind((safeDist or 6), runawayDir));
						--	self.noCamMove = true;
							
							self.runningFromNade = true;
						else
							local targets, target, allTargets = self:TargetNearPos(lookAtPos);
							if (not target) then
								if (not self.followTargetData.confusedMsg or _time - self.followTargetData.confusedMsg.time >= 360) then
									self.followTargetData.confusedMsg = {
										time = _time;
									};
									local msg = self:GetRandomMsg(self.msgs.follower.confused);
									self:SendMsg(msg);
								else
									self.followTargetData.doRandomShooting = self.followTargetData.doRandomShooting or { math.random(6) == 2, _time };
									if (_time - self.followTargetData.doRandomShooting[2] >= 3) then
										self.followTargetData.doRandomShooting = { math.random(6) == 2, _time }
										--self:SendMsg("RE RANDOM == " .. tostring(self.followTargetData.doRandomShooting[1]))
									end
									if (self.followTargetData.doRandomShooting[1]) then
										if (not self.followTargetData.funShooting or _time - self.followTargetData.funShooting >= 0.1) then
											self.followTargetData.funShooting = _time;
											if (not self.firing) then
												self:PressKey('attack1', math.random(10, 25) / 100);
											end
										end
									end
								end
							else
							--	self:SendMsg("I can see him")
								if (self:ShouldShootAtTarget(target)) then
									self.temp._aimEntityId = target.id;
								else
									self.selectSniper = false;
								--	self:SendMsg("We'd rather not tangle with him right now :)");
								end
							end
						end
					else
						self.selectSniper = false;
					end
					
					self:SetCameraTarget(lookAtPos);
					self.noCamMove = noCamMove;
					self.followTargetSpot = true;
				end
				if (canSee and self:GetDistance(followPos) < 20) then
					local followSuit = self.followTarget.actor:GetNanoSuitMode();
					--self:SendMsg("Suit mode" .. followSuit .. ", = " .. self.suitModes[followSuit])
					if (config.NanoSuit[self.suitModes[followSuit]] and g_localActor.actor:GetNanoSuitMode() ~= followSuit) then
						self.copiedSuit = followSuit;
						self:SuitMode(followSuit);
					end
					if (config.CopyCurrentGun) then
						local followGun = self.followTarget.inventory:GetCurrentItem();
						if (followGun and g_localActor.inventory:GetItemByClass(followGun.class) and curr and curr.class ~= followGun.class and self:CheckAmmo(curr, 5) and followGun.class ~= "Fists") then
							if (not self.followTargetData.currGun or self.followTargetData.currGun ~= followGun.class) then
								self.followTargetData.currGun = followGun.class;
								self.followTargetData.hasGunTime = nil;
							end
							if (self.followTargetData.currGun == followGun.class) then
								self.followTargetData.hasGunTime = self.followTargetData.hasGunTime or _time;
							end
							if (_time - self.followTargetData.hasGunTime >= (followGun.class == "Fists" and 1 or 1.8) and not self:GetCurrentItem().selectedBecauseAmmo and not self:GetCurrentItem().selectedBecauseSniping) then
								g_localActor.actor:SelectItemByName(followGun.class);
								self.followTargetData.copiedGunClass = followGun.class;
							end
						end
					end
				end
			else
				
				self.selectSniper = false;
				self.followTargetSpot = false;
			end
		end
	end,
	---------------------------
	FollowPath = function(self, pathData)
		if (not pathData) then
			if (ResetPathOnFollowerLoose) then
				self:ProcessPath(); --self:ResetPath() -- findme 17/04
			end
			return
		end
		if (not self.followPath) then
			self.followPath=pathData;
			self.followPathCurrSpot = 1;
		end
		if (self.followPathCurrSpot > #pathData) then
			if (ResetPathOnFollowerLoose) then
				self:ProcessPath(); --self:ResetPath() -- findme 17/04
			end
			return
		end
		local nextPos = self.followPath[self.followPathCurrSpot];
		if (self:GetDistance(nextPos) < 0.3) then
			self.followPathCurrSpot=self.followPathCurrSpot+1;
			return self:FollowPath();
		end
		--self:Log(0, Vec2Str(nextPos))
		if (self:CanSeePos_Check(nextPos, true)) then
			self:StartMoving(1, nextPos, true);
		else
		--	return self:ProcessPath();
		end
	end,
	---------------------------
	StopFollowPath = function(self, pathData)
		self.followPath=nil;
	end,
	---------------------------
	ProcessGruntAI = function(self)
		if (self.followTarget and self:Exists(self.followTarget.id) and bot_followSystem) then
			self:Log(0, "Follow System and Grunt mode are not compatible, disabling Grunt mode!");
			self.gruntMode = false;
			return false;
		end
		self:CheckGruntCVars();
	end,
	---------------------------
	CheckGruntCVars = function(self)
		if (self.gruntMode) then
			if (aim_maxDistance > 60) then
				aim_maxDistance = 60;
			end
			BOT_AIM_ACCURACY = 40;
			self.boxRun = false;
		end
	end,
	---------------------------
	ShouldShootAtTarget = function(self, target)
	
		if (not self:CanSetAsTarget(target)) then
			return
		end
	
		local pos = target:GetPos();
		local snipers = {
			['GaussRifle'] = true,
			['DSG1'] = true
		};
		local curr = self:GetCurrentItem();
		
		--self:SendMsg(tostring(self:CanSeePos_Check(pos, true, target.id)))
		
		if (self:GetDistance(target) < 70 and self:GetDistance(target) < 13 and self:CanSeePosition(pos, target.id)) then
			--if (self:GetDistance(target) < 13) then
				self:Log(0,"SHOOT!!")
				local SHOPT=g_localActor.inventory:GetItemByClass("Shotgun");
				if (SHOPT and SHOPT.weapon:GetAmmoCount()>0 and curr.class~="Shotgun") then
					SHOPT=System.GetEntity(SHOPT);
					SHOPT.selectedBecauseSniping=true;
					g_localActor.actor:SelectItemByName(SHOPT.class);
				elseif (curr.class=="Shotgun") then
					self:SelectNewItem()
				end
			--end
			return true;
		elseif (self:GetDistance(target) > 70 and self:CanSeePos_Check(pos, true, target.id) and curr) then
			if (curr and not snipers[curr.class]) then
				local gun;
				if (g_localActor.inventory:GetItemByClass('GaussRifle')) then
					gun = System.GetEntity(g_localActor.inventory:GetItemByClass('GaussRifle'));
					gun.selectedBecauseSniping = true;
					if (not old_aim_maxDistance) then
						old_aim_maxDistance = aim_maxDistance
						aim_maxDistance = self:GetDistance(target);
					end
					g_localActor.actor:SelectItemByName(gun.class);
				elseif (g_localActor.inventory:GetItemByClass('DSG1')) then
					gun = System.GetEntity(g_localActor.inventory:GetItemByClass('DSG1'));
					gun.selectedBecauseSniping = true;
					if (not old_aim_maxDistance) then
						old_aim_maxDistance = aim_maxDistance
						aim_maxDistance = self:GetDistance(target);
					end
					g_localActor.actor:SelectItemByName(gun.class);
				else
					return false;
				end
				return true;
			elseif (curr and snipers[curr.class]) then
				return true;
			end
		end
	end,
	---------------------------
	GetCurrentItem = function(self)
		return self.actorItem ; -- return string so it shows error for debugging
	end,
	---------------------------
	TargetNearPos = function(self, pos)
		if (self:GetDistance(pos) > 300) then
			return
		end
		return self:PlayersNear(30, pos);
	end,
	---------------------------
	CheckAmmo = function(self, gun, l)
		--self:Log(0,gun.weapon:GetAmmoType())
		return (gun.class ~= "Fists" and gun.weapon:GetAmmoType() ~= nil) and g_localActor.actor:GetInventoryAmmo(gun.weapon:GetAmmoType()) >= (l or 10) or true;
	end,
	---------------------------
	CheckForcedAccessories = function(self)
	
		----------
		-- if (g_gameRules.class ~= "InstantAction") then
			-- return end
			
		----------
		local hCurrent = self:GetCurrentItem()
		if (not hCurrent) then
			return end
	
		----------
		local bForce = (self.FORCE_ATTACH_ACCESSORIES and (self.FORCE_ATTACH_ENTITYID == hCurrent.id))
	
		----------
		self:Log(5, "%sCheck forced !!", (bForce and "$4FORCED:" or ""))
			
		----------
		if (hCurrent.id == self.LAST_ACCESSORY_GUN_ID and not timerexpired(self.LAST_ACCESSORY_TIMER, 1)) then
			return end
	
		----------
		local aForced = {
		
			----------
			{ sClass = "SCAR", this = "Reflex", nott = "SniperScope" },
			{ sClass = "SCAR", this = "LAMRifle", nott = "LAMRifle" },
		
			----------
			{ sClass = "Shotgun", this = "Reflex", nott = "SniperScope" },
			{ sClass = "Shotgun", this = "LAMRifle", nott = "LAMRifle" },
				
			----------
			{ sClass = "SMG", this = "Reflex", nott = "SniperScope" },
			{ sClass = "SMG", this = "LAMRifle", nott = "LAMRifle" },
				
			----------
			{ sClass = "DSG1", this = "Reflex", nott = "SniperScope" },
			{ sClass = "DSG1", this = "LAMRifle", nott = "LAMRifle" },
				
			----------
			{ sClass = "GaussRifle", this = "Reflex", nott = "SniperScope" },
			{ sClass = "GaussRifle", this = "LAMRifle", nott = "LAMRifle" },
				
			----------
			{ sClass = "FY71", this = "Reflex", nott = "SniperScope" },
			{ sClass = "FY71", this = "LAMRifle", nott = "LAMRifle" },
			-- { sClass = "FY71", this = "FY71IncendiaryAmmo", nott = "FY71IncendiaryAmmo", elsee = "FY71NormalAmmo", bOk = function(w) return ((g_localActor.actor:GetInventoryAmmo("incendiarybullet") + w.weapon:GetAmmoCount()) >= 1) end },
			
			----------
			-- ["LAW"] = { this = "LAMRifle", nott = "LAMRifle" },
		}
		
		----------
		local wClass = hCurrent.class
		for i, aForce in pairs(aForced) do
			local sClass = aForce.sClass
			if (wClass == sClass) then
				self:Log(3, "%s == %s", sClass, (bForce and "FORCE" or "NORMAL"))
				if (bForce or (not hCurrent.weapon:GetAccessory(aForce.this) and not hCurrent.weapon:GetAccessory(aForce.nott))) then
					if (bForce) then
						self:Log(3, "DETAHCED!")
						hCurrent.weapon:AttachAccessory(aForce.this, false, true) end
						
					hCurrent.weapon:AttachAccessory(aForce.this, true, true)
					-- hCurrent.weapon:SwitchAccessory(aForce.this);
					-- if (aForce.this == "LAMRifle") then
						-- hCurrent.weapon:ActivateLamLight(false)
						-- hCurrent.weapon:ActivateLamLaser(true) end
						
					self:Log(3, "$4 ATTACHED %s FOR %s", aForce.this, sClass)
				end
			end
		end
		
		----------
		if (bForce) then
			self.FORCE_ATTACH_ACCESSORIES = false end
		
		----------
		self.LAST_ACCESSORY_TIMER = timerinit()
		self.LAST_ACCESSORY_GUN_ID = hCurrent.id
	end,
	---------------------------
	ProcessModify = function(self)
		
		----------
		if (not BOT_USE_ATTACHMENTS) then 
			return end
	
		----------
		self:CheckForcedAccessories()
	
		----------
		--[[
		local hCurrent = Bot:GetCurrentItem();
		if ((self._queneAttachAccessories or self._attachAccessories) and not self:RequiresNewGun()) then
			--MOVEMENT_INTERRUPTED=true -- bad idea :D
			
				if (hCurrent) then
					self._queneAttachAccessories = false;
					self._attachAccessories = false;
					if (hCurrent.weapon:GetAccessory("Silencer") and hCurrent.weapon:GetAccessory("LAMRifle")) then -- for now bot does not care about zooming
						return
					end
						
					Script.SetTimer(500,function()
						if (not Bot:GetCurrentItem().weapon:IsModifying()) then
						--	g_localActor.actor:SimulateInput('modify', 1, 1);
						end
						self._lastMod = _time;
						self._lastModGun = hCurrent.id;
						
						
						if (g_localActor.inventory:GetItemByClass("LAMRifle") and not hCurrent.weapon:GetAccessory("LAMRifle")) then
							hCurrent.weapon:SwitchAccessory("LAMRifle");
							self:Log(1, "$32ATATCHING!!!")
						end
						if (g_localActor.inventory:GetItemByClass("Silencer") and not hCurrent.weapon:GetAccessory("Silencer")) then
							hCurrent.weapon:SwitchAccessory("Silencer");
							self:Log(1, "$411ATATCHING!!!")
						end
						Script.SetTimer(200, function()
							--MOVEMENT_INTERRUPTED=false;
							self._equiping = false;
							--self:PressKey('modify', 0);
							hCurrent.weapon:ModifyCommit()
							Script.SetTimer(300, function()
							--self:PressKey('modify', 0);
							
							end);
						end);
					end);
				end
		elseif (hCurrent and hCurrent.class ~= "Fists") then
			local attach = false;
			
			if (g_localActor.inventory:GetItemByClass("LAMRifle") and not hCurrent.weapon:GetAccessory("LAMRifle") and hCurrent.weapon:SupportsAccessory("LAMRifle")) then
				attach = true;
			end
			
			if (g_localActor.inventory:GetItemByClass("Silencer") and not hCurrent.weapon:GetAccessory("Silencer") and hCurrent.weapon:SupportsAccessory("Silencer")) then
				attach = true;
			end
			if (attach) then
			--	self:SendMsg("Attach!!");
				self._attachAccessories = true;
			else
				self._attachAccessories = false;
			end
		--	self:Log(0, "Needs it: " .. tostring(attach))
		else
			self._attachAccessories = false;
		end
		--]]
	end,
	---------------------------
	HasItem = function(self, sClass)
		return g_localActor.inventory:GetItemByClass(sClass)
	end,
	---------------------------
	SelectItem = function(self, sClass)
		local hCurrent = self:GetCurrentItem()
		if (hCurrent and hCurrent.class == sClass) then
			return end
			
		self.LAST_RELOAD_TIMER = nil
		
		return g_localActor.actor:SelectItemByName(sClass)
	end,
	---------------------------
	GetInventoryAmmo = function(self, sAmmoType)
	
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
	end,
	---------------------------
	ProcessCheckGoodGun = function(self)
	
		---------------
		if (not BOT_PICKUP_ITEMS) then 
			return end
			
		---------------
		if (ZOMBIE_MODE) then
			return end
	
		---------------
		local bNeedsNewItem = self:RequiresNewGun()
		local hGun, vGun, iDist, bIsGucci = self:PickableWeaponAvailable(10)
		self:Log(3, "Requires new gun: %s (gucci: %s) (hgun: %s, vGun: %s, iDist: %f)", (bNeedsNewItem and "yes" or "no"), tostring(bIsGucci), tostring(hGun), tostring(vGun), (iDist or 0))
		if (vGun and (bIsGucci or bNeedsNewItem or not self:ItemCategoryStockFull(vGun.class)) and (not self._lastPickup or _time - self._lastPickup >= 0)) then
			self:GoGetGun(hGun); -- go get it daddy
		else
			self._PickingUpGun = false
			self._queneAttachAccessories = false
		end
		
		---------------
		local vPos = g_localActor:GetPos()
		local hCurrentItem = Bot:GetCurrentItem()
		if (self.movingToMyGUN and CheckEntity(self.IWantThis) and not self.FORCE_ATTACH_ACCESSORIES) then
			local hThisGun = GetEntity(self.IWantThis)
			local iDistance = vector.distance(vPos, hThisGun:GetPos())
			
			---------------
			self:SuitMode((iDistance > 15 and NANOMODE_SPEED or NANOMODE_DEFENSE))
			
			---------------
			local sClass = hThisGun.class
			if (self:HasItem(sClass) and self:GetInventoryAmmo(hThisGun.weapon:GetAmmoType()) < 30) then
				self:SelectItem(sClass)
				if (hCurrentItem and (hCurrentItem.class == sClass and hThisGun.id ~= hCurrentItem.id)) then
					self:PressKey("drop", 0) end end
			
			---------------
			local vGunPos = hThisGun:GetPos()
			self:Log(3, "My Gun: %s %f %s", hThisGun:GetName(), iDistance, Vec2Str(vGunPos))
			if (not self._PickingUpGun) then
				self.lastSeenMoving = false
				self:StartMoving(1, vGunPos, true)
			end
			
			---------------
			local bVisible = 
				iDistance <= 2.0 or
				BotNavigation:IsNodeVisibleEx(vGunPos)
				-- (BotNavigation:IsNodeVisible_Handle(self:GetViewCameraPos(), vector.modify(vGunPos, "z", 0.25, true), "Handle_CanSeePickableGun", 20) or 
				-- BotNavigation:IsNodeVisible_Handle(self:GetViewCameraPos(), vector.modify(vGunPos, "z", 0.5, true), "Handle_CanSeePickableGun", 20) or
				-- BotNavigation:IsNodeVisible_Handle(self:GetViewCameraPos(), vector.modify(vGunPos, "z", 1, true), "Handle_CanSeePickableGun", 20))
				
			if (not bVisible) then
				self:Log(0, "$5Gun unreachable for now!")
				return self:ResetPickupGun()
			end
			
		
			if (iDistance < 2.0) then
				self:Log(0, "$5Take Gun: %s, Gun Distance: %f", tostring(self._STEALMOVE), iDistance)
				self:StopMovement()
				
				if (not self:SpaceInInventory(hThisGun.class)) then
					self:Log(0, "DROP SOME CRAP !!")
					self:DropItem(self:GetWorstItem(g_localActor.actor:GetItemCategory(hThisGun.class)))
				end
				g_localActor.actor:SvRequestPickUpItem(hThisGun.id)
				self:ResetPickupGun()
				self._PickingUpGun = true
				self.FORCE_ATTACH_ACCESSORIES = true
				self.FORCE_ATTACH_ENTITYID = hThisGun.id
				self.WEAPON_PICKUP_TIMER = timerinit()
				
				if ((not self:RequiresNewGun() and not self._STEALMOVE) or (self._STEALMOVE and hCurrentItem and hCurrentItem.class == sClass)) then
					self:ResetPickupGun()
					self._queneAttachAccessories = self._WILLATTACH
					self:Log(0, "$8 2 RESET!!!");
				end
			elseif ((iDistance > 10 or self:FromAbove(vGunPos)) and self.movingToMyGUN) then
				self._STEALMOVE = false
				self:StopMovement()
				self:ResetPickupGun()
				self:Log(0, "$8 1 RESET!!!")
			end
		end
	end,
	---------------------------
	DropItem = function(self, hItem)
	
		----------
		local hItem = hItem
		if (not hItem) then
			hItem = self:GetCurrentItem()
			if (not hItem) then 
				return end
		end
		
		----------
		hItem.DROPPED_TIMER = timerinit()
		
		----------
		return g_localActor.actor:DropItem(hItem.id, 100000, false)
	end,
	---------------------------
	GetScoreByAmmo = function(self, hItem)
		local iAmmo = hItem.weapon:GetAmmoCount()
		local iClip = hItem.weapon:GetClipSize()
		
		return ((iAmmo / (iClip + 1)) * 100)
	end,
	---------------------------
	GetWorstItem = function(self, sCategory)
		
		---------------
		local aItems = g_localActor.inventory:GetInventoryTable()
		
		---------------
		local aWorst = { nil, -1 }
		
		---------------
		for i, idItem in pairs(aItems) do
			local hItem = GetEntity(idItem)
			if (hItem and hItem.weapon and g_localActor.actor:GetItemCategory(hItem.class) == sCategory) then
				local iScore = self:GetScoreByAmmo(hItem)
				if (aWorst[2] == -1 or iScore < aWorst[2]) then
					aWorst = {
						hItem,
						iScore
					}
				end
			end
		end
		
		---------------
		return aWorst[1]
	end,
	---------------------------
	SpaceInInventory = function(self, sClass)
	
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
	end,
	---------------------------
	ResetPickupGun = function(self)
		self._lastPickup = _time
		self.IWantThis = nil
		self.movingToMyGUN = nil
		self._PickingUpGun = false
	end,
	---------------------------
	ProcessLearnArtificialWallJumping = function(self)
		--do return end
		-- self._AIWJ = self._AIWJ or {};
		-- local pos, x, y, z;
		-- if (#self._AIWJ < 15) then -- enough?
			-- for i, player in ipairs(g_gameRules.game:GetPlayers()or{}) do
				-- if (player.id ~= g_localActor.id) then
					-- if (not player:IsDead()) then
						-- if (player.actor:IsFlying()) then
							-- if (not player._aiwjR) then
								-- player._aiwjR = { _lastInsert = _time - 0.06, _wasAAleksJump = false, _flyStartTime = _time, mode = player.actor:GetNanoSuitMode(), start = player:GetPos(), startAngles = player:GetAngles(), flyData = {}, flyData_ang = {}; };
							-- elseif (player._aiwjR) then
								-- if (_time - player._aiwjR._lastInsert >= 0.1) then --.05
																								
									-- pos = player:GetPos();
															
									-- x = self:GetSubNum(pos.x, true);
									-- y = self:GetSubNum(pos.x, true);
									-- z = self:GetSubNum(pos.x, true); -- what is this?
									
									-- pos = { x = x, y = y, z = z };
															
									-- if (not self:InTable(pos, player._aiwjR.flyData) and (player:GetPos().z - player._aiwjR.start.z >= 2 or player:GetPos().z - player._aiwjR.start.z <= -2)) then -- don't want no little speedmode shit jumps
										
										-- pos = player:GetPos();
										
										-- player._aiwjR._lastInsert = _time;
										-- table.insert(player._aiwjR.flyData,  { x = self:GetSubNum(pos.x, true), y = self:GetSubNum(pos.y, true), z = self:GetSubNum(pos.z, true) });
										-- table.insert(player._aiwjR.flyData_ang,  player.actor:GetHeadDir());
										-- self:SendMsg("Z: " .. pos.z - player._aiwjR.start.z .. " : INSERTED POSITION FOR WALLJUMP RECORDING: " .. Vec2Str({ x = self:GetSubNum(pos.x, true), y = self:GetSubNum(pos.y, true), z = self:GetSubNum(pos.z, true) }),true);
									-- end
									-- if (#player._aiwjR.flyData >= 2) then
										-- if (self:GetDistance(player._aiwjR.flyData[1], player._aiwjR.flyData[2]) >= 10 and not player._aiwjR._wasAAleksJump) then -- 10+ meter in 0.1s? only aleks can do that :D
											-- player._aiwjR._wasAAleksJump = true;
										-- end
									-- end
								-- end
							-- end
						-- elseif (player._aiwjR) then
							-- if (player._aiwjR._flyStartTime < 5 and not player._aiwjR._wasAAleksJump) then -- pathetic jump.
								-- player._aiwjR = nil;
							-- else
								-- if (#player._aiwjR.flyData >= 14 or player._aiwjR._wasAAleksJump) then
									-- player._aiwjR.ID = #self._AIWJ+1;
									-- table.insert(self._AIWJ, player._aiwjR);
									-- self:SendMsg("Inserted walljump: " .. _time-player._aiwjR._flyStartTime .. "s, entries " .. #player._aiwjR.flyData, true)
									-- player._aiwjR = nil;
								-- else
									-- self:SendMsg("NOT inserted: " .. #player._aiwjR.flyData)
									-- player._aiwjR = nil;
								-- end
							-- end
						-- end
					-- elseif (player._aiwjR) then
						-- player._aiwjR = nil; -- player DIED during jump, forget the data.
					-- end
				-- end
			-- end
		-- end
	end,
	---------------------------
	FromAbove = function(self, pos, h)
		--if (pos) then
			return pos.z - g_localActor:GetPos().z >= (h or 2.5)
		--else
		--	return self:WithinAngles(killer, -90.0);
		--end
	end,
	---------------------------
	FromBelow = function(self, pos)
		--self:SendMsg(tostring(g_localActor:GetPos().z - pos.z),true)
		return g_localActor:GetPos().z - pos.z >= 2.5
	end,
	---------------------------
	FromBehind = function(self, killer)
		--local dBehind = self:GetPosInFront(pos, -4); -- minus 4 meters behind us
		--local dInFront = self:GetPosInFront(pos, 4); -- minus 4 meters behind us
		
		--self:SendMsg(Vec2Str(self:GetPosInFront(pos, -4)) .. " ;: " .. self:GetDistance(dBehind) ..'<'.. self:GetDistance(dInFront).." "..tostring(self:GetDistance(dBehind) < self:GetDistance(dInFront)),true)
		
		return not self:WithinAngles(killer, 160); --self:GetDistance(dBehind) < self:GetDistance(dInFront);
		
		--local posBehindAbove = { x = posBehind.x, y = posBehind.y, z = posBehind.z + 4 }; -- added to new func with new messages for maximum immersion :D
	end,
	---------------------------
	FromAboveAndBehind = function(self, pos) -- DROPPED
		--local dBehind = self:GetPosInFront(pos, -4); -- minus 4 meters behind us
		--local dBehindAbove = { x = dBehind.x, y = dBehind.y, z = dBehind.z + 4 } -- minus 4 meters behind us
		
		--return self:GetDistance(dBehind) < self:GetDistance(dBehindAbove);
		
		--local posBehindAbove = { x = posBehind.x, y = posBehind.y, z = posBehind.z + 4 }; -- added to new func with new messages for maximum immersion :D
	end,
	---------------------------
	--[[FromAboveAndFront = function(self, pos)
		local dBehind = self:GetPosInFront(pos, -4); -- minus 4 meters behind us
		local dBehindAbove = { x = dBehind.x, y = dBehind.y, z = dBehind.z + 4 } -- minus 4 meters behind us
		
		return self:GetDistance(dBehind) < self:GetDistance(dBehindAbove);
		
		--local posBehindAbove = { x = posBehind.x, y = posBehind.y, z = posBehind.z + 4 }; -- added to new func with new messages for maximum immersion :D
	end--]] -- wtf?
	---------------------------
	NeedsAmmoForGun = function(self, gun)
		return g_localActor.actor:GetInventoryAmmo(gun.weapon:GetAmmoType()) <= 30;
	end,
	---------------------------
	GoGetGun = function(self, hGun) -- go get it daddy
		
		---------------
		if (not hGun) then
			return end
			
		---------------
		if (not CheckEntity(hGun)) then
			return end
			
		---------------
		if (_BLACKLISTED[string.lower(hGun.class)]) then
			return end
			
		---------------
		if (self:IsCarried(hGun.id)) then
			return end
			
		---------------
		if ((g_localActor.inventory:GetItemByClass(hGun.class) and not self:NeedsAmmoForGun(hGun))) then
			return end
	
		---------------
		self:Log(0, "Go get it daddy")
		
		---------------
		self.IWantThis = hGun.id
		self:StartMoving(1, hGun:GetPos(), true)
		
		---------------
		self:ResetLastSeen()
		self:ResetDeathGoto()
		
		---------------
		self._STEALMOVE = false
		self._WILLATTACH = not g_localActor.inventory:GetItemByClass(hGun.class)
		self.movingToMyGUN = true
		self._PickingUpGun = false
		self._queneAttachAccessories = false
	end,
	---------------------------
	IsCarried = function(self, idGun)
	
		local hItem = GetEntity(idGun)
		if (not hItem) then
			return false end
			
		if (not hItem.item) then
			return false end
	
		return (hItem.item:GetOwnerId() ~= NULL_ENTITY)
	end,
	---------------------------
	RequiresNewGun = function(self, megaGucci)
	
		------------------------
		local iMedium = g_localActor.actor:GetItemCountOfCategory("medium")
		local iHeavy = g_localActor.actor:GetItemCountOfCategory("heavy")
		if ((iMedium + iHeavy) >= 2) then
			return false end
	
		------------------------
		local curr = Bot:GetCurrentItem()
		if (not curr) then
			return true end
			
		------------------------
		if (not curr.weapon) then
			return true end
			
		------------------------
		local fists = (curr.class == "Fists")
		if (fists) then
			return true end
			
		------------------------
		local ammo = curr.weapon:GetAmmoCount()
		if (not ammo) then
			return true end
			
		------------------------
		local clip = curr.weapon:GetClipSize()
		if (not clip) then
			return true end
			
		------------------------
		local sAmmoType = curr.weapon:GetAmmoType()
		if (not sAmmoType) then
			return true end
			
		------------------------
		local inventory = g_localActor.inventory:GetAmmoCount(sAmmoType)
		if (not inventory) then
			return true end
			
		------------------------
		if (ammo <= clip / 5 and inventory <= clip / 5) then
			self:Log(0, "LOW AMMO. GO PICK NEW GUN !")
			return true
		end
			
		------------------------
		return false; -- we don't need FISTS
	end,
	---------------------------
	PickableWeaponAvailable = function(self, iRange)
	
		
		------------------------
		local hCurrent = self:GetCurrentItem()
		
		------------------------
		if (self.movingToMyGUN) then
			return false end
		
		------------------------
		local iMaxDistance = tonumber(iRange)
		if (not isNumber(iMaxDistance)) then
			iMaxDistance = 8 end
			
		------------------------
		local aPickable = Config.PickableWeapons
		if (not isArray(aPickable)) then
			aPickable = {} end
			
		------------------------
		local aPickableGucci = Config.PickableGucciWeapons
		if (not isArray(aPickableGucci)) then
			aPickableGucci = {} end
		
		------------------------
		local bNeedsNewItem = self:RequiresNewGun()
		
		------------------------
		local aChoosenGun = { nil, iMaxDistance }
		local aChoosenGucci = { nil, iMaxDistance }
		
		------------------------
		-- local aNearbyEntities = System.GetPhysicalEntitiesInBox(g_localActor:GetPos(), iMaxDistance)
		local aNearbyEntities = GetEntities(GET_ALL, "weapon")
		if (not isArray(aNearbyEntities)) then
			aNearbyEntities = {} end
		
		------------------------
		local vPos = g_localActor:GetPos()
		
		------------------------
		for i, hEntity in pairs(aNearbyEntities) do
			if (hEntity.weapon and hEntity.item and not _BLACKLISTED[string.lower(hEntity.class)]) then
			
				if (aPickable[hEntity.class] == true and timerexpired(hEntity.DROPPED_TIMER, 3)) then
					self:Log(3, "%s : NEEDS THIS: %s", hEntity.class, ((bNeedsNewItem or not self:ItemCategoryStockFull(hEntity.class)) and "yes" or "no"))
					self:Log(3, "	VISIBLE: %s", ((BotNavigation:IsNodeVisibleEx(hEntity:GetPos())) and "yes" or "no"))
					self:Log(3, "	UNDERWATER: %s", ((not self:IsUnderwater(hEntity)) and "ok" or "BAD"))
					local bWorthIt = not self:IsUnderwater(hEntity) and BotNavigation:IsNodeVisibleEx(hEntity:GetPos()) and (bNeedsNewItem or not self:ItemCategoryStockFull(hEntity.class))
					-- if (not bWorthIt) then
						-- bWorthIt = aPickableGucci[hEntity.class] and (self:NeedMegaGucci(hEntity.class) or self:GucciAmmoLow(hEntity.class)) end
					
					if (bWorthIt) then
						local iDistance = vector.distance(hEntity:GetPos(), vPos)
						if (iDistance < aChoosenGun[2]) then
							aChoosenGun = {
								hEntity,
								iDistance
							}
							self:Log(3, "$4>Found item %s", hEntity.class)
						end
						self:Log(3, "CLASS IS WORTH IT !! DIstance: %f \\ %f", iDistance, aChoosenGun[2])
					end
				end
			end
		end
		
		------------------------
		-- if (aChoosenGun[1] == nil) then
			for sClass, bPick in pairs(aPickableGucci) do
				if (not _BLACKLISTED[string.lower(sClass)]) then
				
					for i, hEntity in pairs(System.GetEntitiesByClass(sClass) or {}) do
						local bCanPick = not self:IsCarried(hEntity) and not self:IsUnderwater(hEntity) and self:CanSeePosition(hEntity:GetPos(), hEntity.id) and (self:NeedMegaGucci(hEntity.class) or self:GucciAmmoLow(hEntity.class))
						if (bCanPick) then
							self:Log(0, "$4PICK UP!")
							bCanPick = self:IsItemWorthPickingUp(hEntity)
							self:Log(0, "$4WORTH IT: %s", (bCanPick and "yes" or "no"))
						end
					
						if (bCanPick) then
							local iDistance = vector.distance(hEntity:GetPos(), vPos)
							self:Log(0, "$7Gauss Distance: %f", iDistance)
							if (iDistance < aChoosenGucci[2]) then
								aChoosenGucci = {
									hEntity,
									iDistance
								}
							end
						end
					end
				end
			end
		-- end
		
		------------------------
		if (aChoosenGucci[1]) then
			self:Log(0, "Found  GUCCI  item Worth picking up !")
			return aChoosenGucci[1], aChoosenGucci[1]:GetPos(), aChoosenGucci[2], true end
		
		------------------------
		if (aChoosenGun[1]) then
			self:Log(0, "Found item Worth picking up !")
			return aChoosenGun[1], aChoosenGun[1]:GetPos(), aChoosenGun[2], false end
		
		------------------------
		local sClayOrC4 = (hCurrent and (hCurrent.class == "C4" or hCurrent.class == "Claymore"))
		if ((not sClayOrC4 or not timerexpired(self.EXPLOSIVE_PICKUP_TIMER, 1))) then
		
			local hExplosive
			if (BOT_CLAYMORE_MASTER) then
				hExplosive = (self.CURRENT_PICKABLE_CLAYMORE or self:ProcessFindClaymores())
				if (hExplosive) then
					self.CURRENT_PICKABLE_CLAYMORE = hExplosive
					self:ProcessTakeClaymores()
				end
			end
			-- self:Log(0, "C4 Master: %s", (BOT_C4_MASTER and "Yes" or "No"))
			if (BOT_C4_MASTER) then
				local hExplosive = (self.CURRENT_PICKABLE_C4 or self:ProcessFindC4())
				if (hExplosive) then
					self.CURRENT_PICKABLE_C4 = hExplosive
					self:ProcessTakeC4() end
			end
		end
			
		---------------
		return
	end,
	---------------------------
	ItemCategoryStockFull = function(self, sClass)
	
		if (not sClass) then
			return false end
	
		if (self:HasItem(sClass)) then
			return true end
	
		local sCategory = g_localActor.actor:GetItemCategory(sClass)
		if (not sCategory) then
			return false end
			
		local iLimit = 1
		if (sCategory == "medium" or sCategory == "heavy") then
			iLimit = 2 end
		
		local iCount = g_localActor.actor:GetItemCountOfCategory(sCategory)
		
		self:Log(3, "COUNT OF CLASS %s CATEGORY %s: %d OF %d", sClass, sCategory, iCount, iLimit)
		
		if (iCount < iLimit) then
			return false end
			
		return true
	end,
	---------------------------
	ResetCurrentClaymore = function(self)
		self.CURRENT_PICKABLE_CLAYMORE = nil
	end,
	---------------------------
	ProcessTakeClaymores = function(self)
		
		---------------
		local hClaymore = self.CURRENT_PICKABLE_CLAYMORE
		if (not CheckEntity(hClaymore)) then
			return end
		
		---------------
		if (self:IsCarried(hClaymore)) then
			return end
		
		---------------
		local vPos = g_localActor:GetPos()
		local vClay = hClaymore:GetPos()
		
		---------------
		local iDistance = vector.distance(vPos, vClay)
		if (iDistance > 15) then
			return self:ResetCurrentClaymore() end
			
		---------------
		local bVisible = 
			iDistance <= 2.0 or
			BotNavigation:IsNodeVisibleEx(vClay)
				
		if (not bVisible) then
			self:Log(0, "$5Claymore unreachable for now!")
			return self:ResetCurrentClaymore()
		end
			
		---------------
		if (iDistance < 2.5) then
			self:StopMovement()
			g_localActor.actor:SvRequestPickUpItem(hClaymore.id)
			self:Log(0, "$5Take Claymore: %s, Gun Distance: %f", hClaymore:GetName(), iDistance)
			self:ResetCurrentClaymore()
			self.EXPLOSIVE_PICKUP_TIMER = timerinit()
		else
			self:StartMoving(1, vClay, true)
		end
		
		Particle.SpawnEffect("explosion.flare.a", vClay, vectors.up, 0.1)
		
	end,
	---------------------------
	ClaymoreStockFull = function(self, iStockLimit)
		local iClaymores = checkNumber(g_localActor.inventory:GetAmmoCount("claymoreexplosive"), 0)
		return (iClaymores >= checkNumber(iStockLimit, 2))
	end,
	---------------------------
	ResetCurrentC4 = function(self)
		self.CURRENT_PICKABLE_C4 = nil
	end,
	---------------------------
	ProcessTakeC4 = function(self)
		
		---------------
		local hC4 = self.CURRENT_PICKABLE_C4
		if (not CheckEntity(hC4)) then
			return end
		
		---------------
		if (self:IsCarried(hC4)) then
			return end
		
		---------------
		local vPos = g_localActor:GetPos()
		local vC4 = hC4:GetPos()
		
		---------------
		local iDistance = vector.distance(vPos, vC4)
		if (iDistance > 15) then
			return self:ResetCurrentC4() end
			
		---------------
		local bVisible = 
			iDistance <= 2.5 or
			BotNavigation:IsNodeVisibleEx(vC4)
			-- (BotNavigation:IsNodeVisible(vector.modify(vC4, "z", 0.25, true)) or 
			-- BotNavigation:IsNodeVisible(vector.modify(vC4, "z", 0.5, true)) or 
			-- BotNavigation:IsNodeVisible(vector.modify(vC4, "z", 1, true))) 
			-- (BotNavigation:IsNodeVisible_Handle(self:GetViewCameraPos(), vector.modify(vC4, "z", 0.25, true), "Handle_CanSeePickableClaymore", 20) or 
			-- BotNavigation:IsNodeVisible_Handle(self:GetViewCameraPos(), vector.modify(vC4, "z", 0.5, true), "Handle_CanSeePickableClaymore", 20) or
			-- BotNavigation:IsNodeVisible_Handle(self:GetViewCameraPos(), vector.modify(vC4, "z", 1, true), "Handle_CanSeePickableClaymore", 20))
				
		if (not bVisible) then
			self:Log(0, "$6C4 unreachable for now!")
			return self:ResetCurrentC4()
		end
			
		---------------
		if (iDistance < 2.0) then
			self:StopMovement()
			g_localActor.actor:SvRequestPickUpItem(hC4.id)
			self:Log(0, "$5Take C4: %s, Gun Distance: %f", hC4:GetName(), iDistance)
			self:ResetCurrentC4()
			self.EXPLOSIVE_PICKUP_TIMER = timerinit()
		else
			self:StartMoving(1, vC4, true)
		end
		
		Particle.SpawnEffect("explosion.flare.a", vC4, vectors.up, 0.1)
		
	end,
	---------------------------
	ProcessFindClaymores = function(self)
	
		---------------
		self:Log(3, "Finding Claymores")
	
		---------------
		if (self:ClaymoreStockFull()) then
			return end
	
		---------------
		local aClaymores = System.GetEntitiesByClass("Claymore")
		if (table.count(aClaymores) == 0) then
			return end
		
		---------------
		local vPos = g_localActor:GetPos()
		
		---------------
		local aCloseClays = { nil, -1 }
		for i, hClaymore in pairs(aClaymores) do
			local vClaymore = hClaymore:GetPos()
			local bCanPick = (not self:IsUnderwater(hClaymore) and not self:IsCarried(hClaymore) and self:CanSeePosition(vector.modify(vClaymore, "z", 0.25, true), hClaymore.id))
			if (bCanPick) then
				local iDistance = vector.distance(vClaymore, vPos)
				if (aCloseClays[2] == -1 or iDistance < aCloseClays[2]) then
					aCloseClays = {
						hClaymore,
						iDistance
					}
				end
			end
		end
		
		---------------
		if (aCloseClays[1]) then
			return aCloseClays[1], aCloseClays[2]
		end
		
		---------------
		return
	end,
	---------------------------
	C4ExplosiveStockFull = function(self, iStockLimit)
		local iClaymores = checkNumber(g_localActor.inventory:GetAmmoCount("c4explosive"), 0)
		return (iClaymores >= checkNumber(iStockLimit, 2))
	end,
	---------------------------
	ProcessFindC4 = function(self)
	
		---------------
		self:Log(1, "Finding C4 Explosives")
	
		---------------
		if (self:C4ExplosiveStockFull()) then
			return end
	
		---------------
		local aC4 = System.GetEntitiesByClass("C4")
		if (table.count(aC4) == 0) then
			return end
		
		---------------
		local vPos = g_localActor:GetPos()
		
		---------------
		local aCloseC4 = { nil, -1 }
		for i, hC4 in pairs(aC4) do
			local vC4 = hC4:GetPos()
			local bCanPick = (not self:IsUnderwater(hC4) and not self:IsCarried(hC4) and self:CanSeePosition(vector.modify(vC4, "z", 0.25, true), hC4.id))
			if (bCanPick) then
				local iDistance = vector.distance(vC4, vPos)
				if (aCloseC4[2] == -1 or iDistance < aCloseC4[2]) then
					aCloseC4 = {
						hC4,
						iDistance
					}
				end
			end
		end
		
		---------------
		if (aCloseC4[1]) then
			return aCloseC4[1], aCloseC4[2]
		end
		
		---------------
		return
	end,
	---------------------------
	IsUnderwater = function(self, idEntity, iThreshold)
	
		----------------
		local hEntity = GetEntity(idEntity)
		if (not hEntity) then
			return false end
		
		----------------
		local vPos = hEntity:GetPos()
		local iWater = CryAction.GetWaterInfo(vPos)
		if (not iWater) then
			return false end
		
		----------------
		local iThreshold = iThreshold
		if (not isNumber(iThreshold)) then
			iThreshold = 0.25 end
			
		----------------
		return ((iWater - vPos.z) > iThreshold)
	end,
	---------------------------
	NeedMegaGucci = function(self, sClass)
		return (not g_localActor.inventory:GetItemByClass(sClass))
	end,
	---------------------------
	IsItemWorthPickingUp = function(self, hEntity)
	
		----------------
		local hWeapon = hEntity.weapon
		if (not hWeapon) then
			return false end
		
		----------------
		local iAmmo = hWeapon:GetAmmoCount()
		local iClip = hWeapon:GetClipSize()
		
		----------------
		self:Log(0, "%f <= %f (%f)", iAmmo, (iClip / 3), iClip)
		
		----------------
		return (iAmmo and iClip and (iAmmo >= (iClip / 3)))
	end,
	---------------------------
	GucciAmmoLow = function(self, sClass)
	
		----------------
		local hWeapon = g_localActor.inventory:GetItemByClass(sClass)
		if (not hWeapon) then
			self:Log(0, "WE DO NOT HAVE THIS GUCCI ITEM %s", sClass)
			return true end
			
		----------------
		hWeapon = GetEntity(hWeapon)
		if (not hWeapon) then
			self:Log(0, "GUCCI ITEM DOES EXIST WE NEED IT !! %s", sClass)
			return true end
			
		----------------
		hWeapon = hWeapon.weapon
		if (not hWeapon) then
			self:Log(0, "GUCCI ITEM DOES NOT HAVE.weapon WE NEED IT !! %s", sClass)
			return true end
		
		----------------
		local iAmmo = hWeapon:GetAmmoCount()
		local iClip = hWeapon:GetClipSize()
		
		----------------
		self:Log(0, "GUCCI AMMO: %d <= %d (orig: %d)", iAmmo, (iClip / 3), iClip)
		
		return (iAmmo and iClip and (iAmmo <= (iClip / 3)))
	end,
	---------------------------
	SetLastPos = function(self)
		--if (not self.lastGLPosTime or _time - self.lastGLPosTime >= 0.001) then
			_lastGLPos = g_localActor:GetWorldPos();
			--self:Log(1, "Setting GL POS")
			self.lastGLPosTime = _time;
		--end
	end,
	---------------------------
	Lean = function(self, bLeft)
	
		if (not timerexpired(self.LAST_LEAN_CHANGE, 0.25) and bLeft ~= self.LAST_LEAN_LEFT) then
			return end
	
		if (self.NO_LEANING) then
			return g_localActor.actor:RequestLean(0, true) end
	
		if (bLeft) then
			g_localActor.actor:RequestLean(-1, true)
		else
			g_localActor.actor:RequestLean(1, true)
		end
		
		self.LAST_LEAN_LEFT = bLeft
		self.LAST_LEAN_CHANGE = timerinit()
		-- local sKey = "leanright"
		-- if (bLeft) then
			-- sKey = "leanleft" end
			
		-- self:Log(0, "leaning to %s", sKey)
		-- self:ReleaseKey("leanright")
		-- self:ReleaseKey("leanleft")
		-- self:PressKey(sKey, 1)
		-- g_localActor.actor:SimulateInput(sKey, 2, 1)
	end,
	---------------------------
	StopAim = function(self)
		self.NO_LEANING = false
		
		local hCurrent = self:GetCurrentItem()
		if (not hCurrent) then
			return end
			
		if (not hCurrent.weapon) then
			return end
			
		if (not hCurrent.weapon:IsZoomed()) then
			return end
		
		g_localActor.actor:SimulateInput('zoom', 1, 1);
	end,
	---------------------------
	Aim = function(self)
	
		---------------
		local hCurrentItem = self:GetCurrentItem()
		if (not hCurrentItem or hCurrentItem.class == "Fists") then
			return end
		
		---------------
		if (not hCurrentItem.weapon:IsZoomed()) then
			if (self.firing) then
				self:StopFire() end
			g_localActor.actor:SimulateInput('zoom', 1, 1)
		end
		
		self.NO_LEANING = true
		---------------
		self:Log(1, "ZOOMING!!");
	end,
	---------------------------
	HandleProMovement = function(self, entity) -- like aanya does
	
		if (self.gruntMode) then
			if (self:GetDistance(entity) > 20) then
				self:PressKey('crouch',3);
				if (not self.lastGruntMov or _time - self.lastGruntMov >= 1) then
					self:StopMovement();
					local randomMov = math.random(2, 3);
					local randomDst = math.random(2);
					self:StartMoving(randomMov, randomDst);
					self.lastGruntMov = _time;
					if (self:GetDistance(entity) > 30) then
						self:PressKey('moveforward', 1);
					end
					
					--fixme: leanbug
				self:Lean(math.random(1, 2));
					end
			else--if (self:GetDistance(entity) < 25) then
				if (not self.lastGruntMov or _time - self.lastGruntMov >= 1) then
					self:PressKey('crouch',3);
					self:StopMovement();
					local randomMov = math.random(2, 3);
					local randomDst = math.random(2);
					self:StartMoving(randomMov, randomDst);
					self.lastGruntMov = _time;
				end
			end
			return
		end
	
		self:Log(1, "$4>>>>>$8ACTORSTANCE: " .. entity.actorStats.stance)
		if (not self.isBoxing and ((self:GetCurrentItem() and self:IsSniper(self:GetCurrentItem().class) and self:GetDistance(entity) >= 66) or (self:GetDistance(entity)>=48 or math.random(1,3) == 2) and ((entity.actorStats.stance~=0 and self:GetDistance(entity)>=13) or (self:GetDistance(entity)>=30)) and self._difficulty>=2)) then -- prone and AIM if target NOT standing OR Distance >- 45 ???
			self:Log(0, "???")
			self.followTargetSpot = true
			self:Aim()
			self:StopMovement()
			self:Prone(1, true)
		elseif (not self.isBoxing) then
			self:Log(0, "!!???")
			local _delay = checkNumber(BOT_PROMOVE_MOVE_DELAY, 0.8)
			local _proneChange = 2;
			
			if (self._difficulty <2) then -- -1=fortnite,0=noob,1=average,2=pro,3=godlike
				_delay=1; -- average
				_proneChange = 5;
			end
			if (self._difficulty <1 and self._difficulty>-1) then -- -1=fortnite,0=noob,1=average,2=pro,3=godlike
				_delay=2; -- noob
				_proneChange = 9999 -- NEVER PRONE
				if (not self.isBoxing) then
					self:PressKey('crouch',3); -- noobs always crouch :D
				else
					self:ReleaseKey('crouch');
				end
				return
			end
			if (self._difficulty <0) then -- -1=fortnite,0=noob,1=average,2=pro,3=godlike
				return self:StopMovement();
			end
			-- if (not self.currentMovement or _time - self.currentMovement._last >= _delay) then
			if (timerexpired(self.PRO_MOVEMENT_TIMER, _delay)) then
				-- if (self.isBoxing) then
					-- self:StartMoving(1, entity:GetPos()); -- ProcessTarget -> DC -> 1 = ok. means we do not need to move forward. bot v.1 did this and this caused weird camera glitches and bugs.
				-- else
					-- self:StopMovement()	
					-- local randomMov = math.random(2, 3);
					-- local randomDst = math.random(checkNumber(BOT_PROMOVE_MOVE_DISTANCE, 1.5))
					-- self:StartMoving(randomMov, randomDst)
					
					-- if (BOT_PROMOVE_RANDOM_PRONE and math.random(_proneChange) == 2) then
						-- self:Prone(math.random(10, 25) / 100);
					-- end
					-- self:Log(0, "PRO MOVEMENT RANDOM DIR !!!")
				-- end
				
				self:Log(0, "PRO MOVEMENT RANDOM DIR !!!")
				self:StopMovement()	
				self.PRO_MOVEMENT_RANDOMDIR = getrandom(2, 3)
				self.PRO_MOVEMENT_RANDOMDIST = getrandom(0.5, checkNumber(BOT_PROMOVE_MOVE_DISTANCE, 1.5))
				self.PRO_MOVEMENT_TIMER = timerinit()
				
				if (BOT_PROMOVE_RANDOM_PRONE and math.random(_proneChange) == 2) then
					self:Prone(math.random(10, 25) / 100);
				end
			end
			
			self:StartMoving(self.PRO_MOVEMENT_RANDOMDIR, self.PRO_MOVEMENT_RANDOMDIST)
		end
	end,
	-- I always forget this. :D
	["SPEED"] = 0,
	["STRENGTH"] = 1,
	["CLOAK"] = 2,
	["ARMOR"] = 3,
	
	suitModes = {
		[0] = "SPEED";
		[1] = "STRENGTH";
		[2] = "CLOAK";
		[3] = "ARMOR";
	},
	---------------------------
	ProcessTest = function(self)
						
		--[[if (g_localActor.actor:IsFrozen() and self.unFreezeIfFrozen) then
			self.SIM_UNFREEZE_SHAKE = true;
			g_localActor.actor:SimulateInput();
		elseif (self.SIM_UNFREEZE_SHAKE) then
			
		end--]]
						
						
						--if (_time - self.boxKeyRun.J >= 1.3) then
						--	self:PressKey("jump", 1);
						--	self:Log(1, _time - self.boxKeyRun.J .. " $6BOXRUN: JUMP");
						--	self.boxKeyRun.J = _time;
						--	
						--		Script.SetTimer(100, function()
						--			self:PressKey("moveright", 0.5);
						--			Script.SetTimer(110, function()
						--				self.boxKeyRun.LJ = nil;
						--			end);
						--		end);
						--elseif (_time - self.boxKeyRun.J >= 1.2) then
						--	
						--	if (not self.boxKeyRun.LJ ) then
						--		self.boxKeyRun.LJ = true;
						--		self:PressKey("moveleft", 0.3);
						--		
						--		self.boxKeyRun.LK = self.boxKeyRun.LK == 1 and 2 or 1;
						--	end
						--end
							
				
	end,
	---------------------------
	HandleBoxMovement = function(self, entity) -- move randomly around, that's what pros do, right?
		self:StopMovement();
		local randomMov = math.random(2, 3);
		local randomDst = math.random(2);
		self:StartMoving(randomMov, randomDst);
	end,
	---------------------------
	PressedKeys = {},
	---------------------------
	PressKey = function(self, sKeyName, iTime)
	
		--------------
		if (not g_localActor.actor.SimulateInput) then 
			return end
		
		--------------
		if (self:IsKeyPressed(sKeyName)) then
			return self:Log(2, "Key %s already Pressed", sKeyName) end
			
		--------------
		g_localActor.actor:SimulateInput(sKeyName, 1, 1)
		
		--------------
		self.PressedKeys[sKeyName] = { pressTime = _time, releaseTime = checkNumber(iTime, -1) }
		self:Log(2, "$4Pressing Key: " .. sKeyName)
	end,
	---------------------------
	IsKeyPressed = function(self, sKeyName)
		return self.PressedKeys[sKeyName]
	end,
	---------------------------
	ReleaseKey = function(self, sKeyName)
	
		--------------
		if (not g_localActor.actor.SimulateInput) then 
			return end
			
		--------------
		if (self:IsKeyPressed(sKeyName)) then
			g_localActor.actor:SimulateInput(sKeyName, 2, 0)
			self.PressedKeys[sKeyName] = nil
			self:Log(2, "$4Pressing Key: " .. sKeyName)
		end
	end,
	---------------------------
	CanSeePos_Check = function(self, pos, retry, entityId)
		if (not retry) then
			return self:CanSeePosition(pos, entityId or self.temp._aimEntityId);
		else
			local pos = pos;
			if (self:CanSeePosition(pos, entityId or self.temp._aimEntityId)) then
				return true;
			elseif (pos) then
				pos.z = pos.z + 1;
				return self:CanSeePosition(pos, entityId or self.temp._aimEntityId);
			end
		end
	end,
	---------------------------
	OnRadioMessage = function(self, hEntity, iMessage)
		BotAI.CallEvent("OnRadioMessage", hEntity, iMessage)
	end,
	---------------------------
	SendRadioMessage = function(self, iMessage)
		g_gameRules.game:SendRadioMessage(g_localActorId, iMessage)
	end,
	---------------------------
	OnTaggedEntity = function(self, idEntity, hEntity)
		if (not self.TAGGED_ENTITIES) then
			self.TAGGED_ENTITIES = {} end
			
		---------------------
		self.TAGGED_ENTITIES[idEntity] = timerinit()
	end,
	---------------------------
	IsEntityTagged = function(self, idEntity)
		if (not self.TAGGED_ENTITIES) then
			self.TAGGED_ENTITIES = {} end
			
		---------------------
		return (not timerexpired(self.TAGGED_ENTITIES[idEntity], 20))
	end,
	---------------------------
	ProcessTarget = function(self, returnOnly)
	
		---------------------
		local hCurrentItem = self:GetCurrentItem()
		local idEntity = self.temp._aimEntityId
		if (idEntity) then
		
			---------------------
			local hEntity = GetEntity(idEntity)
			local entity = self:Exists(idEntity);
			if (entity) then
			
				---------------------
				if (entity.actor:GetSpectatorMode() ~= 0) then
					return self:ClearData() end
			
				---------------------
				self.TARGET_LOST_TIMER = nil
			
				---------------------
				local bTooFar = self:IsTargetTooFar(hEntity, self.LAST_SEEN_TARGET_LOOSE)
				local bIsAlive = self:AliveCheck(hEntity)
			
				---------------------
				self.isTargetRight = false; -- !TODO
			
				---------------------
				self:CheckForBetterGun()
				if (timerexpired(self.MELEE_TIMER, 0.05)) then
					self:Log(0, "MELEE TIMER EXPIRED !!")
					self:DefaultSuitMode() end
			
				---------------------
				self:Log(2, "self:ProcessTarget() -> $4" .. entity:GetName() .. "!");
				if (HAS_JET_PACK and entity.actor:IsFlying()) then
					if (g_localActor.actor:IsFlying()) then
						self:InvokeJump();
					end
					self:PressKey("use");
					self._JETPACKING = true;
				else
					self:ReleaseKey("use");
					self._JETPACKING = false;
				end
				
				---------------------
				local alive, distanceCheck, canSee = self:AliveCheck(entity), self:DistanceCheck(entity), self:CanSee(entity, true);
				self:Log(2, "	ALIVE: %s", (alive and "YES" or "NO"));
				self:Log(2, "	CAN SEE: %s", (canSee and "YES" or "NO"));
				
				---------------------
				if ((not alive or not canSee)) then-- and self.lastSeenMoving) then
					if (self:HasTarget()) then
						self:Log(3, "NEw Target, clearing ALL DATA!!!")
						return self:ClearData()
					end
				end
				
				---------------------
				if (not alive) then
					if (self.STOP_PRONE_IF_DEAD) then
						self.STOP_PRONE_IF_DEAD = false
						self:StopProne()
					end
				end
				
				---------------------
				if (canSee) then
					self.lastSeenPos = entity:GetPos();
					self.lastGLSeenPos = g_localActor:GetPos();
				end
				
				---------------------
				local distance = self:GetDistance(entity)
				local targetAimPos = self:GetAimBonePos(entity)
				local posInBack = self:CalcPos(-1);
				if (alive and canSee) then
				
					self:ResetLastSeen()
				--	self:Log(0, self.isBoxing)
					if (distanceCheck == 1 or (entity.actorStats.stance ~= STANCE_STAND)) then -- ok
						if (self.isBoxing) then
							self:Log(2, "Box, bro")
							self:Log(2, "BOXD:" .. self:GetDistance(entity))
							local boxDistanceCheck = self:DistanceCheck(entity, 1.9);--2.25);
							if (boxDistanceCheck == 1) then
								self:SuitMode(1); -- we're ready to kill, let's use strength. :)
								self:ProcessAimedTarget(true);
								self:Log(2, "Perfect to box now.");
								self.followTargetSpot = true;
								
							elseif (boxDistanceCheck == 2) then
								self:StartMoving(1, entity:GetPos(), true);
								self:SuitMode(self['SPEED']); -- too far, let's rush to him with speed mode. :)
								self:Log(1, "$4too far, bro");
								self.boxRun = true;
								self.movingBack = false;
								self:Log(1, "NO BOS< HE TO CLOSE!")
								
								-- (!) Hacker
								if (self._difficulty == 4) then
									g_localActor:SetPos(entity:GetPos()) end
								
							elseif (boxDistanceCheck == 3) then
								if (not self.movingBack) then
									self:StopMovement();
									self:SuitMode(0); -- we're too close, let's run back fast. :)
									self:StartMoving(4, { x = posInBack.x, y = posInBack.y, z = targetAimPos.z });
									self:Log(1, "$6too close, bro")
									self.movingBack = true;
								end
							end
							
						else
							self:Log(2, "No boxing")
							-- self:SuitMode(3); 
							self:DefaultSuitMode()
							self:ProcessAimedTarget(true);
							self:HandleProMovement(entity);
						end
					elseif (distanceCheck == 2) then -- too far
						self:StopMovement();
						if (self.isBoxing) then
							self:SuitMode(0); 
						else
							self:SuitMode(3);
						end
						self:StartMoving(1, targetAimPos, true);
						self:Log(1, "$5too far, bro")
						self.movingBack = false;
						if (self:GetCurrentItem() and not self:IsSniper(self:GetCurrentItem().class)) then
							self.boxRun = true;
						end
						
						if (self._difficulty==4) then
									g_localActor:SetPos(entity:GetPos())
								end
						
					elseif (distanceCheck == 3) then -- too close	
						self:Log(1, "TOo close!!");
						if (not self.movingBack) then
							self:StopMovement();
							if (self.isBoxing) then
								self:SuitMode(0); 
							else
								self:SuitMode(3); 
							end
							self:StartMoving(4, posInBack);
							self.movingBack = true;
						end
						--self:Log(1, "$5too close 1, bro")
					else
						self:SendMsg(target:GetName() .." < too far")
					end
				end
				
				if (alive and not canSee) then
				
					self:Log(0, "Would to to last seen but: has target: %s", (self:HasTarget() and "yes" or "no"))
					self:Log(0, "Would to to last seen but: too far: %s", (bTooFar and "yes" or "no"))
					self:Log(0, "Would to to last seen but: flying: %s", (entity.actor:IsFlying() and "yes" or "no"))
					if (not bTooFar and not entity.actor:IsFlying() and not self:HasTarget()) then
						self:ProcessLastSeenMoving(entity)
					end
					self:Log(1, "O:" .. tostring((self.lastSeenPos and not self.lastSeenMoving and not self:HasTarget())) .. ", 1=" .. tostring(self.lastSeenPos~=nil) .. ", 2=" .. tostring(not self.lastSeenMoving) .. ", 3=" .. tostring(not self:HasTarget()))
				elseif (not alive and (canSee or self.DEATH_POS_MOVING) and distance > 8 and not self:HasTarget()) then
					if (not entity.actor:IsFlying() and not self.lastSeenMoving and distance < 60) then
						if (not self.followTarget or self.followTarget and distance < 15) then
						
							if (not self.SHOOTING_THREATS) then
								self:Log(1, "$3Moving to death position | CHECKRELOAD", true)
								self:CheckReload(not self:PlayersNear(6));
								self.lastSeenMoving = true;
								
								self.LAST_SEEN_POSITION = entity:GetPos()
								self.lastWasDeathPos = true;
								self.movingBack = false;
								
								self:ProcessGotoDeathPos(entity)
							end
						end
					else
						self:Log(0," 2 STUCK NEAR PLAYER??")
					end
				--elseif (self:HasTarget()) then
				--	self:Log(0, "NEw Target, clearing ALL DATA!!!");
				--	self:ClearData();
				elseif (not canSee) then
					self:Log(0, "CANNOT SEE!")
					self:ProcessPathfinding()
				elseif (alive) then
					self:Log(0, "CAN SEE AND ALIVE?")
					--self:ProcessPathfinding()
				else
					self:Log(0, "DEAD. CAN SEE. TOO CLOSE. CLEAR DATA!!!")
					self:ClearData()
				end
				
				if (not alive and self.NO_MOVEMENT and timerexpired(self.NO_MOVEMENT_START, 0.35)) then
					self:Log(0, "NO MOVEMENT!!")
					self:Log(0, "$4CLEARNING ALL DAA!")
					self:PathfindingReset()
					self:ResetLastSeen()
					self:ClearData()
				end
				
				if (self.LAST_SEEN_MOVING and (bTooFar or self:LastSeenExpired(20) or (not bIsAlive))) then
					self:Log(1, "Last seen done, clearing data");
					self:PathfindingReset()
					self:ResetLastSeen()
				end
				
				if (not self.LAST_SEEN_MOVING and not canSee and not alive) then
					self:Log(0, "Procesing path, DEAD ant NOT LAST SEEN MOVING and NOT CAN SEE and NOT ALIVE")
					self:ProcessPathfinding()
				end
				
				if (not canSee) then
					if (not alive and not self:HasTarget()) then
					
						self:CheckReload();
					end
					self:StopFire();
				elseif (not alive) then
					self:StopFire();
				end
			else
				if (not self:HasTarget()) then
					self:CheckReload(not self:PlayersNear(8));
				end
				self:ClearData();
			end
		else
		
			---------------------
			if (not self:CheckTarget()) then
			
				---------------------
				if (isNull(self.TARGET_LOST_TIMER)) then
					self.TARGET_LOST_TIMER = timerinit() end
					
				---------------------
				if (not CheckEntity(self.CURRENT_ACTIVE_THREAT)) then
				
					---------------------
					local sClass
					if (hCurrentItem) then
						sClass = hCurrentItem.class
						if (sClass == "Claymore") then
							local hSpawn = self:GetNearestEntityOfClass("SpawnPoint", nil, function(hEntity) 
								local aInRange = Bot:GetEntitiesInRange("claymoreexplosive", 3, hEntity:GetPos())
								local bCanPlace = BotAI.CallEvent("CanPlaceExplosive", hEntity, hEntity:GetPos())
								return ((not isArray(aInRange)) and (isDead(bCanPlace) or bCanPlace == true))
							end)
							if (not hSpawn or Bot:GetEntitiesInRange("Door", 3, g_localActor:GetPos())) then
								self:PlaceClaymore()
							else
								self:PlaceBoobyTrap(hSpawn)
							end
							return
						elseif (sClass == "C4") then
							self:PlaceC4()
							return
						end
					else
						self.CLAYMORE_PLACE_DIR = nil
					end
					
					---------------------
					if (self:HasItem("Detonator") and table.count(self.CURRENT_OWNED_C4) > 0) then
						if (self:UnsuspectingTargetNearC4()) then
							self:DetonateC4()
						end
					end
				
					---------------------
					if (self.FORCE_ATTACH_ACCESSORIES and timerexpired(self.WEAPON_PICKUP_TIMER, 2.5)) then
						self.FORCE_ATTACH_ACCESSORIES = false
					end
				
					---------------------
					self:Log(3, "No targetId and no checked target!")
					if ((not self.lastSeenMoving or timerexpired(self.LAST_MOVING_LAST_CALL, 5)) and not self.movingToMyGUN) then
						self:ProcessPath();
					end
					
					---------------------
					local hRadar = GetEntity(self:HasItem("RadarKit"))
					if (hRadar and timerexpired(self.TARGET_LOST_TIMER, 6) and timerexpired(self.C4_DETONATION_TIME, 3)) then
						self:SelectItem("RadarKit")
						self.RADAR_SELECT_TIME = timerinit()
						
						if (sClass == "RadarKit" and timerexpired(self.RADAR_SCAN_TIME, 8)) then
							self:Log(0, "SCAN WITH RADAR!!")
							hRadar.weapon:RequestStopFire()
							hRadar.weapon:RequestStartFire()
							self.RADAR_SCAN_TIME = timerinit()
						end
					else
						self.RADAR_SELECT_TIME = nil
					end
					
					---------------------
					self:CheckReload(not self:PlayersNear(4))
					self:BrowseInventory()
				end
			else
			
				---------------------
				if (self.RADAR_SELECT_TIME) then
					if (GetEntity(self.RADAR_LAST_ENTITY)) then
						self.RADAR_LAST_ENTITY.weapon:RequestStopFire() end
					self.RADAR_SELECT_TIME = nil end
					
				---------------------
				self:Log(0, "HAS TARGET, SI!")
			end
			
			---------------------
			if (self.firing) then
				self:StopFire() end
			
			---------------------
			if (self.STOP_PRONE_IF_DEAD) then
				self:StopProne()
				self.STOP_PRONE_IF_DEAD = false end
			
			---------------------
			if (self._difficulty >= 4) then
				for i, hPlayer in ipairs(GetPlayers()) do
					if (hPlayer.id ~= g_localActorId and self:AliveCheck(hPlayer)) then
						self.temp._aimEntityId = hPlayer.id
						if (not hPlayer.actor:IsFlying()) then
							g_localActor:SetPos(hPlayer:GetPos()) 
							break end
					end
				end
			end
		end
	end,
	---------------------------
	ProcessLastSeenMoving = function(self, hEntity)
		
		self:Log(0, "$3Moving to last seen")
		
		local vEntityPos = hEntity:GetPos()
		
		local iMaxDistance = 60
		if (g_gameRules.class == "PowerStruggle") then
			iMaxDistance = 35 end
			
		if (not self:AliveCheck(hEntity) or (vector.distance(vEntityPos, g_localActor:GetPos()) > iMaxDistance)) then
			self:ClearData()
			return self:ResetLastSeen() end
		
		local bMoved = (not isNull(self.LAST_SEEN_MOVING_ENTITY_POS) and vector.distance(self.LAST_SEEN_MOVING_ENTITY_POS, hEntity:GetPos()) > 5)
		if (self.LAST_SEEN_MOVING_START_TIMER == nil or bMoved) then-- or () then
			if (bMoved) then
				self.LAST_SEEN_MOVING_ENTITY_POS = hEntity:GetPos()
			else
				self.LAST_SEEN_MOVING_CAMPING_TIME = getrandom(2, 3.5)
				self.LAST_SEEN_MOVING_START_TIMER = timerinit() end end
			
		if (not timerexpired(self.LAST_SEEN_MOVING_START_TIMER, self.LAST_SEEN_MOVING_CAMPING_TIME)) then
			self:Log(3, "%f SECONDS CAMPING TIMER !!!", self.LAST_SEEN_MOVING_CAMPING_TIME)
			if (timerexpired(self.LAST_SEEN_MOVING_RANDOMDIR, 0.3)) then
				self:Log(3, "RESET RANDOM MOVE!!")
				self.LAST_SEEN_MOVING_RANDOMDIR = timerinit()
				
				self.LAST_SEEN_MOVING_DIR = getrandom(2, 3)
				self.LAST_SEEN_MOVING_DIST = getrandom(0.3, 0.75)
			end
			
			self:CheckReload()
			self:StartMoving(self.LAST_SEEN_MOVING_DIR, self.LAST_SEEN_MOVING_DIST)
			self:SetCameraTarget(vEntityPos)--(self.LAST_SEEN_MOVING_ENTITY_POS)
			self:ProcessLeaning(vEntityPos)
			return
		end

		local idTarget = BotNavigation:GetTargetId()
		if (not idTarget or idTarget ~= hEntity.id) then
			BotNavigation:GetNewPath(hEntity) end
	
		self.LAST_MOVING_LAST_CALL = timerinit()

		self:ProcessPathfinding()
		BotNavigation.CURRENT_PATH_NODELAY = true
		BotNavigation.CURRENT_PATH_IGNOREPLAYERS = true
		
		self.LAST_SEEN_ENTITYID = hEntity.id
		self.LAST_SEEN_MOVING = 1
		if (self.LAST_SEEN_MOVING_START == nil) then
			self.LAST_SEEN_MOVING_START = _time end

		self:ProcessLeaning(vEntityPos)
	end,
	---------------------------
	ProcessGotoDeathPos = function(self, hEntity)
	
		if (self:AliveCheck(hEntity)) then
			if (self:GetAimTargetId() == hEntity.id) then
				self:ClearData() end
			self.lastSeenMoving = false
			return end
	
		self.LAST_MOVING_LAST_CALL = timerinit()
	
		self:Log(0, "$3Moving to death pos")

		local idTarget = BotNavigation:GetTargetId()
		if (not idTarget or idTarget ~= hEntity.id) then
			BotNavigation:GetNewPath(hEntity) end

		self:ProcessPathfinding()
		BotNavigation.CURRENT_PATH_NODELAY = true
		BotNavigation.CURRENT_PATH_IGNOREPLAYERS = true
		BotNavigation.IGNORE_IDLE_PLAYERS_TIMER = timerinit()

		self.DEATH_POS_MOVING = 1
		if (self.DEATH_POS_MOVING_START == nil) then
			self.DEATH_POS_MOVING_START = _time end

	end,
	---------------------------
	BrowseInventory = function(self)
		
		-----------
		if (not self:HasTarget() and not timerexpired(self.RADAR_SELECT_TIME, 1)) then
			self:Log(3, "HAS RADAR, DO NOT PROCEED BROWSING !!")
			return end
		
		-----------
		self:CheckForBetterGunEx()
		
		-----------
		local hTarget = GetEntity(self.temp._aimEntityId)
		if (hTarget) then
			return end
			
		-----------
		if (self:HasTarget()) then
			self:Log(0, "HAS TARGET !! DO NOT PROCEED RELOADING !!")
			return end
			
		-----------
		local hCurrent = self:GetCurrentItem()
		if (not self:AmmoFull(hCurrent) and self:GetAmmo(hCurrent) > 0) then
			self:Log(3, "Ammo not full. checking reload !!")
			if (self:CheckReloadEx()) then
				return end
		end
			
		-----------
		local aInventory = g_localActor.inventory:GetInventoryTable()
		if (not isArray(aInventory)) then
			return end
			
		-----------
		local aReloadable = { "SCAR", "FY71", "SMG", "Shotgun", "TACGun", "Hurricane", "SOCOM", "DSG1", "GaussRifle" }
		if (timerexpired(self.LAST_RELOAD_TIMER)) then
			for i, idItem in pairs(aInventory) do
				local hItem = GetEntity(idItem)
				if (hItem and table.lookup(aReloadable, hItem.class) and hItem.weapon) then
					if (not self:AmmoFull(hItem)) then
						self:Log(0, "$4 %s AMMO LEFT: %d", hItem.class, self:GetInventoryAmmo(hItem))
					end
					if (not self:AmmoFull(hItem) and self:GetInventoryAmmo(hItem) > 0) then
						
						self:SelectItem(hItem.class)
						self:CheckReloadEx()
						self:Log(0, "AMMO OF %s NOT FULL, SELECT AND RELOAD !", hItem.class)
					end
				end
			end
		end
			
		-----------
		local aAlwaysSelect = { "C4", "Claymore" }
		local aNeverSelect = { "Detonator" }
		
		-----------
		for i, sItem in pairs(aAlwaysSelect) do
			local hItem = GetEntity(self:HasItem(sItem))
			if (hItem and self:GetInventoryAmmo(hItem.weapon:GetAmmoType()) > 0) then
				self:Log(3, "Found %s while browing inventory!", sItem)
				return self:SelectItem(sItem) end
		end
		
	end,
	---------------------------
	AmmoFull = function(self, hCurrent)
	
		if (not hCurrent) then
			return true end
	
		if (not hCurrent.weapon) then
			return true end
	
		local iAmmo = checkNumber(hCurrent.weapon:GetAmmoCount(), 0)
		local iClip = checkNumber(hCurrent.weapon:GetClipSize(), 0)
		local iMax = (iClip - 1)
		
		if (hCurrent.class == "Hurricane") then
			iMax = (iClip / 10)
		end

		return (iAmmo >= (iClip - 1))
	end,
	---------------------------
	PlaceBoobyTrap = function(self, hTarget)

		------------
		if (not CheckEntity(hTarget)) then
			return self:PlaceClaymore() end
	
		------------
		self:Log(1, "Placing Boobytrap at entity %s", hTarget:GetName())

		------------
		local vPos = hTarget:GetPos()
		local vActorPos = g_localActor:GetPos()

		------------
		self.CLAYMORE_PLACE_DIR = vector.getdir(vPos, self:GetViewCameraPos(), true, -1)

		------------
		local iDistance = vector.distance(vActorPos, vPos)
		if (iDistance < 0.5 or (iDistance < 3 and BotNavigation:IsNodeVisible(vPos))) then
			return self:PlaceClaymore() end
	
		------------
		local idTarget = BotNavigation:GetTargetId()
		if ((not idTarget or idTarget ~= hTarget.id) and timerexpired(self.FIND_CLAYMORE_PLACE_TIMER)) then
			self:Log(0, "New path, target CHANGED !!")
			if (not BotNavigation:GetNewPath(hTarget)) then
				self.FIND_CLAYMORE_PLACE_TIMER = timerinit()
				return self:PlaceClaymore() end 
		end

		BotNavigation.CURRENT_PATH_NODELAY = true
		BotNavigation.CURRENT_PATH_IGNOREPLAYERS = true
		BotNavigation.IGNORE_IDLE_PLAYERS_TIMER = timerinit()
		
		self:ProcessPathfinding()
	end,
	---------------------------
	PlaceClaymore = function(self)
	
		------------
		self.PLACING_CLAYMORE_TIMER = timerinit()
	
		------------
		self:Log(1, "Placing Claymore")
		
		------------
		if (not self.CLAYMORE_PLACE_DIR) then
			self.CLAYMORE_PLACE_DIR = self:GetViewCameraDir() end

		------------
		local vDir = self.CLAYMORE_PLACE_DIR

		------------
		self:PressKey("crouch", 0)
		-- self:ReleaseKey("attack1")
		-- self:PressKey("attack1", 0.1)

		------------
		local hCurrent = self:GetCurrentItem()
		if (hCurrent and hCurrent.class == "Claymore") then
			hCurrent.weapon:RequestStartFire()
			hCurrent.weapon:RequestStopFire()
		end

		------------
		self:StopMovement()
		self:SetCameraTarget(vector.make(vDir.x, vDir.z, -1.8), nil, true)
	end,
	---------------------------
	PlaceC4 = function(self)
	
		------------
		self:Log(0, "Placing C4")

		------------
		self:PressKey("crouch", 0)
		-- self:PressKey("attack1", 1)

		------------
		local hCurrent = self:GetCurrentItem()
		if (hCurrent and hCurrent.class == "C4") then
			hCurrent.weapon:RequestStartFire()
			hCurrent.weapon:RequestStopFire()
		end
		
		------------
		self:UpdateOwnedC4()

		------------
		self:StopMovement()
	end,
	---------------------------
	UnsuspectingTargetNearC4 = function(self, iCheckDistance)
		
		------------
		self:UpdateOwnedC4()
		if (table.count(self.CURRENT_OWNED_C4) == 0) then
			return end
		
		------------
		local aPlayers = GetPlayers()
		if (table.count(aPlayers) == 1) then
			return end
		
		------------
		local iCheckDistance = checkNumber(iCheckDistance, 5)
		
		------------
		for i, hC4 in pairs(self.CURRENT_OWNED_C4) do
			local vC4 = hC4:GetPos()
			for _i, hPlayer in pairs(aPlayers) do
				if (self:AliveCheck(hPlayer) and hPlayer.id ~= g_localActorId) then
					if (vector.distance(vC4, hPlayer:GetPos()) < iCheckDistance) then
						return true
					end
				end
			end
		end
		
		------------
		return false
	end,
	---------------------------
	DetonateC4 = function(self)
	
		------------
		if (not self:HasItem("Detonator")) then
			return end
			
		------------
		self:SelectItem("Detonator")
		-- self:PressKey("attack1")
		
		------------
		local hCurrent = self:GetCurrentItem()
		if (hCurrent and hCurrent.class == "Detonator") then
			hCurrent.weapon:RequestStartFire()
			hCurrent.weapon:RequestStopFire()
		end
		
		------------
		self.C4_DETONATION_TIME = _time
		self.C4_DETONATION_TIMER = timerinit()
		self:Log(0, "Detonating C4!!!")
	end,
	---------------------------
	UpdateOwnedC4 = function(self)
	
		------------
		self.CURRENT_OWNED_C4 = {}
		
		------------
		for i, hC4 in pairs(System.GetEntitiesByClass("c4explosive") or {}) do
			if (Game.GetProjectileOwner(hC4.id) == g_localActorId) then
				table.insert(self.CURRENT_OWNED_C4, hC4) end
		end
		
		------------
		return self.CURRENT_OWNED_C4
	end,
	---------------------------
	GetEntitiesInRange = function(self, sClass, iMaxDistance, vPos, fPred)

		------------
		local aEntities = System.GetEntities()

		------------
		local iMaxDistance = checkNumber(iMaxDistance, 5)
			
		------------
		local vPos = vPos
		if (not vector.isvector(vPos)) then
			vPos = g_localActor:GetPos() end
		
		------------
		local aFound = {}
		for i, hEntity in pairs(aEntities) do
			if ((isNull(sClass) or (hEntity.class == sClass)) and (isNull(fPred) or fPred(hEntity) == true)) then
				local iDistance = vector.distance(vPos, hEntity:GetPos())
				if (iDistance < iMaxDistance) then
					table.insert(aFound, hEntity)
				end
			end
		end
		
		------------
		return (table.count(aFound) > 0 and aFound)
	end,
	---------------------------
	GetNearestEntityOfClass = function(self, sClass, vPos, fPred)
		local aEntities = System.GetEntitiesByClass(sClass)
		if (not isArray(aEntities) or table.count(aEntities) == 0) then
			return end
			
		------------
		local vPos = vPos
		if (not vector.isvector(vPos)) then
			vPos = g_localActor:GetPos() end
			
		------------
		local aEntity = { nil, -1 }
		for i, hEntity in pairs(aEntities) do
			if (isNull(fPred) or (fPred(hEntity) == true)) then
				local iDistance = vector.distance(vPos, hEntity:GetPos())
				if (aEntity[2] == -1 or iDistance < aEntity[2]) then
					aEntity = { hEntity, iDistance }
				end
			end
		end
		
		------------
		return aEntity[1]
	end,
	---------------------------
	IsTargetTooFar = function(self, hTarget, iMaxDistance)
	
		------------
		if (not hTarget) then
			return true end
			
		------------
		local iMaxDistance = iMaxDistance
		if (not iMaxDistance) then
			iMaxDistance = self.LAST_SEEN_TARGET_LOOSE end
	
		------------
		local vPos = g_localActor:GetPos()
		local vTarget = hTarget:GetPos()
		
		------------
		local iDistance = vector.distance(vPos, vTarget)
		
		------------
		return (iDistance > iMaxDistance)
	end,
	---------------------------
	ResetDeathGoto = function(self)
		self:ClearData()
		self.DEATH_POS_MOVING_START = nil
	end,
	---------------------------
	ResetLastSeen = function(self)
		self.lastSeenMoving = false
		self.LAST_SEEN_MOVING = nil
		self.LAST_SEEN_MOVING_START = nil
		self.LAST_SEEN_ENTITYID = nil
		self.LAST_SEEN_MOVING_START_TIMER = nil
		self.LAST_SEEN_MOVING_ENTITY_POS = nil
		self.LAST_SEEN_MOVING_CAMPING_TIME = nil
		self.LAST_SEEN_MOVING_RANDOMDIR = nil
	end,
	---------------------------
	LastSeenExpired = function(self, iTime)
		local iTime = iTime
		if (not iTime) then
			iTime = 30 end
		
		if (not self.LAST_SEEN_MOVING_START) then
			return false end
		
		return ((_time - self.LAST_SEEN_MOVING_START) >= iTime)
	end,
	---------------------------
	BindPlayerToPos = function(self, player, pos, releaseIfCondition)
		if self.BIND_PLAYERS then
			self.BIND_PLAYERS[player.id] = { pos, releaseIfCondition };
		end
	end,
	---------------------------
	CarryingHeavyGun = function(self)
		local curr = Bot:GetCurrentItem();
		if (curr and (curr.class == "AlienMount" or curr.class == "Hurricane")) then
			return true;
		end
		return false;
	end,
	---------------------------
	IsSniper = function(self, class)
		local snipers = {
			['DSG1']	   = true,
			['GaussRifle'] = true
		};
	--	self:Log(0, class .. " >> " .. tostring(snipers[class]))
		return snipers[class];
	end,
	---------------------------
	GetAmmoPercentage = function(self, hItem, iCheck)
		
		local hWeapon = hItem.weapon
		if (not hWeapon) then
			return end
			
		local iAmmo = hWeapon:GetAmmoCount()
		local iMaxAmmo = (hWeapon:GetClipSize() + 1)
		
		if (not iAmmo or not iMaxAmmo) then
			if (iCheck) then
				return (0 >= iCheck) end
			return 0 end
			
		local iAmmoPercent = ((iAmmo / iMaxAmmo) * 100)
		
		if (iCheck) then
			return iAmmoPercent >= iCheck end
			
		return iAmmoPercent
	end,
	---------------------------
	GetAimTarget = function(self)
		return GetEntity(self.temp._aimEntityId)
	end,
	---------------------------
	GetAimTargetId = function(self)
		return self.temp._aimEntityId
	end,
	---------------------------
	CheckForBetterGunEx = function(self, bSofort)
	
		-------------
		if (not bSofort and (not timerexpired(self.LAST_FORCE_RELOAD_TIMER, 3) or not timerexpired(self.LAST_RELOAD_TIMER, 3))) then
			return end
	
		-------------
		local hTarget = self:GetAimTarget()
		if (hTarget and hTarget.actor:GetLinkedVehicleId()) then
			self:Log(0, "TARGET ON VEHICLE, CHEcK FOR RPG!")
			if (self:HasItem("RPG") and self:GetAmmo("rocket") >= 1) then
				self:Log(0, "HAS RPG, SELECT NOW !!")
				return self:SelectItem("RPG")
			end
		end
		
		-------------
		local hCurrent = self:GetCurrentItem()
		
		-------------
		local iTargetDistance = self:GetTargetDistance()
		self:Log(3, "iTargetDistance === %f", checkNumber(iTargetDistance, 0))
		if (iTargetDistance and (iTargetDistance > 0 and (iTargetDistance < 10))) then
			local hSMG = GetEntity(self:HasItem("SMG"))
			if (hSMG) then
				if (self:GetAmmoPercentage(hSMG, 25)) then
					self:Log(0, "taregt close and we have SMG. use that crap NOW!")
					return self:SelectItem("SMG")
				end
			end
		end
	
		-------------
		if (hCurrent and hCurrent.weapon) then
			local iAmmo = hCurrent.weapon:GetAmmoCount()
			if (iAmmo and iAmmo > 0) then
				return end
		end
		
		-------------^
		local sSelectThis
		
		-------------
		local vPos = g_localActor:GetPos()
		
		-------------
		local iDist = -1
		local hTarget = self.CURRENT_AIM_TARGET
		if (hTarget) then
			iDist = vector.distance(vPos, hTarget:GetPos()) end
		
		-------------
		local aGoodItems = {}
		local aItems = g_localActor.inventory:GetInventoryTable()
		if (aItems) then
			for i, idItem in pairs(aItems) do
				local hItem = GetEntity(idItem)
				if (hItem and hItem.weapon) then
					local iAmmoCount = hItem.weapon:GetAmmoCount()
					if (iAmmoCount and iAmmoCount > 0) then
						table.insert(aGoodItems, { hItem, iAmmoCount, hItem.weapon:GetDamage(), self:GetAmmoPercentage(hItem) })
					end
				end
			end
		end
		
		-------------
		if (table.count(aGoodItems) == 0) then
			return end
		
		-------------
		table.sort(aGoodItems, function(hA, hB) return ((hA[2] > hB[2]) or (hA[3] > hB[3])) end)
		
		-------------
		local hThisItem = aGoodItems[1][1]
		if (hThisItem) then
			if (hThisItem.class == "SMG") then
				if (iTargetDistance and iTargetDistance >= 20) then
					self:Log(0, "SMG, BUT TARGET IS FAR AWAY!")
					if (table.count(aGoodItems) >= 2 and aGoodItems[2][4] >= 30) then
						self:Log(0, "SWITCHING FROM SMG. FOUND BETTER GUN WITH >= 30% AMMO!!")
						hThisItem = aGoodItems[2][1]
					end
				end
			end
			self:Log(0, "SWITCHING GUN TO BETTER ONE: %s", hThisItem.class)
			return self:SelectItem(hThisItem.class)
		end
		
		-------------
		self:Log(0, "NO ITEM TO SWITCH FOUND !!, USING FISTS !")
		self:SelectItem("Fists")
	end,
	---------------------------
	CheckForBetterGun = function(self)
	
		----------
		if (g_localActor.actor:GetLinkedVehicleId()) then
			return false end
		
		----------
		local iC4Time = self.C4_DETONATION_TIME
		if (iC4Time and ((_time - iC4Time) < 1)) then
			return false end
	
		----------
		local hCurrent = Bot:GetCurrentItem();
		
		----------
		if (ZOMBIE_MODE) then
			if (hCurrent and hCurrent.class ~= "Fists") then
			end
			return
		end
		
		----------
		if (hCurrent and self.followTargetData and self.followTargetData.copiedGunClass == hCurrent.class and (not self.selectSniper or self:IsSniper(hCurrent.class)) and not _BLACKLISTED[hCurrent.class:lower()]) then
			if (self:AmmoLeft(hCurrent)) then
				return false end
		end
		
		----------
		if (hCurrent and hCurrent.class ~= "Fists" and self:AmmoLeft(hCurrent) and not _BLACKLISTED[hCurrent.class:lower()]) then
			return false end
		
		----------
		if (hCurrent and hCurrent.class == "Fists" and self.boxRun and not self._aimEntityId and g_gameRules.class == "PowerStruggle") then
			self:Log(1, "KEEPING FISTS FOR BOX RUN !!")
			return false end
	
		----------
		local aInventory = g_localActor.inventory:GetInventoryTable();
		local hBestWeapon, iWeaponAmmo;
		local bOk, iAmmoLeft = false, 0;
		
		local trashGuns = {};
		
		for i, gunId in ipairs(aInventory or{}) do
			local gun = self:Exists(gunId);
			if (gun and gun.class ~= "Fists" and gun.weapon and not _BLACKLISTED[gun.class:lower()]) then
				bOk, iAmmoLeft = self:AmmoLeft(gun);
				if (not self.selectSniper or self:IsSniper(gun.class)) then
				--	self:SendMsg(gun.class .. " >> " .. iAmmoLeft .. " OK " .. tostring(OK))
					if (bOk and iAmmoLeft and iAmmoLeft > 0 and iAmmoLeft > (iWeaponAmmo or 0)) then
						iWeaponAmmo = iAmmoLeft;
						hBestWeapon = gun;
					elseif (self:IsTrashGun(gun)) then
						table.insert(trashGuns, gun);
					end
				end
				self:Log(15, "Check gun: " .. gun.class .. " >> ammo left >> " .. (iAmmoLeft or 0))
			end
		end
		
		if (timerexpired(self.WEAPON_PICKUP_TIMER, 3)) then
			for i, trashGun in ipairs(trashGuns) do
				bOk = BotAI.CallEvent("ShouldDropItem", trashGun)
				if (bOk == true or isDead(bOk)) then
					g_localActor.actor:DropItem(trashGun.id, 1000, false)
				end
			end
		end
		
		--self:Log(0, "SS = " .. tostring(self.selectSniper))
		if (hBestWeapon and iWeaponAmmo > 0) then
			self:Log(2, "CheckForBetterGun() -> Choosen gun: " .. hBestWeapon.class .. " >> ammo left >> " .. (iWeaponAmmo or 0))
			if (not curr or curr.class ~= hBestWeapon.class) then
				if (not hBestWeapon.selectedBecauseSniping) then
					hBestWeapon.selectedBecauseAmmo = true;
					self:Log(0, "CHOOSING CLASS " .. hBestWeapon.class)
					g_localActor.actor:SelectItemByName(hBestWeapon.class);
				end
			end
		end
		return true;
	end,
	---------------------------
	IsTrashGun = function(self, hWeapon)
		local sAmmoClass = hWeapon.weapon:GetAmmoType()
		if (not sAmmoClass) then
			return false end
			
		local iAmmo = hWeapon.weapon:GetAmmoCount()
		if (not isNumber(iAmmo)) then
			return false end
			
		local iInventoryAmmo = g_localActor.actor:GetInventoryAmmo(sAmmoClass)
		if (not isNumber(iInventoryAmmo)) then
			return false end
			
		return ((iInventoryAmmo + iAmmo) == 0)
	end,
	---------------------------
	AmmoLeft = function(self, gun)
	
	
		if not gun.weapon then return end
	
	--	self:Log(0, gun.class)
	
		local ammoType = gun.weapon:GetAmmoType() or 'NotWeapon';
		local gunAmmo = gun.weapon:GetAmmoCount() or 0;
		local invAmmo = g_localActor.actor:GetInventoryAmmo(ammoType) or 0;
		
		if (gun.class == "AlienMount") then
			return true, 9999;
		end
		
		if (gunAmmo == 0 and invAmmo == 0) then
			return false;
		end
		return true, gunAmmo + invAmmo;
	end,
	---------------------------
	CalcPos = function(self, distance, height)
	
		local pos = self:GetViewCameraPos();
		local dir = self:GetViewCameraDir();
		
		distance = distance or 1;
		height = height or 0;
		
		pos.z = pos.z + height;
		
		ScaleVectorInPlace(dir, distance);
		FastSumVectors(pos, pos, dir);
		
		dir = self:GetViewCameraDir(); --g_localActor:GetDirectionVector(1);
		
		return pos;--, dir;
	end,
	---------------------------
	HasTarget = function(self)
		return self:CheckNextTarget(true);
	end,
	---------------------------
	GetClosestTarget = function(self,d)
		local D=d or 15
		local T
		for i,v in pairs(g_gameRules.game:GetPlayers()or{})do
			local R=self:GetDistance(v)
			if (R<D) then
				T=v
				D=R
		
			end
		end
		return T
	end,
	---------------------------
	StartMoving = function(self, a, b, bSprint, bNoStop)
	
		-----------
		self:Log(5, "TRACEBACK MOVE: %s", debug.traceback()or"x")
	
		-----------
		if (not bot_movement) then
			return end
		
		-----------
		if (not bNoStop) then
			self:StopMovement() end
	
		-----------
		if (self._difficulty > 0) then
			if (bSprint) then
				self:ReleaseKey("sprint")
				self:PressKey("sprint")
			else
				self:ReleaseKey("sprint")
			end
		end
		
		-----------
		self:InvokeMovement(a, b)
		
		-----------
		self.lastSeenMoving = false
		self.moveCase = false
		self.movingBack = false
		self.lastWasDeathPos = false
		self.boxRun = false
		self.movingToVehicle = false
		self.noCamMove = false
		self.unstuckMov = false
		self.followingPlayer = false
		self.runningFromNade = true
	end,
	---------------------------
	CheckTarget = function(self, returnOnly)
		--self:Log(1, "CheckTarget()");
		if (not self.temp._aimEntityId) then
			self:CheckNextTarget();
		else
			if (not self:Exists(self.temp._aimEntityId) or not self:AliveCheck(self:Exists(self.temp._aimEntityId))) then
				self:ClearData();
			elseif (g_gameRules.game:IsInvulnerable(self.temp._aimEntityId)) then
				self:CheckNextTarget()
			else
				self:CheckReload();
			
			end
			
			
		end
		return false;
	end,
	---------------------------
	CheckNextTarget = function(self, returnOnly)
		--self:Log(0, "CHECKING NEXT TARGET ???")
		local all = System.GetEntitiesByClass("Player")or{};
		--local ok ={}
		local god
		if (all and #all >= 1) then
			local closest = {[1]=aim_maxDistance};
			for i, player in ipairs(all) do
				if (player ~= g_localActor and player.actor:GetSpectatorMode() == 0) then
					local hVehicle = GetEntity(player.actor:GetLinkedVehicleId())
					local cansee=self:CanSee(player, true) or (hVehicle and self:CanSee(hVehicle, true))
					local dist = self:GetDistance(player)
				
					if (dist < closest[1]  and cansee ) then -- and 
						
						if (self:CanSetAsTarget(player)) then
							if (g_gameRules.game:IsInvulnerable(player.id)) then
								god = player
								self:Log(0,"NOT USING GOT!!")
							else
								closest[1] = self:GetDistance(player);
								closest[2] = player;
							end
						end
					end
					--if cansee and dist < aim_maxDistance then
					--	table.insert(ok, {p=player,d=dist,hp=player.actor:GetHealth()})
					--end
				end
			end
			if not closest[2] and god~=nil then 
				closest[2] = god 
			end
			if (closest[2] ) then
			
				--ok =table.sort(ok, function(a,b) return a.hp>b.hp end)
				--for i,v in pairs(ok or {})  do
				--	
				--end
			
				if (not returnOnly) then
					self:Log(0, "New Target >> " .. closest[2]:GetName() .. " | Distance: " .. closest[1]);
					self.temp._aimEntityId = closest[2].id;
				end
				return true;
			end
		end
	end,
	---------------------------
	Prone = function(self, desiredTime, force)
		if (not self:CarryingHeavyGun()) then
			if ((force and g_localActor.actorStats.stance~=2) or (not self._proneTime and not self:Underwater())) then
				self._proneTimer = desiredTime or 1;
				self._proneTime = _time;
				g_localActor.actor:SimulateInput('prone', 1, 1);
				self.STOP_PRONE_IF_DEAD=false;
			end
		end
	end,
	---------------------------
	StopProne = function(self, skipCheck)
		if (self._proneTime or skipCheck) then
			self._proneTime = nil;
			self._proneTimer = nil;
			self.lastStopProne = _time;
			g_localActor.actor:SimulateInput('prone', 1, 0);
		end
		
	end,
	---------------------------
	Exists = function(self, Id)
		return (Id and System.GetEntity(Id) or nil);
	end,
	---------------------------
	RoundNumber = function(self, number)
		return math.round(number)	
	end,
	---------------------------
	GetAimPos = function(self, from)
		local dir = self:GetViewCameraDir();
		local hits = Physics.RayWorldIntersection((from or self:GetViewCameraPos()), { x=dir.x*8192, y=dir.y*8192, z=dir.z*8192 }, 8192, ent_all, g_localActor.id, nil, g_HitTable);
		local hitData = g_HitTable[1];
		if (hits and hits > 0 and hitData) then
			return hitData.pos;
		else
			return { x= 0, y = 0, z = 0 };
		end
	end,
	---------------------------
	GetAimedEntity = function(self)
		local dir = self:GetViewCameraDir();
		local hits = Physics.RayWorldIntersection(self:GetViewCameraPos(), { x=dir.x*8192, y=dir.y*8192, z=dir.z*8192 }, 8192, ent_all, g_localActor.id, nil, g_HitTable);
		local hitData = g_HitTable[1];
		if (hits and hits > 0 and hitData) then
			return hitData.entity;
		else
			return nil;
		end
	end,
	---------------------------
	AliveCheck = function(self, target)
		if (not target) then
			return false end
			
		if (not target.actor) then
			return false end
			
		if (target.actor:GetHealth() <= 0) then
			return false end
			
		if (target.actor:GetSpectatorMode() ~= 0) then
			return false end
			
		if (target.actor:GetPhysicalizationProfile() ~= "alive") then
			return false end
	
		return true
	end,
	---------------------------
	GetDistance = function(self, a, b)
		
		local _a, _b, _d;
		local _c = g_localActor:GetPos();
		
		if (type(a)=="userdata") then
			a=System.GetEntity(a);
		end
		if (type(b)=="userdata") then
			b=System.GetEntity(b);
		end
		
		
		if (not a) then
			_a = { x = _c.x, y = _c.y, z = _c.z };
		elseif (a.id) then
			_d = (a.GetPos and a:GetPos() or {x=a.x,y=a.y,z=a.z});
			_a = { x = _d.x, y = _d.y, z = _d.z };
		else
			_a = { x = a.x, y = a.y, z = a.z };
		end
		if (not b) then
			_b = { x = _c.x, y = _c.y, z = _c.z };
		elseif (b.id) then
			_d = (b.GetPos and b:GetPos() or {x=b.x,y=b.y,z=b.z});
			_b = { x = _d.x, y = _d.y, z = _d.z };
		else
			_b = { x = b.x, y = b.y, z = b.z };
		end
		
		local dx, dy, dz = _a.x - _b.x, _a.y - _b.y, _a.z - _b.z
		local dist = math.sqrt(dx * dx + dy * dy + dz * dz);

		return dist;
	end,
	---------------------------
	Dot = function(self, a, b)
		return a.x * b.x + a.y * b.y + a.z * b.z;
	end,
	---------------------------
	Angle = function(self, a, b)
		local dt = self:Dot(a, b)
		local ad = math.sqrt(self:Dot(a, a)) * math.sqrt(self:Dot(b, b))
		return math.acos(dt / ad) * 180 / math.pi;
	end,
	---------------------------
	GetTgtDist = function(self)
		return self.temp._aimEntityId and self:GetDistance(self.temp._aimEntityId) or "causeError";
	end,
	---------------------------
	GetTargetDistance = function(self)
		local hEntity = GetEntity(self.temp._aimEntityId)
		if (not hEntity) then
			return end
			
		return vector.distance(hEntity:GetPos(), g_localActor:GetPos())
	end,
	---------------------------
	IsPositionToRight = function(self, vDirection, vSource, vTarget)
	
		local vDirLeft = vector.new(vDirection)
		vector.rotate_90z(vDirLeft)
		
		local vDirRight = vector.new(vDirection)
		vector.rotate_minus90z(vDirRight)
	
		local vPos_A = vector.add(vector.new(vSource), vector.scale(vDirLeft, 2))
		local vPos_B = vector.add(vector.new(vSource), vector.scale(vDirRight, 2))
		
		
		-- self:Log(0,"%s", Vec2Str(vDirection))
		-- self:Log(0,"%s", Vec2Str(vDirLeft))
		-- self:Log(0,"%s", Vec2Str(vDirRight))
		-- Particle.SpawnEffect("explosions.flare.a", vPos_A, vectors.up, 0.1)
		-- Particle.SpawnEffect("explosions.flare.a", vPos_B, vectors.up, 0.1)
		
		local iDist_A = vector.distance(vPos_A, vTarget)
		local iDist_B = vector.distance(vPos_B, vTarget)
		
		-- self:Log("is pos to right: %s", ((iDist_A < iDist_B) and "ja" or "nein"))
		return (iDist_A < iDist_B)
	end,
	---------------------------
	ProcessLeaning = function(self, vTargetPos)
		local bRight = self:IsPositionToRight(g_localActor:GetDirectionVector(), g_localActor:GetPos(), vTargetPos) --checkVar(, vector.add(g_localActor:GetPos(), vector.scale(self:GetViewCameraDir(), 20))))
		--self:Lean((bRight))
	end,
	---------------------------
	ProcessAimedTarget = function(self, bSkipCamera)
		-- self.lastProccessAimTargetTime = _time;
		
		local hTarget = GetEntity(self.temp._aimEntityId)
		if (hTarget) then
			if (self:CanSee(hTarget, bSkipCamera) and not skipCanSee) then
				local vTarget = hTarget:GetPos()
				if (hTarget.vehicle) then
					vTarget = hTarget:GetCenterOfMassPos()
				else
					local sAimBone = aim_aimBone
					if (sAimBone == "random") then
						local aBones = { "Pelvis", "Head", "Spine" }
						if (not self.RANDOM_AIM_BONE) then
							self.RANDOM_AIM_BONE = getrandom(aBones) end
						
						sAimBone = self.RANDOM_AIM_BONE
					end
					
					local hCurrent = Bot:GetCurrentItem()
					if (hCurrent and (hCurrent.class == "GaussRifle" or hCurrent.class == "DSG1")) then
						sAimBone = "Pelvis" end
						
					vTarget = hTarget:GetBonePos("Bip01 " .. sAimBone)
				end
				
				if (BOT_AIM_ACCURACY < 100 and not self._MELEETIME and self:GetTargetDistance() > 5) then
					
					local aSpread = { 0, 0, 0 }
					local iSpread = math.min(99, 100-BOT_AIM_ACCURACY)
					if (iSpread < BOT_AIM_ACCURACY_MIN) then
						iSpread = BOT_AIM_ACCURACY_MIN end
					
					aSpread[1] = math.random(1, iSpread) / 100
					aSpread[2] = math.random(1, iSpread) / 100
					aSpread[3] = math.random(1, iSpread) / 100
					
					vector.sub(vTarget, vector.amake(aSpread))
					
					self:Log(1, "Aim Accuracy: %f (X = %f, Y = %f, Z = %f)", iSpread, aSpread[1], aSpread[2], aSpread[3])
				end

				self:ProcessLeaning(vTarget)
				self:SetCameraTarget(vTarget)
				self:ProcessShooting(vTarget)
			else
				self:StopFire()
				self:ClearData()
				self:Log(0, "Can't see target, clearing data ... ")
			end
		end
		
		--[[
		local skipViewCamDir = bSkipCamera
		local targetId = self.temp._aimEntityId;
		if (targetId) then
			local target = System.GetEntity(targetId);
			if (target and self:CanSee(target, skipViewCamDir) and not skipCanSee) then
				local tgtPos = target:GetPos();
				if (target.vehicle) then
					tgtPos = target:GetCenterOfMassPos();
				else
					local aimBone = aim_aimBone;
					if (aimBone == "random") then
						local randomBones = {
							"pelvis";
							"head";
							"spine";
						};
						if (not self.randomPickedBone) then
							self.randomPickedBone = randomBones[math.random(#randomBones)];
							self:Log(3, "Bone selection is random, selected random bone: " .. self.randomPickedBone .. " out of " .. self:GetTableNum(randomBones) .. " others");
						end
						aimBone = self.randomPickedBone;
					end
					
					local hCurrent = Bot:GetCurrentItem()
					if (hCurrent and (hCurrent.class == "GaussRifle" or hCurrent.class == "DSG1")) then
						aim_aimBone = "Head" end
					
					self:Log(9, "[ProcessAimedTarget] AIM BONE = " .. aim_aimBone)
					tgtPos = target:GetBonePos("Bip01 " .. aimBone) or tgtPos;
				end
				
				local minusX, minusY, minusZ = 0, 0, 0;
				if (BOT_AIM_ACCURACY < 100 and not self._MELEETIME and self:GetTgtDist() > 5) then
					local accu = math.min(99, 100-BOT_AIM_ACCURACY);
					if (accu<BOT_AIM_ACCURACY_MIN) then
						accu=BOT_AIM_ACCURACY_MIN;
					end
					local minusX = math.random(1, accu)/100;
					local minusY = math.random(1, accu)/100;
					local minusZ = math.random(1, accu)/100;
					self:Log(1,"accu: " .. accu .. " AMIN: " ..BOT_AIM_ACCURACY_MIN .. " miss: " .. minusX .. " , " .. minusY .. ", " .. minusZ)
					
					tgtPos.x = tgtPos.x - minusX;
					tgtPos.y = tgtPos.y - minusY;
					tgtPos.z = tgtPos.z - minusZ;
					
				end
			--		self:Log(0, "OK >> " .. self:GetDistance(tgtPos) )
				self:ProcessLeaning(tgtPos)
				self:SetCameraTarget(tgtPos);
				self:ProcessShooting(tgtPos);
			else
				self:StopFire();
				self:ClearData();
				self:Log(1, "Can't see target, clearing data ... ");
			end
		end
		--]]
		
	end,
	---------------------------
	GetAimBonePos = function(self, target)
		local tgtPos = target:GetPos();
		if (target.vehicle) then
			tgtPos = target:GetCenterOfMassPos();
		else
			local aimBone = aim_aimBone;
			if (aimBone == "random") then
				local randomBones = {
					"pelvis";
					"head";
					"spine";
				};
				if (not self.randomPickedBone) then
					self.randomPickedBone = randomBones[math.random(#randomBones)];
					self:Log(3, "Bone selection is random, selected random bone: " .. self.randomPickedBone .. " out of " .. self:GetTableNum(randomBones) .. " others");
				end
				aimBone = self.randomPickedBone;
			end
			self:Log(9, "[GetAimBonePos] AIM BONE = " .. aim_aimBone)
			tgtPos = target:GetBonePos("Bip01 " .. aimBone) or tgtPos;
			if (not tgtPos) then
				tgtPos=target:GetBonePos("Bip01 head");
			end
		end
		return tgtPos;
	end,
	---------------------------
	CanThrowNade = function(self)
		if ((not self.lastNade  or (_time - self.lastNade >= 12 and self:GetDistance(self:Exists(self.temp._aimEntityId)) > 15 and self:GetDistance(self:Exists(self.temp._aimEntityId)) < 35)) and not self.isBoxing) then
			if (g_localActor.actor:GetInventoryAmmo('explosivegrenade')>=1) then
				self.lastNade = _time;
				return true;
			end
		end
		return false;
	end,
	---------------------------
	StartFire = function(self)
	
		--------------
		self:CheckForBetterGunEx()
	
		--------------
		local idWeapon = self.__shootingWeapon
		if (not idWeapon) then
			return self:Log(0, "No Weapon for Firing!") end
		
		--------------
		local hWeapon = GetEntity(idWeapon)
		if (not hWeapon) then
			return self:Log(0, "Weapon for Firing was not found") end
			
		--------------
		local vPos = g_localActor:GetPos()
			
		--------------
		local idVehicle = g_localActor.actor:GetLinkedVehicleId()
			
		--------------
		if (BOT_THROW_NADES and (not idVehicle and self:CanThrowNade())) then
			self:Log(0, "Throwing a Grenade!")
			g_localActor.actor:SimulateInput("grenade", 1, 1)
			Script.SetTimer(1, function()
				g_localActor.actor:SimulateInput("grenade", 2, 1) end)
		else
			local hTarget = GetEntity(self.temp._aimEntityId)
			if (hTarget) then
				if (self:IsInGodMode(hTarget)) then
					self:Log(0, "TARGET IS INVULNERABLE !")
					if (getrandom(100) >= 65) then
						return end
				else
					local iDistance = vector.distance(vPos, hTarget:GetPos())
					if (iDistance < 2 and not self.isBoxing) then
						self._oldAimBone = self._oldAimBone or aim_aimBone;
						--self:SendMsg("!!aimbone now head!!")
						aim_aimBone = "head";
						self:SuitMode(self.STRENGTH);
						self._MELEETIME = true;
						self.MELEE_TIMER = timerinit()
						self:StopProne()
						if (not self.boxTime_melee or _time - self.boxTime_melee >= BOT_MELEE_DELAY) then
						--	self:Log(0, "Boxing!");
						--self:Log(0, "------------------------- MELEE >>>");
							self:PressKey("special", BOT_MELEE_DELAY);
							self.boxTime_melee = _time;
						end
							
						return 
					else
						aim_aimBone = self._oldAimBone or aim_aimBone or "head";
						--	self:SendMsg("aimbone now old " .. aim_aimBone)
						self._oldAimBone = nil;
						self._MELEETIME = false;
					end
				end
			else
				self._MELEETIME = false
			end
			if (not self.isBoxing or (not self.boxTime or _time - self.boxTime >= BOT_BOX_DELAY)) then
				self.boxTime = _time
					
				self:Log(0, "$6------------------------- FIRE >>>")
				g_localActor.actor:SimulateInput('attack1', 1, 1)
				self.firing = true
				self.IN_FIRING = true
			end
		end
	end,
	---------------------------
	IsInGodMode = function(self, hTarget)
		return g_gameRules.game:IsInvulnerable((hTarget or g_localActor).id)
	end,
	---------------------------
	StopFire = function(self)
	
		if (self.SHOOTING_THREATS) then
			return end
	
		if (not timerexpired(self.RADAR_SELECT_TIME, 1)) then
			return end
	
		if (g_localActor and (self.__shootingWeapon or g_localActor.actor:GetLinkedVehicleId())) then
			g_localActor.actor:SimulateInput('attack1', 2, 1);
			self:Log(0, "FIRE :: STOP >>" .. (self.isBoxing and "melee" or "attack1"))
			--self:CheckReload() -- nononono
		end
		self:Log(0, "CAME FROM FUCKIN: %s", (debug.traceback()or"NO TB"))
		self.firing = false;
		self.IN_FIRING = false;
	end,
	---------------------------
	PlayersNear = function(self,r,p)
		local p=p or g_localActor:GetPos();
		local near = {};
		for i, player in ipairs(g_gameRules.game:GetPlayers()or{}) do
			if (self:GetDistance(player,p) < (r or 10) and player.id~=g_localActorId) then
				table.insert(near,player)
			end
		end
		return #near>0 and near,near[1],near;
	end,
	---------------------------
	AmmoDryButCanReload = function(self)
		local w = self.__shootingWeapon
		if (w and w.class ~= "Fists") then
			local count = w.weapon:GetAmmoCount()
			if (not count) then return end
			local clip = w.weapon:GetClipSize()
			if (not clip) then return end
			clip = clip - 1
			local ammo = g_localActor.inventory:GetAmmoCount(w.weapon:GetAmmoType())
			if (not ammo) then return end
			
			
			--self:Log(0, "class = %s, ammo = %d, clip = %d, count = %d", w.weapon:GetAmmoType(), ammo, clip, count)
			
			if (count < clip / 3) then
				--self:Log(0, "clip critical !")
				if (ammo + count >= clip) then
					--self:Log(0, "reload would work!")
					return true
				end
			end
		end
		
		return false
	
	end,
	---------------------------
	CheckReloadEx = function(self, bForce, hItem)
	
		local hItem = hItem or self.__shootingWeapon or self:GetCurrentItem()
		if (not self:RequiresReload(hItem.class)) then
			self:Log(0, "WEAPON DOES NOT REQUIRE RELOAD")
			return false end
	
		if (not self:CanReloadWeapon(hItem) and timerexpired(self.WEAPON_PICKUP_TIMER, 2)) then
			self:Log(0, "CANNOT RELOAD WEAPON!")
			self:DropItem(hItem)
			return false end
	
		local hItem = hItem or self.__shootingWeapon
		if (not hItem) then
			self:Log(0, "WEAPON FOR CHECK RELOAD EX NOT FOUND")
			return false end
	
		local iAmmo = hItem.weapon:GetAmmoCount()
		if (not iAmmo) then
			self:Log(0, "AMMO FOR CHECK RELOAD EX NOT FOUND")
			return false end
	
		local bReloadOK = bForce or (iAmmo == 0)
		if (bReloadOK) then
			self:Log(0, "FORCE RELOADING !")
			self.LAST_FORCE_RELOAD_TIMER = timerinit()
			return true, hItem.weapon:Reload() end
	
		bReloadOK = (timerexpired(self.LAST_RELOAD_TIMER, 3) and not self:GetNearbyPlayers(8))
		if (bReloadOK) then
			self:Log(0, "ALL OK, RELOADING !")
			self.LAST_RELOAD_TIMER = timerinit()
			return true, hItem.weapon:Reload() end
	
		return true
	end,
	---------------------------
	GetNearbyPlayers = function(self, iRadius, vPos)
	
		------------
		local iRadius = checkNumber(iRadius, 15)
		
		------------
		local vPos = checkVar(vPos, g_localActor:GetPos())
		
		------------
		local aNearby = {}
		
		------------
		local aPlayers = GetPlayers(true)
		for i, hPlayer in pairs(aPlayers) do
			if (hPlayer.id ~= g_localActorId and self:AliveCheck(hPlayer)) then
				local iDistance = vector.distance(vPos, hPlayer:GetPos())
				if (iDistance < iRadius) then
					table.insert(aNearby, hPlayer)
				end
			end
		end
		
		------------
		if (table.count(aNearby) > 0) then
			return aNearby end
			
		------------
		return
	end,
	---------------------------
	CheckReload = function(self, bForce)
	
		----------
		local iReloadTimer = 6
		if (not self:PlayersNear(20)) then
			iReloadTimer = 2 end
		
		----------
		if (not bForce and (self:PlayersNear(8) and not self:AmmoDryButCanReload()) and self.__shootingWeapon and self.__shootingWeapon.weapon:GetClipSize() and self.__shootingWeapon.weapon:GetAmmoCount() and self.__shootingWeapon.weapon:GetAmmoCount()>=self.__shootingWeapon.weapon:GetClipSize()/3) then
			return
		end
		
		----------
		if (self.__shootingWeapon and timerexpired(self.LAST_RELOAD_TIMER, iReloadTimer)) then --  reduced from 8 to 6, now changed to 3 if no enemies near
			
			self.LAST_RELOAD_TIMER = timerinit()
			self:StopSprint()
			self:StopFire()
			Script.SetTimer(1, function() -- so next frame so game registers our STOP SPRINT 
				self.__shootingWeapon.weapon:Reload()
			end);
			self:Log(3, "$8RELOADING WEAPON !!!");
		elseif (bForce and not self.firing) then
			local curr = Bot:GetCurrentItem();
			if (curr and self:RequiresReload(curr.class) and self:CanReloadWeapon(curr)) then
				--self:Log(1, curr.weapon:GetAmmoCount() .. "<" .. curr.weapon:GetClipSize() + 1)
				if (curr.weapon:GetAmmoCount() < curr.weapon:GetClipSize()-2) then -- + 1 = bullet in chamber ;)
					if (not self.forceReloading) then
						curr.weapon:Reload();
						self.forceReloading = { _time, curr.class }
						self:Log(3, "$8FORCE RELOADING WEAPON !!!")
					end
				else
					self.forceReloading = nil;
					self:Log(3, curr.class .. " DOES NOT NEED FORCE RELOAD - AMMO FULL");
				end
			end
		end
	end,
	---------------------------
	CanReloadWeapon = function(self, weapon)
		local sAmmo = weapon.weapon:GetAmmoType()
		if (not sAmmo) then
			return false end
			
		local iAmmo = g_localActor.actor:GetInventoryAmmo(weapon.weapon:GetAmmoType());
		return (iAmmo and iAmmo >= 1)
	end,
	---------------------------
	RequiresReload = function(self, weaponClass)
		local weaponList = {
			['fists'] = false;
			['alienmount'] = false;
			['shiten'] = false;
		--	['golfclub'] = false;
		};
		local needs = weaponList[weaponClass:lower()];
		if (needs == nil) then
			needs = true;
		end
		return needs;
	end,
	---------------------------
	OnHit = function(self, hit)
		if (hit.target == g_localActor) then-- and hit.shooter ~= g_localActor) then
			local weapon = hit.weapon;
			--if (not self.lastJump or _time - self.lastJump >= 13) then
			--	self:InvokeJump();
			--	self.lastJump = _time;
			--end
			--self:SendMsg("OnHit "..tostring(self:CanSetAsTarget(hit.shooter, true)));
			if (self:CanSetAsTarget(hit.shooter, true) and not self.temp._aimEntityId) then
				self:SetCameraTarget(hit.shooter:GetPos(), 25);
				self.temp._aimEntityId = hit.shooter.id;
			end
		end--]]
	end,
	
	---------------------------
	-- OnExplosion
	
	OnExplosion = function(self, explosion)
		if (explosion) then
		
		end
	end,
	
	---------------------------
	-- GetRepu
	
	GetRepu = function(self, id)
		local r;
		for j = 0, 100 do-- in pairs(_REPUTATIONLIST) do
			if (_REPUTATIONLIST[j] and _REPUTATION[id]>=j) then
				r = _REPUTATIONLIST[j];
			end
		end
		return r;
	end,
	
	---------------------------
	-- OnKilled
	
	OnKilled = function(self, playerId, shooterId, weaponClassName, damage, material, hit_type)
	
		local hPlayer = GetEntity(playerId)
		local hShooter = GetEntity(shooterId)
		if (hPlayer == g_localActor) then
			self:Log(0, "Bot Died. Resetting Path data !")
			self:PathfindingReset()
		end
	
		local player, shooter = System.GetEntity(playerId), System.GetEntity(shooterId);
		if (player and shooter) then
			
			self:Log(0, shooter:GetName() .. " >> killed >> " .. player:GetName() .. " | Weapon >> " .. weaponClassName);
			player.lastKilledBy = shooterId;
			if (player.id ~= shooter.id and shooter.id == g_localActor.id and player.actor and player.actor:IsPlayer()) then
				local insultThem = self:ShouldSendMsg(16);
				_REPUTATION[player.id] = math.min(100, math.max(0, (_REPUTATION[player.id] or 50) + 1)); 
				self:Log(0, player:GetName() .. " >> Reputation Increased by 1 >> total " .. _REPUTATION[player.id] .. ", (" .. self:GetRepu(playerId) .. ")");
				if (insultThem and (self._difficulty < 0 or (self._difficulty >0 and math.random(3)==2))) then
					local msg = self:GetRandomMsgByReputationLevel(_REPUTATION[player.id], 'killed')
					self:SendMsg(msg);--self:GetRandomMsg(msg));
				end
				if (player._lastItem and System.GetEntity(player._lastItem.id) and self:CanSeePosition(player._lastItem:GetPos()) and player._lastItem.class ~= Bot:GetCurrentItem().class) then
					self:GoGetGun(player._lastItem);
					self._STEALMOVE=true
				end
				
			end
			if (player.id == g_localActorId and shooterId ~= g_localActorId) then
				_REPUTATION[shooterId] = math.min(100, math.max(0, (_REPUTATION[shooterId] or 50) - 1));
				self:Log(0, player:GetName() .. " >> Reputation Decreased by 1 >> total " .. _REPUTATION[shooterId] .. ", (" .. self:GetRepu(shooterId) .. ")");
				local sendMsg = self:ShouldSendMsg(17);
				local case = "_normal";
				if (self.lastReload and _time - self.lastReload < 3) then
					case = "_reload";
				elseif (self:FromBehind(shooter)) then
					case = "_behind";
				elseif (self:FromAbove(shooter:GetPos())) then
					case = "_above";
				elseif (self:FromBelow(shooter:GetPos())) then
					case = "_below";
				end
				
				if (self._difficulty == -1) then
					case = "_fortnite";
				end

				if (sendMsg) then
					self:SendMsg(self:GetRandomMsg(self.msgs._died[case]));
				end
				
				
			end
		end
		
	end,
	
	---------------------------
	-- GetVehicle
	
	GetVehicle = function(self)
		return GetEntity(g_localActor.actor:GetLinkedVehicleId())
	end,
	
	---------------------------
	-- ProcessShooting
	
	ProcessShooting = function(self, tPos)
		if (self:GetVehicle()) then
			return self:StartFire() end
			
		if (self.isBoxing) then
			self.__shootingWeapon = Bot:GetCurrentItem();
			self:StartFire();
			
		else
			local weapon = Bot:GetCurrentItem();
			if (weapon) then
				if (not self:NeedNewWeapon(weapon)) then
					self:Log(1, "FIRING!");
					self.__shootingWeapon = weapon;
					self:StartFire();
				else
					self:Log(1, "Need new weapon!");
					self:SelectNewItem();
				end
			end
		end
	end,
	
	---------------------------
	-- GetAmmo
	
	GetAmmo = function(self, hWeapon, sAmmo, skipOtherAmmoCheck)
	
		------------
		local iAmmo = checkNumber(self:GetInventoryAmmo(sAmmo), 0) + checkNumber(hWeapon.weapon:GetAmmoCount(), 0)
		if (iAmmo == 0 and (sAmmo == "incendiarybullet" and not bSkipAmmoCheck)) then
			iAmmo = checkNumber(self:GetInventoryAmmo("fybullet"), 0) end
			
		------------
		return (iAmmo)
	end,
	
	---------------------------
	-- OnlyFists
	
	OnlyFists = function(self)
	
		------------
		local hWeapon = Bot:GetCurrentItem()
		
		------------
		local iChecked = 0
		local aCheckList = {
			"SMG",
			"FY71",
			"SCAR",
			"DSG1",
			"SOCOM",
			"TACGun",
			"Shutgun",
			"Hurricane",
			"AlienMount",
		}
		
		------------
		for i, sClass in pairs(aCheckList) do
			local hGun = GetEntity(self:HasItem(sClass))
			if (hGun) then
				local iAmmo = self:GetInventoryAmmo(hGun)
				if (not self:RequiresReload(sClass) or (iAmmo and iAmmo >= 1)) then
					return false end
			end
			iChecked = iChecked + 1
		end
		
		------------
		return true
	end,
	
	---------------------------
	-- NeedNewWeapon
	
	NeedNewWeapon = function(self, hWeapon)
		
		------------
		if (not hWeapon) then
			return true end
		
		------------
		if (not hWeapon.weapon) then 
			return true end
		
		------------
		if (_BLACKLISTED[hWeapon.class:lower()]) then
			return true end
		
		------------
		if (not self:RequiresReload(hWeapon.class)) then
			return false
		elseif (self:GetAmmo(hWeapon, hWeapon.weapon:GetAmmoType()) >= 1) then
			self:Log(2, "still ammo");
			return false
		elseif (self:OnlyFists()) then
			self:Log(2, "Only fists");
			return true
		end
		
		------------
		self:Log(2, "FUCK YES!!! fists");
		return true
	end,
	
	---------------------------
	-- OnShoot
	
	OnShoot = function(self, player, weapon, pos, dir, isBot)
	
		if (isBot) then
			self.LAST_WEAPON_SPREAD = weapon.weapon:GetLastSpread()
			self.LAST_FIRE_TIMER = timerinit()
		end
	end,
	
	---------------------------
	-- MightBeShootingAtUs
	
	MightBeShootingAtUs = function(self, player, gun, hit)
		if (self:GetDistance(hit) < 3) then
			self:Log(1, "YES CLOS EHIT!")
			return true;
		end
		local otherHit = self:RayCheck(player.actor:GetHeadPos(), player.actor:GetHeadDir(), 1000, player.id)
		if (otherHit and ((otherHit.entity and otherHit.entity.id == g_localActor.id) or (self:GetDistance(otherHit.pos) < 3))) then
			self:Log(1, "YES CLOS EHIT 22!")
			return true;
		end
		return false;
	end,
	
	---------------------------
	-- RayCheck
	
	RayCheck = function(self, pos, dir, dist, entId)
		local hits = Physics.RayWorldIntersection(pos, vecScale(dir, dist), dist, ent_all, entId, nil, g_HitTable);
		local hitData = g_HitTable[1];
		if (hits and hitData and hits>0) then
			if (hitData.entity) then 
				self:Log(1, "RC=" .. hitData.entity:GetName())
			end
			return hitData;
		end
	end,
	
	---------------------------

	recordJump = {};
	
	---------------------------
	-- OnPlayerJump
	
	OnPlayerJump = function(self, player, isBot, channelId)
		player._jumpTime = _time;
		if (not self.recordJump[player.id]) then
			self.recordJump[player.id] = true;
		end
	end,
	
	---------------------------
	-- GetFollowerPosition
	
	GetFollowerPosition = function(self)
		return (self.followTarget and self.followTarget:GetPos() or nil);
	end,
	
	---------------------------
	-- SetFollowTarget
	
	SetFollowTarget = function(self, player)
		local player = type(player)=="table" and player or System.GetEntityByName(player)
		if (player and player.id ~= g_localActor.id) then
			
			if (self.followTarget and self.followTarget == player) then
				self.followTarget = nil;
				return self:Log(0, "Removing follow target >> " .. player:GetName())
			end
			
			self:Log(0, "Setting Follow Target >> " .. player:GetName());
			self.followTarget = player;
			if (self.temp._aimEntityId and self.temp._aimEntityId == player.id) then
				self:ClearData()
			end
		else
			self:Log(0, "Can't set localActor as FollowTarget !!");
		end
	--	bot_enabled=false
	end,
	
	---------------------------
	-- TestFunction
	
	TestFunction = function(self, player)
	end,
	
	---------------------------
	-- SetGruntMode
	
	SetGruntMode = function(self, boolean)
	
		self.gruntMode = (bEnable == true)
		self:Log(0, "Grunt mode: %s ", (self.gruntMode and "Enabled" or "Disabled"));
		self:Reload(); -- reload mod data to restore globals and cvars
	end,
	
	---------------------------
	-- CanSeeCloaked
	
	CanSeeCloaked = function(self, player)
	
		if (not BotAI or not BotAI.CanSeeCloaked) then
			return true end
	
		return BotAI:CanSeeCloaked(player)
	end,
	
	---------------------------
	-- SetAntiMode
	
	SetAntiMode = function(self, sPlayerName)
		if (ANTI_MODE or sPlayerName == "") then
			ANTI_MODE = false
			ANTI_NAME = ""
			return
		end
		ANTI_MODE = true
		ANTI_NAME = sPlayerName
	end,
	
	---------------------------
	-- CanSetAsTarget
	
	CanSetAsTarget = function(self, player, onHit, dist)
	
		---------------------------
		if (not bot_hostility) then
			return false end
	
		---------------------------
		if (not player) then
			return false end
	
		---------------------------
		self:CheckAutoFollow(player)
		
		---------------------------
		if (not self.gruntMode and self.quenedFollowTarget and player.id == self.quenedFollowTarget.id) then
			if (not self.followTarget) then
				return false, self:SetFollowTarget(player)
			end
			self.quenedFollowTarget = nil
		end
		
		---------------------------
		local sPlayerName = player:GetName()
		
		---------------------------
		local sAntiName = string.lower(ANTI_NAME or "")
		if (ANTI_MODE and ANTI_NAME) then
			if (_ANTI[player.id] or string.lower(sPlayerName) == sAntiName) then
				_ANTI[player.id] = true
				return true
			else
				return false
			end
		end
		
		---------------------------
		local bSameTeam = g_gameRules.game:GetTeam(g_localActor.id) == g_gameRules.game:GetTeam(player.id)
		
		---------------------------
		if (g_gameRules.class ~= "InstantAction" and bSameTeam) then
			return false end
		
		---------------------------
		if (self.followTarget and self.followTarget.id == player.id) then
			return false end
		
		---------------------------
		local sTeamName = Config.BotTeamName
		if (bot_teaming and string.sub(sPlayerName, 0, string.len(sTeamName)) == sTeamName and not _BLACKLISTED_TEAM[player.id]) then
			return false end
		
		---------------------------
		if (ZOMBIE_KILLER_MODE) then
			if (string.find(sPlayerName, "^%[Z%]")) then
				return true 
			end	
			return false
		end
		
		---------------------------
		if (ZOMBIE_MODE and string.find(sPlayerName, "^%[Z%]")) then
			return false end
		
		---------------------------
		if (self.blindTime and _time - self.blindTime < 1) then
			return false end
		
		---------------------------
		if (not self:AliveCheck(player)) then
			return false end
		
		---------------------------
		if (onHit) then
			return true end
		
		---------------------------
		if (player.actor:GetNanoSuitMode() == 2 and not self:CanSeeCloaked(player)) then
			return false end
		
		if (self:GetDistance(player) < (self._difficulty>0 and 6 or 2) and self:FromBehind(player)) then -- let's still attack players who run behind us, shall we? :)
			return true end
		
		---------------------------
		if (BOT_USE_NEW_FIELDOFVIEW and self:GetDistance(player) > 5) then
			if (not self:WithinAngles(player, BOT_FIELD_OF_VIEW)) then
				return false end
		end
		
		---------------------------
		self:Log(1, "Attacking %s", sPlayerName)
		return true;
	end,
	
	---------------------------
	-- SelectNewItem
	
	SelectNewItem = function(self)
		self:Log(0, "Change Current Item")
		local weapon = Bot:GetCurrentItem()
		local toCheck = {
			"TACGun";
			"AlienMount";
			"Shutgun"; -- prioritize
			"GaussRifle";
			"FY71";
			"SMG";
			"SCAR";
			"DSG1";
			"SOCOM";
			"Hurricane";
		};
		local checked = 0;
		local ok,sgbad
		sgbad=false
		for i, class in pairs(toCheck) do
			ok=true
			if (class == "Shotgun" and self.temp._aimEntityId and self:GetDistance(System.GetEntity(self.temp._aimEntityId)) > 20) then
				ok=false
				sgbad=true
			end
			if (ok and self:Exists(g_localActor.inventory:GetItemByClass(class)) and not _BLACKLISTED[class:lower()]) then
				local ammoTpe = self:Exists(g_localActor.inventory:GetItemByClass(class)).weapon:GetAmmoType();
				if (ammoTpe == "scargrenade" and g_localActor.actor:GetInventoryAmmo(ammoTpe) == 0) then
					ammoTpe = "fybullet";
				end
				if (ammoTpe == "incendiarybullet" and g_localActor.actor:GetInventoryAmmo(ammoTpe) == 0) then
					ammoTpe = "fybullet";
				end
				if (g_localActor.inventory:GetItemByClass(class) and (self:GetAmmo(weapon, ammoTpe) >= 1 or not self:RequiresReload(class))) then
					
					self:Log(1, "$4Has: " .. class .. ", ammo count: " .. self:GetAmmo(weapon, ammoTpe))
				--	if (weapon.class ~= class) then
						return g_localActor.actor:SelectItemByName(class);
					--end
				end
			end
			checked = checked + 1;
		end
		if (checked == self:GetTableNum(toCheck)) then
			-- out of ammo. completely. use Fists.
			if (weapon and weapon.class ~= "Fists") then
				return g_localActor.actor:SelectItemByName("Fists");
			end
		end
	end,
	
	---------------------------
	-- GetTableNum
	
	GetTableNum = function(self, t)
		return table.count(t)
	end,
	
	---------------------------
	-- OnRevive
	
	OnRevive = function(self, hEntity)

		----------------------
		if (self.LAST_SEEN_ENTITYID == hEntity.id) then
			self:ResetLastSeen()
		end
		
		----------------------
		self.spawnTime = _time
		
		
		----------------------
		if (_FOLLOWGRUNT) then
			System.RemoveEntity(_FOLLOWGRUNT.id)
			_FOLLOWGRUNT = nil
		end
		
		----------------------
		if (EXPERIMENTAL_AI_FOLLOWING) then
			Script.SetTimer(1, function()
				
				local hPoint = { 1, nil }
				for i, hSpawnPoint in pairs(System.GetEntitiesByClass("SpawnPoint") or {}) do
					local iDistance = self:GetDistance(hSpawnPoint)
					if (iDistance < hPoint[1]) then
						hPoint = {
							iDistance,
							hSpawnPoint
						}
					end
				end
				
				----------------
				if (hPoint) then
					hPoint = hPoint[2] 
				else
					return
				end
				
				----------------
				if (not _FOLLOWGRUNT) then
					local vPos = hPoint:GetPos()
					local vDir = hPoint:GetDirectionVector()
					
					local vTargetPos = {
						x = vPos.x + (vDir.x * 5),
						x = vPos.y + (vDir.y * 5),
						z = vPos.z + (vDir.z * 5)
					}
					self:SpawnGrunt(vTargetPos)
					self:Log(0, "Grunt Respawned")
				end
			end)
		end
		
	end,
	
	---------------------------
	-- ClearData
	
	ClearData = function(self)
		self.temp._aimEntityId = nil
		self.randomPickedBone = nil
		self.DEATH_POS_MOVING = nil
		self.DEATH_POS_MOVING_START = nil
	end,
	
	---------------------------
	-- DebugTable
	
	DebugTable = function(self, aTable)
		self:Log(0, table.tostring(aTable))
	end,
	
	---------------------------
	-- GetSuit
	
	GetSuit = function(self, iSuit)
		local iCurrSuit = g_localActor.actor:GetNanoSuitMode()
		if (iSuit) then
			return (iCurrSuit == iSuit) end
			
		return iCurrSuit
	end,
	
	---------------------------
	-- HasAimTarget
	
	HasAimTarget = function(self)
		return CheckEntity(self.temp._aimEntityId)
	end,
	
	---------------------------
	-- SetCameraTarget
	
	SetCameraTarget = function(self, vTarget, iSpeed, bIsFinalDirection)
	
		----------------
		local vTarget = vTarget
		
		----------------
		if (not vTarget) then
			return false end

		----------------
		self:Log(2, "Camera Target: %s", Vec2Str(vTarget or vectors.up))
		
		----------------
		if (vTarget.id) then
			vTarget = vTarget:GetPos()
		end
	
		----------------
		local idCurrentWeapon = Bot:GetCurrentItem()
	
		----------------
		local iRecoil = 0
		if (idCurrentWeapon and idCurrentWeapon.weapon and idCurrentWeapon.class ~= "LAW" and not self.isBoxing) then
			iRecoil = (idCurrentWeapon.weapon:GetRecoil() or 0) / 100;
		end
	
		----------------
		local vAngles = self:GetAngles(vTarget, self:GetViewCameraPos());
		local vDirection = self:GetDirectionVector(self:GetViewCameraPos(), vTarget, true, -1);
		if (bIsFinalDirection) then
			vDirection = vector.new(vTarget) end
		
	
		----------------
		if (false and not timerexpired(self.LAST_FIRE_TIMER, 0.1)) then
			local aRecoil = self.LAST_WEAPON_SPREAD
			
			-- vAngles = vector.modify(vAngles, "x", aRecoil.x * -1, true)
			-- vAngles = vector.modify(vAngles, "z", aRecoil.z * -1, true)
			-- vDirection = vector.modify(vDirection, "x", aRecoil.x * -1, true)
			-- vDirection = vector.modify(vDirection, "z", aRecoil.z * -1, true)
			
			vDirection.z = vDirection.z - aRecoil.z
			vDirection.x = vDirection.x - aRecoil.x
			
			self:Log(0, "RECOIL REDUCTION : %f: Z: %f", aRecoil.x, aRecoil.z)
		else
			vAngles.x = vAngles.x - iRecoil
			vDirection.z = vDirection.z - iRecoil
			
			self:Log(3, "Traditional recoil counter")
		end
	
		----------------
		self:Log(3, "Recoil: %f", iRecoil)
		
	
		----------------
		local iGoalDistance = checkNumber(self.CURRENT_GOAL_DISTANCE, -1)
		if (iGoalDistance ~= -1 and iGoalDistance < 1 and checkNumber(self.GOAL_REACHED_DISTANCE, 2.5) < 0.5) then
			self:Log(3, "MAYBE STOP SPRINTING ???")
			self.STOPPED_SPRINTING = true
			self:StopSprint()
		elseif (self.STOPPED_SPRINTING) then
			self.STOPPED_SPRINTING = false
			self:StartSprint() end
			
		----------------
		local bForcedSmoothCam = (not self:HasAimTarget() and not self:HasTarget()) and (iGoalDistance == -1 or iGoalDistance > 1)
		local bSmoothCam = checkVar(bForcedSmoothCam, BOT_CAMERA_SMOOTH_MOVEMENT)
		local iCamSpeed = checkNumber(iSpeed, BOT_CAMERA_ROTATE_SPEED)
		local idVehicle = g_localActor.actor:GetLinkedVehicleId()
	
		----------------
		if (bForcedSmoothCam) then
			iCamSpeed = 3 
			if (self:GetSuit(NANOMODE_SPEED)) then
				iCamSpeed = 1 end
			end
	
		self:Log(3, "Smooth Cam Speed: %f", iCamSpeed)
		----------------
		if (not idVehicle) then
			if (not bSmoothCam) then 
				g_localActor.actor:CancelSmoothDirection()
				g_localActor:SetDirectionVector(vDirection)
				self:Log(2, "Unsmooth: Proccessing Camera Target: %s", Vec2Str(vDirection))
			elseif (timerexpired(self.LAST_SMOOTH_VIEW_UPDATE, 0.15)) then
				self.LAST_SMOOTH_VIEW_UPDATE = timerinit()
				g_localActor.actor:SetSmoothDirection(vDirection, iCamSpeed)
				self:Log(2, "Smooth: Proccessing Camera Target: %s", Vec2Str(vDirection))
			end
		end
		
		----------------
		self._updatingCameraTarget = true
		
		----------------
		if (vector.isnull(vDirection)) then 
			return false end
		
		----------------
		return true
	end,
	
	---------------------------
	-- GetDirectionVector
	
	GetDirectionVector = function(self, a, b, bNormalize, iMult)
	
		----------------
		local v1 = a
		local v2 = b
		
		----------------
		if (not v1) then
			return end
		
		----------------
		if (v1.id) then
			v1 = v1:GetPos()
		else
			v1 = vector.new(v1)
		end
		
		----------------
		if (v2.id) then
			v2 = v2:GetPos() 
		else
			v2 = vector.new(v2)
		end
			
		----------------
		local vDir = {
			x = v1.x - v2.x,
			y = v1.y - v2.y,
			z = v1.z - v2.z
		}
		
		----------------
		if (bNormalize) then
			NormalizeVector(vDir) end
		
		----------------
		if (iMult) then
			vDir = vector.scale(vDir, iMult) end
		
		----------------
		return vDir
	end,
	
	---------------------------
	-- GetAngles
	
	GetAngles = function(self, v1, v2)
	
		if (not v1) then
			return end
			
		if (not v2) then
			return end
			
		-------------------
		local iX, iY, iZ = v1.x - v2.x, v1.y - v2.y, v1.z - v2.z
		local iDist = math.sqrt(iX * iX + iY * iY + iZ * iZ)
		
		-------------------
		local vAng = {
			x = math.atan2(iZ, iDist),
			y = 0,
			z = math.atan2(-iX, iY)
		}
		
		-------------------
		return vAng
	end,
	
	---------------------------
	-- CanSee
	
	CanSee = function(self, entity, ignoreCamDir, customCameraDir)
	
		------------------
		if (entity) then
			local vDir = self:GetViewCameraDir()
			local vPos = self:GetViewCameraPos()
			
			------------------
			if (ignoreCamDir) then
				local vTarget = entity:GetPos()
				if (entity.vehicle) then
					vTarget = entity:GetCenterOfMassPos()
				else
					local sAimBone = aim_aimBone
					if (sAimBone == "random") then
					
						------------------
						if (not self.randomPickedBone) then
							self.randomPickedBone = getrandom({"pelvis", "head", "spine" })
						end
						
						------------------
						sAimBone = self.randomPickedBone
					end
					
					------------------
					vTarget = entity:GetBonePos("Bip01 " .. sAimBone)
					if (not vTarget) then
						vTarget = entity:GetBonePos("Bip01 Head") end
				end
				
				------------------
				vDir = self:GetDirectionVector(vPos, vTarget, true, -1);
				
				------------------
				self:Log(9, "Can See Aimbone: " .. aim_aimBone)
				
				------------------
				return self:CanSeePosition(vTarget, entity.id);
			end
			
			------------------
			local iHits = Physics.RayWorldIntersection(vPos, { x = vDir.x * 8192, y = vDir.y * 8192, z = vDir.z * 8192 }, 8192, ent_all, g_localActor.id, nil, g_HitTable)
			local aHits = g_HitTable[1]
			
			------------------
			if (iHits and aHits and iHits>0) then
				if (not aHits.entity) then 
					return false end
					
				------------------
				self:Log(1, "CanSee() Hit on Entity %s", aHits.entity:GetName())
					
				------------------
				if (aHits.entity.id ~= entity.id) then
					return false end
				
				------------------
				return true
			end
		end

		------------------
		return false
	end,
	
	---------------------------
	-- GetViewCameraPos
	
	GetViewCameraPos = function(self)
	
		do return g_localActor:GetBonePos("Bip01 Head")
		end
		return g_localActor.actor:GetHeadPos()
	end,
	
	---------------------------
	-- GetViewCameraDir
	
	GetViewCameraDir = function(self)
		return g_localActor.actor:GetHeadDir()
	end,
	
	---------------------------
	-- CanSeePosition
	
	CanSeePosition = function(self, pos1, entityId)
		return Physics.RayTraceCheck(g_localActor.actor:GetHeadPos(), pos1, g_localActor.id, entityId or self.temp._aimEntityId or g_localActor.id);
	end,
	
	---------------------------
	-- CanSeePosition_Advanced
	
	CanSeePosition_Advanced = function(self, from1, to1, entityId)
		return Physics.RayTraceCheck(from1 or self:GetViewCameraPos(), to1, g_localActor.id, entityId or self.temp._aimEntityId or g_localActor.id);
	end,
	
	---------------------------
	-- WithinAngles
	
	WithinAngles = function(self, target, iFov)
	
		------------------
		local sBoneName = "Bip01 head"
		local iThreshold = 2
		
		------------------
		local vPos = self:GetViewCameraPos()
		local vTargetPos1 = target:GetBonePos("Bip01 head")
		local vTargetPos2 = target:GetBonePos("Bip01 pelvis")
		
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
		local iHits = Physics.RayWorldIntersection(vPos, { x = dir.x * 8192, y = dir.y * 8192, z = dir.z * 8192 }, 8192, ent_terrain + ent_static + ent_rigid + ent_sleeping_rigid + ent_living, g_localActor.id, nil, aHitData)
		local iEntsBefore = 0
		
		------------------
		local maxDeg = iFov or BOT_FIELD_OF_VIEW or 60.0

		------------------
		if (iHits > 0) then
			for i, v in pairs(aHitData) do
				if (v.entity) then
					if (v.entity.class == "Player" and v.entity.id == target.id) then
						if (iEntsBefore < iThreshold and self:Angle(dir, self:GetViewCameraDir()) < maxDeg) then
							return true
						else
							return false
						end
					end
				end
				iEntsBefore = iEntsBefore + 1
			end
		else
			return false
		end
	end,
	---------------------------
	SetVariable = function(self, sVar, vVal, isBool, floorValue, onlyPositive, isString)
	
		------------------
		if (not (sVar or vVal)) then
			return false end
			
		------------------
		local vVal = (isString and tostring(vVal) or tonumber(vVal));
		if (not vVal) then
			return self:Log(0, "\"" .. sVar .. "\" = \"" .. tostring(_G[sVar]) .. "\"") end
			
		------------------
		if (onlyPositive) then
			if (vVal < 0) then
				vVal = 0 end end
			
		------------------
		if (floorValue) then
			vVal = math.floor(vVal) end
			
		------------------
		if (isBool) then
			if (vVal == 0) then
				vVal = false
			else
				vVal = true
			end
		end
			
		------------------
		_G[sVar] = vVal;
			
		------------------
		return self:Log(0, "Set \"" .. sVar .. "\" to \"" .. tostring(_G[sVar]) .. "\" (type = " .. type(value) .. ")");
	end,
	---------------------------
	-- Log
	Log = function(self, iVerbosity, sMessage, ...)
	
		------------------
		local bLog = true
		if ((isNumber(iVerbosity) and isNumber(bot_logVerbosity)) and iVerbosity > bot_logVerbosity) then
			bLog = false end
	
		------------------
		if (bLog) then
			BotLog(tostring(sMessage), ...) end
	end,
	---------------------------
	-- LogObsoleteFCall
	LogObsoleteFCall = function(self, sFunction)
		self:Log(0, "Obsolete function Called: '%s'", sFunction)
	end,
	--------------------------------------
	-- !! OBSOLETE FUNCTIONS GO HERE !! --
	-- >>    GET RID OF THESE ASAP   << --
	--------------------------------------
	PatchScripts = function(self, skipMapCheck)
		Bot:LogObsoleteFCall("Bot.PatchScripts")
	end,
	--------------------------------------
	CheckIfOverwritten = function(self)
		Bot:LogObsoleteFCall("Bot.CheckIfOverwritten")
	end,
	--------------------------------------
	DumpData = function(self)
		Bot:LogObsoleteFCall("Bot.DumpData")
	end,
	--------------------------------------
	InitChat = function(self)
		Bot:LogObsoleteFCall("Bot.InitChat")
	end,
	--------------------------------------
	InitAI = function(self)
		Bot:LogObsoleteFCall("Bot.InitAI")
	end,
	--------------------------------------
	ProcessCaptureData = function(self)
		Bot:LogObsoleteFCall("Bot.ProcessCaptureData")
	end,
	---------------------------
	ProcessAIPathLearning = function(self)
		Bot:LogObsoleteFCall("Bot.ProcessAIPathLearning")
	end,
	--------------------------------------
	ProcessExperimentalAIPathLearning = function(self)
		Bot:LogObsoleteFCall("Bot.ProcessExperimentalAIPathLearning")
	end,
	--------------------------------------
	LoadPositionData = function(self)
		Bot:LogObsoleteFCall("Bot.LoadPositionData")
	end,
	---------------------------
	RegisterDifficultyModes = function()
		Bot:LogObsoleteFCall("Bot.RegisterDifficultyModes")
	end,
	---------------------------
	PrePatch = function(self)
		Bot:LogObsoleteFCall("Bot.PrePatch")
	end,
	---------------------------
	GoToNextPathSpot = function(self)
		Bot:LogObsoleteFCall("Bot.GoToNextPathSpot")
	end,
	---------------------------
	CheckNextVisiblePathNode = function(self)
		Bot:LogObsoleteFCall("Bot.CheckNextVisiblePathNode")
	end,
	---------------------------
	ProcessFollowGrunt = function(self, grunt)
		Bot:LogObsoleteFCall("Bot.ProcessFollowGrunt")
	end,
	---------------------------
	GetDirToNextPathSpot = function(self)
		Bot:LogObsoleteFCall("Bot.GetDirToNextPathSpot")
	end,
	---------------------------
	ContinueOnPath = function(self) 
		Bot:LogObsoleteFCall("Bot.ContinueOnPath")
	end,
	---------------------------
	ResetPath = function(self)
		Bot:LogObsoleteFCall("Bot.ResetPath")
	end,
	---------------------------
	GetClosestPathSpotDistance = function(self)
		Bot:LogObsoleteFCall("Bot.GetClosestPathSpotDistance")
	end,
	---------------------------
	GetDistanceToCurrentPathPos = function(self)
		Bot:LogObsoleteFCall("Bot.GetDistanceToCurrentPathPos")
	end,
	---------------------------
	UpdatePathSpot = function(self)
		self:LogObsoleteFCall("Bot.UpdatePathSpot")
	end,
	---------------------------
	GetNearestPossiblePath = function(self, exeptThisPath, onlyThisPath, onlyVisible)
		Bot:LogObsoleteFCall("Bot.GoToNextPathSpot")
	end,
};


----------------------
Bot.LAST_SEEN_TARGET_LOOSE = 300
Bot.LAST_SEEN_MOVING = nil
Bot.LAST_SEEN_MOVING_START = nil

----------------------
function _StartupBot()

	BotLog("Initializing Bot")

	local bOk, sErr = pcall(Bot.Init, Bot)
	if (not bOk) then
		SetError("Failed to initialize the Bot", sErr)
		FinchPower:FinchError(not _reload and Config.QuitOnHardError)
		return
	end
	
	Bot:ClearAllData()
	BotLog("Bot Initialized")
end

----------------------
_StartupBot()
