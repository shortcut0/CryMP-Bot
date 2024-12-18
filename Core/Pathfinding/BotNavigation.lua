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
		
	SystemLog(sFmt)
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

-- Draw Tools
BotNavigation.DRAW_CURRENT_PATH = true or false
BotNavigation.DRAW_CURRENT_PATH_DISPLAYTIME = 5
BotNavigation.DRAW_CURRENT_PATH_TIMER = nil
BotNavigation.DRAW_USE_LINES = true

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
-- ResetAll

BotNavigation.ResetAll = function(self)

	self:ResetPath()
	self:ResetPathData()

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
end

---------------------------
-- SetSleepTimer

BotNavigation.SetSleepTimer = function(self, iTime)
	self.SLEEP_TIMER = timerinit()
	self.SLEEP_TIME = checkNumber(iTime, 1)

	NaviLog(debug.traceback())
end

---------------------------
-- Update

BotNavigation.Update = function(self)
	self:Log(5, "BotNavigation.Update()")
	
	----------------
	local vPos = g_localActor:GetPos()
	if ((BOT_CPP_PATHGEN > 0) and not timerexpired(Pathfinding.TIMER_CPP_PATH_GENERATE, Pathfinding.TIMER_CPP_PATH_TIMEOUT)) then
		return NaviLog("pending..")
	end

	----------------
	if (not (self.CURRENT_PATH_ARRAY)) then

		if (not timerexpired(self.SLEEP_TIMER, self.SLEEP_TIME)) then
			NaviLog("SLeeping !")
			return end

		NaviLog("No Path Exists, Generating new one!")
		self:GetNewPath()

		return -- return and wait for update next frame (because of c++ new thread)
	end

	----------------
	-- !!todo: come back to this,
	-- !!todo: might cause future problems
	local hCurrentTarget = self.CURRENT_PATH_TARGET
	if (hCurrentTarget) then
		self.CURRENT_PATH_ISPLAYER = (hCurrentTarget.actor)
		if ((self.CURRENT_PATH_ISPLAYER and self:CheckIfPlayerMoved(self.CURRENT_PATH_GOAL, self.CURRENT_PATH_TARGET))) then
			self.CURRENT_PATH_IGNOREPLAYERS = false
			self:GetNewPath(hCurrentTarget, false)

			return -- return and wait for update next frame (because of c++ new thread)
		end
	end

	----------------
	if (not self.CURRENT_PATH_ARRAY) then
		self.SLEEP_TIMER = timerinit()
		self.SLEEP_TIME = 0.25
		return
	end
	
	----------------
	if (self.CURRENT_PATH_NODE > self.CURRENT_PATH_SIZE) then
		-- self:Log(0, "End of path reached")
			
		if (not self.CURRENT_PATH_FINISHTIME) then 
			self.CURRENT_PATH_FINISHTIME = timerinit() end
			
		local iDelay = 0.5
		if (self.CURRENT_PATH_PLAYER) then
			iDelay = 0.15 end
				
		if (self.CURRENT_PATH_NODELAY) then
			iDelay = -1 end

		local iForced = Bot.FORCED_PATH_DELAY
		if (iForced) then
			iDelay = iForced end

		if (not timerexpired(self.CURRENT_PATH_FINISHTIME, iDelay)) then
			NaviLog("delay timer not expired!!")
			Bot.FORCED_PATH_DELAY = nil
			Bot:StopMovement()
			return
		end
			
		self:GetNewPath()
		return -- return and wait for update next frame (because of c++ new thread)
	end
	
	----------------
	if (not self.CURRENT_PATH_ARRAY) then
		NaviLog("No Path again !!")
		return
	end
	
	----------------
	local bReverted = false
	local hCurrentNode = self.CURRENT_PATH_ARRAY[self.CURRENT_PATH_NODE]
	if (hCurrentNode) then
		
		self.CURRENT_PATH_NODE_ABOVE = (self:IsNodeAbove(hCurrentNode) or self:IsNodeBelow(hCurrentNode))
		self.CURRENT_PATH_NODE_ABOVE_TERRAIN = (self.CURRENT_PATH_NODE_ABOVE or (self:IsNodeAboveTerrain(hCurrentNode, 2)))

		--Pathfinding:Effect(hCurrentNode, 0.5)
		if (self:IsNodeUnreachable(hCurrentNode)) then


            Pathfinding:Effect(hCurrentNode, 1)
			Bot:StopMovement()
			self:Log(0, "Current node is unreachable!")
			
			self.CURRENT_PATH_NODE_STUCK_TIME = timerinit()
			
			if (self.CURRENT_PATH_NODE > 1) then
				self.CURRENT_PATH_NODE = self.CURRENT_PATH_NODE - 1
				repeat 
					self.CURRENT_PATH_NODE = self.CURRENT_PATH_NODE - 1
					hCurrentNode = self.CURRENT_PATH_ARRAY[self.CURRENT_PATH_NODE]
					self:Log(3, "REVERTING to OLDER node %d!", self.CURRENT_PATH_NODE)
				until (not hCurrentNode or  self:IsNodeVisible(hCurrentNode, true))
					
				if (not hCurrentNode) then
					self:Log(0, "all reverted. no visible node found!")
					self:GetNewPath()
					return
				end
				bReverted = true
			else
				--self:ClearPathGoalEnvironemnt()
				--self:Log(3, "Resetting path")

				-- dont regenerate, instead check other nodes first!!
				NaviLog("First node on path is unreachable! Regenerating...")
				local iAnyVisible = self:GetAnyVisibleNodeOnPath()
				if (iAnyVisible) then
					self.CURRENT_PATH_NODE = iAnyVisible
					hCurrentNode = self.CURRENT_PATH_ARRAY[iAnyVisible]
				else
					NaviLog("NO VISIBLE NODE FOUND, AT ALL!!!")
					self:GetNewPath()
					self.CURRENT_PATH_RESETTIME = timerinit()
					return
				end
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
			self:GetNewPath()
			return
			-- BotLog("$4 TOO MUCH REVERTING WITHOUT PROGRESS!!! NEW PATH !!!")
		end
	else
		self.CURRENT_NODE_REVERTED = 0
	end
		
	----------------
	-- GetLastJump Might cause future problems!
	local iGoalDist = 2
	local bDriving = Bot:IsDriving()
	local hVehicle = Bot:GetVehicle()
	if (bDriving) then
		iGoalDist = 4

		-- FIXME: EXPERIMENTAL !!
		local vCenter = vector.modifyz(hVehicle:GetCenterOfMassPos(), 0.1)
		local vDir_Vehicle = hVehicle:GetDirectionVector()

		vPos = vector.add(vCenter, vector.scale(vDir_Vehicle, 5))
		--Pathfinding:Effect(vPos, 0.2)
	else
		if (hCurrentNode and System.IsPointIndoors(hCurrentNode) and not Bot:IsUnderground(hCurrentNode)) then
			self:Log(5, "POINT INDOORS. HIGH PRECISION GOAL DISTANCE!")
			iGoalDist = 0.5 end

		if (not timerexpired(self.CURRENT_PATH_NODE_STUCK_TIME, 1)) then
			NaviLog("super small!!")
			iGoalDist = 0.1
			if (hCurrentNode and System.IsPointIndoors(hCurrentNode)) then
				Bot:SetCameraTarget(hCurrentNode) end
		elseif (not bReverted and (self:IsLastNode(self.CURRENT_PATH_NODE) or (self:IsFirstNode(self.CURRENT_PATH_NODE) and self:IsNodeVisible(self.CURRENT_PATH_ARRAY[self.CURRENT_PATH_NODE])))) then
			iGoalDist = 1.85 end
	end
	----------------
	Bot.GOAL_REACHED_DISTANCE = iGoalDist
	Bot.CURRENT_PATH_NODES = self.CURRENT_PATH_SIZE
	Bot.CURRENT_PATH_NODE = self.CURRENT_PATH_NODE

	----------------
	local bUpdate = false
	local sUpdate

	----------------
	local iZDiffPos = 0
	local iZDiff = 0
	local iDistance

	if (hCurrentNode and not System.IsPointIndoors(hCurrentNode)) then
		iDistance = vector.distance(vPos, hCurrentNode)
		iZDiff = (hCurrentNode.z - vPos.z) -- > if node is ELEVATED
		iZDiffPos = (hCurrentNode.z - vPos.z)

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
	local bAdvancedPath = false
	--local vPos = g_localActor:GetPos()
	local iClosest, vClosest = self:GetClosestNodeOnPath(vPos)
	if (hCurrentNode and iClosest and iClosest > self.CURRENT_PATH_NODE and vector.distance(vClosest, vPos) < vector.distance(hCurrentNode, vPos)) then
		if (Pathfinding.Visible(vPos, vClosest) and self:IsNodeVisibleEx(vClosest) and iZDiff < 0.25) then
			PathFindLog("surpassed by far! set %d (old was %d) to next", iClosest, self.CURRENT_PATH_NODE)
			self.CURRENT_PATH_NODE = (iClosest - 1)
			bAdvancedPath = true
		end
	end

	----------------
	local bFlying = Bot:IsFlying()
	if (bFlying) then
		iGoalDist = (iGoalDist * 2)
	end
	Pathfinding:Effect(hCurrentNode, 0.1)

	----------------
	NaviLog("%f",iGoalDist)
	if (not hCurrentNode) then
		bUpdate = true
		sUpdate = "No Current Node!!"

	elseif (bAdvancedPath) then
		bUpdate = true
		sUpdate = "Advanced on path (somehow)"
		
	elseif (self.CURRENT_NODE_SURPASSED) then
		bUpdate = true
		sUpdate = "Current Node Surpassed!!"
		self.CURRENT_NODE_SURPASSED = nil
		self.CURRENT_NODE_LASTDISTANCE = nil
		
	--elseif (vector.distance2d(vPos, hCurrentNode) < iGoalDist) then
	--- why 2d
	--elseif (vector.distance(vPos, hCurrentNode) < iGoalDist) then
	-- try 2d and z
	elseif (((bFlying and vector.distance2d(vPos, hCurrentNode) < iGoalDist and iZDiff < 2) or (vector.distance(vPos, hCurrentNode) < iGoalDist and iZDiff < 0.25))) then
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
		if (not Bot:IsIndoors() and self:IsNodeVisibleEx(self.CURRENT_PATH_ARRAY[self.CURRENT_PATH_PREVIOUS_NODE])) then
			bUpdate = true
			sUpdate = "Previous Reverted node is now visible!!"
		
		end
	end
	-- ~...
	
	----------------
	self:Log(5, "Vec2D Distance To Goal: %f", (hCurrentNode and vector.distance2d(vPos, hCurrentNode) or 0))
	self:Log(5, "Is Node %d (/%d) last Node %s", self.CURRENT_PATH_NODE, self.CURRENT_PATH_SIZE, (self:IsLastNode(self.CURRENT_PATH_NODE) and "yes" or "no"))
	
	
	----------------
	if (bUpdate and self.CURRENT_PATH_NODE) then
		self.CURRENT_PATH_NODE = self.CURRENT_PATH_NODE + 1
		self:Log(0, "Updating Node Index to %d (%s)", self.CURRENT_PATH_NODE, sUpdate)
		hCurrentNode = self.CURRENT_PATH_ARRAY[self.CURRENT_PATH_NODE]
		
		self.CURRENT_PATH_WAS_REVERTED = nil
		self.CURRENT_NODE_SURPASSED = nil
	end
	
	----------------
	local bReturn = true
	
	----------------
	if (hCurrentNode and self.CURRENT_PATH_ARRAY) then
		self:Log(3, "Traveling to current path node: %d (pos: %s, distance: %f)", self.CURRENT_PATH_NODE, Vec2Str(hCurrentNode), vector.distance(g_localActor:GetPos(), hCurrentNode))
		Bot.PATHFINDING_FINALPATH_POS = self.CURRENT_PATH_ARRAY[table.count(self.CURRENT_PATH_ARRAY)]

		Bot:StartMoving(1, hCurrentNode, true)
		if (Bot:IsIndoors() and vector.distance(vPos, hCurrentNode) < 1.5) then
			Bot.FORCED_CAM_SPEED = BOT_CAMERASPEED_INSTANT
		else
			Bot.FORCED_CAM_SPEED = BOT_CAMERASPEED_AUTO
		end

		-- tunnel check
		if (System.IsPointIndoors(vPos) and not System.IsPointIndoors(hCurrentNode) and not Bot:IsUnderground(hCurrentNode, 3)and not Bot:IsUnderground(vPos, 3)) then
			self.LEAVE_INDOORS_TIMER = timerinit()
			NaviLog("current is INDOORS")
		end

		-- Particle.SpawnEffect("explosions.flare.a", hCurrentNode, g_Vectors.up, 0.1)
	else

		AIEvent("OnPathProbablyEnded")

		self:LogWarning(0, "Failed to retrive current pathnode (id: %d) path probably ended", self.CURRENT_PATH_NODE)
		Bot.PATHFINDING_FINALPATH_POS = nil
		bReturn = false

		if (self.CURRENT_PATH_ISPLAYER and self.CURRENT_PATH_TARGET and not Bot:IsVisible_Entity(self.CURRENT_PATH_TARGET)) then
			self:SetEntityUnreachable(self.CURRENT_PATH_TARGET)
		end

		if (self.CURRENT_PATH_NODE and self.CURRENT_PATH_SIZE) then
			if (self.CURRENT_PATH_NODE > self.CURRENT_PATH_SIZE) then
				self:ResetPathData()
			end
		end
	end

	----------------
	self.CURRENT_PATH_POS = hCurrentNode
		
	----------------
	self:Log(4, "Current Path Goal: %s (isPlayer: %s)", (self.CURRENT_PATH_TARGET and self.CURRENT_PATH_TARGET.class or "<null>"), (self.CURRENT_PATH_PLAYER and "Yes" or "No"))
		
	----------------
	return bReturn
