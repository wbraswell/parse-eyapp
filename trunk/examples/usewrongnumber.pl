#!/usr/bin/perl -w
use strict;
use Rule6;
use Parse::Eyapp::YATW;
use Data::Dumper;
use Wrongnumber;

$Data::Dumper::Indent = 1;
my $parser = new Rule6();
my $t = $parser->Run;
print "\n***** Before ******\n";
print Dumper($t);
$t->s(@Wrongnumber::all);
print "\n***** After ******\n";
print Dumper($t);
