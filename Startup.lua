--------------------------------------------------------
-- CryMP-Bot
--
-- Authors:
--  - Marisa
--
-- History:
--  Created ........ : 12/01/2024
--  Last Modified .. : 12/01/2024

-----------
System.ClearConsole()
math.randomseed(os.time())

-----------
if (loadstring == nil) then
	loadstring = load -- In lua 5.3 this was renamed
end

-----------
CRYMP_BOT_VERSION = "0.0"
CRYMP_BOT_ROOT = "CryMP-Bot"
CRYMP_BOT_LOGSUFFIX = "[CryMP-Bot] " -- Console log prefix
CRYMP_BOT_LOGSUFFIX_ERROR = "[CryMP-Bot] Error: " -- Console log prefix
CRYMP_BOT_LOGSUFFIX_WARNING = "[CryMP-Bot] Warning: " -- Console log prefix
CRYMP_BOT_API_LOGSUFFIX = "[BotAPI] " -- Console log prefix
CRYMP_BOT_LOGGED = {} -- Logged Messages
CRYMP_BOT_LOGSTARS = string.rep("*", 60)
CRYMP_BOT_FORCEDCVARS = {

	BOT_USE_HWID = 0,
	BOT_ALLOW_PAKS = 0,
	BOT_ALLOW_RPC = 0,
	BOT_SHOW_RPC = 0,
	CON_RESTRICTED = 0,
	BOT_NORPC = 0, -- skip rpc
	BOT_NORPC_URL = 1, -- dont download external files
	BOT_NO_SOUNDSYSTEM = 1, -- no sound system was loaded (MUST BE >0 IF IT WASNT LOADED, ELSE CRASH)
}

-----------
BOT_SAFE_CALLS = true -- Ignored in developer mode (???)
BOT_DEV_MODE = true -- Developer mode
BOT_LUA_LOADED = false
BOT_LAST_CONNECT = nil
BOT_LAST_AUTOCONNECT = nil
BOT_INITIALIZED = false

-----------
BotDLL = {}
BotDLL.MessageBox = Game.ShowMessageBox
BotDLL.RayTraceA = Game.Bot_RayTraceCheck
BotDLL.RayRayWorldI = Game.Bot_RayWorldIntersection
BotDLL.GetPID = Game.GetGameProcessId
BotDLL.GetCDKey = Game.GetRandomCDKey
BotDLL.CreateDir = Game.CreateFolder
BotDLL.CreateDirA = Game.CreateNewDirectory

-----------
LAST_ERROR_NAME = "N/A"
LAST_ERROR = "N/A"

-----------
SYSTEM_INTERRUPTED = false
SYSTEM_INTERRUPTED_LAST = nil

-----------
Exec = System.ExecuteCommand

