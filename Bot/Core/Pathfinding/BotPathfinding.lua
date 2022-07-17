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
Pathfinding.NODE_MAX_DIST = 20
Pathfinding.NODE_MAX_DIST_PANIC = 25
Pathfinding.NODE_Z_MAX_DIST = 1

-------------------
Pathfinding.RECORD_NAVMESH = false
Pathfinding.RECORDED_NAVMESH = {}
Pathfinding.RECORD_INSERT_DIST = 2.5
Pathfinding.RECORD_SKIP_FLYING = true

-------------------
-- Pathfinding.Init

Pathfinding.Init = function(self, bReload)

	---------------------
	PathFindLog("Pathfinding.Init()")
	
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
		{ "init",       		"Pathfinding:Init(true)", 				"Re-initializes the Bot Pathfinding System" },
		{ "reloadfile", 		"Bot:LoadPathfinding()",  				"Reloads the Pathfinding file" },
		{ "test",       		"Pathfinding:Test(%1)",   				"Tests the Pathfinding System" },
		{ "test_live",  		"Pathfinding:LivePathfindingTest(%1)", 	"Tests the Pathfinding System with real time tests" },
		{ "record",  			"Pathfinding:Record()",   				"Toggles Realtime-Generating Navmesh" },
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

Pathfinding.InitNavmesh = function(self, bReload)
	
	PathFindLog("Pathfinding.InitNavmesh()")
	
	---------------------
	if (self.NAVMESH_VALIDATED) then
		if (not bReload) then
			return true end end
		
	---------------------
	BOT_NAVMESH = nil
		
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
	if (not BOT_NAVMESH or table.count(BOT_NAVMESH) < 1) then
		return true, PathFindLog("Empty Navmesh file", sMap, sRules)
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
		for i, node in pairs(aPath) do
			 Script.SetTimer(i * 500, function()
				 PathFindLog("Node %d pos %s", i, Vec2Str(node))
				Particle.SpawnEffect("explosions.flare.a", node, g_Vectors.up, 0.1)
				g_localActor:SetPos(node)
			end)
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
-- Pathfinding.RecordCls

Pathfinding.RecordCls = function(self)

	----------------
	local iNodes = table.count(self.RECORDED_NAVMESH or {})
	PathFindLog("Flushed %d Nodes", iNodes)
	
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
	local vPos = vector.modify(g_localActor:GetPos(), "z", 0.1, true)
	local bCanInsert = (not Pathfinding.IsNodesInRadius(vPos, self.RECORD_INSERT_DIST, self.RECORDED_NAVMESH, 1.5))
	if (bCanInsert or self.FORCE_INSERT_NODE) then
		if (not g_localActor.actor:IsFlying() or not self.RECORD_SKIP_FLYING) then
			table.insert(self.RECORDED_NAVMESH, vPos)
			PathFindLog("New Node %d Inserted: %s", table.count(self.RECORDED_NAVMESH), Vec2Str(vPos))
			if (self.AUTO_PAINT_NAVMESH) then
				self:PaintNavmesh() end
		end
	end
	
	----------------
	self.FORCE_INSERT_NODE = false
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
	local sDir = "Bot\\Core\\Pathfinding\\\NavigationData\\Maps"
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