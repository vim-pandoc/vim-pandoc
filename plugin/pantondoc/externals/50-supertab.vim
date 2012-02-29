if exists("g:SuperTabDefaultCompletionType")
	call SuperTabSetDefaultCompletionType("context")

	if exists('g:SuperTabCompletionContexts')
		let b:SuperTabCompletionContexts =
		\ ['pantondoc_completion#Pantondoc_Complete'] + g:SuperTabCompletionContexts
	endif

	" disable supertab completions after bullets and numbered list
	" items (since one commonly types something like `+<tab>` to
	" create a list.)
	let b:SuperTabNoCompleteAfter = ['\s', '^\s*\(-\|\*\|+\|>\|:\)', '^\s*(\=\d\+\(\.\=\|)\=\)']
endif

