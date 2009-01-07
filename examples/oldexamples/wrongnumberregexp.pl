#!/usr/bin/perl -w
use strict;
use Rule6;
use Data::Dumper;
use Parse::Eyapp::Treeregexp;
use Parse::Eyapp::Node;

our @all;
my $severity = shift || 0;

Parse::Eyapp::Treeregexp::generate( STRING => q{
%{
  my %Op = (PLUS=>'+', MINUS => '-', TIMES=>'*', DIV => '/');
%}

  zero_times_whatever: 'TI'(NUM($x)) and { $x->{attr} == 0 } => { $_[0] = $NUM }
  whatever_times_zero: 'TI'(., NUM($x)) and { $x->{attr} == 0 } => { $_[0] = $NUM }

  /* rules related with times */
  times_zero = zero_times_whatever whatever_times_zero;
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
