----------------------------------------
-- PowerStruggle AI Module

BotAI:CreateAIModule("PowerStruggle", {

	----------
	BUY_ERROR = {},
	BUILDINGS = {},
	CURRENT_TEAM = 0,
	SPAWN_BASE = 0,

	CURRENT_CONTESTED_TARGET = nil,
	CURRENT_ATTENTION_TARGET = nil,

	INSIDE_CAPTURE_AREA = nil,

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
			--self:AILog(0, "%s.Events.OnTimer(%f)", self.ModuleFullName, iFrameTime)

			----------------
			self:OnTimer(iFrameTime)
		end,

		------------------------------
		-- OnTimer
		GetSuitMode = function(self)

			local hCurrent = self.CURRENT_ATTENTION_TARGET
			if (self:IsInCaptureRadius(hCurrent)) then
				--AILog("Nanomode armor!")
				return NANOMODE_ARMOR
			end

			--AILog("Mode nONE!")
			return AIEVENT_ABORT
		end,

		------------------------------
		-- OnTimer
		OnIdleWeapon = function(self, sClass)

			if (sClass == ITEM_KIT_RADAR) then

				if (timerexpired(self.LAST_SCAN_TIMER, self.NEXT_SCAN_TIME)) then
					self:ScanWithRadar()
				end
			end

		end,

		------------------------------
		-- OnTimer
		GetIdleViewPoint = function(self)
			return AIEVENT_ABORT
		end,

		------------------------------
		-- OnTimer
		GetIdleWeapon = function(self)

			-----
			local vPos = Bot:GetPos()
			local hCurrent = self.CURRENT_ATTENTION_TARGET
			local vCurrent
			local bIndoors = (Bot:IsIndoors() and not Bot:IsUnderground())
			local bInCaptureRadius = self:IsInCaptureRadius(hCurrent)
			if (hCurrent) then
				vCurrent = hCurrent:GetPos()
				bInCaptureRadius = (bInCaptureRadius or vector.distance(vCurrent, vPos) < 80)
			end

			-----
			local hRadar = Bot:HasItem(ITEM_KIT_RADAR, true)
			if (hRadar and (bIndoors or bInCaptureRadius)) then
				return (ITEM_KIT_RADAR)
			end

			-----
			local hRepair = Bot:HasItem(ITEM_KIT_REPAIR, true)
			local hLockpick = Bot:HasItem(ITEM_KIT_LOCKPICK, true)
		end,

		------------------------------
		-- OnTimer
		Inventory_FoundC4 = function(self, iFrameTime)
		end,

		------------------------------
		-- OnTimer
		Inventory_FoundClaymore = function(self, iFrameTime)
		end,

		------------------------------
		-- OnTimer
		Inventory_CanPlaceExplosive = function(self, iFrameTime)
		end,

		------------------------------
		-- CanGoIdle

		CanGoIdle = function(self, ...)
			--self:AILog(0, "%s.Events.CanGoIdle()", self.ModuleFullName)

			-- never in PS?
			return AIEVENT_ABORT
		end,

		------------------------------
		-- IsCapturing

		IsCapturing = function(self, ...)
			--self:AILog(0, "%s.Events.IsCapturing()", self.ModuleFullName)

			return self:IsCapturing(...)
		end,

		------------------------------
		-- GetPathGoal

		GetPathGoal = function(self, hRandomEntity)
			---self:AILog(0, "%s.Events.GetPathGoal()", self.ModuleFullName)

			return self:GetAttentionPoint()
		end,

		------------------------------
		-- GetPathGoal

		PathGoalReached = function(self)
			--self:AILog(0, "%s.Events.PathGoalReached()", self.ModuleFullName)

			self.LAST_RESORT_TARGET = nil
			return self:GetAttentionPoint()
		end,

		------------------------------
		-- OnEnterVehicleSeat
		OnEnterVehicleSeat = function(self, hVehicle, aSeat, hUser)
			local hOurVehicle = Bot:GetVehicle()
			if (hOurVehicle and hOurVehicle.id == hVehicle.id) then
			end

			hUser.VAN_INVITATION_COUNTER = 0
		end,

		------------------------------
		-- OnLeaveVehicleSeat
		OnLeaveVehicleSeat = function(self, hVehicle, aSeat, hUser, bExiting)
			local hOurVehicle = Bot:GetVehicle()
			if (bExiting and hOurVehicle and hOurVehicle.id == hVehicle.id) then
				hUser.VAN_ABANDON_TIMER = timerinit()
			end
		end,

		------------------------------
		-- ValidateVehicle
		ValidateVehicle = function(self, hVehicle)

			-- no checks yet
			return AIEVENT_OK
		end,

		------------------------------
		-- ProcessInVehicle
		ProcessInVehicle = function(self, hVehicle)

			if (not timerexpired(Bot.VEHICLE_INVITE_TIMEOUT, 8)) then
				AILog("timeout..")
				return AIEVENT_OK
			end

			local vPos = Bot:GetPos()
			local aFriendlies = GetEntities(ENTITY_PLAYER, nil, function(hPlayer)

				local bOk = true
				if (not Bot:IsTarget_SameTeam(hPlayer)) then
					bOk = false
				end
				if (not Bot:IsAlive(hPlayer)) then
					bOk = false
				end
				if (Bot:GetVehicle(hPlayer)) then
					bOk = false
				end
				local iDistance = vector.distance(hPlayer:GetPos(), vPos)
				if (iDistance > 25) then
					bOk = false
				end

				if (not timerexpired(hPlayer.VAN_INVITATION_TIMER, 25)) then
					bOk = false
				end

				if (not timerexpired(hPlayer.VAN_ABANDON_TIMER, 120)) then
					bOk = false
				end

				if (hPlayer.VAN_BLACKLIST_TIMER and not hPlayer.VAN_BLACKLIST_TIMER.expired()) then
					bOk = false
				end

				if (hPlayer.VAN_INVITATION_COUNTER and hPlayer.VAN_INVITATION_COUNTER >= 2) then
					if (not hPlayer.VAN_BLACKLIST_TIMER) then
						hPlayer.VAN_BLACKLIST_TIMER = timernew(75)
					end
					bOk = false
				end

				------
				--- pick up only if NEAR a spawn or out in the wilderness ??
				local hClosestAny = self:GetRandomBuilding(BUILDING_ANY)

				------
				if (bOk) then

					hPlayer.VAN_INVITATION = true
				else
					return false
				end
				return true
			end)

			if (table.count(aFriendlies) > 0) then

				local hInviteTimer = Bot.VEHICLE_INVITE_FRIENDLIES
				if (not hInviteTimer or not hInviteTimer.expired()) then


					if (timerexpired(self.LAST_RADIO_TIMER, 4)) then
						self:SendRadio(RADIO_GET_IN, 5)

						for _, hPlayer in pairs(aFriendlies) do
							hPlayer.VAN_INVITATION_COUNTER = (hPlayer.VAN_INVITATION_COUNTER or 0) + 1
						end
					end

					AILog("INVITING !!")

					Bot.VEHICLE_INVITE_FRIENDLIES = checkVar(hInviteTimer, timernew(10))
					return AIEVENT_ABORT -- wait for friendlies
				else

					Bot.VEHICLE_INVITE_FRIENDLIES = nil
					Bot.VEHICLE_INVITE_TIMEOUT = timerinit()
				end
			end

			AILog("No friendlies!!s")
			return AIEVENT_OK
		end,

		------------------------------
		-- LeaveVehicleForTarget
		LeaveVehicleForTarget = function(self, hVehicle, vGoal)

			-- AIEVENT_ABORT means to abort the action for whatever called this function
			-- AIEVENT_OK means to proceed with the action

			if (not hVehicle) then
				return AIEVENT_OK -- Ok to LEAVE!
			end

			local aWeapons = Bot:GetVehicleWeapons()
			if (not isArray(aWeapons)) then
				return AIEVENT_OK -- Ok to LEAVE
			end

			local bAnyOk = true -- check ammo of each weapon (not yet)
			local hCurrent_Self = self.CURRENT_ATTENTION_TARGET
			local hCurrent_Cont = self.CURRENT_CONTESTED_TARGET
			local hCurrent_Navi = BotNavigation:GetTarget()

			if (hCurrent_Self ~= nil and hCurrent_Navi == hCurrent_Self and not hCurrent_Cont) then


				-- ?? But we have GUNS !!
				local aContestants = self:GetBuildingContestants(hCurrent_Self)
				if (table.count(aContestants) > 0) then
					--AILog("BAD! theres contestants!")
					--return AIEVENT_OK -- Ok to LEAVE
				end

				if (checkFunc(hCurrent_Self.IsType, true, hCurrent_Self, BUILDING_SPAWN, BUILDING_ALIEN)) then
					AILog("Its a spawn or alien site, we're in a vehicle!!")
					return AIEVENT_ABORT -- dont LEAVE
				end
			end

			return AIEVENT_OK -- Ok to LEAVE
		end,

		------------------------------
		-- OkInVehicle
		OkInVehicle = function(self, hVehicle)

			-- true means we can stay
			-- false to leave (always)

			--if (BotAI.CallEvent("LeaveVehicleForTarget", hVehicle) == AIEVENT_ABORT) then
			--	return true, AILog("STAYING !!!!!!!!!!")
			--end

			local vPos = g_localActor:GetPos()
			local hCurr = self.CURRENT_ATTENTION_TARGET
			if (hCurr) then
				if (self:IsInCaptureRadius(hCurr, g_localActorId)) then
					if (hCurr.BUILDING_TYPE == BUILDING_SPAWN and hVehicle:IsSmall()) then
						return false, AILog("bad, its spawn and vehicle i small")
					end
				end
			end

			-- All Good
			return true
		end,

		------------------------------
		-- IsTargetOk
		IsTargetOk = function(self, hTarget, iDistance)
			-- self:AILog(0, "%s.Events.IsTargetOk(%f)", self.ModuleFullName, iDistance)

			if (self:CompareTeams(hTarget, g_localActor)) then
				return false end

			if ((iDistance < 50) and (not self:IsCapturing() or self:IsInCaptureRadius(self.CURRENT_ATTENTION_TARGET, hTarget))) then
				return true end

			if (Bot:GetLastSeen()) then
				return false end

			local hEntity = Bot:GetLastSeenEntity("id")
			if (hEntity and hEntity ~= hTarget.id) then
				return false end

			if (not Bot:IsEntityTagged(hTarget.id)) then
				self:AILog(5, "NOT GOING TO TARGET %s (THEY ARE NOT ON OUR RADAR !!)", hTarget:GetName())
				return false end

			return false
		end,

		------------------------------
		-- ShouldDropItem
		ShouldDropItem = function(self, hWeapon)
			--self:AILog(0, "%s.Events.ShouldDropItem(%s)", self.ModuleFullName, hWeapon.class)

			return true
		end,

		------------------------------
		-- OnRadioMessage
		OnRadioMessage = function(self, hActor, iMessage)
			--self:AILog(0, "%s.Events.OnRadioMessage(%s, %d)", self.ModuleFullName, hActor:GetName(), iMessage)

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

				if (not timerexpired(hActor.VAN_INVITATION_TIMER, 10) and iMessage == RADIO_NO) then
					hActor.VAN_INVITATION_COUNTER = 10
					hActor.VAN_BLACKLIST_TIMER = timernew(75)
				end

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
			--self:AILog(0, "%s.Events.CanPlaceExplosive(%s, %s)", self.ModuleFullName, hSpawn:GetName(), Vec2Str(vSpawn))

			return true
		end,

		------------------------------
		-- OnEntityTagged
		OnEntityTagged = function(self, hEntity)
			--self:AILog(0, "%s.Events.OnEntityTagged(%s)", self.ModuleFullName, hEntity:GetName())
			self:SendRadio(RADIO_ENEMY_SPOTTED)
			return true
		end,
	},

	------------------------------
	-- ScanWithRadar
	ScanWithRadar = function(self)

		local hRadar = GetEntity(Bot:HasItem(ITEM_KIT_RADAR, true))
		if (hRadar) then
			hRadar.weapon:RequestStartFire()
			self.LAST_SCAN_TIMER = timerinit()
			self.NEXT_SCAN_TIME = 0 --getrandom(10, 17)
		end
	end,

	------------------------------
	-- OnTimer

	OnTimer = function(self, iFrameTime)
		--self:AILog(0, "%s.OnTimer()", self.ModuleFullName)

		----------------
		self.CURRENT_TEAM = g_gameRules.game:GetTeam(g_localActorId)

		----------------
		AISetGlobal(eAI_gIsBuildingContested, self:IsContested(self.CURRENT_ATTENTION_TARGET))

		----------------
		if (not self:CheckTeam()) then
			return end

		----------------
		if (self:InBuyZone()) then
			self:CheckEquipment() end

		----------------
		--self:AILog(0, "SELECTED RANDOM: %s", self:GetRandomBuilding(self.CURRENT_ATTENTION_TARGET):GetName())

		----------------
		local hTargetEntity = self.CURRENT_ATTENTION_TARGET
		if (hTargetEntity) then
			local hClosestSpawnGroup = self:GetClosestSpawnGroup(hTargetEntity:GetPos())
			if (hClosestSpawnGroup) then
				g_gameRules.server:RequestSpawnGroup(g_localActorId, hClosestSpawnGroup.id)
			end
		end


		local aBirds = GetEntities({ VEHICLE_VTOL, VEHICLE_HELICOPTER }, nil, function(a)
			return (not a.vehicle:IsDestroyed() and a:GetDriverId() and not Bot:IsTarget_SameTeam(a))
		end)
		local vPos = g_localActor:GetPos()
		local bPause = false
		if (table.count(aBirds) > 0) then
			if (Bot:IsIndoors()) then

				-- Maybe bad idea, last node means exit of tunnel/building/whatever. means more visible
				local vLastIndoors = BotNavigation:GetLastIndoorsNodeOnPath()
				if (not Bot:IsUnderground()) then
					-- ?? only tunnels
					vLastIndoors = nil
				end

				for i, hHunter in pairs(aBirds) do
					if (vector.distance(checkVar(vLastIndoors, vPos), hHunter:GetPos()) < 250) then
						bPause = true
					end
				end

			end
		end

		--local hTimer = self.ALIEN_HIDE_TIMER
		--[[
        if (hTimer) then
            if (not bPause) then
                bPause = (not hTimer.expired())
            end
        else
        end
        ]]

		if (bPause) then
			if (not Bot:HasTarget() and not self:IsContested(self.CURRENT_ATTENTION_TARGET)) then
				AILog("Indoors and vtol nearby!!")
				Bot:InterruptMovement(eMovInterrupt_DangerOutside, 10)
				Bot:StopMovement()
			else
				AILog("Bot Not pausing because theres ENEMIES !")
			end
			--    self.ALIEN_HIDE_TIMER = checkVar(hTimer, timernew(7.5))
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

	SendRadio = function(self, iRadio, iTimer)
		self:AILog(0, "%s.iRadio()", self.ModuleFullName)

		----------------
		if (not isNumber(iRadio)) then
			self:AILog("Invalid RadioID specified to SendRadio(%s)", tostring(iRadio)) end

		----------------
		if (not self.RADIO_TIMERS) then
			self.RADIO_TIMERS = {} end

		----------------
		if (not timerexpired(self.RADIO_TIMERS[iRadio], 30)) then
			return end

		----------------
		local iExpire = checkNumber(iTimer, 30)
		if (iRadio == self.LAST_RADIO_ID and isNull(iTimer)) then
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
		--self:AILog(0, "%s.InBuyZone()", self.ModuleFullName)

		----------------
		return (not isNull(self.INSIDE_BUY_ZONE))
	end,

	------------------------------
	-- CheckTeam

	CheckTeam = function(self)
		--self:AILog(0, "%s.CheckTeam()", self.ModuleFullName)

		----------------
		if (self.CURRENT_TEAM == TEAM_NEUTRAL) then
			self:ChangeTeam(TEAM_WEAKEST)
			return false end

		----------------
		return true
	end,

	------------------------------
	-- CheckTeam

	CheckEntityTeam = function(self, hEnt)
		self:AILog(0, "%s.CheckEntityTeam()", self.ModuleFullName)

		----------------
		return Bot:IsTarget_SameTeam(hEnt)
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
		--self:AILog(0, "%s.GetClosestSpawnGroup()", self.ModuleFullName)

		----------------
		local iMyTeam = g_gameRules.game:GetTeam(g_localActor.id)

		----------------
		local aSpawnGroups = table.appendA(self:GetBuildingsOfType("spawn"), GetEntities(GET_ALL, nil, function(a)
			local bOk = (Bot:IsTarget_SameTeam(a))
			bOk = bOk and (g_gameRules.game:IsSpawnGroup(a.id))
			bOk = bOk and (not a.vehicle or not a.vehicle:IsDestroyed())
			if (bOk) then
				AILog("is ok:::::: %s, %s",g_ts(bOk),a:GetName())
			end

			return bOk
		end))

		----------------
		vPos = checkVar(vPos, g_localActor:GetPos())

		----------------
		local aBestSpawn = { nil, -1 }
		local iDistance

		for i, hSpawn in pairs(aSpawnGroups) do
			if (Bot:IsTarget_SameTeam(hSpawn)) then

				--throw_error()
				iDistance = vector.distance(hSpawn:GetPos(), vPos)
				if (aBestSpawn[2] == -1 or (iDistance < aBestSpawn[2])) then
					aBestSpawn = {
						hSpawn,
						iDistance
					}
				end
			else
--				AILog("team = %d, %s",g_gameRules.game:GetTeam(hSpawn.id),hSpawn:GetName())
			end
		end

		----------------
		if (aBestSpawn[1]) then
			--throw_error()
		--	AILog("->>>>>>>>>> %s",aBestSpawn[1]:GetName())
			return aBestSpawn[1]
		end

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
		BUILDING_ALIEN  = "alien"
		BUILDING_SPAWN  = "spawn"
		BUILDING_WAR 	= "war"
		BUILDING_SMALL 	= "small"
		BUILDING_PROTO  = "prototype"
		BUILDING_ANY	= "ANY"

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
		g_gameRules.OnEnterVehicleSeat = function(self, hVehicle, aSeat, idPassenger)
			AIEvent("OnEnterVehicleSeat", hVehicle, aSeat, GetEntity(idPassenger))
		end

		----------------
		g_gameRules.OnLeaveVehicleSeat = function(self, hVehicle, aSeat, idPassenger, bExiting)
			AIEvent("OnLeaveVehicleSeat", hVehicle, aSeat, GetEntity(idPassenger), bExiting)
		end

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
		g_gameRules.Client.OnStartUncapture = function(self, hBuilding, iTeam)
			AIModule:SetContested(hBuilding, (iTeam ~= CURRENT_TEAM))
			AIModule:AILog(0, "NOW CONTESTED!")
		end

		----------------
		g_gameRules.Client.OnCancelUncapture = function(self, hBuilding, iTeam)
			AIModule:SetContested(hBuilding, (iTeam ~= CURRENT_TEAM))
			AIModule:AILog(0, "NOT CONTESTED!")
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
					sBuildingType = BUILDING_ALIEN
				elseif (hEntity.class == "SpawnGroup") then
					sBuildingType = BUILDING_SPAWN
				end

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

			hEntity.IsType = function(self, ...)
				return (string.matchex(self.BUILDING_TYPE, ...))
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

		-----
		Bot:ContinueMovement(eMovInterrupt_Beef)
		self:AILog(0, "%s.GetAttentionPoint()", self.ModuleFullName)

		-----
		local hTarget, bIsContestant, bLastResort = self:PostGetAttentionPoint()
		local hCurrent = self.CURRENT_ATTENTION_TARGET
		local hNavTarget = BotNavigation.CURRENT_PATH_TARGET

		local bResetNavi
		local iNaviSleep

		if (hTarget) then
			if (hTarget == 0xBEEF) then
				self:AILog(0, "Got 0xBEEF as attention target!")
				if (Bot:OkToProne() and not self:IsContested(hCurrent) and not self:CheckEntityTeam(hCurrent)) then
					Bot:StartProne()
					self.PRONING = true
				else
					Bot:StopProne()
				end

				--Bot.MOVEMENT_INTERRUPTED = eMovInterrupt_Beef
				--if (not self:IsContested(hCurrent)) then
					BotNavigation.SLEEP_TIMER = timerinit()
					BotNavigation.SLEEP_TIME = 3
					Bot:InterruptMovement(eMovInterrupt_Beef)
					Bot:StopMovement()
				--else
				--	self:AILog("not pausing, theres contestants!!")
				--end
				return
			end

			local bTargetIsContestant = (bIsContestant and hTarget == self.CURRENT_CONTESTED_TARGET)
			AILog("Target is contestant: %s (%s)", tostring(bIsContestant),tostring(bTargetIsContestant))
			AILog("hCurrent = %s, Target = %s, CPT = %s", tostring(hCurrent), tostring(hTarget), tostring(BotNavigation.CURRENT_PATH_TARGET))

			if (hNavTarget) then
				AILog(hNavTarget:GetName())
			end


			if (not bTargetIsContestant and hCurrent and (hCurrent ~= hTarget or (hNavTarget ~= nil and hTarget ~= hNavTarget))) then
				bResetNavi = true
				AILog("reset data, target changed")
			end

			if (hTarget) then
				self:AILog(0, "Target ok (%s)", hTarget:GetName())
			end

			if (self.PRONING) then
				Bot:StopProne()
				self.PRONING = false
			end

			if (bIsContestant) then
				AILog("We got contestant instead of building !!")
				self.CURRENT_CONTESTED_TARGET = hTarget
			else
				self.CURRENT_CONTESTED_TARGET = nil
				self.CURRENT_ATTENTION_TARGET = hTarget
			end
		else
			self:AILog(0, "Reset all!")
			self.CURRENT_ATTENTION_TARGET = nil
			self.CURRENT_CONTESTED_TARGET = nil

			-- Experimental (refresh everything now and then)
			bResetNavi = true
		end

		-----
		local aLocalData = nil --self:GetLocalNavmesh() -- cpu hungry
		if (aLocalData) then
			Pathfinding:SetNavmesh(aLocalData)
		else
			Pathfinding:SetNavmesh(NAVMESH_DEFAULT)
		end

		-----
		if (not bLastResort) then
			self.LAST_RESORT_TARGET = nil
		end

		-----
		if (not timerexpired(self.LAST_ITEMS_BOUGHT_TIMER, 0.5)) then
			if (not hTarget or not self:IsContested(hTarget)) then
				self:AILog(0, "We're still buying equipment !")

				--bResetNavi = true
				iNaviSleep = 0.5
			end
		end

		-----
		if (bResetNavi) then
			BotNavigation:ResetPath()
		end
		if (iNaviSleep) then
			AILog("Setting Sleep Timer")
			BotNavigation:SetSleepTimer(0.5)
		end

		-----
		--AILog("Final target: %s", hTarget:GetName())
		return hTarget
	end,

	-----------------
	IsContested = function(self, hBuilding)
		--self:AILog(0, "%s.IsContested()", self.ModuleFullName)

		if (not self.CONTESTED_FACTORIES) then
			return false end

		if (not hBuilding) then
			return false end

		return (self.CONTESTED_FACTORIES[hBuilding.id] == true and (self:GetBuildingContestants_Greedy(hBuilding)))
	end,

	-----------------
	GetLocalNavmesh = function(self)

		self:AILog(0, "%s.GetLocalNavmesh()", self.ModuleFullName)

		local aWORLD = Pathfinding:GetWorldNavmesh()
		if (table.count(aWORLD) == 0) then
			return AILog("No world Navmesh found!!")
		end

		local aLOCALIZED = {}

		local vPos = Bot:GetPos()
		local hCurrent = self.CURRENT_ATTENTION_TARGET
		local hContestant = self.CURRENT_CONTESTED_TARGET
		local bIndoors = Bot:IsIndoors()
		local bUnderground = Bot:IsUnderground()

		----------
		--- IF indoors (a building) and in a capture radius
		--- Use local navmesh (only nearby nodes)

		local hTarget = (hContestant or hCurrent)
		if (hTarget) then

			local vCurrent = hTarget:GetPos()
			local bCurrentIsAlien = (hTarget.BUILDING_TYPE == BUILDING_ALIEN)
			local iCurrentDistance = vector.distance(vPos, vCurrent)

			if ((bIndoors or bCurrentIsAlien) and not bUnderground) then
				AILog("[LocalNavmesh] Indoors and not in tunnels OR at aliens")
				AILog("Distance to current target: %f", iCurrentDistance)
				AILog("Target is indoors: %s", string.bool(Bot:IsIndoors(vector.modifyz(vCurrent, 0.5))))
				AILog("Target is %s", hTarget:GetName())

				if (
						(iCurrentDistance < 40)
								and (Bot:IsIndoors(vector.modifyz(vCurrent, 0.5)))
				) then
					for iNode, aNode in pairs(aWORLD) do
						if (vector.distance(aNode.pos, vPos) < 120) then
							table.insert(aLOCALIZED, aNode)
						end
					end

					local iLOCALIZED = table.count(aLOCALIZED)
					if (iLOCALIZED == 0) then
						AILog("Somehow local navmesh is null !!!")
						return aLOCALIZED
					end

					AILog("Local navmesh generated with %d nodes", iLOCALIZED)
					return aLOCALIZED
				else
					AILog("Target too far or outdoors!")
				end
			end
		end
	end,

	-----------------
	PostGetAttentionPoint = function(self)
		self:AILog(0, "%s.PostGetAttentionPoint()", self.ModuleFullName)

		---------
		local vPos = g_localActor:GetPos()

		---------
		if (BotAI.PAUSE_UPDATE) then
			return
		end

		---------
		if (BotNavigation.AI_TARGET_ISSAME) then
			BotNavigation:SetSleepTimer(1)
			AILog("target is same")
		end
		if (BotNavigation.LAST_PATHGEN_FAILED) then
		end
		if (checkNumber(BotNavigation.CURRENT_PATH_GOALDIST, 999) < 2) then
			BotNavigation:SetSleepTimer(1)
			AILog("target reached")
		end
		---------
		--- Step 1. Check if proto is uncaptured
		--- Step 2. Check if there is an uncaptured spawn nearby
		---			If proto is uncaptured, and there is an uncaptured spawn, take that first
		---			Then take the prototype factory
		--- Step 3. Check for any other uncaptured building in the proto area
		---			If there are any, capture them
		---
		---
		---------

		local fPred = function(hBuilding)
			return Pathfinding:IsEntityReachable(hBuilding)
		end

		----
		local hCurrent = self.CURRENT_ATTENTION_TARGET
		local iCurrentDistance, vCurrent, bCurrentCaptured, bCurrentInCaptureRadius, bCurrentContested, bCapturingAny

		----
		local bProtoCaptured, hProto = self:IsBuildingCaptured(BUILDING_PROTO)
		local vProto = hProto:GetPos()
		local iProtoRange = 175
		local iProtoDistance = vector.distance(vPos, vProto)
		local bInProtoArea = (iProtoDistance < (iProtoRange * 1.25))
		local bNearDoors = (not table.empty(GetEntities(ENTITY_DOOR, nil, function(hDoor) return (vector.distance(hDoor:GetPos(), vPos) < 15) end)))

		----
		local hInside = self.INSIDE_CAPTURE_AREA
		local bInsideCaptured = false
		if (hInside) then
			bInsideCaptured = Bot:IsTarget_SameTeam(hInside)
		end

		----
		local hNearbySpawn = self:GetUncapturedBuilding(BUILDING_SPAWN, vProto, iProtoRange, fPred)
		local hAnyUncaptured = self:GetUncapturedBuilding(BUILDING_ANY, vProto, iProtoRange, fPred)

		----
		local bProtoContested = self:GetContestedBuilding(BUILDING_PROTO, vProto, iProtoRange, fPred)
		local hNearbyContested = self:GetContestedBuilding(BUILDING_SPAWN, vProto, iProtoRange, fPred)
		local hAnyContested = self:GetContestedBuilding(BUILDING_ANY, vProto, iProtoRange, fPred)
		--AILog("bProtoContested=%s",tostring(bProtoContested))
		--AILog("hNearbyContested=%s",tostring(hNearbyContested))
		--AILog("hAnyContested=%s",tostring(hAnyContested))

		----
		local hClosestAlien = self:GetUncapturedBuilding(BUILDING_ALIEN, vPos, 99999)
		local hClosestSpawn = self:GetUncapturedBuilding(BUILDING_SPAWN, vPos, 99999)
		local hClosestWarF = self:GetUncapturedBuilding(BUILDING_WAR, vPos, 99999)
		local hClosestSmallF = self:GetUncapturedBuilding(BUILDING_SMALL, vPos, 99999)
		local hClosestAny = self:GetUncapturedBuilding(BUILDING_ANY, vPos, 99999)

		----
		local hAnyBuilding = self:GetRandomBuilding(hCurrent)

		----
		--AILog("Closest alien: %s %f", hClosestAlien:GetName(), vector.distance(hClosestAlien:GetPos(),vPos))

		----
		local iDistanceClosestAny
		local bClosestAnyInProtoArea
		local bClosestAnyIsProto
		if (hClosestAny) then
			AILog("Closest of any type: %s", hClosestAny:GetName())
			iDistanceClosestAny = vector.distance(hClosestAny:GetPos(), vPos)
			bClosestAnyInProtoArea = (vector.distance(hClosestAny:GetPos(), vProto) < (iProtoRange * 1.25))
			bClosestAnyIsProto = (hClosestAny.BUILDING_TYPE == BUILDING_PROTO)
		end

		----
		local function fCheckProtoArea()

			if (BOT_HOSITLITY <= 0) then
				return
			end

			AILog("In proto area, checking for enemies!")
			local aProtoEnemies = GetEntities(ENTITY_PLAYER, nil, function(hPlayer)

				local vPlayer = vector.modifyz(hPlayer:GetPos(), 0.5)
				if (hPlayer.id == g_localActorId) then
					return false
				end

				if (Bot:IsDead(hPlayer) or Bot:IsSpectating(hPlayer)) then
					return
				end

				if (Bot:IsTarget_SameTeam(hPlayer)) then
					AILog("same team? %s", hPlayer:GetName())
					return false
				end

				local iDist = vector.distance(hPlayer:GetPos(), vPos)
				if (iDist > iProtoRange) then
					AILog("%f>>%f",iDist,iProtoRange)
					return false
				end

				if (not Pathfinding:IsEntityReachable(hPlayer)) then
					AILog("out of reach")
					return false
				end

				if (not Pathfinding:IsEntityOnNode(hPlayer, 35) or not Pathfinding:GetClosestVisiblePoint_Actor(hPlayer, vPlayer, nil, 30)) then
					AILog("not on node or ss of reach")
					return false
				end

				AILog("enemy spottet!!")
				return true
			end)

			if (table.empty(aProtoEnemies)) then return end
			if (table.count(aProtoEnemies) == 1) then return aProtoEnemies[1], true end
			table.sort(aProtoEnemies, fSORTBY_DISTANCE)

			return aProtoEnemies[1], true
		end

		local function fCheckProtoContestants()

			local hPotential, bIsTarget
			if (bProtoContested) then
				AILog("proto is contested, going there NOW.")
				hPotential = hProto
			elseif (hNearbyContested) then
				AILog("proto spawn is contested!")
				hPotential = hNearbyContested
			elseif (hAnyContested) then
				AILog("contested building in proto area!")
				hPotential = hAnyContested
			elseif (bInProtoArea) then
				hPotential, bIsTarget = fCheckProtoArea()
			end

			return hPotential, bIsTarget
		end

		----
		local hPotential, iPotentialDistance
		local bPotentialIsPlayer

		----
		local bCurrentAwayFromDoors = true -- are we close to doors?? (and make sure target isnt near doors as well, else GOTO SPAM AND ROTATING!!)
		local bCurrentInProtoArea
		local bCurrentIsAlien
		local bOutdoors = (not Bot:IsIndoors())

		----
		if (hCurrent) then
			vCurrent = hCurrent:GetPos()
			iCurrentDistance = vector.distance(vCurrent, vPos)
			bCurrentCaptured = self:CompareTeams(self.CURRENT_ATTENTION_TARGET, g_localActor)
			bCurrentInCaptureRadius = self:IsInCaptureRadius(self.CURRENT_ATTENTION_TARGET)
			bCurrentContested = self:IsContested(hCurrent)
			bCapturingAny = self:IsInCaptureRadius(hCurrent)
			bCurrentInProtoArea = (vector.distance(vCurrent, vProto) < (iProtoRange * 1.25))
			bCurrentIsAlien = (hCurrent.BUILDING_TYPE == BUILDING_ALIEN)

			if (bNearDoors) then
				AILog("we're near doors!")
				bCurrentAwayFromDoors = table.empty(GetEntities(ENTITY_DOOR, nil, function(hDoor) AILog(vector.distance(hDoor:GetPos(), vCurrent)) return (vector.distance(hDoor:GetPos(), vCurrent) < 10) end))
			end

			------
			--AILog("Nearby doors: $4%s", string.bool(bCurrentAwayFromDoors))
			if (not bCurrentAwayFromDoors) then

			end

			------
			AILog("Checking current target %s", hCurrent:GetName())

			------
			if (hClosestAny and hClosestAny ~= hCurrent) then
				AILog("[hClosestAny] distance = %f (any = <%f> << %f)", iCurrentDistance, iDistanceClosestAny, (iCurrentDistance / 5))
				if (not bInProtoArea and (iDistanceClosestAny and (iDistanceClosestAny < 15 or iDistanceClosestAny < (iCurrentDistance / 5)))) then
					AILog("uncaptured building at least 5 times closer was found!")
					return hClosestAny
				elseif (bInProtoArea and bClosestAnyInProtoArea and not bCurrentInProtoArea and iDistanceClosestAny < 100) then
					AILog("better building found")
					return hClosestAny
				elseif (bClosestAnyIsProto and iDistanceClosestAny < iCurrentDistance) then
					AILog("Closest is PROTO!!")
					return hClosestAny
				end
			end

			------
			if (bCurrentInCaptureRadius and not bCurrentCaptured) then

				if (not bCurrentContested) then
					if (iCurrentDistance > 8 and ((bNearDoors and bCurrentAwayFromDoors) or (bOutdoors and not bCurrentIsAlien))) then
						AILog("Getting AWAY from doors!!")
						return hCurrent
					end
					AILog("Already at target! capturing ..")
					return (0xBEEF)
				end

				AILog("Current is contested !!")
				local aContestants = self:GetBuildingContestants(hCurrent)
				if (table.size(aContestants) > 0 and timerexpired(Bot.LAST_SEEN_TIMER, 3)) then
					AILog("going to contestant")

					if (self.CURRENT_CONTESTED_TARGET) then
						return self.CURRENT_CONTESTED_TARGET, true
					end
					return aContestants[1], true
				end

				AILog("failed")
				if (self.CURRENT_CONTESTED_TARGET) then
					if (self.CURRENT_ATTENTION_TARGET) then
						return self.CURRENT_ATTENTION_TARGET
					end
				end
				return (0xBEEF)

				------
			else
				if (bInProtoArea and iCurrentDistance > iProtoRange) then
					hPotential, bPotentialIsPlayer = fCheckProtoContestants()
					if (hPotential) then
						AILog("proto area contested !!")
						return hPotential, bPotentialIsPlayer
					else
						hPotential, bPotentialIsPlayer = fCheckProtoArea()
						if (hPotential) then
							AILog("found enemy in proto area !!")
							return hPotential, bPotentialIsPlayer
						end
					end
				end

				------
				if (not bCurrentCaptured) then
					AILog("Current not captured yet !!")
					if (bCurrentInCaptureRadius) then
						return (0xBEEF)
					end
					return self.CURRENT_ATTENTION_TARGET
				end
			end
		end

		----
		if (hInside and not bInsideCaptured) then
			AILog("Already inside a buildig")
			return hInside
		end

		----
		if (not bProtoCaptured) then

			AILog("proto distance %f", iProtoDistance)
			if (hNearbySpawn and iProtoDistance > 15) then
				AILog("Found uncaptured spawn near proto!")
				return hNearbySpawn
			end
			AILog("Going to proto!")

			if (not self:CompareTeams(hProto, g_localActor)) then
				self:SendRadio(RADIO_TAKE_PROTO) end

			AILog("Taking proto")
			return hProto

			------
		elseif (hNearbySpawn and Pathfinding:IsEntityReachable(hNearbySpawn)) then
			AILog("Taking spawn near proto")
			return hNearbySpawn

			------
		elseif (hAnyUncaptured and Pathfinding:IsEntityReachable(hAnyUncaptured)) then
			AILog("found uncaptured building near proto, capturing now!")
			return hAnyUncaptured

			------
		else

			AILog("Proto and surrounding OK")

			hPotential, bPotentialIsPlayer = fCheckProtoContestants()

			if (hPotential) then
				iPotentialDistance = vector.distance(hPotential:GetPos(), vPos)
			end

			-- no target or target far far away, check proto area
			if (hPotential and (not bCapturingAny or (iCurrentDistance > iPotentialDistance))) then

				AILog("proto area in danger and current task not worth it")
				return hPotential, bPotentialIsPlayer
			else
				AILog("ignoring proto area, we're BUSY AF")
			end
		end

		---------
		AILog("[IMPLEMMETATION MISSING, USING ANY BUILDING]")
		if (hClosestAny) then
			return hClosestAny
		end


		-- LAST RESORT !!
		if (hAnyBuilding) then
			self.LAST_RESORT_TARGET = checkVar(self.LAST_RESORT_TARGET, hAnyBuilding)
			return self.LAST_RESORT_TARGET, nil, true
		end
	end,

	-----------------
	GetBuildingContestants = function(self, hBuilding)

		if (BOT_HOSITLITY <= 0) then
			return
		end

		local iCaptureRadius = 24
		local vPos = hBuilding:GetPos()

		local aPlayers = GetEntities(ENTITY_PLAYER, nil, function(hPlayer)
			if (hPlayer.id == g_localActorId) then
				return false
			end

			if (Bot:IsTarget_SameTeam(hPlayer)) then
				return false
			end

			if (hPlayer:IsDead()) then
				return false
			end

			local iDist = vector.distance(hPlayer:GetPos(), vPos)
			if (iDist > iCaptureRadius) then
				return false
			end

			if (not Pathfinding:IsEntityReachable(hPlayer)) then
				return false
			end

			if (not Pathfinding:IsEntityOnNode(hPlayer, 35)) then
				return false
			end

			return true
		end)



		if (table.empty(aPlayers)) then return end
		if (table.count(aPlayers) == 1) then return aPlayers end
		table.sort(aPlayers, fSORTBY_DISTANCE)

		return aPlayers

	end,

	-----------------
	GetBuildingContestants_Greedy = function(self, hBuilding)

		local iCaptureRadius = 40
		local vPos = hBuilding:GetPos()

		local aPlayers = GetEntities(ENTITY_PLAYER, nil, function(hPlayer)
			if (hPlayer.id == g_localActorId or Bot:IsTarget_SameTeam(hPlayer) or hPlayer:IsDead()) then
				return false
			end

			local iDist = vector.distance(hPlayer:GetPos(), vPos)
			if (iDist > iCaptureRadius) then
				return false
			end

			return true
		end)

		if (table.empty(aPlayers)) then return end
		if (table.count(aPlayers) == 1) then return aPlayers end
		table.sort(aPlayers, fSORTBY_DISTANCE)

		return aPlayers

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
	GetRandomBuilding = function(self, hExcept, fPredEx)

		---------
		local vPos = g_localActor:GetPos()
		local aBuildings = self:GetBuildingsOfType(GET_ALL, vPos)
		if (table.count(aBuildings) > 0) then
			return getrandom(aBuildings)
		end

		---------
		return
	end,

	-----------------
	IsCapturing = function(self, hCheck)

		----------
		local hInside = self.INSIDE_CAPTURE_AREA
		if (not hInside) then
			return false
		end

		if (hCheck) then
			return (hInside == hCheck)
		end

		return true

		--[[
		if (not hEntity) then
			return (not isNull(self.INSIDE_CAPTURE_AREA))
		else
			return (vector.distance(hEntity:GetPos(), g_localActor:GetPos()) < 5)
		end

		----------
		if (isNull(self.INSIDE_CAPTURE_AREA)) then
			self:AILog(0, "No in ANY AREA!!")
			return false end

		----------
		self:AILog(0, "Capture Area Id: %s", tostring(self.INSIDE_CAPTURE_AREA.id))
		return (self.INSIDE_CAPTURE_AREA.id == hEntity.id)]]
	end,

	-----------------
	IsInCaptureRadius = function(self, hBuilding, hEntity)

		if (not hBuilding) then
			return false end

		----------
		local hEntity = checkVar(GetEntity(hEntity), g_localActor)
		if (hEntity == g_localActor) then
			--self:AILog(0, "local actor check!")
			return self:IsCapturing(hBuilding)
		end

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

		if (Bot:GotCamped() and self:GoSniperShopping()) then

		elseif ((iMedium + iHeavy) < 2) then
			self:GoShopping()
		end

		if (iUtility < 2) then
			self:GoKitShopping()
		end
		if (iExplosives < 1) then
			self:GoExplosiveShopping()
		end

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
	GoSniperShopping = function(self)


		-----------
		if (not timerexpired(self.SNIPER_BUY_TIMER, 5)) then
			return true end -- check other stuff

		local bBought = false
		local aWorst = {}
		for i, nItem in (Bot:GetInventory()) do

		end

		return (not bBought)
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
	GetUncapturedBuilding = function(self, sType, vSource, iMaxDistance, fPred)
		--self:AILog(0, "%s.GetUncapturedBuilding()", self.ModuleFullName)

		---------
		local aBuildings = self:GetBuildingsOfType(sType)
		if (table.count(aBuildings) == 0) then
			--self:AILog(0, "No Buildings of type '%s' were found", sType)
			return false end

		---------
		local iMaxDistance = checkNumber(iMaxDistance, -1)
		local vSource = checkVar(vSource, g_localActor:GetPos())

		---------
		local aClosest = { nil, iMaxDistance }
		for i, hBuilding in pairs(aBuildings) do
			if (not self:CompareTeams(hBuilding, g_localActor)) then
				local iDistance = vector.distance(vSource, hBuilding:GetPos())
				if ((fPred == nil or fPred(hBuilding) == true) and (iMaxDistance == -1 or (aClosest[2] == -1 or iDistance < aClosest[2]))) then
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
	GetContestedBuilding = function(self, sType, vSource, iMaxDistance, fPred)
		--self:AILog(0, "%s.GetContestedBuilding()", self.ModuleFullName)

		---------
		local aContested = self.CONTESTED_FACTORIES
		if (table.count(aContested) == 0) then
			--self:AILog(0, "No Contested Buildings of type '%s' were found", sType)
			return false end

		---------
		local iMaxDistance = checkNumber(iMaxDistance, -1)
		local vSource = checkVar(vSource, g_localActor:GetPos())

		---------
		local aClosest = { nil, iMaxDistance }
		for idBuilding, bContested in pairs(aContested) do
			local hBuilding = GetEntity(idBuilding)
			if (bContested and table.count(self:GetBuildingContestants(hBuilding)) > 0) then
				if ((sType == GET_ALL or sType == BUILDING_ANY) or (hBuilding.BUILDING_TYPE == sType)) then
					-- ??? we want contested, regardless of team ???
					--if (not self:CompareTeams(hBuilding, g_localActor)) then
					local iDistance = vector.distance(vSource, hBuilding:GetPos())
					if ((fPred == nil or fPred(hBuilding) == true) and (iMaxDistance == -1 or (aClosest[2] == -1 or iDistance < aClosest[2]))) then
						aClosest = {
							hBuilding,
							iDistance
						}
					end
					--end
				end
			end
		end

		---------
		return aClosest[1]
	end,

	-----------------
	GetBuildingsOfType = function(self, sType)
		--self:AILog(0, "%s.GetBuildingsOfType(%s)", self.ModuleFullName, tostring(sType))

		if (sType == GET_ALL or sType == BUILDING_ANY) then
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
		--self:AILog(0, "%s.IsBuildingCaptured()", self.ModuleFullName)

		---------
		local aBuildings = self:GetBuildingsOfType(sBuilding)
		if (table.count(aBuildings) == 0) then
			--self:AILog(0, "No Buildings of type '%s' were found", sBuilding)
			return false end

		---------
		local hBuilding = aBuildings[1]
		if (isNumber(iIndex) and table.count(aBuildings) > 1) then
			hBuilding = aBuildings[iIndex] end

		---------
		if (not hBuilding) then
			--self:AILog(0, "Building Index %d out of bounds", iIndex)
			return end

		---------
		return self:CompareTeams(hBuilding, g_localActorId), hBuilding
	end,
})