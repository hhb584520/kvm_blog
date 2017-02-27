#!/bin/bash
for i in `seq 1 $1`
do
        xl migrate vm1-$i 192.168.100.142        
done

