########################################################################################
#
#    This file was generated using Parse::Eyapp version 1.182.
#
# Copyright © 2006, 2007, 2008 Casiano Rodriguez-Leon.
# Copyright © 2017 William N. Braswell, Jr.
# All Rights Reserved.
#
# Parse::Yapp is Copyright © 1998, 1999, 2000, 2001, Francois Desarmenien.
# Parse::Yapp is Copyright © 2017 William N. Braswell, Jr.
# All Rights Reserved.
#        Don't edit this file, use source file 'lib/Parse/Eyapp/Parse.yp' instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
########################################################################################
package Parse::Eyapp::Parse;
use strict;

push @Parse::Eyapp::Parse::ISA, 'Parse::Eyapp::Driver';




BEGIN {
  # This strange way to load the modules is to guarantee compatibility when
  # using several standalone and non-standalone Eyapp parsers

  require Parse::Eyapp::Driver unless Parse::Eyapp::Driver->can('YYParse');
  require Parse::Eyapp::Node unless Parse::Eyapp::Node->can('hnew'); 
}
  

sub unexpendedInput { defined($_) ? substr($_, (defined(pos $_) ? pos $_ : 0)) : '' }

# Copyright © 2006, 2007, 2008 Casiano Rodriguez-Leon.
# Copyright © 2017 William N. Braswell, Jr.
# All Rights Reserved.
#
# Based on Parse::Yapp.
#
# Parse::Yapp is Copyright © 1998, 1999, 2000, 2001, Francois Desarmenien.
# Parse::Yapp is Copyright © 2017 William N. Braswell, Jr.
# All Rights Reserved.

require 5.004;

use Carp;

my (
  $input,
  $lexlevel, # Used by the lexical analyzer. Controls in which section we are:
             # head (0), body(1) or tail (2)
  @lineno,   # Used by the lexical analyzer. $lineno[0] is the lione number for 
             # the beginning of the token, $lineno[1] the end
  $nberr,    # Number of errors up to now
  $prec,
  $labelno);

my $syms;
my $head;    # list of texts inside header sections
my $tail;
my $token;
my $term;    # hash ref. key: token, value: an array describing the assoc and priority { '-' => [ 'LEFT' 1 ], '*' => [ 'LEFT' 2 ], }
my $termdef; # token definitions. key is token, value is regexp

my $whites;      # string with the code for white spaces (when automatic generated lexer)
my $lexer;       # boolean: true if %lexer was used
my $incremental; # build an incremental lexer: one that reads in chunks from $self->YYInputFile

my $nterm;
my $rules;
my $precterm; # hash ref. key token used in %prec. value: priority
my $start;
my $nullable;
my $semantic; # hash ref. Keys are the tokens. Value: 0 = syntactic 1 = semantic
my $dummy = []; # array ref. the dummy tokens

my ($expect);
my $namingscheme;
my $defaultaction;
my $filename;
my $tree = 0; # true if %tree or %metatree
my $metatree = 0;
my $flatlists = 0; # true if flat list semantic for * + and ? operators
my $bypass = 0;
my $prefix = ''; # yyprefix
my $buildingtree = 0;
my $alias = 0;
my $accessors = {}; # Hash for named accessors when %tree or %metatree is active { exp::left => 0 }
my $strict = 0; # When true, all tokens must be declared or a warning will be issued
my $nocompact; # Do not compact action tables. No DEFAULT field for "STATES"

my %nondeclared; # Potential non declared token identifiers appearing in the program
my %conflict;    # Hash of conflict name => { codeh => 'code handler', line => #line, #prodnumber1 => [pos1, pos2], #prodnumber2 => [pos1,pos2,pos3], ... }

