#!/usr/bin/env python2.5

from boto.ec2.connection import EC2Connection
import time
import base64
import sys
import os

a = open('/dev/shm/access-key-id').read().strip()
s = open('/dev/shm/secret-access-key').read().strip()
c = EC2Connection(a,s)                         

inst_list = sys.argv[1:]
c.terminate_instances(inst_list)
for i in inst_list:
   try:
      os.unlink(i)
   except OSError:
      pass

for i in c.get_all_instances():
   print "%-8s %-8s %s\n" % (i.id, i.state, i.dns_name)
