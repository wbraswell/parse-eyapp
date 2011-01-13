
{ 
my %x = (PLUS=>'+', MINUS => '-', TIMES=>'*', DIV => '/');
}

constantfold: /TIMES|PLUS|DIV|MINUS/:bin(NUM($left), NUM($right)) 
  => { 
    my $x = $x{ref($bin)};
    $left->{attr} = eval  "$left->{attr} $x $right->{attr}";
    $_[0] = $NUM[0]; 
  }
zero_times: TIMES(NUM(TERMINAL), .) and { $TERMINAL->{attr} == 0 } => { $_[0] = $NUM }
times_zero: TIMES(., NUM(TERMINAL)) and { $TERMINAL->{attr} == 0 } => { $_[0] = $NUM }
