###
History Plugin - adds persistent history to the interpreter so
long as no `.history` command has already been defined.

This plugin adds two new options:

 * historyFile: the filename of where to store history lines
 * historyMaxInputSize: Maximum number of bytes to load from
                        the history file

History support can be disabled by setting `historyFile` to
null or false in the interpreter options on startup:

    nesh.start({historyFile: null}, function (err) { ... });

###
fs = require 'fs'
path = require 'path'

exports.setup = (defaults) ->
    defaults.historyFile ?= path.join(process.env.HOME, '.node_history')
    defaults.historyMaxInputSize ?= 10240

exports.postStart = (repl) ->
    # Skip if we have no file to use
    return unless repl.opts.historyFile

    # Skip if a `.history` command is already setup
    return if repl.commands['.history']

    maxSize = repl.opts.historyMaxInputSize
    lastLine = null
    try
        # Get file info and at most maxSize of command history
        stat = fs.statSync repl.opts.historyFile
        size = Math.min maxSize, stat.size
        # Read last `size` bytes from the file
        readFd = fs.openSync repl.opts.historyFile, 'r'
        buffer = new Buffer(size)
        fs.readSync readFd, buffer, 0, size, stat.size - size
        # Set the history on the interpreter
        repl.rli.history = buffer.toString().split('\n').reverse()
        # If the history file was truncated we should pop off a potential partial line
        repl.rli.history.pop() if stat.size > maxSize
        # Shift off the final blank newline
        repl.rli.history.shift() if repl.rli.history[0] is ''
        repl.rli.historyIndex = -1
        lastLine = repl.rli.history[0]

    fd = fs.openSync repl.opts.historyFile, 'a'

    repl.rli.addListener 'line', (code) ->
        if code and code.length and code isnt '.history' and lastLine isnt code
            # Save the latest command in the file
            fs.write fd, "#{code}\n"
            lastLine = code

    process.on 'exit', ->
        fs.closeSync fd

    # Add a command to show the history stack
    repl.commands['.history'] =
        help: 'Show command history'
        action: ->
            repl.outputStream.write "#{repl.rli.history[..].reverse().join '\n'}\n"
            repl.displayPrompt()
