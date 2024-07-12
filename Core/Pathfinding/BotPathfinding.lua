--=====================================================
-- CopyRight (c) R 2022-2203
--
-- Pathfinding utilities for the CryMP bot project
--
--=====================================================

PathFindLog = function(msg, ...)
	local sFmt = "$9[$8PathFinder$9] $9" .. tostring(msg)
	if (...) then
		sFmt = string.format(sFmt, ...) end

	SystemLog(sFmt)
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
	description = "pathfinding utilities for the bot",

	----------------
	RECORDED_NAVMESH = checkGlobal("Pathfinding.RECORDED_NAVMESH")
}


-------------------
Pathfinding.FAILED_CACHE = {}

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

BOT_NAVMESH = checkGlobal(BOT_NAVMESH, {})
FORCED_LINKS = {}
BAKED_LINKS = {}

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
	local sLibPath = CRYMP_BOT_ROOT .. "\\Core\\Pathfinding"

	---------------------
	local bOk, hLib = BotMain:LoadFile(sLibPath .. "\\BotAStar.lua")
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

		---------------
		{ "init",       		"Pathfinding:Init(true)", 				"Re-initializes the Bot Pathfinding System" },
		{ "reloadfile", 		"Bot:LoadPathfinding()",  				"Reloads the Pathfinding file" },
		{ "test",       		"Pathfinding:Test(%1)",   				"Tests the Pathfinding System" },
		{ "test2",       		"Pathfinding:Test2()",   				"Tests the Pathfinding System" },
		{ "test3",       		"Pathfinding:Test3()",   				"Tests the Pathfinding System" },
		{ "test4",       		"Pathfinding:Test4(%%)",   				"Tests the Pathfinding System" },
		{ "test5",       		"Pathfinding:Test5()",   				"Tests the Pathfinding System" },
		{ "test6",       		"Pathfinding:Test6()",   				"Tests the Pathfinding System" },
		{ "test7",       		"Pathfinding:Test7()",   				"Tests the Pathfinding System" },
		{ "test8",       		"Pathfinding:Test8(%%)",   				"Tests the Pathfinding System" },
		{ "test_live",  		"Pathfinding:LivePathfindingTest(%1)", 	"Tests the Pathfinding System with real time tests" },

		---------------
		{ "paintlinks",			"Pathfinding:PaintLinks(nil,nil,30)",	"Paints all Links of all Nodes of the current Navmesh" },
		{ "paintunlinked",		"Pathfinding:PaintUnlinkedNodes()",		"Shows all nodes that do not have any links" },

		---------------
		{ "livegen",			"Pathfinding:SetLiveNavMeshGen()",		"Toggles Real-Time Navmesh Generation" },

		---------------
		{ "validate_links",		"Pathfinding:ReValidateLinks()",		"Toggles Real-Time Navmesh Generation" },

		---------------
		{ "record_wj",  		"Pathfinding:RecordWJ()",   			"Toggles Realtime-Generating Walljump data" },
		{ "record_wj_del",  	"Pathfinding:DeleteWJ(%%)",   			"Deletes the last inserted Walljump data" },
		{ "record_wj_replay",  	"Pathfinding:ReplayWJ(%%)",   			"Replays specified Walljump Data" },
		{ "record_wj_import", 	"Pathfinding:MergeWJNavmesh()",			"Merges already Generated Navmesh you newly Generated one" },

		---------------
		{ "record",  			"Pathfinding:Record()",   				"Toggles Realtime-Generating Navmesh" },
		{ "record_link",  		"Pathfinding:ForceLinkNodes(%%)",		"Forcefully links 2 Nodes together" },
		{ "record_checklinks",  "Pathfinding:ValidateForcedLinks(%%)",	"Validates all forced links" },
		{ "record_all",  		"Pathfinding:SetRecordAll()",   		"Toggles Recording Positions of all Players" },
		{ "record_clear", 		"Pathfinding:RecordCls()",				"Clears current temporary Navmesh" },
		{ "record_paint", 		"Pathfinding:PaintNavmesh()",			"Paints the Currently Generated Navmesh on the Map" },
		{ "record_unpaint", 	"Pathfinding:RemovePaintedNavmesh()",	"Removes the Painted Navmesh" },
		{ "record_livepaint", 	"Pathfinding:SetAutoPaint()",			"Toggles Real-time Painting of Navmesh" },
		{ "record_import", 		"Pathfinding:MergeNavmesh()",			"Merges already Generated Navmesh you newly Generated one" },
		{ "record_insert", 		"Pathfinding:InsertNode()",				"Insers a New node at your current position" },
		{ "record_remove", 		"Pathfinding:RemoveNodes(%%)",			"Removes all Nodes in X Radius" },
		{ "record_populate",	"Pathfinding:PopulateNodes()",			"Populates all currently generated nodes" },

		---------------
		{ "record_export", 		"Pathfinding:ExportNavmesh(Pathfinding.RECORDED_NAVMESH)", "Exports the newly generated Navmesh" },
		{ "record_wj_export", 	"Pathfinding:ExportWJNavmesh(Pathfinding.RECORDED_WJ_NAVMESH)", "Exports the newly generated Navmesh" },

		---------------
		{ "node_insertdist",	"Pathfinding.RECORD_INSERT_DIST = tonumber(%1)",	"Changes the distance at which new nodes will be inserted" },
		{ "node_insertdistz",	"Pathfinding.RECORD_INSERT_DIST_Z = tonumber(%1)","Changes the Z-distance at which new nodes will be inserted" },
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

