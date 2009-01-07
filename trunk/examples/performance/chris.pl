use firewall;
my( $FirewallParser ) = new firewall;

...

$t0 = [Time::HiRes::gettimeofday];
$FirewallParser->YYData->{INPUT} = $entry;
my $t = $FirewallParser->Run();
if( !defined( $TimedEvals{eyapp} ) ){
       $TimedEvals{eyapp} = 0;
}
$TimedEvals{eyapp} += Time::HiRes::tv_interval( $t0 );
