=begin
  This recipe is a utility recipe, installing a number of additions that are
  useful and required 90% of the time.
=end

execute "update-apt" do
    command "sudo apt-get update"
end

# Install Ack, Git, Hg, SVN, xml libs and jpeg libs.
%w{psmisc ack-grep aptitude vim git-core subversion mercurial libxml2-dev
  libjpeg62-dev zlib1g-dev}.each do |pkg|
  package pkg do
    action :install
  end
end

if node[:gis]
  %w{binutils gdal-bin}.each do |pkg|
      package pkg do
        action :install
      end
  end
end

# On a project basis, allow a set of packages to be defined that will be
# installed at almost the start of the setup process.
if node.has_key?("system_packages")
  node[:system_packages].each do |pkg|
    package pkg do
      action :install
    end
  end
end

if node.has_key?("user")

    user_info = node[:user]

    user user_info[:username] do
        shell "/bin/bash"
        supports :manage_home => true
        home "/home/#{user_info[:username]}"
    end

    directory "/home/#{user_info[:username]}/.ssh" do
        owner user_info[:username]
        group user_info[:username]
        mode 0700
    end

    if user_info.has_key?("ssh_key")
        file "/home/#{user_info[:username]}/.ssh/authorized_keys" do
            owner user_info[:username]
            group user_info[:group]
            mode 0600
            content user_info[:ssh_key]
        end
    end

    group user_info[:group] do
        members user_info[:username]
        append true
    end

    directory "/home/#{user_info[:username]}" do
        owner user_info[:username]
        group user_info[:group]
        mode 0775
    end


    cookbook_file "/home/#{user_info[:username]}/.bashrc_extra" do
        source "bashrc_extra"
        mode 0640
        owner user_info[:username]
        group user_info[:group]
        action :create_if_missing
    end

    execute "source-bachrc-extra" do
        command "echo \"source /home/#{node[:user_name]}/.bashrc_extra\" >> /home/#{node[:user_name]}/.bashrc"
        not_if "grep bashrc_extra /home/#{node[:user_name]}/.bashrc"
    end

end
