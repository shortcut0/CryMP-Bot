--------------------------------------------------
---
--- File: Chat.lua
---
--- Authors: Marisa
---
--- Description: The Main Chat & Response System for the CryMP-Bot Project
---
--------------------------------------------------

---------
BotChatAI = {}

BotChatAI.Services = {}
BotChatAI.CurrentService = nil
BotChatAI.CurrentServicePath = nil
BotChatAI.DefaultFunctions = {
    "Resolve"
}

---------

BotChatAI.IGNORED_USERS = {}
BotChatAI.TASK_QUEUE = {}
BotChatAI.BOT_MENTIONS = {}
BotChatAI.SLEEP_TIMER = nil

---------

CHAT_SERVICE_ANY = -1
CHAT_ACTIVE_SERVICE = CHAT_SERVICE_ANY -- Any

---------

CHAT_REPLY_SYSTEM = 0
CHAT_REPLY_ENGINE = 1
CHAT_REPLY_USER = 2

CHAT_SYSTEM_ENABLED = checkGlobal("CHAT_SYSTEM_ENABLED", 0, checkNumber)

---------

CHAT_LOG_PREFIX = "$9[$6ChatSystem$9] "
CHAT_WARNING_LOG_PREFIX = "$9[$6ChatSystem$9] $6Warning: $9"
CHAT_ERROR_LOG_PREFIX = "$9[$6ChatSystem$9] $4Error: $9"

---------
ChatLog = function(sMsg, ...)
    SystemLog(string.formatex(CHAT_LOG_PREFIX .. (sMsg or ""), ...))
end

---------
ChatLogWarning = function(sMsg, ...)
    SystemLog(string.formatex(CHAT_WARNING_LOG_PREFIX .. (sMsg or ""), ...))
end

---------
ChatLogError = function(sMsg, ...)
    SystemLog(string.formatex(CHAT_ERROR_LOG_PREFIX .. (sMsg or ""), ...))
end

---------
BotChatAI.Init = function(self)

    -- Log
    ChatLog("Initialiting Chat System..")

    -- Init CVars
    self:InitCVars()

    -- Load Services
    self:LoadServices()

    -----
    self:SetActiveService(CHAT_ACTIVE_SERVICE)

    -- Log
    ChatLog("Initialization Finished!")
end

---------
BotChatAI.InitCVars = function()

    ------
    local sPrefix = "chatai_"
    local aCVars = {
        { "enabled", "CHAT_SYSTEM_ENABLED", CHAT_SYSTEM_ENABLED, "no description", nil, true}
    }

    local aCommands = {
        { "init",       		"BotChatAI:Init()",		"Re-initializes the Bot Chat AI System" },
        { "reloadfile", 		"BotAI:LoadChatAI()",		"Reloads the Chat AI Library" },
        { "test_message", 		"BotAI.ChatEvent(CHAT_REPLY_USER, {Message='Hello!',Type=ChatToAll,UserId=Bot.id})",		"Simulates a chat message" },
    }

    ---------------------
    local AddCommand = System.AddCCommand

    ------
    local sName, sFunc, sGlobal, pDefault, sDesc, fCallback, bNumber
    for i, aInfo in pairs (aCommands) do
        sName = aInfo[1]
        sFunc = aInfo[2]
        sDesc = aInfo[3]

        AddCommand(sPrefix .. sName, sFunc, (sDesc or "No Description"))
    end

    ------
    for i, aInfo in pairs (aCVars) do
        sName 	  = aInfo[1]
        sGlobal	  = aInfo[2]
        pDefault  = aInfo[3]
        sDesc 	  = aInfo[4]
        fCallback = aInfo[5]
        bNumber	  = aInfo[6]

        AddCVar((sPrefix .. sName), checkString(sDesc, "<No Description>"), pDefault, isNumber(pDefault) or bNumber, sGlobal, fCallback)
    end

    ------
    ChatLog("Registered %d New Console Commands", table.count(aCVars) + table.count(aCommands))
    return true

