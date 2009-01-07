#!/usr/bin/perl -w
use strict;
use TSPostfix2;

my $parser = new TSPostfix2();
$parser->Run;

my $transform = Parse::Eyapp::Treeregexp->new( STRING => q{

  delete_code : CODE => { $delete_code->delete() }

  {
    sub not_semantic {
      my $self = shift;
      return  1 if ((ref($self) eq 'TERMINAL') and ($self->{token} eq $self->{attr}));
      return 0;
    }
  }

  delete_tokens : TERMINAL and { not_semantic($TERMINAL) } => { $delete_tokens->delete() }
})->generate();

