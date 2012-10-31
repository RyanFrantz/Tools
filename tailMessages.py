#!/usr/bin/python

# tailMessages.py - tail the messages file and monitor for dropped packets

# borrowed a little from http://code.activestate.com/recipes/436477-filetailpy/ and https://github.com/kasun/python-tail/blob/master/tail.py
import time, re
from os import stat
import os
from os.path import abspath
from stat import ST_SIZE
from socket import socket

path = '/var/log/messages'
delay = 60

CARBON_SERVER = 'xxx.xxx.xxx.xxx'
CARBON_PORT = 2003

path = abspath(path)
file = open(path)

long_host = os.uname()[1]
host = long_host.split('.')[0]  # just the hostname, ma'am

file.seek(0,2)
while True:
	current_position = file.tell()
	lines = file.readlines()
	if not lines:
		# find the file size and compare to current position; if file size is less than current position file probably rotated
		size = stat(path)[ST_SIZE]
		if size < current_position:
			print "I think we truncated in our pants..."	# debug
			file.close()
			file = open(path)
			file.seek(0,2)
		else:
			file.seek( current_position )

	else:
		epoch =  str( int( time.time() ) )
		countInputDefaultDrop = 0
		countInputInvalidDrop = 0
		countOutputDefaultDrop = 0
		countOutputInvalidDrop = 0
		for string in lines:
			inputDefaultDroppedPackets =  len( re.findall( '\[INPUT\] DEFAULT DROP', string ) )
			inputInvalidDroppedPackets =  len( re.findall( '\[INPUT\] DROP INVALID', string ) )
			outputDefaultDroppedPackets =  len( re.findall( '\[OUTPUT\] DEFAULT DROP', string ) )
			outputInvalidDroppedPackets =  len( re.findall( '\[OUTPUT\] DROP INVALID', string ) )

			countInputDefaultDrop += inputDefaultDroppedPackets
			countInputInvalidDrop += inputInvalidDroppedPackets
			countOutputDefaultDrop += outputDefaultDroppedPackets
			countOutputInvalidDrop += outputInvalidDroppedPackets

		#print '\n'.join(lines) + '\n'	# debug

		metrics = []
		#print "INPUT DEFAULT DROPPED PACKETS: " + str( countInputDefaultDrop )
		metrics.append( "load_balancers." + host + ".iptables.input.DROP.DEFAULT" + ' ' + str( countInputDefaultDrop ) + ' ' + epoch )
		metrics.append( "load_balancers." + host + ".iptables.input.DROP.INVALID" + ' ' + str( countInputInvalidDrop ) + ' ' + epoch )
		metrics.append( "load_balancers." + host + ".iptables.output.DROP.DEFAULT" + ' ' + str( countOutputDefaultDrop ) + ' ' + epoch )
		metrics.append( "load_balancers." + host + ".iptables.output.DROP.INVALID" + ' ' + str( countOutputInvalidDrop ) + ' ' + epoch )

		request = '\n'.join(metrics)
		sock = socket()

		try:
			sock.connect( (CARBON_SERVER,CARBON_PORT) )
		except:
			print "Couldn't connect to %(server)s on port %(port)d!" % { 'server':CARBON_SERVER, 'port':CARBON_PORT }
			sys.exit(1)

		# feed Graphite!
		#print request	# debug
		sock.sendall(request)

	time.sleep( delay )
