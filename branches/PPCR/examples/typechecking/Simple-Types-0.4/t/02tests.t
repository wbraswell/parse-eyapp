#!/usr/bin/perl -w
use strict;
my ($nt, $nt2, $nt3, $nt4, $nt5, $nt6);

BEGIN { $nt = 2; 
}
use Test::More tests=> $nt;

# test -S option and PPCR methodology with Pascal range versus enumerated conflict
SKIP: {
  skip "t/prueba01.c not found", $nt unless ($ENV{DEVELOPER} 
                                                        && -r "t/prueba01.c" 
                                                        && -x "./script/usetypes.pl");

  unlink 't/ppcr.pl';

  my $r = qx{perl -I./lib/ script/usetypes.pl script/prueba02.c 2>&1};

  ok(!$@,'t/prueba01.c executed as modulino');

  my $expected = q{
Type Error at line 8:  Variable 'e' declared with less than 2 dimensions
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'checking output for prueba01.c');

  ############################
}

