fibrous = require 'use-global-fibrous'
optimist = require 'optimist'

# Note: this doesn't work right now. 
# See https://github.com/danielgtaylor/nesh/issues/9
optimist.describe ['f', 'fibrous'], "Use fibrous (each input to the REPL will run in a Fiber)"

if optimist.argv.f? or optimist.argv.fibrous?

  exports.setup = (context) ->
    {nesh} = context
    process.versions.fibrous = fibrous.version
    nesh.defaults.prompt = "fibrous-" + nesh.defaults.prompt
    nesh.defaults.welcome = nesh.defaults.welcome.replace "\n", " with fibrous #{ fibrous.version }\n", 1
    nesh.log.debug "Using fibrous #{ fibrous.version } from #{ require.resolve 'fibrous' }"

  exports.postStart = (context) ->
    repl = context.repl

    # Wrap .eval as a fibrous function
    rawEval = repl.eval
    repl.eval = fibrous (input, context, filename) ->
      rawEval.sync input, context, filename

    # Install fibrous so we can use it
    repl.context.fibrous = fibrous
