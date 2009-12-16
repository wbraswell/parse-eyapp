#!/usr/bin/perl -w
use strict;
use Rule5;
use Parse::Eyapp::Base qw(insert_function);
use Shift;

sub SHIFTLEFT::info { $_[0]{shift} }
insert_function('TERMINAL::info', \&TERMINAL::attr);

my $parser = new Rule5();
$parser->slurp_file('','Arithmetic expression: ', "\n");
my $t = $parser->Run;
unless ($parser->YYNberr) {
  print "***********\n",$t->str,"\n";
  $t->s(@Shift::all);
  print "***********\n",$t->str,"\n";
}
