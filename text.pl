#!/usr/bin/perl -w

# This file prints a list of all the content words
# in a text, one word per line.
#
# Usage: text.pl <file>

use strict;
use PTA::PTA;


my($filename, $p, $parser);

$filename = shift;

$parser = new PTA::PTA;

$parser->parse($filename);

for ($p = $parser->{'start'}; $p; $p = $p->{'next'}) {
    print "$p->{'word'}\n";
}
