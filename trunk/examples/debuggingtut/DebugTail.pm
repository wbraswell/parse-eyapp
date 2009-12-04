package DebugTail;
use strict;
use warnings;

# attribute to count the lines
my $tokenline = 1;

sub tokenline {
  my $self = shift;

  $tokenline += shift if @_;

  $tokenline
}

# attribute with the error handler
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

# attribute with the lexical analyzer
# has this value by default
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

# attribute with the input
# is a reference to the actual input
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
    my $msg = shift;
    print($msg;) if $msg;
  }

  $$input = <$f>;
}

sub input {
  my $self = shift;

  $$input = shift if @_;

  $input;
}

sub Run {
  my ($self) = shift;
  my $yydebug = shift;
  
  return $self->YYParse( 
    yylex => $self->lexer(), 
    yyerror => $self->error,
    yydebug => $yydebug, # 0xF
  );
}

sub main {
  my $package = shift;
  my $prompt = shift;

  my $debug = 0;
  my $file = '';
  my $help;
  my $result = GetOptions (
    "debug!" => \$debug,  
    "file=s" => \$file,
    "help"   => \$help,
  );

  pod2usage() if $help;

  $debug = 0x1F if $debug;
  $file = shift if !$file && @ARGV; 

  slurp_file( $file, $prompt);

  my $parser = $package->new();
  $parser->Run( $input, $debug );
}

1;
