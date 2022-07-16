--=====================================================
-- CopyRight (c) R 2022-2203
--
-- Random (sometimes) useful table utils for lua
--
--=====================================================

PathFindLog = function(msg, ...)
	local sFmt = "[PathFinder] " .. tostring(msg)
	if (...) then
		sFmt = string.format(sFmt, ...) end
		
	System.LogAlways(sFmt)
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
Pathfinding.NODE_MAX_DIST = 20
Pathfinding.NODE_MAX_DIST_PANIC = 25
Pathfinding.NODE_Z_MAX_DIST = 1

-------------------
-- Pathfinding.Init

Pathfinding.Init = function(self, bReload)

	---------------------
	PathFindLog("Pathfinding.Init()")
	
	---------------------
	if (not self.InitAStar()) then
		return false end
	
	---------------------
	if (not self.InitCVars()) then
		return false end
	
	---------------------
	if (not self:InitNavmesh()) then
		return false end
end

-------------------
-- Pathfinding.InitAStar

Pathfinding.InitAStar = function()

	---------------------
	BotLog("Loading AStar Library")
	
	---------------------
	local sLibPath = "Bot\\Core\\Pathfinding"
	
	---------------------
	local bOk, hLib = FinchPower:LoadFile(sLibPath .. "\\BotAStar.lua")
	if (not bOk) then
		return false end
			
	---------------------
	BotLog("AStar Library loaded")
			
	---------------------
	return true
end

-------------------
-- Pathfinding.InitCVars

