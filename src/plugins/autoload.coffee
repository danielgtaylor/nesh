###
Autoloader Plugin
=================
Loads the list of plugins specified in ~/.nesh_config.js if it exists,
otherwise loads a default set of plugins or a passed-in set of plugins.
This plugin is loaded by default when the `nesh` command is executed
in a terminal.

Config options:

{
    ...
    plugins: ['builtins', 'eval', ...],
    pluginsExclude: ['foo']
    ...
}

###
_ = require 'underscore'
fs = require 'fs'
nesh = require '../nesh'
path = require 'path'

exports.setup = (defaults, next) ->
    nesh.log.debug 'Loading plugin autoload'

    # The default list of plugins
    defaultPlugins = ['builtins', 'eval', 'history', 'version', 'welcome']

    # Get the Nesh user configuration
    config = nesh.config.get()

    # Add plugins from config to the list of loaded plugins
    defaultPlugins = _(defaultPlugins.concat config.plugins).uniq() if config.plugins?

    # Remove excluded plugins from the list of loaded plugins
    defaultPlugins = _(defaultPlugins).reject((item) -> item in config.pluginsExclude) if config.pluginsExclude?

    # Set the list of loaded plugins so they are available to other plugins
    defaults.plugins ?= defaultPlugins

    # Load the plugins in parallel, returning an error if one is encountered
    completed = 0
    already_errored = false
    for plugin in defaultPlugins
        do (plugin) ->
            nesh.log.debug "Loading plugin #{plugin}"
            nesh.loadPlugin plugin, (err) ->
                if err
                    next "Error loading plugin #{plugin}: #{err}" unless already_errored
                    already_errored = true
                else
                    completed += 1
                    if completed >= defaultPlugins.length
                        next()
