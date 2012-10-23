file = '/proc/net/ip_conntrack'
FS = ','	# field separator
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

print Time.now.tv_sec.to_s + ','
tcpConnectionTypes.each{ |connectionType|
	print( lines.grep( /#{connectionType}/ ).size.to_s  + ',' )
}

otherConnectionTypes.each{ |connectionType|
	print( lines.grep( /#{connectionType}/ ).size.to_s + ',' )
}

puts( connCount )	# total
