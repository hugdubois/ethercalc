@include = ->
  enable 'serve jquery'
  app.use express.static __dirname

  def {db}

  get '/': ->
    response.contentType 'text/html'
    response.sendfile 'index.html'

  get '/edit': ->
    response.contentType 'text/html'
    response.sendfile 'index.html'

  get '/start': -> render 'start'
  get '/new': ->
    response.redirect require("uuid-pure").newId(10)

  view room: ->
    coffeescript ->
      window.location = '/#' + window.location.pathname.replace(/.*\//, '')

  view start: ->
    div id:"topnav_wrap", -> div id:"navigation"
    div id:"intro-left", ->
      h1 "MeetingCalc"
      h2 "MeetingCalc is a web spreadsheet."
      p "Your data is saved on the web, and people can edit the same document at the same time. Everybody's changes are instantly reflected on all screens."
      p "Work together on inventories, survey forms, list managements, brainstorming sessions and more!"
      div id:"intro-links", ->
        a id:"newpadbutton", href:"/new", ->
            span "Create new pad"
            small "No sign-up, start editing instantly"

  view layout: ->
    html ->
      head ->
        title "MeetingCalc"
        link href:"/start.css", rel:"stylesheet", type:"text/css"
      body id:"framedpagebody", class:"home", ->
        div id:"top", -> @body
  
  at broadcast: ->
    #io.sockets.in(@room).emit 'broadcast', @
    emit = (msg) -> io.sockets.emit 'broadcast', msg
    switch @type
      when 'chat'
        db.rpush "chat-#{@room}", @msg, => emit @
        return
      when 'ask.ecells'
        db.hgetall "ecell-#{@room}", (err, values) => emit
          type: 'ecells'
          ecells: values
          room: @room
        return
      when 'my.ecell'
        db.hset "ecell-#{@room}", @user, @ecell
        return
      when 'execute'
        db.rpush "log-#{@room}", @cmdstr, => emit @
        return
      when 'ask.snapshot'
        db.lrange "log-#{@room}", 0, -1, (err, log) =>
          db.lrange "chat-#{@room}", 0, -1, (err, chat) => emit
            type: 'log'
            to: @user
            room: @room
            log: log
            chat: chat
        return
    emit @
  
  include 'player'

  get '/:room': ->
    @layout = no
    render 'room', @

###
CC0 1.0 Universal

To the extent possible under law, 唐鳳 has waived all copyright and
related or neighboring rights to MeetingCalc.

This work is published from Taiwan.

<http://creativecommons.org/publicdomain/zero/1.0>
###