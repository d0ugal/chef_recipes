from os.path import dirname, abspath
from StringIO import StringIO

from fabric.api import env, sudo, cd, put, task

env.chef_executable = '/var/lib/gems/1.8/bin/chef-solo'

env.project_dir = dirname(abspath(__file__))
env.site_configs = "%s/site_configs" % (env.project_dir, )
env.cookbooks_path = "%s/cookbooks" % (env.project_dir, )

env.remote_project_dir = '/var/chef'
env.remote_site_configs = "%s/chef_recipes/site_configs/" % (env.remote_project_dir)
env.remote_cookbooks_path = "%s/chef_recipes/cookbooks" % (env.remote_project_dir, )

@task
def install_chef():
    sudo('apt-get -y update', pty=True)
    sudo('apt-get -y -q install libopenssl-ruby')
    sudo('apt-get -y -q install git-core rubygems ruby ruby-dev', pty=True)
    sudo('gem install chef --no-ri --no-rdoc', pty=True)
    sudo('mkdir -p %s' % env.remote_project_dir)
    sudo('chown %s %s' % (env.user, env.remote_project_dir))

    chef_config = StringIO()
    chef_config.write('cookbook_path "%s"\n' % env.remote_cookbooks_path)
    put(chef_config, '%s/solo.rb' % env.remote_project_dir, use_sudo=True)

@task
def sync_config():
    put(env.project_dir, env.remote_project_dir)


def _update_site(site):
    with cd(env.remote_project_dir):
        sudo('{chef} -j {configs}{site} -c {proj_dir}/solo.rb'.format(
            chef = env.chef_executable, configs = env.remote_site_configs,
            site = site, proj_dir = env.remote_project_dir
        ), pty=True)

@task
def update_all_sites():
    import os
    sync_config()
    for site in [f for f in os.listdir(env.site_configs) if f.endswith('.json')]:
        print site
        _update_site(site)

@task
def update_site(site):
    import os
    sync_config()
    if site in os.listdir(env.site_configs):
        _update_site(site)

@task
def sites():
    import os

    for site in os.listdir(env.site_configs):
        print site