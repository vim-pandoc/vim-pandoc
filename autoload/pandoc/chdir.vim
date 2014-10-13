" vim: set fdm=marker et ts=4 sw=4 sts=4:

function! pandoc#chdir#Init()
    try
        lcd %:h
    catch /E499/
        return
    catch /E344/
        return
    catch /E472/ "might occur when using tpope's fugitive
        return
    endtry
endfunction
