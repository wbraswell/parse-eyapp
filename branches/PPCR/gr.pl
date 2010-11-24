#!/usr/bin/env perl 
use warnings;
use strict;
use Getopt::Long;
use Parse::Eyapp;

my $file = shift || usage();

my $dfa = getOutput($file);

warn "$dfa\n";

my %states = ($dfa =~ m{State\s*(\d+)\s*:\n\s*
                        (
                        (?:
                         .*->.*       | # a production line
                         .*go\s+to.*  | # a shift or a goto line
                         .*reduce.*   | # a reduce line
                         .*accept.*   | # an accept line
                         \s+          | # white lines
                        )+
                        )
                       }gx);

my $graph = '';
for (sort { $a <=> $b } keys %states) {
  my $desc = $states{$_};
  $desc =~ s/.*->.*//g;     # remove productions
  $desc =~ s/\n\s*\n/\n/g;  # remove white lines

  # build digraph
  # ID  shift, and go to state 4
  while ($desc =~ m{\t(.*)\s+shift,\s+and\s+go\s+to\s+state\s+(\d+)}gx) {
    $graph .=  qq{$_ -> $2 [label = "$1"]\n};
  }

  # decl    go to state 1
  while ($desc =~ m{\t(\S+)\s+go\s+to\s+state\s+(\d+)}gx) {
    $graph .=  qq{$_ -> $2 [label = "$1", color = "red", fontcolor = "red"]\n};
  }

  # $default    accept
  if ($desc =~ m{\t\$default\s+accept\s*}gx) {
    $graph .=  qq{$_ [shape = doublecircle]\n};
  }

  warn "$_ => $desc\n";
  
}
print "digraph G {\n$graph}\n";


sub getOutput {

  my $file = shift || error("Provide a file");

  my($parser)=new Parse::Eyapp(inputfile => $file);

  my($warnings)=$parser->Warnings();
          $warnings
  and warn $warnings;
                               #path, base
  return $parser->ShowDfa();
}

sub error {
  my $message = shift;

  warn "$message\n" if $message;
  usage();
}

sub usage {
  warn << "HELP";
Usage: 
            $0 filename
HELP
  exit(1);
}

