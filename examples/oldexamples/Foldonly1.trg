foldtimes: TIMES(NUM($n), NUM($m)) and {1;}
  => { 
    $n->{attr} = $n->{attr} * $m->{attr};
    $_[0] = $NUM[0]; 
  }

