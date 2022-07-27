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

BotAPI.connectingPlayers = {}
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
	BotAPILog("BotAPI.Init()")
	
	---------------
	self:PatchExploits()
	
end

-------------------
-- OnTimer

BotAPI.OnTimer = function(self, timerTime)
	if (Bot and Bot.PreOnTimer) then
		Bot:PreOnTimer(timerTime)
	end
	
	-----------
	FinchPower:Wait()
	
	-----------
	self:PatchExploits()
end

-------------------
-- PatchExploits

BotAPI.PatchExploits = function(self)

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
		-- This Caused hang ? 
		-- ...~
		-- if (not g_gameRules.server.Old_RequestSpectatorTarget) then
			-- g_gameRules.server.Old_RequestSpectatorTarget = g_gameRules.server.RequestSpectatorTarget end
		
		------
		-- g_gameRules.server.RequestSpectatorTarget = function(self, entityId, iMode)	
			-- if (iMode > 3 and iMode ~= 111) then
				-- return FinchLog("Spectator Target Blocked >> " .. iMode) end
			-- return g_gameRules.server.Old_RequestSpectatorTarget(self, entityId, iMode)
		-- end
		-- ~...
		
		--------
		g_gameRules.Client.ClStartWorking = self.Defaults.ClStartWorking
		g_gameRules.Client.ClStopWorking = self.Defaults.ClStopWorking
	end
end

-------------------
-- OnUpdate

BotAPI.OnUpdate = function(self, frameTime) -- on frame
	if (Config and not Config.System) then
		return
	end
	
	-----------
	self:DoUpdate(frameTime)
end

-------------------
-- DoUpdate

BotAPI.DoUpdate = function(self, frameTime)

	-----------
	if (Bot and Bot.PreUpdate) then
		Bot:PreUpdate(frameTime) end
	
	-----------
	for i, aInfo in pairs(self.connectingPlayers or{}) do
		if (System.GetEntity(i)) then
			if (g_localActor) then
				if (aInfo.entity.id == g_localActor.id) then
					_reload = false;
					self.connectingPlayers[i] = nil;
				elseif (Bot) then
					self:SafeCall(Bot.OnPlayerConnected, Bot, aInfo.entity, aInfo.channelId)
					self.connectingPlayers[i] = nil;
				end
			end
		else
			self.connectingPlayers[i] = nil;
		end
	end
end

-------------------
-- OnRevive

BotAPI.OnRevive = function(self, channelId, player, isBot) -- when received phys profile "alive" from server

	-----------
	if (Bot and Bot.OnRevive) then
		self:SafeCall(Bot.OnRevive, Bot, player, isBot, channelId)
	end
end

-------------------
-- OnJump

BotAPI.OnJump = function(self, channelId, player, isBot)

	-----------
	if (Bot and Bot.OnPlayerJump) then
		self:SafeCall(Bot.OnPlayerJump, Bot, player, isBot, channelId)
	end
end

-------------------
-- OnShoot

BotAPI.OnShoot = function(self, weapon, player, pos, dir)
	
	-----------
	if (Bot and Bot.OnShoot) then
		self:SafeCall(Bot.OnShoot, Bot, player, weapon, pos, dir, (player.id == g_localActorId))
	end
end

-------------------
-- OnPlayerInit

BotAPI.OnPlayerInit = function(self, channelId, player, isBot) -- gameRules + g_localActor available

	-----------
	if (not player) then
		return end

	-----------
	if (isBot) then
		FinchPower:OnPreConnect()
		
	elseif (Bot and Bot.OnPlayerConnected) then
		self:SafeCall(Bot.OnPlayerConnected, Bot, player, channelId)
	end
end

-------------------
-- OnHit

BotAPI.OnHit = function(self, hit)

	-----------
	if (Bot and Bot.PreOnHit) then
		Bot:PreOnHit(hit) end
end

-------------------
-- OnExplosion

BotAPI.OnExplosion = function(self, explosion) -- Explosions near the bot

	-----------
	if (Bot and Bot.PreOnExplosion) then
		Bot:PreOnExplosion(explosion) end
end

-------------------
-- OnConnect

BotAPI.OnConnect = function(self, channelId, player)

	-----------
	self.connectingPlayers[player.id] = {
		entity = player,
		channelId = channelId
	}
end

-------------------
-- OnBotConnect

BotAPI.OnBotConnect = function(self, channelId, player)
end

-------------------
-- OnPlayerDisconnect

BotAPI.OnPlayerDisconnect = function(self, channelId, player)

	-----------
	if (Bot and Bot.OnDisconnect) then
		self:SafeCall(Bot.OnDisconnect, Bot, player, channelId) end
end

-------------------
-- OnBotDisconnect

BotAPI.OnBotDisconnect = function(self, player, reason)

	-----------
	FinchPower:OnDisconnect()
		
	-----------
	if (Bot and Bot.OnBotDisconnect) then
		self:SafeCall(Bot.OnBotDisconnect, Bot, player, channelId) end
		
	-----------
	FinchPower:UninstallBot(reason)
end

-------------------
-- OnBotConnectFailed

BotAPI.OnBotConnectFailed = function(self, reason, info)

	-----------
	FinchPower:UninstallBot(info)
end

-------------------
-- OnTaggedEntity

BotAPI.OnTaggedEntity = function(self, entityId)
	
	-----------
	if (Bot and Bot.OnTaggedEntity) then
		self:SafeCall(Bot.OnTaggedEntity, Bot, entityId, GetEntity(entityId)) end
end

-------------------
-- OnRadioMessage

BotAPI.OnRadioMessage = function(self, hSender, iMessage)
	
	-----------
	if (Bot and Bot.OnRadioMessage) then
		self:SafeCall(Bot.OnRadioMessage, Bot, hSender, iMessage) end
end

-------------------
-- GetFunctionName

BotAPI.GetFunctionName = function(self, f)

	-----------
	if (f:find("%.") or f:find(":")) then
		return end
		
	-----------
	for i, v in pairs(_G or{}) do
		if (v == f) then
			return i end end

	-----------
	return
end

-------------------
-- SafeCall

BotAPI.SafeCall = function(self, fFunc, ...)

	-----------
	if (not isNull(fFunc)) then
		local sFunc = table.lookupRec(_G, fFunc) -- Lookup in _G, not optimal !!
		local bOk, hRes = pcall(fFunc, ...)
		if (not bOk) then
			SetError("SafeCall failed to execute function " .. tostring(functionName), (hRes or "<No Error Info>"))
			return FinchPower:FinchError(false)
		end
		
		-----------
		if (fFunc == loadfile) then
			bOk, hRes = pcall(hRes)
			if (not bOk) then
				SetError("SafeCall failed to load function " .. tostring(functionName), (hRes or "<No Error Info>"))
				return FinchPower:FinchError(false)
			end
		end
	else
		SetError("Invalid function to SafeCall()", "function is nil")
	end
end
