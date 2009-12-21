package Parse::Eyapp::TailSupport;
use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use Scalar::Util qw{blessed};
use Carp;

sub line {
  my $self = shift;

  if (ref($self)) {
    $self->{tokenline} = shift if @_;
    return $self->{tokenline};
  }

  # Called as a class method: static
  my $classtokenline = $self.'::tokenline';
  ${$classtokenline} = shift if @_;
  return ${$classtokenline};
}

sub error {
  my $self = shift;

  if (ref $self) { # instance method
    $self->{ERROR} = shift if @_;

    $self->{ERROR}
  }
  else { # class/static method
    no strict 'refs';
    my $classerror = $self.'::ERROR';
    ${$classerror} = shift if @_;

    ${$classerror};
  }
}

# attribute with the lexical analyzer
# has this value by default
#= sub {
#  croak "Error: lexical analizer not defined";
#};

# attribute with the input
# is a reference to the actual input
# slurp_file. 
# Parameters: object or class, filename, prompt messagge, mode (interactive or not: undef or "\n")
sub slurp_file {
  my $self = shift;
  my $fn = shift;
  my $f;

  my $mode = undef;
  if ($fn && -r $fn) {
    open $f, $fn  or die "Can't find file '$fn'!\n";
  }
  else {
    $f = \*STDIN;
    my $msg = shift;
    $mode = shift;
    print($msg) if $msg;
  }

  local $/ = $mode;
  my $input = <$f>;

  if (ref($self)) {  # called as object method
    $self->{input} = \$input;
  }
  else { # class/static method
    my $classinput = $self.'::input';
    ${$classinput} = \$input;
  }
}

sub input {
  my $self = shift;

  no strict 'refs';
  if (@_) { # used as setter. Passing ref
    $self->line(1);
    if (ref($self)) { # object method
      $self->{input} = shift;

      return $self->{input};
    }
    # Static method passing string
    ${$self.'::input'} = shift();

    return ${$self.'::input'};
  }
  return $self->{input} if ref $self;
  return ${$self.'::input'};
}

# args: parser, debug and optionally the input or a reference to the input
sub Run {
  my ($self) = shift;
  my $yydebug = shift;
  
  unless ($self->input && defined(${$self->input()}) && ${$self->input()} ne '') {
    croak "Provide some input for parsing" unless defined($_[0]);
    if (ref($_[0])) { # if arg is a reference
      $self->input(shift());
    }
    else { # arg isn't a ref: make a copy
      my $x = shift();
      $self->input(\$x);
    }
  }
  return $self->YYParse( 
    #yylex => $self->lexer(), 
    #yyerror => $self->error(),
    yydebug => $yydebug, # 0xF
  );
}

# args: class, prompt, file, optionally input (ref or not)
# return the abstract syntax tree (or whatever was returned by the parser)
sub main {
  my $package = shift;
  my $prompt = shift;

  my $debug = 0;
  my $file = '';
  my $showtree = 0;
  my $TERMINALinfo = '';
  my $help;
  my $slurp;
  my $inputfromfile = 1;
  my $commandinput = '';
  my $result = GetOptions (
    "debug!"         => \$debug,         # sets yydebug on
    "file=s"         => \$file,          # read input from that file
    "commandinput=s" => \$commandinput,  # read input from command line arg
    "tree!"          => \$showtree,      # prints $tree->str
    "info=s"         => \$TERMINALinfo,  # prints $tree->str and provides default TERMINAL::info
    "help"           => \$help,          # shows SYNOPSIS section from the script pod
    "slurp!"         => \$slurp,         # read until EOF or CR is reached
    "inputfromfile!" => \$inputfromfile, # take input from @_
  );

  pod2usage() if $help;

  $debug = 0x1F if $debug;
  $file = shift if !$file && @ARGV; 
  $slurp = "\n" if defined($slurp);
  if (defined($TERMINALinfo)) {
    $showtree = 1;
    no warnings 'redefine';
    no strict 'refs';
    if ($TERMINALinfo eq '') {
      *TERMINAL::info = sub { $_[0]->attr; }
    }
    elsif ($TERMINALinfo eq 'line') {
      *TERMINAL::info = sub { $_[0]->attr->[0 ]};
    }
    else {
      $TERMINALinfo = "sub { my \$self = shift; $TERMINALinfo }" unless ($TERMINALinfo =~ /^\s*sub/);
      eval {
        *TERMINAL::info = eval $TERMINALinfo;
      };
      croak "Argument '$TERMINALinfo' isn't legal: try 'line' or '' instead\n($)\n" if $@;
    }
  }

  my $parser = $package->new();

  if ($commandinput) {
    $parser->input(\$commandinput);
  }
  elsif ($inputfromfile) {
    $parser->slurp_file( $file, $prompt, $slurp);
  }
  else { # input must be a string argument
    croak "No input provided for parsing! " unless defined($_[0]);
    if (ref($_[0])) {
      $parser->input(shift());
    }
    else {
      my $x = shift();
      $parser->input(\$x);
    }
  }

  my $tree = $parser->Run( $debug, @_ );

  if (my $ne = $parser->YYNberr > 0) {
    print "There were $ne errors during parsing\n";
  }
  else {
    print $tree->str()."\n" if $showtree && $tree && blessed $tree && $tree->isa('Parse::Eyapp::Node');
  }

  $tree
}

1;

