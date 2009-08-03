#!/usr/bin/env python2.5

from boto.ec2.connection import EC2Connection
import time
import base64
import sys

a = open('/dev/shm/access-key-id').read().strip()
s = open('/dev/shm/secret-access-key').read().strip()
c = EC2Connection(a,s)                         
lenny = c.get_image('ami-10d73379')
ud = open('startup-silc.sh').read()
res = lenny.run(user_data=ud)
inst = res.instances[0]
while inst.update() == 'pending':
	print '.',
	sys.stdout.flush()
	time.sleep(1)
print
print inst.dns_name
open(inst.id, 'w').write('%s\n', inst.id)
