#!/usr/bin/python

# tailCarbonRelay.py - tail Graphite's carbon-relay clients.log file and monitor for dropped datapoints

# borrowed a little from http://code.activestate.com/recipes/436477-filetailpy/ and https://github.com/kasun/python-tail/blob/master/tail.py
import time, re
from os import stat
import os
from os.path import abspath
from stat import ST_SIZE

path = '/var/graphite/storage/log/carbon-relay-a/clients.log'
delay = 60

path = abspath(path)
file = open(path)

while True:
    current_position = file.tell()
    lines = file.readlines()
    if not lines:
        # find the file size and compare to current position; if file size is less than current position file probably rotated
        size = stat(path)[ST_SIZE]
        if size < current_position:
            print "I think we truncated in our pants..."    # debug
            file.close()
            file = open(path)
            file.seek(0,2)
        else:
            file.seek( current_position )

    else:
        epoch =  str( int( time.time() ) )
        countDroppedDatapoints = {}
        for string in lines:
            # match log lines for dropped data points and use the host IP to index the count of drops
            # Ex. 10_101_163_203:2014:None::sendDatapoint send queue full, dropping datapoint
            match = re.search( '(\d+_\d+_\d+_\d+):\d+:None::sendDatapoint send queue full, dropping datapoint', string )
            if match is not None:
                host_address = re.sub( "_", ".", match.group(1) )
                #print host_address # debug
                if host_address in countDroppedDatapoints:
                    countDroppedDatapoints[ host_address ] += 1
                else:
                    countDroppedDatapoints[ host_address ] = 0

        print time.strftime('%F %H:%M:%S') # debug
        for host_address in countDroppedDatapoints:
            if host_address == "10.101.163.203":
                next # we need to exclude Abe's Skyline listener
            else:
                print host_address + ": " + str(countDroppedDatapoints[ host_address ])

    time.sleep( delay )
