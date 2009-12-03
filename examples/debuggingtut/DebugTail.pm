package DebugTail;
use strict;
use warnings;

my $tokenline = 1;

sub tokenline {
  my $self = shift;

  $tokenline += shift if @_;

  $tokenline
}

my $_Error = sub {
  my $parser = shift;

  my ($token) = $parser->YYCurval;
  my ($what) = $token ? "input: '$token'" : "end of input";
  my @expected = $parser->YYExpect();
  local $" = ', ';
  die "Syntax error near $what line num $tokenline. Expecting (@expected)\n";
};

sub error {
  my $self = shift;

  $_Error = shift if @_;

  $_Error;
}

# Default lexer
my $_Lexer = sub {

  for (${input()}) {
      s{^(\s+)}{} and $tokenline += $1 =~ tr{\n}{};
      return ('',undef) unless $_;
      return ($1,$1) if s/^(.)//;
  }
  return ('',undef);
};

sub lexer {
  my $self = shift;

  $_Lexer = shift if @_;

  $_Lexer;
}

sub Run {
  my ($self) = shift;
  
  return $self->YYParse( 
    yylex => $self->lexer(), 
    yyerror => $self->error,
    yydebug => 0xF
  );
}

# Reference to the actual input
my $input;

sub slurp_file {
  my $fn = shift;
  my $f;

  local $/ = undef;
  if (defined($fn)) {
    open $f, $fn  or die "Can't find file $fn!\n";
  }
  else {
    $f = \*STDIN;
  }

  $$input = <$f>;
}

sub input {
  my $self = shift;

  $$input = shift if @_;

  $input;
}

sub main {
  my $class = shift;

  slurp_file( shift(@ARGV) );

  my $parser = $class->new();

  $parser->Run();
}

1;
