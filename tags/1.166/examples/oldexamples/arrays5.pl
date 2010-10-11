#!/usr/bin/perl -w
use strict;
use Rule6;
use Data::Dumper;
use Parse::Eyapp::Treeregexp;
use Parse::Eyapp::Node;

our @all;

my $severity = shift || 0;

Parse::Eyapp::Treeregexp::generate( STRING => q{
  whatever_times_zero: TIMES(@a, NUM(@b, $x) and { $x->{attr} == 0 }) => { $_[0] = $NUM }
},
SEVERITY => $severity);

$Data::Dumper::Indent = 1;
my $parser = new Rule6();
my $t = $parser->Run;
print "\n***** Before ******\n";
print Dumper($t);
$t->s(@all);
print "\n***** After ******\n";
print Dumper($t);
