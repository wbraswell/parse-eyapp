#!/usr/bin/perl -w
use strict;
use Parse::Eyapp::YATW;
use Parse::Eyapp::Treeregexp;

my $transformations_code = q{
wrong_rule: .* 
};

my @transformations = Parse::Eyapp::Treeregexp::generate( STRING => $transformations_code );
