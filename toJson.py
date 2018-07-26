#!/usr/bin/env python
import re
from bs4 import BeautifulSoup as bs
import sys
import os
import fire

import json

def ciParse(tagSoup):
    return([line.strip() for line in tagSoup.text.split('\n') if line.strip() != ''])

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
        print('Usage: toJson.py [file path] [root tag]')

    with open(filePath) as file:
        raw = file.read()

    soup = bs(raw,'html.parser')
    rootTags = soup.findAll(rootTag)

    res = {}
    for rootTag in rootTags:
        tags = rootTag.findAll(recursive=False)
        ccode = tags[0].text
        d = {t.name : soupBranch(rootTag.find(t.name)) for t in tags}
        res.update({ccode:d})

    with open(outFile,'w') as file:
        json.dump(res,file)

if __name__ == '__main__':

    fire.Fire(cookXml)
