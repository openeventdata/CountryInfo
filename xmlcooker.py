#!/usr/bin/env python
"""
Makes a json-file from the CountryInfo "xml"-formatted file
"""

import re
from bs4 import BeautifulSoup as bs
import sys
import os
import fire
import numpy as np

import json

def quickRe(*args):
    m = re.search(*args)
    if m is not None:
        o = m[0]
    else:
        o = ''
    return(o)

def formatName(name):
    if '{' in name:
        names = re.findall('(?<=\{)[^\}]+(?=\})',name)
        name = '|'.join(names)
    else:
        pass
    name = re.sub(r'[\'\´\`]','',name)
    name = re.sub(r'[^A-Za-z \|]','_',name)
    name = re.sub('__+','_',name)
    name = name.lower()
    return(name)

def ciParseLine(line):
    name = quickRe(r'^[^[\n]+',line).strip()
    name = formatName(name)

    description = quickRe(r'(?<=\[DESCR )[^\]]+(?=\])',line).strip()

    years = re.search(r'(?<=\[)[A-Za-z_ ]*(?P<start>[0-9]{8}) - (?P<end>[0-9]{8})(?=\])',line)
    if years:
        startYr = years['start']
        endYr = years['end']
    else:
        year = re.search(r'(?<=\[)[A-Za-z_ ]*(<|>)(?P<start>[0-9]{8})(?=\])',line)
        if year:
            startYr = year['start']
            endYr = '20161201'
        else:
            print(line)
            startYr = ''
            endYr = ''

    if name == '' and description == '':
        entry = None
    else:
        entry = {'name':name,'description':description,'startYr':startYr,'endYr':endYr}

    return(entry)

def ciParse(tagSoup):
    # Where the magic happens
    text = tagSoup.text

    # Removes attribute tags
    #text = re.sub(r'\[[^\[\]]+\]','',text)

    # Parses EOL comment sections (description) into attribute tags...
    text = re.sub(r'(?<!^)#([^#\n]*)(?=\n)',r'[DESCR \1]',text)

    # Removes all comments (keep after parsing all EOL-comments?)
    # text = re.sub(r'#.*','',text)

    text = text.split('\n')

    entries = [ciParseLine(l) for l in text]
    entries = [e for e in entries if e != None]

#    if len(entries) == 1:
#        entries = entries[0]
#    else:
#        pass

#    values = re.findall(r'\b[A-Z\'\`\-_]+\b',text)
#    values = [v.lower().replace('_',' ').strip() for v in values]
    return(entries)
    # 1 Detect format
    # 2 reparse into list of dictionaries

#####################################

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

#####################################

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

        res.update({ccode:d})

    if outFile == '.stdout':
        sys.stdout.write(json.dumps(res))
    else:
        with open(outFile,'w') as file:
            json.dump(res,file)

#####################################

if __name__ == '__main__':

    fire.Fire(cookXml)
