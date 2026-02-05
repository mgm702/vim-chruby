# chruby.vim

Switch Ruby versions from inside Vim using [chruby](https://github.com/postmodern/chruby).

Rather than requiring Vim to be launched from a chruby-enabled shell, chruby.vim allows dynamic version changes mid-session.

## Installation

**vim-plug:**
```vim
call plug#begin()
Plug 'mgm702/vim-chruby'
call plug#end()
```

**Vundle:**
```vim
Plugin 'mgm702/vim-chruby'
```

**Pathogen:**
```sh
cd ~/.vim/bundle
git clone https://github.com/mgm702/vim-chruby.git
```

Documentation is accessible via `:help chruby.txt` in Vim.

## Usage

List available Ruby versions:
```
:Chruby
```

Switch to a specific Ruby version:
```
:Chruby 3.2.0
```

Switch and echo the version chosen:
```
:Chruby use 3.2.0
```

Auto-detect version from `.ruby-version` file:
```
:Chruby use
```

Automatic switching when changing buffers:
```vim
autocmd BufEnter * Chruby use
```

## Statusline

Add `%{chruby#statusline()}` to your `'statusline'` to display the active Ruby version:

```vim
set statusline+=%{chruby#statusline()}
```

## Configuration

The plugin automatically detects Ruby installations from common locations:

- `~/.rubies/*`
- `/opt/rubies/*`
- `~/.rvm/rubies/*`
- `~/.rbenv/versions/*`
- `~/.rbfu/rubies/*`

You can add additional paths:

```vim
let g:chruby_rubies += ['/path/to/ruby']
```

## Contributing

Contributions are welcome via pull requests. Please use clear, understandable commit messages.

## License

Licensed under the same terms as Vim itself. See `:help license` for details.
