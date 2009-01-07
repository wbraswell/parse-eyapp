package TokenGen2;
use strict;
use warnings;

use Getopt::Long;
use Test::LectroTest::Generator qw(:common Gen);

sub _Error {
  die "Error!";
}



#my $WHITESPACES = String( length=>[0,1], charset=>" \t\n", size => 100 );

my %tokengen = (
   NUM         => Int(range=>[0, 9], sized=>0),
   VAR         => String( length=>[1,2], charset=>"A-Z", size => 100 ),
);

my $numtokens = 0;

sub gen_lexer {
  my $parser = shift;

  my @token = $parser->YYExpect;

  my $tokengen = Elements(@token);

  my $token = $tokengen->generate;

  my $attr = exists($tokengen{$token})? $tokengen{$token}->generate : $token;
  #$attr = $WHITESPACES->generate.$attr;
  #print "NEXT: <$token, $attr>\n";
  $numtokens++;

  return ($token, $attr);
}


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

1;
