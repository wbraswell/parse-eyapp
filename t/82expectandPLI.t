#!/usr/bin/perl -w
use strict;
my ($nt, );

BEGIN { $nt = 8; 
}
use Test::More tests=> $nt;

# test "expects" method with PL-I if if=then then then=if example
SKIP: {
  skip "t/PL_I_conflictNested.eyp not found", $nt unless ($ENV{DEVELOPER} 
                                                        && -r "t/PL_I_conflictNested.eyp" 
                                                        && -r "t/Assign.eyp" 
                                                        && -x "./eyapp");

  unlink 't/pl1.pl';

  my $r = system(q{perl -I./lib/ eyapp  -Po t/Assign.pm t/Assign.eyp});
  ok(!$r, "Auxiliary grammar Assign.yp compiled with option -P");

  $r = system(q{perl -I./lib/ eyapp -TC -o t/pl1.pl t/PL_I_conflictNested.eyp});
  ok(!$r, "Pascal conflict grammar compiled");

  ok(-s "t/pl1.pl", "modulino pl1 exists");

  ok(-x "t/pl1.pl", "modulino has execution permits");

  eval {

    $r = qx{perl -Ilib -It t/pl1.pl -t -i -m 1 -c ''if if=then then then=if'};

  };

  ok(!$@,'t/PL_I_conflictNested.eyp executed as modulino');

  my $expected = q{

)

};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "type r = (x) .. (y); 4"');

  ############################
  eval {

    $r = qx{perl -Ilib -It t/pl1.pl -t -i -m 1 -c 'type r = (x,y,z); 8'};

  };

  ok(!$@,'t/PL_I_conflictNested.eyp executed as modulino');

  $expected = q{

typeDecl_is_type_ID_type_expr(
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
  ),
  NUM(
    TERMINAL[8]
  )
)

};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "type r = (x,y,z); 8"');

  unlink 't/pl1.pl';
  unlink 't/Assign.pm';

}

