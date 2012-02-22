#!/usr/bin/perl -w

# This program prints a list of the words in a text and the
# number of times each word occurs. The default order is
# alphabetical, but you can specify that the computer sort by
# frequency using the "-f" switch.
#
# Usage: freq.pl <file> [-f]

use strict;
use PTA::PTA;


my($filename, @keys, $sort_order);
local($main::parser, $main::item);

sub by_freq;

$filename = shift;
$sort_order = shift;

$main::parser = new PTA::PTA;

$main::parser->parse($filename);
$main::parser->load_freq;

@keys = keys %{$main::parser->{'freq'}};

if (lc($sort_order) eq '-f') {
    @keys = sort by_freq @keys;
} else {
    @keys = sort @keys;
}

foreach $main::item (@keys) {
    write;
}

#
# sort subroutines
##################
sub by_freq {
    $main::parser->{'freq'}{$a} <=> $main::parser->{'freq'}{$b};
}

#
# formats
#########
format STDOUT_TOP =
 Word                Frequency
 ==================  =========
.

format STDOUT =
 @<<<<<<<<<<<<<<<<<  @<<<<<<<<
 $main::item,              $main::parser->{'freq'}{$main::item}
.
