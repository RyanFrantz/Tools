#!/usr/bin/perl

use warnings;
use strict;

#
# TODO:
# 1. Add in argument parsing (i.e. for optional connection type header in the output)
#

my $file = '/proc/net/ip_conntrack';
my $FS = '|';	# field separator
# am I missing any TCP connection types?
my @tcpConnectionTypes = (
	"CLOSE ",	# careful not to match CLOSE_WAIT here...
	"CLOSE_WAIT",
	"ESTABLISHED",
	"FIN_WAIT",
	"FIN_WAIT2",
	"SYN_RECV",
	"TIME_WAIT"
);

my @otherConnectionTypes = (
	"udp",
	"unknown"
);

open( CONNTRACK, $file ) or die "Unable to open \'$file\' for reading: $!\n";
my @lines = <CONNTRACK>;
close CONNTRACK;

print time() . $FS;
my $connCount = @lines;	# total connections
foreach my $connectionType ( @tcpConnectionTypes ) {
	my $count = grep(/$connectionType/, @lines);
	#print $connectionType . ": " . $count . "|";
	print $count . $FS;
}

foreach my $connectionType ( @otherConnectionTypes ) {
	my $count = grep(/^$connectionType/, @lines);
	#print $connectionType . ": " . $count . "|";
	print $count . $FS;
}

print "$connCount\n";	# total 