end

---------------------------
-- GetAnyVisibleNodeOnPath

BotNavigation.GetAnyVisibleNodeOnPath = function(self)

	local aPath = self.CURRENT_PATH_ARRAY
	local iPath = self.CURRENT_PATH_SIZE
	if (not aPath) then
		return
	end

	local aBest = { -1 }

	local vPos = Bot:GetPos()
	local vNode, iDistance
	for iNodeID = 1, iPath do
		vNode = aPath[iNodeID]
		if (vNode) then
			iDistance = vector.distance(vNode, vPos)
			if (aBest[1] == -1 or iDistance < aBest[1]) then
				if (self:IsNodeVisible(vNode, true)) then
					aBest = {
						iDistance,
						iNodeID
					}
				end
			end
		end
	end

	return aBest[2]
end

---------------------------
-- GetClosestNodeOnPath

BotNavigation.GetClosestNodeOnPath = function(self, vPos)

	local aPath = self.CURRENT_PATH_ARRAY
	if (not aPath) then
		return
	end

	local aBest = { -1 }
	for iNode, vNode in pairs(aPath) do
		local iDistance = vector.distance(vPos, vNode)
		if (aBest[1] == -1 or iDistance < aBest[1]) then
			aBest = {
				iDistance,
				iNode,
				vNode
			}
		end
	end

	return aBest[2], aBest[3]
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
-- IsCurrentNodeIndoors

