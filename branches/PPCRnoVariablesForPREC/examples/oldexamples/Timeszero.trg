/* Operator "and" has higher priority than comma "," */
whatever_times_zero: TIMES(@b, NUM($x) and { $x->{attr} == 0 }) => { $_[0] = $NUM }

