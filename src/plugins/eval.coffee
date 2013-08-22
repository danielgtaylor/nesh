###
Eval plugin for Nesh to evaluate code within the REPL context.
###
log = require '../log'
vm = require 'vm'

exports.name = 'eval'
exports.description = 'Evaluates code in the context of the REPL'

# Evaluate evalData from options in the context of the
# REPL if evalData is set, otherwise do nothing.
exports.postStart = (context) ->
    {repl} = context
    if repl.opts.evalData
        log.debug 'Evaluating code in the REPL'
        if global is repl.context
        	vm.runInThisContext repl.opts.evalData
        else
        	vm.runInContext repl.opts.evalData, repl.context
