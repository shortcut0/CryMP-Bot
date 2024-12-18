---=====================================================
--- CopyRight (c) R 2022-2203
---
--- Author: Marisa
---
--- Description:  AI System and utilities for the CryMP bot project
---
--- Events Info:
---
---  -> Callers:
---      -> AIEvent(event, ...) - Calls an AI event without return expectations
---	     -> AIEventGet(event, returns, ...) - Calls an AI event and returns true/false if the response matches with 'returns'-argument (array or single item)
---      -> AIEventGetStr(event, default, ...) - Calls an AI event and forces the return to be a string (or true, if the response matches 'default'-argument)
---
---  -> Events (TBA):
---      -> LeaveVehicleForTarget, 	Request if the bot should leave it's vehicle for a specific target
---      -> ProcessInVehicle, 		Called every frame that the bot is inside a vehicle
---      -> OkInVehicle,			Called every frame that the bot is inside a vehicle
---      -> ValidateVehicle,		Asks if the current vehicle is okay
---
---      -> IsCapturing, 			Asks if the Bot is currently capturing a building (PS Only)
---
---      -> IsTargetOk,				Asks if the current target is okay (to be selected)
---      -> OkTargetLost,			Called when the bot lost it's current target
---      -> OkTargetAcquired,		Called when the bot acquires a new target
---      -> ValidateTarget,			Asks if the current target is okay
---
---      -> GetIdleWeapon,			Requests a new idle weapon to be selected that frame
---      -> OnIdleWeapon,			Called every frame where the bot chose to select an idle weapon
---
---      -> Inventory_FoundC4,			 Called when the bot found a C4 in it'S inventory
---      -> Inventory_FoundClaymore,	 Called when the bot found a claymore in it'S inventory
---      -> Inventory_CanPlaceExplsoive, Asks if the bot is allowed to place an explosive
---      -> OnExplosivePlaced,			 Called when the bot placed an explosive (clay, c4)
---
---      -> CanGoIdle,			 	Asks if the bot is allowed to go idle
---
---      -> OnPathProbablyEnded,	Called when the bots current path probably ended..
---
---
---
---=====================================================

AILog = function(msg, ...)
	local sFmt = "$9[$3BotAI$9] $9" .. tostring(msg)
	if (...) then
		sFmt = string.format(sFmt, ...) end
		
	SystemLog(sFmt)
end

-------------------
AILogError = function(msg, ...)
	local sFmt = "$9[$3BotAI$9] [$4Error$9] " .. tostring(msg)
	if (...) then
		sFmt = string.format(sFmt, ...) end
		
	SystemLog(sFmt)
end

-------------------
AILogWarning = function(msg, ...)
	local sFmt = "$9[$3BotAI$9] [$7Warning$9] " .. tostring(msg)
	if (...) then
		sFmt = string.format(sFmt, ...) end
		
	SystemLog(sFmt)
end

-------------------
BotAI = {
	version = "0.0",
	author = "shortcut0",
	description = "AI System and utilities for the bot"
}

-------------------

BOTAI_LOGGING_VERBOSITY = 4

CURRENT_SV_MODULE_PATH = nil
CURRENT_MODULE_PATH = nil

-------------------

BotAI.SHARED_VARS = {}
BotAI.AI_MODULES = {}
BotAI.AI_SV_MODULES = {}
BotAI.CURRENT_SV_MODULE = nil
BotAI.CURRENT_MODULE = nil

-------------------

eAI_gIsBuildingContested = "isContested"
eAI_gInBuyArea = "inBuyArea"
eAI_gInCaptureZone = "inCaptureZone"

-------------------

eAIPoint_None = (inc(1, "*2") - 1) -- 0
eAIPoint_Jumpable = inc()	-- 2
eAIPoint_NarrowPath = incEnd()	-- 2

eAIPoint_None_Str = "None"
eAIPoint_Jumpable_Str = "Jumpable"
eAIPoint_NarrowPath_Str = "Narrow"

