{
my %Op = (PLUS=>'+', MINUS => '-', TIMES=>'*', DIV => '/');
}

fold: /TIMES|PLUS|DIV|MINUS/:bin(NUM($n), NUM($m)) 
  => { 
    my $op = $Op{ref($bin)};
    my $t;
    ($_[0], $t) = Parse::Eyapp::Node->new('NUM(TERMINAL)');
    $t->{attr} = eval  "$n->{attr} $op $m->{attr}";
    1; # return true value
  }
zero_times_whatever: TIMES(NUM($x), .) and { $x->{attr} == 0 } => { $_[0] = $NUM }
whatever_times_zero: TIMES(., NUM($x)) and { $x->{attr} == 0 } => { $_[0] = $NUM }

/* rules related with times */
times_zero = zero_times_whatever whatever_times_zero;

