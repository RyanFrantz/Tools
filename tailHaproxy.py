#!/usr/bin/python

# tailHaproxy.py - look for various HTTP requests in haproxy logs

# borrowed a little from http://code.activestate.com/recipes/436477-filetailpy/ and https://github.com/kasun/python-tail/blob/master/tail.py
import time, re
from os import stat
import os
from os.path import abspath
from stat import ST_SIZE
from socket import socket

path = '/var/log/haproxy/haproxy-info.log'
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
		countGET = 0
		countPOST = 0
		for string in lines:
			getRequests =  len( re.findall( 'GET', string ) )
			postRequests =  len( re.findall( 'POST', string ) )
			countGET += getRequests
			countPOST += postRequests

		#print '\n'.join(lines) + '\n'	# debug

		metrics = []
		#print "GET REQUESTS: " + str( countGET )
		metrics.append( "load_balancers." + host + ".http.requests.GET" + ' ' + str( countGET ) + ' ' + epoch )
		#print "POST REQUESTS: " + str( countPOST )
		metrics.append( "load_balancers." + host + ".http.requests.POST" + ' ' + str( countPOST ) + ' ' + epoch )
		#print "TOTAL: " + str( len( lines ) )
		metrics.append( "load_balancers." + host + ".http.requests.total" + ' ' + str( len( lines ) ) + ' ' + epoch )
		#print "UNKNOWN: " + str( len( lines ) - ( countGET + countPOST ) )	# i.e. PUTs, HEADs, etc.; I've seen -1 in testing...
		unknown = str( len( lines ) - ( countGET + countPOST ) )
		#metrics.append( "load_balancers." + host + ".http.requests.unknown" + ' ' + str( len( lines ) - ( countGET + countPOST ) ) + ' ' + epoch )
		metrics.append( "load_balancers." + host + ".http.requests.unknown" + ' ' + unknown + ' ' + epoch )
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