Pathfinding.InitNavmesh = function(self, bReload, aNavmesh, aWJNavmesh)

	------------
	PathFindLog("***************************************************")
	PathFindLog("Pathfinding.InitNavmesh()")

	------------
	if (self.NAVMESH_VALIDATED) then
		if (not bReload) then
			return true end end

	------------
	BOT_WJ_NAVMESH = nil
	BOT_NAVMESH = nil
	FORCED_LINKS = {}
	BAKED_LINKS = {}
	AI_ACTION_POINTS = {}
	self.VALIDATION_FUNC = function() end

	------------
	if (not aNavmesh) then
		if (not self:LoadNavmesh()) then
			return false end
	else
		BOT_NAVMESH = aNavmesh
	end

	------------
	if (not aWJNavmesh) then
		if (not self:LoadWJNavmesh()) then
			PathFindLog("Failed to load WallJump Navmesh") end
	else
		BOT_WJ_NAVMESH = aWJNavmesh
	end

	------------
	if (not isArray(BOT_NAVMESH)) then
		return PathFindLog("No Navmesh found!") end

	------------
	if (not isArray(BOT_WJ_NAVMESH)) then
		PathFindLog("No Walljump Navmesh found!") end

	------------
	PathFindLog("Vector Type is %s", vector.type(BOT_NAVMESH[1]))

	------------
	if (not Physics) then
		return false end

	------------
	local fRayCheck_P = Physics.RayTraceCheck
	if (not luautils.isFunction(fRayCheck_P)) then
		PathFindLog("Fatal: Function[1] for validating navmesh not found")
		return false end

	------------
	local fRayCheck_S = Physics.RayTraceCheck
	if (not luautils.isFunction(fRayCheck_S)) then
		PathFindLog("Fatal: Function[2] for validating navmesh not found")
		return false end

	------------
	--Physics.RayWorldIntersection(vSource, vDir, iDistance, fFlags, idIgnore, nil, g_HitTable)
	local fBotRayCheck_R = Game.Bot_RayWorldIntersection
	if (not luautils.isFunction(fBotRayCheck_R)) then
		fBotRayCheck_R = GetDummyFunc() end

	------------
	local fBotRayCheck_C = Game.Bot_RayTraceCheck
	if (not luautils.isFunction(fBotRayCheck_C)) then
		fBotRayCheck_C = GetDummyFunc() end

	------------
	self.VALIDATION_FUNC = function(vSrc, vTgt, iP2, iP3)

		local iDist = vector.distance(vSrc, vTgt)
		local aDir = vector.getdir(vSrc, vTgt, true)

		local vSrc_Back = vector.sub(vector.new(vSrc), aDir)
		local vTgt_Back = vector.add(vector.new(vTgt), aDir)

		local vSrc_BackE = vector.modify(vSrc_Back, "z", 0.5, true)
		local vTgt_BackE = vector.modify(vTgt_Back, "z", 0.5, true)

		local bRHOk = true
		local bHitEntity = false

		--[[
		if (iDist > 1.25) then and System.IsPointIndoors(vSrc)) then
			local iHits = Physics.RayWorldIntersection(vTgt, vector.scale(aDir, iDist), iDist, ent_all - ent_living - ent_rigid, g_localActorId, nil, g_HitTable)
			local aHit = g_HitTable[1]
			bRHOk = ((iHits == 0) and not aHit.entity)
		end
		--]]

		if (iDist > 1.25) then
			local iHits = self:CheckNodeCollisions(vSrc_BackE, vTgt_BackE)
			if (iHits == 0) then
				iHits = self:CheckNodeCollisions(vTgt_BackE, vSrc_BackE)
			end
			bRHOk = ((iHits == 0) and not bHitEntity)
		end

		local bVisible =
			((iDist < 3 and fBotRayCheck_C(vSrc_Back, vTgt_Back, iP2, iP3)) or
			fRayCheck_P(vector.modify(vSrc_Back, "z", 0.15, true), vector.modify(vTgt_Back, "z", 0.15, true), iP2, iP3) or
			fRayCheck_P(vSrc_Back, vector.modify(vTgt_Back, "z", 0.25, true), iP2, iP3) or
			fRayCheck_P(vector.modify(vSrc_Back, "z", 0.25, true), vTgt_Back, iP2, iP3) or
			fRayCheck_P(vector.modify(vSrc_Back, "z", 0.25, true), vector.modify(vTgt_Back, "z", 0.25, true), iP2, iP3)) and
			fRayCheck_P(vSrc_Back, vTgt_Back, iP2, iP3) and
					bRHOk

		return ( bVisible )
	end

	------------
	local hStartTime = timerinit()

	------------
	PathFindLog("Maximum Node Distance: %f (Panic: %f)", self.NODE_MAX_DIST, self.NODE_MAX_DIST_PANIC)

	------------
	PathFindLog("Found %d Forced Links", table.countRec(FORCED_LINKS))

	------------
	local iConnections = 0
	local iNodes = 0
	local aValidatedMesh = {}
	for i, pos in pairs(BOT_NAVMESH) do

		-------------------
		if (not FORCED_LINKS[i]) then
			FORCED_LINKS[i] = {} end

		------------
		iNodes = iNodes + 1

		------------
		local aConnections = self:GenerateLinks(i, self.NODE_MAX_DIST)
		if (table.count(aConnections) == 0) then
			self:Effect(pos)
			aConnections = self:GenerateLinks(i, self.NODE_MAX_DIST_PANIC)
			if (table.count(aConnections) == 0) then
				PathFindLog("$6PANIC: Node %d had no links", i)
			end
		end

		------------
		iConnections = iConnections + table.count(aConnections)
		aValidatedMesh[i] = { id = i, pos = pos, links = aConnections, x = pos.x, y = pos.y, z = pos.z }
	end
	------------
	PathFindLog("Generated %d links %0.4fs", iConnections, timerdiff(hStartTime))

	------------
	local hTimerValidate = timerinit()
	PathFindLog("Validating Links ...")
	self:ValidateLinks(aValidatedMesh)
	PathFindLog("Link Validation took %0.4fs", timerdiff(hTimerValidate))

	------------
	hTimerValidate = timerinit()
	PathFindLog("Refining Links ...")
	self:RefineValidatedLinks(aValidatedMesh)
	PathFindLog("Refined Links in %0.4fs", timerdiff(hTimerValidate))

	------------
	self.VALIDATED_NAVMESH = aValidatedMesh
	self.NAVMESH_VALIDATED = true

	------------
	PathFindLog("Navmesh initialized in %0.4fs (Loops: %d, Nodes: %d, Connections: %d)", timerdiff(hStartTime), (iNodes * iNodes), iNodes, iConnections)

	------------
	if (self.RECORDED_NAVMESH and self.AUTO_PAINT_NAVMESH and self.NAVMESH_AUTO_GENERATE) then
		self:PaintLinks(1) end

	------------
	PathFindLog("***************************************************")
end

---------------------------------------------
-- Pathfinding.LoadNavmesh

Pathfinding.LoadNavmesh = function(self)

	---------------------
	local sRules, sMap = string.match(string.lower(Bot.GetLevelName()), "multiplayer/(.*)/(.*)")

	---------------------
	local sDataPath = string.format("%s\\Core\\Pathfinding\\NavigationData\\Maps\\%s\\%s\\data.lua", CRYMP_BOT_ROOT, sRules, sMap)

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
	bOk, sErr = pcall(hFunc)
	if (not bOk) then
		return false, PathFindLog("Failed to read data.lua")
	end

	---------------------
	if (not BOT_NAVMESH or table.count(BOT_NAVMESH) < 1) then
		return false, PathFindLog("Empty Navmesh file", sMap, sRules)
	end

	---------------------
	if (NAVMESH_FORCED_LINKS and table.count(NAVMESH_FORCED_LINKS) >= 1) then
		FORCED_LINKS = NAVMESH_FORCED_LINKS
	end

	---------------------
	return true
end

---------------------------------------------
-- Pathfinding.LoadWJNavmesh

Pathfinding.LoadWJNavmesh = function(self)

	---------------------
	local sRules, sMap = string.match(string.lower(Bot.GetLevelName()), "multiplayer/(.*)/(.*)")

	---------------------
	local sDataPath = string.format("%s\\Core\\Pathfinding\\NavigationData_WJ\\Maps\\%s\\%s\\data.lua", CRYMP_BOT_ROOT, sRules, sMap)

	---------------------
	PathFindLog("Loading WallJump Data for Map %s\\%s", sRules, sMap)

	---------------------
	if (not fileexists(sDataPath)) then
		return true, PathFindLog("No Data found for Map %s\\%s", sRules, sMap)
	end

	---------------------
	local sData = string.fileread(sDataPath)

	---------------------
	local bOk, hFunc = pcall(loadstring, sData)
	if (not bOk) then
		return false, PathFindLog("Failed to init WallJump Navmesh, Faulty lua file")
	end

	---------------------
	bOk, sErr = pcall(hFunc)
	if (not bOk) then
		return false, PathFindLog("Failed to read data.lua")
	end

	---------------------
	if (not BOT_WJ_NAVMESH or table.count(BOT_WJ_NAVMESH) < 1) then
		return false, PathFindLog("Empty Navmesh file", sMap, sRules)
	end

	---------------------
	PathFindLog("WallJump Navmesh loaded with %d Nodes", table.count(BOT_WJ_NAVMESH))

	---------------------
	return true
end

---------------------------------------------
-- Pathfinding.WriteToFile

Pathfinding.WriteToFile = function(self, hFile, sData)
	hFile:write(sData)
	--hFile:write(crypt.encrypt(sData, "CryMP-Bot", CALG_SCA_255))
end

---------------------------------------------
-- Pathfinding.PaintUnlinkedNodes

Pathfinding.PaintUnlinkedNodes = function(self)

	local aNavmesh = self.VALIDATED_NAVMESH
	for i, aNode in pairs(aNavmesh) do
		local vNode = aNode.pos
		if (table.count(aNode.links) == 0) then
			self:Effect(vNode)
		end
	end
end

---------------------------------------------
-- Pathfinding.RefineValidatedLinks

