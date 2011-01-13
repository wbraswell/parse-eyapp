#!/usr/bin/perl -w
use strict;
use Rule6;
use Parse::Eyapp::YATW;
use Parse::Eyapp::Treeregexp;
use Data::Dumper;

my $transformations_code = q{
simplify_num: 'TERMINAL':bin and { $_[0]->{attr} ne "a" }
  => { 
    $_[0]->{attr} = "a";
  }
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
