----------------------------------------
-- InstantAction AI Module

BotAI:CreateAIModule("InstantAction", {

    ------
    ModuleName = nil,
    ModuleFullName = nil,

    ------
    CURRENT_TARGET = nil,
    DEFAULT_TARGETS = { -- Go here if no other target exists!
        ENTITY_SPAWNPOINT,
        WEAPON_DSG,
        WEAPON_GAUSS,
        WEAPON_HURRICANE,
        WEAPON_C4,
        WEAPON_CLAYMORE
    },

    ------
    Funcs = {},

    ------
    Events = {

        ----------
        OnTimer = function(self)

            AILog("%s.OnTimer()", self.ModuleFullName)
        end,

        ----------
        GetIdleWeapon = function(self)

            AILog("%s.GetIdleWeapon()", self.ModuleFullName)
        end,

        ----------
        OnIdleWeapon = function(self, sItem)

            AILog("%s.GetIdleWeapon()", self.ModuleFullName)
        end,

        ----------
        OnPathProbablyEnded = function(self)

            AILog("%s.OnPathProbablyEnded()", self.ModuleFullName)

            local hCurr = self.CURRENT_TARGET
            if (hCurr) then
                hCurr.GOTO_HERE = timerinit()
            end
            self.CURRENT_TARGET = nil
        end,

        ----------
        CanGoIdle = function(self)

            --AILog("%s.CanGoIdle()", self.ModuleFullName)
            return AIEVENT_OK -- !! FIXME
        end,

        ----------
        OnPathFailed = function(self)

            AILog("%s.OnPathFailed()", self.ModuleFullName)
            self.CURRENT_TARGET = nil
        end,

        ----------
        PathGoalReached = function(self)

            AILog("%s.PathGoalReached()", self.ModuleFullName)
            self.CURRENT_TARGET = nil
        end,

        ----------
        ValidateVehicle = function(self)

            -----
            --AILog("%s.ValidateTarget()", self.ModuleFullName)

            -----
           return AIEVENT_ABORT
        end,


        ----------
        ValidateTarget = function(self)

            -----
            --AILog("%s.ValidateTarget()", self.ModuleFullName)

            -----
           return AIEVENT_OK
        end,

        ----------
        OnTargetLost = function(self)

            -----
            AILog("%s.OnTargetLost()", self.ModuleFullName)
            AILog("Reset target!")

            -----
            self.CURRENT_TARGET = nil
        end,

        ----------
        OnTargetAcquired = function(self, hTarget)

            -----
            AILog("%s.OnTargetAcquired()", self.ModuleFullName)
            AILog("Reset target!")

            -----
            self.CURRENT_TARGET = nil
        end,

        ----------
        IsTargetOk = function(self, hTarget, bIsEntity)

            -----
            --- AILog("%s.IsTargetOk()", self.ModuleFullName)

            -- Nothing to do..
            return AIEVENT_OK
        end,

        ------
        Inventory_CanPlaceExplosive = function(self, hExplosive)

            local bAmmoBad = Bot:InventoryEmpty(hExplosive.class)
            if (bAmmoBad) then
                return AIEVENT_ABORT
            end

            local vPos = Bot:GetPos()
            local bOk, hAt = self:CanPlaceExplosiveOnSpot(vPos, hExplosive.class)
            if (not bOk) then
                AILog("No!1")
                return AIEVENT_ABORT -- False
            end

            local vAt = hAt:GetPos()
            local iDistance = vector.distance(vPos, vAt)
            local bVisible = (Bot:IsVisible_Entity(hAt))

            AILog("dist=%f",iDistance)

            if (iDistance > 15) then
                AILog("No!2")
                return AIEVENT_ABORT
            elseif ((iDistance < 10 and bVisible) or iDistance < 5) then
                AILog("Yes!")
                return AIEVENT_OK
            end

            AILog("No!3")
            return AIEVENT_ABORT
        end,

        ----------
        OnExplosivePlaced = function(self)

            -----
            AILog("%s.OnExplosivePlaced()", self.ModuleFullName)

            -- Nothing to do..
            self:SetAvailableExplosive(nil)
        end,

        ----------
        Inventory_FoundClaymore = function(self, hExplosive)

            -----
            AILog("%s.Inventory_FoundClaymore()", self.ModuleFullName)

            -- Nothing to do..
            self:SetAvailableExplosive(hExplosive)
        end,

        ----------
        Inventory_FoundC4 = function(self, hExplosive)

            -----
            AILog("%s.Inventory_FoundC4()", self.ModuleFullName)

            -- Nothing to do..
            -- Save C4 for vehicles? Not in IA?
            self:SetAvailableExplosive(hExplosive)
        end,

        ----------
        GetPathGoal = function(self)

            -----
            AILog("%s.GetPathGoal()", self.ModuleFullName)

            -----
            local hTarget = self:GetAttentionPoint()
            if (hTarget) then
                self.CURRENT_TARGET = hTarget
            else
                self.CURRENT_TARGET = nil
            end

            AILog("Final Target: %s", g_TS(hTarget and hTarget:GetName() or "none"))
            return hTarget
        end,

    },

    ------
    GetNewTarget = function(self)

        -----
        AILog("%s.GetNewTarget()", self.ModuleFullName)

        -----
        if (BOT_HOSITLITY <= 0) then
            return AILog("No Hositlity!") end

        -------------
        local hForced = Bot.FORCED_FOLLOW_TARGET
        if (hForced) then
            return hForced
        end

        -------------
        local aPlayers = GetEntities(ENTITY_PLAYER, nil, function(hPlayer)

            if (hPlayer.id == g_localActorId) then
                return
            end

            if (not Bot:IsAlive(hPlayer)) then
                return false
            end

            local bOk = AIEvent("IsTargetOk", hPlayer)
            if (bOk ~= AIEVENT_OK) then
                return false
            end

            if (not Pathfinding:IsEntityReachable(hPlayer)) then
                return false
            end

            return true
        end)

        -----
        table.sort(checkArray(aPlayers), fSORTBY_DISTANCE)

        -----
        return checkArray(aPlayers)
    end,

    ------
    GetNewTargetEntity = function(self)

        -----
        AILog("%s.GetNewTargetEntity()", self.ModuleFullName)

        -------------
        local hForced = Bot.FORCED_FOLLOW_TARGET
        if (hForced) then
            return hForced
        end

        local vPos = Bot:GetPos()

        -------------
        local aAvailable = self.DEFAULT_TARGETS
        local aEntities = GetEntities(GET_ALL, nil, function(hEntity)

            if (not string.matchex(hEntity.class, unpack(aAvailable))) then
                return
            end

            if (hEntity.id == g_localActorId) then
                return
            end

            local bOk = AIEvent("IsTargetOk", hEntity, true)
            if (bOk ~= AIEVENT_OK) then
                return false
            end

            if (not Pathfinding:IsEntityReachable(hEntity)) then
                return false
            end

            local iDist = vector.distance(vPos, hEntity:GetPos())
            if (iDist < 25) then
                return false
            end

            return true
        end)

        -----
        table.sort(checkArray(aEntities), fSORTBY_DISTANCE)
        return checkArray(aEntities)
    end,

    ------
    SetAvailableExplosive = function(self, hExplosive)

        local hCurrent = self:GetAvailableExplosive()
        if (hCurrent and GetEntity(hCurrent)) then
            return AILog("explosive already set..")
        end

        self.AVAILABLE_EXPLOSIVE = hExplosive
    end,

    ------
    GetAvailableExplosive = function(self, hCheck)
        if (not GetEntity(self.AVAILABLE_EXPLOSIVE)) then
            return false
        end
        return (self.AVAILABLE_EXPLOSIVE)
    end,

    ------
    CanPlaceExplosiveOnSpot = function(self, vSpot, sType, pRadius)

        if (not timerexpired(Bot.EXPLOSIVE_PLANT_TIMER, 1)) then
            return
        end
        if (not timerexpired(Bot.PICK_ITEM_TIMER, 3)) then
            return
        end

        if (sType == WEAPON_C4) then

        elseif (sType == WEAPON_CLAYMORE) then
            local iLimit = checkNumber(System.GetCVar("g_claymore_limit"), 0)
            local iPlaced = table.count(Bot:GetPlacedExplosives(sType))

            if (iPlaced >= iLimit) then
                return false, nil
            end
        end

        local iRadius = checkNumber(pRadius, 10)
        local aNearbySpawns = GetEntities(ENTITY_SPAWNPOINT, nil, function(a)
            --if (not Pathfinding:IsEntityReachable(a)) then
            --    return false
            --end
            return (vector.distance(a:GetPos(), vSpot) < iRadius)
        end)

        local iResult = table.count(aNearbySpawns)
        if (iResult == 0) then
            return false
        end
        local hNearby = aNearbySpawns[1]
        Pathfinding:Effect(hNearby:GetPos(),0.1)
        return true, hNearby
    end,

    ------
    GetAttentionPoint = function(self)

        -----
        AILog("%s.GetAttentionPoint()", self.ModuleFullName)

        -----
        local vPos = Bot:GetPos()

        -- Players
        local bTarget = Bot:HasTarget() -- useless check? ai mods ingnored during combat
        local aTargets = self:GetNewTarget()
        local hNewTarget, vTarget
        local iTargetDistance
        if (table.count(aTargets) > 0) then
            hNewTarget = aTargets[1]
            vTarget = hNewTarget:GetPos()
            iTargetDistance = vector.distance(vTarget, vPos)
        end

        -- Entities
        local hNewEntity = table.shuffle(self:GetNewTargetEntity())[1]
        local hCurrent = self.CURRENT_TARGET

        -- Inventory check
        local hExplosive = self:GetAvailableExplosive()
        local bExplosiveSpot, hExplosiveSpot = self:CanPlaceExplosiveOnSpot(vPos, self.AVAILABLE_EXPLOSIVE_TYPE)
        if (iTargetDistance) then
            bExplosiveSpot = (bExplosiveSpot and (iTargetDistance > 35))
        end

        local bCanPlaceExplosive = false
        if (hExplosive and self.Events.Inventory_CanPlaceExplosive(self, hExplosive) and (not bTarget and bExplosiveSpot)) then

            AILog("Could place explosive!")
            bCanPlaceExplosive = true
            return hExplosiveSpot
        end

        if (hCurrent and GetEntity(hCurrent)) then

            -----
            local bCurrentReachable = Pathfinding:IsEntityReachable(hCurrent)
            local bCurrentIsPlayer = (hCurrent.actor ~= nil)
            local bCurrentSpectating = false
            if (bCurrentIsPlayer) then
                bCurrentSpectating = Bot:IsSpectating(hCurrent)
            end
            local iCurrentDistance = vector.distance(hCurrent:GetPos(), vPos)
            if (iCurrentDistance < 3 or not timerexpired(hCurrent.GOTO_HERE, 60)) then
                hCurrent = nil
            end

            -----
            if (hCurrent) then
                if (not bCurrentIsPlayer and hNewTarget) then
                    AILog("Current is non player but found new player! switching")
                    return hNewTarget
                end

                -----
                if (bCurrentReachable and not bCurrentSpectating) then
                    AILog("Current target is OK!")
                    return hCurrent
                end

                -----
                AILog("Current target not ok!")
                return hCurrent
            end
        end

        if (hNewTarget) then
            AILog("Going to new target")
            return hNewTarget
        end

        AILog("No other target found!")

        if (hNewEntity) then
            AILog("Going to new entity")
            return hNewEntity
        end

        AILog("NO ENTITY FOUND, WTF!")

        --[[
        if (bPlayer and not bRetry) then
            self:GetNewPath(nil, true, true)
        end
        local aTarget = self:GetClosestAlivePlayer()

        if (not bAITarget) then
            if (not bTarget and aTarget and not self:WasEntityUnreachable(aTarget) and aTarget.id ~= g_localActorId) then
                hTarget = aTarget
                bPlayer = true
                NaviLog("$4target now selected by NAVVI !!")
            end
        end

        --BotMainLog("target=%s",tostring(aTarget))

        -----------
        -- !! TODO: Move to ai modules
        --if (hTarget and hTarget.actor and vector.distance(hTarget:GetPos(), Bot:GetPos()) < 3.5 and Bot:IsVisible(hTarget) and table.count(GetPlayers()) == 2) then
        --	--self:SetSleepTimer(0.5)
        --	NaviLog("SLeeping")
        --	--return -- ??? WTF IS THIS ??
        --end

        -----------
        -- self:Log(0, "Update Env ??")
        if (not self.SPAWNPOINT_ENVIRONMENT or (self.SPAWNPOINT_ENVIRONMENT[1] + 1) > self.SPAWNPOINT_ENVIRONMENT[2]) then
            self:Log(0, "Refresh Env ??")
            self:ClearPathGoalEnvironemnt(sTargetsClass)
        end


        ----------------
        local aTarget = self:GetClosestAlivePlayer()
        if (timerexpired(self.IGNORE_IDLE_PLAYERS_TIMER, 1)) then
            if (not self.CURRENT_PATH_IGNOREPLAYERS and aTarget ~= nil and (self.CURRENT_PATH_ISPLAYER and self:CheckIfPlayerMoved(self.CURRENT_PATH_GOAL, self.CURRENT_PATH_TARGET))) then
                if (self.CURRENT_PATH_TARGET ~= aTarget) then
                    --self:Log(0, "Found alive player. stopping idle path and going to player !!")
                    if (vector.distance(aTarget:GetPos(), Bot:GetPos()) > 3.5) then
                        self:GetNewPath(aTarget, false)
                    else
                        NaviLog("sleeping")
                        self:SetSleepTimer(0.5)
                        return -- ???
                    end
                    --elseif (self.CURRENT_PATH_TARGET) then
                    --BotMainLog("new PAT EBCAUSE IT MOVED !!")
                    --	self:GetNewPath(aTarget, false)
                end
            end
        end

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
        if (hTarget) then
            NaviLog("Current target is %s, asking AI for new one..", hTarget:GetName())
        end
        --]]

    end,
})