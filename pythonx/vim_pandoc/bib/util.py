def make_title_ascii(title):
    import unicodedata
    if type(title) != str :
        title = unicodedata.normalize('NFKD', title).encode('ascii', 'ignore')
    else :
        title = str(title)
    return title
