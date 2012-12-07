util = require '../lib/util'
nutil = require 'util'

module.exports = (bot) ->
  bot.events.on 'parsed', (parsed) ->
    {prefix, command, params, trailing} = parsed
    text = " <- [#{prefix}, #{command}, #{if params? then '['+params.join(', ')+']' else '[]'}, #{trailing}]"
    util.log text

  bot.events.on 'raw', (message) ->
    util.log " -> #{message}"

  name: 'Debug'
  description: "Show in/out communication in nerdobot's console"
  version: '0.1'
  authors: ['Álvaro Cuesta']
