#!/usr/bin/perl -w
use strict;
use Rule6;
use Data::Dumper;
use Transform2;

$Data::Dumper::Indent = 1;
my $parser = new Rule6();
my $t = $parser->Run;
print "\n***** Before ******\n";
print Dumper($t);
$t->s(@Transform2::all);
print "\n***** After ******\n";
print Dumper($t);
