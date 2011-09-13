package "nginx" do
    action :install
end

service "nginx" do
    enabled true
    running true
    supports :status => true, :restart => true, :reload => true
    action [:start, :enable]
end

cookbook_file "/etc/nginx/nginx.conf" do
    source "nginx.conf"
    mode 0640
    owner "root"
    group "root"
    notifies :restart, resources(:service => "nginx")
end

if node.has_key?("domain_names") and node.has_key?("project_name")

    directory "/var/log/nginx/#{node[:project_name]}" do
        owner "root"
        group "root"
        mode 0775
        recursive true
    end

    template "/etc/nginx/sites-available/#{node[:project_name]}" do
        source "site.erb"
        mode 0640
        owner "root"
        group "root"
        notifies :restart, resources(:service => "nginx")
    end

    execute "nginx-symlink" do
        command "sudo ln -s /etc/nginx/sites-available/#{node[:project_name]} /etc/nginx/sites-enabled/#{node[:project_name]}"
        not_if "sudo ls /etc/nginx/sites-enabled/#{node[:project_name]}"
        notifies :restart, resources(:service => "nginx")
    end

end
