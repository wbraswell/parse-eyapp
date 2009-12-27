/*
 * imcc.y
 *
 * Intermediate Code Compiler for Parrot.
 *
 * Copyright (C) 2002 Melvin Smith <melvin.smith@mindspring.com>
 * Copyright (C) 2002-2009, Parrot Foundation.
 *
 * Grammar of the PIR language parser.
 *
 */

/* We need precedence for a few tokens to resolve a couple of conflicts */
%nonassoc LOW_PREC
%nonassoc '\n'
%nonassoc <t> PARAM

%token <t> HLL TK_LINE TK_FILE
%token <t> GOTO ARG IF UNLESS PNULL SET_RETURN SET_YIELD
%token <t> ADV_FLAT ADV_SLURPY ADV_OPTIONAL ADV_OPT_FLAG ADV_NAMED ADV_ARROW
%token <t> NEW ADV_INVOCANT ADV_CALL_SIG
%token <t> NAMESPACE DOT_METHOD
%token <t> SUB SYM LOCAL LEXICAL CONST ANNOTATE
%token <t> INC DEC GLOBAL_CONST
%token <t> PLUS_ASSIGN MINUS_ASSIGN MUL_ASSIGN DIV_ASSIGN CONCAT_ASSIGN
%token <t> BAND_ASSIGN BOR_ASSIGN BXOR_ASSIGN FDIV FDIV_ASSIGN MOD_ASSIGN
%token <t> SHR_ASSIGN SHL_ASSIGN SHR_U_ASSIGN
%token <t> SHIFT_LEFT SHIFT_RIGHT INTV FLOATV STRINGV PMCV LOG_XOR
%token <t> RELOP_EQ RELOP_NE RELOP_GT RELOP_GTE RELOP_LT RELOP_LTE
%token <t> RESULT RETURN TAILCALL YIELDT GET_RESULTS
%token <t> POW SHIFT_RIGHT_U LOG_AND LOG_OR
%token <t> COMMA ESUB DOTDOT
%token <t> PCC_BEGIN PCC_END PCC_CALL PCC_SUB PCC_BEGIN_RETURN PCC_END_RETURN
%token <t> PCC_BEGIN_YIELD PCC_END_YIELD NCI_CALL METH_CALL INVOCANT
%token <t> MAIN LOAD INIT IMMEDIATE POSTCOMP METHOD ANON OUTER NEED_LEX
%token <t> MULTI VTABLE_METHOD LOADLIB SUB_INSTANCE_OF SUBID
%token <t> NS_ENTRY
%token <t> UNIQUE_REG
%token <s> LABEL
%token <t> EMIT EOM
%token <s> IREG NREG SREG PREG IDENTIFIER REG MACRO ENDM
%token <s> STRINGC INTC FLOATC USTRINGC
%token <s> PARROT_OP

%type <t> type hll_def return_or_yield comma_or_goto opt_unique_reg
%type <i> program
%type <i> class_namespace
%type <i> constdef sub emit pcc_ret pcc_yield
%type <i> compilation_units compilation_unit pmc_const pragma
%type <s> classname relop any_string assign_op  bin_op  un_op
%type <i> labels _labels label  statement sub_call
%type <i> pcc_sub_call
%type <sr> sub_param sub_params pcc_arg pcc_result pcc_args pcc_results sub_param_type_def
%type <sr> pcc_returns pcc_yields pcc_return pcc_call arg arglist the_sub multi_type
%type <t> argtype_list argtype paramtype_list paramtype
%type <t> pcc_return_many
%type <t> proto sub_proto sub_proto_list multi multi_types outer
%type <t> vtable instanceof subid
%type <t> method ns_entry_name
%type <i> instruction assignment conditional_statement labeled_inst opt_label op_assign
%type <i> if_statement unless_statement
%type <i> func_assign get_results
%type <i> opt_invocant
%type <i> annotate_directive
%type <sr> target targetlist reg const var result pcc_set_yield
%type <sr> keylist keylist_force _keylist key maybe_ns
%type <sr> vars _vars var_or_i _var_or_i label_op sub_label_op sub_label_op_c
%type <i> pasmcode pasmline pasm_inst
%type <sr> pasm_args
%type <i> var_returns

%token <sr> VAR
%token <t> LINECOMMENT
%token <s> FILECOMMENT
%type <idlist> id_list id_list_id

%nonassoc CONCAT DOT

