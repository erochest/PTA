#!/usr/bin/perl -w

# This program produces a concordance of a text, printing
# the line number the word is on and the character on that line
# that the word begins on, and finally printing out the line
# itself.
#
# Usage: concord.pl <file>

use strict;
use PTA::PTA;


my($filename, $item, $current, $line, $parser);

$filename = shift;

$parser = new PTA::PTA;

$parser->parse($filename);

$current = '';

foreach $item (@{$parser->{'list'}}) {
    if ($item->{'word'} ne $current) {
	$current = $item->{'word'};
	&printheader($current);
    }
    $line = $parser->{'text'}[$item->{'line'}];
    chomp $line;
    printf "%3d.%3d: %s\n", $item->{'line'}+1, $item->{'col'}+1, $line;
}


# subroutines
sub printheader {
    my($word) = @_;
    print "\n$word\n" . ('=' x length($word)) . "\n";
}
