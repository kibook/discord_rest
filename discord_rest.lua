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
	followers      = "/channels/%s/followers",
	groupDm        = "/channels/%s/recipients/%s",
	guild          = "/guilds/%s",
	guildChannels  = "/guilds/%s/channels",
	guildEmoji     = "/guilds/%s/emojis/%s",
	guildEmojis    = "/guilds/%s/emojis",
	guildMember    = "/guilds/%s/members/%s",
	guildMembers   = "/guilds/%s/members",
	guildPreview   = "/guilds/%s/preview",
	guilds         = "/guilds",
	guildThreads   = "/guilds/%s/threads/active",
	invite         = "/invites/%s",
	joinedThreads  = "/channels/%s/users/@me/threads/archived/private",
	memberRole     = "/guilds/%s/members/%s/roles/%s",
	message        = "/channels/%s/messages/%s",
	messages       = "/channels/%s/messages",
	messageThreads = "/channels/%s/messages/%s/threads",
	nick           = "/guilds/%s/members/@me/nick",
	ownReaction    = "/channels/%s/messages/%s/reactions/%s/@me",
	pinMessage     = "/channels/%s/pins/%s",
	pins           = "/channels/%s/pins",
	privateThreads = "/channels/%s/threads/archived/private",
	publicThreads  = "/channels/%s/threads/archived/public",
	reaction       = "/channels/%s/messages/%s/reactions/%s",
	reactions      = "/channels/%s/messages/%s/reactions",
	roles          = "/guilds/%s/roles",
	searchMembers  = "/guilds/%s/members/search",
	threadMembers  = "/channels/%s/thread-members",
	threadSelf     = "/channels/%s/thread-members/@me",
	threadUser     = "/channels/%s/thread-members/%s",
	typing         = "/channels/%s/typing",
	userReaction   = "/channels/%s/messages/%s/reactions/%s/%s",
	user           = "/users/%s",
	webhook        = "/webhooks/%s/%s",
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
			p:resolve(json.decode(data) or status)
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
	return #self.items > 0 and (self.rateLimitRemaining > 0 or os.time() - self.rateLimitReset > 5)
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

function RateLimitQueue:decrementRateLimitRemaining()
	self.rateLimitRemaining = self.rateLimitRemaining - 1
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
			return true
		end
	end

	return false
end

-- Handle HTTP responses from the Discord REST API
function DiscordRest:handleResponse(queue, url, status, text, headers, callback)
	if isResponseError(status) then
		-- No access to headers/body if status > 400, so can't read rate limit info or use Retry-After:
		-- https://github.com/citizenfx/fivem/blob/6a83275c44a0044b4765e7865f73ca670de45cc3/code/components/http-client/src/HttpClient.cpp#L114
		if status == 429 then
			print(("Rate limiting detected for %s"):format(url))

			queue:setRateLimitRemaining(0)
			queue:setRateLimitReset(os.time() + 5)
		else
			queue:decrementRateLimitRemaining()
		end
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
		local p = promise.new()

		PerformHttpRequest(url,
			function(status, data, headers)
				p:resolve()
				self:handleResponse(queue, url, status, data, headers, callback)
			end,
			method, data, headers)

		Citizen.Await(p)
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
-- @param Parameters for adding the user.
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

--- Get info for a member of a guild.
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

--- Get a list of roles for a guild.
-- @param guildId The ID of the guild.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with the list of roles.
-- @usage discord:getGuildRoles("[guild ID]"):next(function(roles) ... end)
-- @see https://discord.com/developers/docs/resources/guild#get-guild-roles
function DiscordRest:getGuildRoles(guildId, botToken)
	return self:performAuthorizedRequest(routes.roles, {guildId}, nil, "GET", nil, botToken)
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

--- Modify attributes of a guild member.
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

--- Remove the ban for a user.
-- @param guildId The ID of the guild to remove the ban for the user from.
-- @param userId The ID of the user to unban.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:removeGuildBan("[guild ID]", "[user ID]")
-- @see https://discord.com/developers/docs/resources/guild#remove-guild-ban
function DiscordRest:removeGuilBan(guildId, userId, botToken)
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

--- Execute a webhook.
-- @param webhookId The ID of the webhook.
-- @param webhookToken The token for the webhook.
-- @param data The data to send.
-- @return A new promise.
-- @usage discord:executeWebhook("[webhook ID]", "[webhook token]", {content = "Hello, world!"})
-- @see https://discord.com/developers/docs/resources/webhook#execute-webhook
function DiscordRest:executeWebhook(webhookId, webhookToken, data)
	return self:executeWebhookUrl(formatRoute(routes.webhook, {webhookId, webhookToken}), data)
end

--- Execute a webhook, using the full URL.
-- @param url The webhook URL.
-- @param data The data to send.
-- @return A new promise.
-- @usage discord:executeWebhookUrl("https://discord.com/api/webhooks/[webhook ID]/[webhook token]", {content = "Hello, world!"})
-- @see https://discord.com/developers/docs/resources/webhook#execute-webhook
function DiscordRest:executeWebhookUrl(url, data)
	local queue = self:getQueue(url)
	local p = promise.new()
	self:enqueueRequest(queue, url, createSimplePromiseCallback(p), "POST", data)
	return p
end