BotNavigation.IsCurrentNodeIndoors = function(self, bIgnoreUnderground)

	-----------
	if (not isArray(self.CURRENT_PATH_ARRAY)) then
		return end

	-----------
	local vCurrent = self:GetCurrentNodePos(self.CURRENT_PATH_NODE)
	if (vCurrent) then
		local bIndoors = System.IsPointIndoors(vCurrent)
		if (not bIgnoreUnderground) then
			return bIndoors
		end
		return (not Bot:IsUnderground(vector.modifyz(vCurrent, 0.25)))
	end

	return
end

---------------------------
-- GetLastIndoorsNodeOnPath

BotNavigation.GetLastIndoorsNodeOnPath = function(self)

	local bIndoors = Bot:IsIndoors()
	if (not bIndoors) then
		return
	end

	local aPath = self.CURRENT_PATH_ARRAY
	local iPath = table.count(aPath)
	local iCurrentNode = self.CURRENT_PATH_NODE
	if ((not aPath or not iCurrentNode) or iCurrentNode > iPath) then
		return
	end

	local vLastNode
	for iNode = iCurrentNode, iPath do
		local vNode = aPath[iNode]
		if (vNode and Bot:IsIndoors(vNode)) then
			vLastNode = vNode
		else
			break
		end
	end

	return vLastNode
end

---------------------------
-- GetNodeDistance

BotNavigation.GetNodeDistance = function(self)

	local iCurr = self.CURRENT_PATH_NODE
	local aPath = self.CURRENT_PATH_ARRAY
	local iPath = table.count(aPath)
	if (iPath == 0) then
		return
	end

	if (iCurr > iPath) then
		return
	end

	local vPos = Bot:GetPos()
	local vNode = aPath[iCurr]
	if (vNode and vPos) then
		return vector.distance(vPos, vNode)
	end
	return
end

---------------------------
-- IsPathNarrow

