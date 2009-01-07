#!/usr/bin/perl -w
use strict;
use Rule6;
use Data::Dumper;
use Parse::Eyapp::Treeregexp;
use Parse::Eyapp::Node;

our @all;

my $treegrammar = q{
%{
  my %Op = (PLUS=>'+', MINUS => '-', TIMES=>'*', DIV => '/');
%}

  fold: /TIMES|PLUS|DIV|MINUS/:bin(NUM($n), NUM($m)) 
    => { 
      my $op = $Op{ref($bin)};
      $n->{attr} = eval  "$n->{attr} $op $m->{attr}";
      $_[0] = $NUM[0]; # return true value
    }
  zero_times_whatever: TIMES(NUM($x), .) and { $x->{attr} == 0 } => { $_[0] = $NUM }
  whatever_times_zero: TIMES(., NUM($x)) and { $x->{attr} == 0 } => { $_[0] = $NUM }

  /* rules related with times */
  times_zero = zero_times_whatever whatever_times_zero;
};

Parse::Eyapp::Treeregexp->new( SEVERITY => 1, STRING => $treegrammar )->generate();

$Data::Dumper::Indent = 1;
my $parser = new Rule6();
my $t = $parser->Run;
print "\n***** Before ******\n";
print Dumper($t);
$t->s(@all);
print "\n***** After ******\n";
print Dumper($t);
