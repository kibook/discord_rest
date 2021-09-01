--- Discord REST API interface
-- @classmod DiscordRest

-- Discord API base URL
local discordApi = "https://discord.com/api"

-- Discord REST API routes
local routes = {
	bulkDelete     = "/channels/%s/messages/bulk-delete",
	channel        = "/channels/%s",
	channelInvites = "/channels/%s/invites",
	crosspost      = "/channels/%s/messages/%s/crosspost",
	message        = "/channels/%s/messages/%s",
	messages       = "/channels/%s/messages",
	ownReaction    = "/channels/%s/messages/%s/reactions/%s/@me",
	reaction       = "/channels/%s/messages/%s/reactions/%s",
	reactions      = "/channels/%s/messages/%s/reactions",
	userReaction   = "/channels/%s/messages/%s/reactions/%s/%s",
	user           = "/users/%s",
}

-- Check if an HTTP status code indicates an error
local function isResponseError(status)
	return status < 200 or status > 299
end

-- Check if an HTTP status code indicates success
local function isResponseSuccess(status)
	return not isResponseError(status)
end

-- Create a simple PerformHttpRequest callback that resolves or rejects a promise
function createSimplePromiseCallback(p)
	return function(status, data, headers)
		if isResponseSuccess(status) then
			p:resolve(json.decode(data))
		else
			p:reject(status)
		end
	end
end

-- Combine options into query string
function createQueryString(options)
	local params = {}

	if options then
		for k, v in pairs(options) do
			table.insert(params, ("%s=%s"):format(k, v))
		end
	end

	if #params > 0 then
		return "?" .. table.concat(params, "&")
	else
		return ""
	end
end

-- Format an API route URI
local function formatRoute(route, variables, options)
	local queryString = createQueryString(options)

	if type(variables) == "table" then
		return discordApi .. route:format(table.unpack(variables)) .. queryString
	else
		return discordApi .. route .. queryString
	end
end

-- Per-route rate limit queue
local RateLimitQueue = {}

-- Create a new queue for a route
function RateLimitQueue:new(route)
	self.__index = self
	local self = setmetatable({}, self)

	self.route = route

	self.items = {}
	self.rateLimitRemaining = 0
	self.rateLimitReset = 0

	return self
end

-- Add a message to the queue
function RateLimitQueue:enqueue(cb)
	table.insert(self.items, 1, cb)
end

-- Remove a message from the queue and execute it
function RateLimitQueue:dequeue()
	local cb = table.remove(self.items)

	if cb then
		cb()
	end
end

-- Check if the queue has any items and hasn't hit the rate limit
function RateLimitQueue:isReady()
	return #self.items > 0 and (self.rateLimitRemaining > 0 or os.time() > self.rateLimitReset)
end

-- Return the route this queue is for
function RateLimitQueue:getRoute()
	return self.route
end

-- Return the number of messages that can be sent on this route
function RateLimitQueue:getRateLimitRemaining()
	return self.rateLimitRemaining
end

-- Update the number of messages that can be sent on this route
function RateLimitQueue:setRateLimitRemaining(value)
	self.rateLimitRemaining = value
end

-- Return the time when the rate limit for this route resets
function RateLimitQueue:getRateLimitReset()
	return self.rateLimitReset
end

-- Updte the time when the rate limit for this route resets
function RateLimitQueue:setRateLimitReset(value)
	self.rateLimitReset = value
end

--- Discord REST API interface
-- @type DiscordRest
DiscordRest = {}

--- Create a new Discord REST API interface
-- @param botToken Optional bot token to use for authorization
-- @return A new Discord REST API interface object
-- @usage local discord = DiscordRest:new("[bot token]")
function DiscordRest:new(botToken)
	self.__index = self
	local self = setmetatable({}, self)

	self.botToken = botToken

	self.queues = {}

	Citizen.CreateThread(function()
		while self do
			self:processQueues()
			Citizen.Wait(500)
		end
	end)

	return self
end

-- Get the queue for a route, or create it if it doesn't exist
function DiscordRest:getQueue(route)
	if not self.queues[route] then
		self.queues[route] = RateLimitQueue:new(route)
	end

	return self.queues[route]
end

-- Process message while respecting the rate limit
function DiscordRest:processQueues()
	for route, queue in pairs(self.queues) do
		if queue:isReady() then
			queue:dequeue()
			break
		end
	end
end

