#!/usr/bin/perl -w
use strict;
use Test::More tests=>5;
#use_ok qw(Parse::Eyapp) or exit;

SKIP: {
  skip "t/dynamicresolution/pascalenumeratedvsrangesolvedviadyn.eyp not found", 5 unless ($ENV{DEVELOPER} && -r "t/dynamicresolution/pascalenumeratedvsrangesolvedviadyn.eyp" && -x "./eyapp");

  unlink 't/Calc.pm';

  my $r = system(q{perl -I./lib/ eyapp -b '' -s -o t/dynamicresolution/persvd.pl t/dynamicresolution/pascalenumeratedvsrangesolvedviadyn.eyp});
  
  ok(!$r, "standalone option");

  ok(-s "t/dynamicresolution/persvd.pl", "modulino standalone exists");
  ok(-x "t/dynamicresolution/persvd.pl", "modulino standalone has execution permits");

  my $eyapppath;
  eval {
    local $ENV{PERL5LIB};
    $eyapppath = shift @INC; # Supress ~/LEyapp/lib from search path

    $r = qx{t/dynamicresolution/persvd.pl -t -c 'type r = (x+2)*3 ..  y/2 ;'};
  };

  ok(!$@,'pascalenumeratedvsrangesolvedviadyn executed as standalone modulino');

  my $expected = qr{type_decl_is_TYPE_ID_type\(\s+TERMINAL,\s+TERMINAL,\s+RANGE\(\s+expr_is_expr_TIMES_expr\(\s+expr_is_LP_expr_RP\(\s+expr_is_expr_PLUS_expr\(\s+ID\(\s+TERMINAL\s+\),\s+expr_is_NUM\(\s+TERMINAL\s+\)\s+\)\s+\),\s+expr_is_NUM\(\s+TERMINAL\s+\)\s+\),\s+TERMINAL,\s+expr_is_expr_DIV_expr\(\s+ID\(\s+TERMINAL\s+\),\s+expr_is_NUM\(\s+TERMINAL\s+\)\s+\)\s+\)\s+\)\s+};

  like($r, $expected,'AST for pascalenumeratedvsrangesolvedviadyn');

  unlink 't/dynamicresolution/persvd.pl';

}

