#!/usr/bin/perl -w
use strict;
use Rule6;
use Data::Dumper;
use Parse::Eyapp::Treeregexp;
use Parse::Eyapp::Node;

our @all;

Parse::Eyapp::Treeregexp::generate( STRING => q{
  #zero_times_whatever: TIMES(NUM($x), @a) and { $x->{attr} == 0 } => { $_[0] = $NUM }
  whatever_times_zero: TIMES(@b, NUM($x)) and { $x->{attr} == 0 } => { $_[0] = $NUM }
});

$Data::Dumper::Indent = 1;
my $parser = new Rule6();
my $t = $parser->Run;
print "\n***** Before ******\n";
print Dumper($t);
$t->s(@all);
print "\n***** After ******\n";
print Dumper($t);
