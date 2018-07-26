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
    text = re.sub(r'\[[^\[\]]+\]','',text)
    text = re.sub(r'#[A-Za-z ]*','',text)
    values = re.findall(r'\b[A-Z_]+\b',text)
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

    raw = re.sub(r'\s(?=[\s\w]*>)','_',raw)

    soup = bs(raw,'html.parser')
    rootTags = soup.findAll(rootTag)

    res = {}
    for rootTag in rootTags:
        tags = rootTag.findAll(recursive=False)
        ccode = tags[0].text
        d = {t.name : soupBranch(rootTag.find(t.name)) for t in tags}
        res.update({ccode:d})

    if outFile == '.stdout':
        sys.stdout.write(json.dumps(res))
    else:
        with open(outFile,'w') as file:
            json.dump(res,file)

if __name__ == '__main__':

    fire.Fire(cookXml)
