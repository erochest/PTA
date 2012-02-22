#!/usr/bin/perl -w

# This program prints a list of the words in a text and the
# collocates of that word. Each word is listed, the number of times
# it appears in the text, a collocate of that word, the total number
# of times the collocate appears in the text, and the number of times
# it appears near the primary word.
#
# The "-w" switch determines how far away from a word to look for
# collocates. The default value is 5.
#
# Usage: freq.pl <file> [-w <number>]

use strict;
use PTA::PTA;


my($filename, @keys, $width, @colls);
local($main::parser, $main::item, $main::coll);

$filename = shift;
if (lc(shift) eq '-w') {
    $width = shift;
} else {
    $width = 5;
}

$main::parser = new PTA::PTA;

$main::parser->parse($filename);
$main::parser->load_coll($width);

@keys = keys %{$main::parser->{'coll'}};
@keys = sort @keys;

foreach $main::item (@keys) {
    @colls = keys %{$main::parser->{'coll'}{$main::item}};
    @colls = sort @colls;
    foreach $main::coll (@colls) {
	write;
    }
}

#
# subroutines
##################

#
# formats
#########
format STDOUT_TOP =
 Word                Frequency  Collocate           Frequency  Co-occurance
 ==================  =========  ==================  =========  ============
.

format STDOUT =
 @<<<<<<<<<<<<<<<<<  @<<<<<<<<  @<<<<<<<<<<<<<<<<<  @<<<<<<<<  @<<<<<<<<<<<
$main::item,$main::parser->{'freq'}{$main::item},$main::coll,$main::parser->{'freq'}{$main::coll},$main::parser->{'coll'}{$main::item}{$main::coll}
.
