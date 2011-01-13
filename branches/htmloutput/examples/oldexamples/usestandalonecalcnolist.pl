#!/usr/bin/perl -w
use strict;
use Calcnolist;

my $parser = Calcnolist->new();
my $input = <<'EOI';
a = 2*3
EOI
my $t = $parser->Run(\$input);
print "========= Symbol Table ==============\n";
print "$_ = $t->{$_}\n" for sort keys %$t;
