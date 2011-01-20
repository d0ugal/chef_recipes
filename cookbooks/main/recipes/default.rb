%w{vim}.each do |pkg|
  package pkg do
    action :install
  end
end

user node[:project_name] do
  comment node[:project_name]
  uid 1001
  gid 1001
  shell "/bin/bash"
  supports :manage_home => true
  home "/home/#{node[:project_name]}"
end

