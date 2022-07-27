-------------------------------------------------------------------------------------------------------------
-- Crysis 1 CryMP-Bot - v0.1a | Written by .R | (c) 2021
-------------------------------------------------------------------------------------------------------------
-- Do NOT reupload ANYWHERE without MY PERMISSION. Seriously. ur ded otherwise
-------------------------------------------------------------------------------------------------------------
-- FILE: FINCH.lua
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
-- NOTE: THIS IS JUST AN EARLY BETA VERSION (0.1gigachad) OF THE BOT. 
-------------------------------------------------------------------------------------------------------------

-------------------------------
System.ClearConsole()
FINCH_VERSION = "1.0.0"

-------------------------------
if (loadstring == nil) then
	loadstring = load end

-------------------------------
FinchLogNotFmt = function(msg)
	return System.LogAlways("$9[$7FinchPower$9] " .. tostring(msg))
end

-------------------------------
FinchLog = function(msg, ...)
	local msg = msg
	if (...) then
		msg = string.format(msg, ...)
	end
	return System.LogAlways(string.format("$9[$7FinchPower$9] %s", string.format(msg, ...)))
end

-------------------------------
FINCH_LOGGED_MESSAGES = {}

-------------------------------
FinchLogTimer = function(iTimer, msg, ...)

	----------------
	local sHandle = tostring(msg)
	if (simplehash) then
		sHandle = simplehash.hash(sHandle, 4) end
		
	----------------
	if (not FINCH_LOGGED_MESSAGES[sHandle] or (_time - FINCH_LOGGED_MESSAGES[sHandle] > iTimer)) then
		FinchLog(msg, ...)
		FINCH_LOGGED_MESSAGES[sHandle] = _time
	end
end

-------------------------------
BotAPILog = function(msg, ...)
	local msg = msg
	if (...) then
		msg = string.format(msg, ...)
	end
	return System.LogAlways(string.format("$9[$6BotAPI$9] %s", string.format(msg, ...)))
end

-------------------------------
BotLog = function(msg, ...)
	local msg = msg
	if (...) then
		msg = string.format(msg, ...)
	end
	return System.LogAlways(string.format("$9[$4Bot$9] %s", string.format(msg, ...)))
end

-------------------------------
math.randomseed(os.time())

-------------------------------
function SetError(name, code)
	LAST_ERROR_NAME = name;
	LAST_ERROR = code;
end;



-------------------------------
if (System.OldQuit == nil) then
	System.OldQuit = System.Quit end
	
System.Quit = function(sCaller, ...)
	FinchLog("System.Quit(" .. tostring((sCaller or "Unknown Caller")) .. ")")
	
	System.SetCVar("log_Verbosity", "-1")
	System.SetCVar("log_fileVerbosity", "-1")	
	
	return System.OldQuit(...)
end;

-------------------------------
if (os.OldExecute == nil) then
	os.OldExecute = os.execute end
	
os.execute = function(...)
	FinchLog("Executing CMD: " .. table.concat({ ... }, " "));		
	return os.OldExecute(...)
end

-------------------------------
table.getnum = function(self)
	local c = 0;
	for i, v in pairs(self or{}) do
		c = c + 1;
	end;
	return c;
end;


