###
Node Enhanced Interactive Interpreter
=====================================
Provides a simple to use, extensible, embeddable interpreter for
your apps.
###
fs = require 'fs'
neshInfo = require '../package'

###
Process a method call on all loaded plugins. This calls the requested
method on each plugin in the order they were added, skipping plugins
which do not have the method defined. If the method is defined and it
takes two parameters (arg, next) then it is assumed to be async and
treated as such, otherwise treated as a sync call. Callback is
passed an error if one occurs during processing.
###
processPlugins = (method, arg, callback) ->
    return callback?() if not nesh.plugins.length

    # Setup async loop function
    process = (i) ->
        return callback?() if i >= nesh.plugins.length

        if nesh.plugins[i][method]?
            callPluginMethod nesh.plugins[i][method], arg, (err) ->
                return callback? err if err
                process i + 1
        else
            # Skip this plugin as it doesn't have this method
            process i + 1

    # Start processing the list of plugins
    process(0)

###
Call the possibly async method. callback gets passed an error
object if an error occurs.
###
callPluginMethod = (method, arg, callback) ->
    if method.length is 2
        # Takes a next function, this is an async call
        method arg, callback
    else
        # No next function, this is a sync call
        try
            method arg
        catch err
            return callback? err
        callback()


nesh = exports

# The nesh (not Coffeescript or Node) version
nesh.version = neshInfo.version

# An object used to populate default values for the repl
nesh.defaults =
    prompt: 'nesh> '

# Languages
nesh.compile = null
nesh.repl = require 'repl'

# A list of currently loaded plugins
nesh.plugins = []

# Logging functions that can be overridden to hook into
# various logging frameworks (e.g. winston, log4js)
nesh.log = require './log'

# Get a list of built-in languages that can be loaded
nesh.languages = ->
    # List every js file without its extension in the languages directory
    fs.readdirSync("#{__dirname}/languages").filter((item) -> item[-2..] is 'js').map (item) -> item.split('.')[..-2].join('.')

# Load a new language by name or as a function
nesh.loadLanguage = (data) ->
    switch typeof data
        when 'function'
            data nesh
        when 'string'
            require("./languages/#{data}").setup nesh
        else
            throw new Error "Data must be a function or string! Received #{data}"

# Add a new plugin. Callback is passed an error object if one occurs.
nesh.loadPlugin = (plugin, callback) ->
    if typeof(plugin) is 'string'
        # Find the right place to import this plugin
        try
            plugin = require "./plugins/#{plugin}"
        catch e
            try
                plugin = require plugin
            catch e
                callback "Could not find plugin '#{plugin}'!"

    nesh.plugins.push plugin
    if plugin.setup
        callPluginMethod plugin.setup, nesh.defaults, callback
    else
        callback()

# Start the repl, processing any loaded plugins.
nesh.start = (opts = {}, callback) ->
    if typeof opts is 'function'
        callback = opts

    for own key, value of nesh.defaults
        opts[key] = value unless opts[key]?

    processPlugins 'preStart', opts, (err) ->
        return callback? err if err

        repl = nesh.repl.start opts

        # Expose the passed options in the repl object
        repl.opts = opts

        processPlugins 'postStart', repl, (err) ->
            return callback? err if err
            callback? err, repl

# Load default plugins
for plugin in ['eval', 'history', 'welcome', 'version']
    nesh.loadPlugin require("./plugins/#{plugin}"), (err) ->
        console.error "Problem loading #{plugin} plugin: ", err if err
