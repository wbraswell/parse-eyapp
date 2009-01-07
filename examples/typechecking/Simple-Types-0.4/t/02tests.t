#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Simple::Types;
use Data::Dumper;

our $test_exception_installed;
BEGIN {
  $test_exception_installed = 1;
  eval { require Test::Exception };
  $test_exception_installed = 0 if $@;
}

my @tests = (
   << "EOICORRECT",
f() {
  int a,b[1][2],c[1][2][3];
  char d[10];
  b[0][1] = a;
}
EOICORRECT
# Duplicated declaration of a at line 2
   << "EOI_TWICE",
f() {
  int a,b[1][2],a[1][2][3];
  char d[10];
  b[0][1] = a;
}
EOI_TWICE
# Duplicated declaration of a at line 3
    << "EOI_TWICE_DIF_DEC",
f() {
  int a,b[1][2],c[1][2][3];
  char d[10], b[9];
  b[0] = a;
}
EOI_TWICE_DIF_DEC

# Correct program. Global and local decs
    << "EOI_GLOBAL_DEC",
int a,b[1][2],c[1][2][3]; 
char d,e[1][2]; 
f() {
  int a,b[1][2],c[1][2][3];
  char d[10], e[9];

  b[0][1] = a;
}
EOI_GLOBAL_DEC
    << "EOI_GLOBAL_DUP",
/* Error: duplicated global dec */
int a,b[1][2],c[1][2][3]; 
char d,a[1][2]; 
f() {
  int a,b[1][2],c[1][2][3];
  char d[10], e[9];

  b[0][1] = a;
}
EOI_GLOBAL_DUP
# Correct program. Parameters
    << "EOI_GLOBAL_PAR",
int a,b[1][2],c[1][2][3]; 
char d,e[1][2]; 
f(int a, char b[10]) {
  int c[1][2][3];
  char d[10], e[9];

  b[0][1] = a;
}
EOI_GLOBAL_PAR
# Correct program. Only global
    << "EOI_GLOBAL",
int a,b[1][2],c[1][2][3]; 
EOI_GLOBAL
# Correct program. Return char and Parameters
    << "EOI_RETURN",
int a,b[1][2],c[1][2][3]; 
char d,e[1][2]; 
char f(int a, char b[10]) {
  int c[1][2];
  char d[10], e[9];

  return b[0];
}
EOI_RETURN
# Correct program. No parameters
    << "EOI_RETURN_NOPAR",
char d,e[1][2]; 
char f() {
  int c[2];
  char d;

  return d;
}
EOI_RETURN_NOPAR
  << "EOIPARAMDECLTWICE",
int a, b[1][2];
char d, e[1][2]; 
char f(int a, char b[10]) {
  int c[1][2];
  char b[10], e[9];

  return b[0];
}
EOIPARAMDECLTWICE
# Correct program. No parameters
    << "EOI_NESTED_BLOCKS",
char d0; 
char f() {
  char d1;
  {
    char d2;
  }
  {
    char d2;
    {
      char d3;

      d3;
    }
  }
  {
    d0;
  }

  return d1;
}
EOI_NESTED_BLOCKS
# Correct program. No parameters
    << "EOI_NESTED_BLOCKS2",
char d0; 
char f() {
  {
    {}
  }
  {
    { }
  }
  {
    {{}}
  }
}
EOI_NESTED_BLOCKS2
    << "EOI_NESTED_BLOCKS3",
char d0; 
char f() {
  {
    {}
  }
  {
    { }
  }
  {
    {{}}
  }
}
g() {
 {}
 {
   {}
 }
 {}
}
EOI_NESTED_BLOCKS3
     <<"EOIUSES_1",
int a,b;

int f(char c) {
 a[2] = 4;
 b[1][3] = a + b;
 c = c[5] * 2;
 return g(c);
}
EOIUSES_1
     <<"EOIUSES_2",
int a,b;

int f(char c) {
 a[2] = 4;
 { 
   int d;
   d = a + b;
 }
 c = d * 2;
 return g(c);
}
EOIUSES_2
     <<"EOICT1",
int a,b,e[20];

int f(char c) {
char d;
 c = 'X';
 a = 'A'+c;
 { 
   int d;
   d = a + b;
 }
 c = d * 2;
 return c;
}
EOICT1
     <<"EOITRIVIAL1",
int f(int a, int b) {
 return a+b;
}
EOITRIVIAL1
     <<"EOICHECKTYPE2",
int a,b,e[10];

g() {}

int f(char c) {
char d;
 c = 'X';
 e[d][b] = 'A'+c;
 { 
   int d;
   d = a + g;
 }
 c = d * 2;
 return c;
}
EOICHECKTYPE2
); # end of @tests

my $c= Simple::Types->new();

for (@tests) {
  our $t;
  print "\n*****************\n$_";
  eval {
    $t = $c->compile($_);
  };
  print "$@\n" if $@;
  $Data::Dumper::Purity = 1;
  $Data::Dumper::Indent = 1;
  #print Dumper($t);
}

