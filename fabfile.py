from fabric.api import env, local, sudo, cd

env.chef_executable = 'chef-solo'


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
    with cd('/var/chef'):
        sudo('%s' % env.chef_executable, pty=True)


def _update_site(site):
    with cd('/var/chef'):
        sudo('%s -j site_configs/%s' % (env.chef_executable, site), pty=True)


def update_all():
    import os
    sync_config()
    for site in [f for f in os.listdir('site_configs') if f[-5:] == '.json']:
        _update_site(site)


def update_site(site):
    import os
    sync_config()
    if site in os.listdir('site_configs'):
        _update_site(site)


def sites():
    import os

    for site in os.listdir('site_configs'):
        print site