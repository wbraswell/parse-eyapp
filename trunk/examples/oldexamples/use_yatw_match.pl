#!/usr/bin/perl -w
use strict;
use Rule6;
use Parse::Eyapp::YATW;
use Data::Dumper;

$Data::Dumper::Indent = 1;
my $parser = new Rule6();
$parser->YYData->{INPUT} = <>;
my $t = $parser->Run;
my $q = Parse::Eyapp::YATW->new(
  PATTERN => sub { 
    my $isterm = $_[0]->isa('TERMINAL'); 
    $isterm
  }
);
$q->s($t);
my @m = $q->m();
print Dumper($_) for @m;;