%start program

%%

program:
     compilation_units    
   ;

compilation_units:
     compilation_unit
   | compilation_units compilation_unit
   ;

compilation_unit:
     class_namespace           
   | constdef                  
   | sub
   | emit
   | MACRO '\n'                
   | pragma                    
   | location_directive            
   | '\n'                      
   ;

pragma:
     hll_def         '\n'      
   | LOADLIB STRINGC '\n'
   ;

location_directive:
     TK_LINE INTC COMMA STRINGC '\n'
   | TK_FILE STRINGC '\n'
   ;

annotate_directive:
    ANNOTATE STRINGC COMMA const
    ;

hll_def:
     HLL STRINGC
   ;

constdef:
     CONST  type IDENTIFIER '=' const
   ;

pmc_const:
     CONST  INTC var_or_i '=' any_string
     | CONST  STRINGC var_or_i '=' any_string
   ;
any_string:
     STRINGC
   | USTRINGC
   ;

pasmcode:
     pasmline
   | pasmcode pasmline
   ;

pasmline:
     labels  pasm_inst '\n'    
   | MACRO '\n'                
   | FILECOMMENT               
   | LINECOMMENT               
   | class_namespace           
   | pmc_const
   | pragma
   ;

pasm_inst:                     
     PARROT_OP pasm_args
   | PCC_SUB sub_proto LABEL
   | PNULL var
   | LEXICAL STRINGC COMMA REG
   | /* none */                
   ;

pasm_args:
     vars
   ;

emit:                         /* EMIT and EOM tokens are used when compiling a .pasm file. */
     EMIT opt_pasmcode EOM
   ;

opt_pasmcode:
     /* empty */
  | pasmcode
  ;

class_namespace:
    NAMESPACE maybe_ns '\n'
   ;

maybe_ns:
     '[' keylist ']'
   | '[' ']'                   
   ;

sub:
     SUB sub_label_op_c sub_proto '\n' sub_params sub_body  ESUB            
   ;

sub_params:
     /* empty */                %prec LOW_PREC
   | '\n'                               
   | sub_params sub_param '\n'
   ;

sub_param:
   PARAM  sub_param_type_def 
   ;

sub_param_type_def:
     type IDENTIFIER paramtype_list
   ;

multi:
     MULTI '(' multi_types ')' 
   ;

outer:
     OUTER '(' STRINGC ')'
    | OUTER '(' IDENTIFIER ')'
   ;

vtable:
     VTABLE_METHOD
   | VTABLE_METHOD '(' STRINGC ')'
   ;

method:
     METHOD
   | METHOD '(' any_string ')'
   ;

ns_entry_name:
    NS_ENTRY
   | NS_ENTRY '(' any_string ')'
   ;

instanceof:
     SUB_INSTANCE_OF '(' STRINGC ')'
   ;

subid:
     SUBID
   | SUBID '(' any_string ')'
   ;

multi_types:
     /* empty */
   | multi_types COMMA multi_type
   | multi_type
   ;

multi_type:
     INTV                      
   | FLOATV                    
   | PMCV                      
   | STRINGV                   
   | IDENTIFIER
   | STRINGC
   | '[' keylist ']'           
   ;

sub_body:
     /* empty */
   |  statements
   ;

pcc_sub_call:
     PCC_BEGIN '\n'
     pcc_args
     opt_invocant
     pcc_call
     opt_label
     pcc_results
     PCC_END                   
   ;

opt_label:
     /* empty */               
   | label '\n'                
   ;

opt_invocant:
     /* empty */               
   | INVOCANT var '\n'         
   ;

sub_proto:
     /* empty */               
   | sub_proto_list
   ;

sub_proto_list:
     proto                     
   | sub_proto_list proto      
   ;

proto:
     LOAD                      
   | INIT                      
   | MAIN                      
   | IMMEDIATE                 
   | POSTCOMP                  
   | ANON                      
   | NEED_LEX                  
   | multi
   | outer
   | vtable
   | method
   | ns_entry_name
   | instanceof
   | subid
   ;

pcc_call:
     PCC_CALL var COMMA var '\n'
   | PCC_CALL var '\n'
   | NCI_CALL var '\n'
   | METH_CALL target '\n'
   | METH_CALL STRINGC '\n'
   | METH_CALL target COMMA var '\n'
   | METH_CALL STRINGC COMMA var '\n'
   ;


