--- Discord REST API export functions

local discordRest = DiscordRest:new(Config.botToken)

--- Channel
-- @section channel

--- Adds another member to a thread.
-- @function addThreadMember
-- @param channelId The ID of the thread channel.
-- @param userId The ID of the user to add to the thread.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage discord:addThreadMember("[channel ID]", "[user ID]")
-- @see https://discord.com/developers/docs/resources/channel#add-thread-member
exports("addThreadMember", function(channelId, userId, botToken)
	return discordRest:addThreadMember(channelId, userId, botToken)
end)

--- Delete multiple messages in a single request.
-- @function bulkDeleteMessages
-- @param channelId The ID of the channel containing the messages.
-- @param messages A list of message IDs to delete (2-100).
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage exports.discord_rest:bulkDeleteMessages("[channel ID]", {"[message ID 1]", "[message ID 2]", ...}, "[bot token]")
-- @see https://discord.com/developers/docs/resources/channel#bulk-delete-messages
exports("bulkDeleteMessages", function(channelId, messages, botToken)
	return discordRest:bulkDeleteMessages(channelId, messages, botToken)
end)

--- Create a new invite for a channel.
-- @function createChannelInvite
-- @param channelId The ID of the channel to create an invite for.
-- @param invite The invite settings.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise that resolves with the newly created invite.
-- @usage exports.discord_rest:createChannelInvite("[channel ID]", {max_age = 3600, max_uses = 1})
-- @see https://discord.com/developers/docs/resources/channel#create-channel-invite
exports("createChannelInvite", function(channelId, invite, botToken)
	return discordRest:createChannelInvite(channelId, invite, botToken)
end)

--- Post a message.
-- @function createMessage
-- @param channelId The ID of the channel to post in.
-- @param message The message parameters.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved when the message is posted.
-- @usage exports.discord_rest:createMessage("[channel ID]", {content = "Hello, world!"}, "[bot token]")
-- @see https://discord.com/developers/docs/resources/channel#create-message
exports("createMessage", function(channelId, message, botToken)
	return discordRest:createMessage(channelId, message, botToken)
end)

--- Create a reaction for a message.
-- @function createReaction
-- @param channelId The ID of the channel containing the message.
-- @param messageId The ID of the message to add a reaction to.
-- @param emoji The name of the emoji to react with.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved when the reaction is added to the message.
-- @usage exports.discord_rest:createReaction("[channel ID]", "[message ID]", "💗", "[bot token]")
-- @see https://discord.com/developers/docs/resources/channel#create-reaction
exports("createReaction", function(channelId, messageId, emoji, botToken)
	return discordRest:createReaction(channelId, messageId, emoji, botToken)
end)

--- Crosspost a message in a News Channel to following channels.
-- @function crosspostMessage
-- @param channelId The ID of the channel containing the message.
-- @param messageId The ID of the message to crosspost.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with the crossposted message.
-- @usage exports.discord_rest:crosspostMessage("[channel ID]", "[message ID]", "[bot token]")
-- @see https://discord.com/developers/docs/resources/channel#crosspost-message
exports("crosspostMessage", function(channelId, messageId, botToken)
	return discordRest:crosspostMessage(channelId, messageId, botToken)
end)

--- Deletes all reactions on a message.
-- @function deleteAllReactions
-- @param channelId The ID of the channel containing the message.
-- @param messageId The ID of the message whose reactions will be deleted.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage exports.discord_rest:deleteAllReactions("[channel ID]", "[message ID]", "[bot token]")
-- @see https://discord.com/developers/docs/resources/channel#delete-all-reactions
exports("deleteAllReactions", function(channelId, messageId, botToken)
	return discordRest:deleteAllReactions(channelId, messageId, botToken)
end)

--- Deletes all the reactions for a given emoji on a message.
-- @function deleteAllReactionsForEmoji
-- @param channelId The ID of the channel containing the message.
-- @param messageId The ID of the message to delete reactions from.
-- @param emoji The emoji of the reaction to delete.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage exports.discord_rest:deleteAllReactionsForEmoji("[channel ID]", "[message ID]", "💗", "[bot token]")
-- @see https://discord.com/developers/docs/resources/channel#delete-all-reactions-for-emoji
exports("deleteAllReactionsForEmoji", function(channelId, messageId, emoji, botToken)
	return discordRest:deleteAllReactionsForEmoji(channelId, messageId, emoji, botToken)
end)