-------------------------------
FinchPower = {
	------------------------------
	ignoreIpCheck = true;
	------------------------------
	Reload = function(self)
		
		IS_RELOAD = true
		System.ExecuteCommand('reloadBot')
		
	end,
	------------------------------
	Init = function(self)
	
		FinchLog("Initializing FinchPower")
	
		-------------------
		-- Add Commands
		if (not self:AddCommands()) then
			return false end
		
		-------------------
		-- Load Libraries
		if (not self:LoadLibraries()) then
			return false end
		
		-------------------
		if (not self:LoadConfigFile()) then
			return false end
		
		-------------------
		if (not self:LoadLauncherConfig()) then
			return false end
		
		-------------------
		if (not self:CreateAPI()) then
			return false end
		
		-------------------
		if (not self:FinchRemoveVBS()) then
			return false end
		
		-------------------
		if (not self:SelectServer(FinchPower.CONNECT_IP, FinchPower.CONNECT_PORT, FinchPower.CONNECT_PASSWORD)) then
			return false end
		
		-------------------
		if (not self:PatchGameRules()) then
			return false end
		
		-------------------
		if (not self:CheckBot()) then
			return false end
		
		-------------------
		self:MoveLogs('Bot Build%((%d+)%) Date%((%d+) (%w+) (%d+)%) Time%((%d+) (%d+) (%d+)%)%.log');
		
		-------------------
		FinchLog("FinchPower Initialized")
		
		-------------------
		IS_RELOAD = false
		
		-------------------
		return true
	end,
	------------------------------
	CheckBot = function(self)
	
		if (not BOT_CONNECTED) then
			return false end
	
		if (not BOT_LOADED) then
			self:LoadBotFile()
		end
	end,
	------------------------------
	AddCommands = function(self)
		---------------------
		local sPrefix = "finchpower_"
		local aCVars = {
			{ "reload",   "FinchPower:Reload()",            "Reloads the FinchPower File" },
			{ "init",     "FinchPower:Init(true)",          "Re-initializes the FinchPower" },
			{ "initlibs", "FinchPower:LoadLibraries(true)", "Reloads the FinchPower Libraries" }
		}
		local iCVars = (table.count and table.count(aCVars) or #aCVars)
		
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
		FinchLog("Registered %d New Console Commands", iCVars)
		
		---------------------
		return true
	end,
	------------------------------
	LoadFile = function(self, sFile)
	
		-----------------------
		local bOk, sErr = pcall(loadfile, sFile)
		if (not bOk) then
			SetError("Failed to load File " .. sFile, (sErr or "<Unknown Cause>"))
			return false, self:FinchError(true)
		else
			bOk, sErr = pcall(sErr)
			if (bOk == false) then
				SetError("Failed to execute File " .. sFile, (sErr or "<Unknown Cause>"))
				return false, self:FinchError(true)
			end
		end
		
		-----------------------
		FinchLog("FILE OK -> " .. sFile)
		
		-----------------------
		return true, sErr
	end;
	------------------------------
	LoadLibraries = function(self)
			
		-----------------------
		FinchLog("Loading Libraries")
		
		-----------------------
		local sLibPath = "Bot\\Includes\\"
	
		-----------------------
		local bOk, hLib = self:LoadFile(sLibPath .. "\\ini.utils.lua")
		if (not bOk) then
			return false end
			
		-----------------------
		bOk, hLib = self:LoadFile(sLibPath .. "\\lua.utils.lua")
		if (not bOk) then
			return false end
			
		-----------------------
		bOk, hLib = self:LoadFile(sLibPath .. "\\timer.utils.lua")
		if (not bOk) then
			return false end
			
		-----------------------
		bOk, hLib = self:LoadFile(sLibPath .. "\\vector.utils.lua")
		if (not bOk) then
			return false end
			
		-----------------------
		bOk, hLib = self:LoadFile(sLibPath .. "\\math.utils.lua")
		if (not bOk) then
			return false end
			
		-----------------------
		bOk, hLib = self:LoadFile(sLibPath .. "\\string.utils.lua")
		if (not bOk) then
			return false end
			
		-----------------------
		bOk, hLib = self:LoadFile(sLibPath .. "\\table.utils.lua")
		if (not bOk) then
			return false end
			
		-----------------------
		bOk, hLib = self:LoadFile(sLibPath .. "\\string.shred.lua")
		if (not bOk) then
			return false end
			
		-----------------------
		bOk, hLib = self:LoadFile(sLibPath .. "\\simplehash.lua")
		if (not bOk) then
			return false end
			
		-----------------------
		bOk, hLib = self:LoadFile(sLibPath .. "\\crypt.utils.lua")
		if (not bOk) then
			return false end
			
		-----------------------
		bOk, hLib = self:LoadFile(sLibPath .. "\\md5.lua")
		if (not bOk) then
			return false end
			
		-----------------------
		FinchLog("All Libraries loaded")
			
		return true
	end;
	------------------------------
	LoadConfigFile = function(self)
	
		-----------------------
		local sConfigPath = "Bot\\Config.lua";
		
		-----------------------
		local bOk, hLib = self:LoadFile(sConfigPath)
		if (not bOk) then
			return false end
			
		
		-----------------------
		if (Config == nil) then
			Config = {} end

		-----------------------
		if (Config.ZombieDisconnects) then
			self.RECONNECT_TRIES = (tonumber(Config.ZombieDisconnects) or 3) end	

		-----------------------
		if (Config.ZombieQuit ~= nil) then
			self.ZOMBIE_QUIT = Config.ZombieQuit end	

		-----------------------
		local sServer = Config.CurrentServer
		if (sServer) then
			local aServer = Config.ServerList[sServer]
			if (aServer) then
				self.CONNECT_IP = aServer.I_PEE
				self.CONNECT_PORT = aServer.PORT
				self.CONNECT_PASSWORD = aServer.PASSWORT
			else
				local iIPA, iIPB, iIPC, iIPD, iPort, sPass = string.match(sServer, "(%d+)%.(%d+)%.(%d+)%.(%d+)%s-:?%s-(%d+)%s-:?%s-(.*)") -- IP:PORT:PASSWORD
				if (iIPA and iIPB and iIPC and iIPD and iPort) then
					self.CONNECT_IP = string.format("%d.%d.%d.%d", iIPA, iIPB, iIPC, iIPD)
					self.CONNECT_PORT = string.format("%d", iPort)
					self.CONNECT_PASSWORD = sPass
					
					-----------------------
					FinchLog("Parsed Server Info (IP: %s, Port: %s, Pass: %s) from String %s", self.CONNECT_IP, self.CONNECT_PORT, (self.CONNECT_PASSWORD or ""), sServer)
				end
			end
		end	
		
		-----------------------
		FinchLog("Loaded %d Configuration entries", table.getnum(Config))
		
		-----------
		return true
	end;
	------------------------------
	LoadLauncherConfig = function(self)
	
		local function ValidateSuit(sMode)
			local aRealBones = {
				["random"] 	= "random",
				["head"] 	= "head",
				["neck"] 	= "neck",
				["torso"] 	= "torso",
				["pelvis"] 	= "pelvis",
				["right hand"] 	= "R hand",
				["left hand"] 	= "L hand",
				["right foot"] 	= "R foot",
				["left foot"] 	= "L foot"
			}
			
			local sRealBone = string.lower(sMode)
			for sBone, sReal in pairs(aRealBones) do
				if (sBone == sRealBone) then
					sRealBone = sReal end
			end
			
			return sRealBone
		end
	
		local sIniPath = string.gettempdir() .. "\\..\\CryMP-Bot-Launcher\\PresetActive\\Current.ini"
		if (not fileexists(sIniPath)) then
			return true, FinchLog("Preset File not found: %s", sIniPath)
		end
		
		FinchLog("Loading Launcher Preset INI: %s", sIniPath)
		local aKeys = {
			["_AutoReconnect_"] 	= { "FinchPower.RECONNECT_IF_KICKED",			true }, 
			["_MaxReconnects_"] 	= { "FinchPower.RECONNECT_TRIES",				300 }, 
			["_ZombieQuit_"] 		= { "FinchPower.RECONNECT_IF_KICKED",			true }, 
			["_AutoQuit_"] 			= { "FinchPower.ZOMBIE_QUIT",		true }, 
			["_ConIP_"] 			= { "FinchPower.CONNECT_IP",		nil }, 
			["_ConPort_"] 			= { "FinchPower.CONNECT_PORT",		nil }, 
			["_ConPassword_"] 		= { "FinchPower.CONNECT_PASSWORD",	nil }, 
			["_AutoQuitTriggers_"] 	= { function(v)FinchPower.RECONNECT_REASONS_BLACKLIST = string.split(v, '|') end,	"admin|kicked|banned" }, 
			["_StringCDKey_"]	 	= { "FinchPower.CD_KEY",			nil }, 
			["_RandomCDKey_"] 		= { "FinchPower.GENERATE_CD_KEY",	true },
			--------------------------------------------------------------------
			["_AimBone_"] 			= { function(v)Config.AimBone = v:lower()end,	"head" },
			["_AimAccuracy_"]		= { "Config.AimAccuracy",			100 },
			["_AimAccuracyMin_"] 	= { "Config.AimAccuracyMin",		100 },
			--------------------------------------------------------------------
			["_UseFOV_"] 			= { "Config.BotUseFOV",				false },
			["_BotFOV_"]			= { "Config.BotFOV",				180 },
			["_UseSmoothCam_"] 		= { "Config.BotSmoothCam",			false },
			["_CamSpeed_"] 			= { "Config.BotSmoothCamSpeed",		100 },
			--------------------------------------------------------------------
			["_MeleeDelay_"] 		= { function(v)Config.MeleeDelay = v/1000 end,		500 },
			["_MeleeGunDelay_"]		= { function(v)Config.MeleeGunDelay = v/1000 end,	180 },
			--------------------------------------------------------------------
			["_AdminMode_"] 		= { "Config.AdminMode",				false },
			["_AdminEncrypt_"] 		= { "Config.EncryptCommands",		false },
			["_AdminName_"]			= { "Config.AdminName",				"$7egirl" },
			--------------------------------------------------------------------
			["_AIPathfinding_"] 		= { "Config.AIPathFinding",			false },
			["_BotHostile_"] 			= { "Config.BotHostility",			false },
			["_BotMovement_"]			= { "Config.BotMovement",			false },
			["_ZombieKiller_"]			= { "Config.ZombieKillerMode",		false },
			["_ZombieMode_"]			= { "Config.ZombieMode",			false },
			["_BotTeaming_"]			= { "Config.BotTeaming",			false },
			["_BotTeamTag_"]			= { "Config.BotTeamName",			"$7egirl" },
			["_BotWalljumping_"]		= { "Config.BotWallJumping",		false },
			["_CircleJump_"]			= { "Config.BotCircleJumping",		false },
			["_DefSuit_"]				= { function(v)Config.BotDefaultSuit = ValidateSuit(string.upper(v)) end,	"Armor" },
			["_BoxMode_"]				= { "Config.BoxerMode",				false },
			["_ShootExplosives_"]		= { "Config.ShootExplosives",		false },
			["_UseNades_"]				= { "Config.UseGrenades",			false },
			["_NoSprint_"]				= { "Config.NoSprinting",			false },
			--------------------------------------------------------------------
			["_AntiName_"]				= { "Config.TargetModeName",		"$7egirl" },
			["_AntiMode_"]				= { "Config.TargetMode",			false },
			--------------------------------------------------------------------
			["_BuyItems_"]				= { "Config.BuyItems",				false },
			["_BuyableItems_"]			= { function(v)Config.BuyableItems = string.split(v, '|')end,	false },
			--------------------------------------------------------------------
			["_BotName_"]				= { "Config.BotName",				"" },
			["_BotUseNames_"]			= { "Config.RandomNames",			false },
			["_RandomNames_"]			= { function(v)Config.BotRandomNames = string.split(v, '|')end,	false },
			--------------------------------------------------------------------
			["_ItemBlacklist_"]			= { function(v)Config.BotBlacklist = string.split(v, '|')end, 	"" },
			--------------------------------------------------------------------
			["_AutoCVars_"]				= { function(v) Config.AutoCVars = FinchPower:ParseCVars(string.split(v)) or {} end, 	"" }, -- !!TODO
			--------------------------------------------------------------------
			["_FollowerSystem_"]		= { "Config.BotFollowSystem",		false },
			["_CopyCloak_"]				= { "Config.BotFollowConfig.NanoSuit.CLOAK",	false },
			["_CopySpeed_"]				= { "Config.BotFollowConfig.NanoSuit.SPEED",	false },
			["_CopyDefense_"]			= { "Config.BotFollowConfig.NanoSuit.ARMOR",	false },
			["_CopyStrength_"]			= { "Config.BotFollowConfig.NanoSuit.STRENGTH",	false },
			["_CopyEquipment_"]			= { "Config.BotFollowConfig.CopyCurrentGun",	false },
			["_CopyStance_"]			= { "Config.BotFollowConfig.CopyStance",		false },
			["_CopyTrolling_"]			= { "Config.BotFollowConfig.FunnyBehavior",		false },
			["_FSmartFollow_"]			= { "Config.BotSmartFollow",						false },
			["_FAutoFollow_"]			= { "Config.BotAutoFollow",							false },
			["_FAutoFollowName_"]		= { "Config.BotFollowSystemAutoName",				"" },
			["_FNearDist_"]				= { "Config.BotFollowConfig.NearDistance",			8 },
			["_FFarDist_"]				= { "Config.BotFollowConfig.LooseDistance",			250 },
			["_FNearDistRandom_"]		= { "Config.BotFollowConfig.NearDistanceRandom",	false },
			["_FUseVehicles_"]		= { "Config.FollowModeUseVehicles",	false },
			--------------------------------------------------------------------
			["_UseChat_"]				= { "Config.BotChatMessages",	false },
			["_ChatChance_"]			= { "Config.BotMessageChance",	20 },
			--------------------------------------------------------------------
			["_RandomPathes_"]			= { "Config.PathRandomizing",		false },
			["_PathRandomDist_"]		= { "Config.PathRandomizing_Max",	20 },
			--------------------------------------------------------------------
			["_BotSystem_"]				= { "Config.System",			false },
			["_SystemBreak_"]			= { "Config.SystemBreak",		false },
			["_CPUSaver_"]				= { "Config.CPUSaverMode",		false },
			["_MaxFPS_"]				= { "Config.BotMaxFPS",			false },
			--------------------------------------------------------------------
			["_AIGruntMode_"]			= { "Config.AIGruntMode",		false },
			["_AIGruntCJ_"]				= { "Config.AIGruntModeCJ",		false },
			["_AIGruntFarPoint_"]		= { "Config.FollowGruntUseFurthestPoint",	false },
			["_AIGruntStuckTime_"]		= { "Config.FollowGruntStuckTimer",			3000 },
			["_AIGruntStuckDist_"]		= { function(v)Config.FollowGruntStuckDist = v/1000 end,			1 },
			["_AIGruntPathDist_"]		= { function(v)Config.FollowGruntPathInsertDistance = v/1000 end,	1 },
			["_AIGruntPathMax_"]		= { "Config.FollowGruntMaxPathPoints",	1000 },
			--------------------------------------------------------------------
			["_FindEquipment_"]			= { "Config.PickupWeapons",		false },
			["_EquipmentToFind_"]		= { function(v)Config.PickableWeapons = string.split(v)end,	"" },
			["_UseAccessories_"]		= { "Config.UseAttachments",	false },
			--------------------------------------------------------------------
			["_SkillSet_"]				= { "Config.BotSkillSet",	1000 }
		}
		
		local iKeysRead = 0
		for iniKey, aData in pairs(aKeys) do
			local sKey = aData[1]
			local sDef = aData[2]
			local bOnlyIfNil = aData[3]
			
			local sIni = iniutils.iniread(sIniPath, "Config", iniKey, sDef)
			-- FinchLog(tostring(iniKey) .. " == " .. tostring(sIni))
			if (not sIni) then
				sIni = "" end
			
			if (type(sIni) == "string" and (string.lower(sIni) == "true" or string.lower(sIni) == "false")) then
				sIni = (string.lower(sIni) == "true") end
				
			if (tonumber(sIni)) then
				sIni = tonumber(sIni) end
				
			if (type(sKey) == "function") then
				sKey(sIni) 
			else
				local sLoad = tostring(sIni)
				if (sIni == nil or type(sIni) == "string") then
					sLoad = "\"" .. tostring(sIni) .. "\"" end
				
				if (not bOnlyIfNil or loadstring(string.format("return %s == nil", sKey))() == true) then
					loadstring(string.format("%s = %s", sKey, sLoad))()
					iKeysRead = iKeysRead + 1
					FinchLog(tostring(sKey) .. " == " .. tostring(sLoad))
				else
					FinchLog("Skipped Key %s (%s)", sKey, sLoad)
				end
			end
		end
		
		--------------------------------------------
		FinchLog("Loaded %d Config Keys", iKeysRead)
		FinchLog("Loaded Preset file")
		
		-----------
		return true
	end;
	------------------------------
	ParseCVars = function(self, aCVarsString)
		local aCVars = {}
		for i, v in pairs(aCVarsString) do
			local sVar, sVal = string.match(v, "(.*)%+(.*)")
			if (sVar and sVal) then
				if (sVal == "true" or sVal == "false") then
					aCVars[sVar] = (sVal == "true") 
				elseif (tonumber(sVal)) then
					aCVars[sVar] = tonumber(sVal) 
				else
					aCVars[sVar] = sVal 
				end
			end
		end
		return aCVars
	end;
	------------------------------
	CreateAPI = function(self)
		
		----------------------------
		FinchLog("Initializing API")
	
		-----------------------
		local sAPIPath = "Bot\\BotAPI.lua";
		
		-----------------------
		local bOk, hLib = self:LoadFile(sAPIPath)
		if (not bOk) then
			return false end
		
		----------------------------
		if (isNull(BotAPI)) then
			return false end
		
		----------------------------
		BotAPI:Init()
		
		----------------------------
		FinchLog("API Initialized")
		
		-----------
		return true
	end;
	------------------------------
	RECONNECT_IF_KICKED = true;
	RECONNECT_TRIES = 3;
	RECONNECT_REASONS_BLACKLIST = {
		'kicked', 'banned'; -- if kick reason contains these messages stop reconnect
	};
	CONNECT_IP = nil;
	CONNECT_PORT = nil;
	CONNECT_PASSWORD = nil;
	CD_KEY = nil;
	ZOMBIE_QUIT = true;
	GENERATE_CD_KEY = true;
	------------------------------
	I_PEE_LIST = nil;
	------------------------------
	PatchGameRules = function(self)
	
		--------------------------
		if(not InstantAction)then
			Script.ReloadScript("Scripts/GameRules/InstantAction.lua") 
		end
		
		--------------------------
		if(not PowerStruggle)then
			Script.ReloadScript("Scripts/GameRules/PowerStruggle.lua") 
		end
	
		--------------------------
		InstantAction.Client.ClSetupPlayer = function(self, playerId)
			self:SetupPlayer(System.GetEntity(playerId)) 
		end
		
		--------------------------
		PowerStruggle.Client.ClSetupPlayer = function(self, playerId)
			self:SetupPlayer(System.GetEntity(playerId)) 
		end
		
		-----------
		return true
	end;
	------------------------------
	UninstallBot = function(self, reason, wasFailConn)
		FinchLog("Bot was disconnected from Server: " .. tostring(reason));
		
		---------------------
		if (Bot) then
			local iGlobals = 7
			for sName, value in pairs(Bot.globals or{}) do
				if (_G[tostring(name)] ~= nil) then
					_G[tostring(name)] = nil
					iGlobals = iGlobals + 1
				end;
			end;

			local aVars = { -- pwease open BotMain.lua and rename these aweeeeeeeeeeeeeeeeful globals !!
				"Bot",
				"_dataAdded",
				"_REPUTATION",
				"BOT_DEV_MODE",
				"_BLACKLISTED",
				"_reenabledBot",
				"_REPUTATIONLIST",
				"_BLACKLISTED_TEAM",
			}
			for i, v in pairs(aVars) do
				_G[v] = nil
			end
			
			BotLog("Cleared %d Globals", iGlobals)
			FinchLog("Bot was uninstalled successfully!")
		else
			FinchLog("First-Launch Disconnect")
		end
		
		---------------------
		RECONNECT_TRIES = (RECONNECT_TRIES or 0) + 1;
		
		---------------------
		local bQuit = false
		
		---------------------
		local bAutoReconnect = self.RECONNECT_IF_KICKED
		if (not bAutoReconnect) then
			bQuit = true
			FinchLog("Not Reconnecting to Server (Auto Reconnect is disabled)")
		end
		
		---------------------
		local bIsBlacklisted = self:IsBlacklistedReason(reason)
		if (bIsBlacklisted) then
			bQuit = true
			FinchLog("Not Reconnecting to Server (Disco Reason contains blacklisted word)")
		end
		
		---------------------
		local bServerOffline = self:IsServerProbablyOffline(reason)
		if (bServerOffline) then
			bQuit = true
			FinchLog("Not Reconnecting to Server (Server is probably offline)")
		end
		
		---------------------
		local bIsInvalidPassword = self:IsInvalidPassword(reason)
		if (bIsInvalidPassword) then
			bQuit = true
			FinchLog("Not Reconnecting to Server (Invalid Server Password)")
		end
		
		---------------------
		local bRetiresExceeded = RECONNECT_TRIES > self.RECONNECT_TRIES
		if (bRetiresExceeded) then
			bQuit = true
			FinchLog("Not Reconnecting to Server (Maximum Reconnection retries exceeded)")
		end
		
		---------------------
		if (not bQuit) then
			FinchLog("Reconnecting to Server (Retry " .. RECONNECT_TRIES .. " of " .. self.RECONNECT_TRIES .. ")");
			self:Connect(true)
		elseif (self.ZOMBIE_QUIT) then
			FinchLog("Impossible to Reconnect, Shutting down bot")
			System.Quit("Zombie Mode")
		else
			FinchLog("Bot staying idle after Disconnect !")
		end
	end;
	------------------------------
	IsServerProbablyOffline = function(self, r)
		return 
			(string.match(r, "Connection attempt to ((%d+)%.(%d+)%.(%d+)%.(%d+):(%d+)) failed") or
			string.match(r, "Connection attempt to ((.*):(%d+)) failed"))
	end;
	------------------------------
	IsInvalidPassword = function(self, r)
		return (string.match(r, "Authentication password is wrong"))
	end;
	------------------------------
	IsBlacklistedReason = function(self, r)
		local sReason = string.lower(r)
		for i, listed in pairs(self.RECONNECT_REASONS_BLACKLIST or{}) do
			if (string.find(sReason, listed:lower())) then
				return true end end
	
		return false
	end;
	------------------------------
	OnDisconnect = function(self)
	
		BOT_CONNECTED = false
		
	end,
	------------------------------
	OnPreConnect = function(self)
	
		if (g_localActor.ON_CONNECTED) then
			return false end
			
		g_localActor.ON_CONNECTED = true
		FinchPower:OnConnected(player)
	end,
	------------------------------
	LoadBotFile = function(self)
	
		---------------------
		FinchLog("Loading Bot File")
			
		---------------------
		BOT_LOADED = self:LoadBotCore()
	end,
	------------------------------
	OnConnected = function(self, player)
	
		self.lastReload = _time
	
		---------------------
		BOT_CONNECTED = true
	
		---------------------
		INGAME = true
		_Connected = false
		LAST_ACTOR = player
			
		---------------------
		self:LoadBotFile()
			
		---------------------
		FinchLog("Patching Game Rules")
			
		---------------------
		g_gameRules.server:RequestSpectatorTarget(g_localActor.id, 111) -- to idenfity bots
		Bot:OnEnteredServer()
			
		---------------------
		self:PatchGameRules()
		Script.SetTimer(2500, function()
			FinchPower:PatchGameRules() end)
			
		---------------------
		FinchLog("Game Rules Patched")
	end;
	------------------------------
	ValidServer = function(self, IP)
	
		-----------
		if (self.ignoreIpCheck) then
			return true end
			
		-----------
		local bValid, sStatus, iStatus = os.execute("ping -n 1 -w 8000 " .. IP);
		FinchLog("Server Ping Result: IP = " .. IP .. ", Status = " .. tostring(bValid));
		
		-----------
		if ((tostring(bValid) ~= "true" and tostring(bValid) ~= "0")) then
			return false end
		
		-----------
		return true
	end;
	------------------------------
	SelectServer = function(self, ip, port, password)

		if (not ip or not port) then
			SetError("Connection Failed", "Not all necessary params for SelectServer() were provided.");
			return false, self:FinchError(true);
		end
		
		if (not self:ValidServer(IP)) then
			SetError("Invalid Server IP", "Unable to contact server with IP " .. IP)
			return false, self:FinchError(true)
		end
		
		I_PEE_PORT = ip .. ":" .. port
		SERVER_PASSWORT = password or ""
		
		FinchLog("Selected Server: " .. I_PEE_PORT .. " Password: " .. SERVER_PASSWORT)
		
		-----------
		return true
	end;
	------------------------------
	Assign = function(self, val1, val2, code)
		pcall(loadstring(val1 .. ", " .. val2 .. " = " .. code));
	end;
	------------------------------
	FinchPrintTable = function(self, finchTable, off)
		local off = off or "";
		for i, v in pairs(finchTable) do
			if(type(v) == "table")then
				System.LogAlways(off .. tostring(i) .. " = {");
				self:FinchPrintTable(v, off .. off);
				System.LogAlways(off .. "}");
			else
				System.LogAlways(off .. tostring(i) .. " = " .. tostring(v));
			end;
		end;
	end;
	------------------------------
	FinchErrorWriteVBS = function(self, errorName, errorCode, softError)
		local path = Game.GetRoot() .. "\\Bot\\Error";
		--self:RunCommand("IF NOT EXIST \"" .. path .. "\" md \"" .. path .. "\"");
		self:CheckDir(path:gsub("\\","/")); --"IF NOT EXIST \"" .. path .. "\" md \"" .. path .. "\"")
		local file, error = io.open(path .. "\\Error_VBS.vbs", "w+");
		if(file)then
			file:write("x=msgbox(\"" .. "*** Error loading bot ***\" & vbCrLf & \"" .. errorCode .. "\" & vbCrLf & \"*****************************************************\" & vbCrLf & \""..(not softError and "Click OK to reload the Bot Files." or "Click OK to exit the Bot.").."\", 0+" .. (not softError and 64 or 16) .. ", \"" .. "CryMP Bot v" .. FINCH_VERSION.. " | " .. errorName .. "\")");
			file:close();
		else
			System.LogAlways("$4<Error> failed to create error message-box " .. tostring(e));
		end;
	end;
	------------------------------
	RunCommand = function(self, line)
		return os.execute(line);
	end;
	------------------------------
	FinchErrorOpenVBS = function(self)
		local sVBPath = "\"" .. Game.GetRoot() .. "/Bot/Error/Error_VBS.vbs\""
		return self:RunCommand(sVBPath:gsub("\\","/"));
	end;
	------------------------------
	FinchRemoveVBS = function(self)
		local sPath = string.gsub(Game.GetRoot() .. "Bot/Error/Error_VBS.vbs", "\\", "/")
		self:RunCommand("if EXIST \"" .. sPath .. "\" del \"" .. sPath .. "\"");
		
		-----------
		return true
	end;
	------------------------------
	FinchError = function(self, quit, reloadFile)
		local star = "************************************************************";
		System.LogAlways(star)
		System.LogAlways("<ERROR>");
		System.LogAlways("       >> " .. tostring(LAST_ERROR_NAME) .. " | Last error:");
		System.LogAlways("          >> " .. tostring(LAST_ERROR));
		System.LogAlways("<DEBUG>");
		System.LogAlways("       >> " .. (Bot and "Config = {" or "Bot.lua not " .. (BOT_DEV_MODE~=nil and "properly " or "") .. "loaded!"));
		if(Bot)then
		self:FinchPrintTable(Bot.cfg, "       ");
		System.LogAlways("       }");
		end;
		System.LogAlways(" ");
		System.LogAlways("Traceback: " .. (debug.traceback()or "traceback failed!"));
		System.LogAlways("Logged at " .. os.date() .. " | FinchPower v" .. FINCH_VERSION);
		System.LogAlways("(Send this Bot.log to Rya on Discord for more info)");
		System.LogAlways(star);
		if(Config and Config.UseErrorBox)then
			self:FinchErrorWriteVBS(LAST_ERROR_NAME, LAST_ERROR, quit);
			self:FinchErrorOpenVBS();
			self:FinchRemoveVBS();
		end;
		self:FinchLogError(star);
		-- return (not IS_RELOAD and quit) and System.Quit("LUA Error") or ((Config and Config.UseErrorBox) and self:FinchLoadFile());
	end;
	------------------------------
	FinchLogError = function(self, star)
	end;
	------------------------------
	FinchLoadFile = function(self)
		
		SetError("Failed to load Bot.lua", "Unknown Error (!)")
		
		local sBotPath = "Bot\\Core\\BotMain.lua"
		local bOk = self:LoadFile(sBotPath)
		if (not bOk) then
			return false, self:FinchError(not _reload and Config.System) 
		end
		
		return true
	end;
	------------------------------
	LoadBotCore = function(self)
	
		SetError("Bot Lua Loaded but Bot is NUll", "Bot is Null");
		System.ExecuteCommand("exec Bot\\Core\\InitBot.cfg"); -- execute bot configuration file 
		
		if(not self:FinchLoadFile())then
			return false, self:FinchError(not _reload and Config.System) end
			
		if(not Bot)then
			return false, self:FinchError(not _reload and Config.System) end
			
		return true, FinchLog("Bot was loaded Successfully!");
	end;
	------------------------------
	PreConnect = function(self)
	
		if (Config and Config.AutoConnect ~= true) then
			return false end
			
		-----------------
		local bOk = true
			
		-----------------
		if (g_localActor) then
			bOk = false end
			
		-----------------
		if (g_gameRules) then
			bOk = false end
			
		-----------------
		if (_LAST_CONNECT and (_time - _LAST_CONNECT < 300)) then
			bOk = false end
			
		-----------------
		if (bOk) then
			self:Connect(true)
		else
			FinchLogTimer(30, "Not connecting to Server yet")
		end
	end;
	------------------------------
	Wait = function(self)
		self:PreConnect()
	end;
	------------------------------
	Connect = function(self, force)
	
		_LAST_CONNECT = _time
	
		----------------------------
		local sCDKey = self.CD_KEY or "AAAAABBBBBCCCCCDDDDD"
		if (self.GENERATE_CD_KEY) then
			FinchLog("Generating Random CD-Key")
			sCDKey = self:GenerateCDKey() end
	
		----------------------------
		if (Config and Config.AutoConnect ~= true) then
			return false end
			
		----------------------------
		lastConnectWasAuto = _time;
		
		----------------------------
		FinchLog("Connecting ...");
		
		----------------------------
		local bConnect = force
		if (not bConnect) then
			bConnect = (not g_gameRules and not _Connected) end
			
		----------------------------
		if (bConnect) then
			FinchLog("Connecting to " .. I_PEE_PORT .. " *= " .. SERVER_PASSWORT);
			FinchLog("CD-Key: %s", sCDKey);
			Script.SetTimer(5000, function()
				_Connected = true;
				System.ExecuteCommand("net_set_cdkey " .. sCDKey);
				System.ExecuteCommand("sv_password " .. SERVER_PASSWORT);
				System.ExecuteCommand("connect " .. I_PEE_PORT); --localhost 50003"); --"); --116.203.92.129 55001");
			end);
			_LAST_CONNECT = _time; -- when did we last try to connect?
			
		elseif (g_gameRules) then
			BOT_LOADED = self:LoadBotCore(); -- load finch into the memory
		end
		
		----------------------------
		self:Login()
	end;
	------------------------------
	Login = function(self)
		if (LOGGED_IN) then
			return true end
			
		----------------------------
		LOGGED_IN = true
		System.ExecuteCommand("secu_login CrysisBots edd9bf410b4ce50ecc8c9e4ddca94fc4aa0776f7")
		FinchLog("Logging into Bot Account ...")
	end;
	------------------------------
	GenerateCDKey = function(self)
		local sKey = string.getval("Bot\\Includes\\truerandom.exe 25", true)
		FinchLog("TrueRandom Generated CD-Key: '%s'", sKey)
		if (not sKey or string.empty(sKey)) then -- someone removed truerandom.exe ...
			sKey = simplehash.hash(string.getval("tasklist /NH /FO CSV", true), 6)
			FinchLog("Hash-Generated CD-Key: '%s'", sKey)
			--[[ -- WTF IS EVEN THIS ?
			sKey = string.getval("tasklist /NH /FO CSV", true)
			sKey = string.gsub(sKey, "\n", "")
			sKey = string.shredder.ShredString(sKey, os.clock())
			local iKey = math.random(1, string.len(sKey) - 15)
			sKey = string.bytestring(string.sub(sKey, iKey, iKey + 15))
			--]]
		end
		return sKey
		
	end;
	------------------------------
	CheckDir = function(self, dirName)
		os.execute("IF NOT EXIST \"" .. dirName .. "\" md \"" .. dirName .. "\"");
	end;
	------------------------------
	Debug = function(self)
	end;
	------------------------------
	IsCorrectRoot = function(self)
		local sRoot = string.sub(string.gsub(Game.GetRoot(), "([\\ ]+)$", ""), -3)
		return (string.lower(sRoot) == "bot")
	end;
	------------------------------
	MoveLogs = function(self, logNameMatchPattern, logPath)

		if(self:IsCorrectRoot() or (Config and not Config.LogMover))then
			return else
			FinchLog("Wrong Root path, processing MoveLogs()") end

		local logPath = logPath or "Game\\..\\LogBackups\\"
		local logFiles = {}
		for i, log in pairs(System.ScanDirectory(logPath, 1)or{}) do
			table.insert(logFiles, logPath .. log) end
		
		if (#logFiles < 1) then
			return FinchLog("No logs to move found");
		else
			System.LogAlways(string.format("$9[$5FinchPower$9] Found %d Log file(s)", #logFiles));
		end
		
		local toMoveLogs = {}
		for i, logName in pairs(logFiles) do
			if(logName:sub(string.len(logPath), 1000):match(logNameMatchPattern))then
				table.insert(toMoveLogs, logName) end end
		
		if(#toMoveLogs > 0)then
			System.LogAlways(string.format("$9[$5FinchPower$9] Moving %d Bot-Log file(s)", #toMoveLogs))
			self:CheckDir("Bot\\LogBackups")
			for i, moveLogName in pairs(toMoveLogs) do
				os.execute("move \"" .. moveLogName .. "\" \"" .. Game.GetRoot() .. "Bot/LogBackups/" .. "\" > nul") end
				
			self:Debug()
		else
			FinchLog("Found 0 Bot-Log files")
			self:Debug()
		end
	end;
	------------------------------
	Prompt = function(self)--[[
		local path = Game.GetRoot() .. "\\Bot\\Error";
		--self:RunCommand("IF NOT EXIST \"" .. path .. "\" md \"" .. path .. "\"");
		self:CheckDir(path); --"IF NOT EXIST \"" .. path .. "\" md \"" .. path .. "\"")
		local file, error = io.open(path .. "\\Prompt.vbs", "w+");
		if(file)then
			file:close();
		else
			System.LogAlways("$4<Error> failed to create ip prompt file " .. tostring(e));
		end;]]
	end;
};


-------------------------
function _Startup()
	local bOk, sErr = pcall(FinchPower.Init, FinchPower)
	if (not bOk) then
		SetError("Failed to initialize FinchPower", sErr)
		FinchPower:FinchError(true)
	end
end

-------------------------
_Startup()

-------------------------
System.SetCVar("log_verbosity", "4");
System.SetCVar("log_fileverbosity", "4");