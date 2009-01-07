#!/usr/bin/perl -w
use strict;
#use Test::More qw(no_plan);
#use Test::More tests => 1;
#use_ok qw(Parse::Eyapp) or exit;
use Parse::Eyapp;
use Data::Dumper;
use Parse::Eyapp::Treeregexp;

my $grammar = q{

%semantic token 'a' 'b' 'c'
%tree

%%

S: %name ABC
     A B C
 | %name BC
     B C
;

A: %name A
     'a' 
;

B: %name B
     'b'
;

C: %name C
    'c'
;
%%

sub _Error {
  die "Syntax error.\n";
}

my $in;

sub _Lexer {
    my($parser)=shift;

    {
      $in  or  return('',undef);

      $in =~ s/^\s+//;

      $in =~ s/^([AaBbCc])// and return($1,$1);
      $in =~ s/^(.)//s and print "<$1>\n";
      redo;
    }
}

sub Run {
    my($self)=shift;
    #$in = shift;
    $in = <>;
    $self->YYParse(); 
}
}; # end grammar

$Data::Dumper::Indent = 1;
Parse::Eyapp->new_grammar(
  input=>$grammar, 
  classname=>'AB', 
  firstline => 10, 
  outputfile => 'AB.pm',
  linenumbers => 1
);
my $parser = AB->new(yyprefix => 'Parse::Eyapp::Node::', 
                     yylex => \&AB::_Lexer, 
		     yyerror => \&AB::_Error,);
my $t = $parser->Run("abc");
#print "\n***** Before ******\n";
print Dumper($t);

my $p = Parse::Eyapp::Treeregexp->new( STRING => q{
   delete_b_in_abc : $x(@a, B, @c)
     => { 
       @{$_[0]->{children}} = (@a, @c); 
       print "*****************".Dumper(\@a)."\n ".Dumper(\@c)."*****************\n";
     }
  },
  OUTPUTFILE => 'main.pm',
  PREFIX => 'Parse::Eyapp::Node::',
  NUMBERS => 1,
  FIRSTLINE => 79,
);
$p->generate();

our (@all);
$t->s(@all);
print "\n***** After ******\n";
print Dumper($t);

