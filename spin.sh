#!/bin/bash
dirname=$(dirname $0)
/usr/bin/false; while [ $? -ne 0 ]; do perl "$dirname/test.pl" >out 2>&1; echo -n $?; cat out | grep 'free unreferenced scalar'; done
say "Error found"