Pathfinding.RefineValidatedLinks = function(self, aNavmesh)

	----------------
	local iValidated = 0
	local bFixed = false
	local iNodes = 0

	----------------
	for iNode, aNode in pairs(aNavmesh) do

		----------------
		local vNode = aNode.pos
		if (table.count(aNode.links) == 0) then
			bFixed = false
			for iOtherNode, aOtherNode in pairs(aNavmesh) do
				if (iOtherNode ~= iNode) then
					local vPos_A = aNode.pos
					local vPos_B = aOtherNode.pos
					if (self:CheckNodesElevation(vPos_A, vPos_B)) then

						local vDir = vector.getdir(vPos_A, vPos_B, true, -1)
						local vHit = self.GetRayHitPosition(vPos_A, vDir, 9999)

						local bBehind = self:CompareNodes3(vPos_A, vPos_B, vHit)

						local iHitDist = 0
						if (vHit) then
							iHitDist = vector.distance(vHit, vPos_A) end

						if ((iHitDist < 25 and not vHit) or (iHitDist < 25 and bBehind) or (iHitDist < 25 and not vector.compare(vDir, vector.getdir(vPos_B, vHit, true, -1)))) then-- or self:IsNodeBehind(vPos_B, vPos_A, vector.scale(vDir, -1)))) then
							aNavmesh[iNode].links[iOtherNode] = true
							aNavmesh[iOtherNode].links[iNode] = true

							bFixed = true
							iValidated = iValidated + 1
						end
					end
				end
			end
			if (bFixed) then
				iNodes = iNodes + 1 end

		end
	end

	----------------
	if (iValidated > 0) then
		PathFindLog("Refined %d Links of %d Nodes", iValidated, iNodes) end
end

---------------------------------------------
-- Pathfinding.CompareNodes3
-- Checks if either vNodeB or vNodeC is closer to vNodeA

Pathfinding.CompareNodes3 = function(self, vNodeA, vNodeB, vNodeC)

	local i_nDist = vector.distance(vNodeA, vNodeB)
	local i_gDist = vector.distance(vNodeA, vNodeC)

	if (i_nDist < i_gDist) then
		return true end

	return false
end

---------------------------------------------
-- Pathfinding.IsNodeBehind

Pathfinding.IsNodeBehind = function(self, vNodeA, vNodeB, vDirection)
	local product = 0
	+ (vNodeA.x - vNodeB.x) * vDirection.x
	+ (vNodeA.y - vNodeB.y) * vDirection.y
	+ (vNodeA.z - vNodeB.z) * vDirection.z

	return (product > 0.0)
end

---------------------------------------------
-- Pathfinding.ValidateLinks

Pathfinding.ValidateLinks = function(self, aNavmesh)

	----------------
	local iValidated = 0
	local bFixed = false
	local iNodes = 0

	----------------
	for i, aNode in pairs(aNavmesh) do

		----------------
		local vNode = aNode.pos
		if (table.count(aNode.links) > 0) then
			bFixed = false
			for iLink in pairs(aNode.links) do
				local vLink = aNavmesh[iLink].pos
				if (aNavmesh[iLink].links[i] == nil) then
					aNavmesh[iLink].links[i] = true
					iValidated = iValidated + 1
					bFixed = true
				end
			end
			if (bFixed) then
				iNodes = iNodes + 1 end
		end
	end

	----------------
	if (iValidated > 0) then
		PathFindLog("Fixed %d Missing Links of %d Nodes", iValidated, iNodes) end
end

---------------------------------------------
-- Pathfinding.ValidateLinks

Pathfinding.ValidateLinksEx = function(self, aNavmesh)

	----------------
	local iValidated = 0
	local bFixed = false
	local iNodes = 0

	----------------
	local fValidate = self.VALIDATION_FUNC

	----------------
	for i, aNode in pairs(aNavmesh) do

		----------------
		local vNode = vector.modify(aNode.pos, "z", 0.25, true)
		if (table.count(aNode.links) > 0) then
			bFixed = false
			for iLink in pairs(aNode.links) do
				local vLink = vector.modify(aNavmesh[iLink].pos, "z", 0.25, true)

				local bOk = fValidate(vNode, vLink, NULL_ENTITY, NULL_ENTITY)
				if (not bOk) then
					PathFindLog("Found obstacle for link %d for node %d", iLink, i)
					Particle.SpawnEffect("explosions.flare.a", vNode, g_Vectors.up, 0.1)
				else
					--PathFindLog("Link %d from Node %d is OK", iLink, i)
				end

			end
			if (bFixed) then
				iNodes = iNodes + 1 end
		end
	end

	----------------
	if (iValidated > 0) then
		PathFindLog("Fixed %d Missing Links of %d Nodes", iValidated, iNodes) end
end

---------------------------------------------
-- Pathfinding.ValidateLinks

Pathfinding.ReValidateLinks = function(self)

	----------------
	local hStart = timerinit()
	self:ValidateLinks(self.VALIDATED_NAVMESH)
	self:ValidateLinksEx(self.VALIDATED_NAVMESH)
	PathFindLog("Validated links in %0.4fs", timerdiff(hStart))
end

---------------------------------------------
-- Pathfinding.GenerateLinks

Pathfinding.GenerateLinks = function(self, iSource, fMaxDistance)
	-----------------------
	local vSource = BOT_NAVMESH[iSource]

	-----------------------
	local aBaked = self:GetBakedLinks(iSource)
	if (isArray(aBaked)) then
		return aBaked end

	-----------------------
	local fRayCheck = self.VALIDATION_FUNC

	-----------------------
	local aConnections = {}
	for iTarget, vTarget in pairs(BOT_NAVMESH) do

		----------------
		if (iTarget ~= iSource) then

			----------------
			local bForcedLink = (FORCED_LINKS[iSource][iTarget] ~= nil)
			if (bForcedLink or (self:CheckNodesElevation(vSource, vTarget))) then
				local iDistance = vector.distance(vSource, vTarget)
				if (bForcedLink or (iDistance < fMaxDistance)) then
					local bCanSee = bForcedLink or fRayCheck(vector.modify(vSource, "z", 0.25, true), vector.modify(vTarget, "z", 0.25, true), NULL_ENTITY, NULL_ENTITY)
					if (bCanSee) then
						if (bForcedLink or (not self.IsPointIntersectedByWater(vector.validate(vSource), vector.validate(vTarget), self.NAVMESH_WATER_MAX_DEPTH))) then
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

---------------------------
-- GetBakedLinks

Pathfinding.GetBakedLinks = function(self, iSourceNode)

	if (not self.USE_BAKED_PATHNODES) then
		return end

	local sHashedNode = string.hexencode("baked_node_" .. iSourceNode)
	local aBaked = BAKED_LINKS[tonumber(sHashedNode)]
	if (isArray(aBaked)) then
		PathFindLog("Found %d Baked Links for Node %d", table.count(aBaked), iSourceNode)
		return aBaked end

	return
end

---------------------------
-- CheckNodesElevation

Pathfinding.CheckNodesElevation = function(self, vSource, vTarget, iMaxElevation)
	local iMaxElevation = checkNumber(iMaxElevation, self.NODE_Z_MAX_DIST)
	local bReturn = ((vTarget.z - vSource.z < iMaxElevation) and (vTarget.z - vSource.z > -iMaxElevation))
	return bReturn
end

---------------------------
-- GetAIPoint

