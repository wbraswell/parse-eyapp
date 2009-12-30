#!/usr/bin/env perl -w
use strict;

print "Hello world:\n";
my $i = 0;
for (@ARGV) {
 print ($i++.": $_\n");
}

