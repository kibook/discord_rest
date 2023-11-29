--- Discord REST API interface
-- @classmod DiscordRest

-- Discord API base URL
local discordApi = "https://discord.com/api"

-- Discord REST API routes
local routes = {
	activeThreads  = "/channels/%s/threads/active",
	ban            = "/guilds/%s/bans/%s",
	bans           = "/guilds/%s/bans",
	bulkDelete     = "/channels/%s/messages/bulk-delete",
	channel        = "/channels/%s",
	channelInvites = "/channels/%s/invites",
	channelThreads = "/channels/%s/threads",
	createDm       = "/users/@me/channels",
	crosspost      = "/channels/%s/messages/%s/crosspost",
	currentUser    = "/users/@me",
	followers      = "/channels/%s/followers",
	github         = "/webhooks/%s/%s/github",
	groupDm        = "/channels/%s/recipients/%s",
	guild          = "/guilds/%s",
	guildChannels  = "/guilds/%s/channels",
	guildEmoji     = "/guilds/%s/emojis/%s",
	guildEmojis    = "/guilds/%s/emojis",
	guildInvites   = "/guilds/%s/invites",
	guildMember    = "/guilds/%s/members/%s",
	guildMembers   = "/guilds/%s/members",
	guildPreview   = "/guilds/%s/preview",
	guilds         = "/guilds",
	guildThreads   = "/guilds/%s/threads/active",
	guildWebhooks  = "/guilds/%s/webhooks",
	integration    = "/guilds/%s/integrations/%",
	integrations   = "/guilds/%s/integrations",
	invite         = "/invites/%s",
	joinedThreads  = "/channels/%s/users/@me/threads/archived/private",
	memberRole     = "/guilds/%s/members/%s/roles/%s",
	message        = "/channels/%s/messages/%s",
	messages       = "/channels/%s/messages",
	messageThreads = "/channels/%s/messages/%s/threads",
	myConnections  = "/users/@me/connections",
	myGuild        = "/users/@me/guilds/%s",
	myGuilds       = "/users/@me/guilds",
	myVoiceState   = "/guilds/%s/voice-states/@me",
	nick           = "/guilds/%s/members/@me/nick",
	ownReaction    = "/channels/%s/messages/%s/reactions/%s/@me",
	pinMessage     = "/channels/%s/pins/%s",
	pins           = "/channels/%s/pins",
	privateThreads = "/channels/%s/threads/archived/private",
	prune          = "/guilds/%s/prune",
	publicThreads  = "/channels/%s/threads/archived/public",
	reaction       = "/channels/%s/messages/%s/reactions/%s",
	reactions      = "/channels/%s/messages/%s/reactions",
	regions        = "/guilds/%s/regions",
	role           = "/guilds/%s/roles/%s",
	roles          = "/guilds/%s/roles",
	searchMembers  = "/guilds/%s/members/search",
	slack          = "/webhooks/%s/%s/slack",
	threadMembers  = "/channels/%s/thread-members",
	threadSelf     = "/channels/%s/thread-members/@me",
	threadUser     = "/channels/%s/thread-members/%s",
	typing         = "/channels/%s/typing",
	user           = "/users/%s",
	userReaction   = "/channels/%s/messages/%s/reactions/%s/%s",
	userVoiceState = "/guilds/%s/voice-states/%s",
	vanityUrl      = "/guilds/%s/vanity-url",
	webhook        = "/webhooks/%s/%s",
	webhookId      = "/webhooks/%s",
	webhookMessage = "/webhooks/%s/%s/messages/%s",
	webhooks       = "/channels/%s/webhooks",
	welcomeScreen  = "/guilds/%s/welcome-screen",
	widget         = "/guilds/%s/widget",
	widgetImage    = "/guilds/%s/widget.png",
	widgetJson     = "/guilds/%s/widget.json",
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
			object = json.decode(data)

			if object == nil then
				p:reject(data)
			else
				p:resolve(object)
			end
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
	self.rateLimitHits = 0

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
		-- Requeue message if callback returns false
		if not cb() then
			table.insert(self.items, cb)
		end
	end
end

-- Check if the queue has any items and hasn't hit the rate limit
function RateLimitQueue:isReady()
	return #self.items > 0 and os.time() > self.rateLimitReset
end

-- Process HTTP responses from the Discord REST API for rate limit info
function RateLimitQueue:processResponse(status, headers)
	self.rateLimitRemaining = self.rateLimitRemaining - 1

	if status == 429 then
		-- No access to headers/body if status > 400, so can't read rate limit info or use Retry-After:
		-- https://github.com/citizenfx/fivem/blob/6a83275c44a0044b4765e7865f73ca670de45cc3/code/components/http-client/src/HttpClient.cpp#L114
		self.rateLimitRemaining = 0
		self.rateLimitHits = self.rateLimitHits + 1
		self.rateLimitReset = os.time() + (self.rateLimitHits * 5)

		return false
	else
		if self.rateLimitHits > 0 then
			self.rateLimitHits = self.rateLimitHits - 1
		end

		if isResponseSuccess(status) then
			local rateLimitRemaining = tonumber(headers["x-ratelimit-remaining"])
			local rateLimitReset = tonumber(headers["x-ratelimit-reset"])

			if rateLimitRemaining then
				self.rateLimitRemaining = rateLimitRemaining
			end

			if rateLimitReset then
				self.rateLimitReset = rateLimitReset
			end
		end

		return true
	end
end

--- Discord REST API interface
-- @type DiscordRest
DiscordRest = {}

--- Discord channel types
-- @field GUILD_TEXT a text channel within a server
-- @field DM a direct message between users
-- @field GUILD_VOICE a voice channel within a server
-- @field GROUP_DM a direct message between multiple users
-- @field GUILD_CATEGORY an organizational category that contains up to 50 channels
-- @field GUILD_NEWS a channel that users can follow and crosspost into their own server
-- @field GUILD_STORE a channel in which game developers can sell their game on Discord
-- @field GUILD_NEWS_THREAD a temporary sub-channel within a GUILD_NEWS channel
-- @field GUILD_PUBLIC_THREAD a temporary sub-channel within a GUILD_TEXT channel
-- @field GUILD_PRIVATE_THREAD a temporary sub-channel within a GUILD_TEXT channel that is only viewable by those invited and those with the MANAGE_THREADS permission
-- @field GUILD_STAGE_VOICE a voice channel for hosting events with an audience
-- @see https://discord.com/developers/docs/resources/channel#channel-object-channel-types
DiscordRest.channelTypes = {
	GUILD_TEXT = 0,
	DM = 1,
	GUILD_VOICE = 2,
	GROUP_DM = 3,
	GUILD_CATEGORY = 4,
	GUILD_NEWS = 5,
	GUILD_STORE = 6,
	GUILD_NEWS_THREAD = 10,
	GUILD_PUBLIC_THREAD = 11,
	GUILD_PRIVATE_THREAD = 12,
	GUILD_STAGE_VOICE = 13
}

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
			Citizen.Wait(self:processQueues() and 0 or 500)
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
	local processedQueue = false

	for route, queue in pairs(self.queues) do
		if queue:isReady() then
			queue:dequeue()
			processedQueue = true
			Citizen.Wait(50)
		end
	end

	return processedQueue
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
		local p = promise.new()

		PerformHttpRequest(url,
			function(status, responseData, responseHeaders)
				if queue:processResponse(status, responseHeaders) then
					p:resolve(true)

					if callback then
						callback(status, responseData, responseHeaders)
					end
				else
					p:resolve(false)

					if Config.debug then
						print(("Rate limiting detected for %s, this request will be requeued after %d seconds"):format(url, queue.rateLimitHits * 5))
					end
				end
			end,
			method, data, headers)

		return Citizen.Await(p)
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

-- Perform a request to a webhook URL
function DiscordRest:performRequestToWebhook(baseUrl, options, method, data, headers)
	local queue = self:getQueue(baseUrl)
	local url = baseUrl .. createQueryString(options)
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

--- Adds another member to a thread.
-- @param channelId The ID of the thread channel.
-- @param userId The ID of the user to add to the thread.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:addThreadMember("[channel ID]", "[user ID]")
-- @see https://discord.com/developers/docs/resources/channel#add-thread-member
function DiscordRest:addThreadMember(channelId, userId, botToken)
	return self:performAuthorizedRequest(routes.threadUser, {channelId, userId}, nil, "PUT", nil, botToken)
end

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
	return self:performAuthorizedRequest(routes.channelInvites, {channelId}, nil, "POST", invite or {}, botToken)
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

--- Follow a News Channel to send messages to a target channel.
-- @param channelId The ID of the news channel.
-- @param targetChannelId The ID of the target channel.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise that resolves with a followed channel object.
-- @usage discord:followNewsChannel("[channel ID]", "[target channel ID]")
-- @see https://discord.com/developers/docs/resources/channel#follow-news-channel
function DiscordRest:followNewsChannel(channelId, targetChannelId, botToken)
	return self:performAuthorizedRequest(routes.followers, {channelId}, nil, "POST", {webhook_channel_id = targetChannelId}, botToken)
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

--- Returns all pinned messages in the channel.
-- @param channelId The ID of the channel to get pinned messages from.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which resolves with a list of pinned messages.
-- @usage discord:getPinnedMessages("[channel ID]")
-- @see https://discord.com/developers/docs/resources/channel#get-pinned-messages
function DiscordRest:getPinnedMessages(channelId, botToken)
	return self:performAuthorizedRequest(routes.pins, {channelId}, nil, "GET", nil, botToken)
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

--- Adds a recipient to a Group DM using their access token.
-- @param channelId The ID of the group DM channel.
-- @param userId The ID of the user to add.
-- @param params Parameters for adding the user.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:groupDmAddRecipient("[channel ID]", "[user ID]", {access_token = "..."})
-- @see https://discord.com/developers/docs/resources/channel#group-dm-add-recipient
function DiscordRest:groupDmAddRecipient(channelId, userId, params, botToken)
	return self:performAuthorizedRequest(routes.groupDm, {channelId, userId}, nil, "PUT", params, botToken)
end

--- Removes a recipient from a Group DM.
-- @param channelId The ID of the group DM channel.
-- @param userId The ID of the user to remove.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:groupDmRemoveRecipient("[channel ID]", "[user ID]")
-- @see https://discord.com/developers/docs/resources/channel#group-dm-remove-recipient
function DiscordRest:groupDmRemoveRecipient(channelId, userId, botToken)
	return self:performAuthorizedRequest(routes.groupDm, {channelId, userId}, nil, "DELETE", nil, botToken)
end

--- Adds the current user to a thread.
-- @param channelId The ID of the thread channel to join.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:joinThread("[channel ID]")
-- @see https://discord.com/developers/docs/resources/channel#join-thread
function DiscordRest:joinThread(channelId, botToken)
	return self:performAuthorizedRequest(routes.threadSelf, {channelId}, nil, "PUT", nil, botToken)
end

--- Removes the current user from a thread.
-- @param channelId The ID of the thread channel to leave.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:leaveThread("[channel ID]")
-- @see https://discord.com/developers/docs/resources/channel#leave-thread
function DiscordRest:leaveThread(channelId, botToken)
	return self:performAuthorizedRequest(routes.threadSelf, {channelId}, nil, "DELETE", nil, botToken)
end

--- Returns all active threads in the channel, including public and private threads.
-- @param channelId The ID of the channel to get a list of active threads for.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with a table of information on active threads.
-- @usage discord:listActiveThreads("[channel ID]"):next(function(data) ... end)
-- @see https://discord.com/developers/docs/resources/channel#list-active-threads
function DiscordRest:listActiveThreads(channelId, botToken)
	return self:performAuthorizedRequest(routes.activeThreads, {channelId}, nil, "GET", nil, botToken)
end

--- Returns archived threads in the channel that are private, and the user has joined.
-- @param channelId The ID of the channel to get a list of private archived threads from.
-- @param options Options for the query.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with a table of information on private archived threads.
-- @usage discord:listJoinedPrivateArchivedThreads("[channel ID]", {limit = 5}):next(function(data) ... end)
-- @see https://discord.com/developers/docs/resources/channel#list-joined-private-archived-threads
function DiscordRest:listJoinedPrivateArchivedThreads(channelId, options, botToken)
	return self:performAuthorizedRequest(routes.joinedThreads, {channelId}, options, "GET", nil, botToken)
end

--- Returns archived threads in the channel that are private.
-- @param channelId The ID of the channel to get a list of private archived threads from.
-- @param options Options for the query.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with a table of information on private archived threads.
-- @usage discord:listPrivateArchivedThreads("[channel ID]", {limit = 5}):next(function(data) ... end)
-- @see https://discord.com/developers/docs/resources/channel#list-private-archived-threads
function DiscordRest:listPrivateArchivedThreads(channelId, options, botToken)
	return self:performAuthorizedRequest(routes.privateThreads, {channelId}, options, "GET", nil, botToken)
end

--- Returns archived threads in the channel that are public.
-- @param channelId The ID of the channel to get a list of public archived threads from.
-- @param options Options for the query.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with a table of information on public archived threads.
-- @usage discord:listPublicArchivedThreads("[channel ID]", {limit = 5}):next(function(data) ... end)
-- @see https://discord.com/developers/docs/resources/channel#list-public-archived-threads
function DiscordRest:listPublicArchivedThreads(channelId, options, botToken)
	return self:performAuthorizedRequest(routes.publicThreads, {channelId}, options, "GET", nil, botToken)
end

--- Get a list of members of a thread.
-- @param channelId The ID of the thread channel.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with a list of members of the thread.
-- @usage discord:listThreadMembers("[channel ID]"):next(function(members) ... end)
-- @see https://discord.com/developers/docs/resources/channel#list-thread-members
function DiscordRest:listThreadMembers(channelId, botToken)
	return self:performAuthorizedRequest(routes.threadMembers, {channelId}, nil, "GET", nil, botToken)
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

--- Pin a message in a channel.
-- @param channelId The ID of the channel containing the message.
-- @param messageId The ID of the message to pin.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:pinMessage("[channel ID]", "[message ID]")
-- @see https://discord.com/developers/docs/resources/channel#pin-message
function DiscordRest:pinMessage(channelId, messageId, botToken)
	return self:performAuthorizedRequest(routes.pinMessage, {channelId, messageId}, nil, "PUT", nil, botToken)
end

--- Removes another member from a thread.
-- @param channelId The ID of the thread channel.
-- @param userId The ID of the user to remove from the thread.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:removeThreadMember("[channel ID]", "[user ID]")
-- @see https://discord.com/developers/docs/resources/channel#remove-thread-member
function DiscordRest:removeThreadMember(channelId, userId, botToken)
	return self:performAuthorizedRequest(routes.threadUser, {channelId, userId}, nil, "DELETE", nil, botToken)
end

--- Creates a new thread from an existing message.
-- @param channelId The ID of the channel containing the message.
-- @param messageId The ID of the message to start the thread from.
-- @param params Parameters for the thread.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise that resolves with the new thread channel.
-- @usage discord:startThreadWithMessage("[channel ID]", "[message ID]", {name = "New thread"}):next(function(channel) ... end)
-- @see https://discord.com/developers/docs/resources/channel#start-thread-with-message
function DiscordRest:startThreadWithMessage(channelId, messageId, params, botToken)
	return self:performAuthorizedRequest(routes.messageThreads, {channelId, messageId}, nil, "POST", params, botToken)
end

--- Creates a new thread that is not connected to an existing message.
-- @param channelId The ID of the channel to create the thread in.
-- @param params Parameters for the thread.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise that resolves with the new thread channel.
-- @usage discord:startThreadWithoutMessage("[channel ID]", {name = "New thread"}):next(function(channel) ... end)
-- @see https://discord.com/developers/docs/resources/channel#start-thread-without-message
function DiscordRest:startThreadWithoutMessage(channelId, params, botToken)
	if not params.auto_archive_duration then
		params.auto_archive_duration = 1440 -- 24 hours
	end

	if type(params.type) == "string" then
		params.type = DiscordRest.channelTypes[params.type]
	end

	if not params.type then
		params.type = DiscordRest.channelTypes.GUILD_PUBLIC_THREAD
	end

	return self:performAuthorizedRequest(routes.channelThreads, {channelId}, nil, "POST", params, botToken)
end

--- Post a typing indicator for the specified channel.
-- @param channelId The ID of the channel to show the typing indicator in.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:triggerTypingIndicator("[channel ID]")
-- @see https://discord.com/developers/docs/resources/channel#trigger-typing-indicator
function DiscordRest:triggerTypingIndicator(channelId, botToken)
	return self:performAuthorizedRequest(routes.typing, {channelId}, nil, "POST", nil, botToken)
end

--- Unpin a message in a channel.
-- @param channelId The ID of the channel containing the message.
-- @param messageId The ID of the message to unpin.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:unpinMessage("[channel ID]", "[message ID]")
-- @see https://discord.com/developers/docs/resources/channel#unpin-message
function DiscordRest:unpinMessage(channelId, messageId, botToken)
	return self:performAuthorizedRequest(routes.pinMessage, {channelId, messageId}, nil, "DELETE", nil, botToken)
end

--- Emoji
-- @section emoji

--- Create a new emoji for the guild.
-- @param guildId The ID of the guild to create the emoji for.
-- @param params Parameters for the new emoji.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise whih is resolved with the new emoji.
-- @usage discord:createGuildEmoji("[guild ID]", {name = "emojiname", image = "data:image/jpeg;base64,..."})
-- @see https://discord.com/developers/docs/resources/emoji#create-guild-emoji
function DiscordRest:createGuildEmoji(guildId, params, botToken)
	return self:performAuthorizedRequest(routes.guildEmojis, {guildId}, nil, "POST", params, botToken)
end

--- Delete the given emoji.
-- @param guildId The ID of the guild to delete the emoji from.
-- @param emojiId The ID of the emoji to delete.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:deleteGuildEmoji("[guild ID]", "[emoji ID]")
-- @see https://discord.com/developers/docs/resources/emoji#delete-guild-emoji
function DiscordRest:deleteGuildEmoji(guildId, emojiId, botToken)
	return self:performAuthorizedRequest(routes.guildEmoji, {guildId, emojiId}, nil, "DELETE", nil, botToken)
end

--- Get information on a guild emoji.
-- @param guildId The ID of the guild where the emoji is from.
-- @param emojiId The ID of the emoji to get information about.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with the information about the emoji.
-- @usage discord:getGuildEmoji("[guild ID]", "[emoji ID]"):next(function(emoji) ... end)
-- @see https://discord.com/developers/docs/resources/emoji#get-guild-emoji
function DiscordRest:getGuildEmoji(guildId, emojiId, botToken)
	return self:performAuthorizedRequest(routes.guildEmoji, {guildId, emojiId}, nil, "GET", nil, botToken)
end

--- Return a list of emoji for the given guild.
-- @param guildId The ID of the guild.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with the list of emoji.
-- @usage discord:listGuildEmojis("[guild ID]"):next(function(emojis) ... end)
-- @see https://discord.com/developers/docs/resources/emoji#list-guild-emojis
function DiscordRest:listGuildEmojis(guildId, botToken)
	return self:performAuthorizedRequest(routes.guildEmojis, {guildId}, nil, "GET", nil, botToken)
end

--- Modify the given emoji.
-- @param guildId The ID of the guild where the emoji is from.
-- @param emojiId The ID of the emoji to modify.
-- @param params Modified parameters for the emoji.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with the updated emoji.
-- @usage discord:modifyGuildEmoji("[guild ID]", "[emoji ID]", {name = "newemojiname"})
-- @see https://discord.com/developers/docs/resources/emoji#modify-guild-emoji
function DiscordRest:modifyGuildEmoji(guildId, emojiId, params, botToken)
	return self:performAuthorizedRequest(routes.guildEmoji, {guildId, emojiId}, nil, "PATCH", params, botToken)
end

--- Guild
-- @section guild

--- Adds a user to the guild.
-- @param guildId The ID of the guild to add the user to.
-- @param userId The ID of the user to add to the guild.
-- @param params Parameters for adding the user.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:addGuildMember("[guild ID]", "[user ID]", {access_token = "..."})
-- @see https://discord.com/developers/docs/resources/guild#add-guild-member
function DiscordRest:addGuildMember(guildId, userId, params, botToken)
	return self:performAuthorizedRequest(routes.guildMember, {guildId, userId}, nil, "PUT", params, botToken)
end

--- Adds a role to a guild member.
-- @param guildId The ID of the guild.
-- @param userId The ID of the user to add the role to.
-- @param roleId The ID of the role to add to the member.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:addGuildMemberRole("[guild ID]", "[user ID]", "[role ID]")
-- @see https://discord.com/developers/docs/resources/guild#add-guild-member-role
function DiscordRest:addGuildMemberRole(guildId, userId, roleId, botToken)
	return self:performAuthorizedRequest(routes.memberRole, {guildId, userId, roleId}, nil, "PUT", nil, botToken)
end

--- Begin a prune operation.
-- @param guildId The ID of the guild to prune.
-- @param params Parameters for pruning.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with the number of members that were pruned.
-- @usage discord:beginGuildPrune("[guild ID]"):next(function(pruned) ... end)
-- @see https://discord.com/developers/docs/resources/guild#begin-guild-prune
function DiscordRest:beginGuildPrune(guildId, params, botToken)
	return self:performAuthorizedRequest(routes.prune, {guildId}, nil, "POST", params, botToken):next(function(data)
		return data.pruned
	end)
end

--- Create a new guild.
-- @param params Parameters for the new guild.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with the new guild.
-- @usage discord:createGuild({name = "My Guild"})
-- @see https://discord.com/developers/docs/resources/guild#create-guild
function DiscordRest:createGuild(params, botToken)
	return self:performAuthorizedRequest(routes.guilds, nil, nil, "POST", params, botToken)
end

--- Create a guild ban, and optionally delete previous messages sent by the banned user.
-- @param guildId The ID of the guild to create the ban for.
-- @param userId The ID of the user to ban.
-- @param params Parameters for the ban.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:createGuildBan("[guild ID]", "[user ID]", {reason = "Not following the rules"})
-- @see https://discord.com/developers/docs/resources/guild#create-guild-ban
function DiscordRest:createGuildBan(guildId, userId, params, botToken)
	return self:performAuthorizedRequest(routes.ban, {guildId, userId}, nil, "PUT", params, botToken)
end

--- Create a new guild channel.
-- @param guildId The ID of the guild to create the channel in.
-- @param params Parameters for the new channel.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with the new channel.
-- @usage discord:createGuildChannel(["guild ID"], {name = "new-channel"}):next(function(channel) ... end)
-- @see https://discord.com/developers/docs/resources/guild#create-guild-channel
function DiscordRest:createGuildChannel(guildId, params, botToken)
	return self:performAuthorizedRequest(routes.guildChannels, {guildId}, nil, "POST", params, botToken)
end

--- Create a new role for the guild.
-- @param guildId The ID of the guild.
-- @param params Parameters for the new role.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with the new role.
-- @usage discord:createGuildRole("[guild ID]", {name = "Moderator", ...}):next(function(role) ... end)
-- @see https://discord.com/developers/docs/resources/guild#create-guild-role
function DiscordRest:createGuildRole(guildId, params, botToken)
	return self:performAuthorizedRequest(routes.roles, {guildId}, nil, "POST", params, botToken)
end

--- Delete a guild permanently.
-- @param guildId The ID of the guild to delete.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:deleteGuild("[guild ID]")
-- @see https://discord.com/developers/docs/resources/guild#delete-guild
function DiscordRest:deleteGuild(guildId, botToken)
	return self:performAuthorizedRequest(routes.guild, {guildId}, nil, "DELETE", nil, botToken)
end

--- Delete an integration for a guild.
-- @param guildId The ID of the guild
-- @param integrationId The ID of the integration to delete.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:deleteGuildIntegration("[guild ID]", "[integration ID]")
-- @see https://discord.com/developers/docs/resources/guild#delete-guild-integration
function DiscordRest:deleteGuildIntegration(guildId, integrationId, botToken)
	return self:performAuthorizedRequest(routes.integration, {guildId, integrationId}, nil, "DELETE", nil, botToken)
end

--- Delete a guild role.
-- @param guildId The ID of the guild.
-- @param roleId The ID of the role that will be deleted.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:deleteGuildRole("[guild ID]", "[role ID]")
-- @see https://discord.com/developers/docs/resources/guild#delete-guild-role
function DiscordRest:deleteGuildRole(guildId, roleId, botToken)
	return self:performAuthorizedRequest(routes.role, {guildId, roleId}, nil, "DELETE", nil, botToken)
end

--- Get info for a given guild.
-- @param guildId The ID of the guild.
-- @param withCounts Whether to include approximate member and presence counts in the returned info.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with the guild info.
-- @usage discord:getGuild("[guild ID]"):next(function(guild) ... end)
-- @see https://discord.com/developers/docs/resources/guild#get-guild
function DiscordRest:getGuild(guildId, withCounts, botToken)
	return self:performAuthorizedRequest(routes.guild, {guildId}, {with_counts = withCounts}, "GET", nil, botToken)
end

--- Return info on a ban for a specific user in a guild.
-- @param guildId The ID of the guild.
-- @param userId The ID of the banned user.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with the ban info.
-- @usage discord:getGuildBan("[guild ID]", "[user ID]"):next(function(ban) ... end)
-- @see https://discord.com/developers/docs/resources/guild#get-guild-ban
function DiscordRest:getGuildBan(guildId, userId, botToken)
	return self:performAuthorizedRequest(routes.ban, {guildId, userId}, nil, "GET", nil, botToken)
end

--- Get a list of bans for a guild.
-- @param guildId The ID of the guild.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with a list of bans.
-- @usage discord:getGuildBans("[guild ID]"):next(function(bans) ... end)
-- @see https://discord.com/developers/docs/resources/guild#get-guild-bans
function DiscordRest:getGuildBans(guildId, botToken)
	return self:performAuthorizedRequest(routes.bans, {guildId}, nil, "GET", nil, botToken)
end

--- Get a list of guild channels.
-- @param guildId The ID of the guild to get a list of channels for.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with the list of channels.
-- @usage discord:getGuildChannels("[guild ID]"):next(function(channels) ... end)
-- @see https://discord.com/developers/docs/resources/guild#get-guild-channels
function DiscordRest:getGuildChannels(guildId, botToken)
	return self:performAuthorizedRequest(routes.guildChannels, {guildId}, nil, "GET", nil, botToken)
end

--- Get a list of integrations for a guild.
-- @param guildId The ID of the guild.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with the list of integrations.
-- @usage discord:getGuildIntegrations("[guild ID]"):next(function(integrations) ... end)
-- @see https://discord.com/developers/docs/resources/guild#get-guild-integrations
function DiscordRest:getGuildIntegrations(guildId, botToken)
	return self:performAuthorizedRequest(routes.integrations, {guildId}, nil, "GET", nil, botToken)
end

--- Get a list of invites for a guild.
-- @param guildId The ID of the guild.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with the list of invites.
-- @usage discord:getGuildInvites("[guild ID]"):next(function(invites) ... end)
-- @see https://discord.com/developers/docs/resources/guild#get-guild-invites
function DiscordRest:getGuildInvites(guildId, botToken)
	return self:performAuthorizedRequest(routes.guildInvites, {guildId}, nil, "GET", nil, botToken)
end

--- Get guild membership info for a user.
-- @param guildId The ID of the guild.
-- @param userId The ID of the user.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise that resolves with the info of the member if they are in the guild.
-- @usage discord:getGuildMember("[guild ID]", "[user ID]"):next(function(member) ... end)
-- @see https://discord.com/developers/docs/resources/guild#get-guild-member
function DiscordRest:getGuildMember(guildId, userId, botToken)
	return self:performAuthorizedRequest(routes.guildMember, {guildId, userId}, nil, "GET", nil, botToken)
end

--- Get preview information for a guild.
-- @param guildId The ID of the guild.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with the preview info for the guild.
-- @usage discord:getGuildPreview("[guild ID]"):next(function(preview) ... end)
-- @see https://discord.com/developers/docs/resources/guild#get-guild-preview
function DiscordRest:getGuildPreview(guildId, botToken)
	return self:performAuthorizedRequest(routes.guildPreview, {guildId}, nil, "GET", nil, botToken)
end

--- Get the number of members that would be removed in a prune operation.
-- @param guildId The ID of the guild that would be pruned.
-- @param options Options for the query.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with the number of users that would be pruned.
-- @usage discord:getGuildPruneCount("[guild ID]"):next(function(pruned) ... end)
-- @see https://discord.com/developers/docs/resources/guild#get-guild-prune-count
function DiscordRest:getGuildPruneCount(guildId, options, botToken)
	return self:performAuthorizedRequest(routes.prune, {guildId}, options, "GET", nil, botToken):next(function(data)
		return data.pruned
	end)
end

--- Get a list of roles for a guild.
-- @param guildId The ID of the guild.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with the list of roles.
-- @usage discord:getGuildRoles("[guild ID]"):next(function(roles) ... end)
-- @see https://discord.com/developers/docs/resources/guild#get-guild-roles
function DiscordRest:getGuildRoles(guildId, botToken)
	return self:performAuthorizedRequest(routes.roles, {guildId}, nil, "GET", nil, botToken)
end

--- Get the vanity URL for a guild.
-- @param guildId The ID of the guild.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with the vanity URL.
-- @usage discord:getGuildVanityUrl("[guild ID]"):next(function(vanityUrl) ... end)
-- @see https://discord.com/developers/docs/resources/guild#get-guild-vanity-url
function DiscordRest:getGuildVanityUrl(guildId, botToken)
	return self:performAuthorizedRequest(routes.vanityUrl, {guildId}, nil, "GET", nil, botToken)
end

--- Get a list of voice regions for a guild.
-- @param guildId The ID of the guild.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with the list of voice regions.
-- @usage discord:getGuildVoiceRegions("[guild ID]"):next(function(regions) ... end)
-- @see https://discord.com/developers/docs/resources/guild#get-guild-voice-regions
function DiscordRest:getGuildVoiceRegions(guildId, botToken)
	return self:performAuthorizedRequest(routes.regions, {guildId}, nil, "GET", nil, botToken)
end

--- Get the welcome screen for a guild.
-- @param guildId The ID of the guild.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with the welcome screen.
-- @usage discord:getGuildWelcomeScreen("[guild ID]"):next(function(welcomeScreen) ... end)
-- @see https://discord.com/developers/docs/resources/guild#get-guild-welcome-screen
function DiscordRest:getGuildWelcomeScreen(guildId, botToken)
	return self:performAuthorizedRequest(routes.welcomeScreen, {guildId}, nil, "GET", nil, botToken)
end

--- Get the widget for a guild.
-- @param guildId The ID of the guild.
-- @return A new promise which is resolved with the widget.
-- @usage discord:getGuildWidget("[guild ID]"):next(function(widget) ... end)
-- @see https://discord.com/developers/docs/resources/guild#get-guild-widget
function DiscordRest:getGuildWidget(guildId)
	return self:performRequest(routes.widgetJson, {guildId}, nil, "GET", nil)
end

--[[
This method can't be implemented as PerformHttpRequest does not work with binary data.

--- Get the widget image for a guild.
-- @param guildId The ID of the guild.
-- @param style Style of the widget image returned.
-- @return A new promise which is resolved with the widget image.
-- @usage discord:getGuildWidgetImage("[guild ID]", "shield"):next(function(image) ... end)
-- @see https://discord.com/developers/docs/resources/guild#get-guild-widget-image
function DiscordRest:getGuildWidgetImage(guildId, style)
	return self:performRequest(routes.widgetImage, {guildId}, options, "GET", nil)
end
]]

--- Get guild widget settings.
-- @param guildId The ID of the guild.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with the widget settings.
-- @usage discord:getGuildWidgetSettings("[guild ID]"):next(function(settings) ... end)
-- @see https://discord.com/developers/docs/resources/guild#get-guild-widget-settings
function DiscordRest:getGuildWidgetSettings(guildId, botToken)
	return self:performAuthorizedRequest(routes.widget, {guildId}, nil, "GET", nil, botToken)
end

--- Returns all active threads in the guild, including public and private threads.
-- @param guildId The ID of the guild.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with the lists of threads and thread members.
-- @usage discord:listActiveGuildThreads("[guild ID]"):next(function(data) ... end)
-- @see https://discord.com/developers/docs/resources/guild#list-active-threads
function DiscordRest:listActiveGuildThreads(guildId, botToken)
	return self:performAuthorizedRequest(routes.guildThreads, {guildId}, nil, "GET", nil, botToken)
end

--- Get a list of members in a guild.
-- @param guildId The ID of the guild to get a list of members for.
-- @param options Options for the query.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with a list of guild members.
-- @usage discord:listGuildMembers("[guild ID]", {limit = 5}):next(function(members) ... end)
-- @see https://discord.com/developers/docs/resources/guild#list-guild-members
function DiscordRest:listGuildMembers(guildId, options, botToken)
	return self:performAuthorizedRequest(routes.guildMembers, {guildId}, options, "GET", nil, botToken)
end

--- Modifies the nickname of the current user in a guild.
-- @param guildId The ID of the guild.
-- @param nick The value to set the user's nickname to.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:modifyCurrentUserNick("[guild ID]", "New nickname")
-- @see https://discord.com/developers/docs/resources/guild#modify-current-user-nick
function DiscordRest:modifyCurrentUserNick(guildId, nick, botToken)
	return self:performAuthorizedRequest(routes.nick, {guildId}, {nick = nick}, "PATCH", nil, botToken)
end

--- Updates the current user's voice state.
-- @param guildId The ID of the guild to modify voice state in.
-- @param params Parameters for modifying the voice state.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:modifyCurrentUserVoiceState("[guild ID]", {...})
-- @see https://discord.com/developers/docs/resources/guild#modify-current-user-voice-state
function DiscordRest:modifyCurrentUserVoiceState(guildId, params, botToken)
	return self:performAuthorizedRequest(routes.myVoiceState, {guildId}, nil, "PATCH", params, botToken)
end

--- Modify a guild's settings.
-- @param guildId The ID of the guild to modify.
-- @param settings The modified settings for the guild.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with the updated guild.
-- @usage discord:modifyGuild("[guild ID]", {name = "New guild name"})
-- @see https://discord.com/developers/docs/resources/guild#modify-guild
function DiscordRest:modifyGuild(guildId, settings, botToken)
	return self:performAuthorizedRequest(routes.guild, {guildId}, nil, "PATCH", params, botToken)
end

--- Modify the positions of a set of channels.
-- @param guildId The ID of the guild containing the channels.
-- @param channelPositions A set of channel position parameters.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:modifyGuildChannelPositions("[guild ID]", {{id = "[channel 1 ID]", position = 2}, {"[channel 2 ID]", position = 1}})
-- @see https://discord.com/developers/docs/resources/guild#modify-guild-channel-positions
function DiscordRest:modifyGuildChannelPositions(guildId, channelPositions, botToken)
	return self:performAuthorizedRequest(routes.guildChannels, {guildId}, nil, "PATCH", channelPositions, botToken)
end

--- Modify guild membership attributes of a user.
-- @param guildId The ID of the guild.
-- @param userId The ID of the member to modify.
-- @param params The parameters to modify.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with the modified guild member.
-- @usage discord:modifyGuildMember("[guild ID]", "[user ID]", {nick = "New nickname"})
-- @see https://discord.com/developers/docs/resources/guild#modify-guild-member
function DiscordRest:modifyGuildMember(guildId, userId, params, botToken)
	return self:performAuthorizedRequest(routes.guildMember, {guildId, userId}, nil, "PATCH", params, botToken)
end

--- Modify a guild role.
-- @param guildId The ID of the guild.
-- @param roleId The ID of the role to modify.
-- @param params Parameters for modifications to the role.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with the modified role.
-- @usage discord:modifyGuildRole("[guild ID]", "[role ID]", {name = "New role name"})
-- @see https://discord.com/developers/docs/resources/guild#modify-guild-role
function DiscordRest:modifyGuildRole(guildId, roleId, params, botToken)
	return self:performAuthorizedRequest(routes.role, {guildId, roleId}, nil, "PATCH", params, botToken)
end

--- Modify the positions of a set of roles for a guild.
-- @param guildId The ID of the guild.
-- @param params A list of roles and their new positions.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with a list of all guild roles.
-- @usage discord:modifyGuildRolePositions("[guild ID]", {{"[role ID 1]", 2}, {"[role ID 2]", 3}, ...})
-- @see https://discord.com/developers/docs/resources/guild#modify-guild-role-positions
function DiscordRest:modifyGuildRolePositions(guildId, params, botToken)
	return self:performAuthorizedRequest(routes.roles, {guildId}, nil, "PATCH", params, botToken)
end

--- Modify a guild's welcome screen.
-- @param guildId The ID of the guild.
-- @param params Parameters for modifying the welcome screen.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with the updated welcome screen.
-- @usage discord:modifyGuildWelcomeScreen("[guild ID]", {enabled = true}):next(function(welcomeScreen) ... end)
-- @see https://discord.com/developers/docs/resources/guild#modify-guild-welcome-screen
function DiscordRest:modifyGuildWelcomeScreen(guildId, params, botToken)
	return self:performAuthorizedRequest(routes.welcomeScreen, {guildId}, nil, "PATCH", params, botToken)
end

--- Modify a guild widget.
-- @param guildId The ID of the guild.
-- @param widget The modified widget attributes.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with the updated widget.
-- @usage discord:modifyGuildWidget("[guild ID]", {...}):next(function(widget) ... end)
-- @see https://discord.com/developers/docs/resources/guild#modify-guild-widget
function DiscordRest:modifyGuildWidget(guildId, widget, botToken)
	return self:performAuthorizedRequest(routes.widget, {guildId}, nil, "PATCH", widget, botToken)
end

--- Updates another user's voice state.
-- @param guildId The ID of the guild.
-- @param userId The ID of the user.
-- @param params Parameters for modifying the voice state.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:modifyUserVoiceState("[guild ID]", "[user ID]", {...})
-- @see https://discord.com/developers/docs/resources/guild#modify-user-voice-state
function DiscordRest:modifyUserVoiceState(guildId, userId, params, botToken)
	return self:performAuthorizedRequest(routes.userVoiceState, {guildId, userId}, nil, "PATCH", params, botToken)
end

--- Remove a guild ban for a user.
-- @param guildId The ID of the guild to remove the ban for the user from.
-- @param userId The ID of the user to unban.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:removeGuildBan("[guild ID]", "[user ID]")
-- @see https://discord.com/developers/docs/resources/guild#remove-guild-ban
function DiscordRest:removeGuildBan(guildId, userId, botToken)
	return self:performAuthorizedRequest(routes.ban, {guildId, userId}, nil, "DELETE", nil, botToken)
end

--- Remove a member from a guild.
-- @param guildId The ID of the guild to remove the member from.
-- @param userId The ID of the member to remove from the guild.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:removeGuildMember("[guild ID]", "[user ID]")
-- @see https://discord.com/developers/docs/resources/guild#remove-guild-member
function DiscordRest:removeGuildMember(guildId, userId, botToken)
	return self:performAuthorizedRequest(routes.guildMember, {guildId, userId}, nil, "DELETE", nil, botToken)
end

--- Removes a role from a guild member.
-- @param guildId The ID of the guild.
-- @param userId The ID of the user to remove the role from.
-- @param roleId The ID of the role to remove from the member.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:removeGuildMemberRole("[guild ID]", "[user ID]", "[role ID]")
-- @see https://discord.com/developers/docs/resources/guild#remove-guild-member-role
function DiscordRest:removeGuildMemberRole(guildId, userId, roleId, botToken)
	return self:performAuthorizedRequest(routes.memberRole, {guildId, userId, roleId}, nil, "DELETE", nil, botToken)
end

--- Get a list of guild members whose username or nickname starts with a provided string.
-- @param guildId The ID of the guild to search in.
-- @param options Options for the query.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with a list of guild members that matched the query.
-- @usage discord:searchGuildMembers("[guild ID]", {query = "Po"}):next(function(members) ... end)
-- @see https://discord.com/developers/docs/resources/guild#search-guild-members
function DiscordRest:searchGuildMembers(guildId, options, botToken)
	return self:performAuthorizedRequest(routes.searchMembers, {guildId}, options, "GET", nil, botToken)
end

--- Invite
-- @section invite

--- Delete an invite.
-- @param inviteCode The code of the invite that will be deleted.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:deleteInvite("[invite code]")
-- @see https://discord.com/developers/docs/resources/invite#delete-invite
function DiscordRest:deleteInvite(inviteCode, botToken)
	return self:performAuthorizedRequest(routes.invite, {inviteCode}, nil, "DELETE", nil, botToken)
end

--- Return info for an invite.
-- @param inviteCode The code of the invite.
-- @param options Options for the query.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with the invite info.
-- @usage discord:getInvite("[invite code]", {with_expiration = true}):next(function(invite) ... end)
-- @see https://discord.com/developers/docs/resources/invite#get-invite
function DiscordRest:getInvite(inviteCode, options, botToken)
	return self:performAuthorizedRequest(routes.invite, {inviteCode}, options, "GET", nil, botToken)
end

--- User
-- @section user

--- Create a new DM channel with a user.
-- @param recipientId The ID of the user to start the DM with.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise that is resolved with the DM channel information.
-- @usage discord:createDm("[recipient ID]"):next(function(channel) ... end)
-- @see https://discord.com/developers/docs/resources/user#create-dm
function DiscordRest:createDm(recipientId, botToken)
	return self:performAuthorizedRequest(routes.createDm, nil, nil, "POST", {recipient_id = recipientId}, botToken)
end

--- Get the current user's information.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with the user's information.
-- @usage discord:getCurrentUser():next(function(user) ... end)
-- @see https://discord.com/developers/docs/resources/user#get-current-user
function DiscordRest:getCurrentUser(botToken)
	return self:performAuthorizedRequest(routes.currentUser, nil, nil, "GET", nil, botToken)
end

--- Get the current user's guilds.
-- @param options Options for the query.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with a list of guilds.
-- @usage discord:getCurrentUserGuilds({limit = 10}):next(function(guilds) ... end)
-- @see https://discord.com/developers/docs/resources/user#get-current-user-guilds
function DiscordRest:getCurrentUserGuilds(options, botToken)
	return self:performAuthorizedRequest(routes.myGuilds, nil, options, "GET", nil, botToken)
end

--- Get user information.
-- @param userId The ID of the user.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:getUser("[user ID]"):next(function(user) ... end)
-- @see https://discord.com/developers/docs/resources/user#get-user
function DiscordRest:getUser(userId, botToken)
	return self:performAuthorizedRequest(routes.user, {userId}, nil, "GET", nil, botToken)
end

--- Get a list of the current user's connections.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with a list of connections.
-- @usage discord:getUserConnections():next(function(connections) ... end)
-- @see https://discord.com/developers/docs/resources/user#get-user-connections
function DiscordRest:getUserConnections(botToken)
	return self:performAuthorizedRequest(routes.myConnections, nil, nil, "GET", nil, botToken)
end

--- Leave a guild.
-- @param guildId The ID of the guild to leave.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:leaveGuild("[guild ID]")
-- @see https://discord.com/developers/docs/resources/user#leave-guild
function DiscordRest:leaveGuild(guildId, botToken)
	return self:performAuthorizedRequest(routes.myGuild, {guildId}, nil, "DELETE", nil, botToken)
end

--- Modify the requester's user account settings.
-- @param params Parameters to modify.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with the modified user.
-- @usage discord:modifyCurrentUser({username = "New Username"}):next(function(user) ... end)
-- @see https://discord.com/developers/docs/resources/user#modify-current-user
function DiscordRest:modifyCurrentUser(params, botToken)
	return self:performAuthorizedRequest(routes.currentUser, nil, nil, "PATCH", params, botToken)
end

--- Webhook
-- @section webhook

--- Delete a webhook.
-- @param webhookId The ID of the webhook.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:deleteWebhook("[webhook ID]")
-- @see https://discord.com/developers/docs/resources/webhook#delete-webhook
function DiscordRest:deleteWebhook(webhookId, botToken)
	return self:performAuthorizedRequest(routes.webhookId, {webhookId}, nil, "DELETE", nil, botToken)
end

--- Deletes a message that was created by the webhook.
-- @param webhookId The ID of the webhook.
-- @param webhookToken The token of the webhook.
-- @param messageId The ID of the message.
-- @return A new promise.
-- @usage discord:deleteWebhookMessage("[webhook ID]", "[webhook token]", "[message ID]")
-- @see https://discord.com/developers/docs/resources/webhook#delete-webhook-message
function DiscordRest:deleteWebhookMessage(webhookId, webhookToken, messageId)
	return self:performRequest(routes.webhookMessage, {webhookId, webhookToken, messageId}, nil, "DELETE")
end

--- Delete a webhook, using its token for authorization instead of a bot token.
-- @param webhookId The ID of the webhook.
-- @param webhookToken The token of the webhook.
-- @return A new promise.
-- @usage discord:deleteWebhookWithToken("[webhook ID]", "[webhook token]")
-- @see https://discord.com/developers/docs/resources/webhook#delete-webhook-with-token
function DiscordRest:deleteWebhookWithToken(webhookId, webhookToken)
	return self:deleteWebhookWithUrl(formatRoute(routes.webhook, {webhookId, webhookToken}))
end

--- Delete a webhook, using its full URL for authorization instead of a bot token.
-- @param url The URL of the webhook.
-- @return A new promise.
-- @usage discord:deleteWebhookWithUrl("https://discord.com/api/webhooks/[webhook ID]/[webhook token]")
-- @see https://discord.com/developers/docs/resources/webhook#delete-webhook-with-token
function DiscordRest:deleteWebhookWithUrl(url)
	return self:performRequestToWebhook(url, nil, "DELETE")
end

--- Edits a previously-sent webhook message from the same token.
-- @param webhookId The ID of the webhook.
-- @param webhookToken The token of the webhook.
-- @param messageId The ID of the message.
-- @param params Parameters to modify.
-- @return A new promise which is resolved with the updated message.
-- @usage discord:editWebhookMessage("[webhook ID]", "[webhook token]", "[message ID]", {content = "New content"}):next(function(message) ... end)
-- @see https://discord.com/developers/docs/resources/webhook#edit-webhook-message
function DiscordRest:editWebhookMessage(webhookId, webhookToken, messageId, params)
	return self:performRequest(routes.webhookMessage, {webhookId, webhookToken, messageId}, nil, "PATCH", params)
end

--- Execute a GitHub webhook.
-- @param webhookId The ID of the webhook.
-- @param webhookToken The token of the webhook.
-- @param data The data to send.
-- @param options Options for the webhook execution.
-- @return A new promise.
-- @usage discord:executeGitHubCompatibleWebhook("[webhook ID]", "[webhook token]", {...})
-- @see https://discord.com/developers/docs/resources/webhook#execute-githubcompatible-webhook
function DiscordRest:executeGitHubCompatibleWebhook(webhookId, webhookToken, data, options)
	return self:executeGitHubCompatibleWebhookUrl(formatRoute(routes.github, {webhookId, webhookToken}), data, options)
end

--- Execute a GitHub webhook, using the full URL.
-- @param url The URL of the webhook.
-- @param data The data to send.
-- @param options Options for the webhook execution.
-- @return A new promise.
-- @usage discord:executeGitHubCompatibleWebhookUrl("https://discord.com/api/webhooks/[webhook ID]/[webhook token]/github", {...})
-- @see https://discord.com/developers/docs/resources/webhook#execute-githubcompatible-webhook
function DiscordRest:executeGitHubCompatibleWebhookUrl(url, data, options)
	return self:performRequestToWebhook(url, options, "POST", data)
end

--- Execute a Slack webhook.
-- @param webhookId The ID of the webhook.
-- @param webhookToken The token of the webhook.
-- @param data The data to send.
-- @param options Options for the webhook execution.
-- @return A new promise.
-- @usage discord:executeSlackCompatibleWebhook("[webhook ID]", "[webhook token]", {text = "hello"})
-- @see https://discord.com/developers/docs/resources/webhook#execute-slackcompatible-webhook
function DiscordRest:executeSlackCompatibleWebhook(webhookId, webhookToken, data, options)
	return self:executeSlackCompatibleWebhookUrl(formatRoute(routes.slack, {webhookId, webhookToken}), data, options)
end

--- Execute a Slack webhook, using the full URL.
-- @param url The webhook URL.
-- @param data The data to send.
-- @param options Options for the webhook execution.
-- @return A new promise.
-- @usage discord:executeSlackCompatibleWebhookUrl("https://discord.com/api/webhooks/[webhook ID]/[webhook token]/slack", {text = "hello"})
-- @see https://discord.com/developers/docs/resources/webhook#execute-slackcompatible-webhook
function DiscordRest:executeSlackCompatibleWebhookUrl(url, data, options)
	return self:performRequestToWebhook(url, options, "POST", data)
end

--- Execute a webhook.
-- @param webhookId The ID of the webhook.
-- @param webhookToken The token for the webhook.
-- @param data The data to send.
-- @param options Options for the webhook execution.
-- @return A new promise.
-- @usage discord:executeWebhook("[webhook ID]", "[webhook token]", {content = "Hello, world!"})
-- @see https://discord.com/developers/docs/resources/webhook#execute-webhook
function DiscordRest:executeWebhook(webhookId, webhookToken, data, options)
	return self:executeWebhookUrl(formatRoute(routes.webhook, {webhookId, webhookToken}), data, options)
end

--- Execute a webhook, using the full URL.
-- @param url The webhook URL.
-- @param data The data to send.
-- @param options Options for the webhook execution.
-- @return A new promise.
-- @usage discord:executeWebhookUrl("https://discord.com/api/webhooks/[webhook ID]/[webhook token]", {content = "Hello, world!"})
-- @see https://discord.com/developers/docs/resources/webhook#execute-webhook
function DiscordRest:executeWebhookUrl(url, data, options)
	return self:performRequestToWebhook(url, options, "POST", data)
end

--- Get a list of webhooks for a channel.
-- @param channelId The ID of the channel.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with a list of webhooks.
-- @usage discord:getChannelWebhooks("[channel ID]"):next(function(webhooks) ... end)
-- @see https://discord.com/developers/docs/resources/webhook#get-channel-webhooks
function DiscordRest:getChannelWebhooks(channelId, botToken)
	return self:performAuthorizedRequest(routes.webhooks, {channelId}, nil, "GET", nil, botToken)
end

--- Get a list of webhooks for a guild.
-- @param guildId The ID of the guild.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with a list of webhooks.
-- @usage discord:getGuildWebhooks("[guild ID]"):next(function(webhooks) ... end)
-- @see https://discord.com/developers/docs/resources/webhook#get-guild-webhooks
function DiscordRest:getGuildWebhooks(guildId, botToken)
	return self:performAuthorizedRequest(routes.guildWebhooks, {guildId}, nil, "GET", nil, botToken)
end

--- Get information for a webhook.
-- @param webhookId The ID of the webhook.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with the webhook.
-- @usage discord:getWebhook("[webhook ID]"):next(function(webhook) ... end)
-- @see https://discord.com/developers/docs/resources/webhook#get-webhook
function DiscordRest:getWebhook(webhookId, botToken)
	return self:performAuthorizedRequest(routes.webhookId, {webhookId}, nil, "GET", nil, botToken)
end

--- Returns a previously-sent webhook message from the same token.
-- @param webhookId The ID of the webhook.
-- @param webhookToken The token of the webhook.
-- @param messageId The ID of the message.
-- @return A new promise which is resolved with the message.
-- @usage discord:getWebhookMessage("[webhook ID]", "[webhook token]", "[message ID]"):next(function(message) ... end)
-- @see https://discord.com/developers/docs/resources/webhook#get-webhook-message
function DiscordRest:getWebhookMessage(webhookId, webhookToken, messageId)
	return self:performRequest(routes.webhookMessage, {webhookId, webhookToken, messageId}, nil, "GET", nil, botToken)
end

--- Get information for a webhook, using its token for authorization instead of a bot token.
-- @param webhookId The ID of the webhook.
-- @param webhookToken The token of the webhook.
-- @return A new promise which is resolved with the webhook.
-- @usage discord:getWebhookWithToken("[webhook ID]", "[webhook token]"):next(function(webhook) ... end)
-- @see https://discord.com/developers/docs/resources/webhook#get-webhook-with-token
function DiscordRest:getWebhookWithToken(webhookId, webhookToken)
	return self:getWebhookWithUrl(formatRoute(routes.webhook, {webhookId, webhookToken}))
end

--- Get information for a webhook, using its full URL for authorization instead of a bot token.
-- @param url The webhook URL.
-- @return A new promise which is resolved with the webhook.
-- @usage discord:getWebhookWithUrl("https://discord.com/api/webhooks/[webhook ID]/[webhook token]"):next(function(webhook) ... end)
-- @see https://discord.com/developers/docs/resources/webhook#get-webhook-with-token
function DiscordRest:getWebhookWithUrl(url)
	return self:performRequestToWebhook(url, nil, "GET")
end

--- Modify a webhook.
-- @param webhookId The ID of the webhook.
-- @param params Parameters to modify.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with the updated webhook.
-- @usage discord:modifyWebhook("[webhook ID]", {name = "New name"}):next(function(webhook) ... end)
-- @see https://discord.com/developers/docs/resources/webhook#modify-webhook
function DiscordRest:modifyWebhook(webhookId, params, botToken)
	return self:performAuthorizedRequest(routes.webhookId, {webhookId}, nil, "PATCH", params, botToken)
end

--- Modify a webhook, using its token for authorization instead of a bot token.
-- @param webhookId The ID of the webhook.
-- @param webhookToken The token of the webhook.
-- @param params Parameters to modify.
-- @return A new promise which is resolved with the updated webhook.
-- @usage discord:modifyWebhookWithToken("[webhook ID]", "[webhook token]", {name = "New name"}):next(function(webhook) ... end)
-- @see https://discord.com/developers/docs/resources/webhook#modify-webhook-with-token
function DiscordRest:modifyWebhookWithToken(webhookId, webhookToken, params)
	return self:modifyWebhookWithUrl(formatRoute(routes.webhook, {webhookId, webhookToken}), params)
end

--- Modify a webhook, using its full URL for authorization instead of a bot token.
-- @param url The URL of the webhook.
-- @param params Parameters to modify.
-- @return A new promise which is resolved with the updated webhook.
-- @usage discord:modifyWebhookWithUrl("https://discord.com/api/webhooks/[webhook ID]/[webhook token]", {name = "New name"}):next(function(webhook) ... end)
-- @see https://discord.com/developers/docs/resources/webhook#modify-webhook-with-token
function DiscordRest:modifyWebhookWithUrl(url, params)
	return self:performRequestToWebhook(url, nil, "PATCH", params)
end

--- Player.
-- Wrapper functions that allow you to use a player's server ID in place of a Discord user ID.
-- @section player

--- Get the Discord user ID of a player.
-- @param player The server ID of the player.
-- @return A new promise which is resolved with the player's Discord user ID, if they have one.
-- @usage discord:getUserId(1):next(function(userId) ... end)
function DiscordRest:getUserId(player)
	local p = promise.new()

	for _, identifier in ipairs(GetPlayerIdentifiers(player)) do
		if identifier:sub(1, 8) == "discord:" then
			return p:resolve(identifier:sub(9))
		end
	end

	return p:reject(("Player %d has no Discord identifier"):format(player))
end

--- Adds a guild role to a player.
-- @param guildId The ID of the guild.
-- @param player The server ID of the player to add the role to.
-- @param roleId The ID of the role to add to the member.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:addGuildMemberRoleToPlayer("[guild ID]", 1, "[role ID]")
-- @see DiscordRest:addGuildMemberRole
function DiscordRest:addGuildMemberRoleToPlayer(guildId, player, roleId, botToken)
	return self:getUserId(player):next(function(userId)
		return self:addGuildMemberRole(guildId, userId, roleId, botToken)
	end)
end

--- Adds a player to a guild.
-- @param guildId The ID of the guild to add the user to.
-- @param player The server ID of the player to add to the guild.
-- @param params Parameters for adding the user.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:addPlayerToGuild("[guild ID]", 1, {access_token = "..."})
-- @see DiscordRest:addGuildMember
function DiscordRest:addPlayerToGuild(guildId, player, params, botToken)
	return self:getUserId(player):next(function(userId)
		return self:addGuildMember(guildId, userId, player, params, botToken)
	end)
end

--- Adds a player to a thread.
-- @param channelId The ID of the thread channel.
-- @param player The server ID of the player to add to the thread.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:addPlayerToThread("[channel ID]", 1)
-- @see DiscordRest:addThreadMember
function DiscordRest:addPlayerToThread(channelId, player, botToken)
	return self:getUserId(player):next(function(userId)
		return self:addThreadMember(channelId, userId, botToken)
	end)
end

--- Create a guild ban for a player.
-- @param guildId The ID of the guild to create the ban for.
-- @param player The server ID of the player to ban.
-- @param params Parameters for the ban.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:createGuildBanForPlayer("[guild ID]", 1, {reason = "Not following the rules"})
-- @see DiscordRest:createGuildBan
function DiscordRest:createGuildBanForPlayer(guildId, player, params, botToken)
	return self:getUserId(player):next(function(userId)
		return self:createGuildBan(guildId, userId, params, botToken)
	end)
end

--- Remove a player's reaction from a message.
-- @param channelId The ID of the channel containing the message.
-- @param messageId The message to remove the reaction from.
-- @param emoji The emoji of the reaction to remove.
-- @param player The server ID of the player whose reaction will be removed.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:deletePlayerReaction("[channel ID]", "[message ID]", "💗", 1)
-- @see DiscordRest:deleteUserReaction
function DiscordRest:deletePlayerReaction(channelId, messageId, emoji, player, botToken)
	return self:getUserId(player):next(function(userId)
		return self:deleteUserReaction(channelId, messageId, emoji, userId, botToken)
	end)
end

--- Return info on a ban for a player in a guild.
-- @param guildId The ID of the guild.
-- @param player The server ID of the banned player.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with the ban info.
-- @usage discord:getGuildBanForPlayer("[guild ID]", 1):next(function(ban) ... end)
-- @see DiscordRest:getGuildBan
function DiscordRest:getGuildBanForPlayer(guildId, player, botToken)
	return self:getUserId(player):next(function(userId)
		return self:getGuildBan(guildId, userId, botToken)
	end)
end

--- Get guild membership info for a player.
-- @param guildId The ID of the guild.
-- @param player The server ID of the player.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise that resolves with the info of the member if they are in the guild.
-- @usage discord:getGuildMember("[guild ID]", 1):next(function(member) ... end)
-- @see DiscordRest:getGuildMember
function DiscordRest:getGuildMemberForPlayer(guildId, player, botToken)
	return self:getUserId(player):next(function(userId)
		return self:getGuildMember(guildId, userId, botToken)
	end)
end

--- Get user information for a player.
-- @param player The server ID of the player.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:getUserForPlayer(1):next(function(user) ... end)
-- @see DiscordRest:getUser
function DiscordRest:getUserForPlayer(player, botToken)
	return self:getUserId(player):next(function(userId)
		return self:getUser(userId, botToken)
	end)
end

--- Adds a player to a Group DM.
-- @param channelId The ID of the group DM channel.
-- @param player The server ID of the player to add.
-- @param params Parameters for adding the user.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:groupDmAddPlayer("[channel ID]", 1, {access_token = "..."})
-- @see DiscordRest:groupDmAddRecipient
function DiscordRest:groupDmAddPlayer(channelId, player, params, botToken)
	return self:getUserId(player):next(function(userId)
		return self:groupDmAddRecipient(channelId, userId, params, botToken)
	end)
end

--- Removes a player from a Group DM.
-- @param channelId The ID of the group DM channel.
-- @param player The server ID of the player to remove.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:groupDmRemovePlayer("[channel ID]", 1)
-- @see DiscordRest:groupDmRemoveRecipient
function DiscordRest:groupDmRemovePlayer(channelId, player, botToken)
	return self:getUserId(player):next(function(userId)
		return self:groupDmRemoveRecipient(channelId, userId, botToken)
	end)
end

--- Modify guild membership attributes of a player.
-- @param guildId The ID of the guild.
-- @param player The server ID of the player.
-- @param params The parameters to modify.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with the modified guild member.
-- @usage discord:modifyGuildMember("[guild ID]", 1, {nick = "New nickname"})
-- @see DiscordRest:modifyGuildMember
function DiscordRest:modifyGuildMemberForPlayer(guildId, player, params, botToken)
	return self:getUserId(player):next(function(userId)
		return self:modifyGuildMember(guildId, userId, params, botToken)
	end)
end

--- Updates a player's voice state.
-- @param guildId The ID of the guild.
-- @param player The server ID of the player.
-- @param params Parameters for modifying the voice state.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:modifyPlayerVoiceState("[guild ID]", 1, {...})
-- @see DiscordRest:modifyUserVoiceState
function DiscordRest:modifyPlayerVoiceState(guildId, player, params, botToken)
	return self:getUserId(player):next(function(userId)
		return self:modifyUserVoiceState(guildId, userId, params, botToken)
	end)
end

--- Remove a guild ban for a player.
-- @param guildId The ID of the guild to remove the ban for the user from.
-- @param player The server ID of the user to unban.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:removeGuildBanForPlayer("[guild ID]", 1)
-- @see DiscordRest:removeGuildBan
function DiscordRest:removeGuildBanForPlayer(guildId, player, botToken)
	return self:getUserId(player):next(function(userId)
		return self:removeGuildBan(guildId, userId, botToken)
	end)
end

--- Removes a guild role from a player.
-- @param guildId The ID of the guild.
-- @param player The server ID of the player to remove the role from.
-- @param roleId The ID of the role to remove from the member.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:removeGuildMemberRoleFromPlayer("[guild ID]", 1, "[role ID]")
-- @see DiscordRest:removeGuildMemberRole
function DiscordRest:removeGuildMemberRoleFromPlayer(guildId, player, roleId, botToken)
	return self:getUserId(player):next(function(userId)
		return self:removeGuildMemberRole(guildId, userId, roleId, botToken)
	end)
end

--- Remove a player from a guild.
-- @param guildId The ID of the guild to remove the member from.
-- @param player The server ID of the player to remove from the guild.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:removePlayerFromGuild("[guild ID]", 1)
-- @see DiscordRest:removeGuildMember
function DiscordRest:removePlayerFromGuild(guildId, player, botToken)
	return self:getUserId(player):next(function(userId)
		return self:removeGuildMember(guildId, userId, botToken)
	end)
end

--- Remove a player from a thread.
-- @param channelId The ID of the thread channel.
-- @param player The server ID of the player to remove from the thread.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:removePlayerFromThread("[channel ID]", 1)
-- @see DiscordRest:removeThreadMember
function DiscordRest:removePlayerFromThread(channelId, player, botToken)
	return self:getUserId(player):next(function(userId)
		return self:removeThreadMember(channelId, userId, botToken)
	end)
end
