#!/usr/bin/perl -w
use strict;
use Rule6;
use Parse::Eyapp::Node;
use Data::Dumper;

my $t = Parse::Eyapp::Node->new( q{TIMES(NUM(TERMINAL), NUM(TERMINAL))}, 
  sub { 
    our ($TIMES, @NUM, @TERMINAL);
    $TIMES->{type}       = "binary operation"; 
    $NUM[0]->{type}      = "int"; 
    $TERMINAL[0]->{attr} = 7; 
    $NUM[1]->{type}      = "float"; 
    $TERMINAL[1]->{attr} = 3.5; 
  },
);

$Data::Dumper::Indent = 1;
print Dumper($t);
