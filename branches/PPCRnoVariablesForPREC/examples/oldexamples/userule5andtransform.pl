#!/usr/bin/perl -w
use strict;
use Rule5;
use Parse::YATW;
use Data::Dumper;

$Data::Dumper::Indent = 1;
my $parser = new Rule5();
my $t = $parser->Run;
print Dumper($t);
