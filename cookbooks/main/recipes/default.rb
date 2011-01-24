%w{ack-grep aptitude vim}.each do |pkg|
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

cookbook_file "/home/vagrant/.bashrc_extra" do
  source "bashrc_extra"
  mode 0640
  owner "vagrant"
  group "vagrant"
end

execute "source-bachrc-extra" do
  command "echo \"source /home/vagrant/.bashrc_extra\" >> /home/vagrant/.bashrc"
end
