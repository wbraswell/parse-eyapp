{
my %Op = (PLUS=>'+', MINUS => '-', TIMES=>'*', DIV => '/');
}

fold: /TIMES|PLUS|DIV|MINUS/:bin(NUM($n), NUM($m)) 
  => { 
    my $op = $Op{ref($bin)};
    $n->{attr} = eval  "$n->{attr} $op $m->{attr}";
    $_[0] = $NUM[0]; 
  }
zero_times_whatever: TIMES(NUM($x), .) and { $x->{attr} == 0 } => { $_[0] = $NUM }
whatever_times_zero: TIMES(., NUM($x)) and { $x->{attr} == 0 } => { $_[0] = $NUM }