-- Handle HTTP responses from the Discord REST API
function DiscordRest:handleResponse(queue, url, status, text, headers, callback)
	if isResponseError(status) then
		if status == 429 then
			-- No access to headers/body if status > 400, so can't use Retry-After
			-- https://github.com/citizenfx/fivem/blob/6a83275c44a0044b4765e7865f73ca670de45cc3/code/components/http-client/src/HttpClient.cpp#L114
			queue:setRateLimitRemaining(0)
			queue:setRateLimitReset(os.time() + 5)
		end

		print(("Discord REST API error: %s: %d"):format(url, status))
	else
		local rateLimitRemaining = tonumber(headers["x-ratelimit-remaining"])
		local rateLimitReset = tonumber(headers["x-ratelimit-reset"])

		if rateLimitRemaining then
			queue:setRateLimitRemaining(rateLimitRemaining)
		end

		if rateLimitReset then
			queue:setRateLimitReset(rateLimitReset)
		end
	end

	if callback then
		callback(status, text, headers)
	end
end

-- Get the bot authorization string
function DiscordRest:getAuthorization(botToken)
	return "Bot " .. (botToken or self.botToken or "")
end

-- Enqueue a request to the REST API
function DiscordRest:enqueueRequest(queue, url, callback, method, data, headers)
	if not headers then
		headers = {}
	end

	if data then
		if type(data) ~= "string" then
			headers["Content-Type"] = "application/json"
			data = json.encode(data)
		end
	else
		headers["Content-Length"] = "0"
		data = ""
	end

	queue:enqueue(function()
		PerformHttpRequest(url,
			function(status, data, headers)
				self:handleResponse(queue, url, status, data, headers, callback)
			end,
			method, data, headers)
	end)
end

-- Perform a request to a REST API route
function DiscordRest:performRequest(route, parameters, options, method, data, headers)
	local queue = self:getQueue(route)
	local url = formatRoute(route, parameters, options)
	local p = promise.new()
	self:enqueueRequest(queue, url, createSimplePromiseCallback(p), method, data, headers)
	return p
end

-- Perform an authorized request to a REST API route
function DiscordRest:performAuthorizedRequest(route, parameters, options, method, data, botToken)
	return self:performRequest(route, parameters, options, method, data, {
		["Authorization"] = self:getAuthorization(botToken)
	})
end

--- Channel
-- @section channel

--- Delete multiple messages in a single request.
-- @param channelId The ID of the channel containing the messages.
-- @param messages A list of message IDs to delete (2-100).
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:bulkDeleteMessages("[channel ID]", {"[message ID 1]", "[message ID 2]", ...})
-- @see https://discord.com/developers/docs/resources/channel#bulk-delete-messages
function DiscordRest:bulkDeleteMessages(channelId, messages, botToken)
	return self:performAuthorizedRequest(routes.bulkDelete, {channelId}, nil, "POST", {messages = messages}, botToken)
end

--- Create a new invite for a channel.
-- @param channelId The ID of the channel to create an invite for.
-- @param invite The invite settings.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise that resolves with the newly created invite.
-- @usage discord:createChannelInvite("[channel ID]", {max_age = 3600, max_uses = 1})
-- @see https://discord.com/developers/docs/resources/channel#create-channel-invite
function DiscordRest:createChannelInvite(channelId, invite, botToken)
	return self:performAuthorizedRequest(routes.channelInvites, {channelId}, nil, "POST", invite, botToken)
end

--- Post a message.
-- @param channelId The ID of the channel to post in.
-- @param message The message parameters.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved when the message is posted.
-- @usage discord:createMessage("[channel ID]", {content = "Hello, world!"})
-- @see https://discord.com/developers/docs/resources/channel#create-message
function DiscordRest:createMessage(channelId, message, botToken)
	return self:performAuthorizedRequest(routes.messages, {channelId}, nil, "POST", message, botToken)
end

--- Create a reaction for a message.
-- @param channelId The ID of the channel containing the message.
-- @param messageId The ID of the message to add a reaction to.
-- @param emoji The emoji to react with.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved when the reaction is added to the message.
-- @usage discord:createReaction("[channel ID]", "[message ID]", "💗")
-- @see https://discord.com/developers/docs/resources/channel#create-reaction
function DiscordRest:createReaction(channelId, messageId, emoji, botToken)
	return self:performAuthorizedRequest(routes.ownReaction, {channelId, messageId, emoji}, nil, "PUT", nil, botToken)
end

