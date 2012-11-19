#!/usr/bin/ruby

require 'socket'

file = '/proc/net/ip_conntrack'
graphite_host = "xxx.xxx.xxx.xxx"
port = 2003

# am I missing any TCP connection types?
tcpConnectionTypes = [
	'CLOSE ',	# careful not to match CLOSE_WAIT here...
	'CLOSE_WAIT',
	'ESTABLISHED',
	'FIN_WAIT',
	'FIN_WAIT2',
	'SYN_RECV',
	'TIME_WAIT'
]

otherConnectionTypes = [
	'udp',
	'unknown'
]

lines = File.readlines( file )
connCount = lines.size.to_s

metrics = []
epoch =  Time.now.tv_sec.to_s
host =  `hostname`.split(".")[0]

tcpConnectionTypes.each{ |connectionType|
	count = lines.grep( /#{connectionType}/ ).size.to_s
	metrics.push( 'load_balancers.' + host + '.connections.tcp.' + connectionType + ' ' + count + ' ' + epoch )
}

otherConnectionTypes.each{ |connectionType|
	count = lines.grep( /#{connectionType}/ ).size.to_s
	metrics.push( 'load_balancers.' + host + '.connections.' + connectionType + ' ' + count + ' ' + epoch )
}

metrics.push( 'load_balancers.' + host + '.connections.total' + ' ' + connCount + ' ' + epoch )

request = metrics.join("\n") + "\n"
print request

begin
	socket = TCPSocket.open(graphite_host, port)
	socket.write( request )
	socket.close()
rescue
	puts "\nConnection error: " + $! + "\n"
end
