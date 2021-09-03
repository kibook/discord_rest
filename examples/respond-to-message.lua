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
                local promises = {}

                if #messages == 0 then
                        return
                end

                for _, message in ipairs(messages) do
                        print(("#%s: %s: %s"):format(channel.name, message.author.username, message.content))

                        if message.content == "!players" then
                                table.insert(promise, respondToMessage(channel, message, "Players on server: " .. #GetPlayers()))
                        end
                end

                channel.last_message_id = messages[#messages].id

                return promise.all(promises)
        end)
end

-- Handle messages in all channels being watched
local function respondToMessages(channels)
        local promises = {}

        for _, channel in ipairs(channels) do
                table.insert(promises, respondToMessagesInChannel(channel))
        end

        return promise.all(promises)
end

-- Get info for all channels being watched
local function getChannels(channelIds)
        local promises = {}

        for _, channelId in ipairs(channelIds) do
                table.insert(promises, exports.discord_rest:getChannel(channelId, botToken))
        end

        return promise.all(promises)
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
