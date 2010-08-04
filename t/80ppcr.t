#!/usr/bin/perl -w
use strict;
my ($nt, $nt2);

BEGIN { $nt = 8; $nt2 = 7; }
use Test::More tests=> $nt+$nt2;

SKIP: {
  skip "t/pascalnestedeyapp2.eyp not found", $nt unless ($ENV{DEVELOPER} 
                                                        && -r "t/pascalnestedeyapp2.eyp" 
                                                        #&& $^V ge v5.10.0
                                                        && -r "t/Range.eyp" 
                                                        && -x "./eyapp");

  unlink 't/ppcr.pl';

  my $r = system(q{perl -I./lib/ eyapp  -o t/Range.pm t/Range.eyp});
  ok(!$r, "Auxiliary grammar Range.yp compiled");

  $r = system(q{perl -I./lib/ eyapp -TC -o t/ppcr.pl t/pascalnestedeyapp2.eyp});
  ok(!$r, "Pascal conflict grammar compiled");

  ok(-s "t/ppcr.pl", "modulino ppcr exists");

  ok(-x "t/ppcr.pl", "modulino has execution permits");

  eval {

    $r = qx{perl -Ilib -It t/ppcr.pl -t -i -m 1 -c 'type r = (x) .. (y);'};

  };

  ok(!$@,'t/pascalnestedeyapp2.eyp executed as modulino');

  my $expected = q{

typeDecl_is_type_ID_type(
  TERMINAL[r],
  RANGE(
    ID(
      TERMINAL[x]
    ),
    ID(
      TERMINAL[y]
    )
  )
)

};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "type r = (x) .. (y);"');

  ############################
  eval {

    $r = qx{perl -Ilib -It t/ppcr.pl -t -i -m 1 -c 'type r = (x,y,z);'};

  };

  ok(!$@,'t/pascalnestedeyapp2.eyp executed as modulino');

  $expected = q{

typeDecl_is_type_ID_type(
  TERMINAL[r],
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


  like($r, $expected,'AST for "type r = (x,y,z);"');

  unlink 't/ppcr.pl';
  unlink 't/Range.pm';

}

SKIP: {
  skip "t/noPackratSolvedExpRG2.eyp not found", $nt2 unless ($ENV{DEVELOPER} 
                                                        && -r "t/pascalnestedeyapp2.eyp" 
                                                        && -r "t/ExpList.eyp" 
                                                        #&& $^V ge v5.10.0
                                                        && -x "./eyapp");

  unlink 't/ppcr.pl';

  my $r = system(q{perl -I./lib/ eyapp  -o t/ExpList.pm t/ExpList.eyp});
  ok(!$r, "Auxiliary grammar ExpList.yp compiled");

  $r = system(q{perl -I./lib/ eyapp -TC -o t/ppcr.pl t/noPackratSolvedExpRG2.eyp 2> t/err});
  ok(!$r, "S->xSx|x grammar compiled");
  like(qx{cat t/err},qr{1 shift/reduce conflict},"number of conflicts eq 1");

  ok(-s "t/ppcr.pl", "modulino ppcr exists");

  ok(-x "t/ppcr.pl", "modulino has execution permits");

  eval {

    $r = qx{perl -Ilib -It t/ppcr.pl -t -i -m 1 -c '2-3 3*4 5+2'};

  };

  ok(!$@,'t/noPackratSolvedExpRG2.eyp executed as modulino');

  my $expected = q{
Number of x's = 1
Reducing by :MIDx

T_is_preproc_S(
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
  unlink 't/ExpList.pm';

}

