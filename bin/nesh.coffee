#!/usr/bin/env coffee

nesh = require '../lib/nesh'

optimist = require('optimist')
    .usage('$0 [options]')
    .options 'c',
        describe: 'Load CoffeeScript; shortcut for -l coffee'
        boolean: true
    .options 'h',
        alias: 'help'
        describe: 'Show help and exit'
        boolean: true
    .options 'l',
        alias: 'lang'
        describe: 'Set language'
        default: 'js'
        string: true
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

if argv.c
    argv.lang = 'coffee'

if argv.lang isnt 'js'
    nesh.loadLanguage argv.lang

opts = {}
opts.prompt = argv.prompt if argv.prompt?
opts.welcome = argv.welcome if argv.welcome?

nesh.start opts, (err) ->
    console.error err if err
