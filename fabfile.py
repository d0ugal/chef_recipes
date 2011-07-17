from fabric.api import env, local, run, sudo
#env.user = 'root'
#env.password = 'Starbuck46xX5KTkc'
#env.hosts = ['31.222.178.35']

env.user = 'vagrant'
env.password = 'vagrant'
env.hosts = ['33.33.33.15']

env.code_dir = '/home/docs/sites/readthedocs.org/checkouts/readthedocs.org'
env.virtualenv = '/home/docs/sites/readthedocs.org'
env.rundir = '/home/docs/sites/readthedocs.org/run'

#env.chef_executable = '/var/lib/gems/1.8/bin/chef-solo'
env.chef_executable = '/usr/lib/ruby/gems/1.8/gems/chef-0.10.2/bin/chef-solo'


def install_chef():
    sudo('apt-get update', pty=True)
    sudo('apt-get install -y libopenssl-ruby')
    sudo('apt-get install -y git-core rubygems ruby ruby-dev', pty=True)
    sudo('gem install chef --no-ri --no-rdoc', pty=True)
    sudo('mkdir -p /etc/chef')
    sudo('chown %s /etc/chef' % (env.user))

# -O switch because rsync sucks.
def sync_config():
    local('sudo rsync -av . %s@%s:/etc/chef' % (env.user, env.hosts[0]))

def update():
    sync_config()
    sudo('cd /etc/chef && %s' % env.chef_executable, pty=True)

def reload():
    "Reload the server."
    env.user = "docs"
    run("kill -HUP `cat %s/gunicorn.pid`" % env.rundir, pty=True)

def restart():
    "Restart (or just start) the server"
    sudo('restart readthedocs-gunicorn', pty=True)

def update_all():
    sync_config()
    import os

    for file in [f for f in os.listdir('site_configs') if f[-5:] == '.json']:
        sudo('cd /etc/chef && %s -j site_configs/%s' % (env.chef_executable, file), pty=True)

def update_site(site):
    sync_config()
    import os
    if site in os.listdir('site_configs'):
        sudo('cd /etc/chef && %s -j site_configs/%s' % (env.chef_executable, site), pty=True)
        
    print site
