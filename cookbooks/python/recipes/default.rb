%w{python-setuptools python-dev}.each do |pkg|
  package pkg do
    action :install
  end
end


execute "install-pip" do
    command "easy_install pip"
end


["virtualenv", "virtualenvwrapper"].each do |pkg|

    execute "install-#{pkg}" do
        command "pip install #{pkg}"
    end

end

# This isn't fully working as it should be run as the project name root but
# that seems to be cusing problems.
script "setup-virtualenv" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code "
  mkdir -p /home/#{node[:project_name]}/.virtualenvs
  export WORKON_HOME=/home/#{node[:project_name]}/.virtualenvs
  source /usr/local/bin/virtualenvwrapper.sh
  mkvirtualenv #{node[:project_name]}
  sudo chown -R #{node[:project_name]} /home/#{node[:project_name]}/.virtualenvs/
  "
end

