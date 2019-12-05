#!/bin/sh

prefixdir=`realpath ..`

aclocal
automake -a -c 
autoconf
./configure --prefix=$prefixdir
make clean
make
make install
