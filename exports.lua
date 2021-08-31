--- Discord REST API export functions

local discordRest = DiscordRest:new()

--- Execute a webhook.
-- @function exports.discord_rest:executeWebhook
-- @param url The webhook URL.
-- @param data The data to send.
-- @return A new promise.
-- @usage exports.discord_rest:executeWebhook("https://discord.com/api/webhooks/[webhook ID]/[webhook token]", {content = "Hello, world!"})
exports("executeWebhook", function(url, data)
	return discordRest:executeWebhook(url, data)
end)

--- Get messages from a channel.
-- @function exports.discord_rest:getChannelMessages
-- @param channelId The ID of the channel.
-- @param options Options to tailor the query.
-- @param botToken Bot token to use for authorization.
-- @return A new promise.
exports("getChannelMessages", function(channelId, options, botToken)
	return discordRest:getChannelMessages(channelId, options, botToken)
end)

--- Delete a message from a channel.
-- @function exports.discord_rest:deleteMessage
-- @param channelId The ID of the channel.
-- @param messageId The ID of the message.
-- @param botToken Bot token to use for authorization.
-- @return A new promise.
exports("deleteMessage", function(channelId, messageId, botToken)
	return discordRest:deleteMessage(channelId, messageId, botToken)
end)

--- Get user information.
-- @function exports.discord_rest:getUser
-- @param userId The ID of the user.
-- @param botToken Bot token to use for authorization.
-- @return A new promise.
exports("getUser", function(userId, botToken)
	return discordRest:getUser(userId, botToken)
end)
