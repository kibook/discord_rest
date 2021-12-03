local botToken = ""
local guildId = ""

local function getChannelByName(guildId,channelName)
        local p = promise.new()

        exports.discord_rest:getGuildChannels(guildId, botToken):next(function(channels)
                for _, channel in ipairs(channels) do
                        if channel.name == channelName then
                                p:resolve(channel.id)
                                return
                        end
                end

                p:reject("No channel named " .. channelName)
        end)

        return p
end

local function sendMessage(channelName, message)
        return getChannelByName(guildId, channelName):next(function(channelId)
                return exports.discord_rest:createMessage(channelId, {content = message}, botToken)
        end)
end

sendMessage("general", "hello, world!"):next(nil, function(err)
        print("An error occurred sending the message: " .. err)
end)
