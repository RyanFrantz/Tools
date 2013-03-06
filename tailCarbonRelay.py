#!/usr/bin/python

# tailCarbonRelay.py - tail Graphite's carbon-relay clients.log file and monitor for dropped datapoints

# borrowed a little from http://code.activestate.com/recipes/436477-filetailpy/ and https://github.com/kasun/python-tail/blob/master/tail.py
import time, re
from os import stat
import os
from os.path import abspath
from stat import ST_SIZE
import subprocess

path = '/var/graphite/storage/log/carbon-relay-a/clients.log'
delay = 60

path = abspath(path)
file = open(path)

long_host = os.uname()[1]
host = long_host.split('.')[0]  # just the hostname, ma'am
subdomain = long_host.split('.')[1]
short_hostname = host + "." + subdomain

exitCodes = { "OK": 0, "WARNING": 1, "CRITICAL": 2, "UNKNOWN": 3 }
nsca_cmd = "/usr/etsy/nagios/bin/send_nsca"

def send_result( retval, status, plugin_output="" ):
    check_results =  "%s\tCarbon Relay Dropped Datapoints\t%d\t%s\n" % ( short_hostname, retval, plugin_output )
    # open a process for 'send_nsca'
    p = subprocess.Popen( [ nsca_cmd, "-H", "nagios.etsycorp.com", "-c", "/usr/etsy/nagios/etc/send_nsca.cfg" ], shell=False, stdin=subprocess.PIPE )
    # and pipe in the status and results of this check   
    p.communicate( check_results )
    
while True:
    plugin_output = " "

    current_position = file.tell()
    lines = file.readlines()
    if not lines:
        # find the file size and compare to current position; if file size is less than current position file probably rotated
        size = stat(path)[ST_SIZE]
        if size < current_position:
            #print "I think we truncated in our pants..."    # debug
            file.close()
            file = open(path)
            file.seek(0,2)
            plugin_output = " File '" + path + "' rotated."
            send_result( exitCodes["OK"], "OK" , plugin_output )
        else:
            file.seek( current_position )
            plugin_output = " No new entries since last check."
            send_result( exitCodes["OK"], "OK" , plugin_output )

    else:
        epoch =  str( int( time.time() ) )
        countDroppedDatapoints = {}
        for string in lines:
            # match log lines for dropped data points and use the host IP to index the count of drops
            # Ex. 1_2_3_4:2014:None::sendDatapoint send queue full, dropping datapoint
            # TODO: add in check to determine if this is first run and ignore all matches before 'now' to prevent false alarms on first run
            match = re.search( '(\d+_\d+_\d+_\d+):\d+:None::sendDatapoint send queue full, dropping datapoint', string )
            if match is not None:
                host_address = re.sub( "_", ".", match.group(1) )
                #print host_address # debug
                if host_address == "10.101.163.203":
                    continue # we need to exclude Abe's Skyline listener
                if host_address in countDroppedDatapoints:
                    countDroppedDatapoints[ host_address ] += 1
                else:
                    countDroppedDatapoints[ host_address ] = 0

        if len(countDroppedDatapoints) > 0:
            for host_address in countDroppedDatapoints:
                plugin_output = plugin_output + host_address + " dropped " + str(countDroppedDatapoints[ host_address ]) + " datapoint(s) "

            plugin_output = plugin_output + " in the last " + delay " seconds"
            send_result( exitCodes["CRITICAL"], "CRITICAL" , plugin_output )
        else:
            send_result( exitCodes["OK"], "OK" , plugin_output )

    time.sleep( delay )