--- Delete a channel.
-- @function deleteChannel
-- @param channelId The ID of the channel.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage exports.discord_rest:deleteChannel("[channel ID]", "[bot token]")
-- @see https://discord.com/developers/docs/resources/channel#deleteclose-channel
exports("deleteChannel", function(channelId, botToken)
	return discordRest:deleteChannel(channelId, botToken)
end)

--- Delete a channel permission overwrite for a user or role in a channel.
-- @function deleteChannelPermission
-- @param channelId The ID of the channel.
-- @param overwriteId The ID of the user or role to remove permissions for.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage exports.discord_rest:deleteChannelPermission("[channel ID]", "[overwrite ID]", "[bot token]")
-- @see https://discord.com/developers/docs/resources/channel#delete-channel-permission
exports("deleteChannelPermission", function(channelId, overwriteId, botToken)
	return discordRest:deleteChannelPermission(channelId, overwriteId, botToken)
end)

--- Delete a message from a channel.
-- @function deleteMessage
-- @param channelId The ID of the channel.
-- @param messageId The ID of the message.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage exports.discord_rest:deleteMessage("[channel ID]", "[message ID]", "[bot token]")
-- @see https://discord.com/developers/docs/resources/channel#delete-message
exports("deleteMessage", function(channelId, messageId, botToken)
	return discordRest:deleteMessage(channelId, messageId, botToken)
end)

--- Remove own reaction from a message.
-- @function deleteOwnReaction
-- @param channelId The ID of the channel containing the message.
-- @param messageId The ID of the message to remove the reaction from.
-- @param emoji The emoji of the reaction to remove.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage exports.discord_rest:deleteOwnReaction("[channel ID]", "[message ID]", "💗", "[bot token]")
-- @see https://discord.com/developers/docs/resources/channel#delete-own-reaction
exports("deleteOwnReaction", function(channelId, messageId, emoji, botToken)
	return discordRest:deleteOwnReaction(channelId, messageId, emoji, botToken)
end)

--- Remove a user's reaction from a message.
-- @function deleteUserReaction
-- @param channelId The ID of the channel containing the message.
-- @param messageId The ID of the message to remove the reaction from.
-- @param emoji The emoji of the reaction to remove.
-- @param userId The ID of the user whose reaction will be removed.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage exports.discord_rest:deleteOwnReaction("[channel ID]", "[message ID]", "💗", "[bot token]")
-- @see https://discord.com/developers/docs/resources/channel#delete-user-reaction
exports("deleteUserReaction", function(channelId, messageId, emoji, userId, botToken)
	return discordRest:deleteUserReaction(channelId, messageId, emoji, userId, botToken)
end)

--- Edit the channel permission overwrites for a user or role in a channel.
-- @function editChannelPermissions
-- @param channelId The ID of the channel to edit the permissions of.
-- @param overwriteId The ID of the user or role to edit permissions for.
-- @param permissions The permissions to set.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage exports.discord_rest:editChannelPermissions("[channel ID]", "[overwrite ID]", {allow = 6, deny = 8, type = 0})
-- @see https://discord.com/developers/docs/resources/channel#edit-channel-permissions
exports("editChannelPermissions", function(channelId, overwriteId, permissions, botToken)
	return discordRest:editChannelPermissions(channelId, overwriteId, permissions, botToken)
end)

--- Edit a previously sent message.
-- @function editMessage
-- @param channelId The ID of the channel containing the message.
-- @param messageId The ID of the message to edit.
-- @param message The edited message.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise, which resolves with the edited message when the request is completed.
-- @usage exports.discord_rest:editMessage("[channel ID]", "[message ID]", {content = "I edited this message!"}, "[bot token]")
-- @see https://discord.com/developers/docs/resources/channel#edit-message
exports("editMessage", function(channelId, messageId, message, botToken)
	return discordRest:editMessage(channelId, messageId, message, botToken)
end)

