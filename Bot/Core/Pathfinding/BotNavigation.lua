--=====================================================
-- CopyRight (c) R 2022-2203
--
-- Pathfinding utilities for the CryMP bot project
--
--=====================================================

NaviLog = function(msg, ...)
	local sFmt = "$9[$6Navigation$9] " .. tostring(msg)
	if (...) then
		sFmt = string.format(sFmt, ...) end
		
	System.LogAlways(sFmt)
end

-------------------
BotNavigation = {
	version = "0.3",
	author = "shortcut0",
	description = "System used by the bot to navigate around maps"
}

---------------------------
BotNavigation.Globals = {
	NAVIGATION_LOG_VERBOSITY = 0
}

---------------------------
BotNavigation.UNSEEN_NODES_FRAMES = {}

---------------------------
BotNavigation.CURRENT_PATH_NODE = nil
BotNavigation.CURRENT_PATH_POS = nil
BotNavigation.CURRENT_PATH_ENVIRONMENT_CLASS = nil
BotNavigation.CURRENT_PATH_NODE_ABOVE = nil
BotNavigation.CURRENT_PATH_NODE_ABOVE_TERRAIN = nil
BotNavigation.CURRENT_PATH_SIZE = nil
BotNavigation.CURRENT_PATH_ARRAY = nil
BotNavigation.CURRENT_PATH_FINISHTIME = nil
BotNavigation.CURRENT_PATH_PLAYER = nil
BotNavigation.CURRENT_PATH_TARGET = nil
BotNavigation.CURRENT_PATH_IGNOREPLAYERS = nil
BotNavigation.CURRENT_PATH_NODELAY = nil
BotNavigation.CURRENT_PATH_RESETTIME = nil
BotNavigation.CURRENT_NODE_REVERTED = nil
BotNavigation.CURRENT_PATH_REVERTED = nil

---------------------------
-- Init

BotNavigation.Init = function(self)

	----------------
	NaviLog(0, "BotNavigation.Init()")
	
	----------------
	self:InitGlobals()
	
	----------------
	self:InitCVars()
end

---------------------------
-- InitCVars

BotNavigation.InitGlobals = function(self)

	---------------------
	local iCounter = 0
	for sName, vValue in pairs(self.Globals or {}) do
		if (_G[tostring(sName)] == nil) then
			_G[tostring(sName)] = vValue;
			iCounter = iCounter + 1;
		end
	end
	
	---------------------
	self:Log(0, "Registered " .. iCounter .. " new globals");
end

---------------------------
-- InitCVars

