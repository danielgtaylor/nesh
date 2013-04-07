Node Enhanced Shell
===================
An enhanced extensible interactive interpreter (REPL) for Node.js and languages that compile to Javascript, like CoffeeScript. Some features:

 * Lightweight & fast
 * Built-in convenience functions
 * Easily extensible interactive environment
 * Asyncronous plugin architecture
 * Multi-language support (e.g. CoffeeScript)

[![Dependency Status](https://gemnasium.com/danielgtaylor/nesh.png)](https://gemnasium.com/danielgtaylor/nesh) [![Build Status](https://travis-ci.org/danielgtaylor/nesh.png?branch=master)](https://travis-ci.org/danielgtaylor/nesh)

Installation
------------
You can install and start using `nesh` with `npm` (note: you may need to use `sudo` to install globally):

```bash
npm install -g nesh

# Run nesh
nesh

# Run nesh with CoffeeScript
npm install -g coffee-script
nesh -c
```

If you wish to use `nesh` within your own project with `require 'nesh'` (i.e. to embed within your app) you can use the following non-global install instead:

```bash
npm install nesh
```

Basic Usage
-----------
The `nesh` command starts an interactive interpreter with a default set of plugins loaded. You can type commands and they will be executed, with the output or any errors displayed below the command.

### Command Help
You can get a list of options and help via:

```bash
nesh --help
```

### Setting a Language
Nesh supports multiple languages, and ships with CoffeeScript support out of the box. To select a language:

```bash
nesh --language coffee
```

You can get a list of supported built-in languages via:

```bash
nesh --list-languages
```

As a shortcut for CoffeeScript, you can also use `nesh -c`. It's also pretty easy to set up an alias for this, e.g. `alias cs='nesh -c'` in bash.

### Setting a Prompt & Welcome Message
A prompt can be set with the `--prompt` parameter, e.g. `nesh --prompt "test> "`. The welcome message can be set the same way with the `--welcome` parameter. You can disable the welcome message via e.g. `nesh --no-welcome`.

### Preloading Code
You can preload a script with the `--eval` option, which will evaluate either a file or string in the context of the interpreter, so anything you define will be available in the interpreter after startup. This is similar to using `ipython -i script.py`.

```bash
echo 'var hello = function (name) { return "Hello, " + name; }' >hello.js
nesh --eval hello.js
```

Now you can run `hello('world');` in the interpreter. A string can also be used:

```bash
nesh --eval "var test = 1;"
```

Languages other than Javascript can also be used. When using a non-Javascript language, the code loaded will use that language's compile function before running. For example:

```bash
nesh -c -e hello.coffee
```

Convenience Functions
---------------------
When run from the `nesh` command several built-in convenience functions are available.

### Hashing

#### md5 (value)
Return an MD5 hash of a value as a hexadecimal string.

#### sha (value)
Return a SHA1 hash of a value as a hexadecimal string.

### Random

#### rand ([start], [end])
Generate a random number. If neither `start` nor `end` are given, it returns a number between 0 and 1. If only `start` is given, a number between 0 and `start` is returned. Otherwise, a number between `start` and `end` is returned.

#### randChoices (choices, [length])
Select an array of random choices of length `length` from an array `choices`.

#### randString (length, [charSet])
Return a random string with characters selected from `charSet`, which defaults to case-sensitive alphanumeric characters.

#### randHex (length)
Return a random lowercase hexadecimal string.

Embedding the Interpreter
-------------------------
The Nesh interpreter can be embedded into your application, whether it is written in Javascript, Coffeescript, or another language that runs on Node. For example, to start an interactive CoffeeScript session on stdin/stdout from Javascript with a custom prompt and welcome message:

```javascript
nesh = require('nesh');

opts = {
    welcome: 'Welcome!',
    prompt: 'test> ',
    inputStream: process.stdin,
    outputStream: process.stdout
};

nesh.loadLanguage('coffee');

nesh.start(opts, function (err) {
    if (err) {
        console.log(err);
    }
});
```

### Embedding Reference

#### nesh.defaults
An object containing default values that are set when no such value is passed to `nesh.start`'s `opts` parameter.

#### nesh.languages ()
Get a list of supported built-in languages that can be passed as strings to `nesh.loadLanguage`.

#### nesh.loadLanguage (name)
Load a language to be interpreted, e.g. `coffee` for CoffeeScript.

#### nesh.loadPlugin (plugin)
Loads a plugin - see below in the Extending the Interpreter section for details.

#### nesh.start ([opts], [callback])
Create a new nesh REPL with the passed options `opts`. Allowed options include the defaults from the Node REPL module (http://nodejs.org/api/repl.html) as well as the following:

 * `welcome` A welcome message to be displayed on startup
 * `evalData` A javascript string to execute within the REPL context on startup

Extending the Interpreter
-------------------------
The Nesh interpreter can be easily extended with new languages and plugins.

Languages can be added using the `nesh.loadLanguage` function. New languages should override `nesh.compile`, `nesh.repl`, and probably `nesh.defaults.historyFile`. The `nesh.repl` object should provide a Node REPL-like interface with a `start` function and return a REPL-like object which may be modified by plugins. For example:

```coffeescript
nesh = require 'nesh'
mylang = require 'mylang'

nesh.loadLanguage (neshRef) ->
    neshRef.compile = (data) ->
        # Compile to js here
        mylang.compile data, {bare: true}
    neshRef.repl =
        start: (opts) ->
            # Do stuff here!
            opts.eval = mylang.eval
            repl = require('repl').start opts
            return repl
    neshRef.defaults.welcome = 'Welcome to my interpreter!'
    neshRef.defaults.historyFile = path.join(process.env.HOME, '.mylang_history')

nesh.start (err) ->
    console.log err if err
```

Plugins may define `setup`, `preStart`, and `postStart` functions that are called when the plugin is loaded, before a REPL is created, and after a REPL has been created respectively. Plugins are loaded via the `nesh.loadPlugin` function. A very simple example plugin written in CoffeeScript might look like this:

```coffeescript
nesh = require 'nesh'
util = require 'util'

myPlugin =
    setup: (defaults) ->
        console.log 'Setting up my plugin! Defaults:'
        console.log util.inspect defaults

    preStart: (opts) ->
        console.log 'About to start the interpreter with these options:'
        console.log util.inspect opts

    postStart: (repl) ->
        console.log 'Interpreter started! REPL:'
        console.log util.inspect repl

nesh.loadPlugin myPlugin, (err) ->
    console.log err if err

    nesh.start (err) ->
        console.log err if err
```

Several plugins ship with Nesh, just take a look at the `src/plugins` directory. If these ever need to be removed then you can do so by accessing the `nesh.plugins` array.

### Asyncronous Plugins
Sometimes, a plugin may take actions that must run asyncronously. To support these cases, each of the plugin's functions can take a callback parameter `next` which must be called when finished. For example, if we were loading the welcome message's default value from a database with an asyncronous call:

```coffeescript
myPlugin =
    setup: (defaults, next) ->
        mongodb.findOne name: 'defaultWelcome', (err, item) ->
            return next(err) if err

            defaults.welcome = item.message
            next()
```

### Default Plugins
Nesh ships with several default plugins:

 * `builtins` Adds built-in convenience functions to the global context
 * `eval` Evaluates javascript in `opts.evalData` in the context of the REPL
 * `history` Provides persistent command history for multiple languages
 * `version` Adds a `.versions` command to show Node, Nesh, and language versions
 * `welcome` Adds a welcome message to the interactive interpreter via `opts.welcome`

### Plugin Reference

#### Plugin.setup (defaults, [next])
Called when the plugin is first loaded. The `defaults` passed in are an object containing default values that will be used to initialize the interpreter when `nesh.start` is called. If `next` is defined, then the function is treated as asyncronous and `next` will be passed a function that must be called when finished. If an error occurs, then the error should be passed to `next`.

This is a good place to add or modify default values.

#### Plugin.preStart (opts, [next])
Called when `nesh.start` has been called but before the REPL is created and started. The `opts` passed in are a merged object made from the Nesh defaults and any options passed to `nesh.start`. If `next` is defined, then the function is treated as asyncronous and `next` will be passed a function that must be called when finished. If an error occurs, then the error should be passed to `next`.

This is a good place to print out information or modify the passed in options before they are sent to the REPL.

#### Plugin.postStart (repl, [next])
Called when `nesh.start` has been called and the REPL is started. The `repl` passed in is the newly created and started REPL from the `nesh.start` call and includes the `opts` from above as `repl.opts`. If `next` is defined, then the function is treated as asyncronous and `next` will be passed a function that must be called when finished. If an error occurs, then the error should be passed to `next`.

This is a good place to modify the REPL, e.g. adding new commands, modifying history, listening for specific key strokes, etc.

Development
-----------
Nesh development is easy! Just grab the source with git and start hacking around. Contributions, especially interesting languages and plugins, are always welcome!

### Building
After making changes it is important to run a build step to generate the Javascript which gets loaded when you import the `nesh` module, which makes it work across all Node languages.

```bash
cake build
```

### Running a local `nesh`
You can run the `nesh` command from your local checkout:

```bash
./bin/nesh.js
```

It is also possible to use `npm` to link your local checkout globally (note: this may require `sudo`):

```bash
npm link
```

Now you should be able to run `nesh` from anywhere and have it use your development version.

### Unit Tests
The unit test suite can be run via the following:

```bash
cake test
```

License
-------
Copyright (c) 2013 Daniel G. Taylor

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