Pathfinding.GetAIPoint = function(self, sType, fPredicate, vPos, iMaxDistance, bVisible)

	--------------
	local aAIPoints = AI_ACTION_POINTS
	if (not isArray(aAIPoints)) then
		return end

	--------------
	local aTypePoints = self:GetAIPointsOfType(sType)
	if (not isArray(aAIPoints)) then
		return end

	--------------
	local vPos = vPos
	if (not vector.isvector(vPos)) then
		vPos = g_localActor:GetPos() end

	--------------
	local iMaxDistance = checkNumber(iMaxDistance, -1)

	--------------
	local aSelectedPoint = { nil, iMaxDistance }
	for i, hPoint in pairs(aAIPoints) do
		if (fPredicate == nil or (fPredicate(hPoint) == true)) then
			local vPoint = hPoint.vec3
			local iDistance = vector.distance(vPoint, vPos)
			if (iMaxDistance == -1 or (iDistance < aSelectedPoint[2])) then
				if (bVisible ~= true or (self:IsNodeVisibleEx(vPoint))) then
					aSelectedPoint = {
						hPoint,
						iDistance
					}
				end
			end
		end
	end

	--------------
	if (aSelectedPoint[1]) then
		return aSelectedPoint.vec3 end

	--------------
	return true
end

---------------------------
-- GetAIPointsOfType

Pathfinding.GetAIPointsOfType = function(self, sType)

	--------------
	local aAIPoints = AI_ACTION_POINTS
	if (not isArray(aAIPoints)) then
		return end

	--------------
	local aTypePoints = aAIPoints[sType]
	if (not isArray(aTypePoints)) then
		BotNavigation:LogWarning("No AI Points of type %s were found", sType)
		return nil end

	--------------
	return aTypePoints
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
	local vGround = Pathfinding.GetRayHitPosition(vector.modify(vInBetween, "z", 0.25, true), vectors.down, 10)
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
	local aHit = Pathfinding.GetRayHit(vSource, vDirection, iDistance, fFlags, idIgnore)
	if (isArray(aHit)) then
		return (aHit.pos or aHit.position) end

	-------------------
	return nil
end

---------------------------------------------
-- Pathfinding.GetRayHit

Pathfinding.GetRayHit = function(vSource, vDirection, iDistance, fFlags, idIgnore)

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
		return (aHits) end

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
-- Pathfinding.Test3

Pathfinding.Test3 = function(self)

	if (not self.TEST_POS_1) then
		self.TEST_POS_1 = g_localActor:GetPos()
		PathFindLog("Position 1 Set.")
	elseif (not self.TEST_POS_2) then
		self.TEST_POS_2 = g_localActor:GetPos()
		PathFindLog("Position 2 Set.")
	else
		local vDir = vector.getdir(self.TEST_POS_1, self.TEST_POS_2, true)
		PathFindLog("%s", Vec2Str(vDir))
		self.TEST_POS_3 = self.GetRayHitPosition(self.TEST_POS_1, vDir, 666)

		Particle.SpawnEffect("explosions.flare.a", self.TEST_POS_1, vectors.up, 0.1)
		Particle.SpawnEffect("explosions.flare.a", self.TEST_POS_2, vectors.up, 0.1)
		Particle.SpawnEffect("explosions.flare.a", self.TEST_POS_3, vectors.up, 0.1)

		CryAction.PersistantArrow(self.TEST_POS_1, 1, vDir, {1,0,0}, "arrow", 10)

		local bReturn = Game.RayObjectsIntersection(self.TEST_POS_1, self.TEST_POS_2, self.TEST_POS_3, 1)
		PathFindLog("Game.RayObjectsIntersection() returned %s", tostring(bReturn))

		self.TEST_POS_1 = nil
		self.TEST_POS_2 = nil
		self.TEST_POS_3 = nil
	end
end

---------------------------------------------
-- Pathfinding.Test4

Pathfinding.Test4 = function(self, iLogTriggerDist)

	for iSrc, aLinks in pairs(FORCED_LINKS) do
		if (table.count(aLinks) > 0) then
			PathFindLog("** [%d] Links: %d", iSrc, table.count(aLinks))
			for iLink in pairs(aLinks) do
				local iDistance = vector.distance(self.VALIDATED_NAVMESH[iSrc].pos, self.VALIDATED_NAVMESH[iLink].pos)
				if (not isNumber(iLogTriggerDist) or (iLogTriggerDist >= iLogTriggerDist)) then
					PathFindLog("	Link: [%d] -> [%d] Distance: %f", iSrc, iLink, iDistance) end end
		end
	end
end

---------------------------------------------
-- Pathfinding.Test5

Pathfinding.Test5 = function(self)

	local vClosest, iClosest = self:GetClosestPoint(g_localActor:GetPos())
	PathFindLog("Closest Node: %d", checkNumber(iClosest, -1))
end

---------------------------------------------
-- Pathfinding.Test6

Pathfinding.Test6 = function(self)

	local vClosest, iClosest = self:GetClosestPoint(g_localActor:GetPos())
	local aNode = self.VALIDATED_NAVMESH[iClosest]

	PathFindLog("Closest Node: %d", checkNumber(iClosest, -1))
	PathFindLog("		  Links: %d", table.count(aNode.links))
	PathFindLog("		 Forced: %d", table.count(FORCED_LINKS[iClosest]))
	for iLinked, bLinked in pairs(aNode.links) do
		local bVisible = self.VALIDATION_FUNC(vClosest, self.VALIDATED_NAVMESH[iLinked].pos, NULL_ENTITY, NULL_ENTITY)
		--if (not bVisible) then
			self:Effect(self.VALIDATED_NAVMESH[iLinked].pos, 0.1)
		--end
		PathFindLog("		[%d]Visible: %s", iLinked, string.bool(bVisible))
	end
	self:Effect(vClosest)
end

---------------------------------------------
-- Pathfinding.Test7

Pathfinding.Test7 = function(self)

	if (not self.TEST_POS_1) then
		self.TEST_POS_1 = g_localActor:GetPos()
		self.TEST_POS_3 = self:GetClosestPoint(self.TEST_POS_1)
		Particle.SpawnEffect("explosions.flare.a", self.TEST_POS_1, g_Vectors.up, 0.1)
		Particle.SpawnEffect("explosions.flare.a", self.TEST_POS_3, g_Vectors.up, 0.1)
		PathFindLog("Position 1 Set.")
	elseif (not self.TEST_POS_2) then
		self.TEST_POS_2 = g_localActor:GetPos()
		self.TEST_POS_4 = self:GetClosestPoint(self.TEST_POS_2)
		Particle.SpawnEffect("explosions.flare.a", self.TEST_POS_2, g_Vectors.up, 0.1)
		Particle.SpawnEffect("explosions.flare.a", self.TEST_POS_4, g_Vectors.up, 0.1)
		PathFindLog("Position 2 Set.")
	else

		local bOk = self.VALIDATION_FUNC(self.TEST_POS_1, self.TEST_POS_2, NULL_ENTITY, NULL_ENTITY)
		local bOk2 = self.VALIDATION_FUNC(self.TEST_POS_3, self.TEST_POS_4, NULL_ENTITY, NULL_ENTITY)

		--local vDir = vector.getdir(self.TEST_POS_4, self.TEST_POS_3, true, -1)
		--CryAction.PersistantArrow(self.TEST_POS_3, 1, vDir, vDir, "arrow_", 30)

		local iHits = self:CheckNodeCollisions(self.TEST_POS_3, self.TEST_POS_4)
		if (iHits == 0) then
			--iHits = self:CheckNodeCollisions(self.TEST_POS_4, self.TEST_POS_3)
		end

		local bOk3 = (iHits == 0)

		PathFindLog("Test 7: Validate 1 = %s, Validate 2 = %s, Validate 3 = %s", string.bool(bOk), string.bool(bOk2), string.bool(bOk3))

		self.TEST_POS_1 = nil
		self.TEST_POS_2 = nil
	end
end

---------------------------------------------
-- Pathfinding.Test8

Pathfinding.CheckNodeCollisions = function(self, vNode1, vNode2)

	--PathFindLog("vNode 1 = %s, vNode 2 = %s",
	--vector.tostring(vNode1), vector.tostring(vNode2))

	local vDir = vector.getdir(vNode1, vNode2, true, -1)
	local iDistance = math.limit(vector.distance(vNode1, vNode2) + 0.25, 1, BOT_RAYWORLD_MAXDIST)
	local iHits = Physics.RayWorldIntersection(vNode1, vector.scale(vDir, iDistance), iDistance, ent_all - ent_living - ent_rigid, g_localActorId, nil, g_HitTable)

	--CryAction.PersistantArrow(vNode1, 1, vDir, vDir, "arrow_", 30)
	--Particle.SpawnEffect("explosions.flare.a", vNode1, g_Vectors.up, 0.25)

	return (iHits)
