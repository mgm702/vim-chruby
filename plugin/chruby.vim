" chruby.vim - Switch Ruby versions using Chruby from inside Vim
" Maintainer: Matt Michnal <mattm3646@gmail.com>
" Version: 1.0
" Based on rvm.vim by Tim Pope

if exists('g:loaded_chruby') || v:version < 700 || &cp
  finish
endif
let g:loaded_chruby = 1

" Setup default paths where Rubies might be installed
if !exists('g:chruby_rubies')
  let g:chruby_rubies = []

  " Default chruby paths
  if isdirectory('/opt/rubies')
    let g:chruby_rubies += glob('/opt/rubies/*', 0, 1)
  endif

  if isdirectory(expand('~/.rubies'))
    let g:chruby_rubies += glob(expand('~/.rubies/*'), 0, 1)
  endif

  " Support for RVM, rbenv, rbfu paths
  if isdirectory(expand('~/.rvm/rubies'))
    let g:chruby_rubies += glob(expand('~/.rvm/rubies/*'), 0, 1)
  endif

  if isdirectory(expand('~/.rbenv/versions'))
    let g:chruby_rubies += glob(expand('~/.rbenv/versions/*'), 0, 1)
  endif

  if isdirectory(expand('~/.rbfu/rubies'))
    let g:chruby_rubies += glob(expand('~/.rbfu/rubies/*'), 0, 1)
  endif
endif

" Utility function to escape shell arguments
function! s:shellesc(arg) abort
  if a:arg =~ '^[A-Za-z0-9_/.-]\+$'
    return a:arg
  else
    return shellescape(a:arg)
  endif
endfunction

" Find Ruby version from .ruby-version file
function! chruby#detect_ruby_version()
  let dir = expand('%:p:h')

  while dir != '/' && dir != ''
    if filereadable(dir . '/.ruby-version')
      let version = get(readfile(dir . '/.ruby-version'), 0, '')
      return trim(version)
    endif
    let dir = fnamemodify(dir, ':h')
  endwhile

  return ''
endfunction

" Get full Ruby version path from a partial name
function! s:find_ruby(version)
  if a:version ==# 'system'
    return 'system'
  endif

  " Match exact path if provided
  if isdirectory(a:version)
    return a:version
  endif

  " Try to match by name in our rubies list
  for ruby in g:chruby_rubies
    let ruby_name = fnamemodify(ruby, ':t')
    if ruby_name =~# '^' . a:version
      return ruby
    endif
  endfor

  return ''
endfunction

" Set environment variables for a Ruby version
function! s:set_ruby_env(ruby_path)
  let path = split($PATH, ':')

  " Remove previous Ruby paths
  if exists('$RUBY_ROOT')
    call filter(path, 'v:val !~# "^" . $RUBY_ROOT')
  endif

  if a:ruby_path ==# 'system'
    let $RUBY_ROOT = ''
    let $RUBY_ENGINE = ''
    let $RUBY_VERSION = ''
    let $GEM_HOME = ''
    let $GEM_PATH = ''
    let $PATH = join(path, ':')
    return 'system'
  endif

  " Set new Ruby environment variables
  let $RUBY_ROOT = a:ruby_path

  " Detect Ruby engine and version
  let ruby_name = fnamemodify(a:ruby_path, ':t')

  if ruby_name =~# '^jruby'
    let $RUBY_ENGINE = 'jruby'
    let $RUBY_VERSION = matchstr(ruby_name, 'jruby-\zs\d\+\.\d\+\.\d\+')
  elseif ruby_name =~# '^rbx'
    let $RUBY_ENGINE = 'rbx'
    let $RUBY_VERSION = matchstr(ruby_name, 'rbx-\zs\d\+\.\d\+\.\d\+')
  elseif ruby_name =~# '^maglev'
    let $RUBY_ENGINE = 'maglev'
    let $RUBY_VERSION = matchstr(ruby_name, 'maglev-\zs\d\+\.\d\+\.\d\+')
  else
    let $RUBY_ENGINE = 'ruby'
    let $RUBY_VERSION = matchstr(ruby_name, 'ruby-\zs\d\+\.\d\+\.\d\+')
  endif

  " Set gem paths
  let $GEM_HOME = expand('~/.gem/' . $RUBY_ENGINE . '/' . $RUBY_VERSION)

  " Determine gem version for path (e.g., 2.7 from 2.7.1)
  let gem_version = matchstr($RUBY_VERSION, '\d\+\.\d\+')
  let $GEM_PATH = $GEM_HOME . ':' . a:ruby_path . '/lib/ruby/gems/' . gem_version . '.0'

  " Update PATH
  let new_path = [$GEM_HOME . '/bin', a:ruby_path . '/bin'] + path
  let $PATH = join(new_path, ':')

  " Store current Ruby path for statusline
  let b:chruby_current = ruby_name

  " Clear command hash to ensure new Ruby binaries are found
  call system('hash -r')

  return ruby_name
endfunction

" Main chruby command
function! s:Chruby(bang,...) abort
  if a:0 == 0
    " If no arguments, just list available Rubies
    let current = exists('$RUBY_ROOT') ? fnamemodify($RUBY_ROOT, ':t') : 'system'

    let output = ["Available Rubies:"]
    for ruby in g:chruby_rubies
      let ruby_name = fnamemodify(ruby, ':t')
      call add(output, (ruby_name ==# current ? ' * ' : '   ') . ruby_name)
    endfor

    call add(output, current ==# 'system' ? ' * system' : '   system')

    return 'echo "' . escape(join(output, "\n"), '"') . '"'
  elseif a:0 >= 1 && a:1 ==# 'use'
    " :Chruby use [version]
    if a:0 == 1
      " Use .ruby-version
      let version = chruby#detect_ruby_version()
      if empty(version)
        return 'echoerr "No .ruby-version file found"'
      endif
    else
      let version = a:2
    endif

    let ruby_path = s:find_ruby(version)
    if empty(ruby_path)
      return 'echoerr "Ruby version not found: ' . version . '"'
    endif

    let ruby_name = s:set_ruby_env(ruby_path)
    return 'echomsg "Now using ' . ruby_name . '"'
  else
    " :Chruby [version]
    let version = a:1
    let ruby_path = s:find_ruby(version)

    if empty(ruby_path)
      return 'echoerr "Ruby version not found: ' . version . '"'
    endif

    call s:set_ruby_env(ruby_path)
    return ''
  endif
endfunction

" Command completion for :Chruby
function! s:Complete(A,L,P)
  let list = []

  " Add ruby names
  for ruby in g:chruby_rubies
    let name = fnamemodify(ruby, ':t')
    if a:A ==# '' || name =~# '^' . a:A
      call add(list, name)
    endif
  endfor

  " Add 'system' and 'use'
  if a:A ==# '' || 'system' =~# '^' . a:A
    call add(list, 'system')
  endif

  if a:A ==# '' || 'use' =~# '^' . a:A
    call add(list, 'use')
  endif

  return join(list, "\n")
endfunction

" Statusline function
function! chruby#statusline()
  if exists('b:chruby_current')
    return '[' . b:chruby_current . ']'
  elseif exists('$RUBY_VERSION')
    return '[' . ($RUBY_ENGINE !=# '' ? $RUBY_ENGINE . '-' : '') . $RUBY_VERSION . ']'
  else
    return '[system]'
  endif
endfunction

" Define command
command! -bar -nargs=* -complete=custom,s:Complete Chruby :execute s:Chruby(<bang>0,<f-args>)
