#!/bin/bash
#
# echoes.sh listens on port 8080 and outputs a string
# "Time now on host <hostname>: <date>"
# when HTTP client makes request
while true; do
  (echo -e 'HTTP/1.1 200 OK\r\n'; echo -e "\n\tVERSION:\t 5" ; echo -e "\tCONTAINER ID:\t $(hostname)" ; echo -e "\tTIME:\t\t $(date)\n") | nc -l -p 8080;
done
