#!/usr/bin/perl -w
use strict;
use Rule6;
use Parse::Eyapp::Node;
use Data::Dumper;

my @t = Parse::Eyapp::Node->new( q{TIMES(NUM(TERMINAL), NUM(TERMINAL))}, 
    sub { 
          $_[0]->{type} = "binary operation"; 
          $_[1]->{type} = "int"; 
          $_[2]->{attr} = 7; 
          $_[3]->{type} = "float"; 
          $_[4]->{attr} = 3.5; 
  },
);

$Data::Dumper::Indent = 1;
print Dumper(@t);
