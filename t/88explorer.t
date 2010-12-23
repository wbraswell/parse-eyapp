#!/usr/bin/perl -w
use strict;
my ($nt, $nt2, $nt3, $nt4, $nt5, $nt6, $nt7, $nt8, $nt9);

BEGIN { $nt2 = 7; $nt3 = 7; $nt4 = 6; $nt6 = 6; $nt7 = 6; 
}
use Test::More tests=> $nt2+$nt3+$nt4+$nt6+$nt7;

SKIP: {
  skip "t/noPackratSolvedExpRGconcept.eyp not found", $nt2 unless ($ENV{DEVELOPER}
                                                        && -r "t/noPackratSolvedExpRGconcept.eyp"
                                                        && -r "t/ExpList2.eyp"
                                                        #&& $^V ge v5.10.0
                                                        && -x "./eyapp");

  unlink 't/ppcr.pl';

  my $r = system(q{perl -I./lib/ eyapp  -Po t/ExpList2.pm t/ExpList2.eyp});
  ok(!$r, "Auxiliary grammar ExpList2.yp compiled witn -P option");

  $r = system(q{perl -I./lib/ eyapp -TC -o t/ppcr.pl t/noPackratSolvedExpRGconcept.eyp 2> t/err});
  ok(!$r, "S->xSx|x grammar compiled");
  like(qx{cat t/err},qr{1 shift/reduce conflict},"number of conflicts eq 1");

  ok(-s "t/ppcr.pl", "modulino ppcr exists");

  ok(-x "t/ppcr.pl", "modulino has execution permits");

  eval {

    $r = qx{perl -Ilib -It t/ppcr.pl -t -i -m 1 -c '2-3 3*4 5+2' 2>&1};

  };

  ok(!$@,'t/noPackratSolvedExpRGconcept.eyp executed as modulino');

  my $expected = q{
Reducing by :MIDx

T_is_isInTheMiddleExplorer_S(
  S_is_x_S_x(
    x_is_x_OP_NUM(
      x_is_NUM(
        TERMINAL[2]
      ),
      TERMINAL[-],
      TERMINAL[3]
    ),
    S_is_x(
      x_is_x_OP_NUM(
        x_is_NUM(
          TERMINAL[3]
        ),
        TERMINAL[*],
        TERMINAL[4]
      )
    ),
    x_is_x_OP_NUM(
      x_is_NUM(
        TERMINAL[5]
      ),
      TERMINAL[+],
      TERMINAL[2]
    )
  )
)

};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "2-3 3*4 5+2"');

  unlink 't/ppcr.pl';
  unlink 't/ExpList2.pm';

}

SKIP: {
  skip "t/reuseconflicthandler2.eyp not found", $nt3 unless ($ENV{DEVELOPER}
                                                        && -r "t/reuseconflicthandler2.eyp"
                                                        && -r "t/ExpList2.eyp"
                                                        #&& $^V ge v5.10.0
                                                        && -x "./eyapp");

  unlink 't/ppcr.pl';

  my $r = system(q{perl -I./lib/ eyapp  -Po t/ExpList2.pm t/ExpList2.eyp});
  ok(!$r, "Auxiliary grammar ExpList2.yp compiled witn -P option");

  $r = system(q{perl -I./lib/ eyapp -TC -o t/ppcr.pl t/reuseconflicthandler2.eyp 2> t/err});
  ok(!$r, "S->xSx|x grammar compiled");
  like(qx{cat t/err},qr{1 shift/reduce conflict},"number of conflicts eq 1");

  ok(-s "t/ppcr.pl", "modulino ppcr exists");

  ok(-x "t/ppcr.pl", "modulino has execution permits");

  eval {

    $r = qx{perl -Ilib -It t/ppcr.pl -t -i -m 1 -c '2; 1 2+2 3-5;' 2>&1};

  };

  ok(!$@,'t/t/reuseconflicthandler2.eyp executed as modulino');

  my $expected = q{
Reducing by :MIDx input = ' 1 2+2 3-5;'
Reducing by :MIDx input = '-5;'

T_is_isInTheMiddleExplorer_S_isInTheMiddleExplorer_S(
  S_is_x(
    x_is_NUM(
      TERMINAL[2]
    )
  ),
  S_is_x_S_x(
    x_is_NUM(
      TERMINAL[1]
    ),
    S_is_x(
      x_is_x_OP_NUM(
        x_is_NUM(
          TERMINAL[2]
        ),
        TERMINAL[+],
        TERMINAL[2]
      )
    ),
    x_is_x_OP_NUM(
      x_is_NUM(
        TERMINAL[3]
      ),
      TERMINAL[-],
      TERMINAL[5]
    )
  )
)

};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "2; 1 2+2 3-5;"');

  unlink 't/ppcr.pl';
  unlink 't/ExpList2.pm';

}

