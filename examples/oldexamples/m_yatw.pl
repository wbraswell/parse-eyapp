#!/usr/bin/perl -w
use strict;
use Rule6;
use Parse::Eyapp::Treeregexp;

Parse::Eyapp::Treeregexp->new( STRING => q{
  bin: /times|plus|div|minus/i($n, $m) 
  zero_x_whatever: TIMES(NUM($x), .) and { $x->{attr} == 0 } 
  whatever_x_zero: TIMES(., NUM($x)) and { $x->{attr} == 0 }
})->generate();

my $parser = new Rule6();
$parser->YYData->{INPUT} = '2*0*0';
my $t = $parser->Run;

our @b = (our $bin, our $zero_x_whatever, our $whatever_x_zero);
for (@b) {
  print "***** Matching: scalar context with ".$_->name." ******\n";
  my $f = $_->m($t);
  my ($n,@r);
  push @r, $n while $n = $f->();
  my $h = sub { print $_->str."\n" for @_ };
  $h->(@r);

  print "***** Matching: list context with ".$_->name." ******\n";
  @r = $_->m($t);
  $h->(@r);
}
