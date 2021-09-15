-- Watch for command !players in a channel, and reply with the number of players in the server

local botToken = "" -- Discord bot token for API access
local channelIds = {} -- Channel to watch for command in

-- Respond to a message
local function respondToMessage(channel, message, content)
	return exports.discord_rest:createMessage(channel.id, {
		message_reference = {
			message_id = message.id
		},
		content = content
	}, botToken)
end

-- Read messages in a watched channel, print them to console, and respond as necessary
local function respondToMessagesInChannel(channel)
	return exports.discord_rest:getChannelMessages(channel.id, {after = channel.last_message_id}, botToken):next(function(messages)
		if #messages == 0 then
			return
		end

		table.sort(messages, function(a, b)
			return a.id < b.id
		end)

		local promises = {}

		for _, message in ipairs(messages) do
			print(("#%s: %s: %s"):format(channel.name, message.author.username, message.content))

			if message.content == "!players" then
				table.insert(promises, respondToMessage(channel, message, "Players on server: " .. #GetPlayers()))
			end
		end

		channel.last_message_id = messages[#messages].id

		return promise.all(promises)
	end)
end

-- Handle messages in all channels being watched
local function respondToMessages(channels)
	return promise.map(channels, function(channel)
		return respondToMessagesInChannel(channel)
	end)
end

-- Get info for all channels being watched
local function getChannels(channelIds)
	return promise.map(channelIds, function(channelId)
		return exports.discord_rest:getChannel(channelId, botToken)
	end)
end

getChannels(channelIds):next(function(channels)
	Citizen.CreateThread(function()
		while true do
			Citizen.Await(respondToMessages(channels))
		end
	end)
end, function(err)
	print("An error occured: " .. err)
end)
