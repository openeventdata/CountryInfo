##  translate.countryinfo.pl
##
##  This Perl program translates the CountryInfo.YYMMDD.txt file in a TABARI-compatible
##  file CountryInfo.YYMMDD.actors with some duplicate detection.
##   
##  TO RUN PROGRAM:
##
##  perl translate.countrycodes.pl <filename>
##
##  INPUT FILE:
##  CountryInfo.yymmdd.txt : A CountryCodes file  (.txt suffix is required for proper output file
##                           name construction
##
##  OUTPUT FILES:
##
##  <filename>.actors: A TABARI-formatted dictionary 
##
##  <filename>.dups.txt: List of duplicates detected and not written to output, also lists of the
##                       synonym sets combined and some of the warnings
##
##  DUPLICATE DETECTION
##
##  1. Duplicates in the blocks processed with sub getblock are skipped
##
##  2. Duplicates in <Leaders> and <Government> are combined, including combining of synonym sets
##
##  PROGRAMMING NOTES:
##  1. There is no consistency checking of the dates of office, which could be inconsistent across
##     Rulers.org (<Leaders>) and the CIA World Leaders (<Government>) sources. Note that TABARI
##     simply applies the first date restriction that is valid, so this won't affect the functioning
##     of TABARI. Consistent dates would, nonetheless, be a good thing, but this additional code
##     is left as an exercise. 
##
##  2. There is some checking for consistency in the formatting of the date restrictions: detected
##     problems in the posted files have been corrected.
## 
##  3. A prior (<) code in <Government> currently sets a finite term beginning at 20030101
##
## 	4. B: year plus 18 is the start of elite status 
##
##  5. An open [~ELI] code is generated for <Leaders> but not <Government>
##
##  6. There is an "if ($kb > 10) {exit;}" check for processing a small number of countries around 
##     line 320. File with debugging code is CountryInfo.120106.debug.txt
##
##  SYSTEM REQUIREMENTS
##  This program has been successfully run under Mac OS 10.5; it is standard perl
##  so it should also run in Unix or Windows. 
##
##  PROVENANCE:
##  Programmer: Philip A. Schrodt
##              Dept of Political Science
##              Pennysylvania State University
##              227 Pond Laboratory
##	            University Park, PA, 16802 U.S.A.
##	            http://web.ku.edu/keds
##
##	Copyright (c) 2012  Philip A. Schrodt.  All rights reserved.
##
## 	Redistribution and use in source and binary forms, with or without modification,
## 	are permitted under the terms of the GNU General Public License:
## 	http://www.opensource.org/licenses/gpl-license.html
##
##	Report bugs to: schrodt@psu.edu
##
##	For plausible indenting of this source code, set the tab size in your editor to "2"
##
##  REVISION HISTORY:
##  22-Jun-09:  Initial version
##  26-Sep-11:  Revised from dict.countrycodes.txt to remove ICEWS-specific code and 
##              update to the new tags
##  10-Jan-12:  Major revisions in the processing of the <Leaders> and <Government>
##              blocks.
##
##  ----------------------------------------------------------------------------------

#!/usr/local/bin/perl
# ======== globals =========== 
#
$tags = "<!--.Country.CountryCode.CountryName.Capital.MajorCities.Leaders.Nationality.Regions.Government.GeogFeatures.Comment.Doc.";   # major tags
$skiptags = "COW-Alpha.COW-Numeric.FIPS-10.ISO3166-alpha2.ISO3166-alpha3.ISO3166-numeric.IMF.";   # recognized tags to skip

# ======== subroutines =========== #

sub TABARI_format { # converts $1 to TABARI format, returns in $fmtd
	$fmtd = $1;
	$fmtd =~ s/\s*$//;  # trim end blanks
	$fmtd =~ s/^\s*//;  # trim initial blanks
	$fmtd .= ' ';
	$fmtd =~ tr/ /_/;
	$fmtd =~ s/__/_/g;  # eliminate duplicate _
	$fmtd = uc $fmtd;
}

sub writeline { # write the line with the country code
	TABARI_format;
	$ka = 0;
	while ($ka < @names) {  # check if we've already seen this
		if ($names[$ka] eq $fmtd) { 
			print FDUP "Duplicate $fmtd in $ccode\n";
			$founddups = 1;
			return;
		}
		++$ka;
	}
	push @names, $fmtd; # update names
	$out = "$fmtd  [$ccode]";
	print FOUT "$out\n";
} # writeline

