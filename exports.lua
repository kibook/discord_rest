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
-- @usage exports.discord_rest:addThreadMember("[channel ID]", "[user ID]")
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

--- Returns archived threads in the channel that are private, and the user has joined.
-- @function listJoinedPrivateArchivedThreads
-- @param channelId The ID of the channel to get a list of private archived threads from.
-- @param options Options for the query.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with a table of information on private archived threads.
-- @usage exports.discord_rest:listJoinedPrivateArchivedThreads("[channel ID]", {limit = 5}, "[bot token]"):next(function(data) ... end)
-- @see https://discord.com/developers/docs/resources/channel#list-joined-private-archived-threads
exports("listJoinedPrivateArchivedThreads", function(channelId, options, botToken)
	return discordRest:listJoinedPrivateArchivedThreads(channelId, options, botToken)
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
-- @function listPublicArchivedThreads
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
-- @usage exports.discord_rest:startThreadWithoutMessage("[channel ID]", {name = "New thread"}, "[bot token]"):next(function(channel) ... end)
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

--- Emoji
-- @section emoji

--- Create a new emoji for the guild.
-- @function createGuildEmoji
-- @param guildId The ID of the guild to create the emoji for.
-- @param params Parameters for the new emoji.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise whih is resolved with the new emoji.
-- @usage exports.discord_rest:createGuildEmoji("[guild ID]", {name = "emojiname", image = "data:image/jpeg;base64,..."}, "[bot token]")
-- @see https://discord.com/developers/docs/resources/emoji#create-guild-emoji
exports("createGuildEmoji", function(guildId, params, botToken)
	return discordRest:createGuildEmoji(guildId, params, botToken)
end)

--- Delete the given emoji.
-- @function deleteGuildEmoji
-- @param guildId The ID of the guild to delete the emoji from.
-- @param emojiId The ID of the emoji to delete.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage exports.discord_rest:deleteGuildEmoji("[guild ID]", "[emoji ID]", "[bot token]")
-- @see https://discord.com/developers/docs/resources/emoji#delete-guild-emoji
exports("deleteGuildEmoji", function(guildId, emojiId, botToken)
	return discordRest:deleteGuildEmoji(guildId, emojiId, botToken)
end)

--- Get information on a guild emoji.
-- @function getGuildEmoji
-- @param guildId The ID of the guild where the emoji is from.
-- @param emojiId The ID of the emoji to get information about.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with the information about the emoji.
-- @usage exports.discord_rest:getGuildEmoji("[guild ID]", "[emoji ID]"):next(function(emoji) ... end)
-- @see https://discord.com/developers/docs/resources/emoji#get-guild-emoji
exports("getGuildEmoji", function(guildId, emojiId, botToken)
	return discordRest:getGuildEmoji(guildId, emojiId, botToken)
end)

--- Return a list of emoji for the given guild.
-- @function listGuildEmojis
-- @param guildId The ID of the guild.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with the list of emoji.
-- @usage exports.discord_rest:listGuildEmojis("[guild ID]", "[bot token]"):next(function(emojis) ... end)
-- @see https://discord.com/developers/docs/resources/emoji#list-guild-emojis
exports("listGuildEmojis", function(guildId, botToken)
	return discordRest:listGuildEmojis(guildId, botToken)
end)

--- Modify the given emoji.
-- @function modifyGuildEmoji
-- @param guildId The ID of the guild where the emoji is from.
-- @param emojiId The ID of the emoji to modify.
-- @param params Modified parameters for the emoji.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with the updated emoji.
-- @usage exports.discord_rest:modifyGuildEmoji("[guild ID]", "[emoji ID]", {name = "newemojiname"}, "[bot token]")
-- @see https://discord.com/developers/docs/resources/emoji#modify-guild-emoji
exports("modifyGuildEmoji", function(guildId, emojiId, params, botToken)
	return discordRest:modifyGuildEmoji(guildId, emojiId, params, botToken)
end)

--- Guild
-- @section guild

--- Adds a user to the guild.
-- @function addGuildMember
-- @param guildId The ID of the guild to add the user to.
-- @param userId The ID of the user to add to the guild.
-- @param Parameters for adding the user.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage exports.discord_rest:addGuildMember("[guild ID]", "[user ID]", {access_token = "..."}, "[bot token]")
-- @see https://discord.com/developers/docs/resources/guild#add-guild-member
exports("addGuildMember", function(guildId, userId, params, botToken)
	return discordRest:addGuildMember(guildId, userId, params, botToken)
end)

--- Adds a role to a guild member.
-- @function addGuildMemberRole
-- @param guildId The ID of the guild.
-- @param userId The ID of the user to add the role to.
-- @param roleId The ID of the role to add to the member.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage exports.discord_rest:addGuildMemberRole("[guild ID]", "[user ID]", "[role ID]", "[bot token]")
-- @see https://discord.com/developers/docs/resources/guild#add-guild-member-role
exports("addGuildMemberRole", function(guildId, userId, roleId, botToken)
	return discordRest:addGuildMemberRole(guildId, userId, roleId, botToken)
end)

--- Create a new guild.
-- @function createGuild
-- @param params Parameters for the new guild.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with the new guild.
-- @usage exports.discord_rest:createGuild({name = "My Guild"})
-- @see https://discord.com/developers/docs/resources/guild#create-guild
exports("createGuild", function(params, botToken)
	return discordRest:createGuild(params, botToken)
end)

--- Create a guild ban, and optionally delete previous messages sent by the banned user.
-- @function createGuildBan
-- @param guildId The ID of the guild to create the ban for.
-- @param userId The ID of the user to ban.
-- @param params Parameters for the ban.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage exports.discord_rest:createGuildBan("[guild ID]", "[user ID]", {reason = "Not following the rules"}, "[bot token]")
-- @see https://discord.com/developers/docs/resources/guild#create-guild-ban
exports("createGuildBan", function(guildId, userId, params, botToken)
	return discordRest:createGuildBan(guildId, userId, params, botToken)
end)

--- Create a new guild channel.
-- @function createGuildChannel
-- @param guildId The ID of the guild to create the channel in.
-- @param params Parameters for the new channel.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with the new channel.
-- @usage exports.discord_rest:createGuildChannel(["guild ID"], {name = "new-channel"}, "[bot token]"):next(function(channel) ... end)
-- @see https://discord.com/developers/docs/resources/guild#create-guild-channel
exports("createGuildChannel", function(guildId, params, botToken)
	return discordRest:createGuildChannel(guildId, params, botToken)
end)

--- Delete a guild permanently.
-- @function deleteGuild
-- @param guildId The ID of the guild to delete.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage exports.discord_rest:deleteGuild("[guild ID]", "[bot token]")
-- @see https://discord.com/developers/docs/resources/guild#delete-guild
exports("deleteGuild", function(guildId, botToken)
	return discordRest:deleteGuild(guildId, botToken)
end)

--- Get info for a given guild.
-- @function getGuild
-- @param guildId The ID of the guild.
-- @param withCounts Whether to include approximate member and presence counts in the returned info.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with the guild info.
-- @usage exports.discord_rest:getGuild("[guild ID]"):next(function(guild) ... end)
-- @see https://discord.com/developers/docs/resources/guild#get-guild
exports("getGuild", function(guildId, withCounts, botToken)
	return discordRest:getGuild(guildId, withCounts, botTokens)
end)

--- Return info on a ban for a specific user in a guild.
-- @function getGuildBan
-- @param guildId The ID of the guild.
-- @param userId The ID of the banned user.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with the ban info.
-- @usage exports.discord_rest:getGuildBan("[guild ID]", "[user ID]", "[bot token]"):next(function(ban) ... end)
-- @see https://discord.com/developers/docs/resources/guild#get-guild-ban
exports("getGuildBan", function(guildId, userId, botToken)
	return discordRest:getGuildBan(guildId, userId, botToken)
end)

--- Get a list of bans for a guild.
-- @function getGuildBans
-- @param guildId The ID of the guild.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with a list of bans.
-- @usage exports.discord_get:getGuildBans("[guild ID]", "[bot token]"):next(function(bans) ... end)
-- @see https://discord.com/developers/docs/resources/guild#get-guild-bans
exports("getGuildBans", function(guildId, botToken)
	return discordRest:getGuildBans(guildId, botToken)
end)

--- Get a list of guild channels.
-- @function getGuildChannels
-- @param guildId The ID of the guild to get a list of channels for.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with the list of channels.
-- @usage exports.discord_rest:getGuildChannels("[guild ID]", "[bot token]"):next(function(channels) ... end)
-- @see https://discord.com/developers/docs/resources/guild#get-guild-channels
exports("getGuildChannels", function(guildId, botToken)
	return discordRest:getGuildChannels(guildId, botToken)
end)

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

--- Get preview information for a guild.
-- @function getGuildPreview
-- @param guildId The ID of the guild.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with the preview info for the guild.
-- @usage exports.discord_rest:getGuildPreview("[guild ID]", "[bot token]"):next(function(preview) ... end)
-- @see https://discord.com/developers/docs/resources/guild#get-guild-preview
exports("getGuildPreview", function(guildId, botToken)
	return discordRest:getGuildPreview(guildId, botToken)
end)

--- Returns all active threads in the guild, including public and private threads.
-- @function listActiveGuildThreads
-- @param guildId The ID of the guild.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with the lists of threads and thread members.
-- @usage exports.discord_rest:listActiveGuildThreads("[guild ID]", "[bot token]"):next(function(data) ... end)
-- @see https://discord.com/developers/docs/resources/guild#list-active-threads
exports("listActiveGuildThreads", function(guildId, botToken)
	return discordRest:listActiveGuildThreads(guildId, botToken)
end)

--- Get a list of members in a guild.
-- @function listGuildMembers
-- @param guildId The ID of the guild to get a list of members for.
-- @param options Options for the query.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with a list of guild members.
-- @usage exports.discord_rest:listGuildMembers("[guild ID]", {limit = 5}, "[bot token]"):next(function(members) ... end)
-- @see https://discord.com/developers/docs/resources/guild#list-guild-members
exports("listGuildMembers", function(guildId, options, botToken)
	return discordRest:listGuildMembers(guildId, options, botToken)
end)

--- Modify a guild's settings.
-- @function modifyGuild
-- @param guildId The ID of the guild to modify.
-- @param settings The modified settings for the guild.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with the updated guild.
-- @usage exports.discord_rest:modifyGuild("[guild ID]", {name = "New guild name"}, "[bot token]")
-- @see https://discord.com/developers/docs/resources/guild#modify-guild
exports("modifyGuild", function(guildId, settings, botToken)
	return discordRest:modifyGuild(guildId, settings, botToken)
end)

--- Modify the positions of a set of channels.
-- @function modifyGuildChannelPositions
-- @param guildId The ID of the guild containing the channels.
-- @param channelPositions A set of channel position parameters.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage exports.discord_rest:modifyGuildChannelPositions("[guild ID]", {{id = "[channel 1 ID]", position = 2}, {"[channel 2 ID]", position = 1}}, "[bot token]")
-- @see https://discord.com/developers/docs/resources/guild#modify-guild-channel-positions
exports("modifyGuildChannelPositions", function(guildId, channelPositions, botToken)
	return discordRest:modifyGuildChannelPositions(guildId, channelPositions, botToken)
end)

--- Modifies the nickname of the current user in a guild.
-- @function modifyCurrentUserNick
-- @param guildId The ID of the guild.
-- @param nick The value to set the user's nickname to.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage exports.discord_rest:modifyCurrentUserNick("[guild ID]", "New nickname")
-- @see https://discord.com/developers/docs/resources/guild#modify-current-user-nick
exports("modifyCurrentUserNick", function(guildId, nick, botToken)
	return discordRest:modifyCurrentUserNick(guildId, nick, botToken)
end)

--- Modify attributes of a guild member.
-- @function modifyGuildMember
-- @param guildId The ID of the guild.
-- @param userId The ID of the member to modify.
-- @param params The parameters to modify.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with the modified guild member.
-- @usage exports.discord_rest:modifyGuildMember("[guild ID]", "[user ID]", {nick = "New nickname"}, "[bot token]")
-- @see https://discord.com/developers/docs/resources/guild#modify-guild-member
exports("modifyGuildMember", function(guildId, userId, params, botToken)
	return discordRest:modifyGuildMember(guildId, userId, params, botToken)
end)

--- Remove the ban for a user.
-- @function removeGuildBan
-- @param guildId The ID of the guild to remove the ban for the user from.
-- @param userId The ID of the user to unban.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage exports.discord_rest:removeGuildBan("[guild ID]", "[user ID]", "[bot token]")
-- @see https://discord.com/developers/docs/resources/guild#remove-guild-ban
exports("removeGuildBan", function(guildId, userId, botToken)
	return discordRest:removeGuildBan(guildId, userId, botToken)
end)

--- Remove a member from a guild.
-- @function removeGuildMember
-- @param guildId The ID of the guild to remove the member from.
-- @param userId The ID of the member to remove from the guild.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage exports.discord_rest:removeGuildMember("[guild ID]", "[user ID]", "[bot token]")
-- @see https://discord.com/developers/docs/resources/guild#remove-guild-member
exports("removeGuildMember", function(guildId, userId, botToken)
	return discordRest:removeGuildMember(guildId, userId, botToken)
end)

--- Removes a role from a guild member.
-- @function removeGuildMemberRole
-- @param guildId The ID of the guild.
-- @param userId The ID of the user to remove the role from.
-- @param roleId The ID of the role to remove from the member.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage exports.discord_rest:removeGuildMemberRole("[guild ID]", "[user ID]", "[role ID]", "[bot token]")
-- @see https://discord.com/developers/docs/resources/guild#remove-guild-member-role
exports("removeGuildMemberRole", function(guildId, userId, roleId, botToken)
	return discordRest:removeGuildMemberRole(guildId, userId, roleId, botToken)
end)

--- Get a list of guild members whose username or nickname starts with a provided string.
-- @function searchGuildMembers
-- @param guildId The ID of the guild to search in.
-- @param options Options for the query.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with a list of guild members that matched the query.
-- @usage exports.discord_rest:searchGuildMembers("[guild ID]", {query = "Po"}, "[bot token]"):next(function(members) ... end)
-- @see https://discord.com/developers/docs/resources/guild#search-guild-members
exports("searchGuildMembers", function(guildId, options, botToken)
	return discordRest:searchGuildMembers(guildId, options, botToken)
end)

--- Invite
-- @section invite

--- Delete an invite.
-- @function deleteInvite
-- @param inviteCode The code of the invite that will be deleted.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise.
-- @usage exports.discord_rest:deleteInvite("[invite code]", "[bot token]")
-- @see https://discord.com/developers/docs/resources/invite#delete-invite
exports("deleteInvite", function(inviteCode, botToken)
	return discordRest:deleteInvite(inviteCode, botToken)
end)

--- Return info for an invite.
-- @function getInvite
-- @param inviteCode The code of the invite.
-- @param options Options for the query.
-- @param botToken Optional bot token to use for authorization.
-- @return A new promise which is resolved with the invite info.
-- @usage exports.discord_rest:getInvite("[invite code]", {with_expiration = true}, "[bot token]"):next(function(invite) ... end)
-- @see https://discord.com/developers/docs/resources/invite#get-invite
exports("getInvite", function(inviteCode, options, botToken)
	return discordRest:getInvite(inviteCode, options, botToken)
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
-- @param webhookId The ID of the webhook.
-- @param webhookToken The token for the webhook.
-- @param data The data to send.
-- @return A new promise.
-- @usage exports.discord_rest:executeWebhook("[webhook ID]", "[webhook token]", {content = "Hello, world!"})
-- @see https://discord.com/developers/docs/resources/webhook#execute-webhook
exports("executeWebhook", function(webhookId, webhookToken, data)
	return discordRest:executeWebhook(webhookId, webhookToken, data)
end)

--- Execute a webhook, using the full URL.
-- @function executeWebhookUrl
-- @param url The webhook URL.
-- @param data The data to send.
-- @return A new promise.
-- @usage exports.discord_rest:executeWebhookUrl("https://discord.com/api/webhooks/[webhook ID]/[webhook token]", {content = "Hello, world!"})
-- @see https://discord.com/developers/docs/resources/webhook#execute-webhook
exports("executeWebhookUrl", function(url, data)
	return discordRest:executeWebhookUrl(url, data)
end)
