BotAI:CreateServerModule(SERVER_ADDR_ALIEN, SERVER_PORT_ANY, {

    ----------
    TEMP = {},
    GAME_RULES = g_gameRules.class,
    ALIEN_HIDE_TIMER = nil,

    ----------
    ModuleName = nil,
    ModuleFullName = nil,

    ----------
    Events = {

        ----------
        OnInit = function(self)
            AILog("Alien Server Module loaded")
        end,

        ----------
        IsTargetOk = function(self)

        end,

        ----------
        OnTimer = function(self)
            AILog("Alien Server tick")

            local vPos = g_localActor:GetPos()
            if (self.GAME_RULES == "PowerStruggle") then

                local aHunters = GetEntities("Hunter")
                local bPause = false
                if (table.count(aHunters) > 0) then
                    if (Bot:IsIndoors()) then

                        for i, hHunter in pairs(aHunters) do
                            local iHP = checkNumber(hHunter.actor:GetHealth(), 0)
                            if (iHP > 0 and vector.distance(vPos, hHunter:GetPos()) < 125) then
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
                    if (not Bot:HasTarget() and not AIGetGlobal(eAI_gIsBuildingContested)) then
                        AILog("Indoors and hunter nearby!!")
                        Bot:InterruptMovement(eMovInterrupt_DangerOutside, 10)
                        Bot:StopMovement()
                    else
                        AILog("Bot Not pausing because theres ENEMIES !")
                    end
                --    self.ALIEN_HIDE_TIMER = checkVar(hTimer, timernew(7.5))
                end
            end
        end
    },
})