BotNavigation.IsPathNarrow = function(self)

	local iCurr = self.CURRENT_PATH_NODE
	local aPath = self.CURRENT_PATH_ARRAY
	local iPath = table.count(aPath)
	if (iPath == 0) then
		return false
	end

	if (iCurr >= iPath) then
		return false
	end

	if ((iCurr + 1) > iPath) then
		return false
	end

	local vNode = aPath[iCurr]
	local vNext = aPath[(iCurr +1)]
	if (not vNode or not vNext) then
		return false
	end

	local iUp = 1
	local iThreshold = 1.75

	vNode = vector.modifyz(vector.copy(vNode), iUp)
	vNext = vector.modifyz(vector.copy(vNext), iUp)

	local vDir = vector.dir(vNode, vNext, 1)

	local bNarrow
	for _, vTry in pairs({
		vector.mid(vNode, vNext),
		vector.interpolate(vNode, vNext, 0.25),
		vector.interpolate(vNode, vNext, 0.75),
	}) do
		for _, vTryDir in pairs({
			vector.left(vDir),
			vector.right(vDir)
		}) do
			bNarrow = (bNarrow or (RWI_GetPos(vTry, vTryDir, iThreshold) ~= nil))
			if (bNarrow) then
				if (BOT_DEBUG_MODE) then
					CryAction.PersistantArrow(vTry, 1, vTryDir, COLOR_RED, "", 10)
					CryAction.PersistantSphere(RWI_GetPos(vTry, vTryDir, 2.5), 1, COLOR_RED, "", 10)
				end
				break
			end
		end
		if (bNarrow) then break end
	end

	return bNarrow
end

---------------------------
-- IsPathElevating

BotNavigation.IsPathElevating = function(self, bIgnoreTerrain)

	local iCurr = self.CURRENT_PATH_NODE
	local aPath = self.CURRENT_PATH_ARRAY
	local iPath = table.count(aPath)
	if (iPath == 0) then
		return 0
	end

	local vCurr, vNext
	local iDiff
	local iCount = 0 -- to elevation
	local bTerrainOk

	for i = iCurr, iPath do
		vCurr = aPath[i]
		if (vCurr and i < iPath) then
			vNext = aPath[(i + 1)]
			iDiff = math.positive((vCurr.z - vNext.z))
			bTerrainOk = (bIgnoreTerrain or Pathfinding:IsPointOnTerrain(vCurr))

			if (bTerrainOk or iDiff < 0.25) then
				iCount = (iCount + 1)
			else
				break -- elevates
			end
		end
	end

	--NaviLog("coun=%d",iCount)
	return iCount
end

---------------------------
-- GetNodeCountToIndoors

BotNavigation.GetNodeCountToIndoors = function(self, bIgnoreUnderground)

	-----------
	if (not isArray(self.CURRENT_PATH_ARRAY)) then
		return end
		
	-----------
	local vCurrent = self:GetCurrentNodePos(self.CURRENT_PATH_NODE)
	if (vCurrent and self.CURRENT_PATH_NODE >= self.CURRENT_PATH_SIZE) then
		return (System.IsPointIndoors(vCurrent) and 1 or 0) end
	
	-----------
	local iCounter = 0
	local bIndoorsFound = false
	for iNode = self.CURRENT_PATH_NODE, self.CURRENT_PATH_SIZE, 1 do
		local vNode = self:GetCurrentNodePos(iNode)
		if (vNode and (not bIgnoreUnderground or not Bot:IsUnderground(vNode, -1))) then
			if (self:IsNodeIndoors(iNode) or System.IsPointIndoors(vNode)) then
				bIndoorsFound = true
				break
			else
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
-- SetCurrentPathNode

BotNavigation.SetCurrentPathNode = function(self, iNode, vNode)

	-----------
	if (not isArray(self.CURRENT_PATH_ARRAY)) then
		return end

	-----------
	if (not isNumber(iNode)) then
		return end

	-----------
	if (iNode > self.CURRENT_PATH_SIZE) then
		return end

	-----------
	PathFindLog("$4 SETTING NEW NODE TO %d", iNode)
	self.CURRENT_PATH_NODE = iNode
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
	local hEntity = self:GetTarget()
	if (hEntity) then
		return hEntity.id end
		
	return
end

---------------------------
-- GetTargetId

BotNavigation.GetTarget = function(self)
	return self.CURRENT_PATH_TARGET
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
	if (not vNode) then
		return false
	end

	local vNextNode = self.CURRENT_PATH_ARRAY[(iNode + 1)]
	
	local iZDiff = math.positive(vNode.z - vNextNode.z)
	local bZDiffOk = (iZDiff < 0.1)

	local bDriving = Bot:IsDriving()
	local bNode_Terrain = Pathfinding:IsPointOnTerrain(vNode)
	local bNext_Terrain = Pathfinding:IsPointOnTerrain(vNextNode)
	if (bNode_Terrain and bNext_Terrain) then
		if (bDriving) then
			bZDiffOk = (iZDiff < 1.25) -- so steep!
		else
			bZDiffOk = (iZDiff < 1.25) -- so steep!
		end
	end

	NaviLog("z=%f",iZDiff)
	if (not Bot:IsSwimming() and (not bZDiffOk)) then
		self:Log(0, "Ignoring next node because its ELEVATED!!")
		return false end
	
	return self:IsNodeVisible(vNextNode)
end

---------------------------
-- IsNodeUnreachable

