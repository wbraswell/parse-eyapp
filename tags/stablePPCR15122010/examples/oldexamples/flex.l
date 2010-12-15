%{
/* 
    for ($parser->YYData->{INPUT}) {
        s/^([0-9]+(?:\.[0-9]+)?)//
                and return('NUM',$1);
        s/^([A-Za-z][A-Za-z0-9_]*)//
                and return('VAR',$1);
        s/^(.)//s
                and return($1,$1);
    }

*/

#define YY_DECL char* yylex(void)

%}

%pointer
%option yylineno noyywrap

digit        [0-9]
letter       [a-zA-Z_]
NUM          {digit}+
VAR          {letter}({letter}|{digit})*
blank        [ \t\v\n\f]+
EQ           [=]
MINUS        [-]
%%

{NUM}        return "NUM";   
{VAR}        return "VAR";
{blank}     
{EQ}         return "EQ";
{MINUS}      return "MINUS";
<<EOF>>      return "";
%%
