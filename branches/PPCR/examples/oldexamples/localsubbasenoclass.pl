#!/usr/local/bin/perl -w
use strict;
use Parse::Eyapp::Base qw(:all);

sub tutu { "tutu" }

sub plim {
  push_method(tutu => sub { "titi" });

  print &tutu()."\n"; # It will print "titi"

  pop_method('tutu');
}

plim();
print &tutu()."\n"; # It will print "tutu"
