=begin
  This recipe is designed to setup a fairly generic python einiroment. Adding
  the system packages that are required, installing pip and setting up 
  everything required to then add virtualenvs.
=end

%w{python-setuptools python-dev}.each do |pkg|
  package pkg do
    action :install
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
  node[:python_global_packages].each do |pkg|
    execute "pip-global-install-#{pkg}" do
      command "pip install #{pkg}"
    end
  end
end

# <hack>
# This is a bit of a massive hack. This should be created *as* the user but 
# it doesn't seem to be working relabily. So, we create it as root and then 
# at the end chown the full thing.
script "setup-virtualenv" do
    interpreter "bash"
    user "root"
    cwd "/tmp"
    code "
    mkdir -p /home/#{node[:user_name]}/.virtualenvs
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

# chown it all so its not the root user.
execute "chown-home" do
  command "sudo chown -R #{node[:user_name]} /home/#{node[:user_name]}"
end

# </hack>
