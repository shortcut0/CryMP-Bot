--=====================================================
-- CopyRight (c) R 2022-2203
--
-- Bot API Functions for C++ Callbacks
--
--=====================================================

-------------------
BotAPI = {
	version = "1.0",
	author = "shortcut0",
	description = "Bot API for C++ Callbacks"
}

-------------------

SYSTEM_INTERRUPTED = nil
SYSTEM_INTERRUPTED_LAST = nil

SCRIPT_CHECK_RUNTIME = function(sSource)

	if (SCRIPT_RUNTIME_ERROR_P or SCRIPT_RUNTIME_ERROR) then
		SetError(string.format("[UNPROTECTED] Error detected last Frame (Source %s)", (sSource or "N/A")), SCRIPT_RUNTIME_MESSAGE)
		BotError(false)
	end

	-----------
	SCRIPT_RUNTIME_ERROR_P = nil
	SCRIPT_RUNTIME_ERROR = nil
	SCRIPT_RUNTIME_MESSAGE = nil
	--BotAPILog("Hello!")
end

-------------------

BotAPI.CONNECTING_PLAYERS = {}
BotAPI.Defaults = {
	-------------------
	ClStartWorking = function(self, entityId, workName)
		self.work_type = workName
		self.work_name = "@ui_work_" .. workName
		HUD.SetProgressBar(true, 0, self.work_name)
	end,
	-------------------
	ClStepWorking = function(self, amount)
		HUD.SetProgressBar(true, amount, self.work_name or "")
	end,
	-------------------
	ClStopWorking = function(self, entityId, complete)
		HUD.SetProgressBar(false, -1, "")
	end,
}

-------------------
-- Init

BotAPI.Init = function(self)
	
	---------------
	BotAPILog("BotAPI.Init() !")

	---------------
	self:InitCVars()
	self.Events:PatchExploits()
	
end

-------------------
-- LogSystemInterrupt

