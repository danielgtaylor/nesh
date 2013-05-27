###
Builtin Utilities Plugin
###

_ = require 'underscore'
crypto = require 'crypto'
querystring = require 'querystring'

exports.name = 'builtins'
exports.description = 'Exposes built-in convenience methods'

exports.postStart = (context) ->
    {repl} = context
    
    ###
    Underscore utilities, see:
    http://documentcloud.github.io/underscore
    ###
    repl.context.__ = _

    ###
    Hashing functions
    ###
    repl.context.md5 = (value) ->
        crypto.createHash('md5').update(value).digest 'hex'

    repl.context.sha = (value) ->
        crypto.createHash('sha1').update(value).digest 'hex'

    ###
    Random functions
    ###
    repl.context.rand = (start, end) ->
        if not start?
            start = 0
            end = 1
        else if not end?
            end = start
            start = 0

        Math.random() * (end - start) + start

    # Generate a random integer
    repl.context.randInt = (start, end) ->
        Math.round repl.context.rand(start, end)

    # Generate a random list of choices from an array
    repl.context.randChoices = (choices, length=1) ->
        result = []

        while --length >= 0
            result.push choices[Math.floor(Math.random() * choices.length)]

        result

    # Generate a random alphanumeric case-sensitive string
    repl.context.randString = (length, charSet='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789') ->
        repl.context.randChoices(charSet.split(''), length).join ''

    # Generate a random lowercase hexadecimal string
    repl.context.randHex = (length) ->
        repl.context.randString length, 'abcdef0123456789'

    ###
    Number representation shortcuts
    ###
    repl.context.bin = (val) -> val.toString 2
    repl.context.oct = (val) -> val.toString 8
    repl.context.hex = (val) -> val.toString 16

    ###
    URL encoding / decoding
    ###
    # Expose the querystring module
    repl.context.querystring = querystring
    # Shortcut to encode URL components
    repl.context.urlenc = querystring.escape
    # Shortcut to decode URL components
    repl.context.urldec = querystring.unescape

    ###
    REPL Commands
    ###
    repl.commands['.cls'] =
        help: 'Clear the screen'
        action: ->
            repl.outputStream.write '\u001B[2J\u001B[0;0f'
            repl.displayPrompt()
