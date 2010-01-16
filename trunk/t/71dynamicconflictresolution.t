#!/usr/bin/perl -w
use strict;
my $nt;

BEGIN { $nt = 9 }
use Test::More tests=>$nt;
#use_ok qw(Parse::Eyapp) or exit;

SKIP: {
  skip "t/dynamicresolution/pascalenumeratedvsrangesolvedviadyn.eyp not found", $nt unless ($ENV{DEVELOPER} && ($ENV{DEVELOPER} eq 'casiano') && -r "t/dynamicresolution/pascalenumeratedvsrangesolvedviadyn.eyp" && -x "./eyapp");

  unlink 't/Calc.pm';

  my $r = system(q{perl -I./lib/ eyapp -b '' -s -o t/dynamicresolution/persvd.pl t/dynamicresolution/pascalenumeratedvsrangesolvedviadyn.eyp});
  
  ok(!$r, "standalone option");

  ok(-s "t/dynamicresolution/persvd.pl", "modulino standalone exists");

  ok(-x "t/dynamicresolution/persvd.pl", "modulino standalone has execution permits");

  local $ENV{PERL5LIB};
  my $eyapppath = shift @INC; # Supress ~/LEyapp/lib from search path
  eval {

    $r = qx{t/dynamicresolution/persvd.pl -t -c 'Type r = (x+2)*3 ..  y/2 ;'};
  };

  ok(!$@,'pascalenumeratedvsrangesolvedviadyn executed as standalone modulino');

  my $expected = qr{TypeDecl_is_TYPE_ID_Type\(\s+TERMINAL,\s+TERMINAL,\s+RANGE\(\s+Expr_is_Expr_TIMES_Expr\(\s+Expr_is_LP_Expr_RP\(\s+Expr_is_Expr_PLUS_Expr\(\s+ID\(\s+TERMINAL\s+\),\s+Expr_is_NUM\(\s+TERMINAL\s+\)\s+\)\s+\),\s+Expr_is_NUM\(\s+TERMINAL\s+\)\s+\),\s+TERMINAL,\s+Expr_is_Expr_DIV_Expr\(\s+ID\(\s+TERMINAL\s+\),\s+Expr_is_NUM\(\s+TERMINAL\s+\)\s+\)\s+\)\s+\)\s+};

  like($r, $expected,'AST for Type r = (x+2)*3 ..  y/2 ;');

  eval {
    $r = qx{t/dynamicresolution/persvd.pl -t -c 'Type e = (x, y, z);'};
  };

  ok(!$@,'pascalenumeratedvsrangesolvedviadyn executed as standalone modulino');

  $expected = qr{TypeDecl_is_TYPE_ID_Type\(\s+TERMINAL,\s+TERMINAL,\s+ENUM\(\s+IdList_is_IdList_COMMA_ID\(\s+IdList_is_IdList_COMMA_ID\(\s+ID\(\s+TERMINAL\s+\),\s+TERMINAL\s+\),\s+TERMINAL\s+\)\s+\)\s+\)};

  like($r, $expected,'AST for Type e = (x, y, z);');

  eval {
    $r = qx{t/dynamicresolution/persvd.pl -t -c 'Type e = (x);'};
  };

  ok(!$@,'pascalenumeratedvsrangesolvedviadyn executed as standalone modulino');

  $expected = qr{TypeDecl_is_TYPE_ID_Type\(\s+TERMINAL,\s+TERMINAL,\s+ENUM\(\s+ID\(\s+TERMINAL\s+\)\s+\)\s+\)};

  like($r, $expected,'AST for Type e = (x);');

  unlink 't/dynamicresolution/persvd.pl';

}

