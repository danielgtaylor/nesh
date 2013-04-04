###
The nesh command, which parses options and then drops the user
into an interactive session.
###
fs = require 'fs'
nesh = require './nesh'

optimist = require('optimist')
    .usage('$0 [options]')
    .options 'c',
        describe: 'Load CoffeeScript; shortcut for -l coffee'
        boolean: true
    .options 'e',
        alias: 'eval'
        describe: 'Filename or string to eval in the REPL context'
        string: true
    .options 'h',
        alias: 'help'
        describe: 'Show help and exit'
        boolean: true
    .options 'l',
        alias: 'lang'
        describe: 'Set interpreter language'
        string: true
    .options 'list-languages',
        describe: 'List available languages'
        boolean: true
    .options 'p',
        alias: 'prompt'
        describe: 'Set prompt string'
        string: true
    .options 'v',
        alias: 'version'
        describe: 'Show version and exit'
        boolean: true
    .options 'w',
        alias: 'welcome'
        describe: 'Set welcome message'
        string: true

argv = optimist.argv

if argv.h
    optimist.showHelp()
    return

if argv.v
    console.log "nesh version #{nesh.version}"
    return

if argv['list-languages']
    console.log nesh.languages().join ', '
    return

if argv.c
    argv.lang = 'coffee'

if argv.lang
    nesh.loadLanguage argv.lang

opts = {}
opts.prompt = argv.prompt if argv.prompt?
opts.welcome = argv.welcome if argv.welcome?

if argv.eval
    if fs.existsSync argv.eval
        opts.evalData = fs.readFileSync argv.eval, 'utf-8'
    else
        opts.evalData = argv.eval

    if nesh.compile
        opts.evalData = nesh.compile opts.evalData

nesh.loadPlugin require('./plugins/builtins'), (err) ->
    return console.log err if err

    nesh.start opts, (err) ->
        console.error err if err
