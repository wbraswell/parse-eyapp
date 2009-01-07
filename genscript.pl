#!/usr/bin/perl -w
use warnings;
use strict;
use Getopt::Long;

my $DRIVER = '#!/usr/bin/perl -I../lib -I../../../lib -w';
my $CLASS  = 'Tutu';
my $PROMPT  = '';
my $OUTPUT = '';

my $result = GetOptions (
    "driver=s" => \$DRIVER,  
    'prompt=s' => \$PROMPT,
    "class=s"  => \$CLASS,
    "output=s" => \$OUTPUT,
    );

my $class = $CLASS;
$class =~ s/::/_/g;
$class =~ tr/A-Z/a-z/;
$OUTPUT = "tutu_$class.pl" unless $OUTPUT;

my $skeleton = skeleton();

$skeleton =~ s/#DRIVER#/$DRIVER/;
$skeleton =~ s/#CLASS#/$CLASS/g;
$skeleton =~ s/#PROMPT#/$PROMPT/g;

warn "$OUTPUT exists! Overwriting ...\n" if -w $OUTPUT;
open my $outfile, ">", $OUTPUT;
warn "Output script in $OUTPUT\n";
chmod 0755, $OUTPUT;

print $outfile $skeleton;

###########################################################

sub skeleton {

  return
<< 'PERL_EYAPP_DRIVER';
#DRIVER#
use strict;
use #CLASS#;
use Parse::Eyapp::Base;
use Getopt::Long;

my $input;

sub uploadfile {
  my $file = shift;
  my $msg = shift;

  eval {
    $input = Parse::Eyapp::Base::slurp_file($file) 
  };
  if ($@) {
    print $msg;
    local $/ = undef;
    $input = <STDIN>;
  }
  return $input;
}

my $debug = 0;
my $file = '';
my $result = GetOptions (
    "debug!" => \$debug,  
    "file=s" => \$file,
    );

$debug = 0x1F if $debug;
$file = shift if !$file && @ARGV; 

my $parser = #CLASS#->new();

my $prompt = '#PROMPT#';
$input = uploadfile($file, $prompt) if $file;
$input = <STDIN> unless $input;

$parser->Run( \$input, $debug );

PERL_EYAPP_DRIVER
}
