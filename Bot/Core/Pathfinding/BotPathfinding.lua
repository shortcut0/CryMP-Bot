--=====================================================
-- CopyRight (c) R 2022-2203
--
-- Pathfinding utilities for the CryMP bot project
--
--=====================================================

PathFindLog = function(msg, ...)
	local sFmt = "[PathFinder] " .. tostring(msg)
	if (...) then
		sFmt = string.format(sFmt, ...) end
		
	System.LogAlways(sFmt)
end

-------------------
local aGenNavmesh
if (Pathfinding) then
	aGenNavmesh = Pathfinding.RECORDED_NAVMESH
end

-------------------
Pathfinding = {
	version = "0.0",
	author = "shortcut0",
	description = "pathfinding utilities for the bot"
}


-------------------
Pathfinding.VALIDATED_NAVMESH = {}
Pathfinding.NAVMESH_VALIDATED = false
Pathfinding.VALIDATION_FUNC = nil
Pathfinding.NAVMESH_WATER_MAX_DEPTH = 1
Pathfinding.NODE_MAX_DIST = 20
Pathfinding.NODE_MAX_DIST_PANIC = 25
Pathfinding.NODE_Z_MAX_DIST = 1

-------------------
Pathfinding.RECORD_NAVMESH = false
Pathfinding.AUTO_PAINT_NAVMESH = true
Pathfinding.RECORDED_NAVMESH = {}
Pathfinding.RECORD_INSERT_DIST = 2.5
Pathfinding.RECORD_INSERT_DIST_Z = 0.35
Pathfinding.RECORD_SKIP_FLYING = true

-------------------
-- Pathfinding.Init

Pathfinding.Init = function(self, bReload)

	---------------------
	PathFindLog("Pathfinding.Init()")
	
	---------------------
	self:RemovePaintedNavmesh()
	
	---------------------
	if (not self.InitAStar(bReload)) then
		return false end
	
	---------------------
	if (not self.InitCVars(bReload)) then
		return false end
	
	---------------------
	if (not self:InitNavmesh(bReload)) then
		return false end
end

-------------------
-- Pathfinding.InitAStar

Pathfinding.InitAStar = function()

	---------------------
	PathFindLog("Loading AStar Library")
	
	---------------------
	local sLibPath = "Bot\\Core\\Pathfinding"
	
	---------------------
	local bOk, hLib = FinchPower:LoadFile(sLibPath .. "\\BotAStar.lua")
	if (not bOk) then
		return false end
			
	---------------------
	PathFindLog("AStar Library loaded")
			
	---------------------
	return true
end

-------------------
-- Pathfinding.InitCVars