BotNavigation.IsNodeUnreachable = function(self, vNode, bRayCheck)

	local bVisible = Pathfinding.Visible(Bot:GetPos(), vNode, nil, true)-- or self:IsNodeVisible(vector.modifyz(vNode, 1), true)
	if (not bVisible) then
		self.CURRENT_NODE_UNSEEN_TIME = (self.CURRENT_NODE_UNSEEN_TIME or 0) + System.GetFrameTime()
		self:Log(0, "UNSEEN TIME: %f", self.CURRENT_NODE_UNSEEN_TIME)
	else
		self:Log(0,"ok")
		self.CURRENT_NODE_UNSEEN_TIME = 0
	end
		
	-----------
	return self.CURRENT_NODE_UNSEEN_TIME > 0.75-- seconds!
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
	local vCamDir = Bot:GetViewCameraDir(1) -- NOT ACCURATE !!
	local vCamPos = Bot:GetViewCameraPos(1) -- NOT ACCURATE !!
	local vBotPos = vector.modifyz(Bot:GetPos(), 0.5) -- NOT ACCURATE !!
	local iDistance = vector.distance(vNode, vCamPos)

	-----------
	if (bRayCheck) then
		local bOk = (
				Physics.RayTraceCheck(vCamPos, vNode, g_localActorId, g_localActorId) or
				Physics.RayTraceCheck(vBotPos, vNode, g_localActorId, g_localActorId)
				--Physics.RayTraceCheck(vector.modifyz(Bot:GetPos(), 0.25), vNode, g_localActorId, g_localActorId)
		)
		if (bOk) then
			--NaviLog("OK!")
			return true
		end
	end

	-----------
	local bVisible = Pathfinding.CanSeeNode(vector.sub(vCamPos, vector.new(vCamDir)), vNode, g_localActorId)
	if (not bVisible) then
		bVisible = Pathfinding.CanSeeNode(vector.sub(g_localActor:GetBonePos("Bip01 Pelvis"), vector.new(vCamDir)), vNode, g_localActorId)
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
-- IsNodeVisible

BotNavigation.IsNodeVisible_Actor = function(self, vNode, hEntity)

		-----------
		local vDir = hEntity.actor:GetHeadDir()
		local vPos = hEntity.actor:GetHeadPos()
		local iDistance = vector.distance(vNode, vPos)

		-----------
		local bVisible = Pathfinding.CanSeeNode(vector.sub(vPos, vector.new(vDir)), vNode, hEntity.id)
		if (not bVisible) then
			bVisible = Pathfinding.CanSeeNode(vector.sub(hEntity:GetBonePos("Bip01 Pelvis"), vector.new(vDir)), vNode, hEntity.id)
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
		local iSize = self.CURRENT_PATH_SIZE
		if (not iNode or not iSize) then
			return false end
	
		-----------
		if (iNode >= iSize) then
			return true end
			
		-----------
		iNode = iNode + 1
		if (iNode >= self.CURRENT_PATH_SIZE) then
			local vEndNode = self.CURRENT_PATH_ARRAY[iNode]
			local vCurrNode = self.CURRENT_PATH_ARRAY[(iNode - 1)]
			
			return (iNode >= iSize and ((((vCurrNode and vector.distance(vCurrNode, vEndNode) < 0.5)) or self:IsNodeVisible_Source(vEndNode, vCurrNode))))
		end
		
		-----------
		-- self:Log(0, "NODE : %d", iNode)
			
		-----------
		local vPos = g_localActor:GetPos()
		local vEnd = self.CURRENT_PATH_ARRAY[iSize]
		if (vEnd) then
			local iDistance = vector.distance(vPos, vEnd)
			return (iDistance < 0.5 or (iDistance < 2.25 and self:IsNodeVisible_Source(vEnd, vPos)))
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
-- IsCurrentNodeUnderwater

BotNavigation.IsCurrentNodeUnderwater = function(self)

		local iCurrent = self.CURRENT_PATH_NODE
		if (not iCurrent) then
				return false
		end
		
		-----------
		local vNode = self.CURRENT_PATH_ARRAY[iCurrent]

		
		-----------
		return (Bot:IsUnderwater(vNode, 0.25))
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
		local zDiff = (vNode.z - iTerrain)
		return (zDiff > checkNumber(iMaxDistance, 1))
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
	if (not hCurrentNode) then
		return
	end

	-----------
	local vPosition = g_localActor:GetPos()

	-----------
	local iDistance_C = vector.distance(hCurrentNode, vPosition)
	local iDistance_N = vector.distance(hNextNode, vPosition)

	-----------

	local iZDiff = math.positive(hNextNode.z - hCurrentNode.z)
	local iBotZDiff = math.positive(hNextNode.z - vPosition.z)
	local bZDiffOk = ((iZDiff < 0.1) or (iBotZDiff < 0.2))

	local bDriving = Bot:IsDriving()
	local bNode_Terrain = Pathfinding:IsPointOnTerrain(hCurrentNode)
	local bNext_Terrain = Pathfinding:IsPointOnTerrain(hNextNode)
	if (bNode_Terrain and bNext_Terrain) then
		if (bDriving) then
			bZDiffOk = (iZDiff < 1.25 or (iBotZDiff < 0.2)) -- so steep!
		else
			bZDiffOk = (iZDiff < 1.25 or (iBotZDiff < 0.2)) -- so steep!
		end
	end
	-----------
	if (not Bot:IsSwimming() and (not bZDiffOk)) then
		self:Log(0, "Ignoring Next node despite it being closer (ITS ELEVATED!)")
		return false
	end

	-----------
	return self:IsNodeVisible(hNextNode) and (iDistance_N < iDistance_C)
end

---------------------------
-- IsWalljumpLink

BotNavigation.IsWalljumpLink = function(self, iNode, iNextNode)

	local aNavmesh = Pathfinding:GetNavmesh()
	if (not aNavmesh) then
		return false
	end

	local aNode = aNavmesh[iNode]
	if (not aNode) then
		return
	end

	local aLinks = aNode.links
	local aWalljumpLink = aNode.walljump_links
	if (not (aLinks and aWalljumpLink)) then
		return
	end

	return (aLinks[iNextNode] == true and aWalljumpLink[iNextNode] == true)
end

---------------------------
-- GetWallJumpStart

BotNavigation.GetWallJumpStart = function(self, iNode)

	if (not BOT_WJ_NAVMESH) then
		return false
	end

	local aNodes = BOT_WJ_NAVMESH[iNode]
	if (not aNodes) then
		return
	end

	return aNodes[1]
end

---------------------------
-- GetWallJumpStart

BotNavigation.GetWallJumpEnd = function(self, iNode)

	if (not BOT_WJ_NAVMESH) then
		return false
	end

	local aNodes = BOT_WJ_NAVMESH[iNode]
	if (not aNodes) then
		return
	end

	local iNodes = table.count(aNodes)
	return aNodes[iNodes]
end

