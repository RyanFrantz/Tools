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

sub getTimestamp {
	# I don't have a fancy module like DateTime on this system nor the ability to install it
	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
	$year += 1900;
	$sec = '0' . $sec if $sec < 10;
	$min = '0' . $min if $min < 10;
	$hour = '0' . $hour if $hour < 10;	
	$mon += 1;	# add one to the zero-indexed month
	$mon = '0' . $mon if $mon < 10;	
	$mday = '0' . $mday if $mday < 10;	# paaaaiiiin...

	return "$year-$mon-$mday $hour:$min:$sec";
}

my $timestamp = getTimestamp();
print $timestamp . $FS;
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
