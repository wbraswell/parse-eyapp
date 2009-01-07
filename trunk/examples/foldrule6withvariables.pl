#!/usr/bin/perl -w
use strict;
use Rule6;
use Parse::Eyapp;
use Parse::Eyapp::Treeregexp;
use Data::Dumper;

our (@all, $uminus, $constantfold, $zero_times_whatever, $whatever_times_zero);

$Data::Dumper::Indent = 1;
my $parser = Rule6->new();
my $t = $parser->Run;
print "\n***** Before ******\n";
print Dumper($t);
my $p = Parse::Eyapp::Treeregexp->new( STRING => q{
  {
    my %Op = (PLUS=>'+', MINUS => '-', TIMES=>'*', DIV => '/');
  }
  constantfold: /TIMES|PLUS|DIV|MINUS/:bin(NUM($x), NUM($y)) 
     => { 
	  my $op = $Op{ref($_[0])};
	  $x->{attr} = eval  "$x->{attr} $op $y->{attr}";
	  $_[0] = $NUM[0]; 
	}
  uminus: UMINUS(NUM($x)) => { $x->{attr} = -$x->{attr}; $_[0] = $NUM }
  zero_times_whatever: TIMES(NUM($x), .) and { $x->{attr} == 0 } => { $_[0] = $NUM }
  whatever_times_zero: TIMES(., NUM($x)) and { $x->{attr} == 0 } => { $_[0] = $NUM }
  },
);
$p->generate();
$uminus->s($t);
$constantfold->s($t);
$zero_times_whatever->s($t);
$whatever_times_zero->s($t);
$constantfold->s($t);
print "\n***** After ******\n";
print Dumper($t);
