%w{python-setuptools python-dev}.each do |pkg|
  package pkg do
  end
end

execute "easy-install-pip" do
    command "easy_install pip"
end

directory "/home/#{node[:user_name]}/.pip/cache" do
    owner node[:user_name]
    group node[:user_name]
    recursive true
end

cookbook_file "/home/#{node[:user_name]}/.pip/pip.conf" do
  source "pip.conf"
  mode 0640
  owner node[:user_name]
  group node[:user_group]
  action :create_if_missing
end

["virtualenv", "virtualenvwrapper"].each do |pkg|

    execute "pip-install-#{pkg}" do
        command "pip install #{pkg}"
    end

end

if node.has_key?("python_global_packages")
  node[:python_packages].each do |pkg|
    execute "pip-global-install-#{pkg}" do
      command "pip install #{pkg}"
    end
  end
end

# This isn't fully working as it should be run as the project name root but
# that seems to be cusing problems.

script "setup-virtualenv" do
    interpreter "bash"
    user "root"
    cwd "/tmp"
    code "
    mkdir -p /home/#{node[:user_name]}/.virtualenvs
    export WORKON_HOME=/home/#{node[:user_name]}/.virtualenvs
    source /usr/local/bin/virtualenvwrapper.sh
    "
end

if node.has_key?("project_name")
    script "create-virtualenv" do
        interpreter "bash"
        user "root"
        cwd "/tmp"
        code "
        export WORKON_HOME=/home/#{node[:user_name]}/.virtualenvs
        source /usr/local/bin/virtualenvwrapper.sh
        if [[ $(lsvirtualenv) != *#{node[:project_name]}* ]]
        then
        mkvirtualenv #{node[:project_name]}
        fi
        "
    end

  cookbook_file "/home/#{node[:user_name]}/.virtualenvs/postactivate" do
    source "postactivate"
    mode 0640
    owner node[:user_name]
    group node[:user_group]
    action :create
  end
end

  if node.has_key?("python_packages")
    node[:python_packages].each do |pkg|
      execute "pip-install-#{pkg}" do
        command "/home/#{node[:user_name]}/.virtualenvs/#{node[:project_name]}/bin/pip install #{pkg}"
      end
    end
  end

  execute "chown-home" do
    command "sudo chown -R #{node[:user_name]} /home/#{node[:user_name]}"
  end
