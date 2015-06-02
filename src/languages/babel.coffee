###
ES6/7 language component for Nesh, the Node.js enhanced shell.
###
require 'colors'

babel = require 'babel-core'
log = require '../log'
path = require 'path'
vm = require 'vm'

exports.setup = ({nesh}) ->
    log.debug 'Loading Babel'

    require 'babel-core/register'

    # Set the compile function to convert CoffeeScript -> bare Javascript
    nesh.compile = (data) ->
        babel.transform data

    # Import the CoffeeScript REPL, which handles individual line commands
    nesh.repl =
      start: (opts) ->
          opts.eval = (code, context, filename, callback) ->
              if code[0] is '(' and code[code.length - 1] is ')'
                  code = code.slice 1, -1

              err = null
              output = null
              try
                  result = babel.transform(code, stage: 0)
                  output = vm.runInThisContext(result.code, {filename})
              catch e
                err = e

              # Sometimes this is the only output... in that case just ignore
              if output is 'use strict' then output = undefined

              callback err, output

          repl = require('repl').start opts

    # Add the CoffeeScript version to the system's list of versions
    process.versions['babel'] = babel.version

    # Set the default welcome message to include the CoffeeScript version
    nesh.defaults.welcome = "Babel #{babel.version} on Node #{process.version}\nType " + '.help'.cyan + ' for more information'

    # Set the CoffeeScript prompt
    nesh.defaults.prompt = 'babel> '
    nesh.defaults.useGlobal = true

    # Save history in ~/.babel_history
    nesh.defaults.historyFile = path.join(nesh.config.home, '.babel_history')
