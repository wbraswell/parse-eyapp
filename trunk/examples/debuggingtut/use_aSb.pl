#!/usr/bin/perl
########################################################################################
#
#    This file was generated using Parse::Eyapp version 1.148.
#
# (c) Parse::Yapp Copyright 1998-2001 Francois Desarmenien.
# (c) Parse::Eyapp Copyright 2006-2008 Casiano Rodriguez-Leon. Universidad de La Laguna.
#        Don't edit this file, use source file 'aSb.yp' instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
########################################################################################
package aSb;
use strict;

push @aSb::ISA, 'Parse::Eyapp::Driver';


BEGIN {
  # This strange way to load the modules is to guarantee compatibility when
  # using several standalone and non-standalone Eyapp parsers

  require Parse::Eyapp::Driver unless Parse::Eyapp::Driver->can('YYParse');
  require Parse::Eyapp::Node unless Parse::Eyapp::Node->can('hnew'); 
}
  

#line 1 "aSb.yp"

use base q{DebugTail}; 

#line 31 use_aSb.pl

my $warnmessage =<< "EOFWARN";
Warning!: Did you changed the \@aSb::ISA variable inside the header section of the eyapp program?
EOFWARN

sub new {
  my($class)=shift;
  ref($class) and $class=ref($class);

  warn $warnmessage unless __PACKAGE__->isa('Parse::Eyapp::Driver'); 
  my($self)=$class->SUPER::new( 
    yyversion => '1.148',
    yyGRAMMAR  =>
[
  [ _SUPERSTART => '$start', [ 'S', '$end' ], 0 ],
  [ S_1 => 'S', [  ], 0 ],
  [ S_2 => 'S', [ 'a', 'S', 'b' ], 0 ],
],
    yyTERMS  =>
{ '' => { ISSEMANTIC => 0 },
	'a' => { ISSEMANTIC => 0 },
	'b' => { ISSEMANTIC => 0 },
	error => { ISSEMANTIC => 0 },
},
    yyFILENAME  => 'aSb.yp',
    yystates =>
[
	{#State 0
		ACTIONS => {
			"a" => 2
		},
		DEFAULT => -1,
		GOTOS => {
			'S' => 1
		}
	},
	{#State 1
		ACTIONS => {
			'' => 3
		}
	},
	{#State 2
		ACTIONS => {
			"a" => 2
		},
		DEFAULT => -1,
		GOTOS => {
			'S' => 4
		}
	},
	{#State 3
		DEFAULT => 0
	},
	{#State 4
		ACTIONS => {
			"b" => 5
		}
	},
	{#State 5
		DEFAULT => -2
	}
],
    yyrules  =>
[
	[#Rule _SUPERSTART
		 '$start', 2, undef
#line 98 use_aSb.pl
	],
	[#Rule S_1
		 'S', 0,
sub {
#line 6 "aSb.yp"
 print "S -> epsilon\n" }
#line 105 use_aSb.pl
	],
	[#Rule S_2
		 'S', 3,
sub {
#line 7 "aSb.yp"
 print "S -> a S b\n" }
#line 112 use_aSb.pl
	]
],
#line 115 use_aSb.pl
    yybypass       => 0,
    yybuildingtree => 0,
    yyprefix       => '',
    yyaccessors    => {
   },
    @_,
  );
  bless($self,$class);

  $self->make_node_classes( qw{TERMINAL _OPTIONAL _STAR_LIST _PLUS_LIST 
         _SUPERSTART
         S_1
         S_2} );
  $self;
}

#line 9 "aSb.yp"


__PACKAGE__->main('Provide a statement like "a a b b" and press <CR><CTRL-D>: ') unless caller;


=for None

=cut



#line 144 use_aSb.pl

1;
