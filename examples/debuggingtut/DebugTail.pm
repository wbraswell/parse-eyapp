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
	die "Syntax error near $what line num $tokenline\n";
};

sub Error {
  my $self = shift;

  $_Error = shift if @_;

  $_Error;
}

sub Run {
	my ($self) = shift;
	my $input = shift;

  my $_Lexer = sub {
	
    for ($input) {
        s{^(\s+)}{} and $tokenline += $1 =~ tr{\n}{};
        return ('',undef) unless $_;
        return ($1,$1) if s/^(.)//;
    }
    return ('',undef);
  };
	
	return $self->YYParse( yylex => $_Lexer, yyerror => $_Error,
                         yydebug => 0xF
  );
}

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
  my $input = <$f>;
  return $input;
}

sub main {
  my $class = shift;

  my $input = slurp_file( shift(@ARGV) );

  my $parser = $class->new();

  $parser->Run($input);
}

1;
