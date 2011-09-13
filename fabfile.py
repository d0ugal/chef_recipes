from os.path import dirname, abspath

from fabric.api import env, sudo, cd, put

env.chef_executable = 'chef-solo'
env.project_dir = dirname(abspath(__file__))
env.site_configs = "%s/%s" % (env.project_dir, 'site_configs',)

def install_chef():
    sudo('apt-get update', pty=True)
    sudo('apt-get install -y libopenssl-ruby')
    sudo('apt-get install -y git-core rubygems ruby ruby-dev', pty=True)
    sudo('gem install chef --no-ri --no-rdoc', pty=True)
    sudo('mkdir -p /var/chef')
    sudo('chown %s /var/chef' % (env.user))


def sync_config():
    put(env.project_dir, '/var/chef')


def update():
    sync_config()
    with cd('/var/chef'):
        sudo('%s' % env.chef_executable, pty=True)


def _update_site(site):
    with cd('/var/chef'):
        sudo('%s -j site_configs/%s' % (env.chef_executable, site), pty=True)


def update_all():
    import os
    sync_config()
    for site in [f for f in os.listdir(env.site_configs) if f.endswith('.json')]:
        _update_site(site)


def update_site(site):
    import os
    sync_config()
    if site in os.listdir(env.site_configs):
        _update_site(site)


def sites():
    import os

    for site in os.listdir(env.site_configs):
        print site