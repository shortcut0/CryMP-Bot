----------------------------------------
-- PowerStruggle AI Module

BotAI:CreateAIModule("PowerStruggle", {

	----------
	BUY_ERROR = {},
	BUILDINGS = {},
	CURRENT_TEAM = 0,
	
	----------
	ModuleFullName = nil,
	ModuleName = nil,

	----------
	Funcs = {
	
		------------------------------
		-- ResetPath
		ResetPath = nil,
		
		------------------------------
		-- ResetPathData
		ResetPathData = nil,
		
	},

	----------
	Events = {
	
		------------------------------
		-- OnInit
		OnInit = function(self)
			self:AILog(0, "%s.Events.OnInit()", self.ModuleFullName)
			
			self:Init()
		end,
	
		------------------------------
		-- OnTimer
		OnTimer = function(self, iFrameTime)
			self:AILog(0, "%s.Events.OnTimer(%f)", self.ModuleFullName, iFrameTime)
			
			----------------
			self:OnTimer(iFrameTime)
		end,
	
		------------------------------
		-- GetPathGoal
		
		GetPathGoal = function(self, hRandomEntity)
			self:AILog(0, "%s.Events.GetPathGoal()", self.ModuleFullName)
			
			return self:GetAttentionPoint()
		end,
	
		------------------------------
		-- IsTargetOk
		IsTargetOk = function(self, hTarget, iDistance)
			-- self:AILog(0, "%s.Events.IsTargetOk(%f)", self.ModuleFullName, iDistance)
			
			if (self:CompareTeams(hTarget, g_localActor)) then
				return false end
			
			if ((iDistance < 50) and (not self:IsCapturing() or self:IsInCaptureRadius(self.CURRENT_ATTENTION_TARGET, hTarget))) then
				return true end
			
			if (Bot.LAST_SEEN_MOVING) then
				return false end
			
			if (Bot.LAST_SEEN_ENTITYID and Bot.LAST_SEEN_ENTITYID ~= hTarget.id) then
				return false end
			
			if (not Bot:IsEntityTagged(hTarget.id)) then
				self:AILog(5, "NOT GOING TO TARGET %s (THEY ARE NOT ON OUR RADAR !!)", hTarget:GetName())
				return false end
				
			return false
		end,
	
		------------------------------
		-- ShouldDropItem
		ShouldDropItem = function(self, hWeapon)
			self:AILog(0, "%s.Events.ShouldDropItem(%s)", self.ModuleFullName, hWeapon.class)
			
			return true
		end,
	
		------------------------------
		-- OnRadioMessage
		OnRadioMessage = function(self, hActor, iMessage)
			self:AILog(0, "%s.Events.OnRadioMessage(%s, %d)", self.ModuleFullName, hActor:GetName(), iMessage)

			----------------
			if (not self.RADIO_TIMERS) then
				self.RADIO_TIMERS = {} end
				
			----------------
			local vPos = g_localActor:GetPos()
			local vActorPos = hActor:GetPos()
				
			----------------
			local iDistance = vector.distance(vPos, vActorPos)
				
			----------------
			if (hActor.id ~= g_localActorId) then
				self.RADIO_TIMERS[iMessage] = timerinit() 
				
				local iResponse
				if (iMessage == RADIO_TAKE_AIRFAC) then
					iResponse = RADIO_YES
					if (not self:GetUncapturedBuilding("air", vPos, 9999)) then
						iResponse = RADIO_NO end
						
				elseif (iMessage == RADIO_TAKE_ENERGY) then
					iResponse = RADIO_YES
					if (not self:GetUncapturedBuilding("alien", vPos, 9999)) then
						iResponse = RADIO_NO end
						
				elseif (iMessage == RADIO_TAKE_PROTO) then
					iResponse = RADIO_YES
					if (not self:GetUncapturedBuilding("prototype", vPos, 9999)) then
						iResponse = RADIO_NO end
						
				elseif (iMessage == RADIO_TAKE_WARFAC) then
					iResponse = RADIO_YES
					if (not self:GetUncapturedBuilding("war", vPos, 9999)) then
						iResponse = RADIO_NO end
						
				elseif (iMessage == RADIO_NEED_HELP) then
					if (iDistance < 60) then
						iResponse = RADIO_YES end
				end
					
				if (iResponse) then
					self:SendRadio(iResponse) end
			end
				
			----------------
			return true
		end,
	
		------------------------------
		-- CanPlaceExplosive
		CanPlaceExplosive = function(self, hSpawn, vSpawn)
			self:AILog(0, "%s.Events.CanPlaceExplosive(%s, %s)", self.ModuleFullName, hSpawn:GetName(), Vec2Str(vSpawn))
			
			return true
		end,
	
		------------------------------
		-- OnEntityTagged
		OnEntityTagged = function(self, hEntity)
			self:AILog(0, "%s.Events.OnEntityTagged(%s)", self.ModuleFullName, hEntity:GetName())
			self:SendRadio(RADIO_ENEMY_SPOTTED)
			return true
		end,
	},
	
	------------------------------
	-- OnTimer
		
	OnTimer = function(self, iFrameTime)
		self:AILog(0, "%s.OnTimer()", self.ModuleFullName)
			
		----------------
		self.CURRENT_TEAM = g_gameRules.game:GetTeam(g_localActorId)
			
		----------------
		if (not self:CheckTeam()) then
			return end
			
		----------------
		if (self:InBuyZone()) then
			self:CheckEquipment() end
			
		----------------
		self:AILog(0, "SELECTED RANDOM: %s", self:GetRandomBuilding(self.CURRENT_ATTENTION_TARGET):GetName())
			
		----------------
		local hTargetEntity = self:GetAttentionPoint()
		if (hTargetEntity) then
			local hClosestSpawnGroup = self:GetClosestSpawnGroup(hTargetEntity:GetPos())
			if (hClosestSpawnGroup) then
				g_gameRules.server:RequestSpawnGroup(g_localActorId, hClosestSpawnGroup.id)
			end
		end
		
	end,
	
	------------------------------
	-- AILog
	
	AILog = function(self, iVerbosity, ...)
		if (isNumber(iVerbosity)) then
			if (iVerbosity <= BOTAI_LOGGING_VERBOSITY) then
				return AILog(...) end
		else
			return AILog(iVerbosity, ...) end
	end,
	
	
	------------------------------
	-- AILogWarning
	
	AILogWarning = function(self, iVerbosity, ...)
		if (isNumber(iVerbosity)) then
			if (iVerbosity <= BOTAI_LOGGING_VERBOSITY) then
				return AILog(...) end
		else
			return AILogWarning(iVerbosity, ...) end
	end,
	
	------------------------------
	-- AILogError
	
	AILogError = function(self, iVerbosity, ...)
		if (isNumber(iVerbosity)) then
			if (iVerbosity <= BOTAI_LOGGING_VERBOSITY) then
				return AILog(...) end
		else
			return AILogError(iVerbosity, ...) end
	end,
	
	------------------------------
	-- SendRadio
		
	SendRadio = function(self, iRadio)
		self:AILog(0, "%s.iRadio()", self.ModuleFullName)
			
		----------------
		if (not isNumber(iRadio)) then
			self:AILog("Invalid RadioID specified to SendRadio()") end
			
		----------------
		if (not self.RADIO_TIMERS) then
			self.RADIO_TIMERS = {} end
			
		----------------
		if (not timerexpired(self.RADIO_TIMERS[iRadio], 30)) then
			return end
			
		----------------
		local iExpire = 30
		if (iRadio == self.LAST_RADIO_ID) then
			self.RADIO_EXPIRE_TIME = checkNumber(self.RADIO_EXPIRE_TIME, getrandom(60, 120))
			iExpire = self.RADIO_EXPIRE_TIME end
		
		if (not timerexpired(self.LAST_RADIO_TIMER, iExpire)) then
			return end
			
		----------------
		self.LAST_RADIO_TIMER = timerinit()
		self.LAST_RADIO_ID = iRadio
		return (Bot:SendRadioMessage(iRadio))
	end,
	
	------------------------------
	-- InBuyZone
		
	InBuyZone = function(self)
		self:AILog(0, "%s.InBuyZone()", self.ModuleFullName)
			
		----------------
		return (not isNull(self.INSIDE_BUY_ZONE))
	end,
	
	------------------------------
	-- CheckTeam
		
	CheckTeam = function(self)
		self:AILog(0, "%s.CheckTeam()", self.ModuleFullName)
			
		----------------
		if (self.CURRENT_TEAM == TEAM_NEUTRAL) then
			self:ChangeTeam(TEAM_WEAKEST)
			return false end
		
		----------------
		return true
	end,
	
	------------------------------
	-- ChangeTeam
		
	ChangeTeam = function(self, iTeam)
		self:AILog(0, "%s.ChangeTeam()", self.ModuleFullName)
			
		----------------
		if (not iTeam) then
			self:AILog(0, "No team specified to .ChangeTeam()")
			return end
		
		----------------
		if (iTeam == TEAM_WEAKEST) then
			iTeam = self:GetWeakestTeam() elseif (iTeam == TEAM_RANDOM) then
				iTeam = self:GetRandomTeam() end
			
		----------------
		if (iTeam < 0 or iTeam > 2) then
			self:AILogWarning(0, "Invalid team specified to .ChangeTeam(%d)", iTeam)
			return end
			
		----------------
		local sTeam = "black"
		if (iTeam == 1) then
			sTeam = "tan" end
			
		----------------
		System.ExecuteCommand(string.format("team %s", sTeam))
		
	end,
	
	------------------------------
	-- GetWeakestTeam
		
	GetWeakestTeam = function(self)
		self:AILog(0, "%s.GetWeakestTeam()", self.ModuleFullName)
			
		----------------
		local aPlayers = GetPlayers()
		
		----------------
		local iNK = 0
		local iUS = 0
		
		----------------
		for i, hPlayer in pairs(aPlayers) do
			local iTeam = g_gameRules.game:GetTeam(hPlayer.id)
			if (iTeam == TEAM_NK) then
				iNK = iNK + 1 elseif (iTeam == TEAM_US) then
					iUS = iUS + 1 end
		end
		
		----------------
		if (iNK > iUS) then
			return TEAM_US end
			
		----------------
		return TEAM_NK
	end,
	
	------------------------------
	-- GetRandomTeam
		
	GetRandomTeam = function(self)
		self:AILog(0, "%s.GetRandomTeam()", self.ModuleFullName)
			
		----------------
		return getrandom(1, 2)
	end,
	
	------------------------------
	-- GetClosestSpawnGroup
		
	GetClosestSpawnGroup = function(self, vPos)
		self:AILog(0, "%s.GetClosestSpawnGroup()", self.ModuleFullName)
			
		----------------
		local iMyTeam = g_gameRules.game:GetTeam(g_localActor.id)
			
		----------------
		local aSpawnGroups = self:GetBuildingsOfType("spawn")
			
		----------------
		local vPos = checkVar(vPos, g_localActor:GetPos())
			
		----------------
		local aBestSpawn = { nil, -1 }
		for i, hSpawn in pairs(aSpawnGroups) do
			if (self:CompareTeams(hSpawn, g_localActor)) then
				local iDistance = vector.distance(hSpawn:GetPos(), vPos)
				if (aBestSpawn[2] == -1 or (iDistance < aBestSpawn[2])) then
					aBestSpawn = {
						hSpawn,
						iDistance
					}
				end
			end
		end
			
		----------------
		if (aBestSpawn[1]) then
			return aBestSpawn[1] end
			
		----------------
		self:GetSpawnBase()
		
		----------------
		return self.SPAWN_BASE --g_gameRules.game:GetTeamDefaultSpawnGroup(self.CURRENT_TEAM)
		
	end,
	
	-----------------
	CompareTeams = function(self, idEntity_A, idEntity_B)
		self:AILog(5, "%s.CompareTeams()", self.ModuleFullName)
		
		----------------
		local hEntity_A = GetEntity(idEntity_A)
		if (not hEntity_A) then
			return false end
		
		----------------
		local hEntity_B = GetEntity(idEntity_B)
		if (not hEntity_B) then
			return false end
		
		----------------
		return (g_gameRules.game:GetTeam(hEntity_A.id) == g_gameRules.game:GetTeam(hEntity_B.id))
	end,
	
	-----------------
	Init = function(self)
		self:AILog(0, "%s.Init()", self.ModuleFullName)
		
		----------------
		TEAM_NEUTRAL = 0
		TEAM_NK = 1
		TEAM_US = 2
		TEAM_WEAKEST = 3
		TEAM_RANDOM = 4
		
		----------------
		RADIO_YES = 0
		RADIO_NO = 1
		RADIO_WAIT = 2
		RADIO_FOLLOW = 3
		RADIO_THANKS = 4
		
		------
		RADIO_ATTACKBASE = 5
		RADIO_TAKE_ENERGY = 6
		RADIO_TAKE_PROTO = 7
		RADIO_TAKE_WARFAC = 8
		RADIO_TAKE_AIRFAC = 9
		
		------
		RADIO_TANK_SPOTTED = 10
		RADIO_AIRCRAFT_SPOTTED = 11
		RADIO_BOAT_SPOTTED = 12
		RADIO_VEHICLE_SPOTTED = 13
		RADIO_INFANTRY_SPOTTED = 14
		
		------
		RADIO_NEED_HELP = 15
		RADIO_GET_IN = 16
		RADIO_GET_OUT = 17
		RADIO_NEED_REPAIR = 18
		RADIO_NEED_SCAN = 19
		
		----------------
		self:CollectBuildings()
		self:PatchGameRules()
	end,
	
	-----------------
	PatchGameRules = function(self)
		self:AILog(0, "%s.PatchGameRules()", self.ModuleFullName)
		
		----------------
		local AIModule = self
		
		----------------
		g_gameRules.Client.ClEnterCaptureArea = function(self, idBuilding, bEnter)
			AIModule:OnEnterCaptureArea(idBuilding, bEnter)
			if (entered) then
				self.capturingId = buildingId else
					self.capturingId = nil end
			self:UpdateCaptureProgress(buildingId)
		end
		
		----------------
		g_gameRules.Client.ClEnterBuyZone = function(self, idZone, bEnter)
			AIModule:OnEnterBuyZone(idZone, bEnter)
			
			if (not isNull(HUD)) then
				HUD.EnteredBuyZone(idZone, bEnter)
				HUD.UpdateBuyList() end
		end
		
		----------------
		g_gameRules.Client.OnContested = function(self, hBuilding, bContested)
			AIModule:SetContested(hBuilding, bContested)
			AIModule:AILog(0, "NOW CONTESTED!")
		end
		
		----------------
		g_gameRules.Client.ClBuyError = function(self, sItem)
			AIModule.BUY_ERROR[sItem] = timerinit()
			AIModule:AILog(0, "ERROR BUYING %s", sItem)
		end
		
		----------------
		g_gameRules.Client.OnCapture = function(self, hBuilding, teamId)
		
			local idBuilding = hBuilding.id

			AIModule:OnCaptured(hBuilding, idBuilding, teamId)
		
			self.contested[idBuilding] = nil
			self.capturing[idBuilding] = nil
			self.captureProgress[idBuilding] = 1
			self:UpdateCaptureProgress(idBuilding)
			
			-- if (not g_localActorId) then 
				-- return end
				
			-- local ownTeamId = self.game:GetTeam(g_localActorId)
			-- if (teamId == ownTeamId) then
				-- local name, locName, locFactoryName=self:GetAlertBuildingName(hBuilding)
				-- self:PlayRadioAlertCoord(name.."_captured", ownTeamId, hBuilding)
				-- self:BLAlert(eBLE_Information, "@mp_BL"..locName.."Captured", hBuilding, locFactoryName)
				
			-- else
				-- local name, locName, locFactoryName=self:GetAlertBuildingName(building)
				-- self:PlayRadioAlertCoord(name.."_enemycaptured", ownTeamId, building)
				-- self:BLAlert(eBLE_Warning, "@mp_BLEnemyCaptured"..locName, building, locFactoryName)
			-- end
		end
	end,
	
	-----------------
	CollectBuildings = function(self)
		
		---------
		self.BUILDINGS = {}
		
		---------
		local aFactories = GetEntities("Factory")
		if (table.count(aFactories) == 0) then
			return self:AILogWarning(0, "No Factories found on this Map!") end
		
		---------
		local aSpawns = GetEntities("SpawnGroup")
		if (table.count(aSpawns) == 0) then
			return self:AILogWarning(0, "No Spawns found on this Map!") end
		
		---------
		local aAlienPoints = GetEntities("AlienEnergyPoint")
		if (table.count(aAlienPoints) == 0) then
			return self:AILogWarning(0, "No Alien Energy Points found on this Map!") end
		
		---------
		local iBuildings = 0
		for i, hEntity in pairs(table.append(aFactories, aSpawns, aAlienPoints)) do
			self:AILog(0, "%s->%s", hEntity:GetName(), hEntity.Properties.teamName)
			if (hEntity.Properties.teamName == "") then
			
				----------
				local sBuildingType = (hEntity.Properties.szName or "")
				if (hEntity.class == "AlienEnergyPoint") then
					sBuildingType = "alien" elseif (hEntity.class == "SpawnGroup") then
						sBuildingType = "spawn" end
				
				----------
				self:AILog(0, "	szName: %s (%s)", (hEntity.Properties.szName or ""), sBuildingType)
				
				----------
				sBuildingType = string.lower(sBuildingType)
				hEntity.BUILDING_TYPE = sBuildingType
				
				----------
				if (not self.BUILDINGS[sBuildingType]) then
					self.BUILDINGS[sBuildingType] = {} end
					
				----------
				iBuildings = iBuildings + 1
					
				----------
				table.insert(self.BUILDINGS[sBuildingType], hEntity)
			end
		end
		
		---------
		self:GetSpawnBase()
		
		---------
		self:AILog(0, "Found %d Buildings", iBuildings)
	end,
	
	-----------------
	GetSpawnBase = function(self)
		
		---------
		self.SPAWN_BASE = nil
		
		---------
		for i, hSpawn in pairs(GetEntities("SpawnGroup")) do
			if (hSpawn.Properties.teamName ~= "") then
				if (self:CompareTeams(hSpawn, g_localActor)) then
					self.SPAWN_BASE = hSpawn
				end
			end
		end
	end,
	
	-----------------
	GetAttentionPoint = function(self)
		self:AILog(0, "%s.GetAttentionPoint()", self.ModuleFullName)
		
		local hTarget = self:PostGetAttentionPoint()
		if (hTarget) then
			if (hTarget == 0xBEEF) then
				self:AILog(0, "Got 0xBEEF as attention target!")
				if (Bot:OkToProne()) then
					Bot:StartProne()
				else
					Bot:StopProne()
				end
				return
			end
			self.CURRENT_ATTENTION_TARGET = hTarget
		else
			self.CURRENT_ATTENTION_TARGET = nil
			
			-- Experimental (refresh everything now and then)
			BotNavigation:ResetPathData()
			-- ~...
		end
		
		if (not timerexpired(self.LAST_ITEMS_BOUGHT_TIMER, 0.5)) then
			if (not hTarget or not self:IsContested(hTarget)) then
				self:AILog(0, "We're still buying equipment !")
				BotNavigation:ResetPath()
				BotNavigation:SetSleepTimer(0.5)
				return end end

		return hTarget
	end,
	
	-----------------
	IsContested = function(self, hBuilding)
		self:AILog(0, "%s.IsContested()", self.ModuleFullName)
		
		if (not self.CONTESTED_FACTORIES) then
			return false end
			
		return (self.CONTESTED_FACTORIES[hBuilding.id] == true)
	end,
	
	-----------------
	PostGetAttentionPoint = function(self)
		self:AILog(0, "%s.PostGetAttentionPoint()", self.ModuleFullName)
		
		---------
		local vPos = g_localActor:GetPos()
		
		---------
		if (BotNavigation.LAST_PATHGEN_FAILED) then
			BotNavigation:SetSleepTimer(1) end
		
		---------
		if (self.CURRENT_ATTENTION_TARGET) then
			self:AILog(0, "checking attention target (In Radius: %s, Correct Team: %s)", string.bool(self:IsInCaptureRadius(self.CURRENT_ATTENTION_TARGET), "yes", "no"), string.bool(not self:CompareTeams(self.CURRENT_ATTENTION_TARGET, g_localActor), "yes", "no"))
			if (self:IsInCaptureRadius(self.CURRENT_ATTENTION_TARGET) and not self:CompareTeams(self.CURRENT_ATTENTION_TARGET, g_localActor)) then
				self:AILog(0, "Already at attention target !!")
				return (0xBEEF) elseif (not self:CompareTeams(self.CURRENT_ATTENTION_TARGET, g_localActor)) then
					return self.CURRENT_ATTENTION_TARGET end
		end
		
		---------
		-- local hContested = GetEntity(self.CONTESTED_GO_HERE)
		-- if (hContested) then
			-- self:AILog(0, "going to contested building")
			-- return hContested end
		
		---------
		local bProto, hProto = self:IsBuildingCaptured("Prototype")
		if (not bProto) then
			local hCloseSpawn = self:GetUncapturedBuilding("spawn", hProto:GetPos(), 100)
			if (hCloseSpawn) then
				self:AILog(0, "Found uncaptured spawn near proto!")
				return hCloseSpawn
			end
			self:AILog(0, "Going to proto!")
			
			if (not self:CompareTeams(hProto, g_localActor)) then
				self:SendRadio(RADIO_TAKE_PROTO) end
			return hProto
		end
		
		---------
		local hNextSpawn = self:GetUncapturedBuilding("spawn", hProto:GetPos(), 175)
		if (hNextSpawn) then
			self:AILog(0, "Found another uncaptured spawn near proto!")
			-- self:SendRadio(RADIO_TAKE_SPAWN)
			return hNextSpawn
		end
			
		---------
		local hNextContested = self:GetContestedBuilding(GET_ALL, vPos, 300)
		if (hNextContested) then
			local bGotoContested = true
			if (bGotoContested) then
				self:SendRadio(self:GetRadioForBuilding(hNextContested))
				return hNextContested end end
		
		---------
		local hNextUncaptured = self:GetUncapturedBuilding(GET_ALL, vPos)
		if (hNextUncaptured) then
			self:SendRadio(self:GetRadioForBuilding(hNextUncaptured))
			return hNextUncaptured end
			
		---------
		local hRandom = self:GetRandomBuilding(self.CURRENT_ATTENTION_TARGET)
		if (not self:CompareTeams(hRandom, g_localActor)) then
			self:SendRadio(self:GetRadioForBuilding(hRandom)) end
		return hRandom
	end,
	
	-----------------
	GetRadioForBuilding = function(self, hBuilding)
		local sType = hBuilding.BUILDING_TYPE
		if (sType == "prototype") then
			return RADIO_TAKE_PROTO elseif (sType == "alien") then
				return RADIO_TAKE_ENERGY elseif (sType == "air") then
					return RADIO_TAKE_AIRFAC elseif (sType == "war") then
						return RADIO_TAKE_WARFAC end
		
		return
	end,
	
	-----------------
	GetRandomBuilding = function(self, hExcept)
		
		---------
		local vPos = g_localActor:GetPos()
		
		---------
		local fPred = nil
		if (not isNull(hExcept)) then
			fPred = function(a)
				return (a.id ~= hExcept.id) end
		end
		
		---------
		local aBuildings = self:GetBuildingsOfType(GET_ALL, vPos)
		if (table.count(aBuildings) > 0) then
			return getrandom(aBuildings, fPred) end
			
		---------
		return
	end,
	
	-----------------
	IsCapturing = function(self, hEntity)
	
		----------
		if (not hEntity) then
			return (not isNull(self.INSIDE_CAPTURE_AREA)) else
			return (vector.distance(hEntity:GetPos(), g_localActor:GetPos()) < 15) end
	
		----------
		if (isNull(self.INSIDE_CAPTURE_AREA)) then
			self:AILog(0, "No in ANY AREA!!")
			return false end
	
		----------
		self:AILog(0, "Capture Area Id: %s", tostring(self.INSIDE_CAPTURE_AREA.id))
		return (self.INSIDE_CAPTURE_AREA.id == hEntity.id)
	end,
	
	-----------------
	IsInCaptureRadius = function(self, hBuilding, hEntity)
	
		if (not hBuilding) then
			return false end
	
		----------
		local hEntity = checkVar(GetEntity(hEntity), g_localActor)
		if (hEntity == g_localActor) then
			self:AILog(0, "local actor check!")
			return self:IsCapturing(hBuilding) end
	
		----------
		self:AILog(0, "CANNOT PROPERLY DETERMINE IF OTHER ENTITIES ARE IN CAPTURE AREA YET !")
		return (vector.distance(hBuilding:GetPos(), hEntity:GetPos()) < 60)
	end,
	-----------------
	SetContested = function(self, hBuilding, bContested)
	
		-----------
		self:AILog(0, "Factory %s contested status: %s", hBuilding:GetName(), string.bool(bContested, "yes","no"))
		
		-----------
		local hCurrent = self.CURRENT_ATTENTION_TARGET
		if (hCurrent and self:CompareTeams(hCurrent, g_localActor)) then
			self.CURRENT_ATTENTION_TARGET = nil end
	
		-----------
		if (not self.CONTESTED_FACTORIES) then
			self.CONTESTED_FACTORIES = {} end
	
		-----------
		self.CONTESTED_FACTORIES [hBuilding.id] = bContested
		
		-----------
		local hContested = GetEntity(self.CONTESTED_GO_HERE)
		
		-----------
		local vPos = g_localActor:GetPos()
		if (bContested) then
			local iDistance = vector.distance(hBuilding:GetPos(), g_localActor:GetPos())
			if (iDistance < 80) then
				if (not self.CURRENT_ATTENTION_TARGET or (vector.distance(self.CURRENT_ATTENTION_TARGET:GetPos(), vPos) > 50)) then
					self.CONTESTED_GO_HERE = hBuilding.id
					self:AILog(0, "Building contested! GO THERE NOW!")
				end
			end
		elseif (hContested and hContested.id == hBuilding.id) then
			self.CONTESTED_GO_HERE = nil
		end
	end,
	-----------------
	OnCaptured = function(self, hBuilding, idBuilding, iTeam)
	
		-----------
		self:AILog(0, "Factory %s captured by %d", hBuilding:GetName(), iTeam)
	
		-----------
		local hCurrent = self.CURRENT_ATTENTION_TARGET
		if (hBuilding == hCurrent) then
			self:AILog(0, "Reset Current attention target!")
			BotNavigation:ResetPath()
			self.CURRENT_ATTENTION_TARGET = nil end
		
		-----------
		if (iTeam ~= g_gameRules.game:GetTeam(g_localActorId)) then
			if (hCurrent and self:CompareTeams(hCurrent, g_localActor)) then
				BotNavigation:ResetPath()
				self.CURRENT_ATTENTION_TARGET = nil end
		end
	end,
	-----------------
	OnEnterCaptureArea = function(self, idBuilding, bEnter)
	
		-----------
		if (not bEnter) then
			self.INSIDE_CAPTURE_AREA = nil
			return end
	
		-----------
		self.INSIDE_CAPTURE_AREA = GetEntity(idBuilding)
	end,
	
	-----------------
	OnEnterBuyZone = function(self, idBuilding, bEnter)
	
		self:AILog(0, "%s Buy Zone: %s", string.bool(bEnter, "Entered", "Left"), tostring(idBuilding))
		-----------
		if (not bEnter) then
			self.INSIDE_BUY_ZONE = nil
			return end
	
		-----------
		self.INSIDE_BUY_ZONE = GetEntity(idBuilding)
	end,
	
	-----------------
	CheckEquipment = function(self)
	
		-----------
		self:AILog(0, "%s.CheckEquipment()", self.ModuleFullName)
	
		-----------
		local iMedium = g_localActor.actor:GetItemCountOfCategory('medium')
		local iHeavy = g_localActor.actor:GetItemCountOfCategory('heavy')
		local iUtility = g_localActor.actor:GetItemCountOfCategory('utility')
		local iExplosives = g_localActor.actor:GetItemCountOfCategory('explosive')
		if ((iMedium + iHeavy) < 2) then
			self:GoShopping() 
			elseif (iUtility < 2) then
				self:GoKitShopping()
				elseif (iExplosives < 1) then
					self:GoExplosiveShopping() end
			
		-----------
		self:AILog(0, "Medium: %d, utility: %d", (iMedium + iHeavy), iUtility)
			
		-----------
		local hCurrent = Bot:GetItem()
		if (hCurrent and hCurrent.weapon) then
			local iInventory = Bot:GetInventoryAmmo(hCurrent)
			local iClip = hCurrent.weapon:GetClipSize()
			if (iClip and (iInventory < (iClip * 2))) then
				self:BuyAmmo()
			end
		end
	end,
	
	-----------------
	GoShopping = function(self)
	
		-----------
		if (Bot.movingToMyGun) then
			return end
	
		-----------
		if (not timerexpired(self.LAST_ITEM_BOUGHT_TIMER, 5)) then
			return end
			
		-----------
		local aExtra = Config.BuyableKits
		local aBuyable = Config.BuyableItems
		local aExcluded = Config.ExcludedItems
			
		-----------
		if (not isArray(aBuyable)) then
			return end
			
		-----------
		local iPrestige = (g_gameRules:GetPlayerPP(g_localActor.id) - 250)
		if (iPrestige <= 0) then
			return end
			
		-----------
		self:AILog(0, "Shopping Budget: %f", iPrestige)
			
		-----------
		local aBuyList = g_gameRules.weaponList
		local aConsideredItems = {}
		for i, aProps in pairs(aBuyList) do
			local sClass = aProps.class
			if (sClass and not self:BuyError(aProps.id)) then
				if (not Bot:HasItem(sClass) and Bot:SpaceInInventory(sClass)) then
					if (aProps.price and aProps.price <= iPrestige and (aBuyable[sClass] == true and aExcluded[sClass] ~= true)) then
						if (timerexpired(self.LAST_ITEM_BOUGHT_TIMER, 1) or (sClass ~= self.LAST_BOUGHT_ITEM)) then
							table.insert(aConsideredItems, { aProps.class, aProps.price, aProps.id }) end
					end
				end
			end
		end
		
		-----------
		local aToBuy
		
		-----------
		if (table.count(aConsideredItems) > 0) then
			local aItemPriority = Config.BuyPriority or {
				['SMG'] = 1.5,
				['SCAR'] = 2.5,
				['FY71'] = 3.0,
				['DSG1'] = 2.1,
				['LAW'] = 0,
				['GaussRifle'] = 4,
			}
			
			-----------
			table.sort(aConsideredItems, function(aItem_A, aItem_B)
				local iPriority_A = checkNumber(aItemPriority[aItem_A[1]], 1)
				local iPriority_B = checkNumber(aItemPriority[aItem_B[1]], 1)
				
				-----------
				if (iPriority_A == iPriority_B) then
					return aItem_A[2] < aItem_B[2] end
				
				-----------
				return (iPriority_A > iPriority_B)
			end)
			
			-----------
			aToBuy = aConsideredItems[1]
		else
			self:GoKitShopping()
		end
		
		if (isArray(aToBuy)) then
			self:AILog(0, "Buying item %s for %d Prestige (id: %s)", aToBuy[1], aToBuy[2], aToBuy[3])
			self.LAST_ITEMS_BOUGHT_TIMER = timerinit()
			self.LAST_ITEM_BOUGHT_TIMER = timerinit()
			self.LAST_BOUGHT_ITEM = aToBuy[1]
			System.ExecuteCommand(string.format("buy %s", aToBuy[3])) end
	end,
	
	-----------------
	GoKitShopping = function(self)
	
		-----------
		if (Bot.movingToMyGun) then
			return end
	
		-----------
		if (not timerexpired(self.LAST_KIT_BOUGHT_TIMER, 5)) then
			return end
			
		-----------
		local aBuyableKits = Config.BuyableKits
		local aExcluded = Config.ExcludedItems
			
		-----------
		if (not isArray(aBuyableKits)) then
			self:AILog(0, "No buyable kit configuration was found")
			return end
			
		-----------
		local iPrestige = (g_gameRules:GetPlayerPP(g_localActor.id) - 250)
		if (iPrestige <= 0) then
			return end
			
		-----------
		self:AILog(0, "Kit Shopping Budget: %f", iPrestige)
			
		-----------
		local aBuyList = g_gameRules.equipList
		local aConsideredKits = {}
		for i, aProps in pairs(aBuyList) do
			local sClass = aProps.class
			if (sClass and not self:BuyError(aProps.id)) then
				if (not Bot:HasItem(sClass)) then
					if (aProps.price and aProps.price <= iPrestige  and (aBuyableKits[sClass] == true and aExcluded[sClass] ~= true)) then
						if (timerexpired(self.LAST_KIT_BOUGHT_TIMER, 1) or (sClass ~= self.LAST_BOUGHT_ITEM)) then
							table.insert(aConsideredKits, { aProps.class, aProps.price, aProps.id }) end
					end
				end
			end
		end
		
		-----------
		local aToBuy
		
		-----------
		if (table.count(aConsideredKits) > 0) then
			local aKitPriority = Config.KitPriority or {
				['RadarKit'] = 3,
				['RepairKit'] = 2,
				['LockpickKit'] = 1,
			}
			
			-----------
			table.sort(aConsideredKits, function(aItem_A, aItem_B)
				local iPriority_A = checkNumber(aKitPriority[aItem_A[1]], 1)
				local iPriority_B = checkNumber(aKitPriority[aItem_B[1]], 1)
				
				-----------
				if (iPriority_A == iPriority_B) then
					return aItem_A[2] < aItem_B[2] end
				
				-----------
				return (iPriority_A > iPriority_B)
			end)
			
			-----------
			aToBuy = aConsideredKits[1]
		else
			self:GoExplosiveShopping()
		end
		
		if (isArray(aToBuy)) then
			self:AILog(0, "Buying KIT %s for %d Prestige (id: %s)", aToBuy[1], aToBuy[2], aToBuy[3])
			self.LAST_ITEMS_BOUGHT_TIMER = timerinit()
			self.LAST_KIT_BOUGHT_TIMER = timerinit()
			self.LAST_BOUGHT_ITEM = aToBuy[1]
			System.ExecuteCommand(string.format("buy %s", aToBuy[3])) end
	end,
	
	-----------------
	GoExplosiveShopping = function(self)
	
		-----------
		if (Bot.movingToMyGun) then
			return end
	
		-----------
		if (self:IsNearBase()) then
			return end
	
		-----------
		if (not timerexpired(self.LAST_EXPLOSIVE_BOUGHT_TIMER, 5)) then
			return end
			
		-----------
		local aBuyableExplosives = Config.BuyableExplosives
		local aExcluded = Config.ExcludedItems
			
		-----------
		if (not isArray(aBuyableExplosives)) then
			self:AILog(0, "No buyable explosive configuration was found")
			return end
			
		-----------
		local iPrestige = (g_gameRules:GetPlayerPP(g_localActor.id) - 250)
		if (iPrestige <= 0) then
			return end
			
		-----------
		self:AILog(0, "Explosive Shopping Budget: %f", iPrestige)
			
		-----------
		local aBuyList = g_gameRules.weaponList
		local aConsideredExplosives = {}
		for i, aProps in pairs(aBuyList) do
			local sClass = aProps.class
			if (sClass and not self:BuyError(aProps.id)) then
				if (not Bot:HasItem(sClass)) then
					if (aProps.price and aProps.price <= iPrestige  and (aBuyableExplosives[sClass] == true and aExcluded[sClass] ~= true)) then
						if (timerexpired(self.LAST_EXPLOSIVE_BOUGHT_TIMER, 1) or (sClass ~= self.LAST_BOUGHT_ITEM)) then
							table.insert(aConsideredExplosives, { aProps.class, aProps.price, aProps.id }) end
					end
				end
			end
		end
		
		-----------
		local aToBuy
		
		-----------
		if (table.count(aConsideredExplosives) > 0) then
			local aExplosivePriority = Config.ExplosivePriority or {
				['C4'] = 2,
				['Claymore'] = 1,
			}
			
			-----------
			table.sort(aConsideredExplosives, function(aItem_A, aItem_B)
				local iPriority_A = checkNumber(aExplosivePriority[aItem_A[1]], 1)
				local iPriority_B = checkNumber(aExplosivePriority[aItem_B[1]], 1)
				
				-----------
				if (iPriority_A == iPriority_B) then
					return aItem_A[2] < aItem_B[2] end
				
				-----------
				return (iPriority_A > iPriority_B)
			end)
			
			-----------
			aToBuy = aConsideredExplosives[1]
		end
		
		if (isArray(aToBuy)) then
			self:AILog(0, "Buying EXPLOSIVE %s for %d Prestige (id: %s)", aToBuy[1], aToBuy[2], aToBuy[3])
			self.LAST_ITEMS_BOUGHT_TIMER = timerinit()
			self.LAST_EXPLOSIVE_BOUGHT_TIMER = timerinit()
			self.LAST_BOUGHT_ITEM = aToBuy[1]
			System.ExecuteCommand(string.format("buy %s", aToBuy[3])) end
	end,
	
	-----------------
	BuyError = function(self, sItemId)
		return (not timerexpired(self.BUY_ERROR[sItemId], 5))
	end,
	
	-----------------
	IsNearBase = function(self)
	
		-----------
		local hBase = self.SPAWN_BASE
		if (not hBase) then
			return false end
			
		-----------
		local vPos = g_localActor:GetPos()
		local vBase = hBase:GetPos()
		
		-----------
		local iDistance = vector.distance(vPos, vBase)
		
		-----------
		return (iDistance < 60)
	end,
	
	-----------------
	BuyAmmo = function(self)
	
		-----------
		if (not timerexpired(self.LAST_AMMO_BOUGHT_TIMER, 1)) then
			return end
			
		-----------
		g_gameRules:BuyAmmo()
		
		-----------
		self.LAST_AMMO_BOUGHT_TIMER = timerinit()
	end,
	
	-----------------
	GetUncapturedBuilding = function(self, sType, vSource, iMaxDistance)
		self:AILog(0, "%s.GetUncapturedBuilding()", self.ModuleFullName)
		
		---------
		local aBuildings = self:GetBuildingsOfType(sType)
		if (table.count(aBuildings) == 0) then
			self:AILog(0, "No Buildings of type '%s' were found", sType)
			return false end
			
		---------
		local iMaxDistance = checkNumber(iMaxDistance, -1)
		local vSource = checkVar(vSource, g_localActor:GetPos())
			
		---------
		local aClosest = { nil, iMaxDistance }
		for i, hBuilding in pairs(aBuildings) do
			if (not self:CompareTeams(hBuilding, g_localActor)) then
				local iDistance = vector.distance(vSource, hBuilding:GetPos())
				if (iMaxDistance == -1 or (aClosest[2] == -1 or iDistance < aClosest[2])) then
					aClosest = {
						hBuilding,
						iDistance
					}
				end
			end
		end
			
		---------
		return aClosest[1]
	end,
	
	-----------------
	GetContestedBuilding = function(self, sType, vSource, iMaxDistance)
		self:AILog(0, "%s.GetContestedBuilding()", self.ModuleFullName)
		
		---------
		local aContested = self.CONTESTED_FACTORIES
		if (table.count(aContested) == 0) then
			self:AILog(0, "No Contested Buildings of type '%s' were found", sType)
			return false end
			
		---------
		local iMaxDistance = checkNumber(iMaxDistance, -1)
		local vSource = checkVar(vSource, g_localActor:GetPos())
			
		---------
		local aClosest = { nil, iMaxDistance }
		for idBuilding, bContested in pairs(aContested) do
			local hBuilding = GetEntity(idBuilding)
			if (bContested) then
				if (sType == GET_ALL or (hBuilding.BUILDING_TYPE == sType)) then
					if (not self:CompareTeams(hBuilding, g_localActor)) then
						local iDistance = vector.distance(vSource, hBuilding:GetPos())
						if (iMaxDistance == -1 or (aClosest[2] == -1 or iDistance < aClosest[2])) then
							aClosest = {
								hBuilding,
								iDistance
							}
						end
					end
				end
			end
		end
			
		---------
		return aClosest[1]
	end,
	
	-----------------
	GetBuildingsOfType = function(self, sType)
		self:AILog(0, "%s.GetBuildingsOfType()", self.ModuleFullName)
		
		if (sType == GET_ALL) then
			local aAll = {}
			for sBuildingType, aBuildings in pairs(self.BUILDINGS) do
				table.append(aAll, aBuildings) end
			return aAll
		end
		
		return (self.BUILDINGS[string.lower(sType)])
	end,
	
	-----------------
	IsBuildingCaptured = function(self, sBuilding, iIndex)
	
		---------
		self:AILog(0, "%s.IsBuildingCaptured()", self.ModuleFullName)
		
		---------
		local aBuildings = self:GetBuildingsOfType(sBuilding)
		if (table.count(aBuildings) == 0) then
			self:AILog(0, "No Buildings of type '%s' were found", sBuilding)
			return false end
		
		---------
		local hBuilding = aBuildings[1]
		if (isNumber(iIndex) and table.count(aBuildings) > 1) then
			hBuilding = aBuildings[iIndex] end
		
		---------
		if (not hBuilding) then
			self:AILog(0, "Building Index %d out of bounds", iIndex)
			return end
		
		---------
		return self:CompareTeams(hBuilding, g_localActorId), hBuilding
	end,
})