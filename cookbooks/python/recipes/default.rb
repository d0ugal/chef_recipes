%w{python-setuptools python-dev}.each do |pkg|
  package pkg do
    action :install
  end
end


execute "easy-install-pip" do
    command "easy_install pip"
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
  mkdir -p /home/vagrant/.virtualenvs
  export WORKON_HOME=/home/vagrant/.virtualenvs
  source /usr/local/bin/virtualenvwrapper.sh
  mkvirtualenv #{node[:project_name]}
  "
end

if node.has_key?("python_packages")
  node[:python_packages].each do |pkg|
    execute "pip-install-#{pkg}" do
      command "/home/vagrant/.virtualenvs/#{node[:project_name]}/bin/pip install #{pkg}"
    end
  end
end

execute "chown-home" do
  command "sudo chown -R vagrant /home/vagrant"
end
