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

    # COMMAND !addquote
    bot.commands.on 'addquote', (from, message, to) ->
      if not message?
        bot.notice "Tell me the quote, moron!", from.nick
        return

      if not to?
        bot.notice "That will only work in channels, idiot...", from.nick
        return

      [nick, quote] = util.split message, ' '

      if not nick? or nick == ''
        bot.notice "Tell me the quote, moron!", from.nick
        return

      if not quote? or quote == ''
        bot.notice "So... what did #{nick} say?", from.nick
        return

      db.run "INSERT INTO quotes (channel, nick, quote, by)
         VALUES ($channel, $nick, $quote, $by);",
        $channel: to
        $nick: nick
        $quote: quote
        $by: from.nick
      , (err) ->
        if err
          boy.say "\x02Error inserting quote:\x0f #{err}", to
          return
        bot.say "Quote inserted! \x02(#{this.lastID})\x0f", to

    # SELECT
    fields = [
      'rowid',
      'channel',
      'nick',
      'quote',
      'by',
      "strftime('%Y-%m-%d %H:%M', timestamp, 'localtime') as timestamp"]

    # COMMAND !quote
    bot.commands.on 'quote', (from, message, to) ->
      # Parse arguments: [channel] [number]
      if message?
        args = message.split ' '
        if args.length == 2
          channel = args[0]
          number = parseInt args[1]
        else if args.length == 1
          arg = args[0]
          if isInt arg
            number = parseInt arg
          else
            channel = arg

      if to
        replyTo = to
        channel = to if not channel?
      else
        replyTo = from.nick

      bind = {}
      whereClause = ''
      if channel? or number?
        whereClause = 'WHERE '
        if channel
          whereClause += 'channel = $channel'
          bind.$channel = channel

        if number
          whereClause += ' AND ' if channel
          whereClause += "rowid = $id"
          bind.$id = number

      fieldString = fields.join ', '

      db.get "SELECT #{fieldString} FROM quotes
        #{whereClause} ORDER BY RANDOM() LIMIT 1;",
        bind,
        (err, row) ->
          if err
            bot.say "Error selecting quote: #{err}", replyTo
            return

          if not row?
            bot.say  'Quote not found', replyTo
            return

          bot.say "#{bot.UNDERLINE}#{row.timestamp}#{bot.RESET} - #{row.by} " +
            "#{bot.BOLD}(#{row.rowid})#{bot.RESET} | #{bot.color 'red'}#{row.nick}" +
            (if channel != replyTo then "@#{row.channel}" else '') +
            "#{bot.RESET}: #{row.quote}"
          , replyTo

  name: 'Quotes'
  description: 'Add and print/browse quotes'
  version: '0.1'
  authors: ['Álvaro Cuesta']
