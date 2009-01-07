#!/usr/bin/perl -w
use strict;
use Rule6;
use Parse::Eyapp::YATW;
use Parse::Eyapp::Treeregexp;
use Data::Dumper;
use transform;

$Data::Dumper::Indent = 1;
my $parser = new Rule6();
my $t = $parser->Run;
print "\n***** Before ******\n";
print Dumper($t);
my $g = Parse::Eyapp::Treeregexp->new(INFILE => "transform.trg" );
$g->generate();
$t->s(@transform::all);
print "\n***** After ******\n";
print Dumper($t);
