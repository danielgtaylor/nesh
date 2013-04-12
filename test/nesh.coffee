assert = require 'assert'
nesh = null

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