sub checkline { # check whether the phrase is in ctyphrase; if not write it and store it in dict array
	TABARI_format;
	$gotdup = 0;
	foreach $phrase (@ctyphrase) {
		if ($fmtd eq $phrase) {
			print "CCX Dup: $fmtd  $phrase  $ccode\n";
			print FDUP "CCX Dup: $fmtd  $phrase  $ccode\n";
			$gotdup = 1;
			last;
		}
	}
	if ($gotdup == 0) {
		$out = "$fmtd  [$ccode] ; CountryCodes.xml";
		print FOUT "$out\n";
	}
} # checkline

sub getblock { # write the line with the country code
	$endtag = "<\/$_[0]";
	while ($line = <FIN>) {
		++$nline;
		if  ($line =~ m/^\s*#/) { next;}
		if  (index($line,$endtag) >= 0) { last;}
		if ($line =~ m/<\Country>/) {
			print "Error: Run-away $_[0] block in $ccode\n";
			last;
		}
		if  ($line =~ m/(.+)/) {  # put entire line into $1
			writeline;
		}
	}
} # getblock

sub skipblock { # skip until terminating tag
	$endtag = "<\/$_[0]";
	while ($line = <FIN>) {
		++$nline;
		if  (index($line,$endtag) >= 0) { last;}
	}
} # skipblock
	
sub combinesyns { 	# combine synonym sets in $leaders[$nlead] and $name, adding any new entries to 
					# the existing set
	$orig = $leaders[$nlead];  # existing entry that was matched
	if ($orig !~ /{/) {  $orig = "{$orig}"; } 	# currently not a synonym set, so add {...}
	print FDUP "Combined in $ccode:\n\t$orig\n\t$name\n";
	while ($name =~ /{([^}]+)}/g) { # go through terms in new synset
		$curterm = $1;
		$newterm = 1;
		while ($orig =~ /{([^}]+)}/g) { # check whether we've already got this
			if ($curterm eq $1) {
				$newterm = 0;
				last;
			}
		}
		if ($newterm) {$orig .= " {$curterm}";}
	}
	$leaders[$nlead] = $orig;		
} # combinesyns

sub checkonename {	# checks whether $thename is already recorded; sets $newname, $nlead
					# called from checkname
#\	print FOUT "checking $ccode : $thename\n";
	$ka = 0;
	while ($ka < @leaders) {  # check if we've already seen this
		if ($leaders[$ka] =~ /{/) {  # check inside synonym set
			$synset = $leaders[$ka];  # required to get around a rare bug: see CountryInfo.120106.debug.txt
			while ($synset =~ /{([^}]+)}/g) {
#				print FOUT ">> $1\n";
				if ($1 eq $thename) { 
					$newname = 0;
#					print FOUT "Match on $ccode : $1\n";
					last;
				}
			}
		}
		elsif ($leaders[$ka] eq $thename) { $newname = 0;}  # check single name
		if (!$newname) {
			$nlead = $ka;					
			return;
		}
		++$ka;
#		print FOUT "$ka ";
	}
} # checkonename
	