end

---------------------------------------------
-- Pathfinding.Test8

Pathfinding.Test8 = function(self, sNode)

	local iNode = tonumber(sNode)
	if (not iNode) then
		return
	end

	PathFindLog("Testing links of Node %d ...", iNode)
	--for i,

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
			 Script.SetTimer(i * 50, function()
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
-- Pathfinding.GetNearestVisibleNode

Pathfinding.GetNearestVisibleNode = function(self, vSource)

	-----------------
	local vClosest, iClosest = self:GetClosestVisiblePoint(vSource)
	if (not vClosest) then
		vClosest, iClosest = self:GetClosestPoint(vSource, nil, self.NODE_MAX_DIST) end

	-----------------
	return vClosest, iClosest
end

---------------------------------------------
-- Pathfinding.GetPath

Pathfinding.GetPath = function(self, vSource, vTarget)

	self.PATHGEN_FAILED = false

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
		vClosest, iClosest = self:GetClosestPoint(vSource, nil, self.NODE_MAX_DIST) end

	-----------------
	if (not vClosest) then
		return nil
	else
		local iDistance = vector.distance(vSource, vClosest)
		if (iDistance > 50 or (iDistance > 20 and not Bot:IsVisible_Points(vSource, vClosest))) then
			self:OnFail(vSource, vTarget)
			self.PATHGEN_FAILED = true
			return nil
		end
	end

	-----------------
	local vGoal, iGoal = self:GetClosestVisiblePoint(vTarget)
	if (not vGoal) then
		vGoal, iGoal = self:GetClosestPoint(vTarget) end

	-----------------
	if (not vGoal) then
		return nil end


	-----------------
	local hStart = timernew()
	local aGoal = self.VALIDATED_NAVMESH[iGoal]
	local aClosest = self.VALIDATED_NAVMESH[iClosest]

	-----------------
	if (not (
		self:IsTargetAvailable(vClosest, vTarget) or
		self:IsTargetAvailable(vTarget, vClosest) or
		self:IsTargetAvailable(vTarget, vSource) or
		self:IsTargetAvailable(vSource, vTarget)
	)) then
		return PathFindLog("[$4Error$9] Targets not connected to each other !!")
	end

	-----------------
	aPath = astar.path(aClosest, aGoal, self.VALIDATED_NAVMESH, true, function(node, neighbor)
		return (node.links[neighbor.id] == true)
	end)

	----------------
	PathFindLog("Generated path with %d Nodes in %0.4fs", table.count(aPath), hStart.diff())

	----------------
	if (not isArray(aPath) or table.count(aPath) < 1) then
		self.PATHGEN_FAILED = true
		self:OnFail(vClosest, aGoal)
		return {} end

	----------------
	local vLast = table.last(aPath)
	PathFindLog("-> %f", vector.distance(vGoal, vTarget))

	if (vector.distance(vGoal, vTarget) > 60 or (vector.distance(vGoal, vTarget) > 20 and not Bot:IsVisible_Points(vLast, aGoal))) then
		self:OnFail(vClosest, vTarget)
	end

	-- !!FIXME
	--local vFirst = table.last(aPath, function(x, y) return (y >= 2)  end)
	--PathFindLog("-> %f", vector.distance(vFirst, vClosest) )
	--if (vector.distance(vFirst, vClosest) > 20 and not Bot:IsVisible_Points(vFirst, vClosest)) then
	--	self:OnFail(vFirst, vClosest)
	--end

	----------------
	table.insertFirst(aPath, vClosest)
	table.insert(aPath, aGoal)

	----------------
	return self.Validate(aPath)

end

---------------------------------------------
-- Pathfinding.OnFail

Pathfinding.OnFail = function(self, vSource, vTarget)
	local sSource = string.format("x%dy%dz%d", vSource.x, vSource.y, vSource.z)
	local sTarget = string.format("x%dy%dz%d", vTarget.x, vTarget.y, vTarget.z)

	self.FAILED_CACHE[sSource] = checkArray(self.FAILED_CACHE[sSource])
	self.FAILED_CACHE[sSource][sTarget] = ((self.FAILED_CACHE[sSource][sTarget] or 0) + 1)

	if (not self:IsTargetAvailable(vSource, vTarget)) then
		PathFindLog("$9[$4Error$9] Target at G(%s) is now no longer available from Source G(%s)", sTarget, sSource)
	end
end

---------------------------------------------
-- Pathfinding.IsTargetAvailable

Pathfinding.IsTargetAvailable = function(self, vSource, vTarget)
	local sSource = string.format("x%dy%dz%d", vSource.x, vSource.y, vSource.z)
	local sTarget = string.format("x%dy%dz%d", vTarget.x, vTarget.y, vTarget.z)

	if (not self.FAILED_CACHE[sSource]) then
		return true
	end

	local iFails = checkNumber(self.FAILED_CACHE[sSource][sTarget], 0)
	return (iFails < 3)
end

---------------------------------------------
-- Pathfinding.IsTargetAvailable

Pathfinding.IsEntityReachable = function(self, hEntity)

	local vPos = g_localActor:GetPos()
	local vEntity = hEntity:GetPos()

	local vClosest, iClosest = self:GetClosestPoint(vPos, nil, self.NODE_MAX_DIST)
	if (not vClosest) then
		return false
	end

	-----------------
	-- Super laggy
	--[[
	local vGoal, iGoal = self:GetClosestVisiblePoint(vEntity)
	if (not vGoal) then
		vGoal, iGoal = self:GetClosestPoint(vEntity) end

	-----------------
	if (not vGoal) then
		return false end
	--]]

	-----------------
	if (not (
			self:IsTargetAvailable(vClosest, vEntity) or
					self:IsTargetAvailable(vEntity, vClosest) or
					self:IsTargetAvailable(vEntity, vPos) or
					self:IsTargetAvailable(vPos, vEntity)
	)) then
		return false
	end

	PathFindLog("ITS OK")
	return true
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
			if ((iDistance < aClosest[3] or aClosest[3] == -1) and (BotNavigation:IsNodeVisible(vSource, true))) then --or self.CanSeeNode(vSource, v.pos))) then
				aClosest = { v.pos, i, iDistance }
			end
		end
	end

	----------------
	return aClosest[1], aClosest[2]
end

---------------------------------------------
-- Pathfinding.GetClosestVisiblePoint

Pathfinding.GetClosestVisiblePoint_OnPath = function(self, vSource, pred)

	local aClosest = { nil, nil, -1 }

	-----------------
	--[[
	for i, v in pairs(BotNavigation.CURRENT_PATH_ARRAY) do
		if (pred == nil or pred(i, vSource, v.pos) == true) then
			local iDistance = vector.distance(v, vSource)
			BotMainLog("node=%d,    iDistance=%f",i,iDistance)
			if ((iDistance < aClosest[3] or aClosest[3] == -1) and (Bot:IsVisible_Points(vSource, v))) then --or self.CanSeeNode(vSource, v.pos))) then
				aClosest = { v, i, iDistance }
			end
		end
	end]]

	local aNodes = BotNavigation.CURRENT_PATH_ARRAY
	local vNode, iDistance
	for i = table.count(aNodes), 1, -1 do
		vNode = aNodes[i]

		iDistance = vector.distance(vNode, vSource)
		if ((iDistance < aClosest[3] or aClosest[3] == -1) and (Bot:IsVisible_Points(vSource, vNode))) then --or self.CanSeeNode(vSource, v.pos))) then
			aClosest = { vNode, i, iDistance }
		end

		--BotMainLog("node=%d,    iDistance=%f",i,iDistance)
	end

	--for i, v in pairs(BotNavigation.CURRENT_PATH_ARRAY) do
	--end

	----------------
	return aClosest[1], aClosest[2]
