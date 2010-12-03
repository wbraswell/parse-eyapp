#!/usr/bin/perl -w
use strict;
my ($nt, );

BEGIN { $nt = 6; 
}
use Test::More tests=> $nt;

# test grammar.dot graphic description of .output and AST .dot files
SKIP: {
  skip "t/AmbiguousCalc.eyp not found", $nt unless ($ENV{DEVELOPER} 
                                                        && -r "t/AmbiguousCalc.eyp" 
                                                        && -r "t/AmbiguousCalc.wexpected" 
                                                        && -r "t/AmbiguousCalc.Wexpected" 
                                                        && -x "./eyapp");
  { # test -w
    unlink 't/AmbiguousCalc.pm';
    unlink 't/AmbiguousCalc.output';
    unlink 't/AmbiguousCalc.dot';
    unlink 't/AmbiguousCalc.png';

    my $r = qx{perl -I./lib/ eyapp -w t/AmbiguousCalc.eyp 2>&1};
    like($r, qr{35 shift.reduce conflicts}, "compilation with -w of ambiguous Calc grammar");

    ok(-s "t/AmbiguousCalc.dot", "AmbiguousCalc.dot generated");

    $r = qx{diff t/AmbiguousCalc.dot t/AmbiguousCalc.wexpected};

    is($r, '', '.dot file as expected with w');

    unlink 't/AmbiguousCalc.pm';
    unlink 't/AmbiguousCalc.output';
    unlink 't/AmbiguousCalc.dot';
    unlink 't/AmbiguousCalc.png';
  }

  { # test -W

    my $r = qx{perl -I./lib/ eyapp -W t/AmbiguousCalc.eyp 2>&1};
    like($r, qr{35 shift.reduce conflicts}, "compilation with -w of ambiguous Calc grammar");

    ok(-s "t/AmbiguousCalc.dot", "AmbiguousCalc.dot generated");

    $r = qx{diff t/AmbiguousCalc.dot t/AmbiguousCalc.WWexpected};

    is($r, '', '.dot file as expected with W');

    unlink 't/AmbiguousCalc.pm';
    unlink 't/AmbiguousCalc.output';
    unlink 't/AmbiguousCalc.dot';
    unlink 't/AmbiguousCalc.png';
  }
}
