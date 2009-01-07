#!/usr/bin/perl -w
use strict;
use Rule4;
use Parse::Eyapp::YATW;
use Data::Dumper;

$Data::Dumper::Indent = 1;
my $parser = new Rule4();
my $t = $parser->Run;
print Dumper($t);
print "\n***********\n";
my $q = Parse::Eyapp::YATW->new(
  PATTERN => 'TERM',
);
$q->s($t);
my @m = $q->matches();
print Dumper($_) for @m;;
print "\n***********\n";
my $p = Parse::Eyapp::YATW->new(
  PATTERN => sub { print "Token $_[0]->{token} has value $_[0]->{attr}\n" if $_[0]->isa('TERMINAL') }
);
$p->s($t);
