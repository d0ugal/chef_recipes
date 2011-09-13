from os.path import dirname, abspath
from StringIO import StringIO

from fabric.api import env, sudo, cd, put, hide

env.chef_executable = '/var/lib/gems/1.8/bin/chef-solo'

env.project_dir = dirname(abspath(__file__))
env.site_configs = "%s/site_configs" % (env.project_dir, )
env.cookbooks_path = "%s/cookbooks" % (env.project_dir, )

env.remote_project_dir = '/var/chef/chef_recipes'
env.remote_site_configs = "%s/site_configs/" % (env.remote_project_dir)
env.remote_cookbooks_path = "%s/cookbooks" % (env.remote_project_dir, )


def install_chef():
    sudo('apt-get update -q', pty=True)
    sudo('apt-get install -y -q libopenssl-ruby')
    sudo('apt-get install -y -q git-core rubygems ruby ruby-dev', pty=True)
    sudo('gem install chef --no-ri --no-rdoc', pty=True)
    sudo('mkdir -p %s' % env.remote_project_dir)
    sudo('chown %s %s' % (env.user, env.remote_project_dir))

    chef_config = StringIO()
    chef_config.write('cookbook_path "%s"\n' % env.remote_cookbooks_path)
    put(chef_config, '%s/solo.rb' % env.remote_project_dir, use_sudo=True)


def sync_config():
    with hide('running',):
        put(env.project_dir, env.remote_project_dir)


def _update_site(site):
    with cd(env.remote_project_dir):
        sudo('{chef} -j {configs}{site} -c {proj_dir}/solo.rb'.format(
            chef = env.chef_executable, configs = env.remote_site_configs,
            site = site, proj_dir = env.remote_project_dir
        ), pty=True)


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