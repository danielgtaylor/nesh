###
Node Enhanced Interactive Interpreter
=====================================
Provides a simple to use, extensible, embeddable interpreter for
your apps.
###
fs = require 'fs'
neshInfo = require '../package'
path = require 'path'

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

# Start the repl, processing any loaded plugins.
start = (opts, callback) ->
    if typeof opts is 'function'
        callback = opts

    for own key, value of nesh.defaults
        opts[key] = value unless opts[key]?

    processPlugins 'preStart', {nesh, options: opts}, (err) ->
        return callback? err if err

        repl = nesh.repl.start opts

        # Expose the passed options in the repl object
        repl.opts = opts

        processPlugins 'postStart', {nesh, options: opts, repl}, (err) ->
            return callback? err if err
            callback? err, repl

nesh = exports

# The nesh (not Coffeescript or Node) version
nesh.version = neshInfo.version

# An object used to populate default values for the repl
nesh.defaults =
    useGlobal: yes  # Using the global context allows packages such as 'colors' to modify built-in prototypes.
    prompt: 'nesh> '

# Languages
nesh.compile = null
nesh.repl = require 'repl'

# A list of currently loaded plugins
nesh.plugins = []

# User configuration
nesh.config = require './config'

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
            data {nesh}
        when 'string'
            require("./languages/#{data}").setup {nesh}
        else
            throw new Error "Data must be a function or string! Received #{data}"

# Add a new plugin. Callback is passed an error object if one occurs.
nesh.loadPlugin = (plugin, callback) ->
    if typeof(plugin) is 'string'
        name = plugin
        # Find the right place to import this plugin
        try
            plugin = require "./plugins/#{name}"
        catch e
            try
                prefix = path.join process.env.HOME, '.nesh_modules', 'node_modules'
                plugin = require path.join(prefix, name)
            catch e
                return callback "Could not find plugin '#{name}': #{e}!"

        # No name defined? Use the filename I guess...
        plugin.name ?= name
        plugin.description ?= 'No description'

    nesh.plugins.push plugin
    if plugin.setup
        callPluginMethod plugin.setup, {nesh}, callback
    else
        callback()

# Initialize nesh by autoloading plugins and preparing to start
# a new REPL. This need not be called explicitly - if it is not
# called then `nesh.start` will invoke it when needed. Calling
# it explicitly gives you more control over plugin loading and
# application startup.
initialized = false
nesh.init = (autoload=true, callback) ->
    initialized = true
    if autoload
        # Load default plugins
        nesh.loadPlugin 'autoload', (err) ->
            if err then callback? "[autoload] #{err}" else callback?()
    else
        callback?()

# Start the REPL. If `nesh.init` has not been called, then it will be
# called before starting the REPL. Any registered plugins will have
# their `preStart` and `postStart` event handlers called. The
# `callback` function is given (err, repl) where err is set if there
# was an error, and `repl` is the new REPL that was created.
nesh.start = (opts = {}, callback) ->
    if not initialized
        nesh.init true, (err) ->
            return callback? err if err
            return start opts, callback
    else
        return start opts, callback
