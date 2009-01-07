#!/usr/bin/perl -w
use Rule;
use Data::Dumper;


$Data::Dumper::Indent = 1;
$parser = new Rule();
my $tree = $parser->Run;
if (defined($tree)) { print Dumper($tree); }
else { print "Cadena no válida\n"; }
