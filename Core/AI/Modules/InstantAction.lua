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
        WEAPON_HURRICANE
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
        OnPathProbablyEnded = function(self)

            AILog("%s.OnPathProbablyEnded()", self.ModuleFullName)
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
        OnTargetAquired = function(self, hTarget)

            -----
            AILog("%s.OnTargetAquired()", self.ModuleFullName)
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

            return true
        end)

        -----
        table.sort(checkArray(aEntities), fSORTBY_DISTANCE)
        return checkArray(aEntities)
    end,

    ------
    GetAttentionPoint = function(self)

        -----
        AILog("%s.GetAttentionPoint()", self.ModuleFullName)

        -----
        local aTargets = self:GetNewTarget()
        local hNewTarget
        if (table.count(aTargets) > 0) then
            hNewTarget = aTargets[1]
        end
        local hNewEntity = table.shuffle(self:GetNewTargetEntity())[1]
        local hCurrent = self.CURRENT_TARGET

        if (hCurrent and GetEntity(hCurrent)) then

            -----
            local bCurrentReachable = Pathfinding:IsEntityReachable(hCurrent)
            local bCurrentIsPlayer = (hCurrent.actor ~= nil)
            local bCurrentSpectating = false
            if (bCurrentIsPlayer) then
                bCurrentSpectating = Bot:IsSpectating(hCurrent)
            end

            -----
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