local botToken = "[bot token]"

exports.discord_rest:executeWebhook("https://discord.com/api/[webhook ID]/[webhook token]", {content = "Hello, world!"}):next(function()
        print("Webhook executed successfully")
end, function(errorCode)
        print("Webhook did not execute successfully (" .. errorCode .. ")")
end)

local channelId = "[channel ID]"
exports.discord_rest:getChannelMessages(channelId, {limit = 1}, botToken):next(function(messages)
        print("Last message was by " .. messages[1].author.username .. ": " .. message[1].content)
end, function(errorCode)
        print("Failed to get messages (" .. errorCode .. ")")
end)

local userId = "[user ID]"
exports.discord_rest:getUser(userId, botToken):next(function(user)
        print(userId .. " = " .. user.username)
end, function(errorCode)
        print("Failed to get user info (" .. errorCode .. ")")
end)
