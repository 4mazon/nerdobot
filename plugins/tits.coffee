request = require ('request')

module.exports = (bot) ->
  bot.commands.on 'tits', (from, message, channel) ->
  	if channel?
    	msg = request {url: "http://www.reddit.com/r/realgirls/.json?"
    	, json: true} ,(err, res, data) ->
    		if data?
    			num = Math.floor Math.random() * data.data.children.length
    			bot.say channel, data.data.children[num].data.url


  name: 'Tits'
  description: 'Tits or get the fuck out '
  version: '0.1'
  authors: ['blzkz']
  