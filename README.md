CountryInfo
===========

This is the GitHub repository for the CountryInfo.txt and related utility programs.
CountryInfo.txt is a general purpose file intended to facilitate natural language
processing of news reports and political texts. It was originally developed to identify
states for the text filtering system used in the development of the Correlates of War
project dataset MID4, then extended to incorporate CIA World Factbook and WordNet
information for the development of TABARI dictionaries. File contains about 32,000 lines
with country names, synonyms and other alternative forms, major city and region names,
and national leaders. It covers about 240 countries and administrative units
(e.g. American Samoa, Christmas Island, Hong Kong, Greenland). It is internally documented
and almost but not quite XML.

Location on the web:  http://eventdata.parusanalytics.com/software.dir/dictionaries.html

Files:

CountryInfo.120116.txt: main file

format.rulers.org.pl:
This Perl program translates one or more lines from the Rulers.org web site into the
CountryInfo.txt format. rulers.org is almost but not quite consistent, so this was a
utility used in the original development of the file; it might be useful for updates.

dict.countrycodes.pl:
This Perl program combines the generic international code file CountryCodes.txt and
individual country files for the ICEWS countries, and produces a TABARI-compatible
file International.draft.actors.

toJson.py (by Peder Gotch Landsverk):
This is a fire-based utility that converts the file to JSON, so it is easier to load and manipulate.
This will eventually also include some sort of parsing of raw strings, so data is completely indexable.
(ex dat[country][leaders][presidents][0][name])