pcc_args:
     /* empty */               
   | pcc_args pcc_arg '\n'     
   ;

pcc_arg:
     ARG arg                   
   ;


pcc_results:
     /* empty */               
   | pcc_results pcc_result '\n'
   ;

pcc_result:
     RESULT target paramtype_list 
   | LOCAL  type id_list_id
   ;

paramtype_list:
     /* empty */               
   | paramtype_list paramtype  
   ;

paramtype:
     ADV_SLURPY                 
   | ADV_OPTIONAL               
   | ADV_OPT_FLAG               
   | ADV_NAMED                  
   | ADV_NAMED '(' STRINGC ')'  
   | ADV_NAMED '(' USTRINGC ')' 
   | UNIQUE_REG                 
   | ADV_CALL_SIG               
   ;


pcc_ret:
     PCC_BEGIN_RETURN '\n'     
     pcc_returns
     PCC_END_RETURN            
   | pcc_return_many
   ;

pcc_yield:
     PCC_BEGIN_YIELD '\n'      
     pcc_yields
     PCC_END_YIELD             
   ;

pcc_returns:
     /* empty */               
   | pcc_returns '\n'
   | pcc_returns pcc_return '\n'
   ;

pcc_yields:
     /* empty */                
   | pcc_yields '\n'
   | pcc_yields pcc_set_yield '\n'
   ;

pcc_return:
     SET_RETURN var argtype_list   
   ;

pcc_set_yield:
     SET_YIELD var argtype_list    
   ;

pcc_return_many:
    return_or_yield  '('
    var_returns  ')'
  ;

return_or_yield:
     RETURN                    
   | YIELDT                    
   ;

var_returns:
     /* empty */               
   | arg
   | STRINGC ADV_ARROW var
   | var_returns COMMA arg
   | var_returns COMMA STRINGC ADV_ARROW var
   ;

statements:
     statement
   | statements statement
   ;

/* This is ugly. Because 'instruction' can start with PARAM and in the
 * 'pcc_sub' rule, 'pcc_params' is followed by 'statement', we get a
 * shift/reduce conflict on PARAM between reducing to the dummy
 *  rule and shifting the PARAM to be used as part
 * of the 'pcc_params' (which is what we want). However, yacc syntax
 * doesn't propagate precedence to the dummy rules, so we have to
 * split out the action just so that we can assign it a precedence. */

helper_clear_state:
                                %prec LOW_PREC
   ;

statement:
     helper_clear_state instruction               
   | MACRO '\n'                
   | FILECOMMENT               
   | LINECOMMENT               
   | location_directive        
   | annotate_directive        
   ;

labels:
     /* none */                
   |  _labels
   ;

_labels:
     _labels label
   | label
   ;

label:
     LABEL
   ;


instruction:
     labels labeled_inst '\n'  
   | error '\n'
   ;

id_list :
     id_list_id
   | id_list COMMA id_list_id
   ;

id_list_id :
     IDENTIFIER opt_unique_reg
   ;

opt_unique_reg:
     /* empty */               
   | UNIQUE_REG                
   ;

labeled_inst:
     assignment
   | conditional_statement
   | LOCAL  type id_list
   | LEXICAL STRINGC COMMA target
   | LEXICAL USTRINGC COMMA target
   | CONST  type IDENTIFIER '=' const
   | pmc_const
   | GLOBAL_CONST  type IDENTIFIER '=' const
   | TAILCALL sub_call
   | GOTO label_op
   | PARROT_OP vars
   | PNULL var                 
   | sub_call                  
   | pcc_sub_call              
   | pcc_ret
   | pcc_yield
   | /* none */                
   ;

type:
     INTV                      
   | FLOATV                    
   | STRINGV                   
   | PMCV                      
   ;

classname:
     IDENTIFIER
   ;

assignment:
     target '=' var
   | target '=' un_op var
   | target '=' var bin_op var
   | target '=' var '[' keylist ']'
   | target '[' keylist ']' '=' var
     /* Removing this line causes test failures in t/compilers/tge/* for
        some reason. Eventually it should be removed and the normal handling
        of ops should be used for all forms of "new". */
   | target '=' 'new' classname '[' keylist ']'
     /* Subroutine call the short way */
   | target  '=' sub_call
   | '('
     targetlist  ')' '=' the_sub '(' arglist ')'
   | get_results
   | op_assign
   | func_assign
   | target '=' PNULL
   ;

