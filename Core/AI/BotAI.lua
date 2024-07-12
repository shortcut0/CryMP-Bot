--=====================================================
-- CopyRight (c) R 2022-2203
--
-- AI System and utilities for the CryMP bot project
--
--=====================================================

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

BotAI.AI_MODULES = {}
BotAI.AI_SV_MODULES = {}
BotAI.CURRENT_SV_MODULE = nil
BotAI.CURRENT_MODULE = nil

-------------------
-- Init

BotAI.Init = function(self, bReload)
	
	------------
	if (bReload) then
		self.AI_MODULES = {} end
	
	------------
	AILog("BotAI.Init()")
	
	------------
	if (not self:InitCVars()) then
		return false end
	
	---------------------
	if (not self.LoadAIModules()) then
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
			if (not sPort or (sPort == tostring(SERVER_PORT_ANY) or sPort == sCurrentPort)) then
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
	BOT_ENTITY_DATA = nil
	BotAI:LoadEntityData()

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
				for sName, vPos in pairs(aEntities) do
					local hEntity = System.GetEntityByName(sName)
					if (hEntity) then
						hEntity.GetPos = function()
							return vPos
						end
					end
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

BotAI.LoadEntityData = function()

	---------------------
	AILog("Loading AI Entity Data")

	---------------------
	local sDataPath = CRYMP_BOT_ROOT .. "\\Core\\AI\\EntityData.lua"

	---------------------
	local bOk, hModule = BotMain:LoadFile(sDataPath)
	if (not bOk) then
		AILog("Failed to Entity Data File '%s' (%s)", sDataPath, (hModule or "<No error info>"))
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
		AILogError("Attempt to call Server event '%s' which is not a function (%s)", tostring(sEventName), type(fEvent))
		return (0xDEAD) end

	return fEvent(self.CURRENT_SV_MODULE, ...)
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
