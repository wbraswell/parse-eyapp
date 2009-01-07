#!/usr/bin/perl
use warnings;
use strict;
use File::Basename;

print "Generating test files for 'eyapp -c'\n";
my @grammar = glob('examples/*/*.eyp examples/*/*.yp'); 
for (@grammar) {
  my ($name,$path,$suffix) = fileparse($_);
  $path =~ s{/}{_}g;
  my $cleanok = " t/cleanok/${path}_$name";
  print "vim -O $cleanok $_\n";
  system("./eyapp -c $_ > t/cleanok/${path}_$name");
  my $cleanvok = " t/cleanvok/${path}_$name";
  print "vim -O $cleanvok $_\n";
  system("./eyapp -vc $_ > t/cleanvok/${path}_$name");
}
