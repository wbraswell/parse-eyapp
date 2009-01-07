#!/usr/bin/perl -w
use strict;
use Rule7;
use Data::Dumper;

$Data::Dumper::Indent = 1;
my $parser = new Rule7();
$parser->Run;
