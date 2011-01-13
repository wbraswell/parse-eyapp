#!/usr/bin/perl -w
use strict;
use Inherited;
use Parse::Eyapp;
use Data::Dumper;

sub Error {
  exists $_[0]->YYData->{ERRMSG}
  and do {
    print $_[0]->YYData->{ERRMSG};
    delete $_[0]->YYData->{ERRMSG};
    return;
  };
  print "Error sintáctico\n";
}

{ # hagamos una clausura con la entrada
  my $input;
  local $/ = undef;
  print "Entrada (En Unix, presione CTRL-D para terminar):\n";
  $input = <stdin>; 

  sub scanner {

    { # Con el redo del final hacemos un bucle "infinito"
      if ($input =~ m|\G\s*INTEGER\b|igc) {
        return ('INTEGER', 'INTEGER');
      } 
      elsif ($input =~ m|\G\s*FLOAT\b|igc) {
        return ('FLOAT', 'FLOAT');
      } 
      elsif ($input =~ m|\G\s*([a-z_]\w*)\b|igc) {
        return ('NAME', $1);
      } 
      elsif ($input =~ m/\G\s*([,;])/gc) {
        return ($1, $1);
      }
      elsif ($input =~ m/\G\s*(.)/gc) {
        die "Caracter invalido: $1\n";
      }
      else {
        return ('', undef); # end of file
      }
      redo;
    }
  }
}

my $debug_level = (@ARGV)? oct(shift @ARGV): 0x1F;
my $parser = Inherited->new();
my $t = $parser->YYParse( yylex => \&scanner, yyerror => \&Error) or die "Syntax Error analyzing input";
$Data::Dumper::Indent = 1;
$Data::Dumper::Terse = 1;
$Data::Dumper::Deepcopy  = 1;
print Dumper($t);
$t->translation_scheme;
print Dumper($t);
