#!/bin/bash

sudo yum -y remove telnet

##Ensure System Accounts are non-login

#Ensure CUPS is not enabled
sudo chkconfig cups off

#Ensure Sticky bit
sudo df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -type d -perm -0002 2>/dev/null | xargs chmod a+t

