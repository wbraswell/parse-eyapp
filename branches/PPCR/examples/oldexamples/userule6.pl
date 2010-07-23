#!/usr/bin/perl -w
use strict;
use Rule6;
use Data::Dumper;

$Data::Dumper::Indent = 1;
my $parser = new Rule6();
my $t = $parser->Run;
print Dumper($t);