BotNavigation.InitCVars = function(self)

	---------------------
	self:Log(0, "BotNavigation.InitCVars()")
	
	---------------------
	local sPrefix = "botnavi_"
	local aCVars = {
		{ "init",       		"BotNavigation:Init()",		"Re-initializes the Bot Navigation System" },
		{ "reloadfile", 		"Bot:LoadNavigation()",		"Reloads the Navigation Library" },
		{ "resetdata", 			"Bot:ResetPathData()",		"Resets the current Navigation Data" },
		
		{ "logverbosity",		"Bot:SetVariable(\"NAVIGATION_LOG_VERBOSITY\", %1, false, true, true)", "Changes the current log verbosity of the Navigation System" },
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
end

---------------------------
-- SetSleepTimer

BotNavigation.SetSleepTimer = function(self, iTime)
	self.SLEEP_TIMER = timerinit()
	self.SLEEP_TIME = checkNumber(iTime, 1)
end

---------------------------
-- Update

BotNavigation.Update = function(self)
	self:Log(5, "BotNavigation.Update()")
	
	----------------
	local vPos = g_localActor:GetPos()
	
	----------------
	local sRandomClass = self:GetRandomEntitiesForEnvironment()
	self.CURRENT_PATH_ENVIRONMENT_CLASS = sRandomClass
	
	----------------
	if (not self.CURRENT_PATH_NODE) then
		self:Log(0, "No path found. regenerating")
		if (not timerexpired(self.SLEEP_TIMER, self.SLEEP_TIME)) then
			return end
		
		self.LAST_PATHGEN_FAILED = true
		self:GetNewPath(sRandomClass)
	else
		self.LAST_PATHGEN_FAILED = false
	end
	
	----------------
	local aTarget = self:GetClosestAlivePlayer()
	if (timerexpired(self.IGNORE_IDLE_PLAYERS_TIMER, 1)) then
		if (not self.CURRENT_PATH_IGNOREPLAYERS and aTarget ~= nil and (not self.CURRENT_PATH_PLAYER or self:CheckIfPlayerMoved(self.CURRENT_PATH_GOAL, self.CURRENT_PATH_TARGET))) then
			if (self.CURRENT_PATH_TARGET ~= aTarget) then
				self:Log(0, "Found alive player. stopping idle path and going to player !!")
				self:GetNewPath(aTarget, false)
			end
		end
	end

	----------------
	if (not self.CURRENT_PATH_ARRAY) then
		return self:GetNewPath(sRandomClass, true) end	
	
	----------------
	if (self.CURRENT_PATH_NODE > self.CURRENT_PATH_SIZE) then
		-- self:Log(0, "End of path reached")
			
		if (not self.CURRENT_PATH_FINISHTIME) then 
			self.CURRENT_PATH_FINISHTIME = _time end
			
		local iDelay = 1
		if (self.CURRENT_PATH_PLAYER) then
			iDelay = 0.15 end
				
		if (self.CURRENT_PATH_NODELAY) then
			iDelay = -1 end
			
		if (_time - self.CURRENT_PATH_FINISHTIME < iDelay) then
			return Bot:StopMovement()
		end
			
		self:GetNewPath(sRandomClass)
	end
	
	----------------
	if (not self.CURRENT_PATH_ARRAY) then
		return self:GetNewPath(sRandomClass, true) end	
	
	----------------
	local bReverted = false
	local hCurrentNode = self.CURRENT_PATH_ARRAY[self.CURRENT_PATH_NODE]
	if (hCurrentNode) then
		
		self.CURRENT_PATH_NODE_ABOVE = (self:IsNodeAbove(hCurrentNode) or self:IsNodeBelow(hCurrentNode))
		self.CURRENT_PATH_NODE_ABOVE_TERRAIN = (self.CURRENT_PATH_NODE_ABOVE or (self:IsNodeAboveTerrain(hCurrentNode, 2)))
		
		if (self:IsNodeUnreachable(hCurrentNode)) then
		
			Bot:StopMovement()
			self:Log(3, "Current node is unreachable!")
			
			self.CURRENT_PATH_NODE_STUCK_TIME = timerinit()
			
			if (self.CURRENT_PATH_NODE > 1) then
				self.CURRENT_PATH_NODE = self.CURRENT_PATH_NODE - 1
				repeat 
					self.CURRENT_PATH_NODE = self.CURRENT_PATH_NODE - 1
					hCurrentNode = self.CURRENT_PATH_ARRAY[self.CURRENT_PATH_NODE]
					self:Log(3, "REVERTING to OLDER node %d!", self.CURRENT_PATH_NODE)
				until (not hCurrentNode or self:IsNodeVisible(hCurrentNode, true))
					
				if (not hCurrentNode) then
					self:Log(3, "all reverted. no visible node found!")
					self:GetNewPath(sRandomClass)
				end
				bReverted = true
			else
				self:ClearPathGoalEnvironemnt()
				self:GetNewPath(sRandomClass)
				self:Log(3, "Resetting path")
				self.CURRENT_PATH_RESETTIME = _time
			end
		else
			-- self.CURRENT_PATH_NODE_STUCK_TIME = nil
		end
	end
		
	----------------
	if (bReverted) then
		self.CURRENT_PATH_REVERTED = true
		
		-- Experimental!!
		self.CURRENT_PATH_PREVIOUS_NODE = self.CURRENT_PATH_NODE 
		self.CURRENT_PATH_WAS_REVERTED = true
		-- ~...
		
		self.CURRENT_NODE_REVERTED = (self.CURRENT_NODE_REVERTED or 0) + 1
		if (self.CURRENT_NODE_REVERTED >= 10) then
			self:GetNewPath(sRandomClass)
			-- BotLog("$4 TOO MUCH REVERTING WITHOUT PROGRESS!!! NEW PATH !!!")
		end
	else
		self.CURRENT_NODE_REVERTED = 0
	end
		
	----------------
	-- GetLastJump Might cause future problems!
	local iGoalDist = 2
	if (hCurrentNode and System.IsPointIndoors(hCurrentNode)) then
		self:Log(5, "POINT INDOORS. HIGH PRECISION GOAL DISTANCE!")
		iGoalDist = 0.5 end
	
	if (not timerexpired(self.CURRENT_PATH_NODE_STUCK_TIME, 1)) then
		iGoalDist = 0.1
		if (hCurrentNode and System.IsPointIndoors(hCurrentNode)) then
			Bot:SetCameraTarget(hCurrentNode) end
	elseif (not bReverted and (Bot:GetLastJump(2.5) or self:IsLastNode(self.CURRENT_PATH_NODE) or (self:IsFirstNode(self.CURRENT_PATH_NODE) and self:IsNodeVisible(self.CURRENT_PATH_ARRAY[self.CURRENT_PATH_NODE])))) then
		iGoalDist = 1.85 end
		
	----------------
	Bot.GOAL_REACHED_DISTANCE = iGoalDist
		
	----------------
	local bUpdate = false
	local sUpdate
		
	----------------
	if (hCurrentNode and not System.IsPointIndoors(hCurrentNode)) then
		local iDistance = vector.distance(vPos, hCurrentNode)
		if (isNumber(self.CURRENT_NODE_LASTDISTANCE) and iDistance > self.CURRENT_NODE_LASTDISTANCE) then
			self:Log(3, "CURRENT NODE SURPASSED !!")
			if (self:CanSeeNextNode()) then
				self:Log(3, "COULD SEE NEXT NODE!! SWITCHING")
				self.CURRENT_NODE_SURPASSED = true end  end
			
		self.CURRENT_NODE_LASTDISTANCE = iDistance
	else
		self.CURRENT_NODE_SURPASSED = nil
	end
	
	----------------
	if (not hCurrentNode) then
		bUpdate = true
		sUpdate = "No Current Node!!"
		
	elseif (self.CURRENT_NODE_SURPASSED) then
		bUpdate = true
		sUpdate = "Current Node Surpassed!!"
		self.CURRENT_NODE_SURPASSED = nil
		self.CURRENT_NODE_LASTDISTANCE = nil
		
	elseif (vector.distance2d(vPos, hCurrentNode) < iGoalDist) then
		bUpdate = true
		self.CURRENT_PATH_REVERTED = false
		sUpdate = "Goal Reached!!"
		
	elseif (not bReverted and not self.CURRENT_PATH_REVERTED) then
		if (self:IsNextNodeCloser(self.CURRENT_PATH_NODE)) then
			bUpdate = true
			sUpdate = "Next Node is Closer!!"
		
		elseif (self:IsNodeBehind(hCurrentNode) and self:CanSeeNextNode()) then
			bUpdate = true
			sUpdate = "Current Node is Behind us!!"
		
		end

	-- Experimental!!
	elseif (not bReverted and self.CURRENT_PATH_WAS_REVERTED) then
		if (self:IsNodeVisibleEx(self.CURRENT_PATH_ARRAY[self.CURRENT_PATH_PREVIOUS_NODE])) then
			bUpdate = true
			sUpdate = "Previus Reverted node is now visible!!"
		
		end
	end
	-- ~...
	
	----------------
	self:Log(5, "Vec2D Distance To Goal: %f", (hCurrentNode and vector.distance2d(vPos, hCurrentNode) or 0))
	self:Log(5, "Is Node %d (/%d) last Node %s", self.CURRENT_PATH_NODE, self.CURRENT_PATH_SIZE, (self:IsLastNode(self.CURRENT_PATH_NODE) and "yes" or "no"))
	
	
	----------------
	if (bUpdate) then
		self.CURRENT_PATH_NODE = self.CURRENT_PATH_NODE + 1
		self:Log(0, "Updating Node Index to %d (%s)", self.CURRENT_PATH_NODE, sUpdate)
		hCurrentNode = self.CURRENT_PATH_ARRAY[self.CURRENT_PATH_NODE]
		
		self.CURRENT_PATH_WAS_REVERTED = nil
		self.CURRENT_NODE_SURPASSED = nil
	end
	
	----------------
	local bReturn = true
	
	----------------
	if (hCurrentNode) then
		self:Log(3, "Traveling to current path node: %d (pos: %s, distance: %f)", self.CURRENT_PATH_NODE, Vec2Str(hCurrentNode), vector.distance(g_localActor:GetPos(), hCurrentNode))
		Bot:StartMoving(1, hCurrentNode, true)
		-- Particle.SpawnEffect("explosions.flare.a", hCurrentNode, g_Vectors.up, 0.1)
	else
		self:LogWarning(3, "Failed to retrive current pathnode (id: %d)", self.CURRENT_PATH_NODE)
		bReturn = false
	end
		
	----------------
	self.CURRENT_PATH_POS = hCurrentNode
		
	----------------
	self:Log(4, "Current Path Goal: %s (isPlayer: %s)", (self.CURRENT_PATH_TARGET and self.CURRENT_PATH_TARGET.class or "<null>"), (self.CURRENT_PATH_PLAYER and "Yes" or "No"))
		
	----------------
	return bReturn
end

---------------------------
-- Log

BotNavigation.Log = function(self, iVerbosity, ...)
		local bLog = true
		if (isNumber(iVerbosity)) then
			if (iVerbosity > NAVIGATION_LOG_VERBOSITY) then
				bLog = false end
		end
		
		if (bLog) then
			return NaviLog(...)
		end
	end

---------------------------
-- Log

BotNavigation.LogWarning = function(self, iVerbosity, ...)
		local bLog = true
		if (isNumber(iVerbosity)) then
			if (iVerbosity > NAVIGATION_LOG_VERBOSITY) then
				bLog = false end
		end
		
		if (bLog) then
			local aArgs = { ... }
			local sMsg = table.popFirst(aArgs)
			if (not sMsg) then
				sMsg = "" end
			return NaviLog("$9[$6Warning$9] " .. sMsg, unpack(aArgs))
		end
	end

---------------------------
-- LogError

BotNavigation.LogError = function(self, iVerbosity, ...)
		local bLog = true
		if (isNumber(iVerbosity)) then
			if (iVerbosity > NAVIGATION_LOG_VERBOSITY) then
				bLog = false end
		end
		
		if (bLog) then
			local aArgs = { ... }
			local sMsg = table.popFirst(aArgs)
			if (not sMsg) then
				sMsg = "" end
			return NaviLog("$9[$4Error$9] " .. sMsg, unpack(aArgs))
		end
	end

---------------------------
-- CanCircleJumpOnCurrentPath

BotNavigation.CanCircleJumpOnCurrentPath = function(self)

	--------------
	if (self.CURRENT_PATH_NODE_ABOVE) then
		return false end
	
	--------------
	if (self.CURRENT_PATH_NODE_ABOVE_TERRAIN) then
		return false end
	
	--------------
	if (not self.IsInOpenSpace()) then
		return false end
	
	--------------
	if (System.IsPointIndoors(g_localActor:GetPos())) then
		return false end
		
	--------------
	local iUntilIndoors = self:GetNodeCountToIndoors()
	if (isNumber(iUntilIndoors) and iUntilIndoors < 6) then
		return false end
		
	--------------
	return true
end

---------------------------
-- GetNodeCountToIndoors

BotNavigation.GetNodeCountToIndoors = function(self)

	-----------
	if (not isArray(self.CURRENT_PATH_ARRAY)) then
		return end
		
	-----------
	local vCurrent = self:GetCurrentNodePos(self.CURRENT_PATH_NODE)
	if (vCurrent and self.CURRENT_PATH_NODE >= self.CURRENT_PATH_SIZE) then
		return System.IsPointIndoors(vCurrent) end
	
	-----------
	local iCounter = 0
	local bIndoorsFound = false
	for iNode = self.CURRENT_PATH_NODE, self.CURRENT_PATH_SIZE, 1 do
		local vNode = self:GetCurrentNodePos(iNode)
		if (vNode) then
			if (self:IsNodeIndoors(iNode) or System.IsPointIndoors(vNode)) then
				bIndoorsFound = true
				break else
					iCounter = iCounter + 1 end
		end
	end
	
	-----------
	if (bIndoorsFound) then
		-- NaviLog("Until Indoors: %d", iCounter)
		return iCounter end
	
	-----------
	return
end

---------------------------
-- IsNodeIndoors

BotNavigation.IsNodeIndoors = function(self, iNode)

	-----------
	if (not isArray(self.CURRENT_PATH_INDOOR_NODES)) then
		self.CURRENT_PATH_INDOOR_NODES = {} end

	-----------
	if (not isNumber(iNode)) then
		return end

	-----------
	if (iNode > self.CURRENT_PATH_SIZE) then
		return end
		
	-----------
	local bInside = self.CURRENT_PATH_INDOOR_NODES[iNode]
	if (isNull(bInside)) then
		bInside = System.IsPointIndoors(self:GetCurrentNodePos(iNode))
		self.CURRENT_PATH_INDOOR_NODES[iNode] = bInside end
		
	-----------
	return (bInside)
end

---------------------------
-- IsInOpenSpace

BotNavigation.IsInOpenSpace = function()
	return true
end

---------------------------
-- GetCurrentNodePos

BotNavigation.GetCurrentNodePos = function(self, iNode)

	-----------
	if (not isArray(self.CURRENT_PATH_ARRAY)) then
		return end

	-----------
	if (not isNumber(iNode)) then
		return end

	-----------
	if (iNode > self.CURRENT_PATH_SIZE) then
		return end
		
	return (self.CURRENT_PATH_ARRAY[iNode])
end

---------------------------
-- GetTargetId

BotNavigation.GetTargetId = function(self)
	local hEntity = self.CURRENT_PATH_TARGET
	if (hEntity) then
		return hEntity.id end
		
	return
end

---------------------------
-- IsTargetPlayer

BotNavigation.IsTargetPlayer = function(self, bNoBots)
	local hEntity = self.CURRENT_PATH_TARGET
	if (hEntity) then
		return ((hEntity.class == "Player") and (not bNoBots or (hEntity.actor:IsPlayer()))) end
		
	return
end

---------------------------
-- CanSeeNextNode

BotNavigation.CanSeeNextNode = function(self)

	local iNode = self.CURRENT_PATH_NODE
	if (not iNode) then
		return false end
		
	if (iNode >= self.CURRENT_PATH_SIZE) then
		return false end
		
	local vNode = self.CURRENT_PATH_ARRAY[(iNode + 0)]
	local vNextNode = self.CURRENT_PATH_ARRAY[(iNode + 1)]
	
	local iZDiff = (vNode.z - vNextNode.z)
	if (iZDiff > 0.175 or iZDiff < -0.175) then
		self:Log(0, "Ignoring next node because its ELEVATED!!")
		return false end
	
	return self:IsNodeVisible(vNextNode)
end

---------------------------
-- IsNodeUnreachable

BotNavigation.IsNodeUnreachable = function(self, vNode, bRayCheck)
	
	-----------
	local vNode = vector.modify(vNode, "z", 0.25, true)
	
	-----------
	local bVisible = self:IsNodeVisible(vNode, true)
		
	-----------
	if (not bVisible) then
		self.CURRENT_NODE_UNSEEN_TIME = (self.CURRENT_NODE_UNSEEN_TIME or 0) + 1
		self:Log(0, "UNSEEN TIME: %d", self.CURRENT_NODE_UNSEEN_TIME)
	else
		self.CURRENT_NODE_UNSEEN_TIME = 0
	end
		
	-----------
	return self.CURRENT_NODE_UNSEEN_TIME > 20
end

---------------------------
-- IsNodeVisible_Handle

BotNavigation.IsNodeVisible_Handle = function(self, vSource, vTarget, sHandle, iThreshold)
	
		local iThreshold = iThreshold
		if (not iThreshold) then
			iThreshold = 50 end
	
		-----------
		if (not self.UNSEEN_NODES_FRAMES) then
			self.UNSEEN_NODES_FRAMES = {} end
	
		-----------
		self.UNSEEN_NODES_FRAMES[sHandle] = (self.UNSEEN_NODES_FRAMES[sHandle] or 0) + 1
		
		-----------
		return (self.UNSEEN_NODES_FRAMES[sHandle] <= iThreshold)
	end
	
---------------------------
-- IsNodeVisible

BotNavigation.IsNodeVisible = function(self, vNode, bRayCheck)
	
		-----------
		local vDir = Bot:GetViewCameraDir(1) -- NOT ACCURATE !! 
		local vPos = Bot:GetViewCameraPos(1) -- NOT ACCURATE !!
		local iDistance = vector.distance(vNode, vPos)
	
		-----------
		local bVisible = Pathfinding.CanSeeNode(vector.sub(vPos, vector.new(vDir)), vNode, g_localActorId)
		if (not bVisible) then
			bVisible = Pathfinding.CanSeeNode(vector.sub(g_localActor:GetBonePos("Bip01 Pelvis"), vector.new(vDir)), vNode, g_localActorId)
		end
		
		-- Pathfinding:Effect(vNode)
		-----------
		-- if (bRayCheck and bVisible) then
			-- local vRayHit = Pathfinding.GetRayHitPosition(vPos, vDir, iDistance, ent_all, g_localActorId)
			-- self:Log(0, "iDistance: %f, RayDist: %f", iDistance, vector.distance(vRayHit, vPos))
			-- if (vRayHit and (vector.distance(vRayHit, vPos) * 1) < iDistance) then
				-- self:Log(0, "Not visible!")
				-- return false end
		-- end
		
		-----------
		return bVisible
	end
	
---------------------------
-- IsNodeVisibleEx

BotNavigation.IsNodeVisibleEx = function(self, vNode)
	
		-----------
		local bVisible = 
		(BotNavigation:IsNodeVisible(vector.modify(vNode, "z", 0.25, true)) or 
		BotNavigation:IsNodeVisible(vector.modify(vNode, "z", 0.5, true)) or 
		BotNavigation:IsNodeVisible(vector.modify(vNode, "z", 1, true))) 
	
		-----------
		return bVisible
	end
	
---------------------------
-- IsNodeVisible_Source

BotNavigation.IsNodeVisible_Source = function(self, vSource, vNode)
	
		-----------
		local bVisible = Pathfinding.CanSeeNode(vSource, vNode, g_localActorId)
		if (not bVisible) then
			bVisible = Pathfinding.CanSeeNode(vector.modify(vSource, "z", 0.25, true), vector.modify(vNode, "z", 0.25, true), g_localActorId)
		end
		
		-----------
		return bVisible
	end

---------------------------
-- IsFirstNode

BotNavigation.IsFirstNode = function(self, iNode)
		return (iNode == 1)
	end

---------------------------
-- IsLastNode

BotNavigation.IsLastNode = function(self, iNode)
	
		-----------
		if (not iNode or not self.CURRENT_PATH_SIZE) then
			return false end
	
		-----------
		if (iNode >= self.CURRENT_PATH_SIZE) then
			return true end
			
		-----------
		iNode = iNode + 1
		if (iNode >= self.CURRENT_PATH_SIZE) then
			local vEndNode = self.CURRENT_PATH_ARRAY[iNode]
			local vCurrNode = self.CURRENT_PATH_ARRAY[(iNode - 1)]
			
			return (iNode >= self.CURRENT_PATH_SIZE and (((vector.distance(vCurrNode, vEndNode) < 0.5) or self:IsNodeVisible_Source(vEndNode, vCurrNode))))
		end
		
		-----------
		-- self:Log(0, "NODE : %d", iNode)
			
		-----------
		local vPos = g_localActor:GetPos()
		local vEnd = self.CURRENT_PATH_ARRAY[self.CURRENT_PATH_ARRAY]
		if (vEnd) then
			local iDistance = vector.distance(vPos, vEnd)
			return (iDistance < 0.5 or (iDistance < 2.25 and self:IsNodeVisible_Source(vEndNode, vCurrNode)))
		end
		
		-----------
		return false
		
	end

---------------------------
-- IsNodeBelow

BotNavigation.IsNodeBelow = function(self, vNode)
		local vPos = g_localActor:GetPos()
		local zDiff = vNode.z - vPos.z
		
		-----------
		-- self:Log(0, "Is Node Below: %s (%f)", ((zDiff < -0.25) and "Yes" or "No"), zDiff)
		
		-----------
		return (zDiff < 0)
	end

---------------------------
-- IsNodeAbove

BotNavigation.IsNodeAbove = function(self, vNode)
		local vPos = g_localActor:GetPos()
		local zDiff = vNode.z - vPos.z
		
		-----------
		-- self:Log(0, "Is Node Above: %s (%f)", ((zDiff > 1) and "Yes" or "No"), zDiff)
		
		-----------
		return (zDiff > 0.8)
	end

---------------------------
-- IsNodeAboveTerrain

BotNavigation.IsNodeAboveTerrain = function(self, vNode, iMaxDistance)
		local iTerrain = System.GetTerrainElevation(vNode)
		if (not iTerrain) then
			return true end
		
		-----------
		local zDiff = vNode.z - iTerrain
		
		-----------
		local iMaxDistance = iMaxDistance
		if (not iMaxDistance) then
			iMaxDistance = 1 end
		
		-----------
		return (zDiff > iMaxDistance)
	end

---------------------------
-- IsNodeBehind

BotNavigation.IsNodeBehind = function(self, vNode)
		local vProjected = System.ProjectToScreen(vNode)
		return (vProjected.z > 1)
	end

---------------------------
-- IsNextNodeCloser

BotNavigation.IsNextNodeCloser = function(self, iNode)
	
		-----------
		if (not iNode) then
			return false end
		
		-----------
		if (iNode + 1 > self.CURRENT_PATH_SIZE) then
			return false end
	
		-----------
		local hCurrentNode = self.CURRENT_PATH_ARRAY[iNode]
		local hNextNode = self.CURRENT_PATH_ARRAY[iNode + 1]
		
		-----------
		local vPosition = g_localActor:GetPos()
		
		-----------
		local iDistance_C = vector.distance(hCurrentNode, vPosition)
		local iDistance_N = vector.distance(hNextNode, vPosition)
		
		-----------
		local iZDiff = hNextNode.z - hCurrentNode.z
		if ((iZDiff > 0.1 or iZDiff < -0.1)) then
			self:Log(0, "Ignoring Next node despite it being closer (ITS EVELVATED!)")
			return false
		end
		
		-----------
		return self:IsNodeVisible(hNextNode) and (iDistance_N < iDistance_C)
	end

---------------------------
-- GetNewPath

BotNavigation.GetNewPath = function(self, sTargetsClass, bIgnorePlayers, bRetry)
	
		-----------
		local hTarget
		local bTarget = false
		
		-----------
		-- self:Log(0, "Update Env ??")
		if (not self.SPAWNPOINT_ENVIRONMENT or (self.SPAWNPOINT_ENVIRONMENT[1] + 1) > self.SPAWNPOINT_ENVIRONMENT[2]) then
			self:Log(0, "Refresh Env ??")
			self:ClearPathGoalEnvironemnt(sTargetsClass)
		end
		
		-----------
		if (isString(sTargetsClass)) then
			
			-----------
			if (self.SPAWNPOINT_ENVIRONMENT[2] == 0) then
				return false, self:Log(3, "No Entities Found!") end
			
			-----------
			self.SPAWNPOINT_ENVIRONMENT[1] = self.SPAWNPOINT_ENVIRONMENT[1] + 1
			
			local iCurrentEnt = self.SPAWNPOINT_ENVIRONMENT[1]
			repeat
				iCurrentEnt = iCurrentEnt + 1
				hTarget = self.SPAWNPOINT_ENVIRONMENT[3][iCurrentEnt]
			until (iCurrentEnt >= self.SPAWNPOINT_ENVIRONMENT[2] or hTarget ~= self.CURRENT_PATH_LAST_TARGET)
			hTarget = self.SPAWNPOINT_ENVIRONMENT[3][iCurrentEnt]
			
			-----------
			local hNewTarget = BotAI.CallEvent("GetPathGoal", hTarget)
			if (not isDead(hNewTarget)) then
				hTarget = hNewTarget end
		else
			hTarget = sTargetsClass
			bTarget = true
			-- bIgnorePlayers = true
		end
		
		-----------
		self:ResetPath()
		
		-----------
		local bPlayer = false
		local aTarget = self:GetClosestAlivePlayer()
		if (not bTarget and aTarget and not self:WasEntityUnreachable(aTarget) and aTarget.id ~= g_localActorId) then
			hTarget = aTarget
			bPlayer = true
		end
		
		-----------
		local hTimerStart = timerinit()
		
		-----------
		local iDistance = 0
		local aPath = {}
		local vGoal
		if (hTarget) then
			local vPos = g_localActor:GetPos()
			local vTarget = hTarget:GetPos()
			iDistance = vector.distance(vPos, vTarget)
			
			vGoal = vector.modify(vTarget, "z", 0.5, true)
			
			if (not vector.isvector(vGoal)) then
				self:Log(0, "GOAL IS NO VECTOR !!")
			else
				aPath = Pathfinding:GetPath(vector.modify(vPos, "z", 0.5, true), vGoal)
				if (not aPath and bPlayer) then
					aPath = self:GetNewPath(self.CURRENT_PATH_ENVIRONMENT_CLASS, true)
				end
			end
		end
		
		-----------
		if (table.count(aPath) > 0) then
			self.CURRENT_PATH_NODE = 0
			self.CURRENT_PATH_SIZE = table.count(aPath)
			self.CURRENT_PATH_ARRAY = aPath
			self.CURRENT_PATH_PLAYER = bPlayer
			self.CURRENT_PATH_TARGET = hTarget
			self.CURRENT_PATH_LAST_TARGET = hTarget
			self.CURRENT_PATH_GOAL = vGoal
			self.CURRENT_PATH_IGNOREPLAYERS = bIgnorePlayers
			
			self:Log(0, "Path Generated in %0.4fs (tClass: %s, tId: %s), tDist: %f, iNodes: %d)", timerdiff(hTimerStart), hTarget.class, tostring(hTarget.id), iDistance, self.CURRENT_PATH_SIZE)
		else
			self:Log(3, "Failed to retrive new path to class %s!!", tostring(sTargetsClass))
			self:Log(3, "	environment count: %d/%d", self.SPAWNPOINT_ENVIRONMENT[1], self.SPAWNPOINT_ENVIRONMENT[2])
			if (bPlayer and not bRetry) then
				self:GetNewPath(self.CURRENT_PATH_ENVIRONMENT_CLASS, true, true)
			end
			
			if (hTarget) then
				self:SetEntityUnreachable(hTarget) end
				
			return false
		end
		
		return true
	end

---------------------------
-- ResetPath

BotNavigation.ResetPath = function(self)
		self.CURRENT_PATH_NODE = nil
		self.CURRENT_PATH_NODE_ABOVE = nil
		self.CURRENT_PATH_SIZE = nil
		self.CURRENT_PATH_ARRAY = nil
		self.CURRENT_PATH_FINISHTIME = nil
		self.CURRENT_PATH_PLAYER = nil
		self.CURRENT_PATH_TARGET = nil
		self.CURRENT_PATH_IGNOREPLAYERS = nil
		self.CURRENT_PATH_NODELAY = nil
		self.CURRENT_PATH_REVERTED = nil
		self.CURRENT_PATH_WAS_REVERTED = nil
		self.CURRENT_NODE_SURPASSED = nil
		self.CURRENT_NODE_LASTDISTANCE = nil
		self.CURRENT_PATH_INDOOR_NODES = nil
	end

---------------------------
-- ResetPathData

BotNavigation.ResetPathData = function(self)
		self.CURRENT_PATH_NODE = nil
		self.CURRENT_PATH_NODE_ABOVE = nil
		self.CURRENT_PATH_SIZE = nil
		self.CURRENT_PATH_ARRAY = nil
		self.CURRENT_PATH_FINISHTIME = nil
		self.CURRENT_PATH_PLAYER = nil
		self.CURRENT_PATH_TARGET = nil
		self.CURRENT_PATH_IGNOREPLAYERS = nil
		self.CURRENT_PATH_NODELAY = nil
		self.CURRENT_PATH_REVERTED = nil -- ??
		self.CURRENT_PATH_WAS_REVERTED = nil -- ??
		self.CURRENT_NODE_SURPASSED = nil
		self.CURRENT_NODE_LASTDISTANCE = nil
		self.CURRENT_PATH_INDOOR_NODES = nil
	end

---------------------------
-- GetRandomEntitiesForEnvironment

BotNavigation.GetRandomEntitiesForEnvironment = function(self)
		local aClasses = table.shuffle({
			"SCAR",
			"FY71",
			"SMG",
			"Shotgun",
			"DSG1",
			"Claymore"
		})
		aClasses = table.insertFirst(aClasses, "SpawnPoint")
		
		-----------
		for i, sClass in pairs(aClasses) do
			local aEntities = System.GetEntitiesByClass(sClass)
			if (table.count(aEntities) > 0) then
				local iReachableCount = 0
				for _i, ent in pairs(aEntities) do
					if (not self:WasEntityUnreachable(ent)) then
						iReachableCount = iReachableCount + 1 
					end
					
					if (iReachableCount >= 3) then
						return sClass 
					end
				end
			end
		end
	
		-----------
		return ""
	end

---------------------------
-- ClearPathGoalEnvironemnt

BotNavigation.ClearPathGoalEnvironemnt = function(self, sTargetsClass)
	
		-----------
		local sTargetsClass = sTargetsClass
		if (not isString(sTargetsClass)) then
			self.SPAWNPOINT_ENVIRONMENT = { 1, 0, {} }
			return end
	
		-----------
		if (not sTargetsClass or sTargetsClass == "") then
			sTargetsClass = self:GetRandomEntitiesForEnvironment() 
			if (not sTargetsClass) then
				return self:LogError("No Entities for Random Goal Environment were found!") end
			end
	
		-----------
		self.SPAWNPOINT_ENVIRONMENT = {
			1, -- Current
			0, -- Total
			table.shuffle(System.GetEntitiesByClass(sTargetsClass))
		}
		
		-----------
		self.SPAWNPOINT_ENVIRONMENT[2] = table.count(self.SPAWNPOINT_ENVIRONMENT[3])
		if (self.SPAWNPOINT_ENVIRONMENT[2] == 0) then
			self:LogWarning(0, "No Entities of Class '%s' found for Environment!", sTargetsClass) end
	end

---------------------------
-- WasEntityUnreachable

BotNavigation.WasEntityUnreachable = function(self, aTarget)
	
		-----------
		if (not self.CURRENT_PATH_UNREACHABLE_PLAYERS) then
			self.CURRENT_PATH_UNREACHABLE_PLAYERS = {} end
	
		-----------
		local iTime = self.CURRENT_PATH_UNREACHABLE_PLAYERS[aTarget.id] or (_time - 9999)
	
		-----------
		return (_time - iTime < 10)
	end

---------------------------
-- SetEntityUnreachable

BotNavigation.SetEntityUnreachable = function(self, aTarget)
	
		-----------
		if (not aTarget) then
			return false end
	
		-----------
		if (not self.CURRENT_PATH_UNREACHABLE_PLAYERS) then
			self.CURRENT_PATH_UNREACHABLE_PLAYERS = {} end
	
		-----------
		self.CURRENT_PATH_UNREACHABLE_PLAYERS[aTarget.id] = _time
	end

---------------------------
-- CheckIfPlayerMoved

BotNavigation.CheckIfPlayerMoved = function(self, vGoalPos, idPlayer, iThreshold)
	
		-----------
		if (not self.CURRENT_PATH_PLAYER) then
			return false end
			
		-----------
		if (not System.GetEntity(idPlayer.id)) then
			return false end
			
		-----------
		local vTarget = idPlayer:GetPos()
		local iDistance = vector.distance(vTarget, vGoalPos)
		local iThreshold = iThreshold or 5
		
		-----------
		return (iDistance > iThreshold)
	end

---------------------------
-- GetClosestAlivePlayer

BotNavigation.GetClosestAlivePlayer = function(self, bRetry)
	
		-------------
		if (not bot_hostility) then
			return end
	
		-------------
		if (self.CURRENT_PATH_RESETTIME and _time - self.CURRENT_PATH_RESETTIME < 3) then
			return end
	
		-------------
		local aTarget = { nil, -1 }
		
		-------------
		local vPos = g_localActor:GetPos()
		
		-------------
		local aPlayers = GetPlayers(bRetry)
		for i, player in pairs(aPlayers) do
			if (player.id ~= g_localActorId and Bot:AliveCheck(player) and not self:WasEntityUnreachable(player)) then
				local iDistance = vector.distance(player:GetPos(), vPos)
				if (aTarget[2] == -1 or iDistance < aTarget[2]) then
					local bOk = BotAI.CallEvent("IsTargetOk", player, iDistance)
					if (isDead(bOk) or bOk == true) then
						aTarget = { player, iDistance } end
				end
			end
		end
		
		-------------
		if (not aTarget[1] and not bRetry) then
			aTarget[1] = self:GetClosestAlivePlayer(true) end
		
		-------------
		return aTarget[1]
	end

-------------------
-- Bot.Navigation = BotNavigation

-------------------
return BotNavigation