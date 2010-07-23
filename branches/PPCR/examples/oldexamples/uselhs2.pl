#!/usr/bin/perl -w

BEGIN { unshift @INC, '/home/lhp/Lperl/src/yapp/Parse-Yapp-Auto/lib/' }
use Lhs2;
use Data::Dumper;


$Data::Dumper::Indent = 1;
$parser = new Lhs2();
my $tree = $parser->Run;
if (defined($tree)) { print Dumper($tree); }
else { print "Cadena no válida\n"; }
