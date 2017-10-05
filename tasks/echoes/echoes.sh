#!/bin/bash
#
# echoes.sh listens on port 8080 and outputs a string
# "Time now on host <hostname>: <date>"
# when HTTP client makes request

while true; do
  echo "Time now on host $(hostname): $(date)." | nc -l -p 8080
done
