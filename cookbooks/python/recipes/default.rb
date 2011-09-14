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

if node.has_key?("user")

    user_info = node[:user]

    directory "/home/#{user_info[:username]}/.pip/cache" do
        owner user_info[:username]
        group user_info[:username]
        recursive true
    end

    cookbook_file "/home/#{user_info[:username]}/.pip/pip.conf" do
      source "pip.conf"
      mode 0640
      owner user_info[:username]
      group user_info[:username]
      action :create_if_missing
    end

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

if node.has_key?("user")

    user_info = node[:user]

    # <hack>
    # This is a bit of a massive hack. This should be created *as* the user but
    # it doesn't seem to be working relabily. So, we create it as root and then
    # at the end chown the full thing.
    script "setup-virtualenv" do
        interpreter "bash"
        user "root"
        cwd "/tmp"
        code "
        mkdir -p /home/#{user_info[:username]}/.virtualenvs
        "
    end

    if node.has_key?("virtualenvs")

        node.virtualenvs.each do |name, info|

            script "create-virtualenv" do
                interpreter "bash"
                user "root"
                cwd "/tmp"
                code "
                export WORKON_HOME=/home/#{user_info[:username]}/.virtualenvs
                source /usr/local/bin/virtualenvwrapper.sh
                if [ ! -d \"$WORKON_HOME/#{name}\" ]
                then
                mkvirtualenv #{name}
                fi
                "
            end

            cookbook_file "/home/#{user_info[:username]}/.virtualenvs/postactivate" do
                source "postactivate"
                mode 0640
                owner user_info[:username]
                group user_info[:group]
                action :create
            end

            if info.has_key?("packages")
                info['packages'].each do |pkg|
                    execute "pip-install-#{pkg}" do
                        command "/home/#{user_info[:username]}/.virtualenvs/#{name}/bin/pip install #{pkg}"
                    end
                end
            end

            if info.has_key?("requirements")
                execute "pip-install-#{info[:requirements]}" do
                    command "/home/#{user_info[:username]}/.virtualenvs/#{name}/bin/pip install -r #{info[:requirements]}"
                end
            end
        end

    end

    # chown it all so its not the root user.
    execute "chown-home" do
      command "sudo chown -R #{user_info[:username]} /home/#{user_info[:username]}"
    end

    # </hack>

end
