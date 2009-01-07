#!/usr/bin/perl -w
use strict;
use Rule6;
use Parse::Eyapp::YATW;
use Parse::Eyapp::Treeregexp;
use Data::Dumper;

$Data::Dumper::Indent = 1;
my $parser = new Rule6();
my $t = $parser->Run;
print "\n***** Before ******\n";
print Dumper($t);
my @transformations = Parse::Eyapp::Treeregexp::generate( FILE => "transformerr1.trg" );
$t->s(@transformations);
print "\n***** After ******\n";
print Dumper($t);
