#!/usr/bin/perl -w
use strict;
use Meta;
use Data::Dumper;
use Parse::Eyapp::Node;

$Data::Dumper::Indent = 1;
$Data::Dumper::Terse = 1;
$Data::Dumper::Deepcopy  = 1;
my $parser = new Meta();
my $t = $parser->Run;
print Dumper($t);
$t->translation_scheme;

