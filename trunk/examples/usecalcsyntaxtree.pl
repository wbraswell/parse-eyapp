#!/usr/bin/perl -w
# usecalcsyntaxtree.pl prueba2.exp
use strict;
use CalcSyntaxTree;

sub slurp_file {
  my $fn = shift;
  my $f;

  local $/ = undef;
  if (defined($fn)) {
    open $f, $fn 
  }
  else {
    $f = \*STDIN;
  }
  my $input = <$f>;
  return $input;
}

my $parser = CalcSyntaxTree->new();

my $input = slurp_file( shift() );
my $tree = $parser->Run($input);

$Parse::Eyapp::Node::INDENT = 2;
print $tree->str."\n";
