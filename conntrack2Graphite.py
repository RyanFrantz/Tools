#!/usr/bin/python

import os, sys, time, re
from socket import socket

# TODO:
# 1. add socket timeout so that we don't block/hang
#  a. include exception handling for time outs

file = '/proc/net/ip_conntrack'
FS = ','	# field separator
# am I missing any TCP connection types?
tcpConnectionTypes = (
	'CLOSE ',	# careful not to match CLOSE_WAIT here...
	'CLOSE_WAIT',
	'ESTABLISHED',
	'FIN_WAIT',
	'FIN_WAIT2',
	'SYN_RECV',
	'TIME_WAIT'
)

otherConnectionTypes = (
	'udp',
	'unknown'
)

CARBON_SERVER = '10.1.1.130'
CARBON_PORT = 2003	# must be an int

f = open( file )
lines = f.read()
f.close

epoch =  str( int( time.time() ) )

connCount = str( len( lines.splitlines() ) )	# total connections

long_host = os.uname()[1]
host = long_host.split('.')[0]	# just the hostname, ma'am
metrics = []
for connectionType in tcpConnectionTypes:
	output =  str( len( re.findall( connectionType, lines ) ) )
	connType = connectionType.lower()
	metrics.append( "load_balancers." + host + ".connections.tcp." + connType + ' ' + output + ' ' + epoch )

for connectionType in otherConnectionTypes:
	output =  str( len( re.findall( connectionType, lines ) ) )
	connType = connectionType.lower()
	metrics.append( "load_balancers." + host + ".connections." + connType + ' ' + output + ' ' + epoch )

# total connections
metrics.append(  "load_balancers." + host + ".connections.total" + ' ' + connCount + ' ' + epoch )

request = '\n'.join(metrics) 

sock = socket()
try:
	sock.connect( (CARBON_SERVER,CARBON_PORT) )
except:
	print "Couldn't connect to %(server)s on port %(port)d!" % { 'server':CARBON_SERVER, 'port':CARBON_PORT }
	sys.exit(1)

# feed Graphite!
sock.sendall(request)

