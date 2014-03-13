__doc__ = """Shorthand for requiring and assigning a module

  .require colors -> colors = require('colors')
  .require ./User -> User = require('./User')
  .require ./model/User -> User = require('./model/User')
  .require use-global-fibrous -> useGlobalFibrous = require('use-global-fibrous')
  .require lodash-node/modern/objects -> objects = require('lodash-node/modern/objects')

  If the `require` is successful, the name of the variable that the module
  has been assigned to will be pre-filled into the REPL as the next
  line of input. This behavior can be disabled with the command-line
  argument `--no-require-echo`.

  """

colors = require 'colors'
optimist = require 'optimist'
vm = require 'vm'
fs = require 'fs'

displayUsage = (repl) ->
  repl.outputStream.write colors.cyan "Usage: .require <unquoted-module-name-or-path> [assign-to]\n"
  repl.displayPrompt()

exports.postStart = (context) ->
  {repl} = context

  exec = (s) ->
    if repl.useGlobal
      vm.runInThisContext s
    else
      vm.runInContext s, repl.context

  action = (m) ->

    if m.trim().length == 0
      displayUsage(repl)
      return

    if /^[\.\/]+$/.test m
      m = fs.realpathSync (process.cwd() + "/" + m)

    tokens = m.split /\s+/
    if tokens.length > 2
      displayUsage(repl)
      return
    else if tokens.length == 2
      vName = tokens[1]
      m = tokens[0]
    else
      vName = ""
      capNext = false
      for c in m
        if c is '/'
          vName = ""
        else if c is '-'
          capNext = true
        else if c is '.'
        else
          if capNext
            vName += c.toUpperCase()
          else
            vName += c
          capNext = false

    expanded = "#{ vName } = require(#{ JSON.stringify m })"
    repl.outputStream.write colors.green expanded + "\n"
    ok = true
    try
      exec expanded
    catch e
      ok = false
      try
        if m[..1] != "./"
          action "./" + m
        else
          throw e
      catch e2
        ok = false
        repl.outputStream.write colors.red ".require: #{ e }\n"
    repl.displayPrompt()
    if ok and optimist.argv['require-echo'] isnt false
      repl.rli.write vName

  repl.defineCommand 'require',
    help: "Require a module and assign it to a variable with the same name"
    action: action
