#!/usr/local/bin/perl -w
package Tutu;
use Parse::Eyapp::Base qw(:all);

sub tutu { 
  print "Inside tutu\n" 
}

sub plim {

  # When the stack is empty the old 'tutu' remains ...
  pop_method('tutu');

  &tutu(); 

  push_method('tutu'); # Tutu dissapears
}

package main;

Tutu::plim();
print "Can't tutu\n" unless Tutu->can('tutu');
Tutu::plim();
