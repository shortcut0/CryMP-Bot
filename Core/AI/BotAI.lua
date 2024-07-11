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

-------------------

BotAI.AI_MODULES = {}

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
	
	------------
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
-- GetAIModuleSource

BotAI.GetAIModuleSource = function(self, sClassName)
	local aModule = self:GetAIModule(sClassName)
	if (not aModule) then
		return "" end
		
	return aModule.sSourceFilePath
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
	return fEvent(self.CURRENT_MODULE, ...)
	
end
