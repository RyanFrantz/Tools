Tools
=====

A simple repo to keep miscellaneous tools I write.

conntrackReport
---------------
A simple script to grep /proc/net/ip_conntrack for counts of TCP/UDP connections.

conntrack2Graphite.py
---------------------
I modified conntrackReport.py to feed Graphite it's data.  I borrowed code from Graphite's 'examples/example-client.py'.

Thanks to the Graphite devs for the example code.

tailHaproxy.py
--------------
To collect information on the number of HTTP requests (at least GETs and POSTs), I wrote tailHaproxy.py.

So far, this script successfully handles log rotations.

tailMessages.py
---------------
I tailored tailHaproxy.py to look at /var/log/messages and report on iptables-related information (dropped packets).

TODO
====
1. Clean up the code (i.e. get rid of debug statements used for testing).
2. Add support for arguments (log to terminal for testing/debugging; daemonizing).
3. Add daemonizing support.
4. Add startup scripts to ensure these scripts survive reboots.
