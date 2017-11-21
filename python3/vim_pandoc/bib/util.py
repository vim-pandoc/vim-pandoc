def flatten(l):
    if type(l) == list:
        return " ".join(l)
    else:
        return l

def make_title_ascii(title):
    import unicodedata
    if type(title) != str :
        title = unicodedata.normalize('NFKD', title).encode('ascii', 'ignore')
    else :
        title = str(title)
    return title

def dict_to_info(data):
    def sort_keys(key):
        if key[0] == "id":
            return 1
        elif key[0] == "author":
            return 2
        elif key[0] == "title":
            return 3
        elif key[0] == "issued":
            return 4
        elif key[0] == "abstract":
            return 5
        else:
            return -1

    try:
        from citeproc import CSLItem
    except:
        from .citeproc import CSLItem
    item = CSLItem(data)
    lines = []
    for i in data:
        if i in ("id", "author", "title", "issued", "abstract"):
            if i == "author":
                formatted_names = []
                for name in item.as_array(i):
                    formatted_name = ", ".join([token for token in  name if token != ''])
                    formatted_names.append(formatted_name)
                lines.append((i, " & ".join(formatted_names)))
            else:
                lines.append((i, " ".join(map(flatten, item.as_array(i))).strip()))

    lines.sort(key=sort_keys)

    return "\n".join([l[0] + ":" + "\t" * 2 +  l[1] for l in lines])
