#!/usr/bin/perl -w
use strict;
use Parse::Yapp;

my $grammar = join('',<DATA>);
Parse::Yapp::yapp($grammar, "Myparser");
my $calc = new Myparser();
$calc->YYData->{INPUT}="2*(4-3)\n-4/2^3\n";
my $output = $calc->YYParse(yylex => \&Lexer, yyerror => \&Error);
print $output;

sub Error {
        exists $_[0]->YYData->{ERRMSG}
    and do {
        print $_[0]->YYData->{ERRMSG};
        delete $_[0]->YYData->{ERRMSG};
        return;
    };
    print "Syntax error.\n";
}

sub Lexer {
    my($parser)=shift;

        $parser->YYData->{INPUT}
    or  $parser->YYData->{INPUT} = <STDIN>
    or  return('',undef);

    $parser->YYData->{INPUT}=~s/^[ \t]//;

    for ($parser->YYData->{INPUT}) {
        s/^([0-9]+(?:\.[0-9]+)?)//
                and return('NUM',$1);
        s/^([A-Za-z][A-Za-z0-9_]*)//
                and return('VAR',$1);
        s/^(.)//s
                and return($1,$1);
    }
}


__END__
%right  '='
%left   '-' '+'
%left   '*' '/'
%left   NEG
%right  '^'

%%
input:  #empty
        |   input line  { push(@{$_[1]},$_[2]); $_[1] }
;

line:       '\n'                { $_[1] }
        |   exp '\n'            { print "$_[1]\n" }
		|	error '\n' { $_[0]->YYErrok }
;

exp:        NUM
        |   VAR                 { $_[0]->YYData->{VARS}{$_[1]} }
        |   VAR '=' exp         { $_[0]->YYData->{VARS}{$_[1]}=$_[3] }
        |   exp '+' exp         { $_[1] + $_[3] }
        |   exp '-' exp         { $_[1] - $_[3] }
        |   exp '*' exp         { $_[1] * $_[3] }
        |   exp '/' exp         {
                                      $_[3]
                                  and return($_[1] / $_[3]);
                                  $_[0]->YYData->{ERRMSG}
                                    =   "Illegal division by zero.\n";
                                  $_[0]->YYError;
                                  undef
                                }
        |   '-' exp %prec NEG   { -$_[2] }
        |   exp '^' exp         { $_[1] ** $_[3] }
        |   '(' exp ')'         { $_[2] }
;

%%