SKIP: {
  skip "t/reducereduceconflictPPCR.eyp not found", $nt4 unless ($ENV{DEVELOPER} 
                                                        && -r "t/reducereduceconflictPPCR.eyp"
                                                        && -x "./eyapp");

  unlink 't/ppcr.pl';

  my $r = system(q{perl -I./lib/ eyapp -TC -o t/ppcr.pl t/reducereduceconflictPPCR.eyp 2> t/err});
  ok(!$r, "t/reducereduceconflictPPCR.eyp grammar compiled");
  like(qx{cat t/err},qr{1 reduce/reduce conflict},"number of conflicts eq 1");

  ok(-s "t/ppcr.pl", "modulino ppcr exists");

  ok(-x "t/ppcr.pl", "modulino has execution permits");

  eval {

    $r = qx{perl -Ilib -It t/ppcr.pl  -t -i -m 1 -c 'a,b:c d:e,' 2>&1};

  };

  ok(!$@,'t/reducereduceconflictPPCR.eyp executed as modulino');

  my $expected = q{

def_is_paramSpec_ToNExplorer_returnSpec(
  paramSpec_is_nameList_type(
    nameList_is_name_nameList(
      NAME(
        TERMINAL[a]
      ),
      nameList_is_name(
        NAME(
          TERMINAL[b]
        )
      )
    ),
    TYPE(
      TERMINAL[c]
    )
  ),
  returnSpec_is_name_type(
    NAME(
      TERMINAL[d]
    ),
    TYPE(
      TERMINAL[e]
    )
  )
)

};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "a,b:c d:e,"');

  unlink 't/ppcr.pl';

}

SKIP: {
  skip "t/DebugDynamicResolution.eyp not found", $nt6 unless ($ENV{DEVELOPER} 
                                                        && -r "t/DebugDynamicResolution.eyp"
                                                        && -x "./eyapp");

  unlink 't/ppcr.pl';

  my $r = system(q{perl -I./lib/ eyapp -C -o t/ppcr.pl t/DebugDynamicResolution.eyp 2> t/err});
  ok(!$r, "t/DebugDynamicResolution.eyp grammar compiled");
  like(qx{cat t/err},qr{1 shift/reduce conflict},"number of conflicts eq 1");

  ok(-s "t/ppcr.pl", "modulino ppcr exists");

  ok(-x "t/ppcr.pl", "modulino has execution permits");

  eval {

    $r = qx{perl -Ilib -It t/ppcr.pl -t -i -c 'D;D;S;S' 2>&1};

  };

  ok(!$@,'t/DebugDynamicResolution.eyp executed as modulino');

  my $expected = q{
PROG(D(D),SS(S))
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "D;D;S;S"');

  unlink 't/ppcr.pl';

}

SKIP: {
  skip "t/dynamicgrammar1.eyp not found", $nt7 unless ($ENV{DEVELOPER} 
                                                        && -r "t/dynamicgrammar1.eyp"
                                                        && -r "t/input_for_dynamicgrammar.txt"
                                                        && -x "./eyapp");

  unlink 't/ppcr.pl';

  my $r = system(q{perl -I./lib/ eyapp -C -o t/ppcr.pl t/dynamicgrammar1.eyp 2> t/err});
  ok(!$r, "t/dynamicgrammar1.eyp grammar compiled");
  like(qx{cat t/err},qr{^$},"no warning: %expect-rr 1");

  ok(-s "t/ppcr.pl", "modulino ppcr exists");

  ok(-x "t/ppcr.pl", "modulino has execution permits");

  eval {

    $r = qx{perl -Ilib -It t/ppcr.pl -f t/input_for_dynamicgrammar.txt 2>&1};

  };  

  ok(!$@,'t/dynamicgrammar1.eyp executed as modulino');

  my $expected = q{
0
2
1
3
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "int (x) + 2; int (z) = 4;"');

  unlink 't/ppcr.pl';

}


