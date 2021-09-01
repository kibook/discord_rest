project = 'discord_rest'
description = 'Discord REST API utility for FiveM and RedM'
examples = {'examples'}
style = true

custom_see_handler('^(https?://.*)$', function(url)
	return url, url
end)
