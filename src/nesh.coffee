###
Node Enhanced Interactive Interpreter
=====================================
Provides a simple to use, extensible, embeddable interpreter for
your apps.
###
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
nesh.repl = require 'repl'

# A list of currently loaded plugins
nesh.plugins = []

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

        processPlugins 'postStart', repl, callback

# Load default plugins
nesh.loadPlugin require('./plugins/welcome'), (err) ->
    console.error 'Problem setting up welcome plugin: ', err if err
nesh.loadPlugin require('./plugins/version'), (err) ->
    console.error 'Problem setting up version plugin: ', err if err
