#!/usr/bin/perl -w
use strict;
use Rule6;
use Parse::Eyapp::YATW;
use Parse::Eyapp::Treeregexp;
use Data::Dumper;

my $transform = q{
my %Op = (PLUS=>'+', MINUS => '-', TIMES=>'*', DIV => '/');
/TIMES|PLUS|DIV|MINUS/(NUM(TERMINAL), NUM(TERMINAL)) 
   => { 
        my $op = $Op{ref($_[0])};
        $I[2]->{attr} = eval  "$I[2]->{attr} $op $I[4]->{attr}";
        $_[0] = $I[1]; 
      }
};

$Data::Dumper::Indent = 1;
my $parser = new Rule6();
my $t = $parser->Run;
print "\n***** Before ******\n";
print Dumper($t);
my $foldtimes = Parse::Eyapp::Treeregexp::generate( $transform );
my $p = Parse::Eyapp::YATW->new(
  PATTERN => $foldtimes,
);
$p->s($t);
print "\n***** After ******\n";
print Dumper($t);