--- Crosspost a message in a News Channel to following channels.
-- @param channelId The ID of the channel containing the message.
-- @param messageId The ID of the message to crosspost.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with the crossposted message.
-- @usage discord:crosspostMessage("[channel ID]", "[message ID]")
-- @see https://discord.com/developers/docs/resources/channel#crosspost-message
function DiscordRest:crosspostMessage(channelId, messageId, botToken)
	return self:performAuthorizedRequest(routes.crosspost, {channelId, messageId}, nil, "POST", nil, botToken)
end

--- Deletes all reactions on a message.
-- @param channelId The ID of the channel containing the message.
-- @param messageId The ID of the message whose reactions will be deleted.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:deleteAllReactions("[channel ID]", "[message ID]")
-- @see https://discord.com/developers/docs/resources/channel#delete-all-reactions
function DiscordRest:deleteAllReactions(channelId, messageId, botToken)
	return self:performAuthorizedRequest(routes.reactions, {channelId, messageId}, nil, "DELETE", nil, botToken)
end

--- Deletes all the reactions for a given emoji on a message.
-- @param channelId The ID of the channel containing the message.
-- @param messageId The ID of the message to delete reactions from.
-- @param emoji The emoji of the reaction to delete.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:deleteAllReactionsForEmoji("[channel ID]", "[message ID]", "💗")
-- @see https://discord.com/developers/docs/resources/channel#delete-all-reactions-for-emoji
function DiscordRest:deleteAllReactionsForEmoji(channelId, messageId, emoji, botToken)
	return self:performAuthorizedRequest(routes.reaction, {channelId, messageId, emoji}, nil, "DELETE", nil, botToken)
end

--- Delete a channel.
-- @param channelId The ID of the channel.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:deleteChannel("[channel ID]")
-- @see https://discord.com/developers/docs/resources/channel#deleteclose-channel
function DiscordRest:deleteChannel(channelId, botToken)
	return self:performAuthorizedRequest(routes.channel, {channelId}, nil, "DELETE", nil, botToken)
end

--- Delete a channel permission overwrite for a user or role in a channel.
-- @param channelId The ID of the channel.
-- @param overwriteId The ID of the user or role to remove permissions for.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:deleteChannelPermission("[channel ID]", "[overwrite ID]")
-- @see https://discord.com/developers/docs/resources/channel#delete-channel-permission
function DiscordRest:deleteChannelPermission(channelId, overwriteId, botToken)
	return self:performAuthorizedRequest(routes.editChannelPermissions, {channelId, overwriteId}, nil, "DELETE", nil, botToken)
end

--- Delete a message from a channel.
-- @param channelId The ID of the channel.
-- @param messageId The ID of the message.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:deleteMessage("[channel ID]", "[message ID]")
-- @see https://discord.com/developers/docs/resources/channel#delete-message
function DiscordRest:deleteMessage(channelId, messageId, botToken)
	return self:performAuthorizedRequest(routes.message, {channelId, messageId}, nil, "DELETE", nil, botToken)
end

--- Remove own reaction from a message.
-- @param channelId The ID of the channel containing the message.
-- @param messageId The ID of the message to remove the reaction from.
-- @param emoji The emoji of the reaction to remove.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:deleteOwnReaction("[channel ID]", "[message ID]", "💗")
-- @see https://discord.com/developers/docs/resources/channel#delete-own-reaction
function DiscordRest:deleteOwnReaction(channelId, messageId, emoji, botToken)
	return self:performAuthorizedRequest(routes.ownReaction, {channelId, messageId, emoji}, nil, "DELETE", nil, botToken)
end

--- Remove a user's reaction from a message.
-- @param channelId The ID of the channel containing the message.
-- @param messageId The message to remove the reaction from.
-- @param emoji The emoji of the reaction to remove.
-- @param userId The ID of the user whose reaction will be removed.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:deleteUserReaction("[channel ID]", "[message ID]", "💗", "[user ID]")
-- @see https://discord.com/developers/docs/resources/channel#delete-user-reaction
function DiscordRest:deleteUserReaction(channelId, messageId, emoji, userId, botToken)
	return self:performAuthorizedRequest(routes.userReaction, {channelId, messageId, emoji, userId}, nil, "DELETE", nil, botToken)
end

--- Edit the channel permission overwrites for a user or role in a channel.
-- @param channelId The ID of the channel to edit the permissions of.
-- @param overwriteId The ID of the user or role to edit permissions for.
-- @param permissions The permissions to set.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:editChannelPermissions("[channel ID]", "[overwrite ID]", {allow = 6, deny = 8, type = 0})
-- @see https://discord.com/developers/docs/resources/channel#edit-channel-permissions
function DiscordRest:editChannelPermissions(channelId, overwriteId, permissions, botToken)
	return self:performAuthorizedRequest(routes.editChannelPermissions, {channelId, overwriteId}, nil, "PUT", permissions, botToken)
