#!/usr/bin/perl -w
use strict;
use TSPostfix2anddeletecode;
use Parse::Eyapp::Treeregexp;

my $parser = TSPostfix2anddeletecode->new();
$parser->Run;
