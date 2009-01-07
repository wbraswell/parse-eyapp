#!/usr/bin/perl -w
use strict;
use Parse::Eyapp;
use Parse::Eyapp::Treeregexp;
use Data::Dumper;

my $grammar = q{
  %right  '='     # Lowest precedence
  %left   '-' '+' # + and - have more precedence than = Disambiguate a-b-c as (a-b)-c
  %left   '*' '/' # * and / have more precedence than + Disambiguate a/b/c as (a/b)/c
  %left   NEG     # Disambiguate -a-b as (-a)-b and not as -(a-b)
  %tree           # Let us build an abstract syntax tree ...

  %%
  line: exp  { 
               Parse::Eyapp::Driver::YYGetSymbolTable($_[1]) 
	     } 
  ;

  exp:
      %name NUM  NUM            | %name VAR   VAR         | %name ASSIGN VAR '=' exp 
    | %name PLUS exp '+' exp    | %name MINUS exp '-' exp | %name TIMES  exp '*' exp 
    | %name DIV     exp '/' exp | %name UMINUS '-' exp %prec NEG 
    |   '(' exp ')'  { $_[2] }  /* Let us simplify a bit the tree */
  ;

  %%
  sub _Error { die "Syntax error.\n"; }

  sub _Lexer {
    my($parser)=shift;

    $parser->YYData->{INPUT} or  return('',undef);

    $parser->YYData->{INPUT}=~s/^\s+//;

    for ($parser->YYData->{INPUT}) {
      s/^([0-9]+(?:\.[0-9]+)?)// and return('NUM',$1);
      s/^([A-Za-z][A-Za-z0-9_]*)// and do {
	return ('VAR', bless [ $1 ], 'Identifiers');
      };
      s/^(.)//s and return($1,$1);
    }
  }

  sub Run {
      my($self)=shift;
      my $r =  $self->YYParse( yylex => \&_Lexer, yyerror => \&_Error, );
      return $r;
  }

  package Identifiers;
  sub id {
    my $self = shift;
    return $self->[0];
  }
}; # end grammar

Parse::Eyapp->new_grammar(
  input=>$grammar, 
  classname=>'Calc',
  firstline=>7,
  outputfile=>'Calc.pm'
); 
my $parser = Calc->new();                # Create the parser
$parser->YYData->{INPUT} = "b*-a+b+2*a\n"; # Set the input
my $t = $parser->Run;                    # Parse it
$Data::Dumper::Indent = 1;
$Data::Dumper::Terse = 1;
$Data::Dumper::Deepcopy  = 1;
print "Tree and symbol Table ****************\n",Dumper($t);

# use Devel::Size qw(size total_size);
# use Perl6::Form;
# 
# sub sizes {
#   my $d = shift;
#   my ($ps, $ts) = (size($d), total_size($d)); 
#   my $ds = $ts-$ps;
#   return ($ps, $ds, $ts);
# }
# 
# print form(
# ' ==============================================================',
# '| VARIABLE | SOLO ESTRUCTURA |     SOLO DATOS |          TOTAL |',
# '|----------+-----------------+----------------+----------------|',
# '| $parser  | {>>>>>>} bytes  | {>>>>>>} bytes | {>>>>>>} bytes |', sizes($parser),
# '| $t       | {>>>>>>} bytes  | {>>>>>>} bytes | {>>>>>>} bytes |', sizes($t),
# ' ==============================================================',
# );
