#!/usr/bin/env perl 
use warnings;
use strict;
use Getopt::Long;
use Parse::Eyapp;

my $labelWithCore = 1;

my $file = shift || usage();

my($parser)=new Parse::Eyapp(inputfile => $file, 
                             nocompact => 1
                            );

my($warnings)=$parser->Warnings();

$warnings and warn $warnings;
                               #path, base
print $parser->outputDot($labelWithCore);

sub usage {
  warn << "HELP";
Usage: 
            $0 filename
HELP
  exit(1);
}

