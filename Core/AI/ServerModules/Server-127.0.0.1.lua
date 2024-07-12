BotAI:CreateServerModule(SERVER_ADDR_LOCAL, SERVER_PORT_ANY, {

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
            AILog("Local Server Module loaded")
        end,

        ----------
        OnTick = function(self)
            AILog("Local Server tick")
        end
    },
})