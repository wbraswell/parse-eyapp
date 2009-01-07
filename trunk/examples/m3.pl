#!/usr/bin/perl -w
use strict;
use Rule6;
use Data::Dumper;
use Parse::Eyapp::Treeregexp;
$Data::Dumper::Indent = 1;

Parse::Eyapp::Treeregexp->new( STRING => q{
  fold: /times|plus|div|minus/i:bin(NUM($n), NUM($m)) 
  zero_times_whatever: TIMES(NUM($x), .) and { $x->{attr} == 0 } 
  whatever_times_zero: TIMES(., NUM($x)) and { $x->{attr} == 0 }
})->generate();

# Syntax analysis
my $parser = new Rule6();
print "Expression: ";
$parser->YYData->{INPUT} = <>;
my $t = $parser->Run;

$Parse::Eyapp::Node::INDENT = 1;
print "Tree:\n",$t->str,"\n";

print "\n***** Matching: scalar context ******\n";

our @b = our ($fold, $zero_times_whatever, $whatever_times_zero);
my $f = $t->m(@b);

print "Match Node:\n",$f->str;

print "\n***** Matching: Array context ******\n";
my @m = $t->m(@b);
print Parse::Eyapp::Node->str(@m),"\n";