sub not_an_id {
  my $id = shift;

  !defined($id) or $id !~ m/^[a-zA-Z_][[a-zA-Z_0-9]*$/;
}

# When using %metatree, i.e. generating a Translation Scheme
# returns true if $code was preceded by a %begin directive
sub is_begin_code {
  my $code = shift;

  return (UNIVERSAL::isa($code, 'ARRAY') and exists($code->[2]) and $code->[2] eq 'BEGINCODE');
}

# Produces the text containing the declarations
# and initializations of the associated variables
sub prefixcode {
  my  %index = @_;

  # When TS var $lhs refers to the father node
  my $text = ($metatree)? 'my $lhs = $_[0]; ' : '';

  # No identifiers were associated with the attributes if %index is empty
  return $text unless %index;

  $text .= join "", (map { "my \$$_ = \$_[$index{$_}]; " } (keys(%index)));

  # The former line produces the code for initialization of the attribute 
  # variables so that a production like:
  #                   exp: VAR.left '='.op exp.right { ... semantic action }
  # will produce s.t. like:
  #        sub {
  #            my $left = $_[1]; my $right = $_[3]; my $op = $_[2];  
  #            ... semantic action
  #        }

  return $text;
}

# Computes the hash %index used in sub 'prefixcode' 
# $index{a} is the index of the symbol associated with 'a' in the right hand side
# of the production. For example in 
#                              R: B.b A.a
# $index{a} will be 2.
sub symbol_index {
  my $rhs = shift || [];
  my $position = shift || @$rhs;
  my %index;

  local $_ = 0;
  for my $value (@{$rhs}) {
    $_++ unless (($value->[0] eq 'CODE') and $metatree) or ($value->[0] eq 'CONFLICTHANDLER');
    my $id = $value->[1][2];
    if (defined($id)) {
        _SyntaxError(
          2, 
          "Error: attribute variable '\$$id' appears more than once", 
          $value->[1][1]) 
      if exists($index{$id});
      $index{$id} = $_;
    }
    last if $_ >= $position;
  }

  return %index;
}

# Computes the hash %index holding the position in the generated
# AST (as it is build by YYBuildAST) of the node associated with
# the identifier. For ex. in "E: E.left '+' E.right"
# $index{right} will be 1 (remember that '+' is a syntactic token)
sub child_index_in_AST {
  my $rhs = shift || [];
  my %index;

  local $_ = 0;
  for my $value (@{$rhs}) {
    my ($symb, $line, $id) = @{$value->[1]};

    # Accessors will be build only for explictly named attributes
    # Hal Finkel's patch
    next unless $$semantic{$symb};
    $index{$id} = $_ if defined($id);
    $_++ ;
  }

  return %index;
}

# This sub gives support to the "%tree alias" directive.
# Expands the 'accessors' hash relation 
# for the current production. Uses 'child_index_in_AST'
# to build the mapping between names and indices
sub make_accessors {
  my $name = shift;
  return unless ($tree and $alias and defined($name) and $name->[0] =~m{^[a-zA-Z_]\w*$});

  my $rhs = shift;

  my %index = child_index_in_AST($rhs);
  for (keys(%index)) {
    $accessors->{"$name->[0]::$_"} = $index{$_};
  }
}

# Gives support to %metatree
sub insert_delaying_code {
  my $code = shift;

  # If %begin the code will be executed at "tree time construction"
  return if is_begin_code($$code);
  if ($$code) {
    $$code = [ 
      # The user code is substituted by a builder of a node referencing the
      # actual sub
      "push \@_,  sub { $$code->[0] }; goto &Parse::Eyapp::Driver::YYBuildTS; ", 
      $$code->[1]
    ]; 
  }
  else {
    $$code = [ ' goto &Parse::Eyapp::Driver::YYBuildTS ', $lineno[0]]
  }
}

# Called only from _AddRules
sub process_production {
  my ($rhs) = @_;

  my $position = $#$rules;
  my @newrhs = ();

  my $m = 0;
  for my $s (0..$#$rhs) {
      my($what,$value)=@{$$rhs[$s]};

      if ($what eq 'CODE') { # TODO: modify name scheme: RULE_POSITION
          my($tmplhs)='@'.$position."-$s";

          if ($value) {

            # The auxiliary production generated for 
            # intermediate actions has access to the
            # attributes of the symbols to its left
            # Not needed if generating a TS
            my @optarg = $metatree? () : ($s+1); 

            # Variable declarations
            my %index = symbol_index($rhs, @optarg);
            $value->[0] = prefixcode(%index).$value->[0];
          }

          insert_delaying_code(\$value) if $metatree;

          #                       rhs prec   name   code
          push(@$rules,[ $tmplhs, [], undef, undef, $value ]);
          push(@newrhs, $tmplhs);
          next;
      }
     elsif ($what eq 'CONFLICTHANDLER') {
       my $ch = $value->[0];
       push @{$conflict{$ch}{production}{-$position}}, $m; 
       next;
     }
#     elsif ($what eq 'CONFLICTVIEWPOINT') {
#     }
      
      push(@newrhs, $$value[0]);
      $m++;
  }
  return \@newrhs;
}

# Receives a specification of the RHS of a production like in:
#       rhs([ $A, $val], name => $_[2], code => $code_rec, prec => $prec)
# Returns the data structure used to represent the RHS:
#      [ @rhs, $arg{prec}, $arg{name}, $arg{code}]
sub rhs {
  my @rhs = @{shift()};

  my %arg = @_;
  $arg{prec} = exists($arg{prec})? token($arg{prec}): undef;
  $arg{name} = undef unless exists($arg{name});
  $arg{code} = exists($arg{code})? token($arg{code}): undef;
 
  @rhs = map { ['SYMB', $_] } @rhs;

  return [ @rhs, $arg{prec}, $arg{name}, $arg{code}];
}

sub token {
  my $value = shift;

  return [ $value,  $lineno[0]];
}

sub symbol {
  my $id = shift;

  return ['SYMB', $id];
}

# To be used with the %lexer directive
sub make_lexer {
  my ($code, $line) = @_;

  my $errline = $line + ($code =~ tr/\n//);

my $lexertemplate = << 'ENDOFLEXER';
__PACKAGE__->YYLexer( 
  sub { # lexical analyzer
    my $self = $_[0]; 
    for (${$self->input()}) {  # contextualize
#line <<line>> "<<filename>>"
      <<code>>       
<<end_user_code>>
      return ('', undef) if ($_ eq '') || (defined(pos($_)) && (pos($_) >= length($_)));
      die("Error inside the lexical analyzer. Line: <<errline>>. File: <<filename>>. No regexp matched.\n");
    } 
  } # end lexical analyzer
);
ENDOFLEXER

  $lexertemplate =~ s/<<code>>/$code/g;
  $lexertemplate =~ s/<<line>>/$line/g;
  $lexertemplate =~ s/<<errline>>/$errline/g;
  $lexertemplate =~ s/<<filename>>/$filename/g;
  $lexertemplate =~ s/<<end_user_code>>/################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################/g;

  return $lexertemplate;
}

sub explorer_handler {
              my ($name, $code) = @_;
              my ($cn, $line) = @$name;


              my ($c, $li) = @$code;

              # TODO: this must be in Output
              my $conflict_header = <<"CONFLICT_EXPLORER";
  my \$self = \$_[0];
  for (\${\$self->input()}) {  
#line $li "$filename" 
CONFLICT_EXPLORER
              $c =~ s/^/$conflict_header/; # }

              # {
              # follows the closing curly bracket of the for .. to contextualize!!!!!!                 v
              $c =~ s/$/\n################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################\n  }\n/;
              #$code->[0] = $c;
              $conflict{$cn}{explorer} = $c;
              $conflict{$cn}{explorerline} = $line;

              # TODO: error control. Factorize!!!!!
              $$syms{$cn} = $line;
              $$nterm{$cn} = undef;

              undef;
            }



# Default lexical analyzer
our $LEX = sub {
    my $self = shift;
    my $pos;

    for (${$self->input}) {
      

      m{\G(\s+)}gc and $self->tokenline($1 =~ tr{\n}{});

      m{\G(INCREMENTAL|VIEWPOINT|EXPECTRR|EXPLORER|REGEXP|WHITES|DPREC|LEXER|DUMMY|\n|\:\:|\%\%|\:|\>|\?|\||\$|\%|\;|\)|\<|\.|\(|\!|\=)}gc and return ($1, $1);

      /\G(ASSOC)/gc and return ($1, $1);
      /\G(BEGINCODE)/gc and return ($1, $1);
      /\G(CODE)/gc and return ($1, $1);
      /\G(CONFLICT)/gc and return ($1, $1);
      /\G(DEFAULTACTION)/gc and return ($1, $1);
      /\G(EXPECT)/gc and return ($1, $1);
      /\G(HEADCODE)/gc and return ($1, $1);
      /\G(IDENT)/gc and return ($1, $1);
      /\G(LABEL)/gc and return ($1, $1);
      /\G(LITERAL)/gc and return ($1, $1);
      /\G(METATREE)/gc and return ($1, $1);
      /\G(NAME)/gc and return ($1, $1);
      /\G(NAMINGSCHEME)/gc and return ($1, $1);
      /\G(NOCOMPACT)/gc and return ($1, $1);
      /\G(NUMBER)/gc and return ($1, $1);
      /\G(OPTION)/gc and return ($1, $1);
      /\G(PLUS)/gc and return ($1, $1);
      /\G(PREC)/gc and return ($1, $1);
      /\G(PREFIX)/gc and return ($1, $1);
      /\G(SEMANTIC)/gc and return ($1, $1);
      /\G(STAR)/gc and return ($1, $1);
      /\G(START)/gc and return ($1, $1);
      /\G(STRICT)/gc and return ($1, $1);
      /\G(SYNTACTIC)/gc and return ($1, $1);
      /\G(TAILCODE)/gc and return ($1, $1);
      /\G(TOKEN)/gc and return ($1, $1);
      /\G(TREE)/gc and return ($1, $1);
      /\G(TYPE)/gc and return ($1, $1);
      /\G(UNION)/gc and return ($1, $1);


      return ('', undef) if ($_ eq '') || (defined(pos($_)) && (pos($_) >= length($_)));
      /\G\s*(\S+)/;
      my $near = substr($1,0,10); 

      return($near, $near);

     # die( "Error inside the lexical analyzer near '". $near
     #     ."'. Line: ".$self->line()
     #     .". File: '".$self->YYFilename()."'. No match found.\n");
    }
  }
;


################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################

my $warnmessage =<< "EOFWARN";
Warning!: Did you changed the \@Parse::Eyapp::Parse::ISA variable inside the header section of the eyapp program?
EOFWARN

sub new {
  my($class)=shift;
  ref($class) and $class=ref($class);

  warn $warnmessage unless __PACKAGE__->isa('Parse::Eyapp::Driver'); 
  my($self)=$class->SUPER::new( 
    yyversion => '1.182',
    yyGRAMMAR  =>
[#[productionNameAndLabel => lhs, [ rhs], bypass]]
  [ '_SUPERSTART' => '$start', [ 'eyapp', '$end' ], 0 ],
  [ 'eyapp_1' => 'eyapp', [ 'head', 'body', 'tail' ], 0 ],
  [ 'symbol_2' => 'symbol', [ 'LITERAL' ], 0 ],
  [ 'symbol_3' => 'symbol', [ 'ident' ], 0 ],
  [ 'ident_4' => 'ident', [ 'IDENT' ], 0 ],
  [ 'prodname_5' => 'prodname', [ 'IDENT' ], 0 ],
  [ 'prodname_6' => 'prodname', [ 'LABEL' ], 0 ],
  [ 'prodname_7' => 'prodname', [ 'IDENT', 'LABEL' ], 0 ],
  [ 'head_8' => 'head', [ 'headsec', '%%' ], 0 ],
  [ 'perlident_9' => 'perlident', [ 'IDENT' ], 0 ],
  [ 'perlident_10' => 'perlident', [ 'perlident', '::', 'IDENT' ], 0 ],
  [ 'headsec_11' => 'headsec', [  ], 0 ],
  [ 'headsec_12' => 'headsec', [ 'decls' ], 0 ],
  [ 'decls_13' => 'decls', [ 'decls', 'decl' ], 0 ],
  [ 'decls_14' => 'decls', [ 'decl' ], 0 ],
  [ 'decl_15' => 'decl', [ '\n' ], 0 ],
  [ 'decl_16' => 'decl', [ 'SEMANTIC', 'typedecl', 'toklist', '\n' ], 0 ],
  [ 'decl_17' => 'decl', [ 'SYNTACTIC', 'typedecl', 'toklist', '\n' ], 0 ],
  [ 'decl_18' => 'decl', [ 'DUMMY', 'typedecl', 'toklist', '\n' ], 0 ],
  [ 'decl_19' => 'decl', [ 'TOKEN', 'typedecl', 'toklist', '\n' ], 0 ],
  [ 'decl_20' => 'decl', [ 'ASSOC', 'typedecl', 'symlist', '\n' ], 0 ],
  [ 'decl_21' => 'decl', [ 'START', 'ident', '\n' ], 0 ],
  [ 'decl_22' => 'decl', [ 'PREFIX', '\n' ], 0 ],
  [ 'decl_23' => 'decl', [ 'WHITES', 'CODE', '\n' ], 0 ],
  [ 'decl_24' => 'decl', [ 'WHITES', 'REGEXP', '\n' ], 0 ],
  [ 'decl_25' => 'decl', [ 'WHITES', '=', 'CODE', '\n' ], 0 ],
  [ 'decl_26' => 'decl', [ 'WHITES', '=', 'REGEXP', '\n' ], 0 ],
  [ 'decl_27' => 'decl', [ 'NAMINGSCHEME', 'CODE', '\n' ], 0 ],
  [ 'decl_28' => 'decl', [ 'HEADCODE', '\n' ], 0 ],
  [ 'decl_29' => 'decl', [ 'UNION', 'CODE', '\n' ], 0 ],
  [ 'decl_30' => 'decl', [ 'DEFAULTACTION', 'CODE', '\n' ], 0 ],
  [ 'decl_31' => 'decl', [ 'INCREMENTAL', '\n' ], 0 ],
  [ 'decl_32' => 'decl', [ 'INCREMENTAL', 'LITERAL', '\n' ], 0 ],
  [ 'decl_33' => 'decl', [ 'LEXER', 'CODE', '\n' ], 0 ],
  [ 'decl_34' => 'decl', [ 'TREE', '\n' ], 0 ],
  [ 'decl_35' => 'decl', [ 'METATREE', '\n' ], 0 ],
  [ 'decl_36' => 'decl', [ 'STRICT', '\n' ], 0 ],
  [ 'decl_37' => 'decl', [ 'NOCOMPACT', '\n' ], 0 ],
  [ 'decl_38' => 'decl', [ 'TYPE', 'typedecl', 'identlist', '\n' ], 0 ],
  [ 'decl_39' => 'decl', [ 'CONFLICT', 'ident', 'CODE', '\n' ], 0 ],
  [ 'decl_40' => 'decl', [ 'CONFLICT', 'ident', 'perlident', '?', 'prodname', ':', 'prodname', '\n' ], 0 ],
  [ 'decl_41' => 'decl', [ 'CONFLICT', 'ident', 'neg', 'REGEXP', '?', 'prodname', ':', 'prodname', '\n' ], 0 ],
  [ 'decl_42' => 'decl', [ 'EXPLORER', 'ident', 'CODE', '\n' ], 0 ],
  [ 'decl_43' => 'decl', [ 'EXPLORER', 'ident', 'LITERAL', '\n' ], 0 ],
  [ 'decl_44' => 'decl', [ 'EXPLORER', 'ident', 'perlident', '\n' ], 0 ],
  [ 'decl_45' => 'decl', [ 'EXPLORER', 'ident', 'perlident', 'LITERAL', '\n' ], 0 ],
  [ 'decl_46' => 'decl', [ 'EXPECT', 'NUMBER', '\n' ], 0 ],
  [ 'decl_47' => 'decl', [ 'EXPECT', 'NUMBER', 'NUMBER', '\n' ], 0 ],
  [ 'decl_48' => 'decl', [ 'EXPECTRR', 'NUMBER', '\n' ], 0 ],
  [ 'decl_49' => 'decl', [ 'error', '\n' ], 0 ],
  [ 'neg_50' => 'neg', [  ], 0 ],
  [ 'neg_51' => 'neg', [ '!' ], 0 ],
  [ 'typedecl_52' => 'typedecl', [  ], 0 ],
  [ 'typedecl_53' => 'typedecl', [ '<', 'IDENT', '>' ], 0 ],
  [ 'symlist_54' => 'symlist', [ 'symlist', 'symbol' ], 0 ],
  [ 'symlist_55' => 'symlist', [ 'symbol' ], 0 ],
  [ 'toklist_56' => 'toklist', [ 'toklist', 'tokendef' ], 0 ],
  [ 'toklist_57' => 'toklist', [ 'tokendef' ], 0 ],
  [ 'tokendef_58' => 'tokendef', [ 'ident', '=', 'REGEXP' ], 0 ],
  [ 'tokendef_59' => 'tokendef', [ 'ident', '=', '%', 'REGEXP' ], 0 ],
  [ 'tokendef_60' => 'tokendef', [ 'ident', '=', '%', 'REGEXP', '=', 'IDENT' ], 0 ],
  [ 'tokendef_61' => 'tokendef', [ 'ident', '=', '%', 'REGEXP', '!', 'IDENT' ], 0 ],
  [ 'tokendef_62' => 'tokendef', [ 'ident', '=', 'CODE' ], 0 ],
  [ 'tokendef_63' => 'tokendef', [ 'symbol' ], 0 ],
  [ 'identlist_64' => 'identlist', [ 'identlist', 'ident' ], 0 ],
  [ 'identlist_65' => 'identlist', [ 'ident' ], 0 ],
  [ 'body_66' => 'body', [ 'rulesec', '%%' ], 0 ],
  [ 'body_67' => 'body', [ '%%' ], 0 ],
  [ 'rulesec_68' => 'rulesec', [ 'rulesec', 'rules' ], 0 ],
  [ 'rulesec_69' => 'rulesec', [ 'startrules' ], 0 ],
  [ 'startrules_70' => 'startrules', [ 'IDENT', ':', '@70-2', 'rhss', ';' ], 0 ],
  [ '_CODE' => '@70-2', [  ], 0 ],
  [ 'startrules_72' => 'startrules', [ 'error', ';' ], 0 ],
  [ 'rules_73' => 'rules', [ 'IDENT', ':', 'rhss', ';' ], 0 ],
  [ 'rules_74' => 'rules', [ 'error', ';' ], 0 ],
  [ 'rhss_75' => 'rhss', [ 'rhss', '|', 'rule' ], 0 ],
  [ 'rhss_76' => 'rhss', [ 'rule' ], 0 ],
  [ 'rule_77' => 'rule', [ 'optname', 'rhs', 'prec', 'epscode' ], 0 ],
  [ 'rule_78' => 'rule', [ 'optname', 'rhs' ], 0 ],
  [ 'rhs_79' => 'rhs', [  ], 0 ],
  [ 'rhs_80' => 'rhs', [ 'rhselts' ], 0 ],
  [ 'rhselts_81' => 'rhselts', [ 'rhselts', 'rhseltwithid' ], 0 ],
  [ 'rhselts_82' => 'rhselts', [ 'rhseltwithid' ], 0 ],
  [ 'rhseltwithid_83' => 'rhseltwithid', [ 'rhselt', '.', 'IDENT' ], 0 ],
  [ 'rhseltwithid_84' => 'rhseltwithid', [ '$', 'rhselt' ], 0 ],
  [ 'rhseltwithid_85' => 'rhseltwithid', [ '$', 'error' ], 0 ],
  [ 'rhseltwithid_86' => 'rhseltwithid', [ 'rhselt' ], 0 ],
  [ 'rhselt_87' => 'rhselt', [ 'symbol' ], 0 ],
  [ 'rhselt_88' => 'rhselt', [ 'code' ], 0 ],
  [ 'rhselt_89' => 'rhselt', [ 'DPREC', 'ident' ], 0 ],
  [ 'rhselt_90' => 'rhselt', [ 'VIEWPOINT' ], 0 ],
  [ 'rhselt_91' => 'rhselt', [ '(', 'optname', 'rhs', ')' ], 0 ],
  [ 'rhselt_92' => 'rhselt', [ 'rhselt', 'STAR' ], 0 ],
  [ 'rhselt_93' => 'rhselt', [ 'rhselt', '<', 'STAR', 'symbol', '>' ], 0 ],
  [ 'rhselt_94' => 'rhselt', [ 'rhselt', 'OPTION' ], 0 ],
  [ 'rhselt_95' => 'rhselt', [ 'rhselt', '<', 'PLUS', 'symbol', '>' ], 0 ],
  [ 'rhselt_96' => 'rhselt', [ 'rhselt', 'PLUS' ], 0 ],
  [ 'optname_97' => 'optname', [  ], 0 ],
  [ 'optname_98' => 'optname', [ 'NAME', 'IDENT' ], 0 ],
  [ 'optname_99' => 'optname', [ 'NAME', 'IDENT', 'LABEL' ], 0 ],
  [ 'optname_100' => 'optname', [ 'NAME', 'LABEL' ], 0 ],
  [ 'prec_101' => 'prec', [ 'PREC', 'symbol' ], 0 ],
  [ 'epscode_102' => 'epscode', [  ], 0 ],
  [ 'epscode_103' => 'epscode', [ 'code' ], 0 ],
  [ 'code_104' => 'code', [ 'CODE' ], 0 ],
  [ 'code_105' => 'code', [ 'BEGINCODE' ], 0 ],
  [ 'tail_106' => 'tail', [  ], 0 ],
  [ 'tail_107' => 'tail', [ 'TAILCODE' ], 0 ],
],
    yyLABELS  =>
{
  '_SUPERSTART' => 0,
  'eyapp_1' => 1,
  'symbol_2' => 2,
  'symbol_3' => 3,
  'ident_4' => 4,
  'prodname_5' => 5,
  'prodname_6' => 6,
  'prodname_7' => 7,
  'head_8' => 8,
  'perlident_9' => 9,
  'perlident_10' => 10,
  'headsec_11' => 11,
  'headsec_12' => 12,
  'decls_13' => 13,
  'decls_14' => 14,
  'decl_15' => 15,
  'decl_16' => 16,
  'decl_17' => 17,
  'decl_18' => 18,
  'decl_19' => 19,
  'decl_20' => 20,
  'decl_21' => 21,
  'decl_22' => 22,
  'decl_23' => 23,
  'decl_24' => 24,
  'decl_25' => 25,
  'decl_26' => 26,
  'decl_27' => 27,
  'decl_28' => 28,
  'decl_29' => 29,
  'decl_30' => 30,
  'decl_31' => 31,
  'decl_32' => 32,
  'decl_33' => 33,
  'decl_34' => 34,
  'decl_35' => 35,
  'decl_36' => 36,
  'decl_37' => 37,
  'decl_38' => 38,
  'decl_39' => 39,
  'decl_40' => 40,
  'decl_41' => 41,
  'decl_42' => 42,
  'decl_43' => 43,
  'decl_44' => 44,
  'decl_45' => 45,
  'decl_46' => 46,
  'decl_47' => 47,
  'decl_48' => 48,
  'decl_49' => 49,
  'neg_50' => 50,
  'neg_51' => 51,
  'typedecl_52' => 52,
  'typedecl_53' => 53,
  'symlist_54' => 54,
  'symlist_55' => 55,
  'toklist_56' => 56,
  'toklist_57' => 57,
  'tokendef_58' => 58,
  'tokendef_59' => 59,
  'tokendef_60' => 60,
  'tokendef_61' => 61,
  'tokendef_62' => 62,
  'tokendef_63' => 63,
  'identlist_64' => 64,
  'identlist_65' => 65,
  'body_66' => 66,
  'body_67' => 67,
  'rulesec_68' => 68,
  'rulesec_69' => 69,
  'startrules_70' => 70,
  '_CODE' => 71,
  'startrules_72' => 72,
  'rules_73' => 73,
  'rules_74' => 74,
  'rhss_75' => 75,
  'rhss_76' => 76,
  'rule_77' => 77,
  'rule_78' => 78,
  'rhs_79' => 79,
  'rhs_80' => 80,
  'rhselts_81' => 81,
  'rhselts_82' => 82,
  'rhseltwithid_83' => 83,
  'rhseltwithid_84' => 84,
  'rhseltwithid_85' => 85,
  'rhseltwithid_86' => 86,
  'rhselt_87' => 87,
  'rhselt_88' => 88,
  'rhselt_89' => 89,
  'rhselt_90' => 90,
  'rhselt_91' => 91,
  'rhselt_92' => 92,
  'rhselt_93' => 93,
  'rhselt_94' => 94,
  'rhselt_95' => 95,
  'rhselt_96' => 96,
  'optname_97' => 97,
  'optname_98' => 98,
  'optname_99' => 99,
  'optname_100' => 100,
  'prec_101' => 101,
  'epscode_102' => 102,
  'epscode_103' => 103,
  'code_104' => 104,
  'code_105' => 105,
  'tail_106' => 106,
  'tail_107' => 107,
},
    yyTERMS  =>
{ '' => { ISSEMANTIC => 0 },
	'!' => { ISSEMANTIC => 0 },
	'$' => { ISSEMANTIC => 0 },
	'%%' => { ISSEMANTIC => 0 },
	'%' => { ISSEMANTIC => 0 },
	'(' => { ISSEMANTIC => 0 },
	')' => { ISSEMANTIC => 0 },
	'.' => { ISSEMANTIC => 0 },
	':' => { ISSEMANTIC => 0 },
	'::' => { ISSEMANTIC => 0 },
	';' => { ISSEMANTIC => 0 },
	'<' => { ISSEMANTIC => 0 },
	'=' => { ISSEMANTIC => 0 },
	'>' => { ISSEMANTIC => 0 },
	'?' => { ISSEMANTIC => 0 },
	'\n' => { ISSEMANTIC => 0 },
	'|' => { ISSEMANTIC => 0 },
	ASSOC => { ISSEMANTIC => 1 },
	BEGINCODE => { ISSEMANTIC => 1 },
	CODE => { ISSEMANTIC => 1 },
	CONFLICT => { ISSEMANTIC => 1 },
	DEFAULTACTION => { ISSEMANTIC => 1 },
	DPREC => { ISSEMANTIC => 1 },
	DUMMY => { ISSEMANTIC => 1 },
	EXPECT => { ISSEMANTIC => 1 },
	EXPECTRR => { ISSEMANTIC => 1 },
	EXPLORER => { ISSEMANTIC => 1 },
	HEADCODE => { ISSEMANTIC => 1 },
	IDENT => { ISSEMANTIC => 1 },
	INCREMENTAL => { ISSEMANTIC => 1 },
	LABEL => { ISSEMANTIC => 1 },
	LEXER => { ISSEMANTIC => 1 },
	LITERAL => { ISSEMANTIC => 1 },
	METATREE => { ISSEMANTIC => 1 },
	NAME => { ISSEMANTIC => 1 },
	NAMINGSCHEME => { ISSEMANTIC => 1 },
	NOCOMPACT => { ISSEMANTIC => 1 },
	NUMBER => { ISSEMANTIC => 1 },
	OPTION => { ISSEMANTIC => 1 },
	PLUS => { ISSEMANTIC => 1 },
	PREC => { ISSEMANTIC => 1 },
	PREFIX => { ISSEMANTIC => 1 },
	REGEXP => { ISSEMANTIC => 1 },
	SEMANTIC => { ISSEMANTIC => 1 },
	STAR => { ISSEMANTIC => 1 },
	START => { ISSEMANTIC => 1 },
	STRICT => { ISSEMANTIC => 1 },
	SYNTACTIC => { ISSEMANTIC => 1 },
	TAILCODE => { ISSEMANTIC => 1 },
	TOKEN => { ISSEMANTIC => 1 },
	TREE => { ISSEMANTIC => 1 },
	TYPE => { ISSEMANTIC => 1 },
	UNION => { ISSEMANTIC => 1 },
	VIEWPOINT => { ISSEMANTIC => 1 },
	WHITES => { ISSEMANTIC => 1 },
	error => { ISSEMANTIC => 1 },
	error => { ISSEMANTIC => 0 },
},
    yyFILENAME  => 'lib/Parse/Eyapp/Parse.yp',
    yystates =>
[
	{#State 0
		ACTIONS => {
			'UNION' => 4,
			'CONFLICT' => 3,
			'TOKEN' => 7,
			'DUMMY' => 8,
			'NAMINGSCHEME' => 5,
			"%%" => -11,
			'ASSOC' => 10,
			'START' => 1,
			"\n" => 2,
			'SEMANTIC' => 22,
			'TYPE' => 20,
			'INCREMENTAL' => 21,
			'NOCOMPACT' => 25,
			'DEFAULTACTION' => 28,
			'STRICT' => 27,
			'EXPECT' => 26,
			'TREE' => 30,
			'error' => 29,
			'HEADCODE' => 11,
			'WHITES' => 15,
			'SYNTACTIC' => 14,
			'LEXER' => 13,
			'PREFIX' => 16,
			'EXPECTRR' => 17,
			'METATREE' => 18,
			'EXPLORER' => 19
		},
		GOTOS => {
			'head' => 6,
			'decl' => 24,
			'eyapp' => 23,
			'decls' => 12,
			'headsec' => 9
		}
	},
	{#State 1
		ACTIONS => {
			'IDENT' => 31
		},
		GOTOS => {
			'ident' => 32
		}
	},
	{#State 2
		DEFAULT => -15
	},
	{#State 3
		ACTIONS => {
			'IDENT' => 31
		},
		GOTOS => {
			'ident' => 33
		}
	},
	{#State 4
		ACTIONS => {
			'CODE' => 34
		}
	},
	{#State 5
		ACTIONS => {
			'CODE' => 35
		}
	},
	{#State 6
		ACTIONS => {
			"%%" => 38,
			'error' => 41,
			'IDENT' => 39
		},
		GOTOS => {
			'body' => 40,
			'rulesec' => 37,
			'startrules' => 36
		}
	},
	{#State 7
		ACTIONS => {
			"<" => 42
		},
		DEFAULT => -52,
		GOTOS => {
			'typedecl' => 43
		}
	},
	{#State 8
		ACTIONS => {
			"<" => 42
		},
		DEFAULT => -52,
		GOTOS => {
			'typedecl' => 44
		}
	},
	{#State 9
		ACTIONS => {
			"%%" => 45
		}
	},
	{#State 10
		ACTIONS => {
			"<" => 42
		},
		DEFAULT => -52,
		GOTOS => {
			'typedecl' => 46
		}
	},
	{#State 11
		ACTIONS => {
			"\n" => 47
		}
	},
	{#State 12
		ACTIONS => {
			'WHITES' => 15,
			'LEXER' => 13,
			'SYNTACTIC' => 14,
			'HEADCODE' => 11,
			'METATREE' => 18,
			'EXPLORER' => 19,
			'EXPECTRR' => 17,
			'PREFIX' => 16,
			'NOCOMPACT' => 25,
			'TYPE' => 20,
			'SEMANTIC' => 22,
			'INCREMENTAL' => 21,
			'error' => 29,
			'TREE' => 30,
			'STRICT' => 27,
			'DEFAULTACTION' => 28,
			'EXPECT' => 26,
			'START' => 1,
			"\n" => 2,
			'TOKEN' => 7,
			'DUMMY' => 8,
			'NAMINGSCHEME' => 5,
			'UNION' => 4,
			'CONFLICT' => 3,
			'ASSOC' => 10,
			"%%" => -12
		},
		GOTOS => {
			'decl' => 48
		}
	},
	{#State 13
		ACTIONS => {
			'CODE' => 49
		}
	},
	{#State 14
		ACTIONS => {
			"<" => 42
		},
		DEFAULT => -52,
		GOTOS => {
			'typedecl' => 50
		}
	},
	{#State 15
		ACTIONS => {
			"=" => 52,
			'REGEXP' => 53,
			'CODE' => 51
		}
	},
	{#State 16
		ACTIONS => {
			"\n" => 54
		}
	},
	{#State 17
		ACTIONS => {
			'NUMBER' => 55
		}
	},
	{#State 18
		ACTIONS => {
			"\n" => 56
		}
	},
	{#State 19
		ACTIONS => {
			'IDENT' => 31
		},
		GOTOS => {
			'ident' => 57
		}
	},
	{#State 20
		ACTIONS => {
			"<" => 42
		},
		DEFAULT => -52,
		GOTOS => {
			'typedecl' => 58
		}
	},
	{#State 21
		ACTIONS => {
			'LITERAL' => 59,
			"\n" => 60
		}
	},
	{#State 22
		ACTIONS => {
			"<" => 42
		},
		DEFAULT => -52,
		GOTOS => {
			'typedecl' => 61
		}
	},
	{#State 23
		ACTIONS => {
			'' => 62
		}
	},
	{#State 24
		DEFAULT => -14
	},
	{#State 25
		ACTIONS => {
			"\n" => 63
		}
	},
	{#State 26
		ACTIONS => {
			'NUMBER' => 64
		}
	},
	{#State 27
		ACTIONS => {
			"\n" => 65
		}
	},
	{#State 28
		ACTIONS => {
			'CODE' => 66
		}
	},
	{#State 29
		ACTIONS => {
			"\n" => 67
		}
	},
	{#State 30
		ACTIONS => {
			"\n" => 68
		}
	},
	{#State 31
		DEFAULT => -4
	},
	{#State 32
		ACTIONS => {
			"\n" => 69
		}
	},
	{#State 33
		ACTIONS => {
			"!" => 74,
			'CODE' => 70,
			'IDENT' => 72
		},
		DEFAULT => -50,
		GOTOS => {
			'neg' => 73,
			'perlident' => 71
		}
	},
	{#State 34
		ACTIONS => {
			"\n" => 75
		}
	},
	{#State 35
		ACTIONS => {
			"\n" => 76
		}
	},
	{#State 36
		DEFAULT => -69
	},
	{#State 37
		ACTIONS => {
			'IDENT' => 80,
			"%%" => 77,
			'error' => 79
		},
		GOTOS => {
			'rules' => 78
		}
	},
	{#State 38
		DEFAULT => -67
	},
	{#State 39
		ACTIONS => {
			":" => 81
		}
	},
	{#State 40
		ACTIONS => {
			'TAILCODE' => 83
		},
		DEFAULT => -106,
		GOTOS => {
			'tail' => 82
		}
	},
	{#State 41
		ACTIONS => {
			";" => 84
		}
	},
	{#State 42
		ACTIONS => {
			'IDENT' => 85
		}
	},
	{#State 43
		ACTIONS => {
			'LITERAL' => 86,
			'IDENT' => 31
		},
		GOTOS => {
			'toklist' => 89,
			'ident' => 88,
			'symbol' => 87,
			'tokendef' => 90
		}
	},
	{#State 44
		ACTIONS => {
			'IDENT' => 31,
			'LITERAL' => 86
		},
		GOTOS => {
			'toklist' => 91,
			'ident' => 88,
			'symbol' => 87,
			'tokendef' => 90
		}
	},
	{#State 45
		DEFAULT => -8
	},
	{#State 46
		ACTIONS => {
			'LITERAL' => 86,
			'IDENT' => 31
		},
		GOTOS => {
			'symlist' => 92,
			'symbol' => 93,
			'ident' => 94
		}
	},
	{#State 47
		DEFAULT => -28
	},
	{#State 48
		DEFAULT => -13
	},
	{#State 49
		ACTIONS => {
			"\n" => 95
		}
	},
	{#State 50
		ACTIONS => {
			'LITERAL' => 86,
			'IDENT' => 31
		},
		GOTOS => {
			'symbol' => 87,
			'tokendef' => 90,
			'toklist' => 96,
			'ident' => 88
		}
	},
	{#State 51
		ACTIONS => {
			"\n" => 97
		}
	},
	{#State 52
		ACTIONS => {
			'CODE' => 99,
			'REGEXP' => 98
		}
	},
	{#State 53
		ACTIONS => {
			"\n" => 100
		}
	},
	{#State 54
		DEFAULT => -22
	},
	{#State 55
		ACTIONS => {
			"\n" => 101
		}
	},
	{#State 56
		DEFAULT => -35
	},
	{#State 57
		ACTIONS => {
			'IDENT' => 72,
			'LITERAL' => 102,
			'CODE' => 103
		},
		GOTOS => {
			'perlident' => 104
		}
	},
	{#State 58
		ACTIONS => {
			'IDENT' => 31
		},
		GOTOS => {
			'identlist' => 105,
			'ident' => 106
		}
	},
	{#State 59
		ACTIONS => {
			"\n" => 107
		}
	},
	{#State 60
		DEFAULT => -31
	},
	{#State 61
		ACTIONS => {
			'LITERAL' => 86,
			'IDENT' => 31
		},
		GOTOS => {
			'ident' => 88,
			'toklist' => 108,
			'tokendef' => 90,
			'symbol' => 87
		}
	},
	{#State 62
		DEFAULT => 0
	},
	{#State 63
		DEFAULT => -37
	},
	{#State 64
		ACTIONS => {
			"\n" => 109,
			'NUMBER' => 110
		}
	},
	{#State 65
		DEFAULT => -36
	},
	{#State 66
		ACTIONS => {
			"\n" => 111
		}
	},
	{#State 67
		DEFAULT => -49
	},
	{#State 68
		DEFAULT => -34
	},
	{#State 69
		DEFAULT => -21
	},
	{#State 70
		ACTIONS => {
			"\n" => 112
		}
	},
	{#State 71
		ACTIONS => {
			"?" => 114,
			"::" => 113
		}
	},
	{#State 72
		DEFAULT => -9
	},
	{#State 73
		ACTIONS => {
			'REGEXP' => 115
		}
	},
	{#State 74
		DEFAULT => -51
	},
	{#State 75
		DEFAULT => -29
	},
	{#State 76
		DEFAULT => -27
	},
	{#State 77
		DEFAULT => -66
	},
	{#State 78
		DEFAULT => -68
	},
	{#State 79
		ACTIONS => {
			";" => 116
		}
	},
	{#State 80
		ACTIONS => {
			":" => 117
		}
	},
	{#State 81
		DEFAULT => -71,
		GOTOS => {
			'@70-2' => 118
		}
	},
	{#State 82
		DEFAULT => -1
	},
	{#State 83
		DEFAULT => -107
	},
	{#State 84
		DEFAULT => -72
	},
	{#State 85
		ACTIONS => {
			">" => 119
		}
	},
	{#State 86
		DEFAULT => -2
	},
	{#State 87
		DEFAULT => -63
	},
	{#State 88
		ACTIONS => {
			"=" => 120
		},
		DEFAULT => -3
	},
	{#State 89
		ACTIONS => {
			"\n" => 122,
			'IDENT' => 31,
			'LITERAL' => 86
		},
		GOTOS => {
			'ident' => 88,
			'symbol' => 87,
			'tokendef' => 121
		}
	},
	{#State 90
		DEFAULT => -57
	},
	{#State 91
		ACTIONS => {
			'LITERAL' => 86,
			'IDENT' => 31,
			"\n" => 123
		},
		GOTOS => {
			'ident' => 88,
			'symbol' => 87,
			'tokendef' => 121
		}
	},
	{#State 92
		ACTIONS => {
			"\n" => 124,
			'IDENT' => 31,
			'LITERAL' => 86
		},
		GOTOS => {
			'symbol' => 125,
			'ident' => 94
		}
	},
	{#State 93
		DEFAULT => -55
	},
	{#State 94
		DEFAULT => -3
	},
	{#State 95
		DEFAULT => -33
	},
	{#State 96
		ACTIONS => {
			'IDENT' => 31,
			'LITERAL' => 86,
			"\n" => 126
		},
		GOTOS => {
			'ident' => 88,
			'symbol' => 87,
			'tokendef' => 121
		}
	},
	{#State 97
		DEFAULT => -23
	},
	{#State 98
		ACTIONS => {
			"\n" => 127
		}
	},
	{#State 99
		ACTIONS => {
			"\n" => 128
		}
	},
	{#State 100
		DEFAULT => -24
	},
	{#State 101
		DEFAULT => -48
	},
	{#State 102
		ACTIONS => {
			"\n" => 129
		}
	},
	{#State 103
		ACTIONS => {
			"\n" => 130
		}
	},
	{#State 104
		ACTIONS => {
			"\n" => 131,
			"::" => 113,
			'LITERAL' => 132
		}
	},
	{#State 105
		ACTIONS => {
			'IDENT' => 31,
			"\n" => 133
		},
		GOTOS => {
			'ident' => 134
		}
	},
	{#State 106
		DEFAULT => -65
	},
	{#State 107
		DEFAULT => -32
	},
	{#State 108
		ACTIONS => {
			"\n" => 135,
			'LITERAL' => 86,
			'IDENT' => 31
		},
		GOTOS => {
			'ident' => 88,
			'symbol' => 87,
			'tokendef' => 121
		}
	},
	{#State 109
		DEFAULT => -46
	},
	{#State 110
		ACTIONS => {
			"\n" => 136
		}
	},
	{#State 111
		DEFAULT => -30
	},
	{#State 112
		DEFAULT => -39
	},
	{#State 113
		ACTIONS => {
			'IDENT' => 137
		}
	},
	{#State 114
		ACTIONS => {
			'LABEL' => 140,
			'IDENT' => 138
		},
		GOTOS => {
			'prodname' => 139
		}
	},
	{#State 115
		ACTIONS => {
			"?" => 141
		}
	},
	{#State 116
		DEFAULT => -74
	},
	{#State 117
		ACTIONS => {
			'NAME' => 144
		},
		DEFAULT => -97,
		GOTOS => {
			'optname' => 145,
			'rhss' => 142,
			'rule' => 143
		}
	},
	{#State 118
		ACTIONS => {
			'NAME' => 144
		},
		DEFAULT => -97,
		GOTOS => {
			'rule' => 143,
			'rhss' => 146,
			'optname' => 145
		}
	},
	{#State 119
		DEFAULT => -53
	},
	{#State 120
		ACTIONS => {
			'REGEXP' => 147,
			'CODE' => 148,
			"%" => 149
		}
	},
	{#State 121
		DEFAULT => -56
	},
	{#State 122
		DEFAULT => -19
	},
	{#State 123
		DEFAULT => -18
	},
	{#State 124
		DEFAULT => -20
	},
	{#State 125
		DEFAULT => -54
	},
	{#State 126
		DEFAULT => -17
	},
	{#State 127
		DEFAULT => -26
	},
	{#State 128
		DEFAULT => -25
	},
	{#State 129
		DEFAULT => -43
	},
	{#State 130
		DEFAULT => -42
	},
	{#State 131
		DEFAULT => -44
	},
	{#State 132
		ACTIONS => {
			"\n" => 150
		}
	},
	{#State 133
		DEFAULT => -38
	},
	{#State 134
		DEFAULT => -64
	},
	{#State 135
		DEFAULT => -16
	},
	{#State 136
		DEFAULT => -47
	},
	{#State 137
		DEFAULT => -10
	},
	{#State 138
		ACTIONS => {
			'LABEL' => 151
		},
		DEFAULT => -5
	},
	{#State 139
		ACTIONS => {
			":" => 152
		}
	},
	{#State 140
		DEFAULT => -6
	},
	{#State 141
		ACTIONS => {
			'IDENT' => 138,
			'LABEL' => 140
		},
		GOTOS => {
			'prodname' => 153
		}
	},
	{#State 142
		ACTIONS => {
			"|" => 155,
			";" => 154
		}
	},
	{#State 143
		DEFAULT => -76
	},
	{#State 144
		ACTIONS => {
			'IDENT' => 156,
			'LABEL' => 157
		}
	},
	{#State 145
		ACTIONS => {
			"(" => 160,
			"\$" => 163,
			'CODE' => 165,
			'VIEWPOINT' => 167,
			'BEGINCODE' => 166,
			'DPREC' => 168,
			'IDENT' => 31,
			'LITERAL' => 86
		},
		DEFAULT => -79,
		GOTOS => {
			'rhselt' => 161,
			'rhseltwithid' => 159,
			'rhselts' => 164,
			'rhs' => 158,
			'ident' => 94,
			'symbol' => 169,
			'code' => 162
		}
	},
	{#State 146
		ACTIONS => {
			"|" => 155,
			";" => 170
		}
	},
	{#State 147
		DEFAULT => -58
	},
	{#State 148
		DEFAULT => -62
	},
	{#State 149
		ACTIONS => {
			'REGEXP' => 171
		}
	},
	{#State 150
		DEFAULT => -45
	},
	{#State 151
		DEFAULT => -7
	},
	{#State 152
		ACTIONS => {
			'LABEL' => 140,
			'IDENT' => 138
		},
		GOTOS => {
			'prodname' => 172
		}
	},
	{#State 153
		ACTIONS => {
			":" => 173
		}
	},
	{#State 154
		DEFAULT => -73
	},
	{#State 155
		ACTIONS => {
			'NAME' => 144
		},
		DEFAULT => -97,
		GOTOS => {
			'optname' => 145,
			'rule' => 174
		}
	},
	{#State 156
		ACTIONS => {
			'LABEL' => 175
		},
		DEFAULT => -98
	},
	{#State 157
		DEFAULT => -100
	},
	{#State 158
		ACTIONS => {
			'PREC' => 177
		},
		DEFAULT => -78,
		GOTOS => {
			'prec' => 176
		}
	},
	{#State 159
		DEFAULT => -82
	},
	{#State 160
		ACTIONS => {
			'NAME' => 144
		},
		DEFAULT => -97,
		GOTOS => {
			'optname' => 178
		}
	},
	{#State 161
		ACTIONS => {
			'PLUS' => 179,
			'OPTION' => 183,
			"<" => 180,
			'STAR' => 181,
			"." => 182
		},
		DEFAULT => -86
	},
	{#State 162
		DEFAULT => -88
	},
	{#State 163
		ACTIONS => {
			'LITERAL' => 86,
			'DPREC' => 168,
			'IDENT' => 31,
			'BEGINCODE' => 166,
			'VIEWPOINT' => 167,
			'CODE' => 165,
			'error' => 185,
			"(" => 160
		},
		GOTOS => {
			'symbol' => 169,
			'code' => 162,
			'ident' => 94,
			'rhselt' => 184
		}
	},
	{#State 164
		ACTIONS => {
			'IDENT' => 31,
			'DPREC' => 168,
			'LITERAL' => 86,
			'CODE' => 165,
			'BEGINCODE' => 166,
			'VIEWPOINT' => 167,
			"\$" => 163,
			"(" => 160
		},
		DEFAULT => -80,
		GOTOS => {
			'symbol' => 169,
			'code' => 162,
			'rhseltwithid' => 186,
			'ident' => 94,
			'rhselt' => 161
		}
	},
	{#State 165
		DEFAULT => -104
	},
	{#State 166
		DEFAULT => -105
	},
	{#State 167
		DEFAULT => -90
	},
	{#State 168
		ACTIONS => {
			'IDENT' => 31
		},
		GOTOS => {
			'ident' => 187
		}
	},
	{#State 169
		DEFAULT => -87
	},
	{#State 170
		DEFAULT => -70
	},
	{#State 171
		ACTIONS => {
			"=" => 188,
			"!" => 189
		},
		DEFAULT => -59
	},
	{#State 172
		ACTIONS => {
			"\n" => 190
		}
	},
	{#State 173
		ACTIONS => {
			'LABEL' => 140,
			'IDENT' => 138
		},
		GOTOS => {
			'prodname' => 191
		}
	},
	{#State 174
		DEFAULT => -75
	},
	{#State 175
		DEFAULT => -99
	},
	{#State 176
		ACTIONS => {
			'BEGINCODE' => 166,
			'CODE' => 165
		},
		DEFAULT => -102,
		GOTOS => {
			'epscode' => 193,
			'code' => 192
		}
	},
	{#State 177
		ACTIONS => {
			'IDENT' => 31,
			'LITERAL' => 86
		},
		GOTOS => {
			'symbol' => 194,
			'ident' => 94
		}
	},
	{#State 178
		ACTIONS => {
			"\$" => 163,
			"(" => 160,
			'IDENT' => 31,
			'DPREC' => 168,
			'LITERAL' => 86,
			'CODE' => 165,
			'VIEWPOINT' => 167,
			'BEGINCODE' => 166
		},
		DEFAULT => -79,
		GOTOS => {
			'symbol' => 169,
			'code' => 162,
			'rhs' => 195,
			'rhseltwithid' => 159,
			'rhselts' => 164,
			'ident' => 94,
			'rhselt' => 161
		}
	},
	{#State 179
		DEFAULT => -96
	},
	{#State 180
		ACTIONS => {
			'STAR' => 196,
			'PLUS' => 197
		}
	},
	{#State 181
		DEFAULT => -92
	},
	{#State 182
		ACTIONS => {
			'IDENT' => 198
		}
	},
	{#State 183
		DEFAULT => -94
	},
	{#State 184
		ACTIONS => {
			'PLUS' => 179,
			'STAR' => 181,
			"<" => 180,
			'OPTION' => 183
		},
		DEFAULT => -84
	},
	{#State 185
		DEFAULT => -85
	},
	{#State 186
		DEFAULT => -81
	},
	{#State 187
		DEFAULT => -89
	},
	{#State 188
		ACTIONS => {
			'IDENT' => 199
		}
	},
	{#State 189
		ACTIONS => {
			'IDENT' => 200
		}
	},
	{#State 190
		DEFAULT => -40
	},
	{#State 191
		ACTIONS => {
			"\n" => 201
		}
	},
	{#State 192
		DEFAULT => -103
	},
	{#State 193
		DEFAULT => -77
	},
	{#State 194
		DEFAULT => -101
	},
	{#State 195
		ACTIONS => {
			")" => 202
		}
	},
	{#State 196
		ACTIONS => {
			'IDENT' => 31,
			'LITERAL' => 86
		},
		GOTOS => {
			'ident' => 94,
			'symbol' => 203
		}
	},
	{#State 197
		ACTIONS => {
			'LITERAL' => 86,
			'IDENT' => 31
		},
		GOTOS => {
			'ident' => 94,
			'symbol' => 204
		}
	},
	{#State 198
		DEFAULT => -83
	},
	{#State 199
		DEFAULT => -60
	},
	{#State 200
		DEFAULT => -61
	},
	{#State 201
		DEFAULT => -41
	},
	{#State 202
		DEFAULT => -91
	},
	{#State 203
		ACTIONS => {
			">" => 205
		}
	},
	{#State 204
		ACTIONS => {
			">" => 206
		}
	},
	{#State 205
		DEFAULT => -93
	},
	{#State 206
		DEFAULT => -95
	}
],
    yyrules  =>
[
	[#Rule _SUPERSTART
		 '$start', 2, undef
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule eyapp_1
		 'eyapp', 3, undef
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule symbol_2
		 'symbol', 1,
sub { 
                    my($symbol,$lineno)=@{$_[1]};
                        exists($$syms{$symbol})
                    or  do {
                        $$syms{$symbol} = $lineno;
                        $$term{$symbol} = undef;

                        # Warning! 
                        $$semantic{$symbol} = 0 unless exists($$semantic{$symbol});
                    };
                    $_[1]
                }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule symbol_3
		 'symbol', 1, undef
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule ident_4
		 'ident', 1,
sub { 
                    my($symbol,$lineno)=@{$_[1]};
                        exists($$syms{$symbol})
                    or  do {
                        $$syms{$symbol} = $lineno;
                        $$term{$symbol} = undef;

                        # Warning! 
                        $$semantic{$symbol} = 1 unless exists($$semantic{$symbol});
                        # Not declared identifier?
                        $nondeclared{$symbol} = 1 unless (exists($$nterm{$symbol}) or $$term{$symbol});
                    };
                    $_[1]
                }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule prodname_5
		 'prodname', 1, undef
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule prodname_6
		 'prodname', 1, undef
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule prodname_7
		 'prodname', 2,
sub { 
              $_[1][0] .= $_[2][0];
              $_[1];
            }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule head_8
		 'head', 2, undef
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule perlident_9
		 'perlident', 1, undef
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule perlident_10
		 'perlident', 3,
sub { 
              $_[1][0] .= "::".$_[3][0];
              $_[1];
            }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule headsec_11
		 'headsec', 0, undef
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule headsec_12
		 'headsec', 1, undef
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule decls_13
		 'decls', 2, undef
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule decls_14
		 'decls', 1, undef
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule decl_15
		 'decl', 1, undef
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule decl_16
		 'decl', 4,
sub { 
                for (@{$_[3]}) {
                    my($symbol,$lineno, $def)=@$_;

                    #    exists($$token{$symbol})
                    #and do {
                    #    _SyntaxError(0,
                    #            "Token $symbol redefined: ".
                    #            "Previously defined line $$syms{$symbol}",
                    #            $lineno);
                    #    next;
                    #};
                    $$token{$symbol}=$lineno;
                    $$term{$symbol} = [ ];
                    $$semantic{$symbol} = 1;
                    $$termdef{$symbol} = $def if $def;
                }
                undef
            }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule decl_17
		 'decl', 4,
sub { 
                for (@{$_[3]}) {
                    my($symbol,$lineno, $def)=@$_;

                    #    exists($$token{$symbol})
                    #and do {
                    #    _SyntaxError(0,
                    #            "Token $symbol redefined: ".
                    #            "Previously defined line $$syms{$symbol}",
                    #            $lineno);
                    #    next;
                    #};
                    $$token{$symbol}=$lineno;
                    $$term{$symbol} = [ ];
                    $$semantic{$symbol} = 0;
                    $$termdef{$symbol} = $def if $def;
                }
                undef
            }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule decl_18
		 'decl', 4,
sub { 
                for (@{$_[3]}) {
                    my($symbol,$lineno, $def)=@$_;

                    $$token{$symbol}=$lineno;
                    $$term{$symbol} = [ ];
                    $$semantic{$symbol} = 0;
                    push @$dummy, $symbol;
                    $$termdef{$symbol} = $def if $def;
                }
                undef
            }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule decl_19
		 'decl', 4,
sub { 
                for (@{$_[3]}) {
                    my($symbol,$lineno, $def)=@$_;

                        exists($$token{$symbol})
                    and do {
                        _SyntaxError(0,
                                "Token $symbol redefined: ".
                                "Previously defined line $$syms{$symbol}",
                                $lineno);
                        next;
                    };
                    $$token{$symbol}=$lineno;
                    $$term{$symbol} = [ ];
                    $$termdef{$symbol} = $def if $def;
                }
                undef
            }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule decl_20
		 'decl', 4,
sub { 
                for (@{$_[3]}) {
                    my($symbol,$lineno)=@$_;

                        defined($$term{$symbol}[0])
                    and do {
                        _SyntaxError(1,
                            "Precedence for symbol $symbol redefined: ".
                            "Previously defined line $$syms{$symbol}",
                            $lineno);
                        next;
                    };
                    $$token{$symbol}=$lineno;
                    $$term{$symbol} = [ $_[1][0], $prec ];
                }
                ++$prec;
                undef
            }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule decl_21
		 'decl', 3,
sub {  
              $start=$_[2][0] unless $start; 
              undef 
            }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule decl_22
		 'decl', 2,
sub { 
              # TODO: Instead of ident has to be a prefix!!!
              $prefix=$_[1][0]; 
              undef 
            }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule decl_23
		 'decl', 3,
sub { 
              push @{$_[2]}, 'CODE';
              $whites = $_[2]; 
            }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule decl_24
		 'decl', 3,
sub { 
              push @{$_[2]}, 'REGEXP';
              $whites = $_[2]; 
            }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule decl_25
		 'decl', 4,
sub { 
              push @{$_[3]}, 'CODE';
              $whites = $_[3]; 
            }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule decl_26
		 'decl', 4,
sub { 
              push @{$_[3]}, 'REGEXP';
              $whites = $_[3]; 
            }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule decl_27
		 'decl', 3,
sub { 
              $namingscheme = $_[2];
              undef  
            }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule decl_28
		 'decl', 2,
sub {  push(@$head,$_[1]); undef }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule decl_29
		 'decl', 3,
sub {  undef }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule decl_30
		 'decl', 3,
sub {  $defaultaction = $_[2]; undef }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule decl_31
		 'decl', 2,
sub {  
                                           $incremental = ''; 
                                           undef 
                                        }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule decl_32
		 'decl', 3,
sub {  
                                           $incremental = $_[2][0]; 
                                           undef 
                                        }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule decl_33
		 'decl', 3,
sub {  
                                           my ($code, $line) = @{$_[2]};
                                           push @$head, [ make_lexer($code, $line), $line]; 
                                           $lexer = 1;
                                           undef 
                                         }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule decl_34
		 'decl', 2,
sub {  
            $tree = $buildingtree = 1;
            $bypass = ($_[1][0] =~m{bypass})? 1 : 0;
            $alias = ($_[1][0] =~m{alias})? 1 : 0;
            $defaultaction = [ ' goto &Parse::Eyapp::Driver::YYBuildAST ', $lineno[0]]; 
            undef 
          }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule decl_35
		 'decl', 2,
sub {  
            $metatree = $tree = $buildingtree = 1;
            undef 
          }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule decl_36
		 'decl', 2,
sub {  
            $strict = 1;
            undef 
          }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule decl_37
		 'decl', 2,
sub {  
            $nocompact = 1;
            undef 
          }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule decl_38
		 'decl', 4,
sub { 
                for ( @{$_[3]} ) {
                    my($symbol,$lineno)=@$_;

                        exists($$nterm{$symbol})
                    and do {
                        _SyntaxError(0,
                                "Non-terminal $symbol redefined: ".
                                "Previously defined line $$syms{$symbol}",
                                $lineno);
                        next;
                    };
                    delete($$term{$symbol});   #not a terminal
                    $$nterm{$symbol}=undef;    #is a non-terminal
                }
            }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule decl_39
		 'decl', 4,
sub { 
              my ($name, $code) = @_[2,3];
              my ($cn, $line) = @$name;


              my ($c, $li) = @$code;

              # TODO: this must be in Output
              my $conflict_header = <<"CONFLICT_HEADER";
  my \$self = \$_[0];
  for (\${\$self->input()}) {  
#line $li "$filename" 
CONFLICT_HEADER
              $c =~ s/^/$conflict_header/; # }

              # {
              # follows the closing curly bracket of the for .. to contextualize!!!!!!                 v
              $c =~ s/$/\n################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################\n  }\n/;
              #$code->[0] = $c;
              $conflict{$cn}{codeh} = $c;
              $conflict{$cn}{line} = $line;

              $$syms{$cn} = $line;
              #$$nterm{$cn} = undef;

              undef;
            }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule decl_40
		 'decl', 8,
sub { 
              #print "<@{$_[2]} @{$_[3]} @{$_[5]} @{$_[7]}>\n";
            
              my $conflict = $_[2];
              my ($startsymbol, $line) = @{$_[3]};
              my @prodname = ($_[5][0], $_[7][0]);

              my $cn = $conflict->[0];

              my $c = <<"CONFLICT_HEADER";
  my \$self = \$_[0];
  for (\${\$self->input()}) {  
#line $line "$filename" 
    \$self->YYIf('$startsymbol', '$prodname[0]', '$prodname[1]');
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
  }
CONFLICT_HEADER

              $conflict{$cn}{codeh} = $c;
              $conflict{$cn}{line} = $line;

              $$syms{$cn} = $line;
              $$nterm{$cn} = undef;

              #$$nterm{$startsymbol} = undef;
              #delete $$syms{$startsymbol};


              if ($startsymbol eq 'EMPTY') {
              $c = <<"NESTEDPARSING";
{ \$self->YYIs('EMPTY', 1); }
NESTEDPARSING
              }
              else {
              $c = <<"NESTEDPARSING";
{ \$self->YYNestedParse('$startsymbol'); }
NESTEDPARSING
              }

              explorer_handler($conflict, [$c, $line]);

              undef;
            }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule decl_41
		 'decl', 9,
sub { 
            
              my $conflict = $_[2];
              my $neg = $_[3];
              my ($regexp, $line) = @{$_[4]};
              my @prodname = ($_[6][0], $_[8][0]);

              my $cn = $conflict->[0];

              my $c = <<"CONFLICT_HEADER";
  my \$self = \$_[0];
  for (\${\$self->input()}) {  
#line $line "$filename" 
    \$self->YYIf('.regexp', '$prodname[0]', '$prodname[1]');
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
  }
CONFLICT_HEADER

              $conflict{$cn}{codeh} = $c;
              $conflict{$cn}{line} = $line;

              $$syms{$cn} = $line;
              $$nterm{$cn} = undef;
              $regexp = substr($regexp,1,-1);

              if (!$neg) {
                $regexp = "\\G(?=$regexp)"; 
              }
              else {
                $regexp = "\\G(?!$regexp)"; 
              }

              $c = <<"NESTEDPARSING";
{ \$self->YYNestedRegexp('$regexp'); }
NESTEDPARSING

              explorer_handler($conflict, [$c, $line]);

              undef;
            }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule decl_42
		 'decl', 4,
sub { 
              my ($name, $code) = @_[2,3];

              explorer_handler($name, $code);
            }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule decl_43
		 'decl', 4,
sub { 
              my ($name, $startsymbol) = @_[2,3];

              my $c = <<"NESTEDPARSING";
{ \$self->YYNestedParse($startsymbol->[0]); }
NESTEDPARSING
              my $li = $startsymbol->[1];

              explorer_handler($name, [$c, $li]);
            }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule decl_44
		 'decl', 4,
sub { 
              my ($name, $startsymbol) = @_[2,3];

              my $c = <<"NESTEDPARSING";
{ \$self->YYNestedParse('$startsymbol->[0]'); }
NESTEDPARSING
              my $li = $startsymbol->[1];

              explorer_handler($name, [$c, $li]);
            }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule decl_45
		 'decl', 5,
sub { 
              my ($name, $startsymbol, $file) = @_[2,4];

              my $c = <<"NESTEDPARSING";
{ \$self->YYNestedParse('$startsymbol->[0]', $file->[0]); }
NESTEDPARSING
              my $li = $startsymbol->[1];

              explorer_handler($name, [$c, $li]);
            }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule decl_46
		 'decl', 3,
sub {  $expect=$_[2][0]; undef }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule decl_47
		 'decl', 4,
sub {  $expect= [ $_[2][0], $_[3][0]]; undef }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule decl_48
		 'decl', 3,
sub {  
                                          $expect = 0 unless defined($expect);
                                          croak "Number of reduce-reduce conflicts is redefined (line $_[2][1], file: $filename)\n" if ref($expect);
                                          $expect= [ $expect, $_[2][0]]; 
                                          undef 
                                        }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule decl_49
		 'decl', 2,
sub {  $_[0]->YYErrok }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule neg_50
		 'neg', 0,
sub { }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule neg_51
		 'neg', 1,
sub {  1; }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule typedecl_52
		 'typedecl', 0, undef
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule typedecl_53
		 'typedecl', 3, undef
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule symlist_54
		 'symlist', 2,
sub {  push(@{$_[1]},$_[2]); $_[1] }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule symlist_55
		 'symlist', 1,
sub {  [ $_[1] ] }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule toklist_56
		 'toklist', 2,
sub {  push(@{$_[1]},$_[2]); $_[1] }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule toklist_57
		 'toklist', 1,
sub {  [ $_[1] ] }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule tokendef_58
		 'tokendef', 3,
sub {  
                                    push @{$_[3]}, 'REGEXP';
                                    push @{$_[1]}, $_[3]; 
                                    $_[1] 
                                 }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule tokendef_59
		 'tokendef', 4,
sub {  
                                    push @{$_[4]}, 'CONTEXTUAL_REGEXP';
                                    push @{$_[1]}, $_[4]; 
                                    $_[1] 
                                 }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule tokendef_60
		 'tokendef', 6,
sub {  
                                    push @{$_[4]}, 'CONTEXTUAL_REGEXP_MATCH';
                                    push @{$_[4]}, $_[6];
                                    push @{$_[1]}, $_[4]; 
                                    $_[1] 
                                 }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule tokendef_61
		 'tokendef', 6,
sub {  
                                    push @{$_[4]}, 'CONTEXTUAL_REGEXP_NOMATCH';
                                    push @{$_[4]}, $_[6];
                                    push @{$_[1]}, $_[4]; 
                                    $_[1] 
                                 }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule tokendef_62
		 'tokendef', 3,
sub {  
                                    push @{$_[3]}, 'CODE';
                                    push @{$_[1]}, $_[3]; 
                                    $_[1] 
                                 }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule tokendef_63
		 'tokendef', 1,
sub { 
                                   push @{$_[1]}, [ @{$_[1]}, 'LITERAL'];
                                   $_[1];
                                 }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule identlist_64
		 'identlist', 2,
sub {  push(@{$_[1]},$_[2]); $_[1] }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule identlist_65
		 'identlist', 1,
sub {  [ $_[1] ] }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule body_66
		 'body', 2,
sub { 
                $start
            or  $start=$$rules[1][0];

                ref($$nterm{$start})
            or  _SyntaxError(2,"Start symbol $start not found ".
                                "in rules section",$_[2][1]);

            # Add conflict handlers
            # [ left hand side,   right hand side,  precedence, rulename, code, ]
            for my $A (keys %conflict) { 

              if  (defined($conflict{$A}{explorer}))  {
                  if (!$conflict{$A}{totalviewpoint}) {
                      my $code = $conflict{$A}{codeh};
                      $conflict{$A}{codeh} = "{ $conflict{$A}{explorer} }\n{ $code }";
                      delete $$syms{$A};
                      delete $$nterm{$A};
                      delete $$term{$A};
                      delete $conflict{$A}{explorer};
                  }
                  else {
                    my $lhs = [$A, $conflict{$A}{explorerline}];
                    my $code = $conflict{$A}{explorer};
                    my $rhss = [ rhs([], name => $lhs, code => $code), ];
                    _AddRules($lhs, $rhss);
                    delete $conflict{$A}{explorer};
                  }
              }
              else {
                 delete $$syms{$A};
                 delete $$nterm{$A};
                 delete $$term{$A};
              }
            }

            # # If exists an @identifiers that is not a nterm and not a term is a warn
            if ($strict) {
              for (keys %nondeclared) {
                  warn "Warning! Non declared token $_ at line $$syms{$_} of $filename\n" 
                unless ($_ eq 'error' || $$term{$_} || exists($$nterm{$_}) || exists($conflict{$_}));
              }
            }
            # Superstart rule
            # [ left hand side,   right hand side,  precedence, rulename, code, ]
            $$rules[0]=[ '$start', [ $start, chr(0) ], undef, undef, undef,];  

        }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule body_67
		 'body', 1,
sub {  _SyntaxError(2,"No rules in input grammar",$_[1][1]); }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule rulesec_68
		 'rulesec', 2, undef
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule rulesec_69
		 'rulesec', 1, undef
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule startrules_70
		 'startrules', 5,
sub {  _AddRules($_[1],$_[4]); undef }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule _CODE
		 '@70-2', 0,
sub {  $start = $_[1][0] unless $start; }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule startrules_72
		 'startrules', 2,
sub {  $_[0]->YYErrok }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule rules_73
		 'rules', 4,
sub {  _AddRules($_[1],$_[3]); undef }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule rules_74
		 'rules', 2,
sub {  $_[0]->YYErrok }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule rhss_75
		 'rhss', 3,
sub {  push(@{$_[1]},$_[3]); $_[1] }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule rhss_76
		 'rhss', 1,
sub {  [ $_[1] ] }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule rule_77
		 'rule', 4,
sub {  
            my ($name, $rhs, $prec, $code) = @_[1..4];

            my %index = symbol_index($rhs);
            $code->[0] = prefixcode(%index).$code->[0] if ($code);

            insert_delaying_code(\$code) if $metatree;
            make_accessors($name, $rhs);
            
            push(@{$rhs}, $prec, $name, $code);  # only three???? what with prefixofcode?
            $rhs
          }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule rule_78
		 'rule', 2,
sub { 
            my ($name, $rhs) = @_[1, 2];
            my $code;

            # Be careful: $defaultaction must be replicated per action
            # to emulate "yacc/yapp" true behavior.
            # There was a previous bug when %metatree and %defaultaction
            # were activated ------------------V
            $code = $defaultaction && [ @$defaultaction ];

                defined($rhs)
            and $rhs->[-1][0] eq 'CODE'
            and $code = ${pop(@{$rhs})}[1];

            my %index = symbol_index($rhs);
            $code->[0] = prefixcode(%index).$code->[0] if ($code);
            make_accessors($name, $rhs);

            insert_delaying_code(\$code) if $metatree;
            
            push(@{$rhs}, undef, $name, $code);

            $rhs
        }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule rhs_79
		 'rhs', 0, undef
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule rhs_80
		 'rhs', 1, undef
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule rhselts_81
		 'rhselts', 2,
sub {  
                push(@{$_[1]},$_[2]);
                $_[1] 
              }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule rhselts_82
		 'rhselts', 1,
sub {  [ $_[1] ] }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule rhseltwithid_83
		 'rhseltwithid', 3,
sub { 
          push @{$_[1][1]}, $_[3][0];
          $_[1]
        }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule rhseltwithid_84
		 'rhseltwithid', 2,
sub { 
          # check that is an identifier
            _SyntaxError(2,"\$ is allowed for identifiers only (Use dot notation instead)",$lineno[0]) 
          if not_an_id($_[2][1][0]);
          push @{$_[2][1]}, $_[2][1][0];
          $_[2]
        }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule rhseltwithid_85
		 'rhseltwithid', 2,
sub {  _SyntaxError(2,"\$ is allowed for identifiers only",$lineno[0]) }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule rhseltwithid_86
		 'rhseltwithid', 1,
sub { 
         $_[1];
       }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule rhselt_87
		 'rhselt', 1,
sub {  [ 'SYMB', $_[1] ] }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule rhselt_88
		 'rhselt', 1,
sub {  [ 'CODE', $_[1] ] }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule rhselt_89
		 'rhselt', 2,
sub {  
           my $cname = $_[2][0];
           $conflict{$cname}{total}++;
           [ 'CONFLICTHANDLER', $_[2] ] 
        }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule rhselt_90
		 'rhselt', 1,
sub {  
           $conflict{$_[1][0]}{totalviewpoint}++;
           [ 'CONFLICTVIEWPOINT', $_[1] ] 
        }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule rhselt_91
		 'rhselt', 4,
sub {  
           my ($name, $rhs) = @_[2, 3];


           my $code = $defaultaction && [ @$defaultaction ];
           $code =[ ' goto &Parse::Eyapp::Driver::YYActionforParenthesis', $lineno[0]] unless $metatree;

             defined($rhs)
           and $rhs->[-1][0] eq 'CODE'
           and $code = ${pop(@$rhs)}[1];

           my %index = symbol_index($rhs);
           $code->[0] = prefixcode(%index).$code->[0] if ($code);

           insert_delaying_code(\$code) if $metatree;
            
           my $A = token('PAREN-'.++$labelno);
           _AddRules($A, [[@$rhs, undef, $name, $code]]);

           [ 'SYMB', $A] 
        }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule rhselt_92
		 'rhselt', 2,
sub {  
          my ($what, $val) = @{$_[1]};
          _SyntaxError(1, "Star(*) operator can't be applied to an action", $lineno[0]) 
            if $what eq 'CODE';
          my $A = token('STAR-'.++$labelno);
          my $code_rec = ' goto &Parse::Eyapp::Driver::YYActionforT_TX1X2 ';
          my $code_empty = ' goto &Parse::Eyapp::Driver::YYActionforT_empty ';

          my $rhss = [
                      rhs([ $A, $val], name => $_[2], code => $code_rec),
                      rhs([],          name => $_[2], code => $code_empty),
                    ];
          _AddRules($A, $rhss);
          [ 'SYMB', $A]
        }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule rhselt_93
		 'rhselt', 5,
sub {  
          my ($what, $val) = @{$_[1]};
          _SyntaxError(1, "Star(*) operator can't be applied to an action", $lineno[0]) 
            if $what eq 'CODE';
          my $B = token('STAR-'.++$labelno);
          my $code_rec = ' goto &Parse::Eyapp::Driver::YYActionforT_TX1X2 ';
          my $code_single = ' goto &Parse::Eyapp::Driver::YYActionforT_single ';
          my $rhss = [#rhs [token , [value, line]] ...,   prec,  name,  code ]
                      rhs([ $B, $_[4], $val], name => $_[3], code => $code_rec),
                      rhs([ $val],            name =>  $_[3], code => $code_single),
                    ];
          _AddRules($B, $rhss);

          my $A = token('STAR-'.++$labelno);
          my $code_empty = ' goto &Parse::Eyapp::Driver::YYActionforT_empty ';
          $code_single = ' { $_[1] } # optimize '."\n";

          $rhss = [
              rhs([ $B ], name => $_[3], code => $code_single ),
              rhs([],     name => $_[3], code => $code_empty),
          ];
          _AddRules($A, $rhss);
          [ 'SYMB', $A ]
        }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule rhselt_94
		 'rhselt', 2,
sub { 
          my ($what, $val) = @{$_[1]};
          _SyntaxError(1, "Question(?) operator can't be applied to an action", $lineno[0]) 
            if $what eq 'CODE';
          my $A = token('OPTIONAL-'.++$labelno);
          my $code_single = ' goto &Parse::Eyapp::Driver::YYActionforT_single ';
          my $code_empty = ' goto &Parse::Eyapp::Driver::YYActionforT_empty ';

          my $rhss = [
                      rhs([ $val], name => $_[2], code => $code_single),
                      rhs([],      name => $_[2], code => $code_empty),
                    ];
          _AddRules($A, $rhss);
          [ 'SYMB', $A]
        }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule rhselt_95
		 'rhselt', 5,
sub {  
          my ($what, $val) = @{$_[1]};
          _SyntaxError(1, "Plus(+) operator can't be applied to an action", $lineno[0]) 
            if $what eq 'CODE';
          my $A = token('PLUS-'.++$labelno);
          my $code_rec = ' goto &Parse::Eyapp::Driver::YYActionforT_TX1X2 ';
          my $code_single = ' goto &Parse::Eyapp::Driver::YYActionforT_single ';

          my $rhss = [
            rhs([$A, $_[4], $val], name => $_[3], code => $code_rec),
            rhs([$val],            name => $_[3], code => $code_single),
          ];
          _AddRules($A, $rhss);
          [ 'SYMB', $A]
        }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule rhselt_96
		 'rhselt', 2,
sub { 
           my ($what, $val) = @{$_[1]};
           _SyntaxError(1, "Plus(+) operator can't be applied to an action", $lineno[0]) 
             if $what eq 'CODE';
           my $A = token('PLUS-'.++$labelno);
           my $code_rec = ' goto &Parse::Eyapp::Driver::YYActionforT_TX1X2 ';
           my $code_single = ' goto &Parse::Eyapp::Driver::YYActionforT_single ';

           my $rhss = [
             rhs([$A, $val], name => $_[2], code => $code_rec),
             rhs([$val],     name => $_[2], code =>  $code_single)
           ];

           _AddRules($A, $rhss);
           [ 'SYMB', $A]
        }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule optname_97
		 'optname', 0, undef
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule optname_98
		 'optname', 2,
sub {  
                      # save bypass status
           $_[2][2] = $_[1][0];
           $_[2] 
         }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule optname_99
		 'optname', 3,
sub {   # LABELs are used for dynamic conflict resolution
                      # save bypass status
           $_[2][2] = $_[1][0];
           # 0: identifier 1: line number 2: bypass 
           # concat the label to the name
           $_[2][0] .= "$_[3][0]";

           $_[2] 
         }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule optname_100
		 'optname', 2,
sub {   # LABELs are used for dynamic conflict resolution
                      # save bypass status
           $_[2][2] = $_[1][0];
           $_[2] 
         }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule prec_101
		 'prec', 2,
sub { 
                        defined($$term{$_[2][0]})
                    or  do {
                        _SyntaxError(1,"No precedence for symbol $_[2][0]",
                                         $_[2][1]);
                        return undef;
                    };

                    ++$$precterm{$_[2][0]};
                    $$term{$_[2][0]}[1];
        }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule epscode_102
		 'epscode', 0,
sub {  $defaultaction }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule epscode_103
		 'epscode', 1,
sub {  $_[1] }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule code_104
		 'code', 1,
sub {  $_[1] }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule code_105
		 'code', 1,
sub { 
        _SyntaxError(2, "%begin code is allowed only when metatree is active\n", $lineno[0])
          unless $metatree;
        my $code = $_[1];
        push @$code, 'BEGINCODE';
        return $code;
      }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule tail_106
		 'tail', 0, undef
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule tail_107
		 'tail', 1,
sub {  $tail=$_[1] }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	]
],
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
    yybypass       => 0,
    yybuildingtree => 0,
    yyprefix       => '',
    yyaccessors    => {
   },
    yyconflicthandlers => {}
,
    yystateconflict => {  },
    @_,
  );
  bless($self,$class);

  $self->make_node_classes('TERMINAL', '_OPTIONAL', '_STAR_LIST', '_PLUS_LIST', 
         '_SUPERSTART', 
         'eyapp_1', 
         'symbol_2', 
         'symbol_3', 
         'ident_4', 
         'prodname_5', 
         'prodname_6', 
         'prodname_7', 
         'head_8', 
         'perlident_9', 
         'perlident_10', 
         'headsec_11', 
         'headsec_12', 
         'decls_13', 
         'decls_14', 
         'decl_15', 
         'decl_16', 
         'decl_17', 
         'decl_18', 
         'decl_19', 
         'decl_20', 
         'decl_21', 
         'decl_22', 
         'decl_23', 
         'decl_24', 
         'decl_25', 
         'decl_26', 
         'decl_27', 
         'decl_28', 
         'decl_29', 
         'decl_30', 
         'decl_31', 
         'decl_32', 
         'decl_33', 
         'decl_34', 
         'decl_35', 
         'decl_36', 
         'decl_37', 
         'decl_38', 
         'decl_39', 
         'decl_40', 
         'decl_41', 
         'decl_42', 
         'decl_43', 
         'decl_44', 
         'decl_45', 
         'decl_46', 
         'decl_47', 
         'decl_48', 
         'decl_49', 
         'neg_50', 
         'neg_51', 
         'typedecl_52', 
         'typedecl_53', 
         'symlist_54', 
         'symlist_55', 
         'toklist_56', 
         'toklist_57', 
         'tokendef_58', 
         'tokendef_59', 
         'tokendef_60', 
         'tokendef_61', 
         'tokendef_62', 
         'tokendef_63', 
         'identlist_64', 
         'identlist_65', 
         'body_66', 
         'body_67', 
         'rulesec_68', 
         'rulesec_69', 
         'startrules_70', 
         '_CODE', 
         'startrules_72', 
         'rules_73', 
         'rules_74', 
         'rhss_75', 
         'rhss_76', 
         'rule_77', 
         'rule_78', 
         'rhs_79', 
         'rhs_80', 
         'rhselts_81', 
         'rhselts_82', 
         'rhseltwithid_83', 
         'rhseltwithid_84', 
         'rhseltwithid_85', 
         'rhseltwithid_86', 
         'rhselt_87', 
         'rhselt_88', 
         'rhselt_89', 
         'rhselt_90', 
         'rhselt_91', 
         'rhselt_92', 
         'rhselt_93', 
         'rhselt_94', 
         'rhselt_95', 
         'rhselt_96', 
         'optname_97', 
         'optname_98', 
         'optname_99', 
         'optname_100', 
         'prec_101', 
         'epscode_102', 
         'epscode_103', 
         'code_104', 
         'code_105', 
         'tail_106', 
         'tail_107', );
  $self;
}


sub _Error {
    my($value)=$_[0]->YYCurval;

    my $token = $$value[0];
    my($what)= $token ? "input: '$token'" : "symbol";

    _SyntaxError(1,"Unexpected $what",$$value[1]);
}

sub slurp_perl_code {
  my($level,$from,$code);

  $from=pos($$input);

  $level=1;
  while($$input=~/([{}])/gc) {
          substr($$input,pos($$input)-1,1) eq '\\' #Quoted
      and next;
          $level += ($1 eq '{' ? 1 : -1)
      or last;
  }
      $level
  and  _SyntaxError(2,"Unmatched { opened line $lineno[0]",-1);
  $code = substr($$input,$from,pos($$input)-$from-1);
  $lineno[1]+= $code=~tr/\n//;
  return [ $code, $lineno[0] ];
}

my %headertoken = (
  start => 'START',
  expect => 'EXPECT',
  token => 'TOKEN',
  strict => 'STRICT',
  type => 'TYPE',
  union => 'UNION',
  namingscheme => 'NAMINGSCHEME',
  metatree => 'METATREE',
  nocompact => 'NOCOMPACT',
  conflict => 'CONFLICT',
  whites    => 'WHITES',
);

# Used for <%name LIST_of_STH +>, <%name OPT_STH ?>
my %listtoken = (
  '*' => 'STAR',
  '+' => 'PLUS',
  '?' => 'OPTION',
);

my $ID = qr{[A-Za-z_][A-Za-z0-9_]*};
my $LABEL = qr{:[A-Za-z0-9_]+};
my $STRING = qr {
   '             # opening apostrophe
   (?:[^'\\]|    # an ordinary character
        \\\\|    # escaped \ i.e. \\
         \\'|    # escaped apostrophe i.e. \'
          \\     # escape i.e. \
  )*?            # non greedy repetitions
  '              # closing apostrophe
}x;

# Head section: \n separates declarations
my $HEADERWHITESPACES = qr{ 
  (?:  
      [\t\ ]+     # Any white space char but \n
    | \#[^\n]*    # Perl like comments
    |   /\*.*?\*/ # C like comments
  )+
}xs;

# Head section: \n is not significant
my $BODYWHITESPACES = qr{
  (?:
      \s+        # Any white space char, including \n
    | \#[^\n]*   # Perl like comments
    |  /\*.*?\*/ # C like comments
  )+
}xs;

my $REGEXP = qr{
   /             # opening slash
   (?:[^/\\]|    # an ordinary character
        \\\\|    # escaped \ i.e. \\
         \\/|    # escaped slash i.e. \/
          \\     # escape i.e. \
  )*?            # non greedy repetitions
  /              # closing slash
}xs;

sub _Lexer {
 
    #At EOF
        pos($$input) >= length($$input)
    and return('',[ undef, -1 ]);

    #In TAIL section
        $lexlevel > 1
    and do {
        my($pos)=pos($$input);

        $lineno[0]=$lineno[1];
        $lineno[1]=-1;
        pos($$input)=length($$input);
        return('TAILCODE',[ substr($$input,$pos), $lineno[0] ]);
    };

    #Skip blanks
            $lexlevel == 0
        ?   $$input=~m{\G($HEADERWHITESPACES)}gc
        :   $$input=~m{\G($BODYWHITESPACES)}gc
    and do {
        my($blanks)=$1;

        #Maybe At EOF
        pos($$input) >= length($$input) and return('',[ undef, -1 ]);

        $lineno[1]+= $blanks=~tr/\n//;
    };

    $lineno[0]=$lineno[1];

            $$input=~/\G($LABEL)/gc
        and return('LABEL',[ $1, $lineno[0] ]);

        $$input=~/\G($ID)/gc
    and return('IDENT',[ $1, $lineno[0] ]);


        $$input=~/\G($STRING)/gc
    and do {
        my $string = $1;

        # The string 'error' is reserved for the special token 'error'
        $string eq "'error'" and do {
            _SyntaxError(0,"Literal 'error' ".
                           "will be treated as error token",$lineno[0]);
            return('IDENT',[ 'error', $lineno[0] ]);
        };

        my $lines = $string =~ tr/\n//;
        _SyntaxError(2, "Constant string $string contains newlines",$lineno[0]) if $lines;
        $lineno[1] += $lines;

        $string = chr(0) if $string eq "''";

        return('LITERAL',[ $string, $lineno[0] ]);
    };

    # New section: body or tail
        $$input=~/\G(%%)/gc
    and do {
        ++$lexlevel;
        return($1, [ $1, $lineno[0] ]);
    };

        $$input=~/\G\s*\{/gc and return ('CODE', &slurp_perl_code());  # }

    if($lexlevel == 0) {# In head section

        $$input=~/\G%(left|right|nonassoc)/gc and return('ASSOC',[ uc($1), $lineno[0] ]);

            $$input=~/\G%\{/gc
        and do {
            my($code);

            $$input=~/\G(.*?)%}/sgc or  _SyntaxError(2,"Unmatched %{ opened line $lineno[0]",-1);

            $code=$1;
            $lineno[1]+= $code=~tr/\n//;
            return('HEADCODE',[ $code, $lineno[0] ]);
        };

        $$input=~/\G%prefix\s+([A-Za-z_][A-Za-z0-9_:]*::)/gc and return('PREFIX',[ $1, $lineno[0] ]);

            $$input=~/\G%(tree((?:\s+(?:bypass|alias)){0,2}))/gc
        and do {
          my $treeoptions =  defined($2)? $2 : '';
          return('TREE',[ $treeoptions, $lineno[0] ])
        };

        $$input=~/\G%(?:(semantic|syntactic|dummy)(?:\s+token)?)\b/gc and return(uc($1),[ undef, $lineno[0] ]);

        $$input=~/\G%(?:(incremental)(?:\s+lexer)?)\b/gc and return(uc($1),[ undef, $lineno[0] ]);

        $$input=~/\G%(lexer|defaultaction|union)\b\s*/gc   and return(uc($1),[ undef, $lineno[0] ]);

        $$input=~/\G([0-9]+)/gc   and return('NUMBER',[ $1, $lineno[0] ]);

        $$input=~/\G%expect-rr/gc and return('EXPECTRR',[ undef, $lineno[0] ]);

        $$input=~/\G%(explorer)/gc and return('EXPLORER',[ undef, $lineno[0] ]);

        $$input=~/\G%($ID)/gc     and return($headertoken{$1},[ undef, $lineno[0] ]);

        $$input=~/\G($REGEXP)/gc  and return('REGEXP',[ $1, $lineno[0] ]);

        $$input=~/\G::/gc and return('::',[ undef, $lineno[0] ]);

    }
    else {  # In rule section

            # like in <%name LIST_of_STH *>
            # like in <%name LIST_of_STH +>
            # like in <%name OPT_STH ?>
            # returns STAR or PLUS or OPTION
            $$input=~/\G(?:<\s*%name\s*($ID)\s*)?([*+?])\s*>/gc
        and return($listtoken{$2},[ $1, $lineno[0] ]);

            # like in %name LIST_of_STH *
            # like in %name LIST_of_STH +
            # like in %name OPT_STH ?
            # returns STAR or PLUS or OPTION
            $$input=~/\G(?:%name\s*($ID)\s*)?([*+?])/gc
        and return($listtoken{$2},[ $1, $lineno[0] ]);

            $$input=~/\G%no\s+bypass/gc
        and do {
          #my $bp = defined($1)?0:1; 
          return('NAME',[ 0, $lineno[0] ]);
        };

            $$input=~/\G%(prec)/gc
        and return('PREC',[ undef, $lineno[0] ]);

            $$input=~/\G%(PREC)/gc
        and return('DPREC',[ undef, $lineno[0] ]);

            $$input=~/\G%name/gc
        and do {
          # return current bypass status
          return('NAME',[ $bypass, $lineno[0] ]);
        };

    # Now label is returned in the "common" area
    #       $$input=~/\G($LABEL)/gc
    #   and return('LABEL',[ $1, $lineno[0] ]);

            $$input=~/\G%begin\s*{/gc  # }
        and return ('BEGINCODE', &slurp_perl_code());

        #********** research *************#
            $$input=~/\G%([a-zA-Z_]\w*)\?/gc
        and return('VIEWPOINT',[ $1, $lineno[0] ]);


    }

    #Always return something
        $$input=~/\G(.)/sg
    or  die "Parse::Eyapp::Grammar::Parse: Match (.) failed: report as a BUG";

    my $char = $1;

    $char =~ s/\cM/\n/; # dos to unix

    $char eq "\n" and ++$lineno[1];

    ( $char ,[ $char, $lineno[0] ]);

}

sub _SyntaxError {
    my($level,$message,$lineno)=@_;

    $message= "*".
              [ 'Warning', 'Error', 'Fatal' ]->[$level].
              "* $message, at ".
              ($lineno < 0 ? "eof" : "line $lineno")." at file $filename\n";

        $level > 1
    and die $message;

    warn $message;

        $level > 0
    and ++$nberr;

        $nberr == 20 
    and die "*Fatal* Too many errors detected.\n"
}

# _AddRules
# There was a serious error I introduced between versions 171 and 172 (subversion
# numbers).  I delayed the instruction
#       my ($tmprule)=[ $lhs, [], splice(@$rhs,-3)];
# with catastrophic consequences for the resulting
# LALR tables.
# The splice of the ($precedence, $name, $code)
# must be done before this line, if not the counts of nullables 
# will no work!
#          @$rhs
#       or  do {
#           ++$$nullable{$lhs};
#           ++$epsrules;
#       };

sub _AddRules {
    my($lhs,$lineno)=@{$_[0]};
    my($rhss)=$_[1];

        ref($$nterm{$lhs})
    and do {
        _SyntaxError(1,"Non-terminal $lhs redefined: ".
                       "Previously declared line $$syms{$lhs}",$lineno);
        return;
    };

        ref($$term{$lhs})
    and do {
        my($where) = exists($$token{$lhs}) ? $$token{$lhs} : $$syms{$lhs};
        _SyntaxError(1,"Non-terminal $lhs previously ".
                       "declared as token line $where",$lineno);
        return;
    };

        ref($$nterm{$lhs})      #declared through %type
    or  do {
            $$syms{$lhs}=$lineno;   #Say it's declared here
            delete($$term{$lhs});   #No more a terminal
    };
    $$nterm{$lhs}=[];       #It's a non-terminal now
    
    # Hal Finkel's patch: a non terminal is a semantic child
    $$semantic{$lhs} = 1; 

    my($epsrules)=0;        #To issue a warning if more than one epsilon rule

    for my $rhs (@$rhss) {
        #               ($precedence, $name, $code)
        my ($tmprule)=[ $lhs, [], splice(@$rhs,-3)];

        # Warning! the splice of the ($precedence, $name, $code)
        # must be done before this line, if not the counts of nullables 
        # will no work!
            @$rhs
        or  do {
            ++$$nullable{$lhs};
            ++$epsrules;
        };

        # Reserve position for current rule
        push(@$rules, undef);
        my $position = $#$rules;

        # Expand to auxiliary productions all the intermediate codes
        $tmprule->[1] = process_production($rhs);
        $$rules[$position] = $tmprule; 
        push(@{$$nterm{$lhs}},$position);
    }

        $epsrules > 1
    and _SyntaxError(0,"More than one empty rule for symbol $lhs",$lineno);
}

# This sub is called fro Parse::Eyapp::Grammar::new
#       0       1      2          3         4     5          6               7                  8
# Args: object, input, firstline, filename, tree, nocompact, lexerisdefined, acceptinputprefix, start
#  See the call to thsi sub 'Parse' inside sub new in module Grammar.pm 
sub Parse {
    my($self)=shift;

        @_ > 0
    or  croak("No input grammar\n");

    my($parsed)={};

    $input=\$_[0]; # we did a shift for $self, one less

    $lexlevel=0;
    my $firstline = $_[1];
    $filename = $_[2] or croak "Unknown input file";
    @lineno= $firstline? ($firstline, $firstline) : (1,1);

    $tree = $_[3];
    if ($tree) { # factorize!
      $buildingtree = 1;
      $bypass = 0;
      $alias = 0;
      $defaultaction = [ ' goto &Parse::Eyapp::Driver::YYBuildAST ', 0]; 
      $namingscheme = [ '\&give_rhs_name', 0];
    }

    $nocompact = $_[4];

    $nberr=0;
    $prec=0;
    $labelno=0;

    $head=[];
    $tail="";

    $syms={};
    $token={};
    $term={};
    $termdef={};
    $nterm={};
    $rules=[ undef ];   #reserve slot 0 for start rule
    $precterm={};

    $start="";
    $start = $_[7] if ($_[7]); 

    $nullable={};
    $expect=0;
    $semantic = {};
    $strict = 0;

    pos($$input)=0;


    $self->YYParse(yylex => \&_Lexer, yyerror => \&_Error); #???

        $nberr
    and _SyntaxError(2,"Errors detected: No output",-1);

    @$parsed{ 'HEAD', 'TAIL', 'RULES', 'NTERM', 'TERM',
              'NULL', 'PREC', 'SYMS',  'START', 'EXPECT', 
              'SEMANTIC', 'BYPASS', 'ACCESSORS', 'BUILDINGTREE',
              'PREFIX',
              'NAMINGSCHEME',
              'NOCOMPACT',
              'CONFLICTHANDLERS',
              'TERMDEF',
              'WHITES',
              'LEXERISDEFINED',
              'INCREMENTAL',
              'STRICT',
              'DUMMY',
            }
    =       (  $head,  $tail,  $rules,  $nterm,  $term,
               $nullable, $precterm, $syms, $start, $expect, 
               $semantic, $bypass, $accessors, $buildingtree,
               $prefix,
               $namingscheme,
               $nocompact,
               \%conflict,
               $termdef,
               $whites,
               $lexer,
               $incremental,
               $strict,
               $dummy,
            );

    undef($input);
    undef($lexlevel);
    undef(@lineno);
    undef($nberr);
    undef($prec);
    undef($labelno);
    undef($incremental);

    undef($head);
    undef($tail);

    undef($syms);
    undef($token);
    undef($term);
    undef($termdef);
    undef($whites);
    undef($nterm);
    undef($rules);
    undef($precterm);

    undef($start);
    undef($nullable);
    undef($expect);
    undef($defaultaction);
    undef($semantic);
    undef($buildingtree);
    undef($strict);

    $parsed
}



=for None

=cut


################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################



1;