end

---------------------------------------------
-- Pathfinding.DebugPath

Pathfinding.DebugPath = function(self)

	local aClosest = { nil, nil, -1 }

	-----------------
	for i, v in pairs(BotNavigation.CURRENT_PATH_ARRAY) do
		Script.SetTimer(i*1000, function()
		Bot:SpawnDebugEffect(v, "d"..i, 0.5)
		end)

	end
end

---------------------------------------------
-- Pathfinding.GetClosestPoint

Pathfinding.GetClosestPoint = function(self, vSource, pred, iMaxDistance)

	local aClosest = { nil, nil, (iMaxDistance or -1) }

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

Pathfinding.RemovePaintedNavmesh = function(self, bOnlyInvalid)

	----------------
	local iCounter = 0
	for i, idEntity in pairs(System.GetEntities()) do
		local iNode = string.match(idEntity:GetName(), "BotNavi_Point(%d+)_Painted")
		if (iNode) then
			if (not bOnlyInvalid or (not self.RECORDED_NAVMESH[iNode])) then
				System.RemoveEntity(idEntity.id)
				iCounter = iCounter + 1
			end
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
-- Pathfinding.RemoveNodes

Pathfinding.RemoveNodes = function(self, iRadius)

	----------------
	if (not self.RECORDED_NAVMESH) then
		return false end

	----------------
	if (not self.RECORDED_NAVMESH) then
		self.RECORDED_NAVMESH = {} end

	----------------
	local iRadius = iRadius
	if (not isNumber(iRadius)) then
		iRadius = 1 end

	----------------
	local iNodesRemoved = 0

	----------------
	local vPos = g_localActor:GetPos()
	local iNodes = table.count(self.RECORDED_NAVMESH)
	local iCurrentNode = 1
	local vNode

	----------------
	repeat
		vNode = self.RECORDED_NAVMESH[iCurrentNode]
		if (vNode and vector.distance(vNode, vPos) <= iRadius) then
			for i, v in pairs(FORCED_LINKS) do
				FORCED_LINKS[i][iCurrentNode] = nil
			end
			FORCED_LINKS[iCurrentNode] = nil
			table.remove(self.RECORDED_NAVMESH, iCurrentNode)
			iNodesRemoved = iNodesRemoved + 1
		end
		iCurrentNode = iCurrentNode + 1
	until (not vNode or (iCurrentNode > iNodes))

	----------------
	self:RemovePaintedNavmesh(true)
	self:PaintNavmesh()

	----------------
	PathFindLog("Forcefully removed %d nodes", iNodesRemoved)
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
	local bCanInsert = false

	----------------
	local aMerged = {}

	----------------
	local iMerged = 0
	for i, vNode in pairs(BOT_NAVMESH) do
		iMerged = iMerged + 1
		self.RECORDED_NAVMESH[i] = vNode
	end

	--------------
	-- table.append(self.RECORDED_NAVMESH, aMerged)
	-- for i, vNode in pairs(BOT_NAVMESH) do

		--[[
		----------------
		bCanInsert = true

		----------------
		if (not Pathfinding.IsNodesInRadius(vNode, self.RECORD_INSERT_DIST, self.RECORDED_NAVMESH, 1.5)) then
			bCanInsert = true end

		----------------
		if (not bCanInsert) then
			bCanInsert = not self:CompareNodeZHeight(vNode, aActor.LAST_WORLD_POSITION)
			bCanInsert = bCanInsert and not Pathfinding.IsNodesInRadius(vNode, self.RECORD_INSERT_DIST, self.RECORDED_NAVMESH, 0.15)
		end
		--]]

		-- if (not Pathfinding.IsNodesInRadius(vNode, self.RECORD_INSERT_DIST, self.RECORDED_NAVMESH)) then
			-- table.insert(aMerged, vNode)
			-- iMerged = iMerged + 1
		-- end
	-- end

	--------------
	-- table.append(self.RECORDED_NAVMESH, aMerged)

	----------------
	PathFindLog("Added %d new Nodes to Navmesh", iMerged)
end

-------------------
-- Pathfinding.MergeWJNavmesh

Pathfinding.MergeWJNavmesh = function(self)

	----------------
	if (not self.RECORDED_WJ_NAVMESH) then
		self.RECORDED_WJ_NAVMESH = {} end

	----------------
	if (not BOT_WJ_NAVMESH) then
		return false, PathFindLog("No Data to merge was found") end

	----------------
	local iMerged = table.count(vNode)
	for i, vNode in pairs(BOT_WJ_NAVMESH) do
		table.insert(self.RECORDED_WJ_NAVMESH, vNode)
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
-- Pathfinding.Record

Pathfinding.RecordWJ = function(self)
	if (self.RECORD_WJ_NAVMESH) then
		self.RECORD_WJ_NAVMESH = false
	else
		self.RECORD_WJ_NAVMESH = true
	end

	----------------
	if (not self.RECORDED_WJ_NAVMESH) then
		self.RECORDED_NAVMESH = {} end

	PathFindLog("WJ Navmesh Recording: %s", (self.RECORD_WJ_NAVMESH and "Started" or "Paused"))
end

-------------------
-- Pathfinding.Record

Pathfinding.DeleteWJ = function(self, iDel)

	local aData = self.RECORDED_WJ_NAVMESH
	if (not isArray(aData)) then
		return PathFindLog("No Data found")
	end

	local iRemove = checkNum(tonumber(checkVar(iDel, ".")), table.count(aData))
	table.remove(self.RECORDED_WJ_NAVMESH, iRemove)
	PathFindLog("Removed Walljump %d", iRemove)
end

-------------------
-- Pathfinding.Record

Pathfinding.ReplayWJ = function(self, pIndex)

	local aData = self.RECORDED_WJ_NAVMESH
	if (not isArray(aData)) then
		return PathFindLog("No Data found")
	end

	local iTotal = table.count(aData)
	local iIndex = tonumber(checkVar(pIndex, iTotal))
	if (iIndex > iTotal or iIndex < 1) then
		return PathFindLog("Out of Range! (%d)", iTotal)
	end

	local aNodes = aData[iIndex]
	for i, aNode in pairs(aNodes) do
		Script.SetTimer(i * (System.GetFrameTime() * 1000), function()
			g_localActor:SetPos(aNode[1])
			g_localActor:SetDirectionVector(aNode[2])
		end)
	end
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
-- Pathfinding.ForceLinkNodes

Pathfinding.ForceLinkNodes = function(self, idArg)
	local iNodeA = self.FORCED_LINK_TEMP_A
	local iNodeB = self.FORCED_LINK_TEMP_B
	local vPos = g_localActor:GetPos()
	local vClosest, iClosest = self:GetClosestPoint(vPos)

	if (not iNodeA or (idArg == "r1")) then
		self.FORCED_LINK_TEMP_A = iClosest
		PathFindLog("Node 1 Selected: %d", iClosest)
	elseif (not iNodeB or (idArg == "r2")) then
		if (iNodeA == iClosest) then
			PathFindLog("Please Select a Different Node: %d", iClosest)
		else
			self.FORCED_LINK_TEMP_B = iClosest
			PathFindLog("Node 2 Selected: %d", iClosest)
		end
	else
		if (not FORCED_LINKS[iNodeA]) then
			FORCED_LINKS[iNodeA] = { } end

		if (not FORCED_LINKS[iNodeB]) then
			FORCED_LINKS[iNodeB] = { } end

		FORCED_LINKS[iNodeA][iNodeB] = true
		FORCED_LINKS[iNodeB][iNodeA] = true
		PathFindLog("Forcefully Linked nodes %d and %d", iNodeA, iNodeB)

		self.FORCED_LINK_TEMP_A = nil
		self.FORCED_LINK_TEMP_B = nil
	end

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

