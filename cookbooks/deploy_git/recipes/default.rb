directory "/var/www/#{node[:project_name]}" do
    owner "www-data"
    group "www-data"
    mode 0777
    recursive true
end

git "/var/www/#{node[:project_name]}" do
  repository node[:repo_address]
  revision "HEAD"
  user "www-data"
  group "www-data"
  git_username node[:repo_username]
  git_password node[:repo_password]
  action :sync
end

execute "change-permissions" do
    command "sudo chmod 775 -R /var/www/#{node[:project_name]}"
end

script "Install Requirements" do
  interpreter "bash"
  user 'root' 
  group 'root'
  code <<-EOH
  sudo /home/#{node[:user_name]}/.virtualenvs/#{node[:project_name]}/bin/pip install -r `find /var/www/#{node[:project_name]} -name requirements.txt`
  EOH
end

execute "remove-local-settings" do
    command "sudo find /var/www/#{node[:project_name]} -name settings_local.py -delete"
end

execute "sync-database" do
    user "www-data"
    group "www-data"
    cwd "/var/www/#{node[:project_name]}/#{node[:django_settings_path]}"
    command "MANAGELOC=$(find /var/www/#{node[:project_name]} -name manage.py); /home/#{node[:user_name]}/.virtualenvs/#{node[:project_name]}/bin/python $MANAGELOC syncdb --noinput"
    not_if "MANAGELOC=$(find /var/www/#{node[:project_name]} -name manage.py); /home/#{node[:user_name]}/.virtualenvs/#{node[:project_name]}/bin/python $MANAGELOC syncdb --noinput --migrate"
end

execute "update-supervisor-app" do
    command "sudo supervisorctl -u #{node[:supervisor_user]} -p #{node[:supervisor_password]} update #{node[:project_name]}"
end
:q

:q
:q
:q!