sub checkname { # extracts name or synonyms, checks whether already recorded and set up new entry if not,
				# returns assorted variables. Used in <Leaders> and <Government>
	if  ($line =~ m/\s+([^\[]+)/) {  # get a name: note that this allows any character except 
		$newname = 1;
		$name = $1;
		$name =~ s/\s*$//;  # trim end blanks
		$name =~ s/([A-Z])-([A-Z])/$1\_$2/g;  # replace embedded -

		if ($name =~ /{/) {  # check inside synonym set
			while ($name =~ /{([^}]+)}/g) { 
				$thename = $1;
				checkonename;
				if (!$newname) {last;}
			}
		}
		else {
			$thename = $name;
			checkonename;
		}

		if ($newname) {    # create a new entry
#			print FOUT "Adding $ccode : $name\n";
			push @leaders, $name;
			push @terminfo, "";
			$nlead = @leaders - 1;
		}
		elsif ($name =~ /{/) { combinesyns; }
	}
} # checkname

sub checkBD {  # process [B: and [D: fields
	if  ($line =~ m/\[D:/) {  # death field
		if ($line =~ m/\[D:(\d\d\d\d\d\d\d\d)/) {
			$terminfo[$nlead] .= " D:".$1;
		}
		else {   print "Incorrectly specified D: field in $line";}
	}
	if  ($line =~ m/\[B:/) {  # birth field
		if ($line =~ m/\[B:(\d\d\d\d\d\d\d\d)/) {
			$terminfo[$nlead] .= " B:".$1;
		}
		else {   print "Incorrectly specified B: field in $line";}
	}
} # checkBD

# ======== main program =========== #

if (length($ARGV[0]) < 4) {
  print "CountryCodes file name is required to run the program\n";
  exit;
}
else { 
	$inputfile = $ARGV[0]; 
	if ($inputfile !~ /txt/) {
		print "Input file name must end in .txt for proper output file name construction\nExiting without processing\n";
		exit;
	}
}

open(FIN,$inputfile)  or die "Can\'t open input file $inputfile; error $!";
print "\n ====== Processing $inputfile ======\n";
$outputfile = ">$inputfile";
$outputfile =~ s/txt/actors/;
open(FOUT,$outputfile) or die "Can\'t open output file $outputfile; error $!";

$dupfile = ">$inputfile";
$dupfile =~ s/txt/dups.txt/;
open(FDUP,$dupfile) or die "Can\'t open duplicates file $dupfile ; error $!";
$founddups = 0;

print FOUT "# TABARI-formatted .actor file produced by translate.countryinfo.pl from $inputfile\n";
$datestr = localtime();
print FOUT "# Generated at: $datestr\n";

$kb = 0;
$nline = 0;
$writeleaders = 0; # flag for whether leaders info needs to be written

while ($line = <FIN>) {
	++$nline;
	
	if ($line =~ m/^\s*#/) { next;} # skip comment
	
# check for unrecognized tags outside of <Leaders> block
	if (($line =~ m/\s*<([\w\d-]+)/) || ($line =~ m/\s*<\/([(\w\d-]+)/)) {
		$check = $1.".";
		if (index($skiptags,$check) >= 0) { next;}
		if (index($tags,$check) < 0) {
			print "Unrecognized tag (line #$nline): $line";
			print FDUP "Unrecognized tag (line #$nline): $line";
			next;
		}
	}
	
	if  ($line =~ m/<!--/) {  # skip XML comment block 
		while ($line = <FIN>) {
			++$nline;
			if  ($line =~ m/-->/) { last;}
		}
	}
	
	if  ($line =~ m/<Comment>/) { skipblock("Comment") } # skip comment block 
	
	if  ($line =~ m/<Doc>(.+)<\/Doc>/) { 
		print FOUT "# $1\n";
		next;  # skip further processing of the line since it could contain field tags
	}

	if ($line =~ m/<Country>/) { 
		if ($writeleaders) {print "Error: Unwritten leaders info in $ccode\n" }
		$ccode = '---';  # this should get re-set to a correct code, otherwise we've got an ill-structured file;
		@names = ();
	}

	if ($line =~ m/<CountryCode>/) {
		if ( ($line =~ m/>(\w\w\w)</) ||
		     ($line =~ m/>(\w\w\w\w\w\w)</)) { 
		  $ccode = $1;
		  print FOUT "\n";
		  ++$kb;
		  if ($kb > 300) {exit;}  # debug: limit number of countries processed
		}
		elsif  ($line =~ m/>---</) {  # skip block if null coded  : we don't really hit this, right?
			while ($line = <FIN>) {
				++$nline;
				if  ($line =~ m/<\/Country>/) { last;}
			}
		}
		else {print "Missing country code, line $nline\n";}
	}

	if ($line =~ m/<CountryName>/) {
		if  ($line =~ m/>([^<]+)</) { writeline; }
		else {print "Missing country name, line $nline\n";}
	}
		
	if ($line =~ m/<Nationality>/) { getblock("Nationality");}

	if ($line =~ m/<Capital>/) { getblock("Capital");}

	if ($line =~ m/<MajorCities>/) { getblock("MajorCities");}

	if ($line =~ m/<Regions>/) { getblock("Regions");}
		
	if  ($line =~ m/<GeogFeatures>/) {  getblock("GeogFeatures") }
				
	if ($line =~ m/<Leaders>/) {
	# @terminfo contains a series of fields which are used to construct date restrictions
	#      B: birth date. This date + 18 years signals the beginning of ELI status
	#      D: death date. End ELI status
	#      T: term of office with beginning and ending
	#      C: currently in office (>)
	#      L: Indicates entry came from <Leaders>, so generates an ELI code
	#    Note that the program doesn't handle elite status between terms of office, or any sort
	#    of consistency checking on the dates
	#
		$nlead = 0;
		$writeleaders = 1; # flag for whether leaders info needs to be written
		@leaders = ();
		@terminfo = ();
		while ($line = <FIN>) {
			++$nline;
			if ($line =~ m/<\/Country>/) {
				print "Run-away <Leaders> block in $ccode\n";
				last;
			}
			if  ($line =~ m/<\/Leaders/) { 
				if (@leaders == 0) {
					print "Warning: empty <Leaders> block in $ccode\n"; 
					print FDUP "Warning: empty <Leaders> block in $ccode\n"; 
				}
				last;
			}
			if  ($line =~ m/^\s*#/) {next;}
			if  ($line =~ m/<\w+/)  {next;}  # opening office tag; note that we aren't doing anything with the identities now; everything is just "GOV" and "ELI"
			if  ($line =~ m/<\/\w+/) { next;}  # closing tag
	
			print "Warning: Prior block in <Leaders> in $ccode : $line" if  ($line =~ m/<\d\d\d\d\d\d\d\d/);  # shouldn't be any of these 
							
			checkname;
			
			checkBD;
			
			if  (($line !~ m/\[\d\d\d\d\d\d\d\d - \d\d\d\d\d\d\d\d]/) && 
			       ($line !~ m/\[>\d\d\d\d\d\d\d\d]/)) { 
					print "<Leaders> term-of-office incorrectly (or never) specified in $ccode : $line";
					$terminfo[$nlead] .= " ERR:";     # flag error so name isn't printed
			}
			else {$terminfo[$nlead] .= " L:";}     # flag showing source was <Leaders> block
				
			while ($line =~ m/\[(\d\d\d\d\d\d\d\d) - (\d\d\d\d\d\d\d\d)]/g) {  # term of office specified
				$terminfo[$nlead] .= " T:".$ccode."GOV ".$1."-".$2;
			}
			if  ($line =~ m/\[>(\d\d\d\d\d\d\d\d)]/) {  # currently in office
				$terminfo[$nlead] .= " C:".$ccode."GOV ".$1;     # set current office field
			}
		} # while $line

	} # Leaders
		
	if ($line =~ m/<Government>/) {
	# Notes on the <Government> block
	# This is similar to the <Leaders> block except for the presence of distinct codes, the < date
	# delimiter and the absence of B: and D: since this information isn't in the World 
	# Leaders files. 
	#
		if (!$writeleaders) { # usually won't hit this, but it is permissible
			print "Warning: No <Leaders> block in $ccode : $line";
			$nlead = 0;
			@leaders = ();
			@terminfo = ();
		}
		$startnline = $nline;
		$writeleaders = 1; # flag for whether leaders info needs to be written
		while ($line = <FIN>) {
			++$nline;
			if ($line =~ m/<\/Country>/) {
				print "Error: Run-away <Government> block in $ccode\n";
				last;
			}
			if  ($line =~ m/<\/Government/) { 
				if ($nline == $startnline+1) {
					print "Warning: empty <Government> block in $ccode\n";
					print FDUP "Warning: empty <Government> block in $ccode\n";
				}
				last;
			}
			if  ($line =~ m/^\s*#/) {next;}
	
			checkname;

			checkBD;
			
			if  (($line !~ m/\[\w+ \d\d\d\d\d\d\d\d - \d\d\d\d\d\d\d\d]/) && 
			   ($line !~ m/\[\w+ >\d\d\d\d\d\d\d\d]/) &&
			   ($line !~ m/\[\w+ <\d\d\d\d\d\d\d\d]/))  { 
				print "Error: <Government> term-of-office incorrectly (or never) specified in $ccode : $line";
				$terminfo[$nlead] .= " ERR:";     # flag error so name isn't printed
			}
			
			while  ($line =~ m/\[(\w+) (\d\d\d\d\d\d\d\d) - (\d\d\d\d\d\d\d\d)]/) {  # term of office specified
				$terminfo[$nlead] .= " T:".$1." ".$2."-".$3;
				$line =~ s/\[\w+ \d\d\d\d\d\d\d\d - \d\d\d\d\d\d\d\d]//;  # could also be done with a m//g
			}
			if  ($line =~ m/\[(\w+) >(\d\d\d\d\d\d\d\d)]/) {  # in office at end of reports
				$terminfo[$nlead] .= " C:".$1." ".$2;     # set prior office field
			}
			if  ($line =~ m/\[(\w+) <(\d\d\d\d\d\d\d\d)]/) {  # in office at beginning of reports
				$terminfo[$nlead] .= " P:".$1." ".$2;     # set prior office field
			}
		} # while $line

	} # Government
	
	# write the <Leaders, and <Government> records
	if (($line =~ m/<\/Country>/) && ($writeleaders)) { 
		$writeleaders = 0;
		for ($ka=0; $ka < @leaders; ++$ka) {
			if ($terminfo[$ka] =~ / ERR:/) {next;}
#			print $ka,":  ",$leaders[$ka], "  ", $terminfo[$ka],"\n"; # debug
#			print FOUT $ka,":  ",$leaders[$ka], "  ", $terminfo[$ka],"\n"; # debug
			$nres = 0;      # number of B/D restrictions			
			$dates = $terminfo[$ka];
			
		# determine first and last dates in office
			$lastterm = 0;
			$firstterm = "21000101";   # no, you shouldn't be using the program if this is invalid...
			while ($dates =~ m/T:\w+ (\d+)-(\d+)/g) { 
				if ($1 < $firstterm) { $firstterm = $1;}
				if ($2 > $lastterm) { $lastterm = $2;}
			}
			if ($dates =~ m/C:(\d+)/) {  $lastterm = $1; } # currently in office date
			if ($dates =~ m/P:(\d+)/) {  $firstterm = $1; } # previously in office date
			
#			print FOUT "$firstterm  $lastterm\n"; # debug

			if ($leaders[$ka] !~ /{([^}]+)}/g) {# write simple name
				print FOUT "$leaders[$ka]  ; CountryInfo.txt\n"; 
			}
			else { # write synonym block				
				print FOUT $1,"  ; CountryInfo.txt\n";
				while ($leaders[$ka] =~ /{([^}]+)}/g) { print FOUT "+$1\n";}
			}
			
			if ($dates =~ m/B:(\d+)/) {  # extract birth date, increment by 18 years
				$byear = substr($1,0,4);
				$bdate = substr($1,4);
				$byear += 18;   # MAGIC NUMBER! -- increment in years from birth date to start of elite status 
				print FOUT "\t[$ccode","ELI ",substr($byear,2),$bdate,"-",substr($firstterm,2),"]\n";
				++$nres;
			}
			if ($dates =~ m/P:(\w+) (\d+)/) {  # extract initially-in-office date from <Government>
				print FOUT "\t[",$1," 030101-",substr($2,2),"]\n";   # MAGIC NUMBER! -- initial date of reports specified here 
			}
			while ($dates =~ m/T:(\w+) \d\d(\d+)-\d\d(\d+)/g) {  # extract the terms of office
				print FOUT "\t[$1 $2-$3]\n";
			}
			if ($dates =~ m/D:(\d+)/) {  # extract death date
				++$nres;
				$ddate = $1;
				if ($dates =~ m/C:(\w+) (\d+)/) {  # we've got a currently in office date; terminate at death
					print FOUT "\t[$1 ",substr($2,2),"-",substr($ddate,2),"]\n";	
					$dates =~ s/C:/X:/;  # cancel C: since we just wrote it
				}			
				elsif ($1 > $lastterm) {print FOUT "\t[$ccode","ELI ",substr($lastterm,2),"-",substr($1,2),"]\n";}
			}
			if ($dates =~ m/C:(\w+) (\d+)/) {  # extract currently in office date
				print FOUT "\t[$1 >",substr($2,2),"]\n";
			}
			if (($nres<2) && ($dates =~ m/L:/))  {  # <Leader> but missing B: or D: info, so need a generic elites field
				print FOUT "\t[$ccode","ELI]\n";
			}
		} # for ka
	} # if <\Country>
}
close(FOUT) or die "Can\'t close output file ; error $!";
close(FIN) or die "Can\'t close input file ; error $!";
close(FDUP) or die "Can\'t close duplicates file ; error $!";

print "Program has finished!\n";
if ($founddups) { print "Duplicate entries found and recorded in $dupfile\n";}
