import sys, time, re

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

f = open( file )
lines = f.read()
f.close

epoch =  str( int( time.time() ) ) + FS
sys.stdout.write( epoch )

connCount = str( len( lines.splitlines() ) )	# total connections

for connectionType in tcpConnectionTypes:
	#print connectionType.lower() + ': ' + str( len( re.findall( connectionType, lines ) ) )
	output =  str( len( re.findall( connectionType, lines ) ) ) + FS
	sys.stdout.write( output )

for connectionType in otherConnectionTypes:
	output =  str( len( re.findall( connectionType, lines ) ) ) + FS
	sys.stdout.write( output )

print str( connCount )
