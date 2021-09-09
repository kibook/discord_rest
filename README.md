# discord_rest

Discord REST API utility for FiveM and RedM.

# Features

- Easy Discord interaction from any resource.
- Promise-based asynchronous export functions.
- Actions are handled in a queue to prevent rate limiting.

# Examples

## Execute a webhook

```lua
-- Print "Hello, world!" in a Discord channel via a webhook
exports.discord_rest:executeWebhook("https://discord.com/api/webhook/.../...", {content = "Hello, world!"})
```

## Get messages from a channel

```lua
-- Get the last 10 messages from a channel and print them
exports.discord_rest:getChannelMessages(channelId, {limit = 10}, botToken):next(function(messages)
	for _, message in ipairs(messages) do
		print(message.author.username .. ": " .. message.content)
	end
end)
```

## Get user info

```lua
-- Get a player's name on Discord
local playerName = GetPlayerName(player)
exports.discord_rest:getUserForPlayer(player):next(function(user)
	print(playerName .. " is called " .. user.username .. " on Discord")
end, function(err)
	print(playerName .. " does not have Discord connected")
end)
```
