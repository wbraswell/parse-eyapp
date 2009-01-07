#!/usr/bin/perl -w
use strict;
use Rule8;
use Data::Dumper;

$Data::Dumper::Indent = 1;
my $parser = new Rule8();
$parser->Run;
