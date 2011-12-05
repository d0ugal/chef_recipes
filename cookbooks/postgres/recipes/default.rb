# We give away straight off that while this is a postgres recipe, its a
# postgres recipe for Python.
%w{libpq-dev postgresql python-psycopg2}.each do |pkg|
  package pkg do
    action :install
  end
end

if node.has_key?("dev_env")
    cookbook_file "/etc/postgresql/8.4/main/pg_hba.conf" do
        source "pg_hba_dev.conf"
        mode 0600
        owner "postgres"
        group "postgres"
        action :create
    end
else
    cookbook_file "/etc/postgresql/8.4/main/pg_hba.conf" do
        source "pg_hba.conf"
        mode 0600
        owner "postgres"
        group "postgres"
        action :create
    end
end

# Hackin' it up.

service "postgresql" do
  service_name "postgresql-8.4"
  supports :restart => true, :status => true, :reload => true
  action :restart
end

if node.has_key?("dev_env")
    execute "postgres-listen" do
        command "echo \"listen_addresses = 'localhost'\" >> /etc/postgresql/8.4/main/postgresql.conf"
        notifies :restart, resources(:service => "postgresql")
    end
end

execute "postgres-change-password" do
    command "sudo -u postgres psql -c \"ALTER ROLE postgres WITH PASSWORD '#{node[:postgres_password]}'\""
end

if node.has_key?("project_name")
    # This is basically a big hack - I can't find a nice way to create a user and
    # give them a password easily.
    execute "postgres-createuser" do
        command "sudo -u postgres psql -c \"CREATE ROLE #{node[:project_db_user]} NOSUPERUSER CREATEDB NOCREATEROLE INHERIT LOGIN PASSWORD \'#{node[:project_db_pass]}\';\""
        not_if "sudo -u postgres psql -c \"SELECT * FROM pg_user;\" | grep -i #{node['project_db_user']}"
    end

  template = "template0"
    # Create a database with the same name as the project and also with the owner
    # set to the user we just created.
    execute "postgres-createdb" do
        command "sudo -u postgres -p #{node[:postgres_password]} createdb -T #{template} -E UTF8  -l en_US.utf8 -O #{node[:project_db_user]} #{node[:project_db_name]}"
        not_if "sudo -u postgres -p #{node[:postgres_password]} psql -c \"SELECT * FROM pg_database;\" | grep -i #{node[:'project_db_name']}"
    end
end