end

---------
BotChatAI.LoadServices = function(self)

    -- Log
    ChatLog("Loading Services..")

    -- Load Services
    local sServicePath = CRYMP_BOT_ROOT .. "\\Core\\AI\\Chat\\Services\\"
    local aModuleFiles = System.ScanDirectory("..\\" .. sServicePath, SCANDIR_FILES)

    ----
    if (table.count(aModuleFiles) == 0) then
        ChatLogWarning("No Chat Services found in '%s'", sServicePath)
        return true
    end

    ----
    local iLoadedFiles = 0
    for i, sFile in pairs(aModuleFiles) do

        self.CurrentServicePath = sFile

        local sPath = string.format("%s%s", sServicePath, sFile)
        local bOk, hService = BotMain:LoadFile(sPath)
        if (not bOk) then
            ChatLog("Failed to Load Chat Service '%s' (%s)", sPath, (hService or "<No error info>"))
        else
            iLoadedFiles = iLoadedFiles + 1
        end
    end

    -- Log
    ChatLog("%d Services Loaded!", iLoadedFiles)
end

---------
BotChatAI.GetServiceCount = function(self)
    return (table.count(self.Services))
end

---------
BotChatAI.GetActiveService = function(self)
    return (self.CurrentService)
end

---------
BotChatAI.SetActiveService = function(self, sName)

    ChatLog("Switching Service..")

    local aServices = self.Services
    if (table.count(aServices) == 0) then

        ChatLogError("No Loaded Services were Found!")
        self.CurrentService = nil

        return
    end


    if (sName == CHAT_SERVICE_ANY) then
        sName = table.lasti(aServices)
    end
    local hSvc = self.Services[sName]
    if (not hSvc) then
        ChatLogError("Service '%s' Was not Found!", sName)
        return
    end

    ChatLog("Service '%s' Was Activated", sName)
    self.CurrentService = hSvc
end

---------
BotChatAI.CreateService = function(self, sName, aParams)

    if (not sName) then
        sName = string.format("Service_%d", (self:GetServiceCount() + 1))
    end

    -- Log
    ChatLog("Creating Service %s", sName)

    if (not aParams) then
        ChatLogError("No Service Params provided!")
        return false
    end

    if (not isArray(aParams)) then
        ChatLogError("Service Params not an Array!")
        return false
    end

    -- Create Defaults
    for _, sDefault in pairs(self.DefaultFunctions) do
        if (aParams[sDefault] == nil) then
            aParams[sDefault] = GetErrorDummy()
        end
    end

    ----
    aParams.ServiceName = sName
    aParams.ServiceFullName = string.format("BotChatAI.%s", sName)
    aParams.ServiceFilePath = checkString(self.CurrentServicePath, "<Unresolved>")

    aParams.NetGet = self.NetGet
    aParams.NetPost = self.NetPost

    aParams.AddTask = self.AddTask

    aParams.CanReply = self.CanReply
    aParams.CanSendMessage = self.CanSendMessage

    ----
    self.Services[sName] = aParams
    if (aParams.Init) then
        aParams.Init(aParams)
    end

    ----
    ChatLog("New Service Created!")
end

---------
BotChatAI.NetPOST = function(sURL, aHeaders, sBody, iType)

    ChatLog("NetPOST()")
    ChatLog(" URL: %s",g_ts(sURL))
    ChatLog(" Headers: %s",g_ts(aHeaders))
    ChatLog(" Body: %s",g_ts(sBody))
    CPPAPI.Request({
        url = sURL,
        body = sBody,
        method = "POST",
        headers = aHeaders,
    }, function(error, response, code)
        ChatLog("Zesz zesz ")
        BotChatAI.OnReply(iType, error, response, code)
    end)
end

---------
BotChatAI.NetGET = function(sURL, aHeaders, sBody, iType)
end

