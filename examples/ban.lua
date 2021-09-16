-- Check if a player is banned from a guild before letting them in the server

local botToken = "" -- Bot token for API access
local guildId = "" -- ID of the guild to check bans for

AddEventHandler("playerConnecting", function(name, setKickReason, deferrals)
        local source = source

        deferrals.defer()

        Citizen.Wait(0)

        deferrals.update("Checking Discord bans...")

        Citizen.Wait(0)

        exports.discord_rest:getGuildBanForPlayer(guildId, source, botToken):next(function(ban)
                deferrals.done(("You (%s#%s) are banned: %s"):format(ban.user.username, ban.user.discriminator, ban.reason))
        end, function(err)
                if err == 404 then -- No ban exists for this player
                        deferrals.done()
                else
                        deferrals.done("Failed to check guild ban status: " .. err)
                end
        end)
end)
