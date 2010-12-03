#!/usr/bin/perl -w
use strict;
my ($nt, );

BEGIN { $nt = 5; 
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

    my $r = system(q{perl -I./lib/ eyapp -w t/AmbiguousCalc.eyp});
    ok(!$r, "compilation with -w of ambigous Calc grammar");

    ok(-s "t/AmbiguousCalc.dot", "AmbiguousCalc.dot generated");

    $r = qx{diff t/AmbiguousCalc.dot t/AmbiguousCalc.wexpected};

    is($r, '', '.dot file as expected');

    unlink 't/AmbiguousCalc.pm';
    unlink 't/AmbiguousCalc.output';
    unlink 't/AmbiguousCalc.dot';
    unlink 't/AmbiguousCalc.png';
  }

  { # test -W
    unlink 't/AmbiguousCalc.pm';
    unlink 't/AmbiguousCalc.output';
    unlink 't/AmbiguousCalc.dot';
    unlink 't/AmbiguousCalc.png';

    my $r = system(q{perl -I./lib/ eyapp -W t/AmbiguousCalc.eyp});
    ok(!$r, "compilation with -w of ambigous Calc grammar");

    ok(-s "t/AmbiguousCalc.dot", "AmbiguousCalc.dot generated");

    $r = qx{diff t/AmbiguousCalc.dot t/AmbiguousCalc.Wexpected};

    is($r, '', '.dot file as expected');

    unlink 't/AmbiguousCalc.pm';
    unlink 't/AmbiguousCalc.output';
    unlink 't/AmbiguousCalc.dot';
    unlink 't/AmbiguousCalc.png';
  }
}

