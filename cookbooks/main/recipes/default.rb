=begin
  This recipe is a utility recipe, installing a number of additions that are 
  useful and required 90% of the time.
=end

execute "update-apt" do
    command "sudo apt-get update"
end

# Install Ack, Git, Hg, SVN, xml libs and jpeg libs.
%w{ack-grep aptitude vim git-core subversion mercurial libxml2-dev 
  libjpeg62-dev zlib1g-dev}.each do |pkg|
  package pkg do
    action :install
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

# Add a bashrc_extra file that is loaded in the bashrc and used to setup a few
# aliases and other useful bash related features.
cookbook_file "/home/vagrant/.bashrc_extra" do
  source "bashrc_extra"
  mode 0640
  owner "vagrant"
  group "vagrant"
  action :create_if_missing
end

execute "source-bachrc-extra" do
  command "echo \"source /home/vagrant/.bashrc_extra\" >> /home/vagrant/.bashrc"
  not_if "grep bashrc_extra /home/vagrant/.bashrc" 
end
