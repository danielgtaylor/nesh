assert = require 'assert'
fs = require 'fs'
nesh = null
path = require 'path'

describe 'nesh', ->
    it 'should import without error', ->
        nesh = require '../lib/nesh'

    it 'should start without error and produce output', (done) ->
        # Create a dummy output stream to catch output
        output = ''
        opts = 
            outputStream:
                write: (data) ->
                    output += data

        nesh.start opts, (err) ->
            assert.equal false, err?
            assert.ok output
            done()

describe 'languages', ->
    it 'should load coffee-script', ->
        nesh.loadLanguage 'coffee'

    it 'should load a language via a function', (done) ->
        nesh.loadLanguage ->
            nesh.compile = null
            nesh.repl = require 'repl'
            nesh.defaults.welcome = 'Welcome!'
            nesh.defaults.prompt = 'nesh> '
            done()

    it 'should have a nesh reference in the context', (done) ->
        nesh.loadLanguage (context) ->
            assert.ok context.nesh
            done()

describe 'plugins', ->
    it 'should load a valid plugin', (done) ->
        plugin =
            name: 'test'
            description: 'foo bar baz'
            setup: (context) ->
                context.nesh.defaults.foo = 'bar'

        nesh.loadPlugin plugin, (err) ->
            nesh.plugins.pop()
            assert.equal false, err?
            done()

    it 'should pass a valid context to setup', (done) ->
        called = false
        plugin =
            setup: (context) ->
                called = true
                assert.ok context.nesh

        nesh.loadPlugin plugin, (err) ->
            nesh.plugins.pop()
            assert.ok called
            done()

    it 'should return an error on plugin setup error', (done) ->
        plugin =
            setup: (context) ->
                throw new Error('Fake error!')

        nesh.loadPlugin plugin, (err) ->
            nesh.plugins.pop()
            assert.equal true, err?
            done()

    it 'should return an error on async plugin setup error', (done) ->
        plugin =
            setup: (context, next) ->
                next 'Fake error!'

        nesh.loadPlugin plugin, (err) ->
            nesh.plugins.pop()
            assert.equal true, err?
            done()

    it 'should pass a valid context to preStart', (done) ->
        called = false
        plugin =
            preStart: (context) ->
                called = true
                assert.ok context.nesh
                assert.ok context.options

        nesh.loadPlugin plugin, (err) ->
            assert.equal false, err?

            opts =
                outputStream:
                    write: (data) ->

            nesh.start opts, (err, repl) ->
                nesh.plugins.pop()
                assert.ok called
                assert.equal false, err?
                done()

    it 'should return an error on plugin preStart error', (done) ->
        called = false
        plugin =
            preStart: ->
                called = true
                throw new Error('Fake error!')

        nesh.loadPlugin plugin, (err) ->
            assert.equal false, err?

            opts =
                outputStream:
                    write: (data) ->

            nesh.start opts, (err) ->
                nesh.plugins.pop()
                assert.ok called
                assert.equal true, err?
                done()

    it 'should return an error on async plugin preStart error', (done) ->
        called = false
        plugin =
            preStart: (context, next) ->
                called = true
                next 'Fake error!'

        nesh.loadPlugin plugin, (err) ->
            assert.equal false, err?

            opts =
                outputStream:
                    write: (data) ->

            nesh.start opts, (err) ->
                nesh.plugins.pop()
                assert.ok called
                assert.equal true, err?
                done()

    it 'should pass a valid context to postStart', (done) ->
        called = false
        plugin =
            postStart: (context) ->
                called = true
                assert.ok context.nesh
                assert.ok context.options
                assert.ok context.repl

        nesh.loadPlugin plugin, (err) ->
            assert.equal false, err?

            opts =
                outputStream:
                    write: (data) ->

            nesh.start opts, (err, repl) ->
                nesh.plugins.pop()
                assert.ok called
                assert.equal false, err?
                done()

    it 'should return an error on plugin postStart error', (done) ->
        called = false
        plugin =
            postStart: ->
                called = true
                throw new Error('Fake error!')

        nesh.loadPlugin plugin, (err) ->
            assert.equal false, err?

            opts =
                outputStream:
                    write: (data) ->

            nesh.start opts, (err) ->
                nesh.plugins.pop()
                assert.ok called
                assert.equal true, err?
                done()

    it 'should return an error on async plugin postStart error', (done) ->
        called = false
        plugin =
            postStart: (context, next) ->
                called = true
                next 'Fake error!'

        nesh.loadPlugin plugin, (err) ->
            assert.equal false, err?

            opts =
                outputStream:
                    write: (data) ->

            nesh.start opts, (err) ->
                nesh.plugins.pop()
                assert.ok called
                assert.equal true, err?
                done()

describe 'config', ->
    it 'should load a valid config file', ->
        filename = path.resolve '.test-config.json'
        fs.writeFileSync filename, '{"plugins": ["test"]}'
        nesh.config.load filename
        fs.unlinkSync filename
        config = nesh.config.get()
        assert.ok config.plugins
        assert.equal 'test', config.plugins[0]

    it 'should throw on invalid input', ->
        filename = path.resolve '.test-broken-config.json'
        fs.writeFileSync filename, '{plugins ["test"]}'
        assert.throws ->
            nesh.config.load filename
        fs.unlinkSync filename

    it 'should save a valid config', ->
        filename = path.resolve '.test-write-config.json'
        nesh.config.reset()
        config = nesh.config.get()
        config.test = 'test'
        nesh.config.save filename
        data = fs.readFileSync filename, 'utf-8'
        fs.unlinkSync filename
        assert.equal '{"test":"test"}', data

describe 'log', ->
    before ->
        # Setup logging for testing
        nesh.log.test()

    it 'should log messages via debug', ->
        nesh.log.debug 'Just a test'
        assert.equal 'Just a test', nesh.log.output
        nesh.log.output = ''

    it 'should log messages via info', ->
        nesh.log.info 'Just a test'
        assert.equal 'Just a test', nesh.log.output
        nesh.log.output = ''

    it 'should log messages via warn', ->
        nesh.log.warn 'Just a test'
        assert.equal 'Just a test', nesh.log.output
        nesh.log.output = ''

    it 'should log messages via error', ->
        nesh.log.error 'Just a test'
        assert.equal 'Just a test', nesh.log.output
        nesh.log.output = ''

describe 'eval', ->
    it 'should eval in the REPL context', (done) ->
        opts =
            evalData: 'var hello = function (name) { return "Hello, " + name; }'
            outputStream:
                write: (data) ->

        nesh.start opts, (err, repl) ->
            assert.ok repl.context.hello
            assert.equal false, err?
            done()