---------------------------
-- GetWallJumpStart

BotNavigation.GetWallJumpPos = function(self, iNode, iIndex)

	if (not BOT_WJ_NAVMESH) then
		return false
	end

	local aNodes = BOT_WJ_NAVMESH[iNode]
	if (not aNodes) then
		return
	end

	local iNodes = table.count(aNodes)
	if (iIndex > iNodes or iIndex < 1) then
		return
	end

	return aNodes[iIndex]
end

---------------------------
-- GetWallJumpStart

BotNavigation.GetWallJumpNodes = function(self, iNode)

	if (not BOT_WJ_NAVMESH) then
		return false
	end

	local aNodes = BOT_WJ_NAVMESH[iNode]
	if (not aNodes) then
		return
	end

	local iNodes = table.count(aNodes)
	return iNodes
end

---------------------------
-- ShouldWallJump

BotNavigation.ShouldWallJump = function(self, vTarget, idTarget1, idTarget2)

	if (not BOT_CAN_WALLJUMP) then
		return
	end

	if (not BOT_WJ_NAVMESH) then
		return false
	end

	if (not timerexpired(self.LAST_WALLJUMP_CHECK, checkVar(self.NEXT_WALLJUMP_TIME, 2))) then
		return
	end

	self.NEXT_WALLJUMP_TIME = math.random(3, 10)

	local iMaxStartPointDistance = 2
	local iMaxEndPointDistance = 3

	local vPos = Bot:GetPos()
	local aBest = { -1, iMaxStartPointDistance, iMaxEndPointDistance }
	local iDistance = vector.distance(vPos, vTarget)
	local iThresholdDistance = 5 -- at least this amount of m closer than without jump
	local iDistanceA, iDistanceB
	local vLastNode, vFirstNode
	local bCloser

	local bVisible_Start, bVisible_End

	for i, aNodes in pairs(BOT_WJ_NAVMESH) do

		vFirstNode = aNodes[1][1]
		vLastNode = aNodes[table.count(aNodes)][1]

		iDistanceA = vector.distance(vFirstNode, vPos)
		iDistanceB = vector.distance(vLastNode, vTarget)

		bCloser = (iDistance - iDistanceB >= iThresholdDistance)

	--	PathFindLog("%s",table.tostring(aNodes))
	--	Bot:SpawnDebugEffect(vFirstNode, i)
	--	Bot:SpawnDebugEffect(vLastNode, i..i)

		if (iDistanceA < aBest[2] or aBest[2] == -1) then
			if (bCloser and (iDistanceB < aBest[3] or aBest[3] == -1) and iDistanceB > 2) then
				bVisible_Start = Bot:IsVisible_Points(vPos, vFirstNode, checkVar(idTarget1, g_localActorId), checkVar(idTarget2, g_localActorId))
				bVisible_End = Bot:IsVisible_Points(vPos, vLastNode, checkVar(idTarget1, g_localActorId), checkVar(idTarget2, g_localActorId))
				if (bVisible_Start and bVisible_End) then
					aBest[1] = i
					aBest[2] = iDistanceA
					aBest[3] = iDistanceB
				end
			end
		end
	end

	return (aBest[1] ~= -1), aBest[1]
end

---------------------------
-- GetClosestNodeFromPoint

BotNavigation.GetClosestNodeFromPoint = function(self, vPos)

	local aData = self.CURRENT_PATH_ARRAY
	if (not aData) then
		return
	end

	local aBest = { nil, -1 }
	local iDistance

	for i, vNode in pairs(aData) do
		if (Bot:IsVisible_Points(vNode, vPos, g_localActorId)) then
			iDistance = vector.distance(vNode, vPos)
			if (iDistance < aBest[2] or aBest[2] == -1) then
				aBest[1] = vNode
				aBest[2] = iDistance
			end
		end
	end

	return aBest[1]
end

---------------------------
-- ShouldWallJumpOnPath