-------------------

AISetGlobal = GetDummyFunc()
AIGetGlobal = GetDummyFunc()

AIEvent = GetDummyFunc()
AIEventGet = GetDummyFunc()
AIEventGetStr = GetDummyFunc()

AIEVENT_DEAD = 0xDEAD
AIEVENT_ABORT = -64087
AIEVENT_OK = -64089

AIGET_OK = { AIEVENT_DEAD, AIEVENT_OK }
AIGET_ABORT = { AIEVENT_DEAD, AIEVENT_ABORT }

-------------------
-- Init

BotAI.Init = function(self, bReload)
	
	------------
	if (bReload) then
		self.AI_MODULES = {} end

	AISetGlobal = self.SetGlobal
	AIGetGlobal = self.GetGlobal
	AIEvent = self.CallEvent
	AIEventGet = self.CallEvent_Get
	AIEventGet_Ovr = self.CallEvent_Get_Overwrite
	AIEventGetStr = self.CallEvent_GetStr
	AIEventGetVec = self.CallEvent_GetVec
	AIEventGetId = self.CallEvent_GetId
	AIEventGetArray = self.CallEvent_GetArray

	------------
	AILog("BotAI.Init()")
	
	------------
	if (not self:InitCVars()) then
		return false end
	
	---------------------
	if (not self.LoadAIModules()) then
		return false end

	---------------------
	if (not self.LoadChatAI()) then
		return false end

	if (not self:InitChatAI()) then
		return false end

	---------------------
	self:LoadServerIds()
	if (not self.LoadServerSpecific()) then
		return false end

	------------
	self:InitServerModule()
	if (not self:InitAIModule()) then
		return false end

	------------
	AILog("BotAI Initialized")
	
	------------
	return true
end


-------------------
-- InitCVars