--- Follow a News Channel to send messages to a target channel.
-- @function followNewsChannel
-- @param channelId The ID of the news channel.
-- @param targetChannelId The ID of the target channel.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise that resolves with a followed channel object.
-- @usage exports.discord_rest:followNewsChannel("[channel ID]", "[target channel ID]", "[bot token]")
-- @see https://discord.com/developers/docs/resources/channel#follow-news-channel
exports("followNewsChannel", function(channelId, targetChannelId, botToken)
	return discordRest:followNewsChannel(channelId, targetChannelId, botToken)
end)

--- Get channel information.
-- @function getChannel
-- @param channelId The ID of the channel.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage exports.discord_rest:getChannel("[channel ID]", "[bot token]"):next(function(channel) ... end)
-- @see https://discord.com/developers/docs/resources/channel#get-channel
exports("getChannel", function(channelId, botToken)
	return discordRest:getChannel(channelId, botToken)
end)

--- Get a list of invites for a channel.
-- @function getChannelInvites
-- @param channelId The ID of the channel to get invites for.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise that resolves with the list of invites.
-- @usage exports.discord_rest:getChannelInvites("[channel ID]", "[bot token]"):next(function(invites) ... end)
-- @see https://discord.com/developers/docs/resources/channel#get-channel-invites
exports("getChannelInvites", function(channelId, botToken)
	return discordRest:getChannelInvites(channelId, botToken)
end)

--- Get a specific message from a channel.
-- @function getChannelMessage
-- @param channelId The ID of the channel.
-- @param messageId The ID of the message.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage exports.discord_rest:getChannelMessage("[channel ID]", "[messageId]", "[bot token]")
-- @see https://discord.com/developers/docs/resources/channel#get-channel-message
exports("getChannelMessage", function(channelId, messageId, botToken)
	return discordRest:getChannelMessage(channelId, messageId, botToken)
end)

--- Get messages from a channel.
-- @function getChannelMessages
-- @param channelId The ID of the channel.
-- @param options Options to tailor the query.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage exports.discord_rest:getChannelMessages("[channel ID]", {limit = 1}, "[bot token]"):next(function(messages) ... end)
-- @see https://discord.com/developers/docs/resources/channel#get-channel-messages
exports("getChannelMessages", function(channelId, options, botToken)
	return discordRest:getChannelMessages(channelId, options, botToken)
end)

--- Returns all pinned messages in the channel.
-- @function getPinnedMessages
-- @param channelId The ID of the channel to get pinned messages from.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which resolves with a list of pinned messages.
-- @usage exports.discord_rest:getPinnedMessages("[channel ID]", "[bot token]")
-- @see https://discord.com/developers/docs/resources/channel#get-pinned-messages
exports("getPinnedMessages", function(channelId, botToken)
	return discordRest:getPinnedMessages(channelId, botToken)
end)

--- Get a list of users that reacted to a message with a specific emoji.
-- @function getReactions
-- @param channelId The ID of the channel containing the message.
-- @param messageId The ID of the message to get reactions from.
-- @param emoji The emoji of the reaction.
-- @param options Options to tailor the query.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage exports.discord_rest:getReactions("[channel ID]", "[message ID]", "💗", nil, "[bot token]"):next(function(users) ... end)
-- @see https://discord.com/developers/docs/resources/channel#get-reactions
exports("getReactions", function(channelId, messageId, emoji, options, botToken)
	return discordRest:getReactions(channelId, messageId, emoji, options, botToken)
end)

--- Adds a recipient to a Group DM using their access token.
-- @function groupDmAddRecipient
-- @param channelId The ID of the group DM channel.
-- @param userId The ID of the user to add.
-- @param params Parameters for adding the user.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage exports.discord_rest:groupDmAddRecipient("[channel ID]", "[user ID]", {access_token = "..."}, "[bot token]")
-- @see https://discord.com/developers/docs/resources/channel#group-dm-add-recipient
exports("groupDmAddRecipient", function(channelId, userId, params, botToken)
	return discordRest:groupDmAddRecipient(channelId, userId, params, botToken)
end)

--- Removes a recipient from a Group DM.
-- @function groupDmRemoveRecipient
-- @param channelId The ID of the group DM channel.
-- @param userId The ID of the user to remove.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage exports.discord_rest:groupDmRemoveRecipient("[channel ID]", "[user ID]", "[bot token]")
-- @see https://discord.com/developers/docs/resources/channel#group-dm-remove-recipient
exports("groupDmRemoveRecipient", function(channelId, userId, botToken)
	return discordRest:groupDmRemoveRecipient(channelId, userId, botToken)
end)

