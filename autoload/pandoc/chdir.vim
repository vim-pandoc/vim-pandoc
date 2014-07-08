function! pandoc#chdir#Init()
    try
        lcd %:h
    catch /E499/
        return
    endtry
endfunction
