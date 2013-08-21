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
    # !! - see https://github.com/jashkenas/coffee-script/pull/3113 - currently prevents that.
    # !! Once the bug has been fixed, replace 'no' with the expression in the inline comment, 
    # !! with the fixed-in version number filled in for '?'
    nesh.defaults.useGlobal = no # semver.satisfies(coffee.VERSION, ">= ?")
    # Save history in ~/.coffee_history
    nesh.defaults.historyFile = path.join(process.env.HOME, '.coffee_history')
