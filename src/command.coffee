###
The nesh command, which parses options and then drops the user
into an interactive session.
###
_ = require 'underscore'
{exec} = require 'child_process'
fs = require 'fs'
nesh = require './nesh'
path = require 'path'

optimist = require('optimist')
    .usage('$0 [options]')
    .options 'c',
        describe: 'Load CoffeeScript; shortcut for -l coffee'
        boolean: true
    .options 'disable',
        describe: 'Disable plugin(s) for autoload'
        string: true
    .options 'e',
        alias: 'eval'
        describe: 'Filename or string to eval in the REPL context'
        string: true
    .options 'enable',
        describe: 'Enable plugin(s) for autoload'
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
    .options 'plugins',
        describe: 'List auto-loaded plugins'
        boolean: true
    .options 'v',
        alias: 'version'
        describe: 'Show version and exit'
        boolean: true
    .options 'verbose',
        describe: 'Enable verbose debug output'
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
    nesh.log.info "nesh version #{nesh.version}"
    return

if argv['list-languages']
    nesh.log.info nesh.languages().join ', '
    return

if argv.verbose
    nesh.log.level = nesh.log.DEBUG

nesh.config.load()

if argv.enable
    enabled = argv.enable.split ','

    install = enabled.filter (item) ->
        not fs.existsSync "./plugins/#{item}.js"

    prefix = path.join process.env.HOME, '.nesh_modules'
    if install.length
        exec "npm --prefix=#{prefix} --color=always install #{install.join ' '} 2>&1", (err, stdout) ->
            nesh.log.info stdout
            throw err if err

    config = nesh.config.get()
    config.plugins ?= []
    config.plugins = _(config.plugins.concat enabled).uniq()
    config.pluginsExclude ?= []
    config.pluginsExclude = _(config.pluginsExclude).reject (item) -> item in enabled

    nesh.config.save()

if argv.disable
    disabled = argv.disable.split ','

    prefix = path.join process.env.HOME, '.nesh_modules'
    uninstall = disabled.filter (item) ->
        fs.existsSync path.join(prefix, 'node_modules', item)

    if uninstall.length
        exec "npm --prefix=#{prefix} --color=always rm #{uninstall.join ' '} 2>&1", (err, stdout) ->
            nesh.log.info stdout
            throw err if err

    config = nesh.config.get()
    config.plugins ?= []
    config.plugins = _(config.plugins).reject (item) -> item in disabled
    config.pluginsExclude ?= []
    config.pluginsExclude = _(config.pluginsExclude.concat disabled).uniq()

    nesh.config.save()

if argv.enable or argv.disable
    return

if argv.c
    argv.lang = 'coffee'

if argv.lang
    nesh.loadLanguage argv.lang

opts = {}
opts.prompt = argv.prompt if argv.prompt?
opts.welcome = argv.welcome if argv.welcome?

if argv.eval
    isJs = false
    if fs.existsSync argv.eval
        isJs = argv.eval[-3..] is '.js'
        opts.evalData = fs.readFileSync argv.eval, 'utf-8'
    else
        opts.evalData = argv.eval

    if not isJs and nesh.compile
        nesh.log.debug 'Compiling eval data'
        opts.evalData = nesh.compile opts.evalData

nesh.init true, (err) ->
    return nesh.log.error err if err

    if argv.plugins
        for plugin in nesh.plugins
            nesh.log.info "#{plugin.name}: " + "#{plugin.description}".grey
        return

    nesh.start opts, (err) ->
        nesh.log.error err if err
