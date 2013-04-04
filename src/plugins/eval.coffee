###
Eval plugin for Nesh to evaluate code within the REPL context.
###
vm = require 'vm'

# Evaluate evalData from options in the context of the
# REPL if evalData is set, otherwise do nothing.
exports.postStart = (repl) ->
    if repl.opts.evalData
        vm.runInContext repl.opts.evalData, repl.context
