package "supervisor" do
    action :install
end

template "/etc/supervisor/supervisord.conf" do
    source "supervisord.conf.erb"
    mode 0600
    owner "root"
    group "root"
    action :create
end

directory "/var/log/#{node[:project_name]}" do
    owner "root"
    group "root"
    mode 0775
    recursive true
end

if node.has_key?("project_name")
    template "/etc/supervisor/conf.d/#{node[:project_name]}.conf" do
        source "site.conf.erb"
        mode 0600
        owner "root"
        group "root"
        action :create
    end
end

execute "supervisor-start" do
    command "sudo supervisord"
    ignore_failure true
end

=begin package from apt adds to rc and contains config file anyway.
execute "supervisor-start" do
    command "sudo /etc/init.d/supervisor start"
    not_if "sudo pgrep supervisord"
end

cookbook_file "/etc/init.d/supervisord" do
    source "init_supervisord"
    mode 0700
    owner "root"
    group "root"
    action :create
end

execute "supervisor-rc" do
    command "sudo update-rc.d etc/init.d/supervisord defaults"
end
=end

