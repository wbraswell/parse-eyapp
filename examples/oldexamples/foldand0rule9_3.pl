#!/usr/bin/perl -w
use strict;
use Rule9;
use Data::Dumper;
use Transform2;

$Data::Dumper::Indent = 1;
my $parser = new Rule9(yyprefix => "Rule9::");
my $t = $parser->YYParse( yylex => \&Rule9::Lexer, yyerror => \&Rule9::Error, 
		    #yydebug =>0xFF
		  );
print "\n***** Before ******\n";
print Dumper($t);
$t->s(@Transform2::all);
print "\n***** After ******\n";
print Dumper($t);
