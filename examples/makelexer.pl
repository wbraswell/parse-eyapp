#!/usr/bin/perl -l

eval 'exec /usr/bin/perl -l -S $0 ${1+"$@"}'
    if 0; # not running under some shell

use strict;
use Getopt::Std;
use Fatal qw( open );
use Parse::Flex::Generate;
use File::Basename;
use Pod::Usage;

my $dir='del/';
#$SIG { INT } =  sub{ $dir =~ m'\w/$' and system "rm -rf $dir" } ;

my ($Grammar, $packname);
if (@ARGV and $ARGV[0] !~ m{-}) {
  $Grammar = shift (@ARGV); 
}

my %opt;
getopts('vmhkl:n:o:', \%opt);

$Grammar = shift if !$Grammar and @ARGV;

$packname = fileparse($Grammar, qr/\.[^.]*/);
$packname =~ s/\W//g;
$packname = "_$packname" unless $packname =~ m{^[a-zA-Z]};

### Defaults and Error Checking
my $flex_flags = '-Cf ';
my $Pack       = $opt{n} || $opt{o} || $packname || ''; 

$opt{h} and die Parse::Flex::Generate::Usage( $Pack );
$opt{m} and pod2usage(-input => 'Parse/Flex.pm', -exitval => 1, -verbose => 2);

die Parse::Flex::Generate::Usage( $Pack ) unless $Grammar;
$opt{l} or $opt{l} = $flex_flags ;
check_argv ( $Pack, $Grammar);

## Initializations
my  $pm  = pm_content $Pack       ;
my  $mk  = makefile_content $Pack, $Grammar, $opt{l}, $opt{v} ;
my  $xs  = xs_content( $Pack )    ;

## setup for compilation
$dir and system qq( mkdir -p $dir);
$dir and system qq( cp  $Grammar $dir );
open OUT , "> $dir${Pack}.xs" ; print OUT $xs; close OUT;
open OUT , "> $dir${Pack}.pm" ; print OUT $pm; close OUT;
open OUT , "> ${dir}Makefile" ; print OUT $mk; close OUT;

## Compile
open OUT , "| make n=1 -sC $dir -f - "  ; 
print OUT $mk; close OUT;
$dir =~ m'\w/$' and system "rm -rf $dir"   unless $opt{k} ;

