import os
import sys
import tempfile
import time

from boto.ec2 import EC2Connection, get_region
from boto.exception import EC2ResponseError
from fabric.api import settings
from fabric.network import disconnect_all
from paramiko import PKey
from unipath import Path

sys.path.insert(0, Path(Path.cwd(), ".."))

def create_vm():

    try:
        kwargs = {
            'aws_access_key_id': os.environ['AWS_ACCESS_KEY_ID'],
            'aws_secret_access_key': os.environ['AWS_SECRET_ACCESS_KEY'],
            'region': get_region('eu-west-1'),
        }
    except KeyError:
        print '*' * 50
        print "You must set both the AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY enviroment variables."
        print '*' * 50
        raise

    ec2 = EC2Connection(**kwargs)

    vm_name = 'chef_recipes_test'

    # Check the keypair exists, if it does delete it and re-create it. We do 
    # this as we don't really want to store the key - its throw away and 
    # we are only given the private part once, fetching again from ec2 doesn't
    # seem to work - at least, it doesn't work through boto.
    # (Interestingly get_key_pair should return None if its not found acording
    # to the boto docs but it raises an exception.)
    try:
        ec2.get_key_pair(vm_name)
        ec2.delete_key_pair(vm_name)
    except EC2ResponseError:
        pass
    
    key_pair = ec2.create_key_pair(vm_name)

    # Check the security group exists, if it doesn't - create it.
    # The boto docs claim None is returned if it doesn't exist, but actually
    # an EC2ResponseError is raised.
    try:
        security_group = ec2.get_all_security_groups(groupnames=[vm_name,])[0]
    except EC2ResponseError:
        security_group = None

    if not security_group:
        security_group = ec2.create_security_group(vm_name, vm_name)
        security_group.authorize(ip_protocol='tcp', from_port=22, to_port=22, cidr_ip='0.0.0.0/0')

    # Create a reservation - the image is an ubuntu machine.
    reservation = ec2.run_instances(image_id='ami-4a34013e',
            key_name='chef_recipes_test', security_groups=['chef_recipes_test',])
    
    instance = reservation.instances[0]

    print "Started VM, Waiting for VM to be 'running'"

    while True:
        time.sleep(5)
        instance.update()
        if instance.state == 'running':
            print "VM Running, it needs a little bit of time before we can connect..."
            break

    # Even after its running, we need a short delay before we can connect.
    time.sleep(30)

    print "OK! Ready. Lets do this."

    host_string = instance.public_dns_name
    user = 'ubuntu'

    key_file = tempfile.NamedTemporaryFile(delete=False)
    key_file.write(key_pair.material)
    key_filename = key_file.name

    return {
        'host_string': host_string, 
        'user': user,
        'key_pair' : key_pair,
        'key_filename' : key_filename,
        'instance': instance,
    }

class TestRunner(object):

    def test(self, host_string, user, key_pair, key_filename):

        print "HOST:", host_string
        print "USER:", user
        print "TEMP KEY FILE:", key_filename
        print "RSA KEY:\n", key_pair.material
        print

        from fabfile import install_chef, sync_config, sites, update_all
                
        with settings(host_string=host_string, key_filename=key_filename, user=user):
            
            print 'OK!'
            install_chef()
            sync_config()
            sites()
            update_all()
            print "DONE!"

    def tear_down(self):

        disconnect_all()
        try:
            print "Terminating the VM"
            self.instance.terminate()
        except AttributeError:
            pass

    def setup(self):

        vm_info = create_vm()
        self.instance = vm_info['instance']
        vm_info.pop('instance')
        self.test(**vm_info)

    def run_tests(self,):
        try:
            self.setup()
        finally:
            self.tear_down()


t = TestRunner()
t.run_tests()