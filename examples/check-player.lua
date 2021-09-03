-- Check if a player is in a Discord guild before letting them in the server

local botToken = "" -- Discord bot token for API access
local guildId = "" -- Discord guild that players must be in

local function getDiscordId(player)
        for _, identifier in ipairs(GetPlayerIdentifiers(player)) do
                if identifier:sub(1, 8) == "discord:" then
                        return identifier:sub(9)
                end
        end
end

local function getGuildStatus(player)
        local p = promise.new()

        local discordId = getDiscordId(player)

        if discordId then
                exports.discord_rest:getGuildMember(guildId, discordId, botToken):next(function(member)
                        p:resolve(true)
                end, function(err)
                        if err == 404 then
                                p:resolve(false)
                        else
                                p:reject("Discord REST API error: " .. err)
                        end
                end)
        else
                p:reject("No Discord ID, ensure Discord is open or you have linked your Discord account")
        end

        return p
end

AddEventHandler("playerConnecting", function(name, setKickReason, deferrals)
        local source = source

        deferrals.defer()

        Citizen.Wait(0)

        deferrals.update("Checking Discord status...")

        Citizen.Wait(0)

        getGuildStatus(source):next(function(isMember)
                if isMember then
                        deferrals.done()
                else
                        deferrals.done("You must join the Discord guild to play on this server")
                end
        end, function(err)
                deferrals.done("Failed to check guild status: " .. err)
        end)
end)
