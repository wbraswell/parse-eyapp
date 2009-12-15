package Math::Tail;
use warnings;
use strict;
use Getopt::Long;
use Pod::Usage;
use base q{Parse::Eyapp::TailSupport};

sub semantic_error {
  my ($parser, $msg) = @_;

  $parser->YYData->{ERRMSG} = $msg;
  $parser->YYError; 
}

1;