-----------
SystemLog = function(sFormat, ...)
	local sMsg = sFormat
	if (...) then
		sMsg = string.format(sFormat, ...)
	end

	if (not string.split) then
		System.LogAlways(sMsg)
		return
	end

	local aLines = string.split(sMsg, "\n")
	if (#(aLines) >= 1) then
		for i, sLine in pairs(aLines) do
			System.LogAlways((string.empty(sLine) and " " or sLine))
		end
	else
		System.LogAlways(sMsg)
	end
end

-----------
BotLog = function(sFormat, ...)
	local sMsg = sFormat
	if (...) then
		sMsg = string.format(sFormat, ...)
	end
	SystemLog(string.format("%s%s", CRYMP_BOT_LOGSUFFIX, sMsg))
end

-----------
BotLogError = function(sFormat, ...)
	local sMsg = sFormat
	if (...) then
		sMsg = string.format(sFormat, ...)
	end
	SystemLog(string.format("%s%s", CRYMP_BOT_LOGSUFFIX_ERROR, sMsg))
end

-----------
BotLogWarning = function(sFormat, ...)
	local sMsg = sFormat
	if (...) then
		sMsg = string.format(sFormat, ...)
	end
	SystemLog(string.format("%s%s", CRYMP_BOT_LOGSUFFIX_WARNING, sMsg))
end

-----------
BotLogEx = function(sMsg)
	SystemLog(CRYMP_BOT_LOGSUFFIX .. tostring(sMsg))
end

-----------
BotAPILog = function(sFormat, ...)
	local sMsg = sFormat
	if (...) then
		sMsg = string.format(sFormat, ...)
	end
	SystemLog(string.format("%s%s", CRYMP_BOT_API_LOGSUFFIX, sMsg))
end

-----------
BotLog_Timer = function(iTimer, sMsg, ...)

	----------------
	local sHandle = tostring(sMsg)
	if (simplehash) then
		sHandle = simplehash.hash(sHandle, 4) end

	----------------
	local iLastMessage = CRYMP_BOT_LOGGED[sHandle]
	if (not iLastMessage or (_time - iLastMessage >= iTimer)) then
		BotLog(sMsg, ...)
		CRYMP_BOT_LOGGED[sHandle] = _time
	end
end

-----------
function SetError(sError, sCode)
	LAST_ERROR_NAME = sError
	LAST_ERROR = sCode
end

-----------
BotError = function(bQuit, bReloadFile)

	---------
	SCRIPT_USE_CRYERROR = true
	SYSTEM_INTERRUPTED = true
	SystemLog(">> SYSTEM_INTERRUPTED")

	---------
	local sStars = CRYMP_BOT_LOGSTARS
	local sError_Name = tostring(LAST_ERROR_NAME)
	local sError_Desc = tostring(LAST_ERROR)

	SystemLog(sStars)
	SystemLog("$9<$4ERROR$9>");
	SystemLog("$9 -> Name: $1" .. tostring(LAST_ERROR_NAME))
	SystemLog("$9 -> Description: ")
	if (string.match(sError_Desc, "\n*")) then

		if (BOT_LUA_LOADED) then
			for i, sLine in pairs(string.split(sError_Desc, "\n")) do
				SystemLog("     $1" .. sLine);
			end
		else
			for sLine in string.gmatch(sError_Desc, "[^\n]+") do
				SystemLog("     $1" .. sLine);
			end
		end
	else
		SystemLog("     $1" .. sError_Desc);
	end
	SystemLog("$9 ");
	SystemLog("$9[DEBUG]");

	if (BOT_LUA_LOADED) then
		SystemLog(table.tostring(Bot.aCfg, "  ", "Config = "))
		SystemLog(" ");
	else
		SystemLog("$9BotLua not loaded")
	end

	SystemLog("$9%s", checkString(debug.traceback(), "<traceback failed>"))
	SystemLog("$9 ");
	SystemLog("$9Date: %s", os.date())
	SystemLog("$9Version: %s", CRYMP_BOT_VERSION)
	SystemLog("$9Developer: %s", string.bool(BOT_DEV_MODE)) -- DANGEROUS! string.bool CAN BE NULL!!
	SystemLog("$9 ");
	SystemLog("$9(Send this Bot.log to shortcut0 on Discord for more info)")
	SystemLog(sStars)

	if (Config and Config.UseErrorBox) then
		BotDLL.MessageBox(string.format("Script Error (%s)\n*************************\n%s\n*************************\nCheck Console for more info or open Bot.log", sError_Name, sError_Desc), "Error", 0+16)
	end

	if (bQuit) then
	--	System.Quit("Script Error")
	end
end

-----------
if (System.OldQuit == nil) then
	System.OldQuit = System.Quit 
end
System.Quit = function(sCaller, ...)
	BotLog("System.Quit(" .. tostring((sCaller or "Unknown Caller")) .. ")")
	
	--System.SetCVar("log_Verbosity", "0")
	--System.SetCVar("log_fileVerbosity", "0")

	-- Never quit in devmode
	if (BOT_DEV_MODE) then
		return
	end

	return System.OldQuit(...)
end

-----------
BotMain = {}

-----------
BotMain.RECONNECT_IF_KICKED = true
BotMain.RECONNECT_TRIES = 3
BotMain.RECONNECT_REASONS_BLACKLIST = { 'kicked', 'banned' }
BotMain.CONNECT_IP = nil
BotMain.CONNECT_PORT = nil
BotMain.CONNECT_PASSWORD = nil
BotMain.CD_KEY = nil
BotMain.ZOMBIE_QUIT = false
BotMain.GENERATE_CD_KEY = true
BotMain.I_PEE_LIST = nil
BotMain.IGNORE_IP_CHECK = true

----------
-- Reload
BotMain.Reload = function(self)

	BOT_INITIALIZED = false
	IS_RELOAD = true
	Exec('reloadBot')

end
----------
-- Init
BotMain.Init = function(self)

	BOT_INITIALIZED = false
	BotLog("Initializing BotMain")

	-------------------
	local iPID = BotDLL.GetPID()
	if (iPID) then
		math.randomseed(iPID) else
		BotLog("Failed to Retrieve current Process ID") end

	-------------------
	-- Force CVars
	self:ForceCVars()

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
	--if (not self:LoadLauncherConfig()) then
	--	return false end

	-------------------
	if (not self:CreateAPI()) then
		return false end

	-------------------
	if (not self:SelectServer(BotMain.CONNECT_IP, BotMain.CONNECT_PORT, BotMain.CONNECT_PASSWORD)) then
		return false end

	-------------------
	if (not self:PatchGameRules()) then
		return false end

	-------------------
	--if (not self:CheckBot()) then
	--	return false end

	-------------------
	BotLog("BotMain Initialized")

	-------------------
	if (BOT_CONNECTED) then
		self:LoadBotMain()
		if (Bot) then
		--	Bot:Init() -- Already called when loading the file
		end
	end
	--if (Bot and BOT_CONNECTED) then
	--	Bot:Init()
	--end

	-------------------
	IS_RELOAD = false
	BOT_INITIALIZED = true

	-------------------
	return true
end

----------
-- Init
BotMain.ForceCVars = function(self)

	if (not CRYMP_BOT_FORCEDCVARS) then
		return
	end

	for sName, pValue in pairs(CRYMP_BOT_FORCEDCVARS) do
		Game.ForceCVar(sName, tostring(pValue))
		BotLog("Forcing CVar %s to %s", sName, tostring(pValue))
	end

	return true
end

----------
-- Init
BotMain.CheckBot = function(self)

	if (not BOT_CONNECTED) then
		return true end

	if (not BOT_LOADED) then
		self:LoadBotFile()
	end

	return true
end

----------
-- Init
BotMain.AddCommands = function(self)
	---------------------
	local sPrefix = "BotMain_"
	local aCVars = {
		{ "reload",   "BotMain:Reload()",            "Reloads the BotMain File" },
		{ "init",     "BotMain:Init(true)",          "Re-initializes the BotMain" },
		{ "initlibs", "BotMain:LoadLibraries(true)", "Reloads the BotMain Libraries" }
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
	BotLog("Registered %d New Console Commands", iCVars)

	---------------------
	return true
end

----------
-- Init
BotMain.LoadFile = function(self, sFile)

	-----------------------
	local bOk, sErr = pcall(loadfile, sFile)
	if (not bOk) then
		SetError("Failed to load File " .. sFile, (sErr or "<Unknown Cause>"))
		return false, BotError(true)
	else
		bOk, sErr = pcall(sErr)
		if (bOk == false) then
			SetError("Failed to execute File " .. sFile, (sErr or "<Unknown Cause>"))
			return false, BotError(true)
		end
	end

	-----------------------
	BotLog("FILE OK -> " .. sFile)

	-----------------------
	return true, sErr
end;

----------
-- Init
BotMain.LoadLibraries = function(self)

	-----------------------
	BotLog("Loading Libraries")

	-----------------------
	local sLibPath = CRYMP_BOT_ROOT .. "\\Includes\\"
	local aLibs = {
		"\\ini.utils.lua",
		"\\lua.utils.lua",
		"\\timer.utils.lua",
		"\\vector.utils.lua",
		"\\math.utils.lua",
		"\\bitwise.utils.lua",
		"\\string.utils.lua",
		"\\table.utils.lua",
		"\\file.utils.lua",
		"\\string.shred.lua",
		"\\simplehash.lua",
		"\\crypt.utils.lua",
		"\\md5.lua"
	}

	-----------------------
	local bOk, hLib
	for i = 1, (#aLibs) do
		bOk, hLib = self:LoadFile(sLibPath .. aLibs[i])
		if (not bOk) then
			return false end
	end

	-----------------------
	BotLog("All Libraries loaded")

	return true
end;

----------
-- Init
BotMain.LoadConfigFile = function(self)

	-----------------------
	local sConfigPath = CRYMP_BOT_ROOT .. "\\Config.lua";

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
				BotLog("Parsed Server Info (IP: %s, Port: %s, Pass: '%s') from String %s", self.CONNECT_IP, self.CONNECT_PORT, (self.CONNECT_PASSWORD or ""), sServer)
			end
		end
	end

	-----------------------
	BotLog("Loaded %d Configuration entries", table.count(Config))

	-----------
	return true
end;

----------
-- Init
BotMain.LoadLauncherConfig = function(self)


	----------------
	-- fixme: enable
	--do return true end

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
		return true, BotLog("Preset File not found: %s", sIniPath)
	end

	BotLog("Loading Launcher Preset INI: %s", sIniPath)
	local aKeys = {
		["_AutoReconnect_"] 	= { "BotMain.RECONNECT_IF_KICKED",			true },
		["_MaxReconnects_"] 	= { "BotMain.RECONNECT_TRIES",				300 },
		["_ZombieQuit_"] 		= { "BotMain.RECONNECT_IF_KICKED",			true },
		["_AutoQuit_"] 			= { "BotMain.ZOMBIE_QUIT",		true },
		["_ConIP_"] 			= { "BotMain.CONNECT_IP",		nil },
		["_ConPort_"] 			= { "BotMain.CONNECT_PORT",		nil },
		["_ConPassword_"] 		= { "BotMain.CONNECT_PASSWORD",	nil },
		["_AutoQuitTriggers_"] 	= { function(v)BotMain.RECONNECT_REASONS_BLACKLIST = string.split(v, '|') end,	"admin|kicked|banned" },
		["_StringCDKey_"]	 	= { "BotMain.CD_KEY",			nil },
		["_RandomCDKey_"] 		= { "BotMain.GENERATE_CD_KEY",	true },
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
		["_AutoCVars_"]				= { function(v) Config.AutoCVars = BotMain:ParseCVars(string.split(v)) or {} end, 	"" }, -- !!TODO
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
		-- BotLog(tostring(iniKey) .. " == " .. tostring(sIni))
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
				BotLog(tostring(sKey) .. " == " .. tostring(sLoad))
			else
				BotLog("Skipped Key %s (%s)", sKey, sLoad)
			end
		end
	end

	--------------------------------------------
	BotLog("Loaded %d Config Keys", iKeysRead)
	BotLog("Loaded Preset file")

	-----------
	return true
end;

----------
-- Init
BotMain.ParseCVars = function(self, aCVarsString)
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

----------
-- Init
BotMain.CreateAPI = function(self)

	----------------------------
	BotLog("Initializing API")

	-----------------------
	local sAPIPath = CRYMP_BOT_ROOT .. "\\BotAPI.lua";

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
	BotLog("API Initialized")

	-----------
	return true
end;

----------
-- Init
BotMain.PatchGameRules = function(self)

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

----------
-- Init
BotMain.UninstallBot = function(self, sReason, sInfo)

	BotLog(CRYMP_BOT_LOGSTARS)
	BotLog("Bot was disconnected from Server: " .. tostring(sReason));

	---------------------
	if (Bot) then
		BotLog("Bot was Uninstalled")
	else
		BotLog("First-Launch Disconnect (Or never successfully connected)")
	end

	---------------------
	RECONNECT_TRIES = (RECONNECT_TRIES or 0) + 1

	---------------------
	local bQuit = false

	---------------------
	local bAutoReconnect = self.RECONNECT_IF_KICKED
	if (not bAutoReconnect) then
		bQuit = true
		BotLog("Not Reconnecting to Server (Auto Reconnect is disabled)")
	end

	---------------------
	local bIsBlacklisted = self:IsBlacklistedReason(sReason)
	if (bIsBlacklisted) then
		bQuit = true
		BotLog("Not Reconnecting to Server (Disco Reason contains blacklisted word)")
	end

	---------------------
	local bServerOffline = self:IsServerProbablyOffline(sReason)
	if (bServerOffline) then
		bQuit = true
		BotLog("Not Reconnecting to Server (Server is probably offline)")
	end

	---------------------
	local bIsInvalidPassword = self:IsInvalidPassword(sReason)
	if (bIsInvalidPassword) then
		bQuit = true
		BotLog("Not Reconnecting to Server (Invalid Server Password)")
	end

	---------------------
	local bRetiresExceeded = (RECONNECT_TRIES > self.RECONNECT_TRIES)
	if (bRetiresExceeded) then
		bQuit = true
		BotLog("Not Reconnecting to Server (Maximum Reconnection retries exceeded)")
	end

	---------------------
	if (not bQuit) then
		BotLog("Reconnecting to Server (Attempt " .. RECONNECT_TRIES .. " of " .. self.RECONNECT_TRIES .. ")");
		self:Connect(true)
	elseif (self.ZOMBIE_QUIT) then
		BotLog("Impossible to Reconnect, Shutting down bot")
		System.Quit("Zombie Mode")
	else
		BotLog("Bot staying idle after Disconnect !")
	end
end

----------
-- Init
BotMain.IsServerProbablyOffline = function(self, r)
	return string.matchex(r, "Connection attempt to ((%d+)%.(%d+)%.(%d+)%.(%d+):(%d+)) failed", "Connection attempt to ((.*):(%d+)) failed")
end

----------
-- Init
BotMain.IsInvalidPassword = function(self, r)
	return (string.match(r, "Authentication password is wrong"))
end

----------
-- Init
BotMain.IsBlacklistedReason = function(self, r)

	-- causes stack overflow (BUT WHy????)
	return (string.findex(r, unpack(checkArray(self.RECONNECT_REASONS_BLACKLIST))))
	--local sReason = string.lower(r)
	--for i, listed in pairs(self.RECONNECT_REASONS_BLACKLIST or{}) do
	--	if (string.find(sReason, listed:lower())) then
	--		return true end end
	--
	--return false
end

----------
-- Init
BotMain.OnDisconnect = function(self)
	BOT_CONNECTED = false
end

----------
-- Init
BotMain.OnPreConnect = function(self)

	if (g_localActor.ON_CONNECTED) then
		return false end

	g_localActor.ON_CONNECTED = true
	BotMain:OnConnected(g_localActor)
end

----------
-- Init
BotMain.LoadBotFile = function(self)

	---------------------
	BotLog("Loading Bot File")

	---------------------
	BOT_LOADED = self:LoadBotCore()
end

----------
-- Init
BotMain.OnConnected = function(self, player)

	---------------------
	BOT_CONNECTED = true -- dafuq?
	_Connected = false   -- ^^^^^^

	---------------------
	BotLog(CRYMP_BOT_LOGSTARS)
	self:LoadBotFile()

	---------------------
	BotLog("Patching Game Rules")

	---------------------
	g_gameRules.server:RequestSpectatorTarget(g_localActor.id, 111) -- to idenfity bots
	Bot:OnEnteredServer()

	---------------------
	self:PatchGameRules()
	Script.SetTimer(2500, function()
		BotMain:PatchGameRules() end)

	---------------------
	BotLog("Game Rules Patched")
end

----------
-- Init
BotMain.ValidServer = function(self, sAddress)
	return true
end

----------
-- Init
BotMain.SelectServer = function(self, sIP, iPort, sKey)

	if (not sIP or not iPort) then
		SetError("Connection Failed", "Not all necessary params for SelectServer() were provided.");
		return false, BotError(true)
	end

	if (not self:ValidServer(sIP)) then
		SetError("Invalid Server IP", "Unable to contact server with IP " .. sIP)
		return false, BotError(true)
	end

	I_PEE_PORT = sIP .. ":" .. iPort
	SERVER_PASSWORT = (sKey or "")

	BotLog("Selected Server: " .. I_PEE_PORT .. " Password: " .. SERVER_PASSWORT)

	-----------
	return true
end

----------
-- Init
BotMain.LoadBotMain = function(self)

	SetError("Failed to load Bot.lua", "Unknown Error")

	local sBotPath = CRYMP_BOT_ROOT .. "\\Core\\BotMain.lua"
	local bOk, sErr = self:LoadFile(sBotPath)
	if (not bOk) then
		return false
	end

	return true
end

----------
-- Init
BotMain.LoadBotCore = function(self)

	SetError("Bot Lua Loaded but Bot is NUll", "Bot is Null")
	Exec("exec " .. CRYMP_BOT_ROOT .. "\\Core\\InitBot.cfg") -- execute bot configuration file

	if (not self:LoadBotMain()) then
		return false, BotError()
	end

	if (not Bot) then
		return false, BotError()
	end

	return true, BotLog("Bot was loaded Successfully!")
end

----------
-- Init
BotMain.PreConnect = function(self)

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
	if (BOT_LAST_CONNECT and (_time - BOT_LAST_CONNECT <= 300)) then
		bOk = false end

	-----------------
	if (bOk) then
		self:Connect(true)
	else
		BotLog_Timer(30, "Not connecting to Server yet")
	end
end

----------
-- Init
BotMain.Wait = function(self)
	self:PreConnect()
end

----------
-- Init
BotMain.Connect = function(self, force)

	----------
	local sCDKey = (self.CD_KEY or "XXXXXXXXXXXXXXXXXXXX")
	if (self.GENERATE_CD_KEY) then
		BotLog("Generating Random CD-Key")
		sCDKey = self:GenerateCDKey()
		self.CD_KEY = sCDKey
	end

	----------
	if (Config and Config.AutoConnect ~= true) then
		return false
	end

	----------
	BOT_LAST_AUTOCONNECT = _time

	----------
	BotLog("***************************************************")
	BotLog("Connecting ...");

	----------
	local bConnect = force
	if (not bConnect) then
		bConnect = (not g_gameRules and not _Connected)
	end

	----------
	if (bConnect) then
		BotLog("Connecting to " .. I_PEE_PORT .. " *= " .. SERVER_PASSWORT);
		BotLog("CD-Key: %s", sCDKey);
		Script.SetTimer(1000, function()
			_Connected = true
			Exec("net_set_cdkey " .. sCDKey)
			Exec("sv_password " .. SERVER_PASSWORT)
			Exec("connect " .. I_PEE_PORT)
		end)
		BOT_LAST_CONNECT = _time

	elseif (g_gameRules) then
		BOT_LOADED = self:LoadBotCore()
	end

	----------
	self:Login()
end

----------
-- Init
BotMain.Login = function(self)

	if (LOGGED_IN) then
		return true
	end

	----------
	LOGGED_IN = true
	Exec("secu_login CrysisBots edd9bf410b4ce50ecc8c9e4ddca94fc4aa0776f7")
	BotLog("Logging into Bot Account ...")
end

----------
-- Init
BotMain.GenerateCDKey = function(self)

	local sKey = BotDLL.GetCDKey()
	if (sKey) then
		return sKey
	end

	sKey = string.getval(CRYMP_BOT_ROOT .. "\\Includes\\truerandom.exe 25", true)
	BotLog("TrueRandom Generated CD-Key: '%s'", sKey)
	if (string.empty(sKey)) then -- someone removed truerandom.exe ...
		sKey = simplehash.hash(BotDLL.GetPID(), 6)
		BotLog("Hash-Generated CD-Key: '%s'", sKey)
	end
	return sKey
end

-----------
-- Init
BotMain.IsCorrectRoot = function(self)
	local sRoot = string.sub(string.gsub(Game.GetRoot(), "([\\ ]+)$", ""), -3)
	return (string.lower(sRoot) == CRYMP_BOT_ROOT)
end

-----------
function Startup()
	local bOk, sErr = pcall(BotMain.Init, BotMain)
	if (not bOk) then
		SetError("Failed to initialize BotLua", sErr)
		BotError(true)
	end
end

-----------
Startup()