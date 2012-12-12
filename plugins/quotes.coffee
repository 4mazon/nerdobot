util = require '../lib/util'
sqlite3 = require('sqlite3')

isInt = (n) ->
  !isNaN(parseInt(n)) and isFinite(n)

module.exports = (bot, file) ->
  db = new sqlite3.cached.Database file, (err) ->
    if err
      console.log "Error opening deatabase #{file}: #{err}"
      console.log "Disabling quote system!"
      return

    # Initialize DB tables if not present
    db.run "CREATE TABLE IF NOT EXISTS quotes (
      channel VARCHAR NOT NULL,
      nick VARCHAR NOT NULL,
      quote VARCHAR NOT NULL,
      by VARCHAR NOT NULL,
      timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL);"

    # COMMAND !addquote <quote>
    #  only works in channels
    bot.commands.on 'addquote', (from, message, channel) ->
      if not channel?
        bot.notice from.nick, "That will only work in channels, idiot..."
        return

      if not message?
        bot.notice from.nick, "Tell me the quote, moron!"
        return

      [nick, quote] = util.split message, ' '

      if not nick? or nick == ''
        bot.notice from.nick, "Tell me the quote, moron!"
        return

      if not quote? or quote == ''
        bot.notice from.nick, "So... what did #{nick} say?"
        return

      db.run "INSERT INTO quotes (channel, nick, quote, by)
         VALUES ($channel, $nick, $quote, $by);",
        $channel: channel
        $nick: nick
        $quote: quote
        $by: from.nick
      , (err) ->
        if err
          boy.say channel, "\x02Error inserting quote:\x0f #{err}"
        else
          bot.say channel, "Quote inserted! \x02(#{this.lastID})\x0f"

    # SELECT string of fields for !quote
    FIELDS = [
      'rowid',
      'channel',
      'nick',
      'quote',
      'by',
      "strftime('%Y-%m-%d %H:%M', timestamp, 'localtime') as timestamp"]
      .join ', '

    # COMMAND !quote <channel> <number> (both optional)
    bot.commands.on 'quote', (from, message, channel) ->
      # Parse arguments
      if message?
        args = message.split ' '
        switch args.length
          when 2
            chn = args[0]
            num = parseInt args[1]
          when 1
            arg = args[0]
            if isInt arg
              num = parseInt arg
            else
              chn = arg

      if channel
        chn ?= channel
        replyTo = channel
      else
        replyTo = from.nick

      # SELECT's extra clause
      clause = ''
      if chn? or num?
        clause  = 'WHERE '
        clause += 'channel = $channel' if chn?
        if num?
          clause += ' AND ' if chn
          clause += 'rowid = $id'

      clause += ' ORDER BY RANDOM() LIMIT 1' if not num?

      db.get "SELECT #{FIELDS} FROM quotes #{clause};",
        $channel: chn
        $id: num,
        (err, row) ->
          if err
            bot.say replyTo, "Error selecting quote: #{err}"
            return

          if not row?
            bot.say replyTo, 'Quote not found'
            return

          bot.say replyTo,
            "#{bot.UNDERLINE}#{row.timestamp}#{bot.RESET} - #{row.by} " +
            "#{bot.BOLD}(#{row.rowid})#{bot.RESET} | #{bot.color 'red'}#{row.nick}" +
            (if not (chn? or chn == replyTo) then "@#{row.channel}" else '') +
            "#{bot.RESET}: #{row.quote}"

  name: 'Quotes'
  description: 'Add and print/browse quotes'
  version: '0.1'
  authors: ['Álvaro Cuesta']