/* C++ hates implicit casts from string constants to char *, so be explicit */
un_op:
     '!'                       
   | '~'                       
   | '-'                       
   ;

bin_op:
     '-'                       
   | '+'                       
   | '*'                       
   | '/'                       
   | '%'                       
   | FDIV                      
   | POW                       
   | CONCAT                    
   | RELOP_EQ                  
   | RELOP_NE                  
   | RELOP_GT                  
   | RELOP_GTE                 
   | RELOP_LT                  
   | RELOP_LTE                 
   | SHIFT_LEFT                
   | SHIFT_RIGHT               
   | SHIFT_RIGHT_U             
   | LOG_AND                   
   | LOG_OR                    
   | LOG_XOR                   
   | '&'                       
   | '|'                       
   | '~'                       
   ;

get_results:
     GET_RESULTS '(' targetlist  ')'       
   ;

op_assign:
     target assign_op var
   ;

assign_op:
     PLUS_ASSIGN               
   | MINUS_ASSIGN              
   | MUL_ASSIGN                
   | DIV_ASSIGN                
   | MOD_ASSIGN                
   | FDIV_ASSIGN               
   | CONCAT_ASSIGN             
   | BAND_ASSIGN               
   | BOR_ASSIGN                
   | BXOR_ASSIGN               
   | SHR_ASSIGN                
   | SHL_ASSIGN                
   | SHR_U_ASSIGN              
   ;

func_assign:
   target '=' PARROT_OP pasm_args
   ;

the_sub:
       IDENTIFIER     
     | STRINGC      
     | USTRINGC     
   | target
   | target DOT sub_label_op
   | target DOT USTRINGC
   | target DOT STRINGC
   | target DOT target         
   ;

sub_call:
     the_sub '(' arglist ')'           
   ;

arglist:
     /* empty */               
   | arglist COMMA arg
   | arg
   | arglist COMMA STRINGC ADV_ARROW var
   | var ADV_ARROW var
   | STRINGC ADV_ARROW var
   ;

arg:
     var argtype_list          
   ;

argtype_list:
     /* empty */               
   | argtype_list argtype      
   ;

argtype:
     ADV_FLAT                  
   | ADV_NAMED                 
   | ADV_CALL_SIG              
   | ADV_NAMED '(' USTRINGC ')' 
   | ADV_NAMED '(' STRINGC  ')' 
   ;

result:
     target paramtype_list     
   ;

targetlist:
     targetlist COMMA result
   | targetlist COMMA STRINGC ADV_ARROW target
   | result
   | STRINGC ADV_ARROW target
   | /* empty */                
   ;

conditional_statement:
     if_statement               
   | unless_statement           
   ;

unless_statement:
     UNLESS var relop var GOTO label_op
   | UNLESS PNULL var GOTO label_op
   | UNLESS var comma_or_goto label_op
   ;

if_statement:
     IF var comma_or_goto label_op
   | IF var relop var GOTO label_op
   | IF PNULL var GOTO label_op
   ;

comma_or_goto:
     COMMA                     
   | GOTO                      
   ;

relop:
     RELOP_EQ                  
   | RELOP_NE                  
   | RELOP_GT                  
   | RELOP_GTE                 
   | RELOP_LT                  
   | RELOP_LTE                 
   ;

target:
     VAR
   | reg
   ;

vars:
     /* empty */               
   | _vars                     
   ;

_vars:
     _vars COMMA _var_or_i     
   | _var_or_i
   ;

_var_or_i:
     var_or_i                  
   | target '[' keylist ']'
   | '[' keylist_force ']'
   ;
sub_label_op_c:
     sub_label_op
   | STRINGC                   
   | USTRINGC                  
   ;

sub_label_op:
     IDENTIFIER                
   | PARROT_OP                 
   ;

label_op:
     IDENTIFIER                
   | PARROT_OP                 
   ;

var_or_i:
     label_op
   | var
   ;

var:
     target
   | const
   ;

keylist:
     _keylist
   ;

keylist_force:
     _keylist
   ;

_keylist:
     key                       
   | _keylist ';' key
   ;

key:
     var
   ;

reg:
     IREG                      
   | NREG                      
   | SREG                      
   | PREG                      
   | REG                       
   ;

const:
     INTC                      
   | FLOATC                    
   | STRINGC                   
   | USTRINGC                  
   ;

/* The End */
%%

