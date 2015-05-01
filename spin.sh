#!/bin/bash
/usr/bin/false; while [ $? -ne 0 ]; do perl test.pl >out 2>&1; echo -n $?; cat out | grep 'scalar'; done
