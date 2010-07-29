#!/usr/bin/env perl
use strict;
use warnings;
use Range;

my $parser = Range->new();
$parser->YYPrompt(<<'EOM');
Try one of these inputs:

                (x) .. (y);
                (x) ..  y ;
                (x+2)*3 ..  y/2 ;
                (x, y, z);
                (x);
                (x, y, z) .. (u+v);

EOM
$parser->slurp_file('', "\n");
my $t = $parser->Run;
if ($parser->YYNberr) {
  print "There were errors\n";
} else {
  print "***********\n",$t->str,"\n";
}

