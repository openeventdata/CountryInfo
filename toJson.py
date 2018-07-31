#!/usr/bin/env python
import re
from bs4 import BeautifulSoup as bs
import sys
import os
import fire

import json

def ciParse(tagSoup):
    text = tagSoup.text
    text = text.replace('.','')
    # Removes attribute tags (must go...)
    text = re.sub(r'\[[^\[\]]+\]','',text)
    # Parses EOL comment sections into attribute tags...
#    text = re.sub(r'(?<!^#)(?<=#)([^#]*)(?=\n)',r'[ATTR \1]',text)
    # Removes all comments (keep after parsing all EOL-comments?)
    text = re.sub(r'#.*','',text)
    # Extracts all names (here i'll make a list of dicts instead of the list of values)
    values = re.findall(r'\b[A-Z\'\`\-_]+\b',text)
    values = [v.lower().replace('_',' ').strip() for v in values]
    return(values)
    # 1 Detect format
    # 2 reparse into list of dictionaries

def soupLeaf(tagSoup):
    if len(tagSoup) == 1:
        val = True
    else:
        val = False
    return(val)

def soupBranch(tagSoup):

    if soupLeaf(tagSoup):
        tagCont = ciParse(tagSoup)
    else:
        tags = tagSoup.findAll()
        tagCont = {tag.name : soupBranch(tag) for tag in tags}

    return(tagCont)

def cookXml(filePath,rootTag,outFile):

    if not os.path.isfile(filePath) and len(sys.argv) == 3:
        sys.stderr.write('Usage: toJson.py [file path] [root tag]')
        sys.stderr.write('if file path is .stdout, the program writes to stdout')

    with open(filePath) as file:
        raw = file.read()

    # Fix spaces in XML tags
    raw = re.sub(r'\s(?=[\s\w]*>)','_',raw)

    # Remove comments
    lines = [l for l in raw.split('\n') if not l.startswith('#')]
    raw = '\n'.join(lines)

    soup = bs(raw,'html.parser')
    rootTags = soup.findAll(rootTag,recursive=False)

    res = {}
    for rootTag in rootTags:
        tags = rootTag.findAll(recursive=False)
        ccode = tags[0].text

        d = {}
        for t in tags:
            if t.name != 'doc' and t.name != 'comment':
                d.update({t.name : soupBranch(rootTag.find(t.name))})
            else:
                pass

#        d = {t.name : soupBranch(rootTag.find(t.name)) for t in tags}
        res.update({ccode:d})

    if outFile == '.stdout':
        sys.stdout.write(json.dumps(res))
    else:
        with open(outFile,'w') as file:
            json.dump(res,file)

if __name__ == '__main__':

    fire.Fire(cookXml)
