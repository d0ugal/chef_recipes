from fabric.api import env, local, run, sudo

# Taken from Eric Holschers blog.
# Modified slightly.
# Change host details, you may need to change the executable path if your running on a vagrant vm.

env.user = 'vagrant'
env.password = 'vagrant'
env.hosts = ['33.33.33.15']

env.chef_executable = '/var/lib/gems/1.8/bin/chef-solo'
#env.chef_executable = '/usr/lib/ruby/gems/1.8/gems/chef-0.10.2/bin/chef-solo'

def install_chef():
    sudo('apt-get update', pty=True)
    sudo('apt-get install -y libopenssl-ruby')
    sudo('apt-get install -y git-core rubygems ruby ruby-dev', pty=True)
    sudo('gem install chef --no-ri --no-rdoc', pty=True)
    sudo('mkdir -p /var/chef')
    sudo('chown %s /var/chef' % (env.user))

def sync_config():
    local('sudo rsync -av . %s@%s:/var/chef' % (env.user, env.hosts[0]))

def update():
    sync_config()
    sudo('cd /var/chef && %s' % env.chef_executable, pty=True)

def update_all():
    sync_config()
    import os

    for file in [f for f in os.listdir('site_configs') if f[-5:] == '.json']:
        sudo('cd /var/chef && %s -j site_configs/%s' % (env.chef_executable, file), pty=True)

def update_site(site):
    sync_config()
    import os
    if site in os.listdir('site_configs'):
        sudo('cd /var/chef && %s -j site_configs/%s' % (env.chef_executable, site), pty=True)
        
    print site
