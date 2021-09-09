-- Check if a player is in a Discord guild before letting them in the server

local botToken = "" -- Discord bot token for API access
local guildId = "" -- Discord guild that players must be in

AddEventHandler("playerConnecting", function(name, setKickReason, deferrals)
        local source = source

        deferrals.defer()

        Citizen.Wait(0)

        deferrals.update("Checking Discord status...")

        Citizen.Wait(0)

        exports.discord_rest:getGuildMemberForPlayer(guildId, source, botToken):next(function(member)
                deferrals.update("Welcome to the server, " .. member.user.username .. "#" .. member.user.discriminator .. "!")
                Citizen.Wait(2000)
                deferrals.done()
        end, function(err)
                if err == 404 then
                        deferrals.done("You must join the Discord guild to play on this server")
                else
                        deferrals.done("Failed to check guild status: " .. err)
                end
        end)
end)