--- Adds the current user to a thread.
-- @function joinThread
-- @param channelId The ID of the thread channel to join.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage exports.discord_rest:joinThread("[channel ID]", "[bot token]")
-- @see https://discord.com/developers/docs/resources/channel#join-thread
exports("joinThread", function(channelId, botToken)
	return discordRest:joinThread(channelId, botToken)
end)

--- Removes the current user from a thread.
-- @function leaveThread
-- @param channelId The ID of the thread channel to leave.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage exports.discord_rest:leaveThread("[channel ID]", "[bot token]")
-- @see https://discord.com/developers/docs/resources/channel#leave-thread
exports("leaveThread", function(channelId, botToken)
	return discordRest:leaveThread(channelId, botToken)
end)

--- Returns all active threads in the channel, including public and private threads.
-- @function listActiveThreads
-- @param channelId The ID of the channel to get a list of active threads for.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with a list of information on active threads.
-- @usage exports.discord_rest:listActiveThreads("[channel ID]"):next(function(data) ... end)
-- @see https://discord.com/developers/docs/resources/channel#list-active-threads
exports("listActiveThreads", function(channelId, botToken)
	return discordRest:listActiveThreads(channelId, botToken)
end)

--- Returns archived threads in the channel that are private.
-- @function listPrivateArchivedThreads
-- @param channelId The ID of the channel to get a list of private archived threads from.
-- @param options Options for the query.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with a table of information on private archived threads.
-- @usage exports.discord_rest:listPrivateArchivedThreads("[channel ID]", {limit = 5}, "[bot token]"):next(function(data) ... end)
-- @see https://discord.com/developers/docs/resources/channel#list-private-archived-threads
exports("listPrivateArchivedThreads", function(channelId, options, botToken)
	return discordRest:listPrivateArchivedThreads(channelId, options, botToken)
end)

--- Returns archived threads in the channel that are public.
-- @functon listPublicArchivedThreads
-- @param channelId The ID of the channel to get a list of public archived threads for.
-- @param options Options for the query.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with a table of information on public archived threads.
-- @usage exports.discord_rest:listPublicArchivedThreads("[channel ID]", {limit = 5}, "[bot token]"):next(function(data) ... end)
-- @see https://discord.com/developers/docs/resources/channel#list-public-archived-threads
exports("listPublicArchivedThreads", function(channelId, options, botToken)
	return discordRest:listPublicArchivedThreads(channelId, options, botToken)
end)

--- Get a list of members of a thread.
-- @function listThreadMembers
-- @param channelId The ID of the thread channel.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with a list of members of the thread.
-- @usage exports.discord_rest:listThreadMembers("[channel ID]", "[bot token]"):next(function(members) ... end)
-- @see https://discord.com/developers/docs/resources/channel#list-thread-members
exports("listThreadMembers", function(channelId, botToken)
	return discordRest:listThreadMembers(channelId, botToken)
end)

--- Update a channel's settings.
-- @function modifyChannel
-- @param channelId The ID of the channel.
-- @param channel The new channel settings.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage exports.discord_rest:modifyChannel("[channel ID]", {name = "new-name"}, "[bot token]")
-- @see https://discord.com/developers/docs/resources/channel#modify-channel
exports("modifyChannel", function(channelId, channel, botToken)
	return discordRest:modifyChannel(channelId, channel, botToken)
end)

--- Pin a message in a channel.
-- @function pinMessage
-- @param channelId The ID of the channel containing the message.
-- @param messageId The ID of the message to pin.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage exports.discord_rest:pinMessage("[channel ID]", "[message ID]", "[bot token]")
-- @see https://discord.com/developers/docs/resources/channel#pin-message
exports("pinMessage", function(channelId, messageId, botToken)
	return discordRest:pinMessage(channelId, messageId, botToken)
end)

--- Removes another member from a thread.
-- @function removeThreadMember
-- @param channelId The ID of the thread channel.
-- @param userId The ID of the user to remove from the thread.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage exports.discord_rest:removeThreadMember("[channel ID]", "[user ID]", "[bot token]")
-- @see https://discord.com/developers/docs/resources/channel#remove-thread-member
exports("removeThreadMember", function(channelId, userId, botToken)
	return discordRest:removeThreadMember(channelId, userId, botToken)
end)