---------
BotChatAI.AddTask = function(iType, aData, sURL, aHeaders, sBody)
    table.insert(BotChatAI.TASK_QUEUE, {
        Type = iType,
        URL = sURL,
        Headers = aHeaders,
        Body = sBody,
        Data = aData,
        Finished = false
    })
end

---------
BotChatAI.RemoveTask = function(iId)
    table.remove(BotChatAI.TASK_QUEUE, iId)
end

---------
BotChatAI.FinishTask = function(iId)
    if (not BotChatAI.TASK_QUEUE[iId]) then
        return
    end

    BotChatAI.TASK_QUEUE[iId].Finished = true
    BotChatAI.TASK_QUEUE[iId].FinishTimer = timernew(getrandom(3, 6))
end

---------
BotChatAI.UpdateTasks = function(self)
    local aQueue = self.TASK_QUEUE
    if (table.empty(aQueue)) then
        return
    end

    local aCurrentTask = aQueue[1]
    if (not isArray(aCurrentTask)) then
        self.RemoveTask(1)
        self.UpdateTasks()
        return
    end

    if (aCurrentTask.Finished) then

        if (aCurrentTask.FinishTimer.expired()) then
            ChatLog("Task 1 now finished")
            self.RemoveTask(1)
            self:UpdateTasks()
        end
        return
    end

    if (aCurrentTask.Active ~= true) then

        ChatLog("Task 1 now active")
        aCurrentTask.Active = true
        aCurrentTask.Finished = false
        self.NetPOST(aCurrentTask.URL, aCurrentTask.Headers, aCurrentTask.Body, aCurrentTask.Type)
    end
end

---------
BotChatAI.OnReply = function(iType, sError, sResponse, iCode)

    -- Log
   -- ChatLog("OnReply")
   -- ChatLog("iType = %s",g_ts(iType))
   -- ChatLog("sError = %s",g_ts(sError))
   -- ChatLog("sResponse = %s",g_ts(sResponse))
   -- ChatLog("iCode = %s",g_ts(iCode))

    -- Finish task
    local aTask = BotChatAI.TASK_QUEUE[1]
    if (not aTask) then
        return
    end

    BotChatAI.FinishTask(1)

    ------
    if (iCode ~= 200) then
        ChatLogError("Type (%d) failed with Code %d (%s)", checkNumber(iType, -1), checkNumber(iCode, -1), g_ts(sError))
        ChatLogError("%s", sResponse)
        return
    end

    local aJSON = json.decode(sResponse)
    if (aJSON.error ~= nil) then
        ChatLogError("Type (%d) received a response, but it failed with error (%s)", checkNumber(iType, -1), g_ts(sError))
        return
    end

    local aReply = {
        Response = aJSON,
        Context = aTask.Data,
    }
    BotChatAI.ChatEvent(iType, aReply)
end

---------
BotChatAI.ChatEvent = function(iType, aReply)

    local hService = BotChatAI:GetActiveService()
    if (not hService) then
        return
    end

    hService:OnReply(iType, aReply)
end

---------
BotChatAI.OnChatMessage = function(...)

    local hService = BotChatAI:GetActiveService()
    if (not hService) then
        return ChatLogWarning("No service found")
    end

    local hSleep = BotChatAI.SLEEP_TIMER
    if (hSleep and not hSleep.expired()) then
        return ChatLogWarning("Sleep timer not expired (%fs left)", hSleep.expires())
    end

    hService:OnChatMessage(...)
end

---------
BotChatAI.SetSleepTimer = function(self, iTime)
    self.SLEEP_TIMER = timernew(iTime)
end

---------
BotChatAI.CanSendMessage = function(self, sMessage)

    if (BotChatAI.IsExposing(sMessage)) then
        return false
    end

    if (BOT_ENABLED <= 0) then
       -- return false
    end

    return true
end


