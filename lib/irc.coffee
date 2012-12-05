net = require('net')
EventEmitter = require('events').EventEmitter

module.exports.parse = parse = (message) ->
  if message.charAt(0) == ':'
    end = message.indexOf ' '
    prefix = message.slice 1, end
    message = message.slice end + 1

  end = message.indexOf ' '
  command = message.slice 0, end
  message = message.slice end + 1

  end = message.indexOf ':'
  if end > 0
    params = message.slice(0, end - 1).split(' ')
  else
    params = []
  message = message.slice end + 1

  prefix: prefix
  command: command
  params: params
  trailing: message

module.exports.parse_prefix = parse_prefix = (prefix) ->
  match = prefix.match /^(.*)!(\S+)@(\S+)/
  if match
    nick: match[1]
    user: match[2]
    host: match[3]
  else
    null

module.exports.Client = class Client
  constructor: (@config) ->
    @events = new EventEmitter()

  connect: () ->
    @socket = net.connect @config.socket, () =>
      @socket.on 'data', (data) =>
        for message in data.split '\r\n'
          if message != ''
            @events.emit 'raw', message
            @data parse(message)
      @socket.on 'end', () =>
        @events.emit 'end'

      @raw "NICK #{@config.user.nick}"
      @raw "USER #{@config.user.login} 0 * :#{@config.user.realname}"
      @events.emit 'connected'

    @socket.setEncoding @config.connection.encoding

  data: (message) ->
    switch message.command
      when 'PING'
        @raw "PONG :#{message.trailing}"
      when '001'
        @events.emit 'welcome'
      when 'PRIVMSG'
        if message.params[0] == @config.user.nick
          @events.emit 'private', message.prefix, message.trailing
        else
          @events.emit 'channel', message.prefix, message.trailing, message.params[0]

    @events.emit 'parsed', message

  raw: (message) ->
    @socket.write message + '\r\n'
    console.log " -> #{message}"
