colors = require 'colors'
intdoc = require 'intdoc'
lang = require 'lodash-node/modern/lang'
vm = require 'vm'

__doc__ = """Shows documentation for an expression; you can also type Ctrl-Q in-line"""

lastTokenPlus = (input) ->
  """A crude cut at figuring out where the last thing you want to
    evaluate in what you're typing is

    Ex. If you are typing
      myVal = new somemodule.SomeClass

    You probably just want help on `somemodule.SomeClass`

    """

  t = ""
  for c in input by -1
    if c not in "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.[]'\"$_:"
      break
    t = c + t

  # Trim the string down if there are dots on either end
  if t[0] is "."
    t = t[1..]
  if t[-1..] is "."
    t = t[..-2]

  t


exports.postStart = (context) ->
  {repl} = context

  document = (expr, reportErrors, showCode) ->
    if expr.trim().length == 0
      if reportErrors
        repl.outputStream.write colors.cyan "#{ __doc__ }\n"
    else
      try
        if repl.useGlobal
          result = vm.runInThisContext "(#{ expr })"
        else
          result = vm.runInContext "(#{ expr })", repl.context
      catch e
        if reportErrors
          repl.outputStream.write colors.red "Bad input; can't document\n"
        repl.displayPrompt()
        return null

      if result.that? and lang.isFunction result
        # This is a synchronized version of a fibrous function
        # so we look to the original one instead
        result = result.that
        defibbed = true
      else
        defibbed = false

      doc = intdoc result
      if defibbed
        callbackParam = doc.params.pop()
      if doc.name and doc.name.length > 0
        tyname = "[#{ doc.type }: #{ doc.name }]"
      else
        tyname = "[#{ doc.type }]"
      repl.outputStream.write colors.cyan tyname
      if typeof result is 'function' and doc.params?
        repl.outputStream.write colors.yellow " #{ doc.name }(#{ ("#{ x }" for x in doc.params).join ", "})"
        if defibbed
          repl.outputStream.write colors.yellow " *#{ callbackParam } handled by fibrous"
      repl.outputStream.write "\n"
      if doc.doc? and doc.doc.length > 0
        repl.outputStream.write doc.doc + "\n"

    if showCode
      if doc
        if doc.code?
          repl.outputStream.write colors.green doc.code + "\n"
        else
          repl.outputStream.write colors.green result.toString() + "\n"
    repl.displayPrompt()

    # Return the documentation
    doc


  repl.defineCommand 'doc',
    help: __doc__
    action: (expr) ->
      document expr, true

  # Add a handler for Ctrl-Q that does documentation for
  # the most recent thing you typed
  repl.inputStream.on 'keypress', (char, key) ->
    leave = true unless key and key.ctrl and not key.meta and not key.shift and key.name is 'q'
    if leave
      repl.__neshDoc__lastDoc = null
      return
    rli = repl.rli
    repl.__neshDoc__docRequested = true
    rli.write "\n"

  originalEval = repl.eval
  repl.eval = (input, context, filename, callback) ->
    if repl.__neshDoc__docRequested
      repl.__neshDoc__docRequested = false
      #console.log colors.green "'#{ input }'"
      input = input[1..-3]
      toDoc = lastTokenPlus input
      if toDoc != input
        repl.outputStream.write colors.yellow toDoc + "\n"
      if repl.__neshDoc__lastDoc == toDoc
        showCode = true
      else
        showCode = false
      doc = document toDoc, false, showCode
      repl.__neshDoc__lastDoc = toDoc
      repl.rli.write input
    else
      repl.__neshDoc__lastDoc = null
      originalEval input, context, filename, callback

#module.exports.lastTokenPlus = lastTokenPlus
