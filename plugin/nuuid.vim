if exists('g:nuuid_loaded') && g:nuuid_loaded
	finish
endif
let g:nuuid_loaded = 1

if !exists('g:nuuid_case')
	let g:nuuid_case = "lower"
endif

" Use python to generate a new UUID
function! NuuidNewUuid()
  if executable('uuidgen')
    let l:new_uuid = system('uuidgen')[:-2]
    return g:nuuid_case == "lower" ? tolower(l:new_uuid) : toupper(l:new_uuid)
  elseif has('python')
python << endpy
import vim
from uuid import uuid4
vim.command("let l:new_uuid = '%s'"% str(uuid4()))
endpy
    return g:nuuid_case == "lower" ? tolower(l:new_uuid) : toupper(l:new_uuid)
  else
    let l:seed = srand()
    " Generate 4 x 4 bytes of random data.
    let l:one = rand(l:seed)
    let l:two = rand(l:seed)
    let l:three = rand(l:seed)
    let l:four = rand(l:seed)
    let l:fmt = "%08X-%04X-%04X-%04X-%04X%08X"
    if g:nuuid_case == "lower"
      let l:fmt = "%08x-%04x-%04x-%04x-%04x%08x"
    endif
    return printf(l:fmt,
    \ l:one,
    \ and(l:two, 0xffff0000) >> 0x10,
    \ and(l:two, 0x0000ffff),
    \ and(l:three, 0xffff0000) >> 0x10,
    \ and(l:three, 0x0000ffff),
    \ l:four)
  endif
endfunction


function! s:NuuidInsertAbbrev()
	inoreabbrev <expr> nuuid NuuidNewUuid()
	inoreabbrev <expr> nguid NuuidNewUuid()
	let g:nuuid_iabbrev = 1
endfunction

function! s:NuuidInsertUnabbrev()
	silent! iunabbrev nuuid
	silent! iunabbrev nguid
	let g:nuuid_iabbrev = 0
endfunction

function! s:NuuidToggleInsertAbbrev()
	if exists('g:nuuid_iabbrev') && g:nuuid_iabbrev
		call s:NuuidInsertUnabbrev()
	else
		call s:NuuidInsertAbbrev()
	endif
endfunction

" set the initial abbreviation state
if !exists('g:nuuid_iabbrev') || g:nuuid_iabbrev
	call s:NuuidInsertAbbrev()
else
	call s:NuuidInsertUnabbrev()
endif

" commands
command! -nargs=0 NuuidToggleAbbrev call s:NuuidToggleInsertAbbrev()
command! -range -nargs=0 NuuidAll <line1>,<line2>substitute/\v<n[ug]uid>/\=NuuidNewUuid()/geI
command! -range -nargs=0 NuuidReplaceAll <line1>,<line2>substitute/\v<([0-9a-f]{8}\-?([0-9a-f]{4}\-?){3}[0-9a-f]{12}|n[gu]uid)>/\=NuuidNewUuid()/geI

" Mappings
nnoremap <Plug>Nuuid i<C-R>=NuuidNewUuid()<CR><Esc>
inoremap <Plug>Nuuid <C-R>=NuuidNewUuid()<CR>
vnoremap <Plug>Nuuid c<C-R>=NuuidNewUuid()<CR><Esc>

if !exists("g:nuuid_no_mappings") || !g:nuuid_no_mappings
	nmap <Leader>u <Plug>Nuuid
	vmap <Leader>u <Plug>Nuuid
endif
