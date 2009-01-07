package TokenGen;
use strict;
use warnings;

use Getopt::Long;
use List::Util qw{first};
use Test::LectroTest::Generator qw(:common Gen);

sub _Error {
  my $parser = shift;
  my $yydata = $parser->YYData;

    exists $yydata->{ERRMSG}
  and do {
      warn $yydata->{ERRMSG};
      delete $yydata->{ERRMSG};
      return;
  };
  my($token)=$parser->YYCurval;
  my($what)= $token->[0] ? "input: '$token->[0]'" : "end of input";
  my @expected = $parser->YYExpect();
  my $next = substr($parser->{input}, pos($parser->{input}), 5);
  local $" = ', ';
  warn << "ERRMSG";

Syntax error near $what (lin num $token->[1]). 
Incoming text: 
===
$next
===
Expected one of these terminals: @expected
ERRMSG
}


{ # closure

  sub Parse::Eyapp::Driver::YYEXPECT {
    my($self)=shift;

    my $state = $self->{STATES}[$self->{STACK}[-1][0]];
    my @expected = keys %{$state->{ACTIONS}};
    unshift(@expected, '') if defined($state->{DEFAULT});
    return @expected;
  }

  my $WHITESPACES = String( length=>[0,1], charset=>" \t\n", size => 100 );

  my %tokengen = (
     NUM         => Int(range=>[0, 128], sized=>0),
     VAR         => String( length=>[1,2], charset=>"A-Z", size => 100 ),
  );

  my $numtokens = 0;

  sub gen_lexer {
    my $parser = shift;

    my @token = $parser->YYEXPECT;
    # Terminate asap
    return ('', '') if ($token[0] eq '') && ($numtokens > 6);

    my $tokengen = Elements(@token);

    my $token = $tokengen->generate;

    my $attr = exists($tokengen{$token})? $tokengen{$token}->generate : $token;
    $attr = $WHITESPACES->generate.$attr;
    print "NEXT: <$token, $attr>\n";
    $numtokens++;
    return ($token, $attr);
  }

} # closure

sub Run {
    my($self)=shift;
    my $yydebug = shift || 0;

    return $self->YYParse( 
      yylex => \&gen_lexer, 
      yyerror => \&_Error,
      yydebug => $yydebug, # 0x1F
    );
}

sub main {
  my $package = shift;

  my $debug = shift || 0;
  my $result = GetOptions (
    "debug!" => \$debug,  
  );

  $debug = 0x1F if $debug;

  my $parser = $package->new();
  $parser->Run( $debug );
}

sub semantic_error {
  my ($parser, $msg) = @_;

  $parser->YYData->{ERRMSG} = $msg;
  $parser->YYError; 
}

1;
