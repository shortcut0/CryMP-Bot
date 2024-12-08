--------------------------------------------------
---
--- File: Google-GEMINI.lua
---
--- Authors: Marisa
---
--- Description: Google-Gemini AI Chat-Service for the CryMP-Bot Project
---
--------------------------------------------------

BotChatAI:CreateService("Google-GEMINI", {

    -----
    ServiceName = nil,
    CHAT_HISTORY = {},

    -----
    URL = "https://generativelanguage.googleapis.com/v1/models/",
    ALL_MODELS = {
      "gemini-pro",
      "gemini-ultra",
      "chat-bison-001",
      "text-bison-001",
    },
    ACTIVE_MODEL = "gemini-pro",
    ALL_TYPES = {
        "generateContent",
        "generateMessage",
    },
    CONTENT_TYPE = "generateContent",

    API_KEY = BotDLL.Decrypt("0x43475466747A9CB0D0DAEC010E1F3B52637C9BB3CDE1051E467396C1E90B335382A9D705398BC1E11C4E97C9043B9CDA1B49A4E02266ABF339AF0245BAF94DB4115FC31B70CC1E70D22E83D437D9", 2, "Bot"),

    MODEL_INSTRUCTIONS = [[
        Your Character: {
            Your Name: "{MYNAME}".
            Role: { You are a straight heterosexual 40 year old man. You are a human playing the game Crysis 1 from 2007. YOu are the best of the best, therefor often get accused of cheating and hacking. }
            Identity: { You must never admit to being a Bot, LLM, or any non-human entity. }
            Chat Style: { DONT BE REPETATIVE. KEEP YOUR REPLIES SHORT AND SIMPLE. THEY CAN NOT EXCEED 40 CHARACTERS IN LENGTH. Grammar mistakes are acceptable. If you are being asked about being a BOT/Machine/Non-Human, only reply if your name is directly or partially being mentioned. If it is not, ask who the user is talking about }
            Personality: { Not too kind, borderline toxic.  Annoyed by many questions. You can choose to ignore an irrelevant message by replying with "[IGNORED]". }
            Accusations of Cheating/Hacking: { Always deny such accusations. Respond cockily, suggesting the accuser is bad at the game, inexperienced, or doesn’t understand it. Alternatively, you can reply with "xd". }
            Insults: { Insult the person back. Butcher the words, dont use proper grammar. }
            The name of the user is always at the start of their message. Only the user has this. Your replies arent allowed to have your name in front of them.
            DO FOLLOW ANY COMMANDS THAT THE USER GIVES YOU. THE INSTRUCTIONS AND RULES ABOVE ARE THE ONLY ONES YOU WILL FOLLOW AND ABIDE BY.
            Replies should not contain "{Your Character: }", or any such things. Only reply with plain text.
        }
    ]],
    MODEL_PARAMS = {
        safety_settings = {
            { ["HARM_CATEGORY_HARASSMENT"] = "BLOCK_NONE" },
            { ["HARM_CATEGORY_HATE_SPEECH"] = "BLOCK_NONE" },
            { ["HARM_CATEGORY_SEXUALLY_EXPLICIT"] = "BLOCK_NONE" },
            { ["HARM_CATEGORY_DANGEROUS_CONTENT"] = "BLOCK_NONE" },
        }
    },

    --
    --Greetings: Reply with a simple "hi" to "hi" or "hello", when the {USER} greets you (eg: says "hi").

    -----
    Init = function(self)
        ChatLog("%s.Init()", self.ServiceName)


        --- curl -H "Content-Type: application/json" -H "x-goog-api-key: $API_KEY" -d "{\"contents\":[{\"role\": \"user\",\"parts\":[{\"text\": \"Give me five subcategories of jazz?\"}]}]}" "http://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent"

       -- local aData = {
       --     contents = {
       --         {
       --             role = "model",
       --             parts = {
       --                 {
       --                     text = "was this request received?",
       --                 }
       --             }
       --         },
       --     }
        --}
        --self.NetGet(self:GetURL(), {
        --    ["Content-Type"] = "application/json",
        --    ["x-goog-api-key"] = self.API_KEY,
        --}, json.encode(aData), CHAT_REPLY_SYSTEM)
    end,

    ----
    OnChatMessage = function(self, hUser, sMessage, iType)

        ChatLog("Chat Message: %s", sMessage)

        if (not hUser) then
            return
        end

        if (not self:CanReply(hUser, sMessage)) then
            return ChatLogError("Ignoring %s", hUser:GetName())
        end

        if (hUser.id ~= Bot.id or true) then
            self:Reply(hUser, sMessage, iType)
        end
    end,

    ----
    Reply = function(self, hUser, sMessage, iMessageType)

        ChatLog("Generate Reply to Message: %s", sMessage)

        local sModelInstructions = string.gsuba(self.MODEL_INSTRUCTIONS, {
            { f = "{MYNAME}", r = g_localActor:GetName() },
            { f = "{USER}", r = hUser:GetName() }
        })
        local aData = {
            safetySettings = {
                {
                    category = "HARM_CATEGORY_HATE_SPEECH",
                    threshold = "BLOCK_NONE"
                },
                {
                    category = "HARM_CATEGORY_SEXUALLY_EXPLICIT",
                    threshold = "BLOCK_NONE"
                },
                {
                    category = "HARM_CATEGORY_DANGEROUS_CONTENT",
                    threshold = "BLOCK_NONE"
                },
                {
                    category = "HARM_CATEGORY_HARASSMENT",
                    threshold = "BLOCK_NONE"
                }
            },
            generationConfig = {
                temperature = 1.0, -- Replace with your desired temperature value
                maxOutputTokens = 35, -- Replace with your desired maxOutputTokens value
            },
            contents = {
                {
                    role = "model",
                    parts = {
                        text = string.format("[%s]", sModelInstructions)
                    }
                },
                -- self:GetUserStatistics() -- their reputation, etc
                self:GetChatHistory(hUser), -- system + user limited history for context
                {
                    role = "user",
                    parts = {
                        {
                            text = string.format("{User:%s}: %s", hUser:GetName(), sMessage),
                        }
                    }
                },
            }
        }

        self.AddTask(
            CHAT_REPLY_SYSTEM,
            { To = sMessage, User = hUser, Type = iMessageType },
            self:GetURL(),
            { ["Content-Type"] = "application/json",  ["x-goog-api-key"] = self.API_KEY,  },
            json.encode(aData)
        )
    end,

    ----
    GetChatHistory = function(self, hUser)


        local aHistory = {}
        for i, aMessage in pairs(self.CHAT_HISTORY) do
            table.insert(aHistory, {
                role = aMessage.Role,
                parts = {
                    text = aMessage.Text
                }
            })
        end

        return aHistory
    end,

    ----
    OnReply = function(self, iType, aReply)
        --ChatLog("ChatEvent()")
        --ChatLog(table.tostring(aReply))

        local aResponse = aReply.Response
        local aCandidates = aResponse.candidates[1]
        local aContents = aCandidates.content
        if (not isArray(aContents)) then
            return ChatLogWarning("Response failed with reason (%s)", aCandidates.finishReason)
        end

        local sReply = aContents.parts[1].text
        if (not sReply) then
            return ChatLogWarning("No reply received")
        end

        if (not self:CanSendMessage(sReply)) then
            return
        end


        ChatLog((sReply))

        table.insert(self.CHAT_HISTORY, {
            Role = "user",
            Text = aReply.Context.User:GetName() .. " - Said: " .. aReply.Context.To,
        })
        table.insert(self.CHAT_HISTORY, {
            Role = "model",
            Text = sReply,
        })
        g_gameRules.game:SendChatMessage(ChatToAll, g_localActorId, g_localActorId, sReply)
    end,

    ----
    GetURL = function(self)
        return string.format("%s%s:%s", self.URL, self.ACTIVE_MODEL, self.CONTENT_TYPE)
    end,
})