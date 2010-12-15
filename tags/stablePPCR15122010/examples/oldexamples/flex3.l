%{
/* use it with Rule6andflex.yp */

#define YY_DECL char* yylex(void)

%}

%pointer
%option yylineno 
%option noyywrap

digit        [0-9]
letter       [a-zA-Z_]
NUM          {digit}+
VAR          {letter}({letter}|{digit})*
blank        [ \t\v\n\f]+
TIMES        [*]
DIV          [/]
LP           [(]
RP           [)]
CHAR        (.|\n)
%%

{blank}     
{NUM}        return "NUM";   
{VAR}        return "VAR";
=            return "ASSIGN";
-            return "MINUS";
{TIMES}      return "TIMES";
{DIV}        return "DIV";
{RP}         return "RP";
{LP}         return "LP";
<<EOF>>      return "";
%%
