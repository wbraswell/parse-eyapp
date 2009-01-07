#!/usr/bin/perl -w
use strict;
use File::Basename;

require Test::More;
# TODO: Use MANIFEST instead!
my @grammar = glob('examples/*/*.eyp examples/*/*.yp'); 
my $numtests = @grammar;
Test::More->import(tests=>$numtests);

SKIP: {
  skip("Developer test", $numtests) unless ($ENV{DEVELOPER} && -x "./eyapp" && ($^O =~ /nux$/));

  for (@grammar) {
     my ($name,$path,$suffix) = fileparse($_);
     $path =~ s{/}{_}g;

     # Uncomment this line to create ok files
     # then check each generated file
     # system("./eyapp -c $_ > t/cleanok/${path}_$name");

     my $output = `./eyapp -c $_`;

     # Human checked results stored in t/cleanok/
     my $okfile = "t/cleanok/${path}_$name";

     my $ok = $output;
     # skip the test if the file does not exists
     if (-r "t/cleanok/${path}_$name") {
       $ok = `cat t/cleanok/${path}_$name`;
     }
     else {
       $_ = "skipping grammar $_";
     }

     is($output, $ok, $_);
  }
}

