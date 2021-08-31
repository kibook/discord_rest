--- Discord REST API export functions

local discordRest = DiscordRest:new()

--- Delete a message from a channel.
-- @function exports.discord_rest:deleteMessage
-- @param channelId The ID of the channel.
-- @param messageId The ID of the message.
-- @param botToken Bot token to use for authorization.
-- @return A new promise.
exports("deleteMessage", function(channelId, messageId, botToken)
	return discordRest:deleteMessage(channelId, messageId, botToken)
end)

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

--- Get user information.
-- @function exports.discord_rest:getUser
-- @param userId The ID of the user.
-- @param botToken Bot token to use for authorization.
-- @return A new promise.
exports("getUser", function(userId, botToken)
	return discordRest:getUser(userId, botToken)
end)

--- Perform a custom HTTP request to the Discord REST API, while still respecting the rate limit.
-- @function exports.discord_rest:performHttpRequest
-- @param url The endpoint of the API to request.
-- @param callback An optional callback function to execute when the response is received.
-- @param method The HTTP method of the request.
-- @param data Data to send in the body of the request.
-- @param headers The HTTP headers of the request.
-- @usage exports.discord_rest:performHttpRequest("https://discord.com/api/channels/[channel ID]/messages/[message ID]", nil, "DELETE", "", {["Authorization"] = "Bot [bot token]"})
exports("performHttpRequest", function(url, callback, method, data, headers)
	discordRest:performHttpRequest(url, callback, method, data, headers)
end)
