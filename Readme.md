# vim-autorepl

**vim-autorepl** starts [REPLs (Read, Evaluate, Print Loop)](https://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop) quickly and easily in Vim and Neovim. It can be configured to start a REPL when you load a file of a particular type or only when you need it.

The plugin optionally integrates with [vim-slime](https://github.com/jpalardy/vim-slime), to create an easy-to-use setup for evaluating code within vim.

## Configuring

**vim-autorepl** is configured using a dictionary stored in `g:autorepl_commands`, where each key is a `&filetype` value recognized by Vim. The values of each key can either be a string or a dictionary. If a string, the command will automatically load and is assumed to be interactive (see below). If a dictionary, automation and interactivity can be set.

Here's an example:

~~~vim
let g:autorepl_commands = {
	\'haskell': '~/.ghcup/bin/ghci',
	\'javascript': {'command': '/usr/local/bin/node', 'auto': 0},
	\'janet: {'command': '/usr/local/bin/janet -e "(import spork/netrepl) (netrepl/server)"', 'interactive': 0},
	\}
~~~

The entry for Haskell starts `ghci` interactively and automatically when a Haskell file is opened. The entry for Javascript starts Node in REPL mode but will not do so automatically (see "Interface" for how to start). The entry for [Janet](https://janet-lang.org/) starts without interactivity and could be used with a plugin such as [Conjure](https://github.com/Olical/conjure) (you could also use this setup with something like Clojure and [vim-fireplace](https://github.com/tpope/vim-fireplace) to start `lein` or `boot`).

## Interface

If you are using the automatic start, there isn't anything to do. However, **vim-autorepl** provides a few functions to make working with REPLS easier.

### I Need to Start A REPL

If you are not using automatic start or you accidentally closed an automatic REPL, run `call autorepl#start_repl()` from within a buffer with a configured `&filetype` and the REPL will start.

### Other Things

The rest of the plugin interface is related to support for [vim-slime](https://github.com/jpalardy/vim-slime), which is discussed below.

## `vim-slime` Support (optional)

**vim-autorepl** will automatically connect [vim-slime](https://github.com/jpalardy/vim-slime) to REPLs it starts, if you configure vim-slime correctly.

To use **vim-autorepl** with vim-slime connectivity, add `let g:slime_target='neovim'` (for Neovim) or `g:slime_target='vimterminal'` (for Vim) to your vim start-up script.

### I've Closed My REPL!

Run `call autorepl#start_repl()` will create a new REPL (or open one if you aren't using automatic starting) and will automatically re-connect vim-slime

### A Buffer Isn't Connected to My REPL!

If you have a REPL open but some buffers were opened before and are not connected, in each buffer, run `call autorepl#attach_repl()` to connect vim-slime to a running REPL.