BotAPI.InitCVars = function(self)
	---------------------
	local sPrefix = "botapi_"
	local aCVars = {

		---------------
		{ "init",       		"BotAPI:Init()", 				"Re-initializes the Bot API File" },
		{ "reloadfile", 		"BotMain:CreateAPI()",  				"Reloads the BotAPI file" },
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
	BotAPILog("Registered %d New Console Commands", iCVars)

	---------------------
	return true
end

-------------------
-- LogSystemInterrupt

BotAPI.LogSystemInterrupt = function(self)

	---------------
	if (SYSTEM_INTERRUPTED_LAST ~= nil and SYSTEM_INTERRUPTED_LAST == false and SYSTEM_INTERRUPTED == true) then
		BotLog("<SYSTEM WAS INTERRUPTED>")
	end

	SYSTEM_INTERRUPTED_LAST = SYSTEM_INTERRUPTED
end

-------------------
-- APIReady

BotAPI.APIReady = function(self)

	--------
	if (not g_localActor) then
		return false
	end

	--------
	return true
end

-------------------
BotAPI.Events = {

	APIReady = BotAPI.APIReady
}

-------------------
-- OnTimer

BotAPI.Events.OnTimer = function(self, ...)

	-----------
	pcall(SCRIPT_CHECK_RUNTIME, "TimerTick")

	-----------
	if (SYSTEM_INTERRUPTED) then
		return
	end

	-----------
	--BotAPILog("API Received Timer Tick!")
	if (BOT_SAFE_CALLS and (not BOT_DEBUG_MODE or not BOT_DEV_MODE)) then
		local bOk, sErr = pcall(self.HandleTimer, self, ...)
		if (not bOk) then
			SetError("[SAFE] Error in HandleTimer", sErr)
			BotError(false)
		end
	else

		--BotLog("UNPROTECTED ERRORS")
		self:HandleTimer(...)
	end
end

-------------------
-- HandleTimer

BotAPI.Events.HandleTimer = function(self, timerTime)

	-----------
	--BotAPILog("Tick ...")
	if (SYSTEM_INTERRUPTED) then
		return
	end

	-----------
	if (Config and not Config.System) then
		return
	end

	-----------
	BotMain:Wait()

	-----------
	if (Bot and Bot.PreOnTimer) then
		Bot:PreOnTimer(timerTime)
	end

	-----------
	self:PatchExploits()
end

-------------------
-- PatchExploits

BotAPI.Events.PatchExploits = function(self)

	-----------
	if (nCX) then
		nCX = nil end
		
	-----------
	if (RPC_STATE) then
		RPC_STATE = false end
		
	-----------
	if (RPC) then
		RPC = {} end
		
	-----------
	if (g_gameRules) then
		g_gameRules.Client.ClStartWorking = BotAPI.Defaults.ClStartWorking
		g_gameRules.Client.ClStopWorking = BotAPI.Defaults.ClStopWorking
	end
end

-------------------
-- OnUpdate

BotAPI.Events.OnUpdate = function(self, frameTime) -- on frame

	-----------
	--- Catch last frames error
	--- C++
	SCRIPT_USE_CRYERROR = true
	pcall(SCRIPT_CHECK_RUNTIME, "FrameTick")

	-----------
	BOT_INGAME = (g_localActor ~= nil)
	if (Config and not Config.System) then
		return
	end

	-----------
	BotAPI:LogSystemInterrupt()
	if (SYSTEM_INTERRUPTED) then
		return
	end

	-----------
	if (not BOT_INITIALIZED) then
		return
	end

	-----------
	if (BOT_SAFE_CALLS and (not BOT_DEBUG_MODE or not BOT_DEV_MODE)) then
		local bOk, sErr = pcall(self.DoUpdate, self)
		if (not bOk) then
			SetError("[SAFE] Error in DoUpdate", sErr)
			BotError(false)
		end
	else

		--BotLog("UNPROTECTED ERRORS")
		SCRIPT_USE_CRYERROR = false -- in c++, resets every frame

		self:DoUpdate()
	end
end

-------------------
-- DoUpdate

BotAPI.Events.OnWallJump = function(self, hPlayer)

	--------
	-- Check
	if (not self:APIReady()) then
		return
	end

	--------
	if (Bot) then
		Bot:OnWallJump(hPlayer)
	end
end

-------------------
-- DoUpdate

BotAPI.Events.OnNetworkLag = function(self, bLag)

	--------
	-- Check
	if (not self:APIReady()) then
		return
	end
end

-------------------
-- DoUpdate

BotAPI.Events.OnChatMessage = function(self, idSource, sMsg, iType)

	--------
	-- Check
	if (not self:APIReady()) then
		return
	end

	Bot:OnChatMessage(idSource, sMsg, iType)
end

-------------------
-- DoUpdate

BotAPI.Events.OnFlashbangBlind = function(self, hPlayer, iPower)

	--------
	-- Check
	if (not self:APIReady()) then
		return
	end
end

-------------------
-- DoUpdate

BotAPI.Events.DoUpdate = function(self, frameTime)

	--------
	-- Check
	if (not self:APIReady()) then
		return
	end

	-----------
	if (Bot and Bot.PreUpdate) then
		Bot:PreUpdate(frameTime)
	else
	--	BotLogError("No update function in BotMain.lua")
	end
	
	-----------
	for i, aInfo in pairs(BotAPI.CONNECTING_PLAYERS) do
		local hPlayer = System.GetEntity(i)
		if (hPlayer) then
			if (g_localActor) then
				if (aInfo.entity.id == g_localActor.id) then
					BotAPI.CONNECTING_PLAYERS[i] = nil
				elseif (Bot) then
					self:SafeCall(Bot.OnPlayerConnected, Bot, aInfo.entity, aInfo.channelId)
					BotAPI.CONNECTING_PLAYERS[i] = nil
				end
			end
		else
			self.connectingPlayers[i] = nil;
		end
	end
end

-------------------
-- OnRevive

BotAPI.Events.OnRevive = function(self, channelId, player, isBot) -- when received phys profile "alive" from server

	--------
	-- Check
	if (not self:APIReady()) then
		return
	end

	-----------
	if (Bot and Bot.OnRevive) then
		self:SafeCall(Bot.OnRevive, Bot, player, isBot, channelId)
	end
end

-------------------
-- OnJump

BotAPI.Events.OnJump = function(self, channelId, player, isBot)

	--------
	-- Check
	if (not self:APIReady()) then
		return
	end

	-----------
	if (Bot and Bot.OnPlayerJump) then
		self:SafeCall(Bot.OnPlayerJump, Bot, player, isBot, channelId)
	end
end

-------------------
-- OnShoot

BotAPI.Events.OnShoot = function(self, weapon, player, pos, dir)

	--------
	-- Check
	if (not self:APIReady()) then
		return
	end

	-----------
	if (Bot and Bot.OnShoot) then
		self:SafeCall(Bot.OnShoot, Bot, player, weapon, pos, dir, (player.id == g_localActorId))
	end
end

-------------------
-- OnPlayerInit

BotAPI.Events.OnPlayerInit = function(self, channelId, player, isBot) -- gameRules + g_localActor available

	-----------
	if (not player) then
		return end

	-----------
	if (isBot) then
		BotMain:OnPreConnect()
		
	elseif (Bot and Bot.OnPlayerConnected) then
		self:SafeCall(Bot.OnPlayerConnected, Bot, player, channelId)
	end
end

-------------------
-- OnHit

BotAPI.Events.OnHit = function(self, hit)

	--------
	-- Check
	if (not self:APIReady()) then
		return
	end

	-----------
	if (Bot and Bot.PreOnHit) then
		Bot:PreOnHit(hit) end
end

-------------------
-- OnHit

BotAPI.Events.OnHit = function(self)

	--------
	-- Check
	if (not self:APIReady()) then
		return
	end

	-----------
	if (Bot and Bot.OnNetworkLag) then
		Bot:OnNetworkLag() end
end

-------------------
-- OnExplosion

BotAPI.Events.OnExplosion = function(self, explosion) -- Explosions near the bot

	--------
	-- Check
	if (not self:APIReady()) then
		return
	end

	-----------
	if (Bot and Bot.PreOnExplosion) then
		Bot:PreOnExplosion(explosion) end
end

-------------------
-- OnConnect

BotAPI.Events.OnConnect = function(self, channelId, player)

	-----------
	self.connectingPlayers[player.id] = {
		entity = player,
		channelId = channelId
	}
end

-------------------
-- OnBotConnect

BotAPI.Events.OnBotConnect = function(self, channelId, player)
end

-------------------
-- OnPlayerDisconnect

BotAPI.Events.OnPlayerDisconnect = function(self, channelId, player)

	-----------
	if (Bot and Bot.OnDisconnect) then
		self:SafeCall(Bot.OnDisconnect, Bot, player, channelId) end
end

-------------------
-- OnBotDisconnect

BotAPI.Events.OnBotDisconnect = function(self, sReason, sInfo)

	-----------
	if (Bot and Bot.OnBotDisconnect) then
		self:SafeCall(Bot.OnBotDisconnect, Bot, g_localActor) end

	-----------
	if (Bot) then
		Bot:RestoreCVarSync()
	end
	BotMain:OnDisconnect()
	BotMain:UninstallBot(sReason, sInfo)
end

-------------------
-- OnBotConnectFailed

BotAPI.Events.OnBotConnectFailed = function(self, sReason, sInfo)

	-----------
	--BotMain:UninstallBot(checkString(sReason,"<N/A>"))
end

-------------------
-- OnTaggedEntity

BotAPI.Events.OnTaggedEntity = function(self, entityId)

	--------
	-- Check
	if (not self:APIReady()) then
		return
	end

	-----------
	if (Bot and Bot.OnTaggedEntity) then
		self:SafeCall(Bot.OnTaggedEntity, Bot, entityId, GetEntity(entityId)) end
end

-------------------
-- OnRadioMessage

BotAPI.Events.OnRadioMessage = function(self, hSender, iMessage)

	--------
	-- Check
	if (not self:APIReady()) then
		return
	end

	-----------
	if (Bot and Bot.OnRadioMessage) then
		self:SafeCall(Bot.OnRadioMessage, Bot, hSender, iMessage) end
end

-------------------
-- SafeCall

BotAPI.Events.SafeCall = function(self, fFunc, ...)

	-----------
	if (not isNull(fFunc)) then
		local sFunc = table.lookupRec(_G, fFunc) -- Lookup in _G, not optimal !!
		local bOk, hRes = pcall(fFunc, ...)
		if (not bOk) then
			SetError("SafeCall failed to execute function " .. tostring(sFunc), (hRes or "<No Error Info>"))
			return BotError(false)
		end
		
		-----------
		if (fFunc == loadfile) then
			bOk, hRes = pcall(hRes)
			if (not bOk) then
				SetError("SafeCall failed to load function " .. tostring(sFunc), (hRes or "<No Error Info>"))
				return BotError(false)
			end
		end
	else
		SetError("Invalid function to SafeCall()", "function is nil")
	end
end
