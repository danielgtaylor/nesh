###
CoffeeScript language component for Nesh, the Node.js enhanced shell.
###
require 'colors'

coffee = require 'coffee-script'
log = require '../log'
path = require 'path'
semver = require 'semver'

exports.setup = (context) ->
    {nesh} = context
    log.debug 'Loading CoffeeScript'
    # Set the compile function to convert CoffeeScript -> bare Javascript
    nesh.compile = (data) ->
        coffee.compile data, {bare: true, header: false}
    # Import the CoffeeScript REPL, which handles individual line commands
    nesh.repl = require 'coffee-script/lib/coffee-script/repl'
    # Add the CoffeeScript version to the system's list of versions
    process.versions['coffee-script'] = coffee.VERSION
    # Set the default welcome message to include the CoffeeScript version
    nesh.defaults.welcome = "CoffeeScript #{coffee.VERSION} on Node #{process.version}\nType " + '.help'.cyan + ' for more information'
    # Set the CoffeeScript prompt
    nesh.defaults.prompt = 'coffee> '
    # !! While we *want* to use the global context, a bug in CoffeeScript as of 1.6.3 
    # !! - see https://github.com/jashkenas/coffee-script/pull/3113 - prevents that.
    # !! Versions newer than 1.6.3 include the fix.
    nesh.defaults.useGlobal = semver.satisfies(coffee.VERSION, "> 1.6.3")
    if not nesh.defaults.useGlobal
        log.warn 'Warning: inherited global context requires CoffeeScript > 1.6.3'
        log.warn '         packages that modify built-in prototypes may not work'
    # Save history in ~/.coffee_history
    nesh.defaults.historyFile = path.join(nesh.config.home, '.coffee_history')
