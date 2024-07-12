BotAI:CreateServerModule(SERVER_ADDR_ALIEN, SERVER_PORT_ANY, {

    ----------
    TEMP = {},
    GAME_RULES = g_gameRules.class,

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

            if (self.GAME_RULES == "PowerStruggle") then

                local aHunters = GetEntities("Hunter")
                local bPause = false
                if (table.count(aHunters) > 0) then
                    if (Bot:IsIndoors()) then

                        for i, hHunter in pairs(aHunters) do
                            if (vector.distance(vPos, hHunter:GetPos()) < 80) then
                                bPause = true
                            end
                        end

                    end
                end

                if (bPause) then
                    AILog("Indoors and hunter nearby!!")
                    Bot:InterruptMovement(eMovInterrupt_DangerOutside, 10)
                    Bot:StopMovement()
                end
            end
        end
    },
})