BotNavigation.ShouldWallJumpOnPath = function(self)

	if (not BOT_CAN_WALLJUMP) then
		return
	end

	if (not BOT_WJ_NAVMESH) then
		return false
	end

	if (not timerexpired(self.LAST_WALLJUMP_CHECK, checkVar(self.NEXT_WALLJUMP_TIME, 2))) then
		return
	end

	self.NEXT_WALLJUMP_TIME = 0-- math.random(3, 10)

	local iMaxStartPointDistance = 4
	local iMaxEndPointDistance = 3

	local vPos = Bot:GetPos()
	local aBest = { -1, iMaxStartPointDistance, iMaxEndPointDistance, nil, -1 }
	local iDistance
	local iThresholdDistance = 5 -- at least this amount of m closer than without jump
	local iDistanceA, iDistanceB
	local vLastNode, vFirstNode
	local bCloser
	local vClosestFromEnd

	local vSkipTo, iSkipTo
	local bVisible_Start, bVisible_End

	local iCurrNode = self.CURRENT_PATH_NODE
	if (self.CURRENT_PATH_ARRAY_RAW and iCurrNode) then
		for iNextNode, aNode in pairs(self.CURRENT_PATH_ARRAY_RAW) do
			if (iNextNode > iCurrNode) then

				local aWJLink = aNode.walljump_links
				if (aWJLink) then
					aWJLink = aWJLink[iNextNode]
					if (aWJLink and aWJLink.Ok == true) then
						if (vector.distance(vPos, aNode.pos) < 8) then
							NaviLog("FORCING WALLJUM???")
							return true, aWJLink.ID, aNode.pos, iNextNode
						end
					end
				end
			end
		end
	end

	for i, aNodes in pairs(BOT_WJ_NAVMESH) do

		vFirstNode = aNodes[1][1]
		vLastNode = aNodes[table.count(aNodes)][1]

		vClosestFromEnd = self:GetClosestNodeFromPoint(vLastNode)

		if (vClosestFromEnd) then
			iDistanceA = vector.distance(vFirstNode, vPos)
			iDistanceB = vector.distance(vLastNode, vClosestFromEnd)

			--BotMainLog("path=%d, DA = %f, DB = %f",i, iDistanceA, iDistanceB)

			bCloser = true--(iDistance - iDistanceB >= iThresholdDistance)

			--	PathFindLog("%s",table.tostring(aNodes))
			--	Bot:SpawnDebugEffect(vFirstNode, i)
			--	Bot:SpawnDebugEffect(vLastNode, i..i)

			if (iDistanceA < aBest[2] or aBest[2] == -1) then

				--Bot:SpawnDebugEffect(vClosestFromEnd, i..i..i, 1)
				--BotMainLog("p:%d, dist 1 ok",i)



				--do return end
				if (bCloser and (iDistanceB < aBest[3] or aBest[3] == -1)) then

					--BotMainLog("dist 2 ok")

					bVisible_Start = Bot:IsVisible_Points(vPos, vFirstNode, checkVar(idTarget1, g_localActorId), checkVar(idTarget2, g_localActorId))
					bVisible_End = Bot:IsVisible_Points(vClosestFromEnd, vLastNode, checkVar(idTarget1, g_localActorId), checkVar(idTarget2, g_localActorId))

					if (bVisible_Start and bVisible_End) then

						--BotMainLog("end and next node is visible")
						--BotMainLog("start and pos is visible")

						--Bot:SpawnDebugEffect(vLastNode, "vLastNode", 1)
						--g_localActor:SetPos(vLastNode)
						vSkipTo, iSkipTo = Pathfinding:GetClosestVisiblePoint_OnPath(vLastNode)


						if (iSkipTo and iSkipTo > self.CURRENT_PATH_NODE and vSkipTo) then

							--BotMainLog("skip is ok!! %d",iSkipTo)

							aBest[1] = i
							aBest[2] = iDistanceA
							aBest[3] = iDistanceB
							aBest[4] = vSkipTo
							aBest[5] = iSkipTo

							--Repeat(function()
							--	Bot:SpawnDebugEffect(vSkipTo, math.random(1,100000), 1)
							--	--g_localActor:SetPos(vLastNode)
							--	--Bot:SpawnDebugEffect(vLastNode, math.random(1,100000), 0.5)
							--	-- 	Bot:SpawnDebugEffect(vFirstNode, math.random(1,100000), 0.1)
							--	BotMainLog("START NODE DISTANCE FROM BOT: %f",iDistanceA)
							--	BotMainLog("SKIP TO INDEX %d FROM %d",iSkipTo,self.CURRENT_PATH_NODE)
							--end, 10, 1000)
							--SYSTEM_INTERRUPTED = true
							--do return end

							--Pathfinding:DebugPath()
						end
					end
				end
			end
		end
	end

	local bAllOk = (aBest[1] ~= -1 and aBest[5] ~= -1 and aBest[4] ~= nil)
	return bAllOk, aBest[1], aBest[4], aBest[5]
end

---------------------------
-- GetNewPath

BotNavigation.GetNewPath = function(self, pTarget, bIgnorePlayers, bRetry)

	-----------
	if (Bot:HasTarget()) then
--		throw_error("bad, bot has target!")
		return
	end

	-----------
	if (not timerexpired(self.LAST_PATH_GENERATE, 1)) then
		return
	end

	self.LAST_PATH_GENERATE = timerinit()
	NaviLog("Get new Path now!")

	-----------
	local hTarget = pTarget
	local bTarget = false
	local bAITarget

	-----------
	self.AI_TARGET_ISSAME = nil

	-----------
	local hTimer = timernew()
	if (not hTarget or not isArray(hTarget)) then

		NaviLog("new path!")
		local hAITarget = BotAI.CallEvent("GetPathGoal", hTarget)
		if (not isDead(hAITarget)) then
			hTarget = hAITarget
			bAITarget = true

			--Pathfinding:Effect(hTarget:GetPos(),1)
			if (hTarget) then
				NaviLog("AITarget: %s", g_TS(hTarget:GetName()))
			end

			if (hTarget and Bot:GetDistance(hTarget) < 1) then

				NaviLog("already there...")
				--[[hAITarget = BotAI.CallEvent("PathGoalReached")
				if (hAITarget and hAITarget.id ~= hTarget.id) then
					hTarget = hAITarget
					bAITarget = true
				elseif (hAITarget == nil) then
					self:ResetPath()
					NaviLog("No target?")
					return
				elseif (hAITarget == hTarget) then
					NaviLog("Target still same?")
					--self.AI_TARGET_ISSAME = true
					return
				else
					self:ResetPath()
					PathFindLog("AI Target changd (%s, %s, %s)", g_TS(hTarget.id), g_TS(hAITarget.id), g_TS(hAITarget.id ~= hTarget.id))
					return
				end--]]
				--return
			end
		end
	else
		bTarget = true
		NaviLog("Path Target was passed as Argument: $4%s", hTarget:GetName())
	end

	NaviLog("Operation took %fs", hTimer.diff())

	-----------
	self:ResetPath()

	-----------
	local bPlayer = (hTarget and hTarget.actor ~= nil)
	local hTimer = timernew()
	local iDistance = 0
	local aPath = {}
	local vGoal

	-----------
	Pathfinding:SetCurrentTarget(hTarget)

	-----------
	if (hTarget) then

		local vPos = vector.modifyz(g_localActor:GetPos(), 0.5)
		local vTarget = vector.modifyz(hTarget:GetPos(), 0.5)

		iDistance = vector.distance(vPos, vTarget)
		vGoal = vTarget

		self.TIMER_PATHGEN = timernew()

		aPath = Pathfinding:GetPath(vPos, vGoal, function(aResult, aRawResult)
			BotNavigation:ResolvePath(aResult, aRawResult, hTarget)
		end)

		---------------------------------

		self.CURRENT_PATH_PLAYER = bPlayer
		self.CURRENT_PATH_ISPLAYER = bPlayer
		self.CURRENT_PATH_TARGET = hTarget
		self.CURRENT_PATH_LAST_TARGET = hTarget
		self.CURRENT_PATH_GOAL = vGoal
		self.CURRENT_PATH_GOALDIST = iDistance
		self.CURRENT_PATH_IGNOREPLAYERS = bIgnorePlayers

		---------------------------------

		if (BOT_CPP_PATHGEN) then
			return
		end

		self:ResolvePath(aPath, aPath, hTarget)
		--if (not aPath and bPlayer) then
		--	aPath = self:GetNewPath(self.CURRENT_PATH_ENVIRONMENT_CLASS, true)
		--end
	end
	return true
