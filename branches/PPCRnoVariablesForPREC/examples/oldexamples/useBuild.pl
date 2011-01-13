#!/usr/bin/perl -w
use strict;
use Rule6;
use Data::Dumper;
use Build;

$Data::Dumper::Indent = 1;
my $parser = new Rule6();
my $t = $parser->Run;
print "\n***** Before ******\n";
print Dumper($t);
$t->s(@Build::all);
print "\n***** After ******\n";
print Dumper($t);
