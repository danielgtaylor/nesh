###
Builtin Utilities Plugin
###

crypto = require 'crypto'

exports.postStart = (repl) ->
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