end

---------------------------
-- ResolvePath

BotNavigation.ResolvePath = function(self, aPath, aRawPath, hTarget)


	-----------
	if (table.count(aPath) > 0) then

		self.LAST_PATHGEN_FAILED = false
		self.CURRENT_PATH_NODE = 0
		self.CURRENT_PATH_SIZE = table.count(aPath)
		self.CURRENT_PATH_ARRAY = aPath
		self.CURRENT_PATH_ARRAY_RAW = aRawPath

		self:Log(0, "Path Generated in %fs iNodes: %d", self.TIMER_PATHGEN.diff(), self.CURRENT_PATH_SIZE)
		self:Log(0, "Target = %s", hTarget:GetName())
		self:Log(0, tracebackEx())

		-----------
	else
		self.LAST_PATHGEN_FAILED = true

		if (hTarget) then
			self:SetEntityUnreachable(hTarget)
		end
		return false
	end
end

---------------------------
-- ResetPath

BotNavigation.ResetPath = function(self)

	NaviLog("ResetPath() %s",tracebackEx())
	self.CURRENT_PATH_NODE = nil
	self.CURRENT_PATH_NODE_ABOVE = nil
	self.CURRENT_PATH_SIZE = nil
	self.CURRENT_PATH_ARRAY = nil
	self.CURRENT_PATH_FINISHTIME = nil
	self.CURRENT_PATH_PLAYER = nil
	self.CURRENT_PATH_ISPLAYER = nil
	self.CURRENT_PATH_TARGET = nil
	self.CURRENT_PATH_IGNOREPLAYERS = nil
	self.CURRENT_PATH_NODELAY = nil
	self.CURRENT_PATH_REVERTED = nil
	self.CURRENT_PATH_WAS_REVERTED = nil
	self.CURRENT_NODE_SURPASSED = nil
	self.CURRENT_NODE_LASTDISTANCE = nil
	self.CURRENT_PATH_INDOOR_NODES = nil
	self.CURRENT_PATH_GOALDIST = nil
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
		self.CURRENT_PATH_ISPLAYER = nil
		self.CURRENT_PATH_TARGET = nil
		self.CURRENT_PATH_IGNOREPLAYERS = nil
		self.CURRENT_PATH_NODELAY = nil
		self.CURRENT_PATH_REVERTED = nil -- ??
		self.CURRENT_PATH_WAS_REVERTED = nil -- ??
		self.CURRENT_NODE_SURPASSED = nil
		self.CURRENT_NODE_LASTDISTANCE = nil
		self.CURRENT_PATH_INDOOR_NODES = nil
		self.CURRENT_PATH_GOALDIST = nil
	end

---------------------------
-- GetPathGoal

BotNavigation.GetPathGoal = function(self)
	return (self.CURRENT_PATH_GOAL)
end
---------------------------
-- GetPathGoal

BotNavigation.IsPathGoalIndoors = function(self)
	local aGoal = (self.CURRENT_PATH_GOAL)
	if (not aGoal) then
		return false
	end

	return (System.IsPointIndoors(aGoal) and not Bot:IsUnderground(aGoal))
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
		if (not self.CURRENT_PATH_ISPLAYER) then
			BotMainLog("player no")
			return false end
			
		-----------
		if (not System.GetEntity(idPlayer.id)) then
			return false end
			
		-----------
		local vTarget = idPlayer:GetPos()
		local iDistance = vector.distance(vTarget, vGoalPos)

		-----------
		--BotMainLog("i=%f",iDistance)
		return (iDistance > checkVar(iThreshold, 45))
	end

---------------------------
-- PaintPath

BotNavigation.UpdatePaintPath = function(self)
	if (self.DRAW_CURRENT_PATH) then
		if (timerexpired(self.DRAW_CURRENT_PATH_TIMER, 1)) then
			self:PaintPath()
		end
	end
end

---------------------------
-- PaintPath

BotNavigation.PaintPath = function(self, iDisp)

	-----------
	local aPath = self.CURRENT_PATH_ARRAY
	local iPath = table.count(aPath)
	if (iPath == 0) then
		return end

	-----------
	local iDisplayTime = (iDisp or self.DRAW_CURRENT_PATH_DISPLAYTIME)
	local aLinkColor = { 0, 0, 1 } -- Blue
	local aNodeColor = { 0, 0, 1 } -- Blue

	-----------
	local vCurr, vNext, vDir
	for i = 1, iPath do

		vCurr = aPath[i]
		vNext = aPath[(i + 1)]

		-- Draw Node
		CryAction.PersistantSphere(vCurr, 0.5, aNodeColor, ("PaintedSphere_" .. i), iDisplayTime)
		if (vector.length(vCurr) == 0) then
		end

		-- Draw Link
		if (i < iPath) then

			vDir = vector.getdir(vCurr, vNext, 1)

			-- Select Draw Method
			if (self.DRAW_USE_LINES) then
				CryAction.PersistantLine(vCurr, vNext, aLinkColor, ("PaintedLine_" .. i), iDisplayTime)
			else
				CryAction.PersistantArrow(vCurr, 1, vDir, aLinkColor, ("PaintedLink_" .. i), iDisplayTime)
			end
		end
	end

	-----------
	self.DRAW_CURRENT_PATH_TIMER = timerinit()
end

-------------------
-- Bot.Navigation = BotNavigation

-------------------
return BotNavigation