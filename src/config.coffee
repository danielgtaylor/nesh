###
Nesh Configuration. Implements a basic configuration system
which can load and save state via JSON. By default this data
is stored in ~/.nesh_config.json, but a custom path can be
passed to the load and save functions.
###
fs = require 'fs'
log = require './log'
path = require 'path'

_config = {}

config = exports

# The default path to the configuration file
config.path = path.join process.env.HOME, '.nesh_config.json'

# Load a configuration file. This should be called once before
# loading plugins so that plugins have access to the config.
# Calling it again will reload the configuration.
config.load = (path = config.path) ->
    if fs.existsSync path
        # Try to load the config file
        log.debug "Loading config from #{path}"
        try
            _config = require path
        catch e
            throw "Error loading Nesh config from #{path}: #{e}"
    else
        log.debug "No config found at #{path}"

# Save the configuration to a file.
config.save = (path = config.path) ->
    fs.writeFileSync path, JSON.stringify(_config)

# Get the configuration object
config.get = ->
    _config
