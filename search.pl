#!/usr/bin/perl -w

# This program search for regular expressions within a file
# and prints out the line number and line those expressions
# occur on.
#
# Usage: search.pl <file> <re>
# Note that <re> may need quotes about it. Check the usage
# on your system.

use strict;
use PTA::PTA;


my($filename, $parser, $search, $x);

$filename = shift;
$search = shift;

$parser = new PTA::PTA;

$parser->parse($filename);

for ($x = 0; $x <= $#{$parser->{'text'}}; $x++) {
    if ($parser->{'text'}[$x] =~ /$search/) {
	print "$x: $parser->{'text'}[$x]";
    }
}
