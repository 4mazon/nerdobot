#!/usr/bin/env coffee

Bot = require('../lib/bot').Bot
config = require process.argv[2] or process.env.NERDO_CONFIG or '../config'

bot = new Bot(config)

bot.events.on 'connected', () -> console.log 'Connected'
bot.events.on 'end', () -> console.log 'Disconnected'

bot.connect()