BotAI.InitCVars = function(self)

	---------------------
	local sPrefix = "botai_"
	local aCVars = {
	
		---------------
		{ "init",       		"BotAI:Init(true)", 				"Re-initializes the Bot AI System" },
		{ "reloadfile",       	"Bot:LoadAISystem()", 				"Reloads the Bot AI System" },
		{ "logverbosity",		"Bot:SetVariable(\"BOTAI_LOGGING_VERBOSITY\", %1, false, true, true)", "Changes the current log verbosity of the Bot AI System" },
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
	AILog("Registered %d New Console Commands", iCVars)
	
	---------------------
	return true
	
end


-------------------
-- InitServerModule

BotAI.InitServerModule = function(self)

	---------------------
	AILog("BotAI.InitServerModule()")

	---------------------
	local sGameRules = g_gameRules.class
	local aModules = self.AI_SV_MODULES
	local hModule

	local sCurrentAddr = BotMain.CONNECT_IP
	local sCurrentPort = BotMain.CONNECT_PORT

	for sModule, xModule in pairs(aModules) do
		local sName, sPort = string.match(sModule, "^(%d+%.%d+%.%d+%.%d+):?(.*)$")
		AILog("[%20s] Module: %s, %s", sModule, tostring(sName), tostring(sPort))
		if (sName and (sName == sCurrentAddr)) then
			if (not sPort or (sPort == tostring(SERVER_PORT_ANY) or string.match(sCurrentPort, sPort))) then
				hModule = xModule
			end
		end
	end

	---------------------
	if (not hModule) then
		AILogWarning("No Server Module found for Server (%s:%s)", sCurrentAddr, sCurrentPort)
		return
	end

	self.CURRENT_SV_MODULE = hModule
	self.CallSvEvent("OnInit")

	---------------------
	AILog("AI Server Module Initialized")

	---------------------
	return true
end

-------------------
-- InitAIModule

BotAI.InitAIModule = function(self)

	---------------------
	AILog("BotAI.InitAIModule()")

	---------------------
	local sGameRules = g_gameRules.class
	
	---------------------
	local hModule = self:GetAIModule(sGameRules)
	if (not hModule) then
		AILogError("No AI Module found for Game Rules of class '%s'", sGameRules)
		return false end
	
	---------------------
	self.CURRENT_MODULE = hModule
	
	---------------------
	self.CallEvent("OnInit")
	
	---------------------
	AILog("AI Module Initialized")
	
	---------------------
	return true
	
end


-------------------
-- LoadServerIds

BotAI.LoadServerIds = function()

	local sFile = (CRYMP_BOT_ROOT .. "\\Core\\AI\\Servers.lua")
	local bOk, sErr = BotMain:LoadFile(sFile)
	if (not bOk) then
		AILogWarning("Failed to load the ServerIds file \"%s\" (%s)", sFile, checkString(sErr, string.UNKNOWN))
	end
end

-------------------
-- LoadServerSpecific

BotAI.LoadServerSpecific = function()

	---------------------
	AILog("Loading AI Server-Specific Modules")

	---------------------
	local sModulePath = CRYMP_BOT_ROOT .. "\\Core\\AI\\ServerModules\\"

	---------------------
	local aModuleFiles = System.ScanDirectory("..\\" .. sModulePath, SCANDIR_FILES)
	if (table.count(aModuleFiles) == 0) then
		AILog("No AI Server Modules found in '%s'", sModulePath)
		return true end

	---------------------
	local iLoadedFiles = 0
	for i, sFile in pairs(aModuleFiles) do
		local sPath = string.format("%s%s", sModulePath, sFile)

		---------
		CURRENT_SV_MODULE_PATH = sPath

		---------
		local bOk, hModule = BotMain:LoadFile(sPath)
		if (not bOk) then
			AILog("Failed to Load AI Server Module '%s' (%s)", sPath, (hModule or "<No error info>"))
		else
			iLoadedFiles = iLoadedFiles + 1
		end
	end

	---------------------
	AILog("Loaded %d AI Server Modules", iLoadedFiles)
	return true
end


-------------------
-- LoadAIModule

BotAI.LoadAIModules = function()

	---------------------
	AILog("Loading AI Modules")

	---------------------
	local sModulePath = CRYMP_BOT_ROOT .. "\\Core\\AI\\Modules\\"
	
	---------------------
	local aModuleFiles = System.ScanDirectory("..\\" .. sModulePath, SCANDIR_FILES)
	if (table.count(aModuleFiles) == 0) then
		AILog("No AI Modules found in '%s'", sModulePath)
		return true end
	
	---------------------
	local iLoadedFiles = 0
	for i, sFile in pairs(aModuleFiles) do
		local sPath = string.format("%s%s", sModulePath, sFile)
		
		---------
		CURRENT_MODULE_PATH = sPath
		
		---------
		local bOk, hModule = BotMain:LoadFile(sPath)
		if (not bOk) then
			AILog("Failed to Load AI Module '%s' (%s)", sPath, (hModule or "<No error info>"))
		else
			iLoadedFiles = iLoadedFiles + 1
		end
	end

	---------------------
	BOT_ENTITY_DATA_PROCESSED = checkGlobal("BOT_ENTITY_DATA_PROCESSED", {}, checkArray)
	BOT_ENTITY_DATA = nil
	BotAI:LoadEntityData()

	---------------------
	if (isArray(BOT_ENTITY_DATA_PROCESSED)) then
		for idEntity, hEntity in pairs(BOT_ENTITY_DATA_PROCESSED) do
			if (hEntity.OLD_POSITION) then
				hEntity.GetPos = hEntity.OLD_POSITION
				AILog("Reset entity")
			end
		end
	end

	---------------------
	if (isArray(BOT_ENTITY_DATA)) then
		local sRules, sMapName = string.match(Bot:GetLevelName(), "Multiplayer/(.*)/(.*)")
		BotMainLog(Bot:GetLevelName())
		local aData = BOT_ENTITY_DATA[g_gameRules.class]
		if (isArray(aData)) then
			local aEntities = aData[sMapName]
			if (isArray(aEntities)) then
				AILog("Found Entity Data for Map %s", sMapName)
				local iPatched = 0
				for i, aLocations in pairs(aEntities) do

					local sType = aLocations.Type
					local aEntities = GetEntities(GET_ALL, nil, function(a)
						--AILog("1")
						local iDist = vector.distance(a:GetPos(), aLocations.Location)
						if (iDist > 5) then
							return false
						end
						if (sType ~= nil and not string.match(a.class, sType)) then
							return false
						end
						AILog("in range: %s", a:GetName())
						return string.match(a:GetName(), aLocations.Name)
					end)

					local vMoves = aLocations.Move
					for i, hEntity in pairs(aEntities) do

						BOT_ENTITY_DATA_PROCESSED[hEntity.id] = hEntity
						hEntity.OLD_POSITION = checkVar(hEntity.OLD_POSITION, hEntity.GetPos)

						hEntity.GetPos = function()
							if (vector.isvector(vMoves)) then
								return vMoves
							end

							if (timerexpired(hEntity.DYNAMIC_POS_UPDATE, 120)) then
								hEntity.DYNAMIC_POS = getrandom(vMoves)
								hEntity.DYNAMIC_POS_UPDATE = timerinit()
							end

							--AILog("Dynamic position: %s", g_TS(hEntity.DYNAMIC_POS))
							return hEntity.DYNAMIC_POS
						end
						AILog("Updated position for entitiy %s", hEntity:GetName())
					end

					AILog("Checking %d", i)
					--local hEntity = System.GetEntityByName(sName)
					--if (hEntity) then
					--end
				end
			end
		end
	end

	---------------------
	AILog("Loaded %d AI Modules", iLoadedFiles)
	
	---------------------
	return true
	
end


-------------------
-- LoadAIModule

BotAI.LoadChatAI = function()

	-----
	AILog("Loading Chat AI...")

	-----
	if (not Bot:LoadFile("Chat.lua", "ChatAI", "AI\\Chat\\")) then
		return false, AILogError("Failed to load the ChatAI System!")
	end

	-----
	return true, AILog("Chat AI System Loaded!")
end


-------------------
-- InitChatAI

BotAI.InitChatAI = function()

	-----
	AILog("Initializing Chat AI...")

	-----
	local bOk, sErr = pcall(BotChatAI.Init, BotChatAI)
	if (not bOk) then
		return false, AILogError("Failed to Initialize the ChatAI System (%s)", (sErr or "N/A"))
	end

	-----
	return true, AILog("Chat AI System Initialized!")
end


-------------------
-- LoadAIModule

BotAI.LoadEntityData = function()

	---------------------
	AILog("Loading AI Entity Data")

	---------------------
	local sDataPath = CRYMP_BOT_ROOT .. "\\Core\\AI\\EntityData.lua"

	---------------------
	local bOk, hModule = BotMain:LoadFile(sDataPath)
	if (not bOk) then
		AILog("Failed to Load Entity Data File '%s' (%s)", sDataPath, (hModule or "<No error info>"))
	else
		AILog("Loaded AI Entity Data")
	end

	---------------------
	return true

end


-------------------
-- GetAIModule

BotAI.GetAIModule = function(self, sClassName)
	return self.AI_MODULES[sClassName]
end

-------------------
-- GetAIModule

BotAI.GetAIServerModule = function(self, sClassName)
	return self.AI_SV_MODULES[sClassName]
end

-------------------
-- GetAIModuleSource

BotAI.GetAIModuleSource = function(self, sClassName)
	local aModule = self:GetAIModule(sClassName)
	if (not aModule) then
		return "" end
		
	return aModule.sSourceFilePath
end

-------------------
-- GetAIServerModuleSource

BotAI.GetAIServerModuleSource = function(self, sClassName)
	local aModule = self:GetAIServerModule(sClassName)
	if (not aModule) then
		return "" end

	return aModule.sSourceFilePath
end


-------------------
-- CreateServerModule

BotAI.CreateServerModule = function(self, sServer, sPort, aProperties)

	---------------------
	if (not sServer) then
		AILogError("No Server Identifier specified to BotAI.CreateServerModule()")
		AILogWarning("Did you forget to declare your Server in Servers.lua?")
		return false end

	---------------------
	AILog("Creating new AI Server Module '%s'", sServer)

	---------------------
	local sClassName = string.format("%s:%s", sServer, sPort)
	if (self:GetAIServerModule(sClassName)) then
		AILogError("AI Server Module '%s' already exists! Source: %s", sServer, self:GetAIServerModuleSource(sClassName))
		return false end

	---------------------
	self.AI_SV_MODULES[sClassName] = aProperties
	self.AI_SV_MODULES[sClassName].ModuleName = sClassName
	self.AI_SV_MODULES[sClassName].ModuleFullName = ("BotAI." .. sClassName)
	self.AI_SV_MODULES[sClassName].sSourceFilePath = (CURRENT_SV_MODULE_PATH or "<unknown>")

	---------------------
	self.RegisterFunctionsForModule(self.AI_SV_MODULES[sClassName])

	---------------------
	AILog("Created AI Server Module '%s'", sClassName)

	---------------------
	return true

end


-------------------
-- CreateAIModule

BotAI.CreateAIModule = function(self, sClassName, aProperties)

	---------------------
	if (not sClassName) then
		AILogError("No Module Name specified to BotAI.CreateAIModule()")
		return false end

	---------------------
	AILog("Creating new AI Module '%s'", sClassName)
	
	---------------------
	if (self:GetAIModule(sClassName)) then
		AILogError("AI Module '%s' already exists! Source: %s", sClassName, self:GetAIModuleSource(sClassName))
		return false end
	
	---------------------
	self.AI_MODULES[sClassName] = aProperties
	self.AI_MODULES[sClassName].ModuleName = sClassName
	self.AI_MODULES[sClassName].ModuleFullName = "BotAI." .. sClassName
	self.AI_MODULES[sClassName].sSourceFilePath = CURRENT_MODULE_PATH or "<unknown>"

	---------------------
	self.RegisterFunctionsForModule(self.AI_MODULES[sClassName])

	---------------------
	AILog("Created AI Module '%s'", sClassName)
	
	---------------------
	return true
	
end

-------------------
-- RegisterFunctionsForModule

BotAI.RegisterFunctionsForModule = function(aModule)


	---------------------
	AILog("Creating Module Functions")
	
	---------------------
	local aFunctions = {
	
		---------------------
		-- ResetPath
		ResetPath = function() Pathfinding:ResetPath() end,
	
		---------------------
		-- ResetPathData
		ResetPathData = function() Pathfinding:ResetPathData() end,
	}
	
	---------------------
	aModule.Funcs = aFunctions

	---------------------
	AILog("Module Functions Created")
	
	---------------------
	return true
	
end


-------------------
-- GetGlobal

BotAI.GetGlobal = function(hGlobal)
	return BotAI.SHARED_VARS[hGlobal]
end

-------------------
-- StGlobal

BotAI.SetGlobal = function(hGlobal, hValue)
	BotAI.SHARED_VARS[hGlobal] = hValue
end

-------------------
-- CallSvEvent

BotAI.CallSvEvent = function(sEventName, ...)

	---------------------
	local self = BotAI

	---------------------
	if (not sEventName) then
		AILogError("No Event Name specified to BotAI.CallSvEvent()")
		return (0xDEAD) end

	---------------------
	if (not self.CURRENT_SV_MODULE) then
		--AILogError("No AI Module loaded (Event Called was %s)", sEventName)
		return (0xDEAD) end

	---------------------
	local aEvents = self.CURRENT_SV_MODULE.Events
	if (not isArray(aEvents)) then
		return (0xDEAD) end

	---------------------
	local fEvent = aEvents[sEventName]
	if (not isFunction(fEvent)) then
		--AILogError("Attempt to call Server event '%s' which is not a function (%s)", tostring(sEventName), type(fEvent))
		return (0xDEAD) end

	return fEvent(self.CURRENT_SV_MODULE, ...)
end

-------------------
-- CallEvent_GetStr

BotAI.CallEvent_GetStr = function(sEventName, sDefault, ...)

	local hRet = AIEvent(sEventName, ...)
	if (not isString(hRet)) then
		return (sDefault)
	end

	return hRet
end

-------------------
-- CallEvent_GetStr

BotAI.CallEvent_GetVec = function(sEventName, vDefault, ...)

	local hRet = AIEvent(sEventName, ...)
	if (not vector.isvector(hRet)) then
		return (vDefault)
	end

	return hRet
end

-------------------
-- CallEvent_GetStr

BotAI.CallEvent_GetArray = function(sEventName, aDefault, ...)

	local hRet = AIEvent(sEventName, ...)
	if (not isArray(hRet)) then
		return (aDefault)
	end

	return hRet
end

-------------------
-- CallEvent_GetStr

BotAI.CallEvent_GetId = function(sEventName, nDefault, ...)

	local hRet = AIEvent(sEventName, ...)
	if (not isEntityId(hRet)) then
		return (nDefault)
	end

	return hRet
end

-------------------
-- CallEvent_Get

BotAI.CallEvent_Get_Overwrite = function(sEventName, aVar, ...)

	local hRet = AIEvent(sEventName, ...)
	if (table.lookup(AIGET_ABORT, hRet)) then
		return false
	end

	--AILog("ret===%s",g_ts(hRet))

	aVar.Value = hRet
	return true
end

-------------------
-- CallEvent_Get

BotAI.CallEvent_Get = function(sEventName, aOks, ...)

	local hRet = AIEvent(sEventName, ...)
	if (not isArray(aOks)) then
		return (hRet == aOks)
	end

	if (table.lookup(aOks, hRet)) then
		return true
	end
	return false
end

-------------------
-- CallEvent

BotAI.CallEvent = function(sEventName, ...)

	---------------------
	local self = BotAI

	---------------------
	if (not sEventName) then
		AILogError("No Event Name specified to BotAI.CallEvent()")
		return (0xDEAD) end

	---------------------
	if (not self.CURRENT_MODULE) then
		--AILogError("No AI Module loaded (Event Called was %s)", sEventName)
		return (0xDEAD) end
	
	---------------------
	local aEvents = self.CURRENT_MODULE.Events
	if (not isArray(aEvents)) then
		return (0xDEAD) end

	---------------------
	local fEvent = aEvents[sEventName]
	if (not isFunction(fEvent)) then
		AILogError("Attempt to call event '%s' which is not a function", sEventName)
		return (0xDEAD) end

	---------------------
	-- AILog("Module[%s]: Calling Event '%s'", self.CURRENT_MODULE.ModuleName, sEventName)

	---------------------
	BotAI.CallSvEvent(sEventName, ...)
	return fEvent(self.CURRENT_MODULE, ...)
	
end


---------------------------------------------
-- BotAI.GetAIPoints

BotAI.GetAIPoints = function(self)
	return {
		eAIPoint_None,
		eAIPoint_Jumpable
	}
end

---------------------------------------------
-- BotAI.GetAIStrPoints

BotAI.GetAIStrPoints = function(self)
	return {
		{ eAIPoint_None, eAIPoint_None_Str },
		{ eAIPoint_Jumpable, eAIPoint_Jumpable_Str },
		{ eAIPoint_NarrowPath, eAIPoint_NarrowPath_Str },
	}
end

---------------------------------------------
-- BotAI.ResolveAIPoints

BotAI.ResolveAIPoints = function(xPoints)

	local aPoints = BotAI.GetAIPoints()
	local sPoints = BitGetAll(xPoints, aPoints)

	return string.gsuba(sPoints, BotAI.GetAIStrPoints())
end