Pathfinding.RecordNavmesh = function(self)

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

	----------------
	if (self.AUTO_PAINT_NAVMESH and self.NAVMESH_AUTO_GENERATE) then
		self:PaintLinks() end

end

-------------------
-- Pathfinding.Update

Pathfinding.RecordWJNavmesh = function(self)

	----------------
	if (not self.RECORDED_WJ_NAVMESH) then
		self.RECORDED_WJ_NAVMESH = {} end

	----------------
	self:RecordPlayerWJMovement(g_localActor)

	----------------
	if (self.AUTO_PAINT_NAVMESH and self.NAVMESH_AUTO_GENERATE) then
		self:PaintLinks() end

end

-------------------
-- Pathfinding.Update

Pathfinding.Update = function(self)

	----------------
	if (self.RECORD_NAVMESH) then
		self:RecordNavmesh()
	end

	----------------
	if (self.RECORD_WJ_NAVMESH) then
		self:RecordWJNavmesh()
	end
end

-------------------
-- Pathfinding.Update

Pathfinding.RecordPlayerMovement = function(self, aActor)

	----------------
	if (not Bot:IsAlive(aActor)) then
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
	local bElevationChanged = (not self:CompareNodeZHeight(vPos, aActor.LAST_WORLD_POSITION))
	if (not bCanInsert) then
		bCanInsert = bElevationChanged
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

			local iCurrent = table.count(self.RECORDED_NAVMESH)
			if ((bElevationChanged or self.LAST_NODE_ELEVATION_CHANGED) and iCurrent > 1) then

				local iPrevius = (iCurrent - 1)
				local iDistance = vector.distance(vPos, self.RECORDED_NAVMESH[iPrevius])

				if (((bForceInsert and iDistance < 8) or (iDistance <= self.RECORD_INSERT_DIST))) then
					PathFindLog("Automatically force linked nodes %d and %d", iCurrent, iPrevius)

					if (not FORCED_LINKS[iCurrent]) then
						FORCED_LINKS[iCurrent] = {} end

					if (not FORCED_LINKS[iPrevius]) then
						FORCED_LINKS[iPrevius] = {} end

					FORCED_LINKS[iCurrent][iPrevius] = true
					FORCED_LINKS[iPrevius][iCurrent] = true

					self:Effect(vPos, 1)
					self:Effect(self.RECORDED_NAVMESH[iPrevius], 1)
				else
					PathFindLog("NOT linking, OUT of RANGE ! %f", iDistance)
				end
			end

			if (self.NAVMESH_AUTO_GENERATE) then
				self.InitNavmesh(self, true, self.RECORDED_NAVMESH)
			end

			self.LAST_NODE_ELEVATION_CHANGED = bElevationChanged
		end
	end
	----------------
	if (bForceInsert) then
		self.FORCE_INSERT_NODE = false end

end

-------------------
-- Pathfinding.Update

Pathfinding.OnWallJump = function(self, aActor)
	self.IS_WALL_JUMPING = true
	self.IS_WALL_JUMPING_TIMER = timerinit()
	self.CURRENT_WALLJUMP_NODES = {
		{ Bot:GetPos(), Bot:GetDir() }
	}
end

-------------------
-- Pathfinding.Update

Pathfinding.RecordPlayerWJMovement = function(self, aActor)

	----------------
	if (not Bot:IsAlive(aActor)) then
		return end

	----------------
	local vPos = aActor:GetPos()
	local vDir = aActor.actor:GetHeadDir()
	local aNodes = self.CURRENT_WALLJUMP_NODES

	if (aActor.LAST_WORLD_POSITION) then
		if (self.IS_WALL_JUMPING) then
			if (not aActor.actor:IsFlying() and timerexpired(self.IS_WALL_JUMPING_TIMER, 1)) then

				table.insert(aNodes, { vPos, vDir })
				table.insert(self.RECORDED_WJ_NAVMESH, aNodes)

				self.IS_WALL_JUMPING = false
				self.IS_WALL_JUMPING_TIMER = nil
				self.CURRENT_WALLJUMP_NODES = nil

				NaviLog("New Wall Jump Recorded! Nodes: %d", table.count(aNodes))
			else
				table.insert(aNodes, { vPos, vDir })

				NaviLog("Walljump recording ...")
			end
		end
	end

	----------------
	aActor.LAST_WORLD_POSITION = vPos

end


-------------------
-- PopulateNodes

Pathfinding.PopulateNodes = function(self)

	----------------
	local function posOk(vPos, vParent)

		----------------
		if (not vector.isvector(vPos)) then
			return false end

		----------------
		if (System.IsPointIndoors(vPos)) then
			return false end

		----------------
		local bCanInsert = false
		if (not Pathfinding.IsNodesInRadius(vPos, self.RECORD_INSERT_DIST, self.RECORDED_NAVMESH, 1)) then
			bCanInsert = true end

		----------------
		local bElevationChanged = (not self:CompareNodeZHeight(vPos, vParent))
		if (not bCanInsert) then
			bCanInsert = bElevationChanged
			bCanInsert = bCanInsert and not Pathfinding.IsNodesInRadius(vPos, self.RECORD_INSERT_DIST, self.RECORDED_NAVMESH, 0.15)
		end

		----------------
		return bCanInsert
	end

	----------------
	local iFlags = ent_all - ent_rigid - ent_living

	----------------
	local aNewNavmesh = table.copy(self.RECORDED_NAVMESH)

	----------------
	local iPopulated = 0
	for i, vNode in pairs(self.RECORDED_NAVMESH) do
		local vNode_A = Pathfinding.GetRayHitPosition(vector.addInPlace(vNode, vector.make(2, 0, 1)),  vectors.down, 3, iFlags)
		local vNode_B = Pathfinding.GetRayHitPosition(vector.addInPlace(vNode, vector.make(2, 2, 1)),  vectors.down, 3, iFlags)
		local vNode_C = Pathfinding.GetRayHitPosition(vector.addInPlace(vNode, vector.make(-2, 0, 1)), vectors.down, 3, iFlags)
		local vNode_D = Pathfinding.GetRayHitPosition(vector.addInPlace(vNode, vector.make(0, -2, 1)), vectors.down, 3, iFlags)

		if (posOk(vNode_A, vNode)) then
			self:Effect(vNode_A, 1)
			iPopulated = iPopulated + 1
			table.insert(aNewNavmesh, vNode_A) end

		if (posOk(vNode_B, vNode)) then
			self:Effect(vNode_B, 1)
			iPopulated = iPopulated + 1
			table.insert(aNewNavmesh, vNode_B) end

		if (posOk(vNode_C, vNode)) then
			self:Effect(vNode_C, 1)
			iPopulated = iPopulated + 1
			table.insert(aNewNavmesh, vNode_C) end

		if (posOk(vNode_D, vNode)) then
			self:Effect(vNode_D, 1)
			iPopulated = iPopulated + 1
			table.insert(aNewNavmesh, vNode_D) end
	end

	----------------
	self.RECORDED_NAVMESH = aNewNavmesh
	PathFindLog("Populate %d Nodes", iPopulated)

	----------------
	if (self.AUTO_PAINT_NAVMESH) then
		self:PaintNavmesh()  end

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
	-- PathFindLog(iElevationDiff)
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
-- Pathfinding.Effect

Pathfinding.Effect = function(self, vPos, iScale)
	Particle.SpawnEffect("explosions.flare.a", vPos, vectors.up, checkNumber(iScale, 0.1))
end


---------------------------------------------
-- Pathfinding.ValidateForcedLinks