--- Creates a new thread from an existing message.
-- @function startThreadWithMessage
-- @param channelId The ID of the channel containing the message.
-- @param messageId The ID of the message to start the thread from.
-- @param params Parameters for the thread.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise that resolves with the new thread channel.
-- @usage exports.discord_rest:startThreadWithMessage("[channel ID]", "[message ID]", {name = "New thread"}, "[bot token]")
-- @see https://discord.com/developers/docs/resources/channel#start-thread-with-message
exports("startThreadWithMessage", function(channelId, messageId, params, botToken)
	return discordRest:startThreadWithMessage(channelId, messageId, params, botToken)
end)

--- Creates a new thread that is not connected to an existing message.
-- @function startThreadWithoutMessage
-- @param channelId The ID of the channel to create the thread in.
-- @param params Parameters for the thread.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise that resolves with the new thread channel.
-- @usage exports.discord_rest:startThreadWithoutMessage("[channel ID]", {name = "New thread", auto_archive_duration = 60, type = 11}, "[bot token]"):next(function(channel) ... end)
-- @see https://discord.com/developers/docs/resources/channel#start-thread-without-message
exports("startThreadWithoutMessage", function(channelId, params, botToken)
	return discordRest:startThreadWithoutMessage(channelId, params, botToken)
end)

--- Post a typing indicator for the specified channel.
-- @function triggerTypingIndicator
-- @param channelId The ID of the channel to show the typing indicator in.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage exports.discord_rest:triggerTypingIndicator("[channel ID]", "[bot token]")
-- @see https://discord.com/developers/docs/resources/channel#trigger-typing-indicator
exports("triggerTypingIndicator", function(channelId, botToken)
	return discordRest:triggerTypingIndicator(channelId, botToken)
end)

--- Unpin a message in a channel.
-- @function unpinMessage
-- @param channelId The ID of the channel containing the message.
-- @param messageId The ID of the message to unpin.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage exports.discord_rest:unpinMessage("[channel ID]", "[message ID]", "[bot token]")
-- @see https://discord.com/developers/docs/resources/channel#unpin-message
exports("unpinMessage", function(channelId, messageId, botToken)
	return discordRest:unpinMessage(channelId, messageId, botToken)
end)

--- Guild
-- @section guild

--- Get info for a member of a guild.
-- @function getGuildMember
-- @param guildId The ID of the guild.
-- @param userId The ID of the user.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise that resolves with the info of the member if they are in the guild.
-- @usage exports.discord_rest:getGuildMember("[guild ID]", "[user ID]", "[bot token]"):next(function(member) ... end)
-- @see https://discord.com/developers/docs/resources/guild#get-guild-member
exports("getGuildMember", function(guildId, userId, botToken)
	return discordRest:getGuildMember(guildId, userId, botToken)
end)

--- User
-- @section user

--- Create a new DM channel with a user.
-- @function createDm
-- @param recipientId The ID of the user to start the DM with.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise that is resolved with the DM channel information.
-- @usage exports.discord_rest:createDm("[recipient ID]", "[bot token]"):next(function(channel) ... end)
-- @see https://discord.com/developers/docs/resources/user#create-dm
exports("createDm", function(recipientId, botToken)
	return discordRest:createDm(recipientId, botToken)
end)

--- Get user information.
-- @function getUser
-- @param userId The ID of the user.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage exports.discord_rest:getUser("[user ID]", "[bot token]"):next(function(user) ... end)
-- @see https://discord.com/developers/docs/resources/user#get-user
exports("getUser", function(userId, botToken)
	return discordRest:getUser(userId, botToken)
end)

--- Webhook
-- @section Webhook

--- Execute a webhook.
-- @function executeWebhook
-- @param url The webhook URL.
-- @param data The data to send.
-- @return A new promise.
-- @usage exports.discord_rest:executeWebhook("https://discord.com/api/webhooks/[webhook ID]/[webhook token]", {content = "Hello, world!"})
-- @see https://discord.com/developers/docs/resources/webhook#execute-webhook
exports("executeWebhook", function(url, data)
	return discordRest:executeWebhook(url, data)
end)
