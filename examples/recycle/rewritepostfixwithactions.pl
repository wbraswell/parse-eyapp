#!/usr/bin/perl 
use warnings;
use PostfixWithActions;

my $debug = shift || 0;
my $pparser = PostfixWithActions->new();
print "Write an expression: "; 
my $x = <STDIN>;

# First, translate to postfix ...
$pparser->Run($debug, $x);

exit(1) if $pparser->YYNberr;

# And then selectively substitute 
# some semantic actions
# to obtain an infix calculator ...

my %s;
$pparser->YYSetaction(
  'OP:ASSIGN'   => sub { $s{$_[1]} = $_[3] },
  'OP:PLUS'     => sub { $_[1] + $_[3] },
  'OP:TIMES'    => sub { $_[1] * $_[3] },
  'OP:DIV'      => sub { $_[1] / $_[3] },
  'OP:NEG'      => sub { -$_[2] },
);

$pparser->Run($debug, $x);

# Let su reuse the grammar a third time.
# Now we use it to generate the AST
my $buildtree = \&Parse::Eyapp::Driver::YYBuildAST;
$pparser->YYSetaction(
  'EXP'           => sub { $_[1] }, # bypass 
  'OPERAND:NUM'   => $buildtree,
  'OPERAND:VAR'   => $buildtree,
  'OP:ASSIGN'     => $buildtree,
  'OP:PLUS'       => $buildtree,
  'OP:TIMES'      => $buildtree,
  'OP:DIV'        => $buildtree,
  'OP:NEG'        => $buildtree,
);

my $t = $pparser->Run($debug, $x);
print $t->str."\n";

package TERMINAL;
sub info { $_[0]{attr} };
