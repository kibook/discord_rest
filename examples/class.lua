local discord = DiscordRest:new("[bot token]")

local channelId = "[channel ID]"
discord:getChannelMessages(channelId, {limit = 1}):next(function(messages)
        print("Last message was by " .. messages[1].author.username .. ": " .. message[1].content)
end, function(errorCode)
        print("Failed to get messages (" .. errorCode .. ")")
end)

local userId = "[user ID]"
discord:getUser(userId):next(function(user)
        print(userId .. " = " .. user.username)
end, function(errorCode)
        print("Failed to get user info (" .. errorCode .. ")")
end)
