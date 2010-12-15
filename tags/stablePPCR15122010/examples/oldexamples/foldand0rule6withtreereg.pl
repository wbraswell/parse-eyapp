#!/usr/bin/perl -w
use strict;
use Rule6;
use Parse::Eyapp::YATW;
use Parse::Eyapp::Treeregexp;
use Data::Dumper;

my $transformations_code = q{
%{ 
my %x = (PLUS=>'+', MINUS => '-', TIMES=>'*', DIV => '/');
%}

constantfold: 'TIMES|PLUS|DIV|MINUS':bin(NUM($left), NUM($right)) 
  => { 
    my $x = $x{ref($bin)};
    $left->{attr} = eval  "$left->{attr} $x $right->{attr}";
    $_[0] = $NUM[0]; 
  }
zero_times: TIMES(NUM(TERMINAL), .) and { $TERMINAL->{attr} == 0 } => { $_[0] = $NUM }
times_zero: TIMES(., NUM(TERMINAL)) and { $TERMINAL->{attr} == 0 } => { $_[0] = $NUM }
};

$Data::Dumper::Indent = 1;
my $parser = new Rule6();
my $t = $parser->Run;
print "\n***** Before ******\n";
print Dumper($t);
my @transformations = Parse::Eyapp::Treeregexp::generate( STRING => $transformations_code );
$t->s(@transformations);
print "\n***** After ******\n";
print Dumper($t);