Pathfinding.InitCVars = function()

	---------------------
	local sPrefix = "pathfinding_"
	local aCVars = {
		{ "init",       		"Pathfinding:Init(true)", 				"Re-initializes the Bot Pathfinding System" },
		{ "reloadfile", 		"Bot:LoadPathfinding()",  				"Reloads the Pathfinding file" },
		{ "test",       		"Pathfinding:Test(%1)",   				"Tests the Pathfinding System" },
		{ "test2",       		"Pathfinding:Test2()",   				"Tests the Pathfinding System" },
		{ "test_live",  		"Pathfinding:LivePathfindingTest(%1)", 	"Tests the Pathfinding System with real time tests" },
		
		{ "paintlinks",			"Pathfinding:PaintLinks(nil,nil,30)",	"Paints all Links of all Nodes of the current Navmesh" },
		
		{ "livegen",			"Pathfinding:SetLiveNavMeshGen()",		"Toggles Real-Time Navmesh Generation" },
		
		{ "record",  			"Pathfinding:Record()",   				"Toggles Realtime-Generating Navmesh" },
		{ "record_all",  		"Pathfinding:SetRecordAll()",   		"Toggles Recording Positions of all Players" },
		{ "record_clear", 		"Pathfinding:RecordCls()",				"Clears current temporary Navmesh" },
		{ "record_paint", 		"Pathfinding:PaintNavmesh()",			"Paints the Currently Generated Navmesh on the Map" },
		{ "record_unpaint", 	"Pathfinding:RemovePaintedNavmesh()",	"Removes the Painted Navmesh" },
		{ "record_livepaint", 	"Pathfinding:SetAutoPaint()",			"Toggles Real-time Painting of Navmesh" },
		{ "record_import", 		"Pathfinding:MergeNavmesh()",			"Merges already Generated Navmesh you newly Generated one" },
		{ "record_insert", 		"Pathfinding:InsertNode()",				"Insers a New node at your current position" },
		
		{ "record_export", 		"Pathfinding:ExportNavmesh(Pathfinding.RECORDED_NAVMESH)", "Exports the newly generated Navmesh" },
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
	PathFindLog("Registered %d New Console Commands", iCVars)
	
	---------------------
	return true
	
end

-------------------
-- Pathfinding.InitNavmesh

Pathfinding.InitNavmesh = function(self, bReload, aNavmesh)
	
	PathFindLog("Pathfinding.InitNavmesh()")
	
	---------------------
	if (self.NAVMESH_VALIDATED) then
		if (not bReload) then
			return true end end
		
	---------------------
	BOT_NAVMESH = nil
		
	---------------------
	if (not aNavmesh) then
		if (not self:LoadNavmesh()) then
			return false end
	else
		BOT_NAVMESH = aNavmesh
	end
	
	---------------------
	PathFindLog("Vector Type is %s", vector.type(BOT_NAVMESH[1]))
	
	---------------------
	if (not Physics) then
		return false end
		
	---------------------
	local fRayCheck = Physics.RayTraceCheck
	if (not luautils.isfunction(fRayCheck)) then
		return false end
	
	---------------------
	self.VALIDATION_FUNC = fRayCheck
	
	---------------------
	local iStartTime = os.clock()
	
	---------------------
	PathFindLog("Maximum Node Distance: %f (Panic: %f)", self.NODE_MAX_DIST, self.NODE_MAX_DIST_PANIC)
	
	---------------------
	local iConnections = 0
	local iNodes = 0
	local aValidatedMesh = {}
	for i, pos in pairs(BOT_NAVMESH) do
	
		-- Script.SetTimer(i * 50, function()
			-- Particle.SpawnEffect("explosions.flare.a", pos, g_Vectors.up, 0.1)
		-- end)
	
		-------------------
		iNodes = iNodes + 1
	
		-------------------
		local aConnections = self:GenerateLinks(i, self.NODE_MAX_DIST)
		if (table.count(aConnections) == 0) then
			Particle.SpawnEffect("explosions.flare.a", pos, vectors.up, 0.1)
			PathFindLog("PANIC: Node %d had no links. retrying with panic distance", i)
			aConnections = self:GenerateLinks(i, self.NODE_MAX_DIST_PANIC)
		end
		
		-------------------
		iConnections = iConnections + table.count(aConnections)
				
		-------------------
		aValidatedMesh[i] = { id = i, pos = pos, links = aConnections, x = pos.x, y = pos.y, z = pos.z }
	end
	
	---------------------
	self:ValidateLinks(aValidatedMesh)
	
	---------------------
	self.VALIDATED_NAVMESH = aValidatedMesh
	
	---------------------
	self.NAVMESH_VALIDATED = true
	
	---------------------
	PathFindLog("Navmesh initialized in %0.4fs (Loops: %d, Nodes: %d, Connections: %d)", (os.clock() - iStartTime), (iNodes * iNodes), iNodes, iConnections)
	
	
	---------------------
	if (self.RECORDED_NAVMESH and self.AUTO_PAINT_NAVMESH and self.NAVMESH_AUTO_GENERATE) then
		self:PaintLinks(1) end
	
end

---------------------------------------------
-- Pathfinding.LoadNavmesh

Pathfinding.LoadNavmesh = function(self)

	---------------------
	local sRules, sMap = string.match(string.lower(Bot.GetLevelName()), "multiplayer/(.*)/(.*)")
	
	---------------------
	local sDataPath = string.format("Bot\\Core\\Pathfinding\\NavigationData\\Maps\\%s\\%s\\data.lua", sRules, sMap)
	
	---------------------
	PathFindLog("Loading Data for Map %s\\%s", sRules, sMap)
	
	---------------------
	if (not fileexists(sDataPath)) then
		return true, PathFindLog("No Data found for Map %s\\%s", sRules, sMap)
	end
	
	---------------------
	local sData = string.fileread(sDataPath)
	
	---------------------
	local bOk, hFunc = pcall(loadstring, sData)
	if (not bOk) then
		return false, PathFindLog("Failed to init Navmesh, Faulty data.lua")
	end
	
	---------------------
	local bOk, sErr = pcall(hFunc)
	if (not bOk) then
		return false, PathFindLog("Failed to read data.lua")
	end
	
	---------------------
	if (not BOT_NAVMESH or table.count(BOT_NAVMESH) < 1) then
		return false, PathFindLog("Empty Navmesh file", sMap, sRules)
	end
	
	---------------------
	return true
end

---------------------------------------------
-- Pathfinding.ValidateLinks

Pathfinding.ValidateLinks = function(self, aNavmesh)
	for i, aNode in pairs(aNavmesh) do
		local vNode = aNode.pos
		for iLink in pairs(aNode.links) do
			local vLink = aNavmesh[iLink].pos
			if (not aNavmesh[iLink].links[i]) then
				aNavmesh[iLink].links[i] = true
			end
		end
	end
end

---------------------------------------------
-- Pathfinding.GenerateLinks

Pathfinding.GenerateLinks = function(self, iSource, fMaxDistance)
	-----------------------
	local vSource = BOT_NAVMESH[iSource]
	
	-----------------------
	local fRayCheck = self.VALIDATION_FUNC
	
	-----------------------
	local aConnections = {}
	for iTarget, vTarget in pairs(BOT_NAVMESH) do
		if (iTarget ~= iSource) then
			if ((vTarget.z - vSource.z < self.NODE_Z_MAX_DIST) and (vTarget.z - vSource.z > -self.NODE_Z_MAX_DIST)) then
				local iDistance = vector.distance(vSource, vTarget)
				if (iDistance < fMaxDistance) then
					local bCanSee = fRayCheck(vector.modify(vSource, "z", 0.25, true), vector.modify(vTarget, "z", 0.25, true), NULL_ENTITY, NULL_ENTITY)
					if (bCanSee) then
						if (not self.IsPointIntersectedByWater(vector.validate(vSource), vector.validate(vTarget), self.NAVMESH_WATER_MAX_DEPTH)) then
							aConnections[iTarget] = true
						end
					end
				end
			end
		end
	end
	
	-----------------------
	return aConnections
end

---------------------------------------------
-- Pathfinding.IsPointIntersectedByWater

Pathfinding.IsPointIntersectedByWater = function(vSource, vEnd, iMaxDepth)

	-----------------------
	local iDistance = vector.distance(vSource, vEnd) / 2
	local vDirection = vector.scale(vector.getdir(vSource, vEnd, true), -1)
	
	-----------------------
	local vInBetween = {
		x = vSource.x + (vDirection.x * 5),
		y = vSource.y + (vDirection.y * 5),
		z = vSource.z + (vDirection.z * 5)
	}
	
	-----------------------
	local iWaterHeight = CryAction.GetWaterInfo(vInBetween)
	if (not iWaterHeight) then
		return false end
		
	-----------------------
	local vGround = Pathfinding.GetRayHitPosition(vector.modify(vInBetween, "z", 0.25, true), vectors.down, 100)
	if (not vGround) then
		return true end
		
	-----------------------
	local iDepth = (vSource.z - vGround.z)
	if (iDepth > iMaxDepth) then
		-- Particle.SpawnEffect("explosions.flare.a", vInBetween, vectors.up, 0.1)
		-- g_localActor:SetPos(vGround)
		-- Particle.SpawnEffect("explosions.flare.a", vGround, vectors.up, 0.1)
		-- PathFindLog("Intersected by water: depth: %f", iDepth)
		return true
	end
	
	return false
end

---------------------------------------------
-- Pathfinding.GetRayHitPosition

Pathfinding.GetRayHitPosition = function(vSource, vDirection, iDistance, fFlags, idIgnore)

	-------------------
	if (not idIgnore) then
		idIgnore = NULL_ENTITY end

	-------------------
	if (not fFlags) then
		fFlags = ent_all end
		
	-------------------
	if (not iDistance) then
		iDistance = 4096 end
		
	-------------------
	local vDir = vector.scale(vector.new(vDirection), iDistance)
	
	-------------------
	local iHits = Physics.RayWorldIntersection(vSource, vDir, iDistance, fFlags, idIgnore, nil, g_HitTable)
	local aHits = g_HitTable[1]
	
	-------------------
	if (iHits and iHits > 0 and isArray(aHits)) then
		return (aHits.pos or aHits.position) end
	
	-------------------
	return nil
end

---------------------------------------------
-- Pathfinding.IsOperational

Pathfinding.IsOperational = function()
	return (Pathfinding.NAVMESH_VALIDATED == true)
end

---------------------------------------------
-- Pathfinding.OnTick

Pathfinding.OnTick = function(self)

	------------------------------------
	if (not self.NAVMESH_VALIDATED) then
		return false end
		
	------------------------------------
	if (self.TESTFIND_ENTITY) then
		local idEntity = System.GetEntityByName(self.TESTFIND_ENTITY_NAME)
		if (idEntity) then
		
			-------------------
			local bReGen = false
			if (self.TESTGEN_PATH) then
				if (vector.distance(idEntity:GetPos(), self.TESTGEN_PATH[table.count(self.TESTGEN_PATH)]) > 5) then
					bReGen = true end
			else
				bReGen = true
			end
			
			-------------------
			if (bReGen) then
				self:Test(idEntity) end
			
			---------------------------
			if (self.TESTGEN_PATH) then
			
				---------------------------
				if (not self.TESTGEN_PATH_CURRENT) then
					self.TESTGEN_PATH_CURRENT = 1 end
			
				---------------------------
				if (self.TESTGEN_PATH_CURRENT > table.count(self.TESTGEN_PATH)) then
					self:Test(idEntity)
					return PathFindLog("End of path reached !")
				end
			
				---------------------------
				local idNext = self.TESTGEN_PATH[self.TESTGEN_PATH_CURRENT]
				g_localActor:SetPos(idNext)
				g_localActor:AddImpulse(-1, g_localActor:GetCenterOfMassPos(), g_Vectors.up, 50, 1)
				g_localActor:SetDirectionVector(vector.scale(vector.getdir(System.GetViewCameraPos(), idNext, true), -1))
				
				---------------------------
				self.TESTGEN_PATH_CURRENT = self.TESTGEN_PATH_CURRENT + 1
			end
		else
			PathFindLog("Cannot find test entity by name '%s'", self.TESTFIND_ENTITY_NAME)
		end
	end
end

---------------------------------------------
-- Pathfinding.LivePathfindingTest

Pathfinding.LivePathfindingTest = function(self, sEntityName)
	---------------------------
	if (self.TESTGEN_PATH) then
		self.TESTGEN_PATH = nil
		self.TESTGEN_PATH_CURRENT = nil
		self.TESTFIND_ENTITY = nil
		return PathFindLog("Test Stopped")
	end
	
	---------------------------
	self.TESTFIND_ENTITY = true
	self.TESTFIND_ENTITY_NAME = sEntityName or self.TESTFIND_ENTITY_NAME
	
	---------------------------
	return PathFindLog("Test Started with entity named %s", self.TESTFIND_ENTITY_NAME)
end

---------------------------------------------
-- Pathfinding.Test2

Pathfinding.Test2 = function(self)
	
	if (not self.TEST_POS_1) then
		self.TEST_POS_1 = g_localActor:GetPos()
		PathFindLog("Position 1 Set.")
	elseif (not self.TEST_POS_2) then
		self.TEST_POS_2 = g_localActor:GetPos()
		PathFindLog("Position 2 Set.")
	else
	
		PathFindLog("Intersected by water: %s", (self.IsPointIntersectedByWater(self.TEST_POS_1, self.TEST_POS_2, self.NAVMESH_WATER_MAX_DEPTH) and "Yes" or "No"))
	
		local vDir = vector.scale(vector.getdir(self.TEST_POS_1, self.TEST_POS_2), -1)
		PathFindLog("%s", Vec2Str(vDir))
		CryAction.PersistantArrow(self.TEST_POS_1, 1, vDir, vDir, "arrow", 10)
	
		self.TEST_POS_1 = nil
		self.TEST_POS_2 = nil
	end
end

---------------------------------------------
-- Pathfinding.Test

Pathfinding.Test = function(self, idClassOrEntity)
	---------------------
	self.TESTGEN_PATH = nil
	self.TESTGEN_PATH_CURRENT = nil
	
	---------------------
	local vStart = g_localActor:GetPos()
	local vEnd
	if (isArray(idClassOrEntity)) then
		vEnd = idClassOrEntity:GetPos()
	else
		vEnd = System.GetEntitiesByClass(idClassOrEntity or "SpawnPoint")
		vEnd = getrandom(vEnd)
		vEnd = vEnd:GetPos()
	end
	
	---------------------
	PathFindLog("Finding path from %s to %s", Vec2Str(vStart), Vec2Str(vEnd))
	
	---------------------
	local iStartTime = os.clock()
	
	---------------------
	local aPath = Pathfinding:GetPath(vStart, vEnd)
	if (not isArray(aPath)) then
		return PathFindLog("Failed to find a path")
	end
	
	---------------------
	PathFindLog("Found a path with %d nodes in %0.4fs", table.count(aPath), (os.clock() - iStartTime))
	
	---------------------
	self.TESTGEN_PATH = aPath
	
	---------------------
	if (not self.TESTFIND_ENTITY) then
		local iPath = table.count(aPath)
		for i, node in pairs(aPath) do
			 Script.SetTimer(i * 500, function()
				 PathFindLog("Node %d pos %s", i, Vec2Str(node))
				Particle.SpawnEffect("explosions.flare.a", node, g_Vectors.up, 0.1)
				g_localActor:SetPos(node)
			end)
			if (i < iPath) then
				local vDir = vector.scale(vector.getdir(node, aPath[(i + 1)]), -1)
				PathFindLog("%s", Vec2Str(vDir))
				CryAction.PersistantArrow(node, 1, vDir, vDir, "arrow_" .. i, 30)
			end
		end
	end
	---------------------
end

---------------------------------------------
-- Pathfinding.GetPath

Pathfinding.GetPath = function(self, vSource, vTarget)
	
	-----------------
	local aPath = { vSource, vTarget }
	
	-----------------
	if (self.VALIDATION_FUNC(vSource, vTarget, NULL_ENTITY, NULL_ENTITY) == true and self:NodesHaveSameElevation(vSource, vTarget)) then
		PathFindLog("vStart and vTarget are connected!")
		return aPath
	end
	
	-----------------
	local vClosest, iClosest = self:GetClosestVisiblePoint(vSource)
	if (not vClosest) then
		vClosest, iClosest = self:GetClosestPoint(vSource) end
		
	-----------------
	if (not vClosest) then
		return { } end
		
	local aClosest = self.VALIDATED_NAVMESH[iClosest]
	
	-----------------
	local vGoal, iGoal = self:GetClosestVisiblePoint(vTarget)
	if (not vGoal) then
		vGoal, iGoal = self:GetClosestPoint(vTarget) end
		
	-----------------
	if (not vGoal) then
		return { } end
		
	local aGoal = self.VALIDATED_NAVMESH[iGoal]
	
	-----------------
	local iStartTime = os.clock()
	
	-----------------
	aPath = astar.path(aClosest, aGoal, self.VALIDATED_NAVMESH, false, function(node, neighbor)
		return node.links[neighbor.id] == true
	end)
	
	----------------
	PathFindLog("Generated path with %d Nodes in %0.4fs", table.count(aPath), (os.clock() - iStartTime))
	
	----------------
	if (not isArray(aPath) or table.count(aPath) < 1) then
		return {} end
	
	----------------
	table.insertFirst(aPath, vClosest)
	table.insert(aPath, aGoal)
	
	----------------
	return self.Validate(aPath)
	
end

---------------------------------------------
-- Pathfinding.Validate

Pathfinding.Validate = function(aPath)
	local aValidated = {}
	
	----------------
	for i, node in pairs(aPath) do
		aValidated[i] = vector.validate(node)
	end
	
	----------------
	return aValidated
end

---------------------------------------------
-- Pathfinding.NodesHaveSameElevation

Pathfinding.NodesHaveSameElevation = function(self, vSource, vTarget)

	-----------
	local iZDiff = (vSource.z - vTarget.z)
	if (iZDiff > 1) then
		return false elseif (iZDiff < -0.5) then
			return false end
			
	-----------
	return true
end

---------------------------------------------
-- Pathfinding.CanSeeNode

Pathfinding.CanSeeNode = function(vSource, vTarget, idSource, idTarget)

	if (not idSource) then
		idSource = NULL_ENTITY end
		
	if (not idTarget) then
		idTarget = NULL_ENTITY end
	
	----------------
	return Pathfinding.VALIDATION_FUNC(vSource, vTarget, idSource, idTarget)
end

---------------------------------------------
-- Pathfinding.GetClosestVisiblePoint

Pathfinding.GetClosestVisiblePoint = function(self, vSource, pred)

	local aClosest = { nil, nil, -1 }
	
	-----------------
	for i, v in pairs(self.VALIDATED_NAVMESH) do
		if (pred == nil or pred(vSource, v.pos) == true) then
			local iDistance = vector.distance(v.pos, vSource)
			if ((iDistance < aClosest[3] or aClosest[3] == -1) and self.CanSeeNode(vSource, v.pos)) then
				aClosest = { v.pos, i, iDistance }
			end
		end
	end
	
	----------------
	return aClosest[1], aClosest[2]
end

---------------------------------------------
-- Pathfinding.GetClosestPoint

Pathfinding.GetClosestPoint = function(self, vSource, pred)

	local aClosest = { nil, nil, -1 }
	
	-----------------
	for i, v in pairs(self.VALIDATED_NAVMESH) do
		if (pred == nil or pred(vSource, v.pos) == true) then
			local iDistance = vector.distance(v.pos, vSource)
			if ((iDistance < aClosest[3] or aClosest[3] == -1)) then
				aClosest = { v.pos, i, iDistance }
			end
		end
	end
	
	----------------
	return aClosest[1], aClosest[2]
end


-------------------
-- Pathfinding.GetMapName

Pathfinding.GetMapName = function()
	local sRules, sMap = string.match(string.lower(Bot.GetLevelName()), "multiplayer/(.*)/(.*)")
	return sMap, sRules
end

-------------------
-- Pathfinding.PaintLinks

Pathfinding.PaintLinks = function(self, bForce, bClear, iTime)

	if (not bForce and self.RECORD_LINKS_LASTUPDATE and (_time - self.RECORD_LINKS_LASTUPDATE < 0.2)) then
		return end
	
	local iRadius = 1
	if (bClear) then
		iRadius = 0 end
		
	if (not iTime) then
		iTime = 1 end
		
	local aNavmesh = self.VALIDATED_NAVMESH
	for i, vNode in pairs(aNavmesh) do
		for iLink, bLinked in pairs(vNode.links) do
			local vDir = vector.scale(vector.getdir(vector.validate(vNode), vector.validate(aNavmesh[iLink])), -1)
			CryAction.PersistantArrow(vNode, iRadius, vDir, vDir, "arrow_" .. i .. "+" .. iLink, iTime)
		end
	end
	
	self.RECORD_LINKS_LASTUPDATE = _time
end

-------------------
-- Pathfinding.PaintNavmesh

Pathfinding.PaintNavmesh = function(self)
	if (not self.RECORD_NAVMESH) then
		return false end
		
	----------------
	if (not self.RECORDED_NAVMESH) then
		return false end
		
	----------------
	-- self:RemovePaintedNavmesh()
		
	----------------
	for i, node in pairs(self.RECORDED_NAVMESH) do
		local sName = string.format("BotNavi_Point%d_Painted", i)
		if (not System.GetEntityByName(sName)) then
			local idEntity = System.SpawnEntity({
				name = sName,
				class = "TagPoint",
				position = node,
				orientation = g_Vectors.up
			})
			
			idEntity:LoadObject(0, "Editor/Objects/ai_hide_point.cgf")
			idEntity:DrawSlot(0, 1)
		end
	end
	
	----------------
	PathFindLog("Painted %d Navmesh Nodes", table.count(self.RECORDED_NAVMESH))
end

-------------------
-- Pathfinding.RemovePaintedNavmesh

Pathfinding.RemovePaintedNavmesh = function(self)
		
	----------------
	local iCounter = 0
	for i, idEntity in pairs(System.GetEntities()) do
		if (string.match(idEntity:GetName(), "BotNavi_Point(%d+)_Painted")) then
			System.RemoveEntity(idEntity.id)
			iCounter = iCounter + 1
		end
	end
	
	----------------
	PathFindLog("Deleted %d Navmesh Nodes", iCounter)
end

-------------------
-- Pathfinding.SetAutoPaint

Pathfinding.SetAutoPaint = function(self)

	if (self.AUTO_PAINT_NAVMESH) then
		self.AUTO_PAINT_NAVMESH = false
		self:RemovePaintedNavmesh()
	else
		self.AUTO_PAINT_NAVMESH = true
		self:PaintNavmesh()
	end
	
	----------------
	PathFindLog("Realtime Navmesh Painting: %s", (self.AUTO_PAINT_NAVMESH and "Started" or "Stopped"))
end

-------------------
-- Pathfinding.InsertNode

Pathfinding.InsertNode = function(self)
	
	----------------
	if (not self.RECORDED_NAVMESH) then
		return false end
		
	----------------
	if (not self.RECORDED_NAVMESH) then
		self.RECORDED_NAVMESH = {} end
	
	----------------
	self.FORCE_INSERT_NODE = true
	
	----------------
	PathFindLog("Forcefully inserted new node at index %d", (table.count(self.RECORDED_NAVMESH) + 1))
end

-------------------
-- Pathfinding.MergeNavmesh

Pathfinding.MergeNavmesh = function(self)
	
	----------------
	if (not self.RECORDED_NAVMESH) then
		self.RECORDED_NAVMESH = {} end
	
	----------------
	if (not BOT_NAVMESH) then
		return false end
	
	----------------
	local iMerged = 0
	for i, node in pairs(BOT_NAVMESH) do
		if (not Pathfinding.IsNodesInRadius(node, self.RECORD_INSERT_DIST, self.RECORDED_NAVMESH)) then
			table.insert(self.RECORDED_NAVMESH, node)
			iMerged = iMerged + 1
		end
	end
	
	----------------
	PathFindLog("Added %d new Nodes to Navmesh", iMerged)
end

-------------------
-- Pathfinding.Record

Pathfinding.Record = function(self)
	if (self.RECORD_NAVMESH) then
		self.RECORD_NAVMESH = false
	else
		self.RECORD_NAVMESH = true
	end
	
	----------------
	if (not self.RECORDED_NAVMESH) then
		self.RECORDED_NAVMESH = {} end
	
	PathFindLog("Navmesh Recording: %s", (self.RECORD_NAVMESH and "Started" or "Paused"))
end

-------------------
-- Pathfinding.SetRecordAll

Pathfinding.SetRecordAll = function(self)
	if (self.RECORDED_NAVMESH_ALL) then
		self.RECORDED_NAVMESH_ALL = false
		self:PaintLinks(1, 1)
	else
		self.RECORDED_NAVMESH_ALL = true
	end
	
	PathFindLog("All-Player Recording: %s", (self.RECORDED_NAVMESH_ALL and "Started" or "Paused"))
	
end

-------------------
-- Pathfinding.SetLiveNavMeshGen

Pathfinding.SetLiveNavMeshGen = function(self)
	if (self.NAVMESH_AUTO_GENERATE) then
		self.NAVMESH_AUTO_GENERATE = false
	else
		self.NAVMESH_AUTO_GENERATE = true
	end
	
	PathFindLog("Real-time Navmesh Validation: %s", (self.NAVMESH_AUTO_GENERATE and "Started" or "Paused"))
	
end

-------------------
-- Pathfinding.RecordCls

Pathfinding.RecordCls = function(self)

	----------------
	local iNodes = table.count(self.RECORDED_NAVMESH or {})
	PathFindLog("Flushed %d Nodes", iNodes)
	
	----------------
	self:RemovePaintedNavmesh()
	
	----------------
	self.RECORDED_NAVMESH = {}
end

-------------------
-- Pathfinding.Update

Pathfinding.Update = function(self)
	if (not self.RECORD_NAVMESH) then
		return false end
		
	----------------
	if (not self.RECORDED_NAVMESH) then
		self.RECORDED_NAVMESH = {} end
		
	----------------
	if (self.RECORDED_NAVMESH_ALL) then
		for i, hPlayer in pairs(GetPlayers()) do
			self:RecordPlayerMovement(hPlayer)
		end
	else
		self:RecordPlayerMovement(g_localActor)
	end
	
	if (self.AUTO_PAINT_NAVMESH and self.NAVMESH_AUTO_GENERATE) then
		self:PaintLinks() end
end

-------------------
-- Pathfinding.Update

Pathfinding.RecordPlayerMovement = function(self, aActor)
	
	----------------
	if (not Bot:AliveCheck(aActor)) then
		return end
	
	----------------
	local bForceInsert = (aActor.id == g_localActorId and self.FORCE_INSERT_NODE)
	
	----------------
	local vPos = vector.modify(aActor:GetPos(), "z", 0.1, true)
	
	----------------
	local bCanInsert = false
	if (not Pathfinding.IsNodesInRadius(vPos, self.RECORD_INSERT_DIST, self.RECORDED_NAVMESH, 1.5)) then
		bCanInsert = true end
		
	----------------
	if (not bCanInsert) then
		bCanInsert = not self:CompareNodeZHeight(vPos, aActor.LAST_WORLD_POSITION)
		bCanInsert = bCanInsert and not Pathfinding.IsNodesInRadius(vPos, self.RECORD_INSERT_DIST, self.RECORDED_NAVMESH, 0.15)
	end
	
	----------------
	if (bCanInsert or bForceInsert) then
		if (not aActor.actor:IsFlying() or not self.RECORD_SKIP_FLYING) then
			aActor.LAST_WORLD_POSITION = vPos
			table.insert(self.RECORDED_NAVMESH, vPos)
			PathFindLog("%s$9 Added New Node $4%d$9 Pos: $1%s$9", aActor:GetName(), table.count(self.RECORDED_NAVMESH), Vec2Str(vPos))
			if (self.AUTO_PAINT_NAVMESH) then
				self:PaintNavmesh()  end
				
			if (self.NAVMESH_AUTO_GENERATE) then
				self.InitNavmesh(self, true, self.RECORDED_NAVMESH)
			end
		end
	end
	
	----------------
	if (bForceInsert) then
		self.FORCE_INSERT_NODE = false end
	
end

-------------------
-- Pathfinding.NodeHeightChanged

Pathfinding.CompareNodeZHeight = function(self, vNode, vOldNode)

	----------------
	local bHeightChanged = self:CompareNodeElevation(vNode, self.RECORD_INSERT_DIST_Z, vOldNode)
		
	----------------
	return bHeightChanged 
end

-------------------
-- Pathfinding.CompareNodeElevation

Pathfinding.CompareNodeElevation = function(self, vNode, iThreshold, vOldNode)

	----------------
	local iThreshold = (iThreshold or self.RECORD_INSERT_DIST_Z)

	----------------
	local iCurrent = table.count(self.RECORDED_NAVMESH)
	if (iCurrent <= 1) then
		return true end
	
	----------------
	if (not vOldNode) then
		vOldNode = self.RECORDED_NAVMESH[(iCurrent - 1)] end
	
	----------------
	local iElevationDiff = (vOldNode.z - vNode.z)

	----------------
	if (iElevationDiff > iThreshold) then
		return false elseif (iElevationDiff < -iThreshold) then
			return false end
		
	----------------	
	return true
end

-------------------
-- Pathfinding.IsNodesInRadius

Pathfinding.IsNodesInRadius = function(vSource, iDistance, aNodes, iZ)

	----------------
	for i, node in pairs(aNodes) do
		if (vector.distance(node, vSource) < iDistance and (not iZ or vSource.z - node.z < iZ)) then
			return true end end
			
	----------------
	return false
end

-------------------
-- Pathfinding.IsNodesInRadius2D

Pathfinding.IsNodesInRadius2D = function(vSource, iDistance, aNodes)

	----------------
	for i, node in pairs(aNodes) do
		if (vector.distance2d(node, vSource) < iDistance) then
			return true end end
			
	----------------
	return false
end

-------------------
-- Pathfinding.GetNodeInRadius

Pathfinding.GetNodesInRadius = function(vSource, iDistance, aNodes)

	local aInRadius = {}

	----------------
	for i, node in pairs(aNodes) do
		if (vector.distance(node, vSource) < iDistance) then
			table.insert(aInRadius, node) end end
			
	----------------
	return aInRadius
end

-------------------
-- Pathfinding.ExportNavmesh

Pathfinding.ExportNavmesh = function(self, aNodes)

	---------------------
	PathFindLog("Exporting Navmesh")
	
	---------------------
	local aEntities = System.GetEntitiesByClass ("TagPoint") or {}
	
	---------------------
	local sMapName, sMapRules = self.GetMapName()
	local sDir = "Bot\\Core\\Pathfinding\\NavigationData\\Maps"
	os.execute(string.format("if not exist \"%s\" md \"%s\"", sDir, sDir))
	
	local sFileName = string.format("%s\\%s\\%s\\Data.lua", sDir, sMapRules, sMapName)
	local hFile = io.open(sFileName, "w+") --string.openfile(sFileName, "w+")
	hFile:write("-------------------\n")
	hFile:write("--Bot-AutoGenerated\n")
	hFile:write("\n")
	hFile:write("-----------------\n")
	hFile:write("BOT_NAVMESH = {\n")
	
	---------------------
	local iCounter = 1
	
	if (aNodes) then
		for i, node in pairs(aNodes) do
			hFile:write(string.format("\t[%d] = { x = %0.4f, y = %0.4f, z = %0.4f },\n", iCounter, node.x, node.y, node.z))
			iCounter = iCounter + 1
		end
	else
		for i, entity in pairs(aEntities) do
			local sName = entity:GetName()
			if (string.match(entity:GetName(), "BotNavi_Point%d")) then
				PathFindLog(" -> New Point %s", entity:GetName())
				
				local aPos = entity:GetPos()
				hFile:write(string.format("\t[%d] = { x = %0.4f, y = %0.4f, z = %0.4f },\n", iCounter, aPos.x, aPos.y, aPos.z))
				
				iCounter = iCounter + 1
			end
		end
	end
	
	hFile:write("}\n")
	hFile:write("\n")
	hFile:write("---------------\n")
	hFile:write("Pathfinding.NODE_MAX_DIST = 8\n")
	hFile:write("Pathfinding.NODE_MAX_DIST_PANIC = 15\n")
	hFile:write("Pathfinding.NODE_Z_MAX_DIST = 1\n")
	hFile:write("\n")
	hFile:write("------------------\n")
	hFile:write("return BOT_NAVMESH\n")
	hFile:close()
	
	---------------------
	PathFindLog("Exported %d Points to File %s", iCounter, sFileName)
	
	---------------------
	-- self:InitNavmesh(true)
	
	---------------------
	return true
	
end