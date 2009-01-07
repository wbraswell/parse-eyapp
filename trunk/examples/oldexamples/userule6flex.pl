#!/usr/bin/perl -w
use strict;
use Rule6flex;
use Data::Dumper;
use flex3;

$Data::Dumper::Indent = 1;
my $parser = Rule6flex->new();
my $t = $parser->Run;
print Dumper($t);