end

--- Edit a previously sent message.
-- @param channelId The ID of the channel containing the message.
-- @param messageId The ID of the message to edit.
-- @param message The edited message.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise, which resolves with the edited message when the request is completed.
-- @usage discord:editMessage("[channel ID]", "[message ID]", {content = "I edited this message!"})
-- @see https://discord.com/developers/docs/resources/channel#edit-message
function DiscordRest:editMessage(channelId, messageId, message, botToken)
	return self:performAuthorizedRequest(routes.message, {channelId, messageId}, nil, "PATCH", message, botToken)
end

--- Get channel information.
-- @param channelId The ID of the channel.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:getChannel("[channel ID]"):next(function(channel) ... end)
-- @see https://discord.com/developers/docs/resources/channel#get-channel
function DiscordRest:getChannel(channelId, botToken)
	return self:performAuthorizedRequest(routes.channel, {channelId}, nil, "GET", nil, botToken)
end

--- Get a list of invites for a channel.
-- @param channelId The ID of the channel to get invites for.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise that resolves with the list of invites.
-- @usage discord:getChannelInvites("[channel ID]"):next(function(invites) ... end)
-- @see https://discord.com/developers/docs/resources/channel#get-channel-invites
function DiscordRest:getChannelInvites(channelId, botToken)
	return self:performAuthorizedRequest(routes.channelInvites, {channelId}, nil, "GET", nil, botToken)
end

--- Get a specific message from a channel.
-- @param channelId The ID of the channel.
-- @param messageId The ID of the message.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:getChannelMessage("[channel ID]", "[messageId]")
-- @see https://discord.com/developers/docs/resources/channel#get-channel-message
function DiscordRest:getChannelMessage(channelId, messageId, botToken)
	return self:performAuthorizedRequest(routes.message, {channelId, messageId}, nil, "GET", nil, botToken)
end

--- Get a list of messages from a channels
-- @param channelId The ID of the channel.
-- @param options Options to tailor the query.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:getChannelMessage("[channel ID]", {limit = 1}):next(function(messages) ... end)
-- @see https://discord.com/developers/docs/resources/channel#get-channel-messages
function DiscordRest:getChannelMessages(channelId, options, botToken)
	return self:performAuthorizedRequest(routes.messages, {channelId}, options, "GET", nil, botToken)
end

--- Get a list of users that reacted to a message with a specific emoji.
-- @param channelId The ID of the channel containing the message.
-- @param messageId The ID of the message to get reactions from.
-- @param emoji The emoji of the reaction.
-- @param options Options to tailor the query.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:getReactions("[channel ID]", "[message ID]", "💗"):next(function(users) ... end)
-- @see https://discord.com/developers/docs/resources/channel#get-reactions
function DiscordRest:getReactions(channelId, messageId, emoji, options, botToken)
	return self:performAuthorizedRequest(routes.reaction, {channelId, messageId, emoji}, options, "GET", nil, botToken)
end

--- Update a channel's settings.
-- @param channelId The ID of the channel.
-- @param channel The new channel settings.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:modifyChannel("[channel ID]", {name = "new-name"})
-- @see https://discord.com/developers/docs/resources/channel#modify-channel
function DiscordRest:modifyChannel(channelId, channel, botToken)
	return self:performAuthorizedRequest(routes.channel, {channelId}, nil, "PATCH", channel, botToken)
end

--- User
-- @section user

--- Get user information.
-- @param userId The ID of the user.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:getUser("[user ID]"):next(function(user) ... end)
-- @see https://discord.com/developers/docs/resources/user#get-user
function DiscordRest:getUser(userId, botToken)
	return self:performAuthorizedRequest(routes.user, {userId}, nil, "GET", nil, botToken)
end

--- Webhook
-- @section webhook

--- Execute a Discord webhook
-- @param url The webhook URL.
-- @param data The data to send.
-- @return A new promise.
-- @usage discord:executeWebhook("https://discord.com/api/webhooks/[webhook ID]/[webhook token]", {content = "Hello, world!"})
-- @see https://discord.com/developers/docs/resources/webhook#execute-webhook
function DiscordRest:executeWebhook(url, data)
	local queue = self:getQueue(url)
	local p = promise.new()
	self:enqueueRequest(queue, url, createSimplePromiseCallback(p), "POST", data)
	return p
end