Pathfinding.InitCVars = function()

	---------------------
	local sPrefix = "pathfinding_"
	local aCVars = {
		{ "init",       "Pathfinding:Init(true)", "Re-initializes the Bot Pathfinding System" },
		{ "reloadfile", "Bot:LoadPathfinding()",  "Reloads the Pathfinding file" },
		{ "test",       "Pathfinding:Test(%1)",   "Tests the Pathfinding System" },
		{ "test_live",  "Pathfinding:LivePathfindingTest(%1)", "Tests the Pathfinding System with real time tests" }
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

Pathfinding.InitNavmesh = function(self)
	
	PathFindLog("Pathfinding.InitNavmesh()")
	
	---------------------
	if (self.NAVMESH_VALIDATED) then
		if (not bReload) then
			return true end end
		
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
		return true, PathFindLog("Failed to init Navmesh, Faulty data.lua")
	end
	
	---------------------
	local bOk, sErr = pcall(hFunc)
	if (not bOk) then
		return true, PathFindLog("Failed to read data.lua")
	end
	
	---------------------
	if (not BOT_NAVMEHS or table.count(BOT_NAVMEHS) < 1) then
		return true, PathFindLog("Empty Navmesh file", sMap, sRules)
	end
	
	---------------------
	PathFindLog("Vector Type is %s", vector.type(BOT_NAVMEHS[1]))
	
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
	local iConnections = 0
	local iNodes = 0
	local aValidatedMesh = {}
	for i, pos in pairs(BOT_NAVMEHS) do
	
		-- Script.SetTimer(i * 50, function()
			-- Particle.SpawnEffect("explosions.flare.a", pos, g_Vectors.up, 0.1)
		-- end)
	
		-------------------
		iNodes = iNodes + 1
	
		-------------------
		local aConnections = self:GenerateLinks(i, self.NODE_MAX_DIST)
		if (table.count(aConnections) == 0) then
			PathFindLog("PANIC: Node %d had no links. retrying with panic distance", i)
			aConnections = self:GenerateLinks(i, self.NODE_MAX_DIST_PANIC)
		end
		
		-------------------
		iConnections = iConnections + table.count(aConnections)
				
		-------------------
		aValidatedMesh[i] = { id = i, pos = pos, links = aConnections, x = pos.x, y = pos.y, z = pos.z }
	end
	
	---------------------
	self.VALIDATED_NAVMESH = aValidatedMesh
	
	---------------------
	self.NAVMESH_VALIDATED = true
	
	---------------------
	PathFindLog("Navmesh initialized in %0.4fs (Loops: %d, Nodes: %d, Connections: %d)", (os.clock() - iStartTime), (iNodes * iNodes), iNodes, iConnections)
	
end

---------------------------------------------
-- Pathfinding.GenerateLinks

Pathfinding.GenerateLinks = function(self, iSource, fMaxDistance)
	-----------------------
	local vSource = BOT_NAVMEHS[iSource]
	
	-----------------------
	local fRayCheck = self.VALIDATION_FUNC
	
	-----------------------
	local aConnections = {}
	for iTarget, vTarget in pairs(BOT_NAVMEHS) do
		if (iTarget ~= iSource) then
			if ((vTarget.z - vSource.z < self.NODE_Z_MAX_DIST) and (vTarget.z - vSource.z > -self.NODE_Z_MAX_DIST)) then
				local iDistance = vector.distance(vSource, vTarget)
				if (iDistance < fMaxDistance) then
					local bCanSee = fRayCheck(vector.modify(vSource, "z", 0.25, true), vector.modify(vTarget, "z", 0.25, true), NULL_ENTITY, NULL_ENTITY)
					if (bCanSee) then
						aConnections[iTarget] = true
					end
				end
			end
		end
	end
	
	-----------------------
	return aConnections
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
		vEnd = random(System.GetEntitiesByClass(idClassOrEntity or "SpawnPoint")):GetPos()
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
	for i, node in pairs(aPath) do
		-- Script.SetTimer(i * 500, function()
			-- PathFindLog("Node %d pos %s", i, Vec2Str(node))
			-- Particle.SpawnEffect("explosions.flare.a", node, g_Vectors.up, 0.1)
			-- g_localActor:SetPos(node)
		-- end)
	end
	---------------------
end

---------------------------------------------
-- Pathfinding.GetPath

Pathfinding.GetPath = function(self, vSource, vTarget)
	
	-----------------
	local aPath = { vSource, vTarget }
	
	-----------------
	if (self.VALIDATION_FUNC(vSource, vTarget, NULL_ENTITY, NULL_ENTITY) == true) then
		PathFindLog("vStart and vTarget are connected!")
		return aPath
	end
	
	-----------------
	local vClosest, iClosest = self:GetClosestPoint(vSource)
	if (not vClosest) then
		return { } end
		
	local aClosest = self.VALIDATED_NAVMESH[iClosest]
	
	-----------------
	local vGoal, iGoal = self:GetClosestPoint(vTarget)
	if (not vGoal) then
		return { } end
		
	local aGoal = self.VALIDATED_NAVMESH[iGoal]
	
	-----------------
	aPath = astar.path(aClosest, aGoal, self.VALIDATED_NAVMESH, false, function(node, neighbor)
		return node.links[neighbor.id] == true
	end)
	
	----------------
	if (not isArray(aPath) or table.count(aPath) < 1) then
		return {} end
	
	----------------
	return aPath
	
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
	return sMap
end

-------------------
-- Pathfinding.PainNavmesh

Pathfinding.PaintNavmesh = function()
end

-------------------
-- Pathfinding.ExportNavmehs

Pathfinding.ExportNavmehs = function(self)

	---------------------
	PathFindLog("Exporting Navmesh")
	
	---------------------
	local aEntities = System.GetEntitiesByClass ("TagPoint") or {}
	
	---------------------
	local sMapName = self.GetMapName()
	local sFileName = string.format("ExportedNavmehs - %s", sMapName)
	local hFile = openfile(sFileName, "w+")
	hFile:write("BOT_NAVMEHS = {\n")
	
	---------------------
	local iCounter = 1
	for i, entity in pairs(aEntities) do
		local sName = entity:GetName()
		if (string.match(entity:GetName(), "BotNavi_Point%d")) then
			PathFindLog(" -> New Point %s", entity:GetName())
			
			local aPos = entity:GetPos()
			hFile:write(string.format("\t[%d] = { x = %0.4f, y = %0.4f, z = %0.4f }\n", iCounter, aPos.x, aPos.y, aPos.z))
			
			iCounter = iCounter + 1
		end
	end
	
	hFile:write("}\n")
	hFile:close()
	
	---------------------
	PathFindLog("Exported %d Points to File %s", iCounter, sFileName)
	
	---------------------
	return true
	
end