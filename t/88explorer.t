#!/usr/bin/perl -w
use strict;
my ($nt, $nt2, $nt3, $nt4, $nt5, $nt6);

BEGIN { $nt = 8; $nt2 = 7; $nt3 = 7; $nt4 = 6; $nt5 = 7; $nt6 = 6;
}
use Test::More tests=> $nt+$nt2+$nt3+$nt4+$nt5+$nt6;

# test -S option and PPCR methodology with Pascal range versus enumerated conflict
SKIP: {
  skip "t/pascalnestedeyapp3_5.eyp not found", $nt unless ($ENV{DEVELOPER}
                                                        && -r "t/pascalnestedeyapp3_5.eyp"
                                                        && -x "./eyapp");

  unlink 't/ppcr.pl';

  my $r = system(q{perl -I./lib/ eyapp  -P -S range t/pascalnestedeyapp3_5.eyp 2>&1});
  ok(!$r, "pascalnestedeyapp3_5.eyp compiled with options '-S range' and -P");

  $r = system(q{perl -I./lib/ eyapp -TC -o t/ppcr.pl t/pascalnestedeyapp3_5.eyp});
  ok(!$r, "Pascal conflict grammar compiled");

  ok(-s "t/ppcr.pl", "modulino ppcr exists");

  ok(-x "t/ppcr.pl", "modulino has execution permits");

  eval {

    $r = qx{perl -Ilib -It t/ppcr.pl -t -i -m 1 -c 'type e = (x, y, z);'};

  };

  ok(!$@,'t/pascalnestedeyapp3_5.eyp executed as modulino');

  my $expected = q{

typeDecl_is_type_ID_type(
  TERMINAL[e],
  ENUM(
    idList_is_idList_ID(
      idList_is_idList_ID(
        ID(
          TERMINAL[x]
        ),
        TERMINAL[y]
      ),
      TERMINAL[z]
    )
  )
)

};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "type e = (x, y, z);"');

  ############################
  eval {

    $r = qx{perl -Ilib -It t/ppcr.pl -t -i -m 1 -c 'type e = (x) .. (y);'};

  };

  ok(!$@,'t/pascalnestedeyapp3_5.eyp executed as modulino');

  $expected = q{

typeDecl_is_type_ID_type(
  TERMINAL[e],
  RANGE(
    range_is_expr_expr(
      ID(
        TERMINAL[x]
      ),
      ID(
        TERMINAL[y]
      )
    )
  )
)

};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "type e = (x) .. (y);"');

  unlink 't/ppcr.pl';
  unlink 'range.pm';
}

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



# testing PPCR and -S option with CplusplusNested.eyp
# testing nested parsing (YYPreParse) when one token 
# has been read by the outer parser
SKIP: {
  skip "t/CplusplusNested3.eyp not found", $nt5 unless ($ENV{DEVELOPER} 
                                                        && -r "t/CplusplusNested3.eyp"
                                                        && -x "./eyapp");

  unlink 't/ppcr.pl';

  my $r = system(q{perl -I./lib/ eyapp  -PS decl t/CplusplusNested3.eyp});
  ok(!$r, "Auxiliary grammar decl.pm gnerated with '-PS decl' option");

  $r = system(q{perl -I./lib/ eyapp -C -o t/ppcr.pl t/CplusplusNested3.eyp 2> t/err});
  ok(!$r, "t/CplusplusNested3.eyp grammar compiled");
  like(qx{cat t/err},qr{^$},"no warning: %expect-rr 1");

  ok(-s "t/ppcr.pl", "modulino ppcr exists");

  ok(-x "t/ppcr.pl", "modulino has execution permits");

  eval {

    $r = qx{perl -Ilib -It t/ppcr.pl -t -i -c 'int (x) + 2; int (z) = 4;' 2>&1};

  };

  ok(!$@,'t/CplusplusNested3.eyp executed as modulino');

  my $expected = q{
PROG(PROG(EMPTY,EXP(TYPECAST(TERMINAL[int],ID[x]),NUM[2])),DECL(TERMINAL[int],ID[z],NUM[4]))
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "int (x) + 2; int (z) = 4;"');

  unlink 't/ppcr.pl';
  unlink 'decl.pm';

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

