#!/usr/bin/perl -w

BEGIN { unshift @INC, '/home/lhp/Lperl/src/yapp/Parse-Yapp-Auto/lib/' }
use Autoaction1;

$parser = new Autoaction1();
$parser->Run;
