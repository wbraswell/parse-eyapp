#!/usr/bin/perl -w
# usetreebypass.pl prueba2.exp
use strict;
use TreeBypass;

sub slurp_file {
  my $fn = shift;
  my $f;

  local $/ = undef;
  if (defined($fn)) {
    open $f, $fn  or die "Can't find file $fn!\n";
  }
  else {
    $f = \*STDIN;
  }
  my $input = <$f>;
  return $input;
}

my $parser = TreeBypass->new();

my $input = slurp_file( shift() );
my $tree = $parser->Run($input);
die "There were errors\n" unless defined($tree);

$Parse::Eyapp::Node::INDENT = 2;
print $tree->str."\n";