---------
BotChatAI.IsExposing = function(sMessage)
    return (string.matchex(string.lower(sMessage),
        "as an ai",
        "i cannot assist",
        "against my guidelines",
        "my programming",
        "i cannot help you",

        "%[ignored%]"
    ))
end

---------
BotChatAI.ForceReply = function(hUser, sMessage)

    local bSpecial = string.matchex(string.lower(sMessage),
        "hi",
        "hello",
        "hey",
        "moin",
        "hola",
        "privet",


        -----
        "hacker",
            "cheater",
            "cheat",
            "hack",
            "aimbot"

    )

    if (not bSpecial) then
        return false
    end

    if (bSpecial) then
        if (hUser.SENT_SPECIAL_MESSAGE) then
            return false
        end

        hUser.SENT_SPECIAL_MESSAGE = timernew(320)
    end

    return true
end

---------
BotChatAI.CanReply = function(self, hUser, sMessage)

    if (CHAT_SYSTEM_ENABLED <= 0) then
        ChatLog("System offline")
        return false
    end

    local iThreshold = 3
    if (BOT_DEBUG_MODE and hUser:GetName() ~= "ahhhh") then
        --return ChatLog("debug name invalid")
        iThreshold = 1
    end

    if (hUser.id == Bot.id) then
        return false
    end

    if (BotChatAI.IsServerEntity(hUser)) then
        if (BotChatAI.IsMuted(sMessage)) then
            BotChatAI.SetSleepTimer(60)
        else
            ChatLog("Unresolved Server Reply (%s)", sMessage)
        end
        return false
    end

    if (BotChatAI.IsBeingIgnored(hUser)) then
        ChatLo("Ignored!")
        return false
    end

    if (not BotChatAI.ForceReply(hUser, sMessage)) then
        if (not BotChatAI.WasBotMentioned(sMessage, iThreshold)) then
            ChatLog("We havent been mentioned.")
            return false
        end
    else
        ChatLog("special message.")
    end

    return true
end

---------
BotChatAI.WasBotMentioned = function(sMessage, iThreshold)
    local sName = g_localActor:GetName()
    local iLen = string.len(sName)
    local bMentioned = false
    for i = (iLen - 5), iLen do
        --ChatLog("check: %s",string.sub(sName, 1, iLen))
        if (string.find(sName, string.escape(string.sub(sName, i, iLen)))) then
            bMentioned = true
            break
        end
    end

    table.insert(BotChatAI.BOT_MENTIONS, { Timer = timernew(60), Mentioned = bMentioned })

    if (bMentioned) then
        return true
    end

    local iLast = BotChatAI.GetLastMention()
    if (iLast == -1) then
        return false
    end

    ChatLog("mention: %d",iLast)
    return (iLast < iThreshold)
end

---------
BotChatAI.GetLastMention = function()

    local aMentions = BotChatAI.BOT_MENTIONS
    local iMentions = table.count(aMentions)
    local iLast = 0

    for i = iMentions, 1, -1 do
        if (aMentions[i].Mentioned and not aMentions[i].Timer.expired()) then
            if (iLast == 0) then
                iLast = -1 -- never
            end
            break
        else
            iLast = (iLast + 1)
        end
    end

    if (iLast == iMentions) then
        return -1 -- never
    end
    return iLast
end

---------
BotChatAI.IsMuted = function(sMessage)
    return (string.matchex(string.lower(sMessage),
        "you are muted",
        "you have been muted",
        "banned from chat",
        "muted for .*"
    ))
end

---------
BotChatAI.IsServerEntity = function(hUser)

    local hActor = hUser.actor
    if (not hActor) then
        return true
    end

    return (not hActor:IsPlayer())
end

---------
BotChatAI.IsBeingIgnored = function(hUser)

    local aIgnoredUsers = BotChatAI.IGNORED_USERS
    local aCase = aIgnoredUsers[hUser.id]

    if (not aCase) then
        return false
    end

    return (aCase.Timer.expired())
end
