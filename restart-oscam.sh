#!/bin/bash
killall -9 oscam 
opensc-tool -l 
while pgrep opensc-tool > /dev/null; do sleep 1; done
/usr/local/bin/oscam -b
