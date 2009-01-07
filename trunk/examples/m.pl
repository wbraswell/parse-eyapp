#!/usr/bin/perl -w
use strict;
use Rule6;
use Data::Dumper;
use Parse::Eyapp::Treeregexp;
$Data::Dumper::Indent = 1;

Parse::Eyapp::Treeregexp->new( STRING => q{
  is_bin: /times|plus|div|minus/i($n, $m) 
  zero_times_whatever: TIMES(NUM($x), .) and { $x->{attr} == 0 } 
  whatever_times_zero: TIMES(., NUM($x)) and { $x->{attr} == 0 }
})->generate();

our @b = our ($is_bin, $zero_times_whatever, $whatever_times_zero);

sub aux {
  my @m = @_;

  for my $n (@m) {
    my $class = ref($n->node);
    my @patterns = $n->patterns;
    my @names = $n->names;
    print $n->node."\ndepth=".$n->depth."\npatterns = @patterns\nnames = @names\n"
  }
}

sub Rule6::test {
  my $parser = shift;

  my $input = $parser->YYData->{INPUT} = shift;
  my $t = $parser->Run;

  print "\n***** Matching: Array context $input ******\n";
  my @m = $t->m(@b);
  aux(@m);

  @m = ();
  print "\n***** Matching: scalar context $input ******\n";
  $m[0] = $t->m(@b);
  aux(@m);
}


# Syntax analysis
my $parser = new Rule6();

$parser->test('2*0*0');
$parser->test('0*0*0');
$parser->test('0*0+0*0');
