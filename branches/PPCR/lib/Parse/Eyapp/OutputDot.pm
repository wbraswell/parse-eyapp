package Parse::Eyapp::OutputDot;
use warnings;
use strict;
use base q{Parse::Eyapp};

sub outputDot {
  my $parser = shift;
  my $labelWithCore = shift;

  my $graph = '';

  my $dfa = $parser->ShowDfa();

  my $grammar = $parser->ShowRules()."\n";

  #warn "$grammar\n";

  # make an array from the grammar

  my %grammar = $grammar =~ m{(\d+):\s+(.*)}gx;

  # escape double quotes inside %grammar
  $graph .= qq{"$grammar{0}" [shape = doubleoctagon, fontcolor=blue, color=blue ]\n};
  for (1 .. (keys %grammar)-1) {
    $grammar{$_} =~ s/\\/\\\\/g;
    $grammar{$_} =~ s/"/\\"/g;

    #warn "$_ => $grammar{$_}\n";

    $graph .= qq{"$grammar{$_}" [shape = box, fontcolor=blue, color=blue ]\n};
  }

  #warn "$dfa\n";

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
    my @LRitems = $desc =~ m{(\S.*->.*[^\s.])\s+\(Rule\s+\d+\)}g;     # remove productions

    # label states with core LR-0 items
    if ($labelWithCore) { # this is optional
      local $" = "\\n";
      $graph .= qq{$_ [shape = plaintext, label = "$_\\n@LRitems"]\n};
    }

    #warn "LRitems in $_:\n@LRitems\n";

    $desc =~ s/\n\s*\n/\n/g;  # remove white lines

    # build digraph
    # ID  shift, and go to state 4
    while ($desc =~ m{\t(.*)\s+shift,\s+and\s+go\s+to\s+state\s+(\d+)}gx) {
      my ($label, $state)  = ($1, $2);
      $label =~ s/\\(?!")/\\\\/g;
      $graph .=  qq{$_ -> $state [label = "$label"]\n};
    }

    # decl    go to state 1
    while ($desc =~ m{\t(\S+)\s+go\s+to\s+state\s+(\d+)}gx) {
      $graph .=  qq{$_ -> $2 [label = "$1", arrowhead = odot, color = "red", fontcolor = "red"]\n};
    }

    # $default	reduce using rule 1 (prog)
    # ID	reduce using rule 15 (decORexp_explorer)
    while ($desc =~ m{\t(\S+)\s+reduce\s+using\s+rule\s+(\d+)}gx) {
      $graph .=  qq{$_ -> "$grammar{$2}" [label = "$1", arrowhead=dot, color = "blue", fontcolor = "blue"]\n};
    }

    # shift-reduce conflicts
    # ';'	[reduce using rule 4 (ds)]
    while ($desc =~ m{\t(\S+)\s+\[\s*reduce\s+using\s+rule\s+(\d+)}gx) {
      $graph .=  
        qq{$_ -> "$grammar{$2}" [label = "$1", arrowhead=dot, style=dotted, color = "orange", fontcolor = "orange"]\n};
    }

    # $default    accept
    if ($desc =~ m{\t\$default\s+accept\s*}gx) {
      $graph .=  qq{$_ [shape = doublecircle]\n};
      $graph .=  qq{$_ -> "$grammar{0}" [arrowhead = dot, color = blue]\n};
    }

    #warn "$_ => $desc\n";
    
  }
  return <<"EOGRAPH";
digraph G {
concentrate = true

$graph
}
EOGRAPH
}

1;

