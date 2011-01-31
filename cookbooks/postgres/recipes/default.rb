# We give away straight off that while this is a postgres recipe, its a
# postgres recipe for Python.
%w{postgresql python-psycopg2}.each do |pkg|
  package pkg do
    action :install
  end
end


cookbook_file "/etc/postgresql/8.4/main/pg_hba.conf" do
    source "pg_hba.conf"
    mode 0600
    owner "postgres"
    group "postgres"
    action :create
end

# Hackin' it up.

service "postgresql" do
  service_name "postgresql-8.4"
  supports :restart => true, :status => true, :reload => true
  action :restart
end

execute "postgres-listen" do
    command "echo \"listen_addresses = '*'\" >> /etc/postgresql/8.4/main/postgresql.conf"
    notifies :restart, resources(:service => "postgresql")
end

execute "postgres-change-password" do
    command "sudo -u postgres psql -c \"ALTER ROLE postgres WITH PASSWORD 'postgres'\""
end

# This is basically a big hack - I can't find a nice way to create a user and
# give them a password easily.
execute "postgres-createuser" do
    command "sudo -u postgres psql -c \"CREATE ROLE #{node[:project_name]} NOSUPERUSER CREATEDB NOCREATEROLE INHERIT LOGIN PASSWORD \'#{node[:project_name]}\';\""
    not_if "sudo -u postgres psql -c \"SELECT * FROM pg_user;\" | grep #{node['project_name']}"
end

# Create a database with the same name as the project and also with the owner
# set to the user we just created.
execute "postgres-createdb" do
    command "sudo -u postgres createdb -O #{node[:project_name]} #{node[:project_name]}"
    not_if "sudo -u postgres psql -c \"SELECT * FROM pg_database;\" | grep #{node['project_name']}"
end
