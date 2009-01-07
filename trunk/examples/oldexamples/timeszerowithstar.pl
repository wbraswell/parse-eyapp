#!/usr/bin/perl -w
use strict;
use Rule6;
use Parse::Eyapp::YATW;
use Parse::Eyapp::Treeregexp;
use Data::Dumper;

my $transformations_code = q{
zero_times: TIMES(NUM(TERMINAL)*, .) and { $I[2]->{attr} == 0 } => { print "matches!\n" }
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
