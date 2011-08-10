execute "update-apt" do
    command "sudo apt-get update"
end

%w{psmisc ack-grep aptitude vim git-core subversion mercurial libxml2-dev}.each do |pkg|
  package pkg do
    action :install
  end
end

# Allow the user to specify some other system packages to install
if node.has_key?("system_packages")
  node[:system_packages].each do |pkg|
    package pkg do
      action :install
    end
  end
end

if not node.has_key?("dev_env")
    user node[:user_name] do 
        shell "/bin/bash"
        supports :manage_home => true
        home "/home/#{node[:user_name]}"
    end

    directory "/home/#{node[:user_name]}/.ssh" do
        owner node[:user_name]
        group node[:user_name]
        mode 0700
    end

    if node.has_key?("ssh_key")
        file "/home/#{node[:user_name]}/.ssh/authorized_keys" do
            owner node[:user_name]
            group node[:user_group]
            mode 0600
            content node[:ssh_key]
        end
    end

    group node[:user_group] do
        members node[:user_name]
        append true
    end

    directory "/home/#{node[:user_name]}" do
        owner node[:user_name]
        group node[:user_group]
        mode 0775
    end
end

cookbook_file "/home/#{node[:user_name]}/.bashrc_extra" do
  source "bashrc_extra"
  mode 0640
  owner node[:user_name]
  group node[:user_group]
  action :create_if_missing
end

execute "source-bachrc-extra" do
  command "echo \"source /home/#{node[:user_name]}/.bashrc_extra\" >> /home/#{node[:user_name]}/.bashrc"
  not_if "grep bashrc_extra /home/#{node[:user_name]}/.bashrc" 
end
