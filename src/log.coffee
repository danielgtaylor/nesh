###
Nesh logging module. This is exposed as `nesh.logger` and can be
hooked into your app's logging infrastructure. By default the
messages get printed to stdout.
###
require 'colors'

module.exports = logger =
    # Log levels
    DEBUG: 4
    INFO: 3
    WARN: 2
    ERROR: 1

    # Default level (INFO)
    level: 3

    # Use console color escape codes?
    colors: true

    # Get the log level name
    levelName: ->
        names = {}
        names[logger.DEBUG] = 'debug'
        names[logger.INFO] = 'info'
        names[logger.WARN] = 'warn'
        names[logger.ERROR] = 'error'

        names[logger.level]

    # Log a message with a specific level, but only if that
    # level is within logger.level.
    log: (level, msg) ->
        console.log msg if level <= logger.level

    # The following are convenience functions to log at
    # various levels.
    debug: (msg) ->
        logger.log logger.DEBUG, if logger.colors then msg.grey else msg

    info: (msg) ->
        logger.log logger.INFO, msg

    warn: (msg) ->
        logger.log logger.WARNING, if logger.colors then msg.yellow else msg

    error: (msg) ->
        logger.log logger.ERROR, if logger.colors then msg.red else msg

    ###
    Convenience methods for logging frameworks
    ###

    # Instant setup for Winston - https://npmjs.org/package/winston
    winston: ->
        winston = require 'winston'
        logger.colors = false
        logger.log = (level, msg) ->
            winston[logger.levelName()] msg if level <= logger.level
