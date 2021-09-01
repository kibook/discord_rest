--- Discord REST API export functions

local discordRest = DiscordRest:new()

--- Post a message.
-- @function createMessage
-- @param channelId The ID of the channel to post in.
-- @param message The message parameters.
-- @param botToken Bot token to use for authorization.
-- @return A new promise which is resolved when the message is posted.
-- @usage exports.discord_rest:createMessage("[channel ID]", {content = "Hello, world!"}, "[bot token]")
exports("createMessage", function(channelId, message, botToken)
	return discordRest:createMessage(channelId, message, botToken)
end)

--- Create a reaction for a message.
-- @function createReaction
-- @param channelId The ID of the channel containing the message.
-- @param messageId The ID of the message to add a reaction to.
-- @param emoji The name of the emoji to react with.
-- @param botToken Bot token to use for authorization.
-- @return A new promise which is resolved when the reaction is added to the message.
-- @usage exports.discord_rest:createReaction("[channel ID]", "[message ID]", "💗", "[bot token]")
exports("createReaction", function(channelId, messageId, emoji, botToken)
	return discordRest:createReaction(channelId, messageId, emoji, botToken)
end)

--- Delete a channel.
-- @function deleteChannel
-- @param channelId The ID of the channel.
-- @param botToken Bot token to use for authorization.
-- @return A new promise.
-- @usage exports.discord_rest:deleteChannel("[channel ID]", "[bot token]")
exports("deleteChannel", function(channelId, botToken)
	return discordRest:deleteChannel(channelId, botToken)
end)

--- Delete a message from a channel.
-- @function deleteMessage
-- @param channelId The ID of the channel.
-- @param messageId The ID of the message.
-- @param botToken Bot token to use for authorization.
-- @return A new promise.
-- @usage exports.discord_rest:deleteMessage("[channel ID]", "[message ID]", "[bot token]")
exports("deleteMessage", function(channelId, messageId, botToken)
	return discordRest:deleteMessage(channelId, messageId, botToken)
end)

--- Remove own reaction from a message.
-- @function deleteOwnReaction
-- @param channelId The ID of the channel containing the message.
-- @param messageId The ID of the message to remove the reaction from.
-- @param emoji The emoji of the reaction to remove.
-- @param botToken Bot token to use for authorization.
-- @return A new promise.
-- @usage discord:deleteOwnReaction("[channel ID]", "[message ID]", "💗", "[bot token]")
exports("deleteOwnReaction", function(channelId, messageId, emoji, botToken)
	return discordRest:deleteOwnReaction(channelId, messageId, emoji, botToken)
end)

--- Remove own reaction from a message.
-- @function deleteUserReaction
-- @param channelId The ID of the channel containing the message.
-- @param messageId The ID of the message to remove the reaction from.
-- @param emoji The emoji of the reaction to remove.
-- @param botToken Bot token to use for authorization.
-- @return A new promise.
-- @usage discord:deleteOwnReaction("[channel ID]", "[message ID]", "💗", "[bot token]")
exports("deleteUserReaction", function(channelId, messageId, emoji, userId, botToken)
	return discordRest:deleteUserReaction(channelId, messageId, emoji, userId, botToken)
end)

--- Execute a webhook.
-- @function executeWebhook
-- @param url The webhook URL.
-- @param data The data to send.
-- @return A new promise.
-- @usage exports.discord_rest:executeWebhook("https://discord.com/api/webhooks/[webhook ID]/[webhook token]", {content = "Hello, world!"})
exports("executeWebhook", function(url, data)
	return discordRest:executeWebhook(url, data)
end)

--- Get channel information.
-- @function getChannel
-- @param channelId The ID of the channel.
-- @param botToken Bot token to use for authorization.
-- @return A new promise.
-- @usage exports.discord_rest:getChannel("[channel ID]", "[bot token]"):next(function(channel) ... end)
exports("getChannel", function(channelId, botToken)
	return discordRest:getChannel(channelId, botToken)
end)

--- Get a specific message from a channel.
-- @function getChannelMessage
-- @param channelId The ID of the channel.
-- @param messageId The ID of the message.
-- @param botToken Bot token to use for authorization.
-- @return A new promise.
-- @usage exports.discord_rest:getChannelMessage("[channel ID]", "[messageId]", "[bot token]")
exports("getChannelMessage", function(channelId, messageId, botToken)
	return discordRest:getChannelMessage(channelId, messageId, botToken)
end)

--- Get messages from a channel.
-- @function getChannelMessages
-- @param channelId The ID of the channel.
-- @param options Options to tailor the query.
-- @param botToken Bot token to use for authorization.
-- @return A new promise.
-- @usage exports.discord_rest:getChannelMessages("[channel ID]", {limit = 1}, "[bot token]"):next(function(messages) ... end)
exports("getChannelMessages", function(channelId, options, botToken)
	return discordRest:getChannelMessages(channelId, options, botToken)
end)

--- Get a list of users that reacted to a message with a specific emoji.
-- @function getReactions
-- @param channelId The ID of the channel containing the message.
-- @param messageId The ID of the message to get reactions from.
-- @param emoji The emoji of the reaction.
-- @param options Options to tailor the query.
-- @param botToken Bot token to use for authorization.
-- @return A new promise.
-- @usage exports.discord_rest:getReactions("[channel ID]", "[message ID]", "💗", nil, "[bot token]"):next(function(users) ... end)
exports("getReactions", function(channelId, messageId, emoji, options, botToken)
	return discordRest:getReactions(channelId, messageId, emoji, options, botToken)
end)

--- Get user information.
-- @function getUser
-- @param userId The ID of the user.
-- @param botToken Bot token to use for authorization.
-- @return A new promise.
-- @usage exports.discord_rest:getUser("[user ID]", "[bot token]"):next(function(user) ... end)
exports("getUser", function(userId, botToken)
	return discordRest:getUser(userId, botToken)
end)

--- Update a channel's settings.
-- @function modifyChannel
-- @param channelId The ID of the channel.
-- @param channel The new channel settings.
-- @param botToken Bot token to use for authorization.
-- @return A new promise.
-- @usage exports.discord_rest:modifyChannel("[channel ID]", {name = "new-name"}, "[bot token]")
exports("modifyChannel", function(channelId, channel, botToken)
	return discordRest:modifyChannel(channelId, channel, botToken)
end)

--- Perform a custom HTTP request to the Discord REST API, while still respecting the rate limit.
-- @function performHttpRequest
-- @param url The endpoint of the API to request.
-- @param callback An optional callback function to execute when the response is received.
-- @param method The HTTP method of the request.
-- @param data Data to send in the body of the request.
-- @param headers The HTTP headers of the request.
-- @usage exports.discord_rest:performHttpRequest("https://discord.com/api/channels/[channel ID]/messages/[message ID]", nil, "DELETE", "", {["Authorization"] = "Bot [bot token]"})
exports("performHttpRequest", function(url, callback, method, data, headers)
	discordRest:performHttpRequest(url, callback, method, data, headers)
end)
