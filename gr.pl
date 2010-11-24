#!/usr/bin/env perl 
use warnings;
use strict;
use Getopt::Long;
use Parse::Eyapp;

my $graph = '';

my $file = shift || usage();

my($parser)=new Parse::Eyapp(inputfile => $file);

my($warnings)=$parser->Warnings();

$warnings and warn $warnings;
                               #path, base
my $dfa = $parser->ShowDfa();

my $grammar = $parser->ShowRules()."\n";

warn "$grammar\n";

# make an array from the grammar

my %grammar = $grammar =~ m{(\d+):\s+(.*)}gx;

# escape double quotes inside %grammar
for (sort { $a <=> $b } keys %grammar) {
  $grammar{$_} =~ s/"/\\"/g;

  warn "$_ => $grammar{$_}\n";

  $graph .= qq{"$grammar{$_}" [shape = box, fontcolor=blue, color=blue ]\n};
}

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

  # $default	reduce using rule 1 (prog)
  # ID	reduce using rule 15 (decORexp_explorer)
  while ($desc =~ m{\t(\S+)\s+reduce\s+using\s+rule\s+(\d+)}gx) {
    $graph .=  qq{$_ -> "$grammar{$2}" [label = "$1", color = "blue", fontcolor = "blue"]\n};
  }


  # $default    accept
  if ($desc =~ m{\t\$default\s+accept\s*}gx) {
    $graph .=  qq{$_ [shape = doublecircle]\n};
  }

  warn "$_ => $desc\n";
  
}
print "digraph G {\n$graph}\n";


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