Pathfinding.ValidateForcedLinks = function(self, iMaxDistance)

	----------------
	local iMaxDistance = checkNumber(iMaxDistance, 10)

	----------------
	local iRemoved = 0
	for iSource, aLinks in pairs(FORCED_LINKS) do
		for iTarget, bLinked in pairs(aLinks) do
			local vSource = self.VALIDATED_NAVMESH[iSource].pos
			local vTarget = self.VALIDATED_NAVMESH[iTarget].pos
			local iDistance = vector.distance(vSource, vTarget)
			if (iDistance >= iMaxDistance) then
				FORCED_LINKS[iSource][iTarget] = nil
				FORCED_LINKS[iTarget][iSource] = nil
				iRemoved = iRemoved + 1
				PathFindLog("Forced Link %d -> %d Removed (Distance: %f)", iSource, iTarget, iDistance)
			end
		end
	end

	----------------
	PathFindLog("Removed %d Invalid Forced Links", iRemoved)

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
	local sDir = CRYMP_BOT_ROOT .. "\\Core\\Pathfinding\\NavigationData\\Maps"

	-- !! FIXME (Delete this shiiiiiiiiaaatthhh)
	os.execute(string.format("@MD \"%s/%s\"", sDir, sMapRules))

	local sFileName = string.format("%s\\%s\\%s\\Data.lua", sDir, sMapRules, sMapName)
	local hFile, sError = io.open(sFileName, "w+") --string.openfile(sFileName, "w+")
	if (not isFile(hFile)) then
		PathFindLog("Failed to open file for writing (%s)", checkString(sError, string.UNKNOWN))
		PathFindLog("\tFile was %s (%s\\%s)", sFileName, sDir, sMapRules)
		return
	end

	self:WriteToFile(hFile, "-------------------\n")
	self:WriteToFile(hFile, "--Bot-AutoGenerated\n")
	self:WriteToFile(hFile, "\n")
	self:WriteToFile(hFile, "-----------------\n")
	self:WriteToFile(hFile, "BOT_NAVMESH = {\n")

	---------------------
	local iCounter = 1

	if (aNodes) then
		for i, node in pairs(aNodes) do
			self:WriteToFile(hFile, string.format("\t[%d] = { x = %0.4f, y = %0.4f, z = %0.4f },\n", iCounter, node.x, node.y, node.z))
			iCounter = iCounter + 1
		end
	else
		for i, entity in pairs(aEntities) do
			local sName = entity:GetName()
			if (string.match(entity:GetName(), "BotNavi_Point%d")) then
				PathFindLog(" -> New Point %s", entity:GetName())

				local aPos = entity:GetPos()
				self:WriteToFile(hFile, string.format("\t[%d] = { x = %0.4f, y = %0.4f, z = %0.4f },\n", iCounter, aPos.x, aPos.y, aPos.z))

				iCounter = iCounter + 1
			end
		end
	end

	self:WriteToFile(hFile, "}\n")
	self:WriteToFile(hFile, "\n")
	self:WriteToFile(hFile, "------------------------\n")
	self:WriteToFile(hFile, "NAVMESH_FORCED_LINKS = {\n")
	for iNode, aLinks in pairs(FORCED_LINKS) do
		if (table.count(aLinks) > 0) then
			self:WriteToFile(hFile, string.format("\t[%d] = {\n", iNode))
			for iLink, hLinked in pairs(aLinks) do
				self:WriteToFile(hFile, string.format("\t\t[%d] = %s,\n", iLink, tostring(hLinked)))
			end
			self:WriteToFile(hFile, "\t},\n")
		end
	end
	self:WriteToFile(hFile, "}\n")
	self:WriteToFile(hFile, "\n")
	self:WriteToFile(hFile, "------------------------\n")
	self:WriteToFile(hFile, "BAKED_LINKS = {\n")
	for iNode, aNode in pairs(self.VALIDATED_NAVMESH) do
		if (table.count(aNode.links) > 0) then
			self:WriteToFile(hFile, string.format("\t[%s] = { ", string.hexencode("baked_node_" .. iNode)))
			for iLink, bLinked in pairs(aNode.links) do
				self:WriteToFile(hFile, string.format("%d, ", iLink))
			end
			self:WriteToFile(hFile, " },\n")
		end
	end
	self:WriteToFile(hFile, "}\n")
	self:WriteToFile(hFile, "\n")
	self:WriteToFile(hFile, "---------------\n")
	self:WriteToFile(hFile, "Pathfinding.NODE_MAX_DIST = 8\n")
	self:WriteToFile(hFile, "Pathfinding.NODE_MAX_DIST_PANIC = 15\n")
	self:WriteToFile(hFile, "Pathfinding.NODE_Z_MAX_DIST = 1\n")
	self:WriteToFile(hFile, "\n")
	self:WriteToFile(hFile, "------------------\n")
	self:WriteToFile(hFile, "return BOT_NAVMESH\n")
	hFile:close()

	---------------------
	PathFindLog("Exported %d Points to File %s", iCounter, sFileName)

	---------------------
	-- self:InitNavmesh(true)

	---------------------
	return true, sFileName

end

-------------------
-- Pathfinding.ExportWJNavmesh

Pathfinding.ExportWJNavmesh = function(self, aNodes)

	---------------------
	PathFindLog("Exporting Walljump Navmesh")

	---------------------
	local sMapName, sMapRules = self.GetMapName()
	local sDir = string.format(CRYMP_BOT_ROOT .. "\\Core\\Pathfinding\\NavigationData_WJ\\Maps\\%s\\%s", sMapRules, sMapName)
	os.execute(string.format("if not exist \"%s\" md \"%s\"", sDir, sDir))

	local sFileName = string.format("%s\\Data.lua", sDir)
	local hFile = io.open(sFileName, "w+") --string.openfile(sFileName, "w+")
	self:WriteToFile(hFile, "-------------------\n")
	self:WriteToFile(hFile, "--Bot-AutoGenerated\n")
	self:WriteToFile(hFile, "\n")
	self:WriteToFile(hFile, "-----------------\n")
	self:WriteToFile(hFile, "BOT_WJ_NAVMESH = {\n")

	---------------------
	local iCounterA = 1
	local iCounterB = 1
	for i, aPath in pairs(aNodes) do
		self:WriteToFile(hFile, string.format("\t[%d] = {\n", i))
		for ii, vNode in pairs(aPath) do
			self:WriteToFile(hFile, string.format("\t\t[%d] = { { x = %0.4f, y = %0.4f, z = %0.4f }, { x = %0.4f, y = %0.4f, z = %0.4f } },\n", ii, vNode[1].x, vNode[1].y, vNode[1].z, vNode[2].x, vNode[2].y, vNode[2].z))
			iCounterA = iCounterA + 1
		end
		self:WriteToFile(hFile, string.format("\t},\n"))
	end

	self:WriteToFile(hFile, "}")
	self:WriteToFile(hFile, "\n")
	self:WriteToFile(hFile, "------------------\n")
	self:WriteToFile(hFile, "return BOT_WJ_NAVMESH\n")
	hFile:close()

	---------------------
	PathFindLog("Exported %d Points to File %s", iCounterA, sFileName)

	---------------------
	-- self:InitNavmesh(true)

	---------------------
	return true, sFileName

end

-------------------
-- Pathfinding.BakeNavmesh

Pathfinding.BakeNavmesh = function(self)

	---------------------
	PathFindLog("Baking Navmesh")

	---------------------
	local bOk, sFile = self:ExportNavmesh(BOT_NAVMESH)

	---------------------
	crypt.encryptfile(sFile)

	---------------------
	return true

end

-- PathFindLog("%s", table.tostring(Physics))
-- PathFindLog("%s", table.tostring(System))
-- PathFindLog("%s", table.tostring(CryAction))

-- PathFindLog("%s", tostring(System.RayTraceCheck(vectors.up, vectors.down, 1, 2)))
-- PathFindLog("%s", tostring(Physics.RayTraceCheck(vectors.up, vectors.down, NULL_ENTITY, NULL_ENTITY)))
-- System.IsPointVisible()
-- CryAction.IsGameObjectProbablyVisible()