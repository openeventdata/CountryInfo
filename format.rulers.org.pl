##  format.rulers.org.pl
##
##  This Perl program translates one or more lines from the Rulers.org web site into the 
##  CountryInfo.txt format.
##   
##  TO RUN PROGRAM:
##
##  format.rulers.org.pl [optional file name]
##
##  INPUT/OUTPUT:
##  Option 1: Input is from the text file entered in the command line; output is in a new file with
##  that named prefixed by "fmtd."
##
##  Option 2: Input is from the keyboard (<STDIN>); usually this will just be a cut-and-paste from 
##  the web site. Enter Ctrl-D to quit. Translated format is printed to the terminal screen and 
##  placed in the clipboard. 
##          
##  PROGRAMMING NOTES:
##  1. There is a translator (copied from the web...) that gets rid of a lot of the diacriticals
##     but it works erratically -- probably due to multiple web formats -- and many of these will
##     probably need to be corrected manually.
##
##  2. Lines that are not in a recognizable format are ignored and a diagnostic is written to the 
##     screen.
##
##  SYSTEM REQUIREMENTS
##  This program has been successfully run under Mac OS 10.5; the reformatting should also run in 
##  Unix or Windows but the system() call to place the output on the clipboard will presumably need
##  to be modified. 
##
##  PROVENANCE:
##  Programmer: Philip A. Schrodt
##              Dept of Political Science
##              Pennysylvania State University
##              227 Pond Laboratory
##	            University Park, PA, 16802 U.S.A.
##	            http://eventdata.psu.edu
##
##	Copyright (c) 2012  Philip A. Schrodt.  All rights reserved.
##
## 	Redistribution and use in source and binary forms, with or without modification,
## 	are permitted under the terms of the GNU General Public License:
## 	http://www.opensource.org/licenses/gpl-license.html
##
##	Report bugs to: schrodt@psu.edu
##
##  REVISION HISTORY:
##  07-Jan-12:  Initial version
##

$months = "Jan.Feb.Mar.Apr.May.Jun.Jul.Aug.Sep.Oct.Nov.Dec";		# ISO 3166 country codes
%xlateL = (  # set up ASCII translation -- this only sort of works in OS-X
    a => 'âàå',
    c => 'ç',
    e => 'èëéê',
    i => 'ïî',
    o => 'ôø',
    u => 'ùûü',
#    n => '\xF1'
    #...
    );

%xlateU;
$xlateU{uc $_} = uc ($xlateL{$_}) for keys %xlateL; #Generate the upper case versions

#$test1 = "This is a test";  # debugging
#system("echo $test1 | pbcopy");
#exit();

if (length($ARGV[0]) > 4) { # read input from a file
	$readfile = 1;
	$infile = $ARGV[0];
	$outfile = "fmtd.".$infile;
	print "Processing the text from \"$infile\"; formatted text will be written to \"$outfile\"\n";
	open(FIN,$infile) or die "Can\'t open input file $infile; error $!";  
	open(FOUT,">$outfile") or die "Can\'t open output file $outfile; error $!"; 
	$inhdl = *FIN;
}
else {
	$readfile = 0;	
	$inhdl = *STDIN;  # read input from the keyboard
	print "Enter one or more lines of text from rulers.org, then <RTN> to be translate; enter Ctrl-D to quit\n";
}

#$nrec = 0;
while ($line = <$inhdl>) {
#	++$nrec;
#	if ($nrec > 10) {exit;} # debug: process only part of a file
#	print $line;
  $name = "";
	if ($line =~ /(\d+) (\w+) (\d+) -\s+(\d+) (\w+) (\d+)/) {  # completed term format
		$d1 = $1;
		if (length($d1) < 2) { $d1 = "0$d1";}
		$m1 = $2;
		$mn1 = (index($months, $m1)/4) + 1;
		if (length($mn1) < 2) { $mn1 = "0$mn1";}		
		$y1 = $3;
		$d2 = $4;
		if (length($d2) < 2) { $d2 = "0$d2";}
		$m2 = $5;
		$mn2 = (index($months, $m2)/4) + 1;
		if (length($mn2) < 2) { $mn2 = "0$mn2";}		
		$y2 = $6;
		$tseg = "[$y1$mn1$d1 - $y2$mn2$d2]";
		if ($line =~ /\d\d\d\d\s+([A-Z][^(]+)/) {$name = $1;}
	}	
	elsif ($line =~ /(\d+) (\w+) (\d+) - /) { # on-going term format
		$d1 = $1;
		if (length($d1) < 2) { $d1 = "0$d1";}
		$m1 = $2;
		$mn1 = (index($months, $m1)/4) + 1;
		if (length($mn1) < 2) { $mn1 = "0$mn1";}		
		$y1 = $3;
		$tseg = "[>$y1$mn1$d1]"; 
		if ($line =~ /\d+ -\s+([^(]+)/) {$name = $1;}
	}	
	if (length($name) > 0) {
		$name =~ s/\s+$//;  # remove terminal blanks
		eval "\$name =~ tr/$xlateL{$_}/$_/;" for keys %xlateL; # remove diacriticals
		eval "\$name =~ tr/$xlateU{$_}/$_/;" for keys %xlateU;
		$name = uc($name);
		$name =~ s/ /_/g;
		$name .= "_";
		if ($line =~ /b\. (\d+)/) { $bseg = "[B: $1"."0101]";}  # the 0101 is a CountryInfo.txt convention
		else {$bseg = "";} 
		if ($line =~ /d\. (\d+)/) { $dseg = "[D: $1"."0101]";}
		else {$dseg = "";} 
	
		$entry = "\t\t$name $tseg $bseg $dseg";
		if ($readfile) {print FOUT $entry,"\n";}
		else {
			print "Formatted: $entry\n";
			system("echo $entry | pbcopy"); # paste the line to the clipboard (OS-X)
		}
	}
	else { 
		chomp($line);
		print "Unrecognized format: \"",$line,"\"\n";
	}
}
if ($readfile) {
	close(FOUT) or die "Can\'t close output file ; error $!";
	close(FIN) or die "Can\'t close input file ; error $!";
}
print "Goodbye, and have a nice day!\n";
print "Farvel, og ha en fin dag!\n";  