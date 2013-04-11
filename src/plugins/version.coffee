###
Version Information Plugin
==========================
This plugin adds a new command to the repl called `.versions` that
will print out version information for nesh, any loaded languages,
and Node itself. The new command is listed with a description when
you run `.help`.
###
coffee = require 'coffee-script'
nesh = require '../nesh'

exports.name = 'version'
exports.description = 'Adds a .versions command'

exports.setup = (defaults) ->
    process.versions.nesh = nesh.version

# The postStart action - run after the repl is created
# This adds the `.versions` command to the interpreter
exports.postStart = (repl) ->
    repl.commands['.versions'] =
        help: 'Show Node version information'
        action: ->
            versions = ("#{key} #{value}" for key, value of process.versions).join '\n'
            repl.outputStream.write "#{versions}\n"
            repl.displayPrompt()
