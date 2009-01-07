#!/usr/bin/perl -w
use strict;
use Parse::Eyapp::Treeregexp;
use Data::Dumper;

my $input;
{
   local $/ = undef;
   $input = <>;
}
my $t = Parse::Eyapp::Treeregexp::generate($input);


