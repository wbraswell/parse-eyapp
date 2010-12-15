#!/usr/bin/perl -w
use strict;
use Identifyattr;
use Data::Dumper;

$Data::Dumper::Indent = 1;
my $parser = new Identifyattr();
my $t = $parser->Run;
print "@$t\